param(
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataRoot = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\ac5-fullsync",
  [int]$NodeCount = 10,
  [int]$BasePort = 3200,
  [int]$BaseHeartbeatPort = 48132,
  [int]$UdpStride = 3,
  [int]$BurstCount = 10,
  [int]$BurstIntervalMs = 150
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

Write-Host "=== AC5 FullSync Crash Probe ==="
Write-Host "NodeCount=$NodeCount BasePort=$BasePort BurstCount=$BurstCount"

function RegisterDevice([string]$BaseUrl, [string]$Hw, [string]$Nama) {
  $body = @{
    hardware_id = $Hw
    name = $Nama
    user_name = $Nama
    app_version = "1.0.0"
  } | ConvertTo-Json
  $lastErr = $null
  for ($i=1; $i -le 3; $i++) {
    try {
      Invoke-RestMethod -Method POST -Uri "$BaseUrl/api/devices" -ContentType "application/json" -Body $body -TimeoutSec 30 | Out-Null
      return $true
    } catch {
      $lastErr = $_
      Start-Sleep -Seconds 2
    }
  }
  if ($lastErr) { throw $lastErr }
  return $false
}

function Is-NodeReachable([string]$BaseUrl) {
  try {
    $r = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/" -TimeoutSec 3
    return ($r.StatusCode -eq 200)
  } catch {
    return $false
  }
}

try {
  foreach ($n in $nodes) {
    Start-NodeProcess -ServerRoot $ServerRoot -DataDir $n.DataDir -Port $n.Port -NodeName $n.Name `
      -HeartbeatPort $n.HeartbeatPort -DiscoveryPort $n.DiscoveryPort -ControlPort $n.ControlPort `
      -HeartbeatTargets $hbTargets -BroadcastAddr "127.0.0.1" -ExtraEnv @{
        AKPI_ENABLE_COMPACTION_LOOP = "0"
        AKPI_ENABLE_DEVICE_DEDUPE = "0"
        AKPI_DISABLE_QUEUE_RETRY = "1"
        AKPI_DISABLE_WAITING_ROOM = "1"
      } | Out-Null
    Start-Sleep -Milliseconds 250
  }

  foreach ($n in $nodes) {
    if (-not (Wait-Healthy -BaseUrl $n.BaseUrl -TimeoutSec 40)) {
      throw "Node not healthy: $($n.Name) $($n.BaseUrl)"
    }
  }
  Write-Host "[OK] All nodes healthy"
  Start-Sleep -Seconds 8

  $hwByNode = @{}
  foreach ($n in $nodes) {
    $hw = "ac5-full-hw-$($n.Name)"
    $null = RegisterDevice -BaseUrl $n.BaseUrl -Hw $hw -Nama ("AC5FULL " + $n.Name)
    $hwByNode[$n.Name] = $hw
  }
  Write-Host "[OK] Seed register done"

  for ($i=0; $i -lt $BurstCount; $i++) {
    foreach ($n in $nodes) {
      $hw = [string]$hwByNode[$n.Name]
      try {
        $null = RegisterDevice -BaseUrl $n.BaseUrl -Hw $hw -Nama ("AC5FULL " + $n.Name)
      } catch {
        Write-Host "[WARN] request failed node=$($n.Name) err=$($_.Exception.Message)"
      }
    }
    if ($BurstIntervalMs -gt 0) { Start-Sleep -Milliseconds $BurstIntervalMs }
  }

  Start-Sleep -Seconds 5
  $down = @()
  foreach ($n in $nodes) {
    if (-not (Is-NodeReachable -BaseUrl $n.BaseUrl)) {
      $down += $n.Name
    }
  }

  if ($down.Count -eq 0) {
    Write-Host "[PASS] No node crashed in full-sync probe" -ForegroundColor Green
    exit 0
  } else {
    Write-Host "[FAIL] Nodes unreachable after probe: $($down -join ', ')" -ForegroundColor Red
    exit 1
  }
}
finally {
  Write-Host "`n=== Crash Tail ==="
  foreach ($n in $nodes) {
    $log = Join-Path $n.DataDir "node.log"
    if (Test-Path $log) {
      $txt = Get-Content -Path $log -Raw
      if ($txt -match "fatal runtime error|0xc0000409") {
        Write-Host "--- $($n.Name) ---" -ForegroundColor Yellow
        (Get-Content -Path $log | Select-String -Pattern "storage.ingest enter|storage.ingest applied|fatal runtime error|db_open_retry|db_open_failed" | Select-Object -Last 30).Line
      }
    }
  }
  foreach ($n in $nodes) {
    Stop-Node -Node $n | Out-Null
  }
}

