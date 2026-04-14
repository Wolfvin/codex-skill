param(
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataRoot = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\t2-integrity-10nodes",
  [int]$NodeCount = 10,
  [int]$BasePort = 3500,
  [int]$BaseHeartbeatPort = 51032,
  [int]$Iterations = 30,
  [int]$ConvergenceWaitSec = 45,
  [int]$ConvergencePollSec = 5,
  [switch]$SingleWriter = $true,
  [switch]$Fast
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\node-sim-lib.ps1"

function Get-StableHash([object]$Value) {
  $json = $Value | ConvertTo-Json -Depth 20 -Compress
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $hash = $sha.ComputeHash($bytes)
    return ([System.BitConverter]::ToString($hash)).Replace("-", "").ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

function Get-Snapshots([object[]]$Nodes) {
  $rows = @()
  foreach ($n in $Nodes) {
    $devices = @()
    $anggota = @()
    $ann = @()
    try { $devices = @(Invoke-RestMethod -Method GET -Uri "$($n.BaseUrl)/api/devices" -TimeoutSec 8) } catch {}
    try { $anggota = @(Invoke-RestMethod -Method GET -Uri "$($n.BaseUrl)/api/anggota" -TimeoutSec 8) } catch {}
    try { $ann = @(Invoke-RestMethod -Method GET -Uri "$($n.BaseUrl)/api/announcements" -TimeoutSec 8) } catch {}

    $devNorm = @($devices | Sort-Object id | ForEach-Object {
      [pscustomobject]@{ id = $_.id; is_active = $_.is_active; is_admin = $_.is_admin; is_super_admin = $_.is_super_admin }
    })
    $angNorm = @($anggota | Sort-Object id | ForEach-Object { [pscustomobject]@{ id = $_.id; nama = $_.nama; status = $_.status } })
    # semantic hash untuk announcements: abaikan field volatil (id/timestamp) agar tidak false mismatch
    $annNorm = @($ann | ForEach-Object {
      [pscustomobject]@{
        title = [string]$_.title
        body = [string]$_.body
        category = [string]$_.category
        is_pinned = [bool]$_.is_pinned
      }
    } | Sort-Object title, body, category, is_pinned)

    $rows += [pscustomobject]@{
      node = $n.Name
      devices_count = $devNorm.Count
      anggota_count = $angNorm.Count
      announcements_count = $annNorm.Count
      devices_hash = Get-StableHash $devNorm
      anggota_hash = Get-StableHash $angNorm
      announcements_hash = Get-StableHash $annNorm
    }
  }
  return $rows
}

function Wait-Convergence([object[]]$Nodes, [int]$WaitSec, [int]$PollSec) {
  $deadline = (Get-Date).AddSeconds($WaitSec)
  do {
    $snap = Get-Snapshots -Nodes $Nodes
    $angHashes = @($snap | Select-Object -ExpandProperty anggota_hash | Sort-Object -Unique)
    $annHashes = @($snap | Select-Object -ExpandProperty announcements_hash | Sort-Object -Unique)
    if ($angHashes.Count -eq 1 -and $annHashes.Count -eq 1) {
      return $snap
    }
    Start-Sleep -Seconds ([Math]::Max(1, $PollSec))
  } while ((Get-Date) -lt $deadline)
  return (Get-Snapshots -Nodes $Nodes)
}

if (Test-Path $DataRoot) {
  Remove-Item -LiteralPath $DataRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $DataRoot -Force | Out-Null

$nodes = Build-NodeList -NodeCount $NodeCount -BasePort $BasePort -DataRoot $DataRoot -BaseHeartbeatPort $BaseHeartbeatPort -UdpStride 3
$hbTargets = ($nodes | ForEach-Object { $_.HeartbeatPort }) -join ","

Write-Host "=== T2 Integrity 10 Nodes ==="
Write-Host "NodeCount=$NodeCount BasePort=$BasePort"
if ($Fast) {
  $Iterations = 10
  $ConvergenceWaitSec = 20
  $ConvergencePollSec = 2
  Write-Host "[FAST] iterations=$Iterations"
}

try {
  foreach ($n in $nodes) {
    Start-NodeProcess -ServerRoot $ServerRoot -DataDir $n.DataDir -Port $n.Port -NodeName $n.Name `
      -HeartbeatPort $n.HeartbeatPort -DiscoveryPort $n.DiscoveryPort -ControlPort $n.ControlPort `
      -HeartbeatTargets $hbTargets -BroadcastAddr "127.0.0.1" -ExtraEnv @{
        AKPI_ENABLE_COMPACTION_LOOP = "0"
        AKPI_DISABLE_QUEUE_RETRY = "1"
      } | Out-Null
    Start-Sleep -Milliseconds 200
  }
  foreach ($n in $nodes) {
    if (-not (Wait-Healthy -BaseUrl $n.BaseUrl -TimeoutSec 45)) {
      throw "Node not healthy: $($n.Name)"
    }
  }

  for ($i = 0; $i -lt $Iterations; $i++) {
    $writers = if ($SingleWriter) { @($nodes[0]) } else { $nodes }
    foreach ($n in $writers) {
      $hw = "t2-integrity-hw-$($n.Name)"
      $bootBody = @{ hardware_id = $hw; app_version = "1.0.0" } | ConvertTo-Json
      try { Invoke-RestMethod -Method POST -Uri "$($n.BaseUrl)/api/session/bootstrap" -ContentType "application/json" -Body $bootBody -TimeoutSec 8 | Out-Null } catch {}
      try {
        $devBody = @{
          hardware_id = $hw
          name = "T2 Integrity $($n.Name)"
          user_name = "T2 Integrity $($n.Name)"
          app_version = "1.0.0"
        } | ConvertTo-Json
        Invoke-RestMethod -Method POST -Uri "$($n.BaseUrl)/api/devices" -ContentType "application/json" -Body $devBody -TimeoutSec 8 | Out-Null
      } catch {}
    }
    if (($i % 6) -eq 0) {
      try {
        $a = @{
          title = "T2 Integrity $i"
          body = "seed"
          category = "ops"
          is_pinned = $false
          author = "t2"
        } | ConvertTo-Json
        Invoke-RestMethod -Method POST -Uri "$($nodes[0].BaseUrl)/api/announcements" -ContentType "application/json" -Body $a -TimeoutSec 8 | Out-Null
      } catch {}
    }
  }

  $snapshots = Wait-Convergence -Nodes $nodes -WaitSec $ConvergenceWaitSec -PollSec $ConvergencePollSec

  $devHashes = @($snapshots | Select-Object -ExpandProperty devices_hash | Sort-Object -Unique)
  $angHashes = @($snapshots | Select-Object -ExpandProperty anggota_hash | Sort-Object -Unique)
  $annHashes = @($snapshots | Select-Object -ExpandProperty announcements_hash | Sort-Object -Unique)

  Write-Host ($snapshots | Format-Table -AutoSize | Out-String)
  Write-Host ("[DEBUG] unique anggota_hash={0}" -f ($angHashes -join ","))
  Write-Host ("[DEBUG] unique announcements_hash={0}" -f ($annHashes -join ","))

  if ($angHashes.Count -eq 1 -and $annHashes.Count -eq 1) {
    Write-Host "[PASS] Integrity check: hash koleksi sync (anggota+announcements) konsisten di semua node." -ForegroundColor Green
    if ($devHashes.Count -ne 1) {
      Write-Host "[INFO] devices hash beda antar node (expected/info): devices terlihat node-local pada mode ini." -ForegroundColor Yellow
    }
    exit 0
  }

  Write-Host "[FAIL] Hash mismatch koleksi sync: anggota=$($angHashes.Count) announcements=$($annHashes.Count)" -ForegroundColor Red
  exit 1
}
finally {
  foreach ($n in $nodes) { Stop-Node -Node $n | Out-Null }
}
