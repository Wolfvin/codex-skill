param(
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataRoot = "D:\Workspace\projects\akp2i_projects",
  [int]$NodeCount = 2,
  [int]$BasePort = 3000,
  [int]$BaseHeartbeatPort = 47732,
  [int]$UdpStride = 3,
  [string]$BroadcastAddr = "127.0.0.1",
  [int]$WaitSec = 6
)

. "$PSScriptRoot\node-sim-lib.ps1"

$nodes = Build-NodeList -NodeCount $NodeCount -BasePort $BasePort -DataRoot $DataRoot -BaseHeartbeatPort $BaseHeartbeatPort -UdpStride $UdpStride
$hbTargets = ($nodes | ForEach-Object { $_.HeartbeatPort }) -join ","

Write-Section "Crash Diag Start"
$udpPorts = @()
foreach ($n in $nodes) {
  $udpPorts += $n.HeartbeatPort
  $udpPorts += $n.ControlPort
  $udpPorts += $n.DiscoveryPort
}
$udpPorts = $udpPorts | Sort-Object -Unique
Write-Host "[INFO] pre-clean UDP ports: $($udpPorts -join ',')" -ForegroundColor Yellow
foreach ($p in $udpPorts) {
  Stop-NodeByUdpPort -Port $p | Out-Null
}

foreach ($n in $nodes) {
  Write-Host "[INFO] restart $($n.Name) port=$($n.Port) hb=$($n.HeartbeatPort) ctrl=$($n.ControlPort) disc=$($n.DiscoveryPort)" -ForegroundColor Cyan
  Stop-NodeProcess -DataDir $n.DataDir | Out-Null
  Stop-NodeByPort -Port $n.Port | Out-Null
  Start-NodeProcess -ServerRoot $ServerRoot -DataDir $n.DataDir -Port $n.Port -NodeName $n.Name `
    -HeartbeatPort $n.HeartbeatPort -DiscoveryPort $n.DiscoveryPort -ControlPort $n.ControlPort `
    -HeartbeatTargets $hbTargets -BroadcastAddr $BroadcastAddr -LogDir $n.DataDir | Out-Null
  Start-Sleep -Seconds 1
}

Write-Section "Wait"
Start-Sleep -Seconds $WaitSec

Write-Section "Health + Last Log"
foreach ($n in $nodes) {
  $base = $n.BaseUrl
  $ok = $false
  try {
    $resp = Invoke-WebRequest -UseBasicParsing -Uri "$base/" -TimeoutSec 3
    $ok = $resp.StatusCode -eq 200
  } catch {}
  Write-Host "[INFO] $($n.Name) health=$ok url=$base" -ForegroundColor Cyan

  $logFile = Join-Path $n.DataDir "node.log"
  if (Test-Path $logFile) {
    Write-Host "--- tail $($n.Name) ($logFile) ---" -ForegroundColor Yellow
    Get-Content -Path $logFile -Tail 40
  } else {
    Write-Host "[WARN] log file not found: $logFile" -ForegroundColor Yellow
  }
}
