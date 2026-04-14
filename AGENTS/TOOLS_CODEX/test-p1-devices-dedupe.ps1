param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [string]$HardwareId = "eb631723-7fb8-41a9-8543-87038070062d",
  [string]$AppVersion = "1.0.0",
  [string]$DataDir = "",
  [int]$BootstrapCount = 10,
  [int]$PingCount = 60,
  [int]$PingIntervalMs = 250
)

$ErrorActionPreference = "Stop"

function Get-DbMetrics {
  $baseDataDir = if ([string]::IsNullOrWhiteSpace($DataDir)) {
    Join-Path $env:LOCALAPPDATA "Smart Tax Assistance\\server\\lokal"
  } else {
    $DataDir
  }
  $devicesDir = Join-Path $baseDataDir "devices"
  $fileCount = 0
  if (Test-Path $devicesDir) {
    $fileCount = (Get-ChildItem -Path $devicesDir -File -ErrorAction SilentlyContinue | Measure-Object).Count
  }
  $activeCount = 0
  try {
    $active = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/devices"
    if ($null -ne $active) {
      $activeCount = @($active).Count
    }
  } catch {
    $activeCount = -1
  }
  return [pscustomobject]@{
    devices_active = $activeCount
    devices_total  = $fileCount
    oplog_devices  = -1
  }
}

function Post-Bootstrap {
  param([string]$Url, [string]$Hw, [string]$Ver)
  $body = @{ hardware_id = $Hw; app_version = $Ver } | ConvertTo-Json
  return Invoke-RestMethod -Method POST -Uri "$Url/api/session/bootstrap" -ContentType "application/json" -Body $body
}

function Get-Ping {
  param([string]$Url, [string]$Hw, [string]$Token)
  $headers = @{
    "x-akp2i-hardware-id" = $Hw
    "x-akp2i-token" = $Token
  }
  return Invoke-RestMethod -Method GET -Uri "$Url/api/session/ping" -Headers $headers
}

Write-Host "=== P1 Devices Dedupe Simulation ==="
Write-Host "BaseUrl         : $BaseUrl"
Write-Host "HardwareId      : $HardwareId"
Write-Host "BootstrapCount  : $BootstrapCount"
Write-Host "PingCount       : $PingCount"
Write-Host "PingIntervalMs  : $PingIntervalMs"
Write-Host ""

$before = Get-DbMetrics
Write-Host "[Before] devices_active=$($before.devices_active) devices_total=$($before.devices_total) oplog_devices=$($before.oplog_devices)"

$lastBootstrap = $null
for ($i = 1; $i -le $BootstrapCount; $i++) {
  $lastBootstrap = Post-Bootstrap -Url $BaseUrl -Hw $HardwareId -Ver $AppVersion
}
Write-Host "[Bootstrap] done x$BootstrapCount, ok=$($lastBootstrap.ok), role=$($lastBootstrap.role)"

$token = [string]$lastBootstrap.token
if ([string]::IsNullOrWhiteSpace($token)) {
  throw "Token kosong dari bootstrap. Tidak bisa lanjut ping simulation."
}

$pingOk = 0
for ($i = 1; $i -le $PingCount; $i++) {
  $resp = Get-Ping -Url $BaseUrl -Hw $HardwareId -Token $token
  if ($resp.ok -eq $true) { $pingOk++ }
  if ($PingIntervalMs -gt 0) { Start-Sleep -Milliseconds $PingIntervalMs }
}
Write-Host "[Ping] success=$pingOk/$PingCount"

$after = Get-DbMetrics
Write-Host "[After ] devices_active=$($after.devices_active) devices_total=$($after.devices_total) oplog_devices=$($after.oplog_devices)"

$deltaActive = [int]$after.devices_active - [int]$before.devices_active
$deltaTotal = [int]$after.devices_total - [int]$before.devices_total
$deltaOplog = [int]$after.oplog_devices - [int]$before.oplog_devices

Write-Host ""
Write-Host "=== Delta ==="
Write-Host "delta_devices_active : $deltaActive"
Write-Host "delta_devices_total  : $deltaTotal"
Write-Host "delta_oplog_devices  : $deltaOplog"

$isFreshBootstrapCase = ([int]$before.devices_active -eq 0 -and [int]$before.devices_total -eq 0)
$maxAllowedTotal = if ($isFreshBootstrapCase) { 2 } else { 1 }
$pass = ($deltaActive -le 1 -and $deltaTotal -le $maxAllowedTotal -and $deltaOplog -le 1)
if ($pass) {
  if ($isFreshBootstrapCase) {
    Write-Host "[PASS] P1 dedupe/session-ping guard aktif (fresh bootstrap allow <=2 writes)." -ForegroundColor Green
  } else {
    Write-Host "[PASS] P1 dedupe/session-ping guard aktif (growth <= 1)." -ForegroundColor Green
  }
  exit 0
}

Write-Host "[FAIL] Growth devices/oplog masih terlalu besar." -ForegroundColor Red
exit 1
