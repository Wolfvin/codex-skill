param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [int]$TimeoutSec = 10,
  [switch]$AutoStartBackend,
  [switch]$KeepBackendRunning
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Section([string]$msg) {
  Write-Host ""
  Write-Host "=== $msg ===" -ForegroundColor Cyan
}

function Wait-Health([string]$Url, [int]$MaxSec) {
  $deadline = (Get-Date).AddSeconds($MaxSec)
  while ((Get-Date) -lt $deadline) {
    try {
      $r = Invoke-WebRequest -UseBasicParsing -Uri "$Url/" -TimeoutSec 3
      if ($r.StatusCode -eq 200) { return $true }
    } catch {}
    Start-Sleep -Milliseconds 500
  }
  return $false
}

function Ensure-Backend([string]$Url, [string]$Root) {
  if (Wait-Health -Url $Url -MaxSec 3) {
    Write-Host "[OK] backend sudah sehat." -ForegroundColor Green
    return
  }
  if (-not $AutoStartBackend) {
    throw "Backend belum sehat. Jalankan backend dulu atau pakai -AutoStartBackend."
  }

  $stopScript = Join-Path $Root "SOP\41_stop_backend.ps1"
  $runScript  = Join-Path $Root "SOP\40_run_backend.ps1"
  if (-not (Test-Path $stopScript)) { throw "Tidak ditemukan: $stopScript" }
  if (-not (Test-Path $runScript)) { throw "Tidak ditemukan: $runScript" }

  Write-Section "Auto start backend (isolasi)"
  powershell -NoProfile -ExecutionPolicy Bypass -File $stopScript | Out-Null
  $cmd = "cd '$Root'; powershell -NoProfile -ExecutionPolicy Bypass -File '.\SOP\40_run_backend.ps1' -DisableElectionMonitor -DisableControlListener -DisableDiscoveryListener -DisableHeartbeatBroadcast -DisableHeartbeatListener -DisableStorageSync -DisableQueueRetry"
  Start-Process -FilePath "powershell" -ArgumentList @("-NoProfile", "-Command", $cmd) | Out-Null

  if (-not (Wait-Health -Url $Url -MaxSec 60)) {
    throw "Backend gagal healthy setelah auto start."
  }
  Write-Host "[OK] backend healthy setelah auto start." -ForegroundColor Green
}

function Stop-Backend([string]$Root) {
  $stopScript = Join-Path $Root "SOP\41_stop_backend.ps1"
  if (Test-Path $stopScript) {
    powershell -NoProfile -ExecutionPolicy Bypass -File $stopScript | Out-Null
  } else {
    Get-Process akp2i-server -ErrorAction SilentlyContinue | Stop-Process -Force
  }
}

Write-Section "G5 Preflight"
Ensure-Backend -Url $BaseUrl -Root $ServerRoot

$ok = 0
$fail = 0
$createdAnnId = $null
$createdAnggotaId = $null

try {
  Write-Section "G5-1 Create announcement"
  $annBody = @{
    title = "G5 Write Gate"
    body = "g5-delete-test"
    category = "Info"
    is_pinned = $false
    author = "g5-script"
  } | ConvertTo-Json
  $createAnnResp = Invoke-WebRequest -UseBasicParsing -Method POST -Uri "$BaseUrl/api/announcements" -ContentType "application/json" -Body $annBody -TimeoutSec $TimeoutSec
  if ($createAnnResp.StatusCode -lt 200 -or $createAnnResp.StatusCode -ge 300) {
    throw "Create announcement status tidak sukses: $($createAnnResp.StatusCode)"
  }
  $anns = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/announcements" -TimeoutSec $TimeoutSec
  $foundAnn = $anns | Where-Object { [string]$_.title -eq "G5 Write Gate" -and [string]$_.body -eq "g5-delete-test" } | Select-Object -Last 1
  if ($null -eq $foundAnn) { throw "Announcement baru tidak ditemukan sesudah create." }
  $createdAnnId = [string]$foundAnn.id
  Write-Host ("[OK] create announcement id={0}" -f $createdAnnId) -ForegroundColor Green
  $ok++

  Write-Section "G5-2 Delete announcement"
  $delAnnResp = Invoke-WebRequest -UseBasicParsing -Method DELETE -Uri "$BaseUrl/api/announcements/$createdAnnId" -TimeoutSec $TimeoutSec
  if ($delAnnResp.StatusCode -lt 200 -or $delAnnResp.StatusCode -ge 300) {
    throw "Delete announcement status tidak sukses: $($delAnnResp.StatusCode)"
  }
  if (-not (Wait-Health -Url $BaseUrl -MaxSec 3)) {
    throw "Backend tidak sehat setelah DELETE announcement."
  }
  Write-Host "[OK] delete announcement + backend tetap sehat" -ForegroundColor Green
  $ok++

  Write-Section "G5-3 Create anggota"
  $suffix = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  $anggBody = @{
    nama = "G5 User $suffix"
    nomor_anggota = "G5-$suffix"
    role = "anggota"
    brevet = "a"
    quotes = "g5-write-gate"
    warna_card = "linear-gradient(135deg,#0d4a2f,#2d8a55)"
    joined_at = "2026-04-04"
  } | ConvertTo-Json
  $createAngResp = Invoke-WebRequest -UseBasicParsing -Method POST -Uri "$BaseUrl/api/anggota" -ContentType "application/json" -Body $anggBody -TimeoutSec $TimeoutSec
  if ($createAngResp.StatusCode -lt 200 -or $createAngResp.StatusCode -ge 300) {
    throw "Create anggota status tidak sukses: $($createAngResp.StatusCode)"
  }
  $members = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/anggota" -TimeoutSec $TimeoutSec
  $foundMember = $members | Where-Object { [string]$_.nomor_anggota -eq "G5-$suffix" } | Select-Object -First 1
  if ($null -eq $foundMember) { throw "Anggota baru tidak ditemukan sesudah create." }
  $createdAnggotaId = [string]$foundMember.id
  Write-Host ("[OK] create anggota id={0}" -f $createdAnggotaId) -ForegroundColor Green
  $ok++

  Write-Section "G5-4 Patch anggota"
  $patchBody = @{
    nama = [string]$foundMember.nama
    role = [string]$foundMember.role
    brevet = [string]$foundMember.brevet
    status = "nonaktif"
    quotes = "g5-patched"
    warna_card = [string]$foundMember.warna_card
  } | ConvertTo-Json
  $patchResp = Invoke-WebRequest -UseBasicParsing -Method PATCH -Uri "$BaseUrl/api/anggota/$createdAnggotaId" -ContentType "application/json" -Body $patchBody -TimeoutSec $TimeoutSec
  if ($patchResp.StatusCode -lt 200 -or $patchResp.StatusCode -ge 300) {
    throw "Patch anggota status tidak sukses: $($patchResp.StatusCode)"
  }
  if (-not (Wait-Health -Url $BaseUrl -MaxSec 3)) {
    throw "Backend tidak sehat setelah PATCH anggota."
  }
  Write-Host "[OK] patch anggota + backend tetap sehat" -ForegroundColor Green
  $ok++

  Write-Section "G5-5 Delete anggota"
  $delMemberResp = Invoke-WebRequest -UseBasicParsing -Method DELETE -Uri "$BaseUrl/api/anggota/$createdAnggotaId" -TimeoutSec $TimeoutSec
  if ($delMemberResp.StatusCode -lt 200 -or $delMemberResp.StatusCode -ge 300) {
    throw "Delete anggota status tidak sukses: $($delMemberResp.StatusCode)"
  }
  if (-not (Wait-Health -Url $BaseUrl -MaxSec 3)) {
    throw "Backend tidak sehat setelah DELETE anggota."
  }
  Write-Host "[OK] delete anggota + backend tetap sehat" -ForegroundColor Green
  $ok++
}
catch {
  $fail++
  Write-Host ("[FAIL] {0}" -f $_.Exception.Message) -ForegroundColor Red
}
finally {
  Write-Section "G5 Summary"
  Write-Host ("Checks OK   : {0}" -f $ok)
  Write-Host ("Checks FAIL : {0}" -f $fail)

  if (-not $KeepBackendRunning) {
    Write-Section "Stop backend"
    Stop-Backend -Root $ServerRoot
  } else {
    Write-Host "[INFO] Backend dibiarkan aktif (--KeepBackendRunning)."
  }
}

if ($fail -gt 0) { exit 1 }
exit 0
