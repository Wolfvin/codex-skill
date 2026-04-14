param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataDir = "D:\Workspace\projects\akp2i_projects\_tmp_server_data_e3",
  [int]$HealthTimeoutSec = 90,
  [int]$ObserveSeconds = 75,
  [int]$SelfRegisterRuns = 5,
  [switch]$KeepBackendRunning
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Section($msg) {
  Write-Host ""
  Write-Host "=== $msg ===" -ForegroundColor Cyan
}

function Wait-Health([string]$Url, [int]$TimeoutSec) {
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $deadline) {
    try {
      $r = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 3
      if ($r.StatusCode -eq 200) { return $true }
    } catch {}
    Start-Sleep -Milliseconds 800
  }
  return $false
}

$stopScript = Join-Path $ServerRoot "SOP\41_stop_backend.ps1"
$runScript = Join-Path $ServerRoot "SOP\40_run_backend.ps1"
$smokeScript = Join-Path $PSScriptRoot "frontend-api-smoke.mjs"
if (-not (Test-Path $stopScript)) { throw "Stop script tidak ditemukan: $stopScript" }
if (-not (Test-Path $runScript)) { throw "Run script tidak ditemukan: $runScript" }
if (-not (Test-Path $smokeScript)) { throw "Smoke script tidak ditemukan: $smokeScript" }

New-Item -ItemType Directory -Force -Path $DataDir | Out-Null

$backendProc = $null
$backendLog = Join-Path $PSScriptRoot "phase-e3-backend.log"
$allOk = $true
$statusSamples = New-Object System.Collections.Generic.List[object]
$selfRegisterMs = New-Object System.Collections.Generic.List[int]
$createdAnggotaIds = New-Object System.Collections.Generic.List[string]

try {
  Write-Section "Stop Backend"
  powershell -ExecutionPolicy Bypass -File $stopScript

  Write-Section "Run Backend"
  if (Test-Path $backendLog) { Remove-Item $backendLog -Force }
  $cmd = "set AKPI_DATA_DIR=$DataDir&& powershell -ExecutionPolicy Bypass -File `"$runScript`" -RootDir `"$ServerRoot`" > `"$backendLog`" 2>&1"
  $backendProc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmd -WorkingDirectory $ServerRoot -PassThru

  Write-Section "Wait Health"
  if (-not (Wait-Health -Url "$BaseUrl/" -TimeoutSec $HealthTimeoutSec)) {
    throw "Backend tidak ready di $BaseUrl dalam $HealthTimeoutSec detik"
  }
  Write-Host "[OK] Health check 200"

  Write-Section "Smoke GET/POST"
  $env:SMOKE_BASE_URL = $BaseUrl
  $env:SMOKE_CLEANUP = "1"
  node $smokeScript
  if ($LASTEXITCODE -ne 0) {
    throw "frontend-api-smoke gagal dengan exit code $LASTEXITCODE"
  }

  Write-Section "Observe Election/Peer Cycle"
  $deadline = (Get-Date).AddSeconds($ObserveSeconds)
  while ((Get-Date) -lt $deadline) {
    $sample = [ordered]@{
      at = (Get-Date).ToString("HH:mm:ss")
      status_ok = $false
      is_server = $null
      peers_online = $null
    }
    try {
      $st = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/server/status" -TimeoutSec 5
      $sample.status_ok = $true
      $sample.is_server = [bool]$st.is_server
    } catch {
      $sample.status_ok = $false
      $allOk = $false
    }
    try {
      $peers = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/peers" -TimeoutSec 5
      if ($peers -is [System.Array]) {
        $sample.peers_online = ($peers | Measure-Object).Count
      }
    } catch {}
    $statusSamples.Add([pscustomobject]$sample)
    Start-Sleep -Seconds 5
  }

  Write-Section "Self-register Performance Check"
  for ($i = 1; $i -le $SelfRegisterRuns; $i++) {
    $hw = "e3-hw-$i-$([Guid]::NewGuid().ToString('N').Substring(0,8))"
    $payload = @{
      hardware_id = $hw
      nama = "E3 User $i"
      nomor_anggota = "E3TEST-$i-$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
      brevet = "a"
      quotes = "phase-e3-check"
      role = "anggota"
      status = "aktif"
    } | ConvertTo-Json

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $resp = Invoke-RestMethod -Method POST -Uri "$BaseUrl/api/anggota/self-register" -ContentType "application/json" -Body $payload -TimeoutSec 25
    $sw.Stop()
    $selfRegisterMs.Add([int]$sw.ElapsedMilliseconds)

    if (-not $resp.ok) {
      $allOk = $false
      Write-Warning ("Self-register run {0} gagal: {1}" -f $i, $resp.error)
    } else {
      if ($resp.id) { $createdAnggotaIds.Add([string]$resp.id) }
      Write-Host ("[OK] self-register run {0}: {1}ms" -f $i, [int]$sw.ElapsedMilliseconds)
    }
  }

  Write-Section "Cleanup E3 anggota"
  foreach ($id in $createdAnggotaIds) {
    try {
      Invoke-RestMethod -Method DELETE -Uri "$BaseUrl/api/anggota/$id" -TimeoutSec 10 | Out-Null
    } catch {}
  }

  Write-Section "Summary"
  $statusOkCount = ($statusSamples | Where-Object { $_.status_ok }).Count
  $statusTotal = $statusSamples.Count
  $isServerTrueCount = ($statusSamples | Where-Object { $_.is_server -eq $true }).Count
  $avgMs = if ($selfRegisterMs.Count -gt 0) { [int](($selfRegisterMs | Measure-Object -Average).Average) } else { -1 }
  $maxMs = if ($selfRegisterMs.Count -gt 0) { ($selfRegisterMs | Measure-Object -Maximum).Maximum } else { -1 }
  Write-Host ("status_ok: {0}/{1}" -f $statusOkCount, $statusTotal)
  Write-Host ("is_server=true samples: {0}" -f $isServerTrueCount)
  Write-Host ("self-register avg/max ms: {0}/{1}" -f $avgMs, $maxMs)
  if ($statusOkCount -eq 0 -or $isServerTrueCount -eq 0) { $allOk = $false }

  if ($allOk) {
    Write-Host "[SUCCESS] Phase E3 gate PASS." -ForegroundColor Green
  } else {
    throw "Phase E3 gate FAIL (lihat summary di atas)"
  }
}
finally {
  Remove-Item Env:SMOKE_BASE_URL -ErrorAction SilentlyContinue
  Remove-Item Env:SMOKE_CLEANUP -ErrorAction SilentlyContinue

  if (-not $KeepBackendRunning) {
    Write-Section "Stop Backend (Final)"
    powershell -ExecutionPolicy Bypass -File $stopScript
  } else {
    Write-Host "[INFO] Backend dibiarkan aktif (--KeepBackendRunning)." -ForegroundColor Yellow
  }

  if ($backendProc -and -not $backendProc.HasExited -and -not $KeepBackendRunning) {
    try { Stop-Process -Id $backendProc.Id -Force -ErrorAction SilentlyContinue } catch {}
  }

  if ((-not $allOk) -and (Test-Path $backendLog)) {
    Write-Section "Backend Log (tail)"
    Get-Content -Path $backendLog -Tail 120
  }
}
