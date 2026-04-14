param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [string[]]$HardwareIds = @(),
  [string[]]$Names = @(),
  [int]$TimeoutSec = 8
)

$ErrorActionPreference = "Stop"

function Get-Sha256Hex {
  param([string]$InputText)
  if ([string]::IsNullOrWhiteSpace($InputText)) { return "" }
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputText)
    $hash = $sha.ComputeHash($bytes)
    return -join ($hash | ForEach-Object { $_.ToString("x2") })
  } finally {
    $sha.Dispose()
  }
}

function Invoke-ApiJson {
  param(
    [string]$Method,
    [string]$Uri,
    $Body = $null
  )

  try {
    if ($null -ne $Body) {
      $json = $Body | ConvertTo-Json -Depth 8
      $resp = Invoke-RestMethod -Method $Method -Uri $Uri -ContentType "application/json" -Body $json -TimeoutSec $TimeoutSec
    } else {
      $resp = Invoke-RestMethod -Method $Method -Uri $Uri -TimeoutSec $TimeoutSec
    }
    return @{
      ok = $true
      status = 200
      data = $resp
      error = ""
    }
  } catch {
    $status = -1
    $msg = $_.Exception.Message
    if ($_.Exception.Response) {
      try { $status = [int]$_.Exception.Response.StatusCode } catch { $status = -1 }
      try {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $rawBody = $reader.ReadToEnd()
        if ($rawBody) { $msg = "$msg | body=$rawBody" }
      } catch { }
    }
    return @{
      ok = $false
      status = $status
      data = $null
      error = $msg
    }
  }
}

if (-not $HardwareIds -or $HardwareIds.Count -eq 0) {
  throw "Isi -HardwareIds minimal 1 nilai."
}

if ($Names.Count -gt 0 -and $Names.Count -ne $HardwareIds.Count) {
  throw "Jika -Names dipakai, jumlahnya harus sama dengan -HardwareIds."
}

Write-Host "=== User Bootstrap Diagnose ==="
Write-Host "BaseUrl     : $BaseUrl"
Write-Host "Users count : $($HardwareIds.Count)"
Write-Host ""

$devicesRes = Invoke-ApiJson -Method "GET" -Uri "$BaseUrl/api/devices"
$activeDevices = @()
if ($devicesRes.ok -and $devicesRes.data) {
  if ($devicesRes.data -is [System.Array]) {
    $activeDevices = @($devicesRes.data)
  } elseif ($devicesRes.data.devices -is [System.Array]) {
    $activeDevices = @($devicesRes.data.devices)
  } elseif ($devicesRes.data.value -is [System.Array]) {
    $activeDevices = @($devicesRes.data.value)
  }
}

if ($devicesRes.ok) {
  Write-Host "[OK] GET /api/devices -> $($activeDevices.Count) row(s)"
} else {
  Write-Host "[WARN] GET /api/devices gagal -> $($devicesRes.error)"
}

Write-Host ""
Write-Host "=== Per User ==="

$rows = @()
for ($i = 0; $i -lt $HardwareIds.Count; $i++) {
  $hw = [string]$HardwareIds[$i]
  $name = if ($Names.Count -gt 0) { [string]$Names[$i] } else { "user_$($i+1)" }
  $hashed = Get-Sha256Hex -InputText $hw
  $registered = $false
  $deviceRole = ""
  $deviceName = ""

  if ($activeDevices.Count -gt 0 -and $hashed) {
    $match = $activeDevices | Where-Object { [string]$_.id -eq $hashed } | Select-Object -First 1
    if ($match) {
      $registered = $true
      $deviceRole = if ($match.is_super_admin) { "super_admin" } elseif ($match.is_admin) { "admin" } else { "user" }
      $deviceName = [string]$match.name
    }
  }

  $boot = Invoke-ApiJson -Method "POST" -Uri "$BaseUrl/api/session/bootstrap" -Body @{
    hardware_id = $hw
    app_version = "1.0.0"
  }

  $bootOk = $false
  $bootRole = ""
  $bootReason = ""
  $bootBypass = $false
  $bootAllow = $false
  $tokenSet = $false
  $status = $boot.status

  if ($boot.ok -and $boot.data) {
    $bootOk = [bool]$boot.data.ok
    $bootRole = [string]($boot.data.role)
    $bootReason = [string]($boot.data.reason)
    $bootBypass = [bool]($boot.data.auth.restricted_bypass)
    $bootAllow = [bool]($boot.data.auth.super_admin_allowlisted)
    $tokenSet = -not [string]::IsNullOrWhiteSpace([string]$boot.data.token)
  } else {
    $bootReason = $boot.error
  }

  $rows += [PSCustomObject]@{
    name = $name
    hardware_id = $hw
    hashed_id = $hashed
    registered_in_devices = $registered
    device_role = $deviceRole
    device_name = $deviceName
    bootstrap_http = $status
    bootstrap_ok = $bootOk
    bootstrap_role = $bootRole
    reason = $bootReason
    restricted_bypass = $bootBypass
    super_admin_allowlisted = $bootAllow
    token_set = $tokenSet
  }
}

$rows | Format-Table -AutoSize

Write-Host ""
Write-Host "=== Strict Verdict ==="
foreach ($r in $rows) {
  if (-not $r.bootstrap_ok) {
    Write-Host "[BLOCK] $($r.name): restricted (reason=$($r.reason), http=$($r.bootstrap_http), registered=$($r.registered_in_devices))"
    continue
  }
  if (-not $r.token_set) {
    Write-Host "[WARN]  $($r.name): bootstrap ok tapi token kosong"
    continue
  }
  Write-Host "[PASS]  $($r.name): bootstrap ok, role=$($r.bootstrap_role), token_set=$($r.token_set)"
}
