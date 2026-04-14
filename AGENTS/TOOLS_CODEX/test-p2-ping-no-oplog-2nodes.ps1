param(
  [int]$PortA = 3020,
  [int]$PortB = 3021,
  [int]$HeartbeatA = 47832,
  [int]$HeartbeatB = 47833,
  [int]$DiscoveryA = 47834,
  [int]$DiscoveryB = 47835,
  [int]$ControlA = 47836,
  [int]$ControlB = 47837,
  [string]$HardwareId = "eb631723-7fb8-41a9-8543-87038070062d",
  [int]$PingCount = 120,
  [int]$PingIntervalMs = 100,
  [switch]$ResetData
)

$ErrorActionPreference = "Stop"
$serverExe = "D:\Workspace\projects\akp2i_projects\server_lokal\target\debug\akp2i-server.exe"
if (!(Test-Path $serverExe)) { throw "Binary not found: $serverExe" }

$dataA = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\p2-nodeA"
$dataB = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\p2-nodeB"
if ($ResetData) {
  if (Test-Path $dataA) { Remove-Item -LiteralPath $dataA -Recurse -Force }
  if (Test-Path $dataB) { Remove-Item -LiteralPath $dataB -Recurse -Force }
}
New-Item -ItemType Directory -Force -Path $dataA | Out-Null
New-Item -ItemType Directory -Force -Path $dataB | Out-Null

function Wait-Healthy([string]$BaseUrl) {
  for ($i=0; $i -lt 40; $i++) {
    try {
      $r = Invoke-RestMethod -Method GET -Uri "$BaseUrl/"
      if ($r -match "AKP2I Server OK") { return $true }
    } catch {}
    Start-Sleep -Milliseconds 300
  }
  return $false
}

function Bootstrap([string]$BaseUrl, [string]$Hw) {
  $body = @{ hardware_id = $Hw; app_version = "1.0.0" } | ConvertTo-Json
  Invoke-RestMethod -Method POST -Uri "$BaseUrl/api/session/bootstrap" -ContentType "application/json" -Body $body
}

function Ping([string]$BaseUrl, [string]$Hw, [string]$Token) {
  $headers = @{
    "x-akp2i-hardware-id" = $Hw
    "x-akp2i-token" = $Token
  }
  Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/session/ping" -Headers $headers
}

function Count-DeviceFiles([string]$DataDir) {
  $dir = Join-Path $DataDir "devices"
  if (!(Test-Path $dir)) { return 0 }
  return (Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue | Measure-Object).Count
}

function Count-DevicesOpLog([string]$BaseUrl) {
  $resp = Invoke-RestMethod -Method GET -Uri "$BaseUrl/sync/index?since_seq=0&limit=2000"
  if ($null -eq $resp -or $null -eq $resp.delta) { return 0 }
  return @($resp.delta | Where-Object { $_.collection -eq "devices" }).Count
}

Write-Host "=== P2 Real 2-Node Simulation ==="
Write-Host "NodeA : http://127.0.0.1:$PortA"
Write-Host "NodeB : http://127.0.0.1:$PortB"
Write-Host "PingCount=$PingCount intervalMs=$PingIntervalMs"
Write-Host ""

function Start-Node([hashtable]$Vars) {
  $lines = @()
  foreach ($k in $Vars.Keys) {
    $v = [string]$Vars[$k]
    $escaped = $v.Replace("'", "''")
    $lines += "`$env:$k='$escaped'"
  }
  $exeEscaped = $serverExe.Replace("'", "''")
  $script = ($lines -join "; ") + "; & '$exeEscaped'"
  $bytes = [System.Text.Encoding]::Unicode.GetBytes($script)
  $encoded = [Convert]::ToBase64String($bytes)
  Start-Process -FilePath "powershell" -ArgumentList @("-NoProfile", "-EncodedCommand", $encoded) -PassThru
}

$procA = Start-Node @{
  AKPI_DATA_DIR = $dataA
  AKPI_PORT = "$PortA"
  AKPI_HEARTBEAT_PORT = "$HeartbeatA"
  AKPI_DISCOVERY_PORT = "$DiscoveryA"
  AKPI_CONTROL_PORT = "$ControlA"
  AKPI_HEARTBEAT_TARGET_PORTS = "$HeartbeatA,$HeartbeatB"
  AKPI_ENABLE_COMPACTION_LOOP = "0"
  AKPI_ENABLE_DEVICE_DEDUPE = "0"
  AKPI_DISABLE_STORAGE_SYNC = "1"
  AKPI_DISABLE_QUEUE_RETRY = "1"
  AKPI_DISABLE_WAITING_ROOM = "1"
}

$procB = Start-Node @{
  AKPI_DATA_DIR = $dataB
  AKPI_PORT = "$PortB"
  AKPI_HEARTBEAT_PORT = "$HeartbeatB"
  AKPI_DISCOVERY_PORT = "$DiscoveryB"
  AKPI_CONTROL_PORT = "$ControlB"
  AKPI_HEARTBEAT_TARGET_PORTS = "$HeartbeatA,$HeartbeatB"
  AKPI_ENABLE_COMPACTION_LOOP = "0"
  AKPI_ENABLE_DEVICE_DEDUPE = "0"
  AKPI_DISABLE_STORAGE_SYNC = "1"
  AKPI_DISABLE_QUEUE_RETRY = "1"
  AKPI_DISABLE_WAITING_ROOM = "1"
}

try {
  $baseA = "http://127.0.0.1:$PortA"
  $baseB = "http://127.0.0.1:$PortB"

  if (!(Wait-Healthy $baseA)) { throw "NodeA not healthy" }
  if (!(Wait-Healthy $baseB)) { throw "NodeB not healthy" }

  $bootA = Bootstrap -BaseUrl $baseA -Hw $HardwareId
  $bootB = Bootstrap -BaseUrl $baseB -Hw $HardwareId
  $tokenA = [string]$bootA.token
  $tokenB = [string]$bootB.token
  if ([string]::IsNullOrWhiteSpace($tokenA) -or [string]::IsNullOrWhiteSpace($tokenB)) {
    throw "Token bootstrap kosong"
  }

  Start-Sleep -Seconds 3
  $peersA = @(Invoke-RestMethod -Method GET -Uri "$baseA/api/peers")
  $peersB = @(Invoke-RestMethod -Method GET -Uri "$baseB/api/peers")
  Write-Host "[Peers] NodeA sees=$($peersA.Count), NodeB sees=$($peersB.Count)"

  $beforeAFile = Count-DeviceFiles -DataDir $dataA
  $beforeBFile = Count-DeviceFiles -DataDir $dataB
  $beforeAOp = Count-DevicesOpLog -BaseUrl $baseA
  $beforeBOp = Count-DevicesOpLog -BaseUrl $baseB
  Write-Host "[Before] A files=$beforeAFile oplog=$beforeAOp | B files=$beforeBFile oplog=$beforeBOp"

  for ($i=1; $i -le $PingCount; $i++) {
    $null = Ping -BaseUrl $baseA -Hw $HardwareId -Token $tokenA
    $null = Ping -BaseUrl $baseB -Hw $HardwareId -Token $tokenB
    if ($PingIntervalMs -gt 0) { Start-Sleep -Milliseconds $PingIntervalMs }
  }

  $afterAFile = Count-DeviceFiles -DataDir $dataA
  $afterBFile = Count-DeviceFiles -DataDir $dataB
  $afterAOp = Count-DevicesOpLog -BaseUrl $baseA
  $afterBOp = Count-DevicesOpLog -BaseUrl $baseB
  Write-Host "[After ] A files=$afterAFile oplog=$afterAOp | B files=$afterBFile oplog=$afterBOp"

  $dAFile = [int]$afterAFile - [int]$beforeAFile
  $dAOp   = [int]$afterAOp - [int]$beforeAOp
  $dBFile = [int]$afterBFile - [int]$beforeBFile
  $dBOp   = [int]$afterBOp - [int]$beforeBOp
  Write-Host "[Delta] A files=$dAFile oplog=$dAOp | B files=$dBFile oplog=$dBOp"

  $pass = ($dAFile -eq 0 -and $dAOp -eq 0 -and $dBFile -eq 0 -and $dBOp -eq 0)
  if ($pass) {
    Write-Host "[PASS] P2 valid: ping burst tidak menambah files_index/op_log devices di 2 node." -ForegroundColor Green
    exit 0
  } else {
    Write-Host "[FAIL] P2 gagal: ada growth files_index/op_log saat ping burst." -ForegroundColor Red
    exit 1
  }
}
finally {
  if ($procA -and !$procA.HasExited) { Stop-Process -Id $procA.Id -Force }
  if ($procB -and !$procB.HasExited) { Stop-Process -Id $procB.Id -Force }
}
