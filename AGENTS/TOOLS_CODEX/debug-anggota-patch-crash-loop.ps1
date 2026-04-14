param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [int]$TimeoutSec = 8,
  [int]$Loops = 5,
  [string]$TargetId = "",
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
    Start-Sleep -Milliseconds 400
  }
  return $false
}

function Tail-File([string]$Path, [int]$Lines = 80) {
  if (Test-Path $Path) {
    Get-Content -Path $Path -Tail $Lines
  } else {
    Write-Host "[WARN] log file not found: $Path" -ForegroundColor Yellow
  }
}

$stopScript = Join-Path $ServerRoot "SOP\41_stop_backend.ps1"
$runScript  = Join-Path $ServerRoot "SOP\40_run_backend.ps1"
if (-not (Test-Path $stopScript)) { throw "Stop script tidak ditemukan: $stopScript" }
if (-not (Test-Path $runScript)) { throw "Run script tidak ditemukan: $runScript" }

$logDir = Join-Path $PSScriptRoot ".tmp"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir ("anggota-patch-crash-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
$errFile = Join-Path $logDir ("anggota-patch-crash-{0}.err.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

Write-Section "Stop backend lama"
powershell -NoProfile -ExecutionPolicy Bypass -File $stopScript | Out-Null

Write-Section "Start backend isolasi + log"
$runner = @"
`$env:RUST_LOG='info,akp2i_server::routes::anggota=debug,akp2i_server::routes::storage_sync=debug';
powershell -NoProfile -ExecutionPolicy Bypass -File '$runScript' -DisableElectionMonitor -DisableControlListener -DisableDiscoveryListener -DisableHeartbeatBroadcast -DisableHeartbeatListener -DisableStorageSync -DisableQueueRetry
"@

$backendProc = Start-Process -FilePath "powershell" `
  -ArgumentList @("-NoProfile", "-Command", $runner) `
  -RedirectStandardOutput $logFile `
  -RedirectStandardError $errFile `
  -PassThru

Write-Host ("[INFO] backend pid: {0}" -f $backendProc.Id)
Write-Host ("[INFO] backend log: {0}" -f $logFile)

Write-Section "Wait health"
if (-not (Wait-Health -Url $BaseUrl -MaxSec 20)) {
  Write-Host "[FAIL] Backend tidak sehat setelah start." -ForegroundColor Red
  Tail-File -Path $logFile -Lines 120
  exit 1
}
Write-Host "[OK] Backend healthy"

Write-Section "Resolve target anggota id"
$items = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/anggota" -TimeoutSec $TimeoutSec
if (-not ($items -is [System.Array])) {
  throw "/api/anggota tidak mengembalikan array"
}

if ([string]::IsNullOrWhiteSpace($TargetId)) {
  $target = $items | Where-Object {
    ([string]$_.nomor_anggota -like "F5*") -or ([string]$_.nama -like "F5*")
  } | Select-Object -First 1
  if ($null -eq $target) { throw "Tidak ditemukan target anggota F5. Pakai -TargetId manual." }
  $TargetId = [string]$target.id
}
Write-Host ("[OK] target id: {0}" -f $TargetId)

$payload = @{
  nama = "F5 Gate User"
  role = "anggota"
  brevet = "a"
  status = "nonaktif"
  quotes = "f5-cleanup-loop"
  warna_card = "linear-gradient(135deg,#0d4a2f,#2d8a55)"
} | ConvertTo-Json

Write-Section "PATCH loop"
$success = 0
$fail = 0
$crashed = $false

for ($i = 1; $i -le $Loops; $i++) {
  try {
    Invoke-RestMethod -Method PATCH -Uri "$BaseUrl/api/anggota/$TargetId" -ContentType "application/json" -Body $payload -TimeoutSec $TimeoutSec | Out-Null
    $success++
    Write-Host ("[OK] loop {0}/{1}" -f $i, $Loops) -ForegroundColor Green
  } catch {
    $fail++
    Write-Warning ("[FAIL] loop {0}/{1}: {2}" -f $i, $Loops, $_.Exception.Message)
    if (-not (Wait-Health -Url $BaseUrl -MaxSec 2)) {
      $crashed = $true
      Write-Warning "[STOP] backend unhealthy after PATCH failure."
      break
    }
  }
}

Write-Section "Summary"
Write-Host ("Success: {0}" -f $success)
Write-Host ("Fail   : {0}" -f $fail)
Write-Host ("Crash? : {0}" -f $crashed)

Write-Section "Backend log tail"
Tail-File -Path $logFile -Lines 150
Write-Section "Backend err tail"
Tail-File -Path $errFile -Lines 80

if (-not $KeepBackendRunning) {
  Write-Section "Stop backend"
  powershell -NoProfile -ExecutionPolicy Bypass -File $stopScript | Out-Null
}

if ($crashed) { exit 2 }
if ($fail -gt 0) { exit 1 }
exit 0
