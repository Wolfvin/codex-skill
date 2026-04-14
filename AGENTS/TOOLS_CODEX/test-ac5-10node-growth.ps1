param(
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataRoot = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\ac5-10nodes",
  [int]$NodeCount = 10,
  [int]$BasePort = 3100,
  [int]$BaseHeartbeatPort = 48032,
  [int]$UdpStride = 3,
  [int]$BurstCount = 20,
  [int]$BurstIntervalMs = 120
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\node-sim-lib.ps1"

if (Test-Path $DataRoot) {
  Remove-Item -LiteralPath $DataRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $DataRoot | Out-Null

$serverExe = Join-Path $ServerRoot "target\debug\akp2i-server.exe"
if (!(Test-Path $serverExe)) { throw "Server binary not found: $serverExe" }

$nodes = Build-NodeList -NodeCount $NodeCount -BasePort $BasePort -DataRoot $DataRoot -BaseHeartbeatPort $BaseHeartbeatPort -UdpStride $UdpStride
$hbTargets = ($nodes | ForEach-Object { $_.HeartbeatPort }) -join ","
$procs = @()

Write-Host "=== AC5 10-Node Growth Simulation ==="
Write-Host "NodeCount     : $NodeCount"
Write-Host "BasePort      : $BasePort"
Write-Host "BaseHeartbeat : $BaseHeartbeatPort"
Write-Host "DataRoot      : $DataRoot"
Write-Host "BurstCount    : $BurstCount"
Write-Host ""

function RegisterDevice([string]$BaseUrl, [string]$Hw, [string]$Nama) {
  $body = @{
    hardware_id = $Hw
    name = $Nama
    user_name = $Nama
    app_version = "1.0.0"
  } | ConvertTo-Json
  $lastErr = $null
  for ($i=1; $i -le 4; $i++) {
    try {
      Invoke-RestMethod -Method POST -Uri "$BaseUrl/api/devices" -ContentType "application/json" -Body $body -TimeoutSec 30 | Out-Null
      return $true
    } catch {
      $lastErr = $_
      Start-Sleep -Seconds 4
    }
  }
  if ($lastErr) { throw $lastErr }
  return $false
}

function Count-DeviceFiles([string]$DataDir) {
  $dir = Join-Path $DataDir "devices"
  if (!(Test-Path $dir)) { return 0 }
  return (Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue | Measure-Object).Count
}

try {
  foreach ($n in $nodes) {
    $procId = Start-NodeProcess -ServerRoot $ServerRoot -DataDir $n.DataDir -Port $n.Port -NodeName $n.Name `
      -HeartbeatPort $n.HeartbeatPort -DiscoveryPort $n.DiscoveryPort -ControlPort $n.ControlPort `
      -HeartbeatTargets $hbTargets -BroadcastAddr "127.0.0.1" -ExtraEnv @{
        AKPI_ENABLE_COMPACTION_LOOP = "0"
        AKPI_ENABLE_DEVICE_DEDUPE = "0"
        AKPI_DISABLE_QUEUE_RETRY = "1"
        AKPI_DISABLE_WAITING_ROOM = "1"
        AKPI_DISABLE_STORAGE_SYNC = "1"
      }
    $procs += $procId
    Start-Sleep -Milliseconds 250
  }

  foreach ($n in $nodes) {
    if (-not (Wait-Healthy -BaseUrl $n.BaseUrl -TimeoutSec 40)) {
      throw "Node tidak healthy: $($n.Name) $($n.BaseUrl)"
    }
  }
  Write-Host "[OK] Semua node healthy"
  Start-Sleep -Seconds 8

  $hwByNode = @{}
  foreach ($n in $nodes) {
    $hw = "ac5-hw-$($n.Name)"
    $null = RegisterDevice -BaseUrl $n.BaseUrl -Hw $hw -Nama ("AC5 " + $n.Name)
    $hwByNode[$n.Name] = $hw
  }
  Write-Host "[OK] Seed register semua node selesai"

  $before = @{}
  foreach ($n in $nodes) {
    $before[$n.Name] = Count-DeviceFiles -DataDir $n.DataDir
  }

  for ($i=0; $i -lt $BurstCount; $i++) {
    foreach ($n in $nodes) {
      $hw = [string]$hwByNode[$n.Name]
      $null = RegisterDevice -BaseUrl $n.BaseUrl -Hw $hw -Nama ("AC5 " + $n.Name)
    }
    if ($BurstIntervalMs -gt 0) { Start-Sleep -Milliseconds $BurstIntervalMs }
  }

  $after = @{}
  foreach ($n in $nodes) {
    $after[$n.Name] = Count-DeviceFiles -DataDir $n.DataDir
  }

  $maxDelta = 0
  $sumDelta = 0
  foreach ($n in $nodes) {
    $delta = [int]$after[$n.Name] - [int]$before[$n.Name]
    if ($delta -gt $maxDelta) { $maxDelta = $delta }
    $sumDelta += $delta
    Write-Host ("[INFO] {0} device_files before={1} after={2} delta={3}" -f $n.Name, $before[$n.Name], $after[$n.Name], $delta)
  }

  if ($maxDelta -le 1) {
    Write-Host "[PASS] AC5 growth rasional: max delta per node <= 1 (tidak linear saat burst register)." -ForegroundColor Green
    Write-Host "[INFO] sum_delta=$sumDelta max_delta=$maxDelta"
    exit 0
  }

  Write-Host "[FAIL] AC5 gagal: ada growth files devices berlebih saat burst register." -ForegroundColor Red
  Write-Host "[INFO] sum_delta=$sumDelta max_delta=$maxDelta"
  exit 1
}
finally {
  foreach ($n in $nodes) {
    Stop-Node -Node $n | Out-Null
  }
}
