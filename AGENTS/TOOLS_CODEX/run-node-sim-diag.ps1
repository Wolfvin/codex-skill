param(
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataRoot = "D:\Workspace\projects\akp2i_projects",
  [int]$NodeCount = 2,
  [int]$BasePort = 3100,
  [int]$BaseHeartbeatPort = 57732,
  [int]$UdpStride = 3,
  [int]$StartupDelaySec = 6,
  [int]$PostStartWaitSec = 8,
  [int]$TimeoutSec = 8,
  [int]$Limit = 200
)

. "$PSScriptRoot\node-sim-lib.ps1"

$nodes = Build-NodeList -NodeCount $NodeCount -BasePort $BasePort -DataRoot $DataRoot -BaseHeartbeatPort $BaseHeartbeatPort -UdpStride $UdpStride
$hbTargets = ($nodes | ForEach-Object { $_.HeartbeatPort }) -join ","

function Test-Health([string]$BaseUrl) {
  try {
    $resp = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/" -TimeoutSec 3
    return $resp.StatusCode -eq 200
  } catch {
    return $false
  }
}

function Get-SyncIndexSummary([string]$BaseUrl) {
  $url = "$BaseUrl/sync/index?since_seq=0&limit=$Limit"
  $resp = Invoke-RestMethod -Method GET -Uri $url -TimeoutSec $TimeoutSec
  $delta = @($resp.delta)
  $seqs = $delta | ForEach-Object { $_.server_seq }
  $maxSeq = if ($seqs.Count -gt 0) { ($seqs | Measure-Object -Maximum).Maximum } else { 0 }
  $minSeq = if ($seqs.Count -gt 0) { ($seqs | Measure-Object -Minimum).Minimum } else { 0 }
  $anggotaCount = @($delta | Where-Object { $_.collection -eq "anggota" }).Count
  return [pscustomobject]@{
    base_url = $BaseUrl
    delta_count = $delta.Count
    seq_min = $minSeq
    seq_max = $maxSeq
    next_since_seq = $resp.next_since_seq
    has_more = $resp.has_more
    server_timestamp = $resp.server_timestamp
    anggota_delta = $anggotaCount
  }
}

function Get-AnggotaCount([string]$BaseUrl) {
  try {
    $list = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/anggota" -TimeoutSec $TimeoutSec
    return @($list).Count
  } catch {
    return $null
  }
}

Write-Section "Start Nodes"
$udpPorts = @()
foreach ($n in $nodes) {
  $udpPorts += $n.HeartbeatPort
  $udpPorts += $n.ControlPort
  $udpPorts += $n.DiscoveryPort
}
$udpPorts = $udpPorts | Sort-Object -Unique
foreach ($p in $udpPorts) { Stop-NodeByUdpPort -Port $p | Out-Null }
foreach ($n in $nodes) {
  Stop-NodeProcess -DataDir $n.DataDir | Out-Null
  Stop-NodeByPort -Port $n.Port | Out-Null
  Start-NodeProcess -ServerRoot $ServerRoot -DataDir $n.DataDir -Port $n.Port -NodeName $n.Name `
    -HeartbeatPort $n.HeartbeatPort -DiscoveryPort $n.DiscoveryPort -ControlPort $n.ControlPort `
    -HeartbeatTargets $hbTargets -BroadcastAddr "127.0.0.1" -LogDir $n.DataDir | Out-Null
  Start-Sleep -Milliseconds 600
}
Start-Sleep -Seconds $StartupDelaySec
if ($PostStartWaitSec -gt 0) {
  Start-Sleep -Seconds $PostStartWaitSec
}

Write-Section "Health"
foreach ($n in $nodes) {
  $ok = Test-Health -BaseUrl $n.BaseUrl
  Write-Host "[INFO] $($n.Name) health=$ok url=$($n.BaseUrl)" -ForegroundColor Cyan
}

Write-Section "Sync Index Summary"
foreach ($n in $nodes) {
  if (Test-Health -BaseUrl $n.BaseUrl) {
    $sum = Get-SyncIndexSummary -BaseUrl $n.BaseUrl
    $sum | Format-List
  } else {
    Write-Host "[WARN] skip sync/index $($n.Name) (not healthy)" -ForegroundColor Yellow
  }
}

Write-Section "Peers"
foreach ($n in $nodes) {
  try {
    $resp = Invoke-RestMethod -Method GET -Uri "$($n.BaseUrl)/api/peers" -TimeoutSec $TimeoutSec
    $peers = if ($resp.peers) { $resp.peers } else { @() }
    $active = if ($resp.active_server) { $resp.active_server } else { "" }
    $summary = $peers | ForEach-Object { "$($_.ip):$($_.port) server=$($_.is_server) online=$($_.online)" }
    Write-Host "[INFO] $($n.Name) peers=$($summary -join '; ')" -ForegroundColor Cyan
    Write-Host "[INFO] $($n.Name) active_server=$active" -ForegroundColor Cyan
  } catch {
    Write-Host "[WARN] $($n.Name) peers fetch failed: $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

Write-Section "Anggota Count"
foreach ($n in $nodes) {
  $count = Get-AnggotaCount -BaseUrl $n.BaseUrl
  Write-Host "[INFO] $($n.Name) anggota_count=$count" -ForegroundColor Cyan
}

Write-Section "Stop Nodes"
foreach ($n in $nodes) {
  Stop-Node -Node $n | Out-Null
}
