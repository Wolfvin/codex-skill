param(
  [string]$BaseUrl = "http://192.168.100.74:3000",
  [string]$RawHardwareId = "",
  [int]$TimeoutSec = 10
)

$ErrorActionPreference = "Stop"

function Get-MachineGuid {
  try {
    $v = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid" -ErrorAction Stop
    if ($null -ne $v -and "$v".Trim() -ne "") { return "$v".Trim() }
  } catch {}
  return $null
}

function Get-Sha256Hex([string]$Text) {
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    return ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join ""
  } finally {
    $sha.Dispose()
  }
}

function Invoke-Json {
  param(
    [string]$Method,
    [string]$Uri,
    [hashtable]$Headers = @{},
    [object]$Body = $null
  )
  try {
    $args = @{
      Method = $Method
      Uri = $Uri
      TimeoutSec = $TimeoutSec
      Headers = $Headers
      ErrorAction = "Stop"
    }
    if ($null -ne $Body) {
      $args.ContentType = "application/json"
      $args.Body = $Body
    }
    $data = Invoke-RestMethod @args
    return [pscustomobject]@{ ok = $true; status = 200; data = $data; error = "" }
  } catch {
    $status = $null
    try { $status = [int]$_.Exception.Response.StatusCode } catch {}
    return [pscustomobject]@{ ok = $false; status = $status; data = $null; error = $_.Exception.Message }
  }
}

Write-Host "=== PROD FRESH NODE PREFLIGHT ==="
Write-Host ("BaseUrl : {0}" -f $BaseUrl)

$raw = $RawHardwareId
$src = "manual"
if ([string]::IsNullOrWhiteSpace($raw)) {
  $raw = Get-MachineGuid
  $src = "machine_guid"
}
if ([string]::IsNullOrWhiteSpace($raw)) {
  throw "HWID tidak ditemukan. Isi -RawHardwareId."
}
$hash = Get-Sha256Hex $raw

Write-Host ("HWID source : {0}" -f $src)
Write-Host ("HWID raw    : {0}" -f $raw)
Write-Host ("HWID hash   : {0}" -f $hash)

$appRoot = Join-Path $env:LOCALAPPDATA "Smart Tax Assistance"
$webRoot = Join-Path $env:LOCALAPPDATA "com.smartpdf.autoextractor"
$webView = Join-Path $webRoot "EBWebView"
$serverDb = Join-Path $appRoot "server\\lokal\\index.db"

Write-Host "`n=== LOCAL RUNTIME FILES ==="
Write-Host ("app root exists      : {0}" -f (Test-Path $appRoot))
Write-Host ("app.exe exists       : {0}" -f (Test-Path (Join-Path $appRoot "app.exe")))
Write-Host ("akp2i-server exists  : {0}" -f (Test-Path (Join-Path $appRoot "akp2i-server.exe")))
Write-Host ("server index.db      : {0}" -f (Test-Path $serverDb))
Write-Host ("webview root exists  : {0}" -f (Test-Path $webRoot))
Write-Host ("EBWebView exists     : {0}" -f (Test-Path $webView))

Write-Host "`n=== API CHECK ==="
$pingPublic = Invoke-Json -Method "GET" -Uri "$BaseUrl/api/session/ping"
Write-Host ("GET /api/session/ping public : ok={0} status={1}" -f $pingPublic.ok, $pingPublic.status)
if (-not $pingPublic.ok) { Write-Host ("  err: {0}" -f $pingPublic.error) }

$bootBody = @{ hardware_id = $raw; app_version = "1.0.0" } | ConvertTo-Json
$boot = Invoke-Json -Method "POST" -Uri "$BaseUrl/api/session/bootstrap" -Body $bootBody
if (-not $boot.ok) {
  Write-Host ("POST /api/session/bootstrap    : FAILED status={0} err={1}" -f $boot.status, $boot.error)
  exit 1
}
Write-Host ("POST /api/session/bootstrap    : ok={0} role={1} reason={2}" -f [bool]$boot.data.ok, [string]$boot.data.role, [string]$boot.data.reason)
$token = [string]$boot.data.token
Write-Host ("bootstrap token.set            : {0}" -f ([bool](-not [string]::IsNullOrWhiteSpace($token))))

$pingAuth = Invoke-Json -Method "GET" -Uri "$BaseUrl/api/session/ping" -Headers @{
  "x-akp2i-token" = $token
  "x-akp2i-hardware-id" = $raw
}
if ($pingAuth.ok) {
  Write-Host ("GET /api/session/ping auth     : ok={0} reason={1}" -f [bool]$pingAuth.data.ok, [string]$pingAuth.data.reason)
} else {
  Write-Host ("GET /api/session/ping auth     : FAILED status={0} err={1}" -f $pingAuth.status, $pingAuth.error)
}

$devices = Invoke-Json -Method "GET" -Uri "$BaseUrl/api/devices"
if ($devices.ok) {
  $arr = @()
  if ($devices.data -is [System.Array]) { $arr = @($devices.data) }
  elseif ($devices.data.devices -is [System.Array]) { $arr = @($devices.data.devices) }
  elseif ($devices.data.value -is [System.Array]) { $arr = @($devices.data.value) }
  $m = $arr | Where-Object { [string]$_.id -eq $hash } | Select-Object -First 1
  if ($m) {
    Write-Host ("devices match                 : PASS is_admin={0} is_super_admin={1}" -f [bool]$m.is_admin, [bool]$m.is_super_admin)
  } else {
    Write-Host ("devices match                 : BLOCK (hash tidak ditemukan, total={0})" -f $arr.Count)
  }
} else {
  Write-Host ("GET /api/devices              : FAILED status={0} err={1}" -f $devices.status, $devices.error)
}

Write-Host "`n=== PRODUCTION VERDICT ==="
if ($boot.data.ok -eq $true -and $pingAuth.ok -and $pingAuth.data.ok -eq $true) {
  Write-Host "[PASS] Node fresh siap masuk dashboard. Kalau UI masih restricted -> masalah state WebView/cached app setting."
} else {
  Write-Host "[BLOCK] Masih ada blocker backend/auth. Jangan lanjut rilis node ini sebelum hijau."
}
