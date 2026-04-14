param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [int]$HealthTimeoutSec = 90,
  [int]$LoopCount = 20,
  [switch]$AutoStartBackend,
  [switch]$SkipRestartCycle,
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

function Expect-ConnectionRefused([string]$Url) {
  try {
    Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 3 | Out-Null
    return $false
  } catch {
    return $true
  }
}

$stopScript = Join-Path $ServerRoot "SOP\41_stop_backend.ps1"
$runScript = Join-Path $ServerRoot "SOP\40_run_backend.ps1"
if (-not (Test-Path $stopScript)) { throw "Stop script tidak ditemukan: $stopScript" }
if (-not (Test-Path $runScript)) { throw "Run script tidak ditemukan: $runScript" }

$backendLog = Join-Path $PSScriptRoot "phase-f5-backend.log"
$backendProc = $null
$allOk = $true
$createdId = $null
$createdNomor = $null
$createdSeed = $null
$baselineCount = 0

function Start-BackendBackground([string]$RunScript, [string]$Root, [string]$LogPath) {
  try { Get-Process akp2i-server -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue } catch {}
  powershell -ExecutionPolicy Bypass -File $stopScript | Out-Null
  Start-Sleep -Milliseconds 700
  if (Test-Path $LogPath) { Remove-Item $LogPath -Force }
  $cmd = "powershell -ExecutionPolicy Bypass -File `"$RunScript`" -RootDir `"$Root`" > `"$LogPath`" 2>&1"
  return Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmd -WorkingDirectory $Root -PassThru
}

try {
  Write-Section "F5-1 Online Baseline"
  if (-not (Wait-Health -Url "$BaseUrl/" -TimeoutSec 8)) {
    if ($AutoStartBackend) {
      Write-Host "[INFO] Backend belum ready, auto-start dijalankan..." -ForegroundColor Yellow
      $backendProc = Start-BackendBackground -RunScript $runScript -Root $ServerRoot -LogPath $backendLog
      if (-not (Wait-Health -Url "$BaseUrl/" -TimeoutSec $HealthTimeoutSec)) {
        throw "Backend tidak ready di $BaseUrl walau AutoStartBackend aktif."
      }
    } else {
      throw "Backend tidak ready di $BaseUrl dalam 8 detik. Jalankan backend dulu atau pakai -AutoStartBackend."
    }
  }
  $anggota = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/anggota" -TimeoutSec 8
  if (-not ($anggota -is [System.Array])) {
    throw "/api/anggota bukan array."
  }
  $baselineCount = $anggota.Count
  Write-Host ("[OK] /api/anggota count baseline: {0}" -f $baselineCount) -ForegroundColor Green

  Write-Section "F5-2 Create anggota (seed test)"
  $createdNomor = "F5-$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())"
  $seed = @{
    nama = "F5 Gate User"
    nomor_anggota = $createdNomor
    role = "anggota"
    brevet = "a"
    status = "aktif"
    quotes = "f5-gate"
    warna_card = "linear-gradient(135deg,#0d4a2f,#2d8a55)"
  } | ConvertTo-Json
  $create = Invoke-RestMethod -Method POST -Uri "$BaseUrl/api/anggota" -ContentType "application/json" -Body $seed -TimeoutSec 12
  if ($create -and ($create | Get-Member -Name id -MemberType NoteProperty -ErrorAction SilentlyContinue)) {
    $createdId = [string]$create.id
    $createdSeed = $create
  }

  $afterCreate = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/anggota" -TimeoutSec 8
  if ($afterCreate.Count -lt ($baselineCount + 1)) {
    throw "Jumlah anggota tidak bertambah setelah create."
  }
  if (-not $createdId) {
    $created = $afterCreate | Where-Object { [string]($_.nomor_anggota) -eq $createdNomor } | Select-Object -First 1
    if ($created) { $createdId = [string]$created.id }
  }
  if (-not $createdId) {
    throw "Create anggota sukses hitung, tapi id seed tidak ditemukan untuk cleanup (nomor=$createdNomor)."
  }
  Write-Host ("[OK] anggota baru id={0}" -f $createdId) -ForegroundColor Green
  Write-Host ("[OK] count setelah create: {0}" -f $afterCreate.Count) -ForegroundColor Green

  if (-not $SkipRestartCycle) {
    Write-Section "F5-3 Offline simulation (backend stop)"
    powershell -ExecutionPolicy Bypass -File $stopScript
    Start-Sleep -Seconds 2
    $offlineOk = Expect-ConnectionRefused -Url "$BaseUrl/api/session/ping"
    if (-not $offlineOk) {
      throw "Offline simulation gagal: endpoint masih bisa diakses setelah stop."
    }
    Write-Host "[OK] backend offline terdeteksi (connection refused)." -ForegroundColor Green

    Write-Section "F5-4 Recovery (backend start)"
    if (Test-Path $backendLog) { Remove-Item $backendLog -Force }
    $cmd = "powershell -ExecutionPolicy Bypass -File `"$runScript`" -RootDir `"$ServerRoot`" > `"$backendLog`" 2>&1"
    $backendProc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmd -WorkingDirectory $ServerRoot -PassThru

    if (-not (Wait-Health -Url "$BaseUrl/" -TimeoutSec $HealthTimeoutSec)) {
      throw "Recovery gagal: backend tidak healthy lagi."
    }
    Write-Host "[OK] backend recovery healthy." -ForegroundColor Green

    $afterRecovery = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/anggota" -TimeoutSec 8
    $found = $afterRecovery | Where-Object { $_.id -eq $createdId }
    if (-not $found) {
      throw "Anggota seed tidak ditemukan setelah recovery."
    }
    Write-Host "[OK] data anggota tetap ada setelah recovery." -ForegroundColor Green
  } else {
    Write-Section "F5-3/F5-4 Skipped"
    Write-Host "[INFO] Skip restart cycle aktif: offline/recovery tidak dijalankan." -ForegroundColor Yellow
  }

  Write-Section "F5-5 Multi-run API loop"
  $loopFail = 0
  for ($i = 1; $i -le $LoopCount; $i++) {
    try {
      $a = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/anggota" -TimeoutSec 6
      $s = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/stats" -TimeoutSec 6
      $n = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/announcements" -TimeoutSec 6
      if (-not ($a -is [System.Array])) { throw "anggota non-array" }
      if (-not ($n -is [System.Array])) { throw "announcements non-array" }
      if (-not $s) { throw "stats empty" }
      Write-Host ("[OK] loop {0}/{1}" -f $i, $LoopCount)
    } catch {
      $loopFail += 1
      Write-Warning ("loop {0}/{1} gagal: {2}" -f $i, $LoopCount, $_.Exception.Message)
    }
  }
  if ($loopFail -gt 0) {
    throw "Multi-run gagal: $loopFail/$LoopCount loop error."
  }

  Write-Section "F5-6 Cleanup seed anggota"
  if ($createdId) {
    try {
      Invoke-RestMethod -Method DELETE -Uri "$BaseUrl/api/anggota/$createdId" -TimeoutSec 8 | Out-Null
      Write-Host "[OK] cleanup anggota seed done." -ForegroundColor Green
    } catch {
      Write-Warning "Cleanup DELETE gagal, fallback ke PATCH status=nonaktif."
      try {
        $fallback = @{
          nama = [string]($createdSeed.nama ?? "F5 Gate User")
          role = [string]($createdSeed.role ?? "anggota")
          brevet = [string]($createdSeed.brevet ?? "a")
          status = "nonaktif"
          quotes = [string]($createdSeed.quotes ?? "f5-gate")
          warna_card = [string]($createdSeed.warna_card ?? "linear-gradient(135deg,#0d4a2f,#2d8a55)")
        } | ConvertTo-Json
        Invoke-RestMethod -Method PATCH -Uri "$BaseUrl/api/anggota/$createdId" -ContentType "application/json" -Body $fallback -TimeoutSec 8 | Out-Null
        Write-Host "[OK] fallback PATCH nonaktif sukses." -ForegroundColor Green
      } catch {
        Write-Warning "Cleanup fallback PATCH juga gagal; lakukan manual saat backend stabil."
      }
    }
  }

  Write-Section "F5 Summary"
  Write-Host "[SUCCESS] F5 gate otomatis PASS (backend/API level)." -ForegroundColor Green
  if ($SkipRestartCycle) {
    Write-Host "Manual checks tersisa (WAJIB):"
    Write-Host "1) Jalankan uji offline/recovery manual (karena skip restart cycle aktif)."
    Write-Host "2) Login -> buka Anggota -> reload -> tetap render."
    Write-Host "3) Switch Dashboard <-> Anggota 20x tanpa blank."
  } else {
    Write-Host "Manual UI checks (masih wajib):"
    Write-Host "1) Login -> buka Anggota -> reload -> tetap render."
    Write-Host "2) Matikan backend -> halaman tidak blank total (offline grace/cache)."
    Write-Host "3) Hidupkan backend -> data self-heal kembali normal."
    Write-Host "4) Switch Dashboard <-> Anggota 20x tanpa blank."
  }
}
catch {
  $allOk = $false
  Write-Host ("[FAIL] {0}" -f $_.Exception.Message) -ForegroundColor Red
}
finally {
  if (-not $KeepBackendRunning) {
    Write-Section "Stop Backend (Final)"
    powershell -ExecutionPolicy Bypass -File $stopScript
  } else {
    Write-Host "[INFO] Backend dibiarkan aktif (--KeepBackendRunning)." -ForegroundColor Yellow
  }

  if ($backendProc -and -not $backendProc.HasExited -and -not $KeepBackendRunning) {
    try { Stop-Process -Id $backendProc.Id -Force -ErrorAction SilentlyContinue } catch {}
  }

  if (-not $allOk) {
    if ($createdId) {
      try {
        Invoke-RestMethod -Method DELETE -Uri "$BaseUrl/api/anggota/$createdId" -TimeoutSec 8 | Out-Null
      } catch {}
    }
    if (Test-Path $backendLog) {
      Write-Section "Backend Log (tail)"
      Get-Content -Path $backendLog -Tail 120
    }
    exit 1
  }
}
