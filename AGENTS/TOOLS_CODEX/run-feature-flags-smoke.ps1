param(
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataRoot = "D:\Workspace\projects\akp2i_projects",
  [int]$BasePort = 3200,
  [int]$BaseHeartbeatPort = 58732,
  [int]$UdpStride = 3,
  [int]$StartupDelaySec = 5,
  [int]$TimeoutSec = 8,
  [string]$BroadcastAddr = "127.0.0.1"
)

. "$PSScriptRoot\node-sim-lib.ps1"

$flags = @(
  "AKPI_DISABLE_HEARTBEAT_BROADCAST",
  "AKPI_DISABLE_HEARTBEAT_LISTENER",
  "AKPI_DISABLE_DISCOVERY_LISTENER",
  "AKPI_DISABLE_CONTROL_LISTENER",
  "AKPI_DISABLE_ELECTION_MONITOR",
  "AKPI_DISABLE_STORAGE_SYNC",
  "AKPI_DISABLE_QUEUE_RETRY"
)

Write-Section "Feature Flags Smoke"
$results = @()

for ($i = 0; $i -lt $flags.Count; $i++) {
  $flag = $flags[$i]
  $port = $BasePort + $i
  $hb = $BaseHeartbeatPort + ($i * $UdpStride)
  $n = [pscustomobject]@{
    Name = "flagtest-$i"
    Port = $port
    HeartbeatPort = $hb
    ControlPort = $hb + 1
    DiscoveryPort = $hb + 2
    DataDir = Join-Path $DataRoot ("flagtest-" + $i)
    BaseUrl = "http://127.0.0.1:$port"
  }

  $extra = @{
    $flag = "1"
    AKPI_NODE_NAME = "flagtest-$flag"
    AKPI_DEVICE_ID = "flagtest-$flag"
    AKPI_APP_KEY = "test-key"
    AKPI_IP = "127.0.0.1"
  }

  Stop-Node -Node $n | Out-Null
  Start-NodeProcess -ServerRoot $ServerRoot -DataDir $n.DataDir -Port $n.Port -NodeName $n.Name `
    -HeartbeatPort $n.HeartbeatPort -DiscoveryPort $n.DiscoveryPort -ControlPort $n.ControlPort `
    -HeartbeatTargets $n.HeartbeatPort -BroadcastAddr $BroadcastAddr -LogDir $n.DataDir `
    -ExtraEnv $extra | Out-Null

  if ($StartupDelaySec -gt 0) { Start-Sleep -Seconds $StartupDelaySec }

  $ok = Wait-Healthy -BaseUrl $n.BaseUrl -TimeoutSec $TimeoutSec
  if ($ok) {
    try {
      $status = Invoke-JsonGet -Url "$($n.BaseUrl)/api/server/status" -TimeoutSec 6
      $results += [pscustomobject]@{ flag = $flag; ok = $true; is_server = $status.is_server }
      Write-Host "[OK] $flag healthy" -ForegroundColor Green
    } catch {
      $results += [pscustomobject]@{ flag = $flag; ok = $true; is_server = $null }
      Write-Host "[WARN] $flag healthy, status fetch failed" -ForegroundColor Yellow
    }
  } else {
    $results += [pscustomobject]@{ flag = $flag; ok = $false; is_server = $null }
    Write-Host "[FAIL] $flag health check gagal" -ForegroundColor Red
  }

  Stop-Node -Node $n | Out-Null
  Start-Sleep -Milliseconds 400
}

Write-Section "Summary"
$results | Format-Table -AutoSize
