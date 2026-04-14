param(
  [string]$BaseUrlA = "http://127.0.0.1:3000",
  [string]$BaseUrlB = "http://127.0.0.1:3001",
  [int]$TimeoutSec = 8,
  [int]$Limit = 200
)

function Write-Section([string]$title) {
  Write-Host "`n=== $title ===" -ForegroundColor Cyan
}

function Invoke-JsonGet([string]$Url, [int]$TimeoutSec = 8) {
  return Invoke-RestMethod -Method GET -Uri $Url -TimeoutSec $TimeoutSec
}

function Test-Health([string]$BaseUrl) {
  try {
    $resp = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/" -TimeoutSec 4
    return $resp.StatusCode -eq 200
  } catch {
    return $false
  }
}

function Get-SyncIndexSummary([string]$BaseUrl) {
  $url = "$BaseUrl/sync/index?since_seq=0&limit=$Limit"
  $resp = Invoke-JsonGet -Url $url -TimeoutSec $TimeoutSec
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
    $list = Invoke-JsonGet -Url "$BaseUrl/api/anggota" -TimeoutSec $TimeoutSec
    return @($list).Count
  } catch {
    return $null
  }
}

Write-Section "Sync Index Summary"
try {
  $okA = Test-Health -BaseUrl $BaseUrlA
  $okB = Test-Health -BaseUrl $BaseUrlB
  Write-Host "[INFO] health A=$okA B=$okB"
  if ($okA) {
    $sumA = Get-SyncIndexSummary -BaseUrl $BaseUrlA
    $sumA | Format-List
  } else {
    Write-Host "[WARN] skip sync/index A (not healthy)" -ForegroundColor Yellow
  }
  if ($okB) {
    $sumB = Get-SyncIndexSummary -BaseUrl $BaseUrlB
    $sumB | Format-List
  } else {
    Write-Host "[WARN] skip sync/index B (not healthy)" -ForegroundColor Yellow
  }
} catch {
  Write-Host "[FAIL] sync/index summary: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Section "Anggota Count"
$cntA = Get-AnggotaCount -BaseUrl $BaseUrlA
$cntB = Get-AnggotaCount -BaseUrl $BaseUrlB
Write-Host "[INFO] $BaseUrlA anggota_count=$cntA"
Write-Host "[INFO] $BaseUrlB anggota_count=$cntB"

Write-Section "Sync Range Probe"
try {
  if (Test-Health -BaseUrl $BaseUrlA) {
    $probeA = Invoke-JsonGet -Url "$BaseUrlA/sync/index/range?from_seq=1&to_seq=5" -TimeoutSec $TimeoutSec
    Write-Host "[OK] range A items=$(@($probeA.delta).Count)" -ForegroundColor Green
  } else {
    Write-Host "[WARN] skip range A (not healthy)" -ForegroundColor Yellow
  }
  if (Test-Health -BaseUrl $BaseUrlB) {
    $probeB = Invoke-JsonGet -Url "$BaseUrlB/sync/index/range?from_seq=1&to_seq=5" -TimeoutSec $TimeoutSec
    Write-Host "[OK] range B items=$(@($probeB.delta).Count)" -ForegroundColor Green
  } else {
    Write-Host "[WARN] skip range B (not healthy)" -ForegroundColor Yellow
  }
} catch {
  Write-Host "[WARN] sync/index/range gagal: $($_.Exception.Message)" -ForegroundColor Yellow
}
