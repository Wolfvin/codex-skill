param(
  [string]$ServerUrl = "http://127.0.0.1:3000",
  [int]$TimeoutSec = 6
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg) {
  Write-Host "`n=== $msg ===" -ForegroundColor Cyan
}

function Invoke-JsonGet {
  param([string]$Url)
  try {
    $resp = Invoke-RestMethod -Method Get -Uri $Url -TimeoutSec $TimeoutSec
    return @{ ok = $true; status = 200; data = $resp; error = $null }
  } catch {
    $status = 0
    try { $status = [int]$_.Exception.Response.StatusCode } catch {}
    return @{ ok = $false; status = $status; data = $null; error = $_.Exception.Message }
  }
}

function Get-Count($value) {
  if ($null -eq $value) { return 0 }
  if ($value -is [System.Array]) { return $value.Count }
  if ($value.PSObject.Properties.Name -contains 'items' -and $value.items -is [System.Array]) { return $value.items.Count }
  if ($value -is [hashtable]) { return $value.Keys.Count }
  if ($value.PSObject -and $value.PSObject.Properties) { return $value.PSObject.Properties.Count }
  return 0
}

$targets = @(
  @{ key = 'stats';          path = '/api/stats' },
  @{ key = 'anggota';        path = '/api/anggota' },
  @{ key = 'announcements';  path = '/api/announcements' },
  @{ key = 'membersPreview'; path = '/api/dashboard/members-preview' },
  @{ key = 'activity';       path = '/api/dashboard/activity' },
  @{ key = 'deadlines';      path = '/api/dashboard/deadlines' }
)

Write-Step "Server Probe"
Write-Host "ServerUrl: $ServerUrl"

$results = @{}
foreach ($t in $targets) {
  $url = "$ServerUrl$($t.path)"
  $res = Invoke-JsonGet -Url $url
  $count = Get-Count $res.data
  $results[$t.key] = @{
    ok = $res.ok
    status = $res.status
    count = $count
    error = $res.error
  }
  if ($res.ok) {
    Write-Host ("[OK] {0,-14} status={1} count={2}" -f $t.key, $res.status, $count) -ForegroundColor Green
  } else {
    Write-Host ("[FAIL] {0,-14} status={1} err={2}" -f $t.key, $res.status, $res.error) -ForegroundColor Yellow
  }
}

Write-Step "Storage Snapshot (LocalAppData)"
$dataDir = Join-Path $env:LOCALAPPDATA "Smart Tax Assistance\server\lokal"
if (Test-Path $dataDir) {
  $indexDb = Join-Path $dataDir "index.db"
  $anggotaDir = Join-Path $dataDir "anggota"
  $annDir = Join-Path $dataDir "announcements"
  $ops = @(
    @{ key='index.db'; path=$indexDb },
    @{ key='anggota dir'; path=$anggotaDir },
    @{ key='announcements dir'; path=$annDir }
  )
  foreach ($o in $ops) {
    if (Test-Path $o.path) {
      if (Test-Path $o.path -PathType Leaf) {
        $size = (Get-Item $o.path).Length
        Write-Host ("[OK] {0,-18} exists size={1} bytes" -f $o.key, $size) -ForegroundColor Green
      } else {
        $files = (Get-ChildItem -Path $o.path -File -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Host ("[OK] {0,-18} exists files={1}" -f $o.key, $files) -ForegroundColor Green
      }
    } else {
      Write-Host ("[MISS] {0,-18} not found" -f $o.key) -ForegroundColor Yellow
    }
  }
} else {
  Write-Host "[MISS] Data dir not found: $dataDir" -ForegroundColor Yellow
}

Write-Step "Interpretasi Cepat"
$anggotaCount = $results['anggota'].count
$annCount = $results['announcements'].count
if ($results['anggota'].ok -and $results['announcements'].ok) {
  if ($anggotaCount -gt 0 -or $annCount -gt 0) {
    Write-Host "[INFO] Backend punya data. Jika UI kosong, kemungkinan besar masalah cache/init JS frontend." -ForegroundColor Cyan
  } else {
    Write-Host "[INFO] Backend endpoint hidup tapi data memang kosong (seed/ingest belum ada)." -ForegroundColor Cyan
  }
} else {
  Write-Host "[INFO] Endpoint penting gagal diakses. Fokus perbaiki koneksi/auth server dulu." -ForegroundColor Cyan
}

Write-Step "Perintah DevTools (jalankan di Console UI)"
Write-Host "await window.akp2iDebugAuthAndCache?.()"
Write-Host "await window.akp2iForceCacheHeal?.()"
Write-Host "location.reload()"

