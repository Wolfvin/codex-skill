param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataDir = "D:\Workspace\projects\akp2i_projects\_tmp_server_data",
  [switch]$SkipBackendRestart,
  [switch]$KeepBackendRunning,
  [switch]$ForceCleanup,
  [switch]$StrictLegacyCheck,
  [int]$HealthTimeoutSec = 90
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
      $r = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
      if ($r.StatusCode -eq 200) { return $true }
    } catch {}
    Start-Sleep -Milliseconds 800
  }
  return $false
}

function Check-Endpoint([string]$Url, [string]$Method, [int[]]$Expected) {
  $methodArg = $Method.ToUpperInvariant()
  $code = ""
  if ($methodArg -eq "POST") {
    $code = curl.exe --max-time 4 -s -o NUL -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{}" $Url
  } else {
    $code = curl.exe --max-time 4 -s -o NUL -w "%{http_code}" -X GET $Url
  }
  $status = 0
  if (-not [int]::TryParse($code, [ref]$status)) {
    return $false
  }
  return $Expected -contains $status
}

$stopScript = Join-Path $ServerRoot "SOP\41_stop_backend.ps1"
$runScript = Join-Path $ServerRoot "SOP\40_run_backend.ps1"
$smokeScript = Join-Path $PSScriptRoot "frontend-api-smoke.mjs"

if (-not (Test-Path $stopScript)) { throw "Stop script tidak ditemukan: $stopScript" }
if (-not (Test-Path $runScript)) { throw "Run script tidak ditemukan: $runScript" }
if (-not (Test-Path $smokeScript)) { throw "Smoke script tidak ditemukan: $smokeScript" }

New-Item -ItemType Directory -Force -Path $DataDir | Out-Null

$backendProc = $null
$smokeExit = 1

try {
  if (-not $SkipBackendRestart) {
    Write-Section "Stop Backend"
    powershell -ExecutionPolicy Bypass -File $stopScript

    Write-Section "Run Backend"
    $cmd = "set AKPI_DATA_DIR=$DataDir&& powershell -ExecutionPolicy Bypass -File `"$runScript`" -RootDir `"$ServerRoot`""
    $backendProc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmd -WorkingDirectory $ServerRoot -PassThru
  } else {
    Write-Section "Skip Restart"
    Write-Host "Memakai backend yang sudah aktif."
  }

  Write-Section "Wait Health"
  if (-not (Wait-Health -Url "$BaseUrl/" -TimeoutSec $HealthTimeoutSec)) {
    throw "Backend tidak ready di $BaseUrl dalam $HealthTimeoutSec detik"
  }
  Write-Host "[OK] Health check 200"

  Write-Section "Run Smoke"
  $env:SMOKE_BASE_URL = $BaseUrl
  if ($ForceCleanup) { Remove-Item Env:SMOKE_CLEANUP -ErrorAction SilentlyContinue }
  else { $env:SMOKE_CLEANUP = "0" }
  node $smokeScript
  $smokeExit = $LASTEXITCODE
  if ($smokeExit -ne 0) {
    throw "Smoke test gagal dengan exit code $smokeExit"
  }

  Write-Section "Legacy Endpoint Check"
  $syncOff = Check-Endpoint -Url "$BaseUrl/api/sync/status" -Method "GET" -Expected @(410)
  $crdtOff = Check-Endpoint -Url "$BaseUrl/api/crdt/sync" -Method "POST" -Expected @(410)
  Write-Host ("[CHECK] /api/sync/status == 410 : {0}" -f $syncOff)
  Write-Host ("[CHECK] /api/crdt/sync  == 410 : {0}" -f $crdtOff)
  if (-not $syncOff -or -not $crdtOff) {
    if ($StrictLegacyCheck) {
      throw "Legacy endpoint check gagal"
    } else {
      Write-Warning "Legacy endpoint check gagal (non-strict mode)."
    }
  }

  Write-Section "Result"
  Write-Host "[SUCCESS] Debug cycle selesai." -ForegroundColor Green
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
}
