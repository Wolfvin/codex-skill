# Node Simulation Helpers

function Write-Section([string]$title) {
  Write-Host "`n=== $title ===" -ForegroundColor Cyan
}

function Invoke-JsonGet([string]$Url, [int]$TimeoutSec = 8) {
  return Invoke-RestMethod -Method GET -Uri $Url -TimeoutSec $TimeoutSec
}

function Invoke-JsonPost([string]$Url, [object]$Body, [int]$TimeoutSec = 8) {
  $json = $Body | ConvertTo-Json -Depth 6
  return Invoke-RestMethod -Method POST -Uri $Url -ContentType 'application/json' -Body $json -TimeoutSec $TimeoutSec
}

function Invoke-JsonDelete([string]$Url, [int]$TimeoutSec = 8) {
  return Invoke-RestMethod -Method DELETE -Uri $Url -TimeoutSec $TimeoutSec
}

function Wait-Healthy([string]$BaseUrl, [int]$TimeoutSec = 20) {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/" -TimeoutSec 3
      if ($resp.StatusCode -eq 200) { return $true }
    } catch {}
    Start-Sleep -Milliseconds 400
  }
  return $false
}

function Get-ListeningPort([int]$Port) {
  try {
    $c = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop
    return $c
  } catch {
    return $null
  }
}

function Start-NodeProcess(
  [string]$ServerRoot,
  [string]$DataDir,
  [int]$Port,
  [string]$NodeName,
  [int]$HeartbeatPort,
  [int]$DiscoveryPort,
  [int]$ControlPort,
  [string]$HeartbeatTargets,
  [string]$BroadcastAddr = "127.0.0.1",
  [string]$LogDir = "",
  [int]$ElectionReconcileSec = 5,
  [hashtable]$ExtraEnv = $null
) {
  if (!(Test-Path $DataDir)) { New-Item -ItemType Directory -Path $DataDir | Out-Null }
  if ([string]::IsNullOrWhiteSpace($LogDir)) { $LogDir = $DataDir }
  if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
  $logFile = Join-Path $LogDir "node.log"
  $exe = Join-Path $ServerRoot "target\\debug\\akp2i-server.exe"
  $runner = Join-Path $LogDir "run-node.cmd"
  $lines = @(
    "@echo off",
    "set AKPI_DATA_DIR=$DataDir",
    "set AKPI_PORT=$Port",
    "set AKPI_NODE_NAME=$NodeName",
    "set AKPI_DEVICE_ID=$NodeName-$Port",
    "set AKPI_HEARTBEAT_PORT=$HeartbeatPort",
    "set AKPI_DISCOVERY_PORT=$DiscoveryPort",
    "set AKPI_CONTROL_PORT=$ControlPort",
    "set AKPI_HEARTBEAT_TARGET_PORTS=$HeartbeatTargets",
    "set BROADCAST_ADDR=$BroadcastAddr",
    "set AKPI_ELECTION_RECONCILE_SECS=$ElectionReconcileSec",
    "set RUST_LOG=info"
  )
  if ($ExtraEnv) {
    foreach ($k in $ExtraEnv.Keys) {
      $lines += ("set {0}={1}" -f $k, $ExtraEnv[$k])
    }
  }
  if (Test-Path $exe) {
    $lines += "`"$exe`" 1>`"$logFile`" 2>&1"
  } else {
    $lines += "cargo run 1>`"$logFile`" 2>&1"
  }
  Set-Content -Path $runner -Value $lines -Encoding ASCII
  $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $runner -WorkingDirectory $ServerRoot -PassThru
  $pidFile = Join-Path $DataDir "node.pid"
  Set-Content -Path $pidFile -Value $proc.Id
  # Try to resolve actual server PID via TCP listener on Port
  $resolvedPid = $null
  $sw = [Diagnostics.Stopwatch]::StartNew()
  while ($sw.Elapsed.TotalSeconds -lt 12) {
    try {
      $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop | Select-Object -First 1
      if ($conn -and $conn.OwningProcess) {
        $resolvedPid = $conn.OwningProcess
        break
      }
    } catch {}
    Start-Sleep -Milliseconds 300
  }
  if ($resolvedPid) {
    Set-Content -Path $pidFile -Value $resolvedPid
  }
  $meta = [pscustomobject]@{
    port = $Port
    heartbeat_port = $HeartbeatPort
    discovery_port = $DiscoveryPort
    control_port = $ControlPort
    node_name = $NodeName
    pid = if ($resolvedPid) { $resolvedPid } else { $proc.Id }
  }
  $metaFile = Join-Path $DataDir "node.meta.json"
  $meta | ConvertTo-Json -Depth 4 | Set-Content -Path $metaFile -Encoding ASCII
  return $proc.Id
}

function Stop-NodeProcess([string]$DataDir) {
  $pidFile = Join-Path $DataDir "node.pid"
  if (!(Test-Path $pidFile)) { return $false }
  $procId = Get-Content $pidFile | Select-Object -First 1
  if ($procId) {
    try {
      Stop-Process -Id $procId -Force -ErrorAction Stop
      Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
      return $true
    } catch {
      return $false
    }
  }
  return $false
}

function Read-NodeMeta([string]$DataDir) {
  $metaFile = Join-Path $DataDir "node.meta.json"
  if (!(Test-Path $metaFile)) { return $null }
  try {
    return Get-Content $metaFile -Raw | ConvertFrom-Json
  } catch {
    return $null
  }
}

function Stop-Node([object]$Node) {
  $stopped = $false
  if ($Node -and $Node.DataDir) {
    if (Stop-NodeProcess -DataDir $Node.DataDir) { $stopped = $true }
    $meta = Read-NodeMeta -DataDir $Node.DataDir
    $port = if ($Node.Port) { $Node.Port } elseif ($meta.port) { [int]$meta.port } else { $null }
    $hb = if ($Node.HeartbeatPort) { $Node.HeartbeatPort } elseif ($meta.heartbeat_port) { [int]$meta.heartbeat_port } else { $null }
    $ctrl = if ($Node.ControlPort) { $Node.ControlPort } elseif ($meta.control_port) { [int]$meta.control_port } else { $null }
    $disc = if ($Node.DiscoveryPort) { $Node.DiscoveryPort } elseif ($meta.discovery_port) { [int]$meta.discovery_port } else { $null }
    if ($port) { if (Stop-NodeByPort -Port $port) { $stopped = $true } }
    if ($hb) { if (Stop-NodeByUdpPort -Port $hb) { $stopped = $true } }
    if ($ctrl) { if (Stop-NodeByUdpPort -Port $ctrl) { $stopped = $true } }
    if ($disc) { if (Stop-NodeByUdpPort -Port $disc) { $stopped = $true } }
    if (-not $stopped) {
      $pidFile = Join-Path $Node.DataDir "node.pid"
      $nodePid = if (Test-Path $pidFile) { (Get-Content $pidFile | Select-Object -First 1) } else { $null }
      $pidAlive = $false
      if ($nodePid) { $pidAlive = (Get-Process -Id $nodePid -ErrorAction SilentlyContinue) -ne $null }
      $portAlive = $false
      if ($port) {
        try { $portAlive = (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction Stop) -ne $null } catch {}
      }
      if (-not $pidAlive -and -not $portAlive) { $stopped = $true }
    }
  }
  return $stopped
}

function Stop-NodeByPort([int]$Port) {
  try {
    $conns = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop
    $pids = $conns.OwningProcess | Sort-Object -Unique
    foreach ($pid in $pids) {
      try {
        Stop-Process -Id $pid -Force -ErrorAction Stop
        Write-Host "[OK] stop pid=$pid port=$Port" -ForegroundColor Green
      } catch {
        Write-Host "[WARN] gagal stop pid=$pid port=${Port}: $($_.Exception.Message)" -ForegroundColor Yellow
      }
    }
    if ($pids.Count -gt 0) { return $true }
  } catch {}
  return $false
}

function Stop-NodeByUdpPort([int]$Port) {
  try {
    $eps = Get-NetUDPEndpoint -LocalPort $Port -ErrorAction Stop
    $pids = $eps.OwningProcess | Sort-Object -Unique
    foreach ($pid in $pids) {
      try {
        Stop-Process -Id $pid -Force -ErrorAction Stop
        Write-Host "[OK] stop pid=$pid udp_port=$Port" -ForegroundColor Green
      } catch {
        Write-Host "[WARN] gagal stop pid=$pid udp_port=${Port}: $($_.Exception.Message)" -ForegroundColor Yellow
      }
    }
    if ($pids.Count -gt 0) { return $true }
  } catch {}
  return $false
}

function Get-NodePid([string]$DataDir) {
  $pidFile = Join-Path $DataDir "node.pid"
  if (!(Test-Path $pidFile)) { return $null }
  $procId = Get-Content $pidFile | Select-Object -First 1
  return $procId
}

function Build-NodeList(
  [int]$NodeCount,
  [int]$BasePort,
  [string]$DataRoot,
  [int]$BaseHeartbeatPort = 47732,
  [int]$UdpStride = 3
) {
  $nodes = @()
  for ($i=0; $i -lt $NodeCount; $i++) {
    $name = [char]([int][char]'A' + $i)
    $hb = $BaseHeartbeatPort + ($i * $UdpStride)
    $nodes += [pscustomobject]@{
      Name = "node$name"
      Port = $BasePort + $i
      HeartbeatPort = $hb
      ControlPort = $hb + 1
      DiscoveryPort = $hb + 2
      DataDir = Join-Path $DataRoot "node$name"
      BaseUrl = "http://127.0.0.1:$($BasePort + $i)"
    }
  }
  return $nodes
}

