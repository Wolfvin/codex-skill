param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [string]$AdminHardwareId,
  [int]$TimeoutSec = 8
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step($msg) {
  Write-Host "`n=== $msg ===" -ForegroundColor Cyan
}

function Invoke-Api {
  param(
    [string]$Method,
    [string]$Path,
    [hashtable]$Headers = @{},
    $Body = $null,
    [int[]]$AcceptStatus = @(200)
  )
  $uri = "$BaseUrl$Path"
  try {
    if ($null -ne $Body) {
      $json = $Body | ConvertTo-Json -Depth 8
      $resp = Invoke-WebRequest -UseBasicParsing -Method $Method -Uri $uri -Headers $Headers -Body $json -ContentType "application/json" -TimeoutSec $TimeoutSec
    } else {
      $resp = Invoke-WebRequest -UseBasicParsing -Method $Method -Uri $uri -Headers $Headers -TimeoutSec $TimeoutSec
    }
    $ok = $AcceptStatus -contains [int]$resp.StatusCode
    return [pscustomobject]@{ ok = $ok; status = [int]$resp.StatusCode; body = $resp.Content; error = "" }
  } catch {
    $status = 0
    $body = ""
    try {
      if ($_.Exception.Response) {
        $status = [int]$_.Exception.Response.StatusCode
        $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $body = $sr.ReadToEnd()
      }
    } catch {}
    $ok = $AcceptStatus -contains $status
    return [pscustomobject]@{ ok = $ok; status = $status; body = $body; error = $_.Exception.Message }
  }
}

if (-not $AdminHardwareId) {
  throw "AdminHardwareId wajib diisi."
}

Write-Step "A1. Bootstrap admin (alur nyata welcome/session)"
$bootstrap = Invoke-Api -Method POST -Path "/api/session/bootstrap" -Body @{ hardware_id = $AdminHardwareId; app_version = "1.0.0" } -AcceptStatus @(200)
if (-not $bootstrap.ok) {
  Write-Host "[FAIL] bootstrap admin status=$($bootstrap.status) err=$($bootstrap.error)" -ForegroundColor Red
  exit 1
}
$bootJson = $null
try { $bootJson = $bootstrap.body | ConvertFrom-Json } catch {}
$token = [string]($bootJson.token)
$role = [string]($bootJson.role)
$okValue = [bool]($bootJson.ok)
Write-Host "[INFO] bootstrap: ok=$okValue role=$role token_set=$([bool]($token))"
if (-not $okValue -or [string]::IsNullOrWhiteSpace($token)) {
  Write-Host "[FAIL] admin bootstrap tidak menghasilkan sesi valid." -ForegroundColor Red
  exit 1
}

$adminHeaders = @{
  "x-akp2i-hardware-id" = $AdminHardwareId
  "x-akp2i-token" = $token
}

Write-Step "A2. Admin harus bisa akses endpoint monitor/manager"
$adminSlots = Invoke-Api -Method GET -Path "/api/devices/slots" -Headers $adminHeaders -AcceptStatus @(200)
$adminIdentity = Invoke-Api -Method GET -Path "/identity/conflict/list?status=pending_rebind&limit=5" -Headers $adminHeaders -AcceptStatus @(200)
$adminPass = $adminSlots.ok -and $adminIdentity.ok
if ($adminPass) {
  Write-Host "[PASS] admin auth gate backend OK (slots + identity conflict list)." -ForegroundColor Green
} else {
  Write-Host "[FAIL] admin gate gagal." -ForegroundColor Red
  Write-Host "  slots   -> status=$($adminSlots.status) err=$($adminSlots.error)"
  Write-Host "  identity-> status=$($adminIdentity.status) err=$($adminIdentity.error)"
}

Write-Step "A3. Non-admin/unauth harus ditolak"
$anonSlots = Invoke-Api -Method GET -Path "/api/devices/slots" -AcceptStatus @(401,403)
$anonIdentity = Invoke-Api -Method GET -Path "/identity/conflict/list?status=pending_rebind&limit=5" -AcceptStatus @(401,403)
$anonPass = $anonSlots.ok -and $anonIdentity.ok
if ($anonPass) {
  Write-Host "[PASS] non-admin blocked sesuai ekspektasi (401/403)." -ForegroundColor Green
} else {
  Write-Host "[FAIL] non-admin tidak terblokir sesuai ekspektasi." -ForegroundColor Red
  Write-Host "  slots   -> status=$($anonSlots.status) err=$($anonSlots.error)"
  Write-Host "  identity-> status=$($anonIdentity.status) err=$($anonIdentity.error)"
}

Write-Step "Summary"
if ($adminPass -and $anonPass) {
  Write-Host "[PASS] Role gate backend final: ADMIN allowed, NON-ADMIN blocked." -ForegroundColor Green
  exit 0
}

Write-Host "[FAIL] Role gate backend belum siap produksi." -ForegroundColor Red
exit 2
