param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [switch]$RestartBackend,
  [switch]$KeepBackendRunning,
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
      $r = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 3
      if ($r.StatusCode -eq 200) { return $true }
    } catch {}
    Start-Sleep -Milliseconds 800
  }
  return $false
}

$stopScript = Join-Path $ServerRoot "SOP\41_stop_backend.ps1"
$runScript = Join-Path $ServerRoot "SOP\40_run_backend.ps1"
$backendProc = $null
$createdId = $null

try {
  if ($RestartBackend) {
    Write-Section "Restart Backend"
    powershell -ExecutionPolicy Bypass -File $stopScript
    $cmd = "powershell -ExecutionPolicy Bypass -File `"$runScript`" -RootDir `"$ServerRoot`""
    $backendProc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmd -WorkingDirectory $ServerRoot -PassThru
  }

  Write-Section "Wait Health"
  if (-not (Wait-Health -Url "$BaseUrl/" -TimeoutSec $HealthTimeoutSec)) {
    throw "Backend tidak ready di $BaseUrl"
  }
  Write-Host "[OK] backend health ready"

  Write-Section "Baseline Anggota"
  $before = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/anggota" -TimeoutSec 10
  $beforeCount = if ($before -is [System.Array]) { $before.Count } else { 0 }
  Write-Host ("anggota sebelum: {0}" -f $beforeCount)

  $hw = "tools-hw-$([Guid]::NewGuid().ToString('N').Substring(0,12))"
  $nama = "Tools User $([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
  $nomor = "TOOLS-$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"

  Write-Section "Bootstrap Session"
  $bootstrapBody = @{
    hardware_id = $hw
    app_version = "1.0.0"
  } | ConvertTo-Json
  $bootstrap = Invoke-RestMethod -Method POST -Uri "$BaseUrl/api/session/bootstrap" -ContentType "application/json" -Body $bootstrapBody -TimeoutSec 15
  $bootstrapOk = $false
  if ($bootstrap.PSObject.Properties['ok']) { $bootstrapOk = [bool]$bootstrap.ok }
  $bootstrapRole = "-"
  if ($bootstrap.PSObject.Properties['role'] -and $bootstrap.role) {
    $bootstrapRole = [string]$bootstrap.role
  } elseif ($bootstrap.PSObject.Properties['profile'] -and $bootstrap.profile -and $bootstrap.profile.PSObject.Properties['role'] -and $bootstrap.profile.role) {
    $bootstrapRole = [string]$bootstrap.profile.role
  }
  $bootstrapReason = "-"
  if ($bootstrap.PSObject.Properties['reason'] -and $bootstrap.reason) { $bootstrapReason = [string]$bootstrap.reason }
  Write-Host ("bootstrap ok: {0}, role: {1}, reason: {2}" -f $bootstrapOk, $bootstrapRole, $bootstrapReason)

  Write-Section "Self Register"
  $registerBody = @{
    hardware_id = $hw
    nama = $nama
    nomor_anggota = $nomor
    brevet = "male"
    quotes = "tools-flow"
    role = "anggota"
    status = "aktif"
  } | ConvertTo-Json
  $register = Invoke-RestMethod -Method POST -Uri "$BaseUrl/api/anggota/self-register" -ContentType "application/json" -Body $registerBody -TimeoutSec 25
  if (-not $register.ok) {
    throw "self-register gagal: $($register.error)"
  }
  $createdId = $register.id
  Write-Host ("self-register ok, id: {0}" -f $createdId)

  Write-Section "Verify Anggota Render Source"
  $after = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/anggota" -TimeoutSec 10
  $afterCount = if ($after -is [System.Array]) { $after.Count } else { 0 }
  $found = $after | Where-Object { $_.id -eq $createdId -or $_.nama -eq $nama } | Select-Object -First 1
  Write-Host ("anggota sesudah: {0}" -f $afterCount)
  if (-not $found) {
    throw "anggota baru tidak muncul di GET /api/anggota"
  }
  Write-Host ("[OK] anggota ditemukan: {0} ({1})" -f $found.nama, $found.id)

  Write-Section "Result"
  Write-Host "[SUCCESS] tools.ps1 test flow PASS" -ForegroundColor Green
}
finally {
  if ($createdId) {
    Write-Section "Cleanup"
    $deleted = $false
    for ($attempt = 1; $attempt -le 3; $attempt++) {
      try {
        Invoke-RestMethod -Method DELETE -Uri "$BaseUrl/api/anggota/$createdId" -TimeoutSec 20 | Out-Null
        Write-Host ("[OK] cleanup anggota test (attempt {0})" -f $attempt)
        $deleted = $true
        break
      } catch {
        Start-Sleep -Milliseconds 600
      }
    }
    if (-not $deleted) {
      Write-Warning "cleanup anggota test gagal setelah retry."
    }
  }

  if ($RestartBackend -and -not $KeepBackendRunning) {
    Write-Section "Stop Backend (Final)"
    powershell -ExecutionPolicy Bypass -File $stopScript
  }

  if ($backendProc -and -not $backendProc.HasExited -and -not $KeepBackendRunning) {
    try { Stop-Process -Id $backendProc.Id -Force -ErrorAction SilentlyContinue } catch {}
  }
}
