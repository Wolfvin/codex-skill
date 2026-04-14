param(
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataDir = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\ann-delete-stability",
  [int]$Port = 3920,
  [int]$Loops = 40
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\node-sim-lib.ps1"

if (Test-Path $DataDir) {
  Remove-Item -LiteralPath $DataDir -Recurse -Force
}
New-Item -ItemType Directory -Path $DataDir -Force | Out-Null

$node = [pscustomobject]@{
  Name = "annnode"
  Port = $Port
  HeartbeatPort = 54132
  ControlPort = 54133
  DiscoveryPort = 54134
  DataDir = $DataDir
  BaseUrl = "http://127.0.0.1:$Port"
}

Write-Host "=== Announcements Delete Stability ==="
Write-Host "BaseUrl=$($node.BaseUrl) loops=$Loops"

try {
  Start-NodeProcess -ServerRoot $ServerRoot -DataDir $DataDir -Port $Port -NodeName $node.Name `
    -HeartbeatPort $node.HeartbeatPort -DiscoveryPort $node.DiscoveryPort -ControlPort $node.ControlPort `
    -HeartbeatTargets "$($node.HeartbeatPort)" -BroadcastAddr "127.0.0.1" -ExtraEnv @{
      AKPI_ENABLE_COMPACTION_LOOP = "0"
      AKPI_DISABLE_STORAGE_SYNC = "1"
      AKPI_DISABLE_QUEUE_RETRY = "1"
      AKPI_AUTO_PROMOTE_FIRST_DEVICE = "1"
    } | Out-Null

  if (-not (Wait-Healthy -BaseUrl $node.BaseUrl -TimeoutSec 45)) { throw "Server unhealthy" }

  $hw = "ann-delete-hw"
  $devBody = @{
    hardware_id = $hw
    name = "Ann Delete Tester"
    user_name = "Ann Delete Tester"
    app_version = "1.0.0"
  } | ConvertTo-Json
  Invoke-RestMethod -Method POST -Uri "$($node.BaseUrl)/api/devices" -ContentType "application/json" -Body $devBody -TimeoutSec 8 | Out-Null

  $valBody = @{ hardware_id = $hw; app_version = "1.0.0" } | ConvertTo-Json
  $val = Invoke-RestMethod -Method POST -Uri "$($node.BaseUrl)/api/validate" -ContentType "application/json" -Body $valBody -TimeoutSec 8
  if ([string]::IsNullOrWhiteSpace([string]$val.token)) { throw "Token kosong" }
  $headers = @{
    "x-akp2i-hardware-id" = $hw
    "x-akp2i-token" = [string]$val.token
  }

  for ($i=1; $i -le $Loops; $i++) {
    $c = @{
      title = "DEL-$i"
      body = "delete-stability"
      category = "ops"
      is_pinned = $false
      author = "tester"
    } | ConvertTo-Json
    $null = Invoke-RestMethod -Method POST -Uri "$($node.BaseUrl)/api/announcements" -ContentType "application/json" -Body $c -TimeoutSec 8

    $list = @(Invoke-RestMethod -Method GET -Uri "$($node.BaseUrl)/api/announcements" -TimeoutSec 8)
    if ($list.Count -lt 1) { throw "Announcement tidak ditemukan setelah create loop=$i" }
    $target = $list | Select-Object -First 1
    $null = Invoke-RestMethod -Method DELETE -Uri "$($node.BaseUrl)/api/announcements/$($target.id)" -Headers $headers -TimeoutSec 8
  }

  Start-Sleep -Seconds 2
  if (-not (Wait-Healthy -BaseUrl $node.BaseUrl -TimeoutSec 6)) {
    throw "Server down setelah loop delete"
  }

  $log = Join-Path $DataDir "node.log"
  if (Test-Path $log) {
    $txt = Get-Content -Path $log -Raw
    if ($txt -match "fatal runtime error|0xc0000409|supersede_target_post_commit_failed") {
      throw "Terdeteksi fatal/supersede error di log"
    }
  }

  Write-Host "[PASS] Loop create/delete announcements stabil, tanpa crash/fatal." -ForegroundColor Green
  exit 0
}
finally {
  Stop-Node -Node $node | Out-Null
}

