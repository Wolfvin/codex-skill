param(
  [ValidateSet("build","run")]
  [string]$Mode = "build",
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataDir = "",
  [int]$Port = 3000,
  [int]$HeartbeatPort = 47732,
  [int]$DiscoveryPort = 47734,
  [int]$ControlPort = 47733,
  [string]$HeartbeatTargets = "",
  [string]$BroadcastAddr = "127.0.0.1"
)

function Write-Section([string]$title) {
  Write-Host "`n=== $title ===" -ForegroundColor Cyan
}

Write-Section "Backend Cargo ($Mode)"
if (!(Test-Path $ServerRoot)) {
  throw "ServerRoot tidak ditemukan: $ServerRoot"
}

Push-Location $ServerRoot
try {
  if ($Mode -eq "build") {
    cargo build
    exit $LASTEXITCODE
  }

  if ([string]::IsNullOrWhiteSpace($DataDir)) {
    $DataDir = Join-Path $ServerRoot "..\\_tmp_server_data"
  }
  if (!(Test-Path $DataDir)) { New-Item -ItemType Directory -Path $DataDir | Out-Null }

  $env:AKPI_DATA_DIR = $DataDir
  $env:AKPI_PORT = "$Port"
  $env:AKPI_NODE_NAME = "dev-node"
  $env:AKPI_DEVICE_ID = "dev-node-$Port"
  $env:AKPI_HEARTBEAT_PORT = "$HeartbeatPort"
  $env:AKPI_DISCOVERY_PORT = "$DiscoveryPort"
  $env:AKPI_CONTROL_PORT = "$ControlPort"
  if (-not [string]::IsNullOrWhiteSpace($HeartbeatTargets)) {
    $env:AKPI_HEARTBEAT_TARGET_PORTS = $HeartbeatTargets
  }
  $env:BROADCAST_ADDR = $BroadcastAddr
  $env:RUST_LOG = "info"

  cargo run
  exit $LASTEXITCODE
} finally {
  Pop-Location
}
