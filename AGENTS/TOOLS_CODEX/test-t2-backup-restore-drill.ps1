param(
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataRoot = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\t2-backup-restore",
  [int]$BasePort = 3600,
  [int]$BaseHeartbeatPort = 52032
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\node-sim-lib.ps1"

$nodeA = [pscustomobject]@{
  Name = "nodeA"
  Port = $BasePort
  HeartbeatPort = $BaseHeartbeatPort
  ControlPort = $BaseHeartbeatPort + 1
  DiscoveryPort = $BaseHeartbeatPort + 2
  DataDir = Join-Path $DataRoot "nodeA"
  BaseUrl = "http://127.0.0.1:$BasePort"
}
$nodeB = [pscustomobject]@{
  Name = "nodeB"
  Port = $BasePort + 1
  HeartbeatPort = $BaseHeartbeatPort + 3
  ControlPort = $BaseHeartbeatPort + 4
  DiscoveryPort = $BaseHeartbeatPort + 5
  DataDir = Join-Path $DataRoot "nodeB"
  BaseUrl = "http://127.0.0.1:$($BasePort + 1)"
}
$backupDir = Join-Path $DataRoot "backup_nodeB"
$restoredDir = Join-Path $DataRoot "nodeB_restored"

if (Test-Path $DataRoot) {
  Remove-Item -LiteralPath $DataRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $DataRoot -Force | Out-Null

Write-Host "=== T2 Backup/Restore Drill ==="
Write-Host "NodeA=$($nodeA.BaseUrl) NodeB=$($nodeB.BaseUrl)"

function Get-Counts([string]$BaseUrl) {
  $devices = 0; $anggota = 0; $ann = 0
  try { $devices = @(Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/devices" -TimeoutSec 8).Count } catch {}
  try { $anggota = @(Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/anggota" -TimeoutSec 8).Count } catch {}
  try { $ann = @(Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/announcements" -TimeoutSec 8).Count } catch {}
  return [pscustomobject]@{ devices = $devices; anggota = $anggota; announcements = $ann }
}

try {
  $hbTargets = "$($nodeA.HeartbeatPort),$($nodeB.HeartbeatPort)"
  Start-NodeProcess -ServerRoot $ServerRoot -DataDir $nodeA.DataDir -Port $nodeA.Port -NodeName $nodeA.Name `
    -HeartbeatPort $nodeA.HeartbeatPort -DiscoveryPort $nodeA.DiscoveryPort -ControlPort $nodeA.ControlPort `
    -HeartbeatTargets $hbTargets -BroadcastAddr "127.0.0.1" -ExtraEnv @{ AKPI_ENABLE_COMPACTION_LOOP = "0" } | Out-Null
  Start-NodeProcess -ServerRoot $ServerRoot -DataDir $nodeB.DataDir -Port $nodeB.Port -NodeName $nodeB.Name `
    -HeartbeatPort $nodeB.HeartbeatPort -DiscoveryPort $nodeB.DiscoveryPort -ControlPort $nodeB.ControlPort `
    -HeartbeatTargets $hbTargets -BroadcastAddr "127.0.0.1" -ExtraEnv @{ AKPI_ENABLE_COMPACTION_LOOP = "0" } | Out-Null

  if (-not (Wait-Healthy -BaseUrl $nodeA.BaseUrl -TimeoutSec 45)) { throw "nodeA unhealthy" }
  if (-not (Wait-Healthy -BaseUrl $nodeB.BaseUrl -TimeoutSec 45)) { throw "nodeB unhealthy" }

  for ($i=0; $i -lt 12; $i++) {
    $hw = "t2-backup-hw-$i"
    $b = @{ hardware_id = $hw; app_version = "1.0.0" } | ConvertTo-Json
    try { Invoke-RestMethod -Method POST -Uri "$($nodeA.BaseUrl)/api/session/bootstrap" -ContentType "application/json" -Body $b -TimeoutSec 8 | Out-Null } catch {}
    try {
      $d = @{ hardware_id = $hw; name = "BKP $i"; user_name = "BKP $i"; app_version = "1.0.0" } | ConvertTo-Json
      Invoke-RestMethod -Method POST -Uri "$($nodeA.BaseUrl)/api/devices" -ContentType "application/json" -Body $d -TimeoutSec 8 | Out-Null
    } catch {}
  }
  Start-Sleep -Seconds 8

  Stop-Node -Node $nodeB | Out-Null
  Start-Sleep -Seconds 2
  Stop-NodeByPort -Port $nodeB.Port | Out-Null
  Stop-NodeByUdpPort -Port $nodeB.HeartbeatPort | Out-Null
  Stop-NodeByUdpPort -Port $nodeB.ControlPort | Out-Null
  Stop-NodeByUdpPort -Port $nodeB.DiscoveryPort | Out-Null
  Start-Sleep -Seconds 1
  New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
  Copy-Item -Path (Join-Path $nodeB.DataDir "*") -Destination $backupDir -Recurse -Force
  Write-Host "[OK] backup snapshot nodeB created: $backupDir"

  for ($i=12; $i -lt 24; $i++) {
    $hw = "t2-backup-hw-$i"
    $b = @{ hardware_id = $hw; app_version = "1.0.0" } | ConvertTo-Json
    try { Invoke-RestMethod -Method POST -Uri "$($nodeA.BaseUrl)/api/session/bootstrap" -ContentType "application/json" -Body $b -TimeoutSec 8 | Out-Null } catch {}
    try {
      $d = @{ hardware_id = $hw; name = "BKP $i"; user_name = "BKP $i"; app_version = "1.0.0" } | ConvertTo-Json
      Invoke-RestMethod -Method POST -Uri "$($nodeA.BaseUrl)/api/devices" -ContentType "application/json" -Body $d -TimeoutSec 8 | Out-Null
    } catch {}
  }

  if (Test-Path $restoredDir) { Remove-Item -LiteralPath $restoredDir -Recurse -Force }
  New-Item -ItemType Directory -Path $restoredDir -Force | Out-Null
  Copy-Item -Path (Join-Path $backupDir "*") -Destination $restoredDir -Recurse -Force
  $nodeB.DataDir = $restoredDir
  Write-Host "[OK] nodeB restored from snapshot to $restoredDir"

  Start-NodeProcess -ServerRoot $ServerRoot -DataDir $restoredDir -Port $nodeB.Port -NodeName $nodeB.Name `
    -HeartbeatPort $nodeB.HeartbeatPort -DiscoveryPort $nodeB.DiscoveryPort -ControlPort $nodeB.ControlPort `
    -HeartbeatTargets $hbTargets -BroadcastAddr "127.0.0.1" -ExtraEnv @{ AKPI_ENABLE_COMPACTION_LOOP = "0" } | Out-Null
  if (-not (Wait-Healthy -BaseUrl $nodeB.BaseUrl -TimeoutSec 45)) { throw "nodeB unhealthy after restore" }

  Start-Sleep -Seconds 15

  $aCount = Get-Counts -BaseUrl $nodeA.BaseUrl
  $bCount = Get-Counts -BaseUrl $nodeB.BaseUrl
  Write-Host "[nodeA] devices=$($aCount.devices) anggota=$($aCount.anggota) ann=$($aCount.announcements)"
  Write-Host "[nodeB] devices=$($bCount.devices) anggota=$($bCount.anggota) ann=$($bCount.announcements)"

  if ($bCount.devices -ge $aCount.devices -and $bCount.anggota -ge $aCount.anggota -and $bCount.announcements -ge $aCount.announcements) {
    Write-Host "[PASS] Backup/restore drill: nodeB recovered and re-sync OK." -ForegroundColor Green
    exit 0
  }

  Write-Host "[FAIL] nodeB belum catch-up setelah restore." -ForegroundColor Red
  exit 1
}
finally {
  Stop-Node -Node $nodeA | Out-Null
  Stop-Node -Node $nodeB | Out-Null
}
