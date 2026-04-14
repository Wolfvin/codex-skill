param(
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataRoot = "D:\Workspace\projects\akp2i_projects",
  [int]$BasePort = 3000,
  [int]$NodeCount = 2,
  [int]$TimeoutSec = 8,
  [int]$BaseHeartbeatPort = 47732,
  [int]$UdpStride = 3,
  [string]$BroadcastAddr = "127.0.0.1",
  [switch]$AutoRestart,
  [switch]$ForceKillPort
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

Write-Section "Node Health"
foreach ($n in $nodes) {
  $ok = Test-Health -BaseUrl $n.BaseUrl
  $pidFileId = Get-NodePid -DataDir $n.DataDir
  $listen = Get-NetTCPConnection -LocalPort $n.Port -State Listen -ErrorAction SilentlyContinue
  $lp = if ($listen) { $listen.OwningProcess } else { $null }
  Write-Host "[INFO] $($n.Name) health=$ok port=$($n.Port) pid_file=$pidFileId pid_listen=$lp" -ForegroundColor Cyan

  if (-not $ok -and $AutoRestart) {
    if ($ForceKillPort) {
      Stop-NodeByPort -Port $n.Port | Out-Null
    }
    Write-Host "[INFO] restart $($n.Name)..." -ForegroundColor Yellow
    Start-NodeProcess -ServerRoot $ServerRoot -DataDir $n.DataDir -Port $n.Port -NodeName $n.Name `
      -HeartbeatPort $n.HeartbeatPort -DiscoveryPort $n.DiscoveryPort -ControlPort $n.ControlPort `
      -HeartbeatTargets $hbTargets -BroadcastAddr $BroadcastAddr | Out-Null
    Start-Sleep -Seconds 2
    $ok2 = Test-Health -BaseUrl $n.BaseUrl
    Write-Host "[INFO] $($n.Name) health_after_restart=$ok2" -ForegroundColor Cyan
  }
}
