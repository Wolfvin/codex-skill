param(
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataRoot = "D:\Workspace\projects\akp2i_projects",
  [int]$NodeCount = 3,
  [int]$BasePort = 3000,
  [int]$BaseHeartbeatPort = 47732,
  [int]$UdpStride = 3,
  [string]$BroadcastAddr = "127.0.0.1",
  [int]$TimeoutSec = 30,
  [int]$StartupDelaySec = 8,
  [switch]$SkipStart,
  [switch]$SkipStop,
  [switch]$SkipFailover
)

. "$PSScriptRoot\node-sim-lib.ps1"

$nodes = Build-NodeList -NodeCount $NodeCount -BasePort $BasePort -DataRoot $DataRoot -BaseHeartbeatPort $BaseHeartbeatPort -UdpStride $UdpStride
$hbTargets = ($nodes | ForEach-Object { $_.HeartbeatPort }) -join ","
$nodeA = $nodes[0]
$nodeB = if ($nodes.Count -gt 1) { $nodes[1] } else { $null }
$nodeC = if ($nodes.Count -gt 2) { $nodes[2] } else { $null }

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
}

Write-Section "Health Check"
foreach ($n in $nodes) {
  $ok = Wait-Healthy -BaseUrl $n.BaseUrl -TimeoutSec $TimeoutSec
  if ($ok) { Write-Host "[OK] $($n.BaseUrl) healthy" -ForegroundColor Green }
  else { Write-Host "[FAIL] $($n.BaseUrl) tidak sehat" -ForegroundColor Red }
}

Write-Section "Peers"
foreach ($n in $nodes) {
  try {
    $peers = Invoke-JsonGet -Url "$($n.BaseUrl)/api/peers" -TimeoutSec 6
    $list = if ($peers.peers) { $peers.peers } elseif ($peers.items) { $peers.items } else { $peers }
    $count = if ($list) { @($list).Count } else { 0 }
    Write-Host "[OK] $($n.Name) peers=$count" -ForegroundColor Green
  } catch {
    Write-Host "[WARN] $($n.Name) peers gagal: $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

Write-Section "Seed Data (server node A)"
$seedAnggotaId = $null
$seedAnnId = $null
try {
  $payload = @{
    nama = "Sim User $(Get-Date -Format 'HHmmss')"
    nomor_anggota = "SIM-$(Get-Random -Minimum 100 -Maximum 999)"
    role = "anggota"
    brevet = "a"
    status = "aktif"
    quotes = "node-sim"
    warna_card = "linear-gradient(135deg,#0d4a2f,#2d8a55)"
  }
  $res = Invoke-JsonPost -Url "$($nodeA.BaseUrl)/api/anggota" -Body $payload -TimeoutSec 8
  $seedAnggotaId = $res.id
  if (-not $seedAnggotaId) {
    try {
      $list = Invoke-JsonGet -Url "$($nodeA.BaseUrl)/api/anggota" -TimeoutSec 8
      $last = $list | Select-Object -Last 1
      $seedAnggotaId = $last.id
    } catch {}
  }
  Write-Host "[OK] anggota seed id=$seedAnggotaId" -ForegroundColor Green
} catch {
  Write-Host "[WARN] create anggota gagal: $($_.Exception.Message)" -ForegroundColor Yellow
}

try {
  $payload = @{
    title = "Sim Announcement $(Get-Date -Format 'HHmmss')"
    body = "node-sim"
    category = "Info"
    is_pinned = $false
    author = "node-sim"
  }
  $res = Invoke-JsonPost -Url "$($nodeA.BaseUrl)/api/announcements" -Body $payload -TimeoutSec 8
  $seedAnnId = $res.id
  if (-not $seedAnnId) {
    try {
      $list = Invoke-JsonGet -Url "$($nodeA.BaseUrl)/api/announcements" -TimeoutSec 8
      $last = $list | Select-Object -Last 1
      $seedAnnId = $last.id
    } catch {}
  }
  Write-Host "[OK] announcement seed id=$seedAnnId" -ForegroundColor Green
} catch {
  $msg = $_.Exception.Message
  if ($msg -match "404" -or $msg -match "Not Found") {
    Write-Host "[SKIP] announcements endpoint tidak tersedia" -ForegroundColor DarkYellow
  } else {
    Write-Host "[WARN] create announcement gagal: $msg" -ForegroundColor Yellow
  }
}

Start-Sleep -Seconds 12

Write-Section "Verify Sync (B/C)"
$targets = @()
if ($nodeB) { $targets += $nodeB }
if ($nodeC) { $targets += $nodeC }
foreach ($n in $targets) {
  try {
    $list = Invoke-JsonGet -Url "$($n.BaseUrl)/api/anggota" -TimeoutSec 8
    $count = @($list).Count
    Write-Host "[OK] $($n.Name) anggota count=$count" -ForegroundColor Green
  } catch {
    Write-Host "[WARN] $($n.Name) anggota gagal: $($_.Exception.Message)" -ForegroundColor Yellow
  }
  try {
    $sync = Invoke-JsonGet -Url "$($n.BaseUrl)/sync/index?since_seq=0&limit=5" -TimeoutSec 8
    Write-Host "[OK] $($n.Name) sync/index ok" -ForegroundColor Green
  } catch {
    Write-Host "[WARN] $($n.Name) sync/index gagal: $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

if (-not $SkipFailover -and $nodeB) {
  Write-Section "Failover"
  if (Stop-Node -Node $nodeA) {
    Write-Host "[OK] stop nodeA" -ForegroundColor Green
  } else {
    Write-Host "[WARN] gagal stop nodeA" -ForegroundColor Yellow
  }
  $promoted = $false
  $sw = [Diagnostics.Stopwatch]::StartNew()
  while ($sw.Elapsed.TotalSeconds -lt 20) {
    try {
      $status = Invoke-JsonGet -Url "$($nodeB.BaseUrl)/api/server/status" -TimeoutSec 6
      Write-Host "[INFO] nodeB status: $($status | ConvertTo-Json -Compress)" -ForegroundColor Cyan
      if ($status.is_server -eq $true) { $promoted = $true; break }
    } catch {
      Write-Host "[WARN] nodeB status gagal: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 3
  }
  if (-not $promoted) {
    Write-Host "[WARN] nodeB belum promote (cek election/heartbeat)" -ForegroundColor Yellow
  }
}

Write-Section "Cleanup seeds"
$cleanupBaseUrl = $nodeA.BaseUrl
try {
  $health = Wait-Healthy -BaseUrl $cleanupBaseUrl -TimeoutSec 4
  if (-not $health -and $nodeB) { $cleanupBaseUrl = $nodeB.BaseUrl }
} catch {
  if ($nodeB) { $cleanupBaseUrl = $nodeB.BaseUrl }
}
if ($seedAnggotaId) {
  try {
    Invoke-JsonDelete -Url "$cleanupBaseUrl/api/anggota/$seedAnggotaId" -TimeoutSec 8 | Out-Null
    Write-Host "[OK] delete anggota $seedAnggotaId" -ForegroundColor Green
  } catch {
    Write-Host "[WARN] delete anggota gagal: $($_.Exception.Message)" -ForegroundColor Yellow
  }
}
if ($seedAnnId) {
  try {
    Invoke-JsonDelete -Url "$cleanupBaseUrl/api/announcements/$seedAnnId" -TimeoutSec 8 | Out-Null
    Write-Host "[OK] delete announcement $seedAnnId" -ForegroundColor Green
  } catch {
    Write-Host "[WARN] delete announcement gagal: $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

if (-not $SkipStop) {
  Write-Section "Stop Nodes"
  foreach ($n in $nodes) {
    if (Stop-Node -Node $n) {
      Write-Host "[OK] stop $($n.Name)" -ForegroundColor Green
    } else {
      Write-Host "[WARN] gagal stop $($n.Name)" -ForegroundColor Yellow
    }
  }
}
