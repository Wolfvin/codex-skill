param(
  [string]$ServerDir = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataDir = "$env:LOCALAPPDATA\Smart Tax Assistance\server\lokal",
  [int]$WaitSec = 8,
  [int]$MaxWaitSec = 120
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Write-Host "=== Start Backend (Safe Triage Mode) ==="
Write-Host "ServerDir : $ServerDir"
Write-Host "DataDir   : $DataDir"

$env:AKPI_DATA_DIR = $DataDir
$env:AKPI_DISABLE_STORAGE_SYNC = '1'
$env:AKPI_DISABLE_QUEUE_RETRY = '1'
$env:AKPI_DISABLE_WAITING_ROOM = '1'
$env:AKPI_DISABLE_ELECTION_MONITOR = '1'
$env:AKPI_DISABLE_CONTROL_LISTENER = '1'
$env:AKPI_DISABLE_DISCOVERY_LISTENER = '1'
$env:AKPI_DISABLE_HEARTBEAT_LISTENER = '1'
$env:AKPI_DISABLE_HEARTBEAT_BROADCAST = '1'

Push-Location $ServerDir
try {
  $existing = Get-Process akp2i-server -ErrorAction SilentlyContinue
  if (-not $existing) {
    Start-Process -FilePath powershell -ArgumentList '-NoProfile','-Command','cargo run' -WorkingDirectory $ServerDir
  } else {
    Write-Host "[INFO] akp2i-server sudah berjalan (PID: $($existing.Id -join ', ')). Skip spawn baru."
  }

  Start-Sleep -Seconds $WaitSec

  $deadline = (Get-Date).AddSeconds([Math]::Max(10, $MaxWaitSec))
  $healthy = $false
  do {
    try {
      $ok = Invoke-RestMethod -Uri 'http://127.0.0.1:3000/' -TimeoutSec 3
      Write-Host "[PASS] health: $ok"
      $healthy = $true
      break
    } catch {
      Start-Sleep -Seconds 2
    }
  } while ((Get-Date) -lt $deadline)

  if (-not $healthy) {
    Write-Host "[FAIL] health probe gagal hingga timeout ${MaxWaitSec}s."
    Get-Process akp2i-server -ErrorAction SilentlyContinue | Select-Object Id,ProcessName,StartTime | Format-Table -AutoSize
    netstat -ano | findstr :3000
  }
} finally {
  Pop-Location
}

Write-Host "NOTE: mode ini untuk isolasi crash startup. Setelah stabil, nyalakan fitur bertahap lagi."
