param(
  [int]$Port = 3010,
  [string]$HardwareId = "eb631723-7fb8-41a9-8543-87038070062d",
  [string]$DataDir = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\p1-isolated-data",
  [switch]$ResetData
)

$ErrorActionPreference = "Stop"

$serverExe = "D:\Workspace\projects\akp2i_projects\server_lokal\target\debug\akp2i-server.exe"
if (!(Test-Path $serverExe)) {
  throw "Server binary not found: $serverExe"
}

if ($ResetData -and (Test-Path $DataDir)) {
  Remove-Item -LiteralPath $DataDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $DataDir | Out-Null

$env:AKPI_DATA_DIR = $DataDir
$env:AKPI_PORT = "$Port"
$env:AKPI_DISABLE_STORAGE_SYNC = "1"
$env:AKPI_DISABLE_QUEUE_RETRY = "1"
$env:AKPI_DISABLE_WAITING_ROOM = "1"
$env:AKPI_ENABLE_COMPACTION_LOOP = "0"
$env:AKPI_ENABLE_DEVICE_DEDUPE = "0"

$baseUrl = "http://127.0.0.1:$Port"
Write-Host "=== Run P1 Isolated ==="
Write-Host "BaseUrl    : $baseUrl"
Write-Host "DataDir    : $DataDir"
Write-Host "HardwareId : $HardwareId"
Write-Host ""

$proc = Start-Process -FilePath $serverExe -PassThru
try {
  $healthy = $false
  for ($i = 1; $i -le 30; $i++) {
    try {
      $r = Invoke-RestMethod -Method GET -Uri "$baseUrl/"
      if ($r -match "AKP2I Server OK") {
        $healthy = $true
        break
      }
    } catch {}
    Start-Sleep -Milliseconds 500
  }
  if (-not $healthy) {
    throw "Server isolated tidak healthy di $baseUrl"
  }

  powershell -ExecutionPolicy Bypass -File "D:\Workspace\projects\akp2i_projects\AGENTS\TOOLS_CODEX\test-p1-devices-dedupe.ps1" `
    -BaseUrl $baseUrl `
    -HardwareId $HardwareId `
    -DataDir $DataDir `
    -BootstrapCount 10 `
    -PingCount 60 `
    -PingIntervalMs 200
}
finally {
  if ($proc -and !$proc.HasExited) {
    Stop-Process -Id $proc.Id -Force
  }
}

