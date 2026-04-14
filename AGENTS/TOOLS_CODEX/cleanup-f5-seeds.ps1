param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [int]$TimeoutSec = 20,
  [int]$RetryCount = 3,
  [int]$RetryDelayMs = 800,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Section($msg) {
  Write-Host ""
  Write-Host "=== $msg ===" -ForegroundColor Cyan
}

function New-BaseUrlCandidates([string]$rawBaseUrl) {
  $base = $rawBaseUrl.TrimEnd("/")
  $list = New-Object System.Collections.Generic.List[string]
  if (-not [string]::IsNullOrWhiteSpace($base)) { [void]$list.Add($base) }
  if ($base -eq "http://127.0.0.1:3000") { [void]$list.Add("http://localhost:3000") }
  if ($base -eq "http://localhost:3000") { [void]$list.Add("http://127.0.0.1:3000") }
  return $list.ToArray()
}

function Invoke-WithRetry {
  param(
    [scriptblock]$Call,
    [int]$MaxRetry,
    [int]$DelayMs
  )
  $lastErr = $null
  for ($i = 1; $i -le $MaxRetry; $i++) {
    try {
      return & $Call
    } catch {
      $lastErr = $_
      if ($i -lt $MaxRetry) {
        Start-Sleep -Milliseconds $DelayMs
      }
    }
  }
  throw $lastErr
}

function Resolve-HealthyBaseUrl {
  param(
    [string[]]$Candidates,
    [int]$Timeout
  )
  foreach ($u in $Candidates) {
    try {
      $health = Invoke-WithRetry -MaxRetry $RetryCount -DelayMs $RetryDelayMs -Call {
        Invoke-WebRequest -UseBasicParsing -Uri "$u/" -TimeoutSec ([Math]::Min($Timeout, 8))
      }
      if ($health.StatusCode -eq 200) {
        Write-Host ("[OK] Healthy base URL: {0}" -f $u) -ForegroundColor Green
        return $u
      }
    } catch {
      Write-Warning ("[WARN] Health check gagal untuk {0}: {1}" -f $u, $_.Exception.Message)
    }
  }
  throw ("Tidak ada base URL sehat. Coba jalankan backend dulu. Candidates: {0}" -f ($Candidates -join ", "))
}

function Test-HealthQuick {
  param(
    [string]$Base,
    [int]$Timeout
  )
  try {
    $r = Invoke-WebRequest -UseBasicParsing -Uri "$Base/" -TimeoutSec ([Math]::Min($Timeout, 4))
    return ($r.StatusCode -eq 200)
  } catch {
    return $false
  }
}

Write-Section "Preflight health"
$baseCandidates = New-BaseUrlCandidates -rawBaseUrl $BaseUrl
$ActiveBaseUrl = Resolve-HealthyBaseUrl -Candidates $baseCandidates -Timeout $TimeoutSec

Write-Section "Fetch anggota"
$items = Invoke-WithRetry -MaxRetry $RetryCount -DelayMs $RetryDelayMs -Call {
  Invoke-RestMethod -Method GET -Uri "$ActiveBaseUrl/api/anggota" -TimeoutSec $TimeoutSec
}
if (-not ($items -is [System.Array])) {
  throw ("/api/anggota tidak mengembalikan array. base_url={0}" -f $ActiveBaseUrl)
}

$targets = $items | Where-Object {
  $nomor = [string]($_.nomor_anggota)
  $nama = [string]($_.nama)
  ($nomor -like "F5*") -or ($nama -like "F5*")
}

Write-Host ("Total anggota      : {0}" -f $items.Count)
Write-Host ("Target F5 detected : {0}" -f $targets.Count)

if ($targets.Count -eq 0) {
  Write-Host "[OK] Tidak ada seed F5 tersisa." -ForegroundColor Green
  exit 0
}

Write-Section "Soft cleanup (PATCH nonaktif)"
$ok = 0
$fail = 0

foreach ($t in $targets) {
  $id = [string]$t.id
  $namaVal = if ($null -ne $t.nama -and [string]::IsNullOrWhiteSpace([string]$t.nama) -eq $false) { [string]$t.nama } else { "F5 Gate User" }
  $roleVal = if ($null -ne $t.role -and [string]::IsNullOrWhiteSpace([string]$t.role) -eq $false) { [string]$t.role } else { "anggota" }
  $brevetVal = if ($null -ne $t.brevet -and [string]::IsNullOrWhiteSpace([string]$t.brevet) -eq $false) { [string]$t.brevet } else { "a" }
  $quotesVal = if ($null -ne $t.quotes -and [string]::IsNullOrWhiteSpace([string]$t.quotes) -eq $false) { [string]$t.quotes } else { "f5-cleanup" }
  $warnaVal = if ($null -ne $t.warna_card -and [string]::IsNullOrWhiteSpace([string]$t.warna_card) -eq $false) { [string]$t.warna_card } else { "linear-gradient(135deg,#0d4a2f,#2d8a55)" }
  $payload = @{
    nama = $namaVal
    role = $roleVal
    brevet = $brevetVal
    status = "nonaktif"
    quotes = $quotesVal
    warna_card = $warnaVal
  } | ConvertTo-Json

  if ($DryRun) {
    Write-Host ("[DRY] PATCH /api/anggota/{0}" -f $id)
    continue
  }

  try {
    Invoke-WithRetry -MaxRetry $RetryCount -DelayMs $RetryDelayMs -Call {
      Invoke-RestMethod -Method PATCH -Uri "$ActiveBaseUrl/api/anggota/$id" -ContentType "application/json" -Body $payload -TimeoutSec $TimeoutSec
    } | Out-Null
    $ok += 1
    Write-Host ("[OK] nonaktif: {0} ({1})" -f $id, $t.nomor_anggota) -ForegroundColor Green
  } catch {
    $fail += 1
    Write-Warning ("[FAIL] patch {0}: {1}" -f $id, $_.Exception.Message)
    $healthy = Test-HealthQuick -Base $ActiveBaseUrl -Timeout $TimeoutSec
    if (-not $healthy) {
      Write-Warning ("[STOP] Backend tidak sehat setelah patch gagal. Hentikan cleanup. Indikasi kuat proses server crash/restart.")
      break
    }
  }
}

Write-Section "Summary"
Write-Host ("Patched OK : {0}" -f $ok)
Write-Host ("Patch fail : {0}" -f $fail)

if ($fail -gt 0) { exit 1 }
