param(
  [string]$DataDir = "",
  [string]$BaseUrl = "http://127.0.0.1:3000"
)

function Write-Section([string]$title) {
  Write-Host "`n=== $title ===" -ForegroundColor Cyan
}

function Show-Env([string]$Key) {
  $val = [Environment]::GetEnvironmentVariable($Key, "Process")
  if ([string]::IsNullOrWhiteSpace($val)) {
    $val = [Environment]::GetEnvironmentVariable($Key, "User")
  }
  if ([string]::IsNullOrWhiteSpace($val)) {
    $val = [Environment]::GetEnvironmentVariable($Key, "Machine")
  }
  if ([string]::IsNullOrWhiteSpace($val)) {
    Write-Host "[WARN] $Key = <empty>" -ForegroundColor Yellow
    return $null
  }
  Write-Host "[OK] $Key = $val" -ForegroundColor Green
  return $val
}

function Test-Health([string]$Url) {
  try {
    $resp = Invoke-WebRequest -UseBasicParsing -Uri "$Url/" -TimeoutSec 3
    return $resp.StatusCode -eq 200
  } catch {
    return $false
  }
}

Write-Section "Ports & Multi-node"
$akpiPort = Show-Env "AKPI_PORT"
Show-Env "AKPI_HEARTBEAT_PORT"
Show-Env "AKPI_DISCOVERY_PORT"
Show-Env "AKPI_CONTROL_PORT"
Show-Env "AKPI_HEARTBEAT_TARGET_PORTS"
Show-Env "BROADCAST_ADDR"
Show-Env "AKPI_ELECTION_RECONCILE_SECS"

Write-Section "Storage & Data Dir"
$envData = Show-Env "AKPI_DATA_DIR"
if ([string]::IsNullOrWhiteSpace($DataDir)) {
  $DataDir = if (-not [string]::IsNullOrWhiteSpace($envData)) { $envData } else { "" }
}
if (-not [string]::IsNullOrWhiteSpace($DataDir)) {
  Write-Host "[INFO] DataDir = $DataDir" -ForegroundColor Cyan
  if (Test-Path $DataDir) {
    $expected = @("index.db","queue","staging","dead_letter","anggota","announcements","devices","document_logs","files_count","app_settings")
    foreach ($e in $expected) {
      $p = Join-Path $DataDir $e
      if (Test-Path $p) { Write-Host "[OK] $p" -ForegroundColor Green }
      else { Write-Host "[WARN] missing $p" -ForegroundColor Yellow }
    }
  } else {
    Write-Host "[WARN] DataDir tidak ditemukan" -ForegroundColor Yellow
  }
} else {
  Write-Host "[WARN] DataDir belum di-set (AKPI_DATA_DIR kosong)" -ForegroundColor Yellow
}

Write-Section "Feature Flags (disable)"
Show-Env "AKPI_DISABLE_HEARTBEAT_BROADCAST"
Show-Env "AKPI_DISABLE_HEARTBEAT_LISTENER"
Show-Env "AKPI_DISABLE_DISCOVERY_LISTENER"
Show-Env "AKPI_DISABLE_CONTROL_LISTENER"
Show-Env "AKPI_DISABLE_ELECTION_MONITOR"
Show-Env "AKPI_DISABLE_STORAGE_SYNC"
Show-Env "AKPI_DISABLE_QUEUE_RETRY"

Write-Section "Identity / Networking"
Show-Env "AKPI_DEVICE_ID"
Show-Env "AKPI_IP"
Show-Env "AKPI_NODE_NAME"

Write-Section "Global / Admin Ops"
Show-Env "AKPI_APP_KEY"

Write-Section "Backend Health"
$ok = Test-Health -Url $BaseUrl
Write-Host "[INFO] Health $BaseUrl = $ok" -ForegroundColor Cyan

Write-Section "Frontend/Client Cache (manual check)"
Write-Host "- akp2i_diag_anggota_last" -ForegroundColor Yellow
Write-Host "- akp2i_diag_dashboard_last" -ForegroundColor Yellow
Write-Host "- akp2i_diag_pengumuman_last" -ForegroundColor Yellow
Write-Host "- akp2i_diag_developer_last" -ForegroundColor Yellow

Write-Section "Auth Bypass (manual check)"
Write-Host "- Pastikan super_admin allowlist bypass restricted saat server unreachable" -ForegroundColor Yellow
