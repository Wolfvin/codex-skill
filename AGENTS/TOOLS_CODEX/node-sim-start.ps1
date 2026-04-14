param(
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataRoot = "D:\Workspace\projects\akp2i_projects",
  [int]$NodeCount = 3,
  [int]$BasePort = 3000,
  [int]$BaseHeartbeatPort = 47732,
  [int]$UdpStride = 3,
  [string]$BroadcastAddr = "127.0.0.1",
  [int]$StartupDelaySec = 8,
  [switch]$KeepRunning,
  [switch]$SkipStart
)

. "$PSScriptRoot\node-sim-lib.ps1"

$nodes = Build-NodeList -NodeCount $NodeCount -BasePort $BasePort -DataRoot $DataRoot -BaseHeartbeatPort $BaseHeartbeatPort -UdpStride $UdpStride
$hbTargets = ($nodes | ForEach-Object { $_.HeartbeatPort }) -join ","

Write-Section "Start Nodes"
if (-not $SkipStart) {
  foreach ($n in $nodes) {
    Write-Host "[INFO] start $($n.Name) port=$($n.Port) hb=$($n.HeartbeatPort) ctrl=$($n.ControlPort) disc=$($n.DiscoveryPort) data=$($n.DataDir)"
    Start-NodeProcess -ServerRoot $ServerRoot -DataDir $n.DataDir -Port $n.Port -NodeName $n.Name -HeartbeatPort $n.HeartbeatPort -DiscoveryPort $n.DiscoveryPort -ControlPort $n.ControlPort -HeartbeatTargets $hbTargets -BroadcastAddr $BroadcastAddr | Out-Null
    Start-Sleep -Milliseconds 600
  }
  if ($StartupDelaySec -gt 0) {
    Write-Host "[INFO] wait ${StartupDelaySec}s for startup/compile..."
    Start-Sleep -Seconds $StartupDelaySec
  }
} else {
  Write-Host "[INFO] SkipStart aktif. Mengasumsikan node sudah berjalan."
}

Write-Section "Health Check"
foreach ($n in $nodes) {
  $ok = Wait-Healthy -BaseUrl $n.BaseUrl -TimeoutSec 20
  if ($ok) {
    Write-Host "[OK] $($n.BaseUrl) healthy" -ForegroundColor Green
  } else {
    Write-Host "[FAIL] $($n.BaseUrl) tidak sehat" -ForegroundColor Red
  }
}

Write-Section "Port Listen Check"
foreach ($n in $nodes) {
  $listen = Get-ListeningPort -Port $n.Port
  if ($listen) {
    Write-Host "[OK] port $($n.Port) LISTEN" -ForegroundColor Green
  } else {
    Write-Host "[WARN] port $($n.Port) tidak LISTEN. Kemungkinan AKPI_PORT belum didukung." -ForegroundColor Yellow
  }
}

if (-not $KeepRunning) {
  Write-Section "Stop Nodes"
  foreach ($n in $nodes) {
    if (Stop-NodeProcess -DataDir $n.DataDir) {
      Write-Host "[OK] stop $($n.Name)" -ForegroundColor Green
    } else {
      Write-Host "[WARN] gagal stop $($n.Name)" -ForegroundColor Yellow
    }
  }
}
