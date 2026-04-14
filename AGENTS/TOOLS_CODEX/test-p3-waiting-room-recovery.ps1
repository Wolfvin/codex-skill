param(
  [int]$Port = 3030,
  [string]$HardwareId = "eb631723-7fb8-41a9-8543-87038070062d",
  [string]$DataDir = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\p3-waiting-room",
  [int]$RetryIntervalMs = 2000,
  [int]$PollIntervalSecs = 1,
  [switch]$ResetData
)

$ErrorActionPreference = "Stop"
$serverExe = "D:\Workspace\projects\akp2i_projects\server_lokal\target\debug\akp2i-server.exe"
if (!(Test-Path $serverExe)) { throw "Binary not found: $serverExe" }

if ($ResetData -and (Test-Path $DataDir)) {
  Remove-Item -LiteralPath $DataDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $DataDir | Out-Null

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

function WaitingStats([string]$BaseUrl, [string]$Hw, [string]$Token) {
  $headers = @{
    "x-akp2i-hardware-id" = $Hw
    "x-akp2i-token" = $Token
  }
  Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/ops/waiting-room/stats" -Headers $headers
}

function Post-Announcement([string]$BaseUrl, [string]$TitleSuffix) {
  $body = @{
    title = "P3 test $TitleSuffix"
    body = "fault injection waiting room"
    category = "ops"
    is_pinned = $false
    author = "p3-tester"
  } | ConvertTo-Json
  Invoke-RestMethod -Method POST -Uri "$BaseUrl/api/announcements" -ContentType "application/json" -Body $body
}

Write-Host "=== P3 Waiting Room Recovery Test ==="
Write-Host "BaseUrl         : http://127.0.0.1:$Port"
Write-Host "DataDir         : $DataDir"
Write-Host "RetryIntervalMs : $RetryIntervalMs"
Write-Host "PollIntervalSec : $PollIntervalSecs"
Write-Host ""

$envCmd = @(
  "`$env:AKPI_DATA_DIR='$DataDir'",
  "`$env:AKPI_PORT='$Port'",
  "`$env:AKPI_ENABLE_COMPACTION_LOOP='0'",
  "`$env:AKPI_DISABLE_STORAGE_SYNC='1'",
  "`$env:AKPI_DISABLE_QUEUE_RETRY='1'",
  "`$env:AKPI_DISABLE_WAITING_ROOM='0'",
  "`$env:AKPI_WAITING_ROOM_RETRY_INTERVAL_MS='$RetryIntervalMs'",
  "`$env:AKPI_WAITING_ROOM_POLL_INTERVAL_SECS='$PollIntervalSecs'",
  "`$env:AKPI_ALLOW_LOCAL_OPS_NOAUTH='1'",
  "`$env:AKPI_TEST_FORCE_DB_OPEN_FAIL_COLLECTIONS='announcements'",
  "`$env:AKPI_TEST_FORCE_DB_OPEN_FAIL_COUNT='1'",
  "& '$($serverExe.Replace("'", "''"))'"
) -join "; "
$encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($envCmd))
$proc = Start-Process -FilePath "powershell" -ArgumentList @("-NoProfile", "-EncodedCommand", $encoded) -PassThru

try {
  $baseUrl = "http://127.0.0.1:$Port"
  if (!(Wait-Healthy $baseUrl)) { throw "Server not healthy" }

  $boot = Bootstrap -BaseUrl $baseUrl -Hw $HardwareId
  $token = [string]$boot.token
  if ([string]::IsNullOrWhiteSpace($token)) { throw "Bootstrap token kosong" }
  Write-Host "[Bootstrap] ok=$($boot.ok) role=$($boot.role)"

  $before = WaitingStats -BaseUrl $baseUrl -Hw $HardwareId -Token $token
  Write-Host "[Before] waiting_room total=$($before.total) due_now=$($before.due_now) max_retry=$($before.max_retry_count)"

  $null = Post-Announcement -BaseUrl $baseUrl -TitleSuffix "locked"
  Write-Host "[Trigger] POST /api/announcements sent (forced db_open_failed test hook, count=1)"

  $queuedObserved = $false
  for ($i=0; $i -lt 50; $i++) {
    $mid = WaitingStats -BaseUrl $baseUrl -Hw $HardwareId -Token $token
    Write-Host "[Observe-$i] total=$($mid.total) due_now=$($mid.due_now) max_retry=$($mid.max_retry_count)"
    if ([int]$mid.total -gt 0) { $queuedObserved = $true; break }
    Start-Sleep -Seconds 1
  }
  if (-not $queuedObserved) {
    throw "Queue tidak pernah terisi saat fault lock"
  }

  $drained = $false
  for ($i=0; $i -lt 80; $i++) {
    $after = WaitingStats -BaseUrl $baseUrl -Hw $HardwareId -Token $token
    Write-Host "[Recover-$i] total=$($after.total) due_now=$($after.due_now) max_retry=$($after.max_retry_count)"
    if ([int]$after.total -eq 0) { $drained = $true; break }
    Start-Sleep -Seconds 1
  }

  if ($drained) {
    Write-Host "[PASS] P3 waiting room naik saat fault, lalu turun ke 0 saat recovery." -ForegroundColor Green
    exit 0
  } else {
    Write-Host "[FAIL] waiting room tidak drain ke 0 setelah recovery." -ForegroundColor Red
    exit 1
  }
}
finally {
  if ($proc -and !$proc.HasExited) {
    Stop-Process -Id $proc.Id -Force
  }
}
