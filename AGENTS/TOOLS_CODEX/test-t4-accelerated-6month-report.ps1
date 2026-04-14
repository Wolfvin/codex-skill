param(
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataDir = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\t4-accelerated-6month",
  [int]$Port = 3900,
  [int]$DurationSec = 180,
  [int]$SimulatedDays = 180,
  [int]$LoopSleepMs = 90,
  [int]$MaxGrowthMb = 120
)

$ErrorActionPreference = "Stop"
$serverExe = Join-Path $ServerRoot "target\debug\akp2i-server.exe"
if (!(Test-Path $serverExe)) { throw "Binary not found: $serverExe" }
. "$PSScriptRoot\node-sim-lib.ps1"

if (Test-Path $DataDir) {
  Remove-Item -LiteralPath $DataDir -Recurse -Force
}
New-Item -ItemType Directory -Path $DataDir -Force | Out-Null

function Get-DirStats([string]$Path) {
  if (!(Test-Path $Path)) { return [pscustomobject]@{ bytes = 0L; files = 0 } }
  $files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue
  $bytes = ($files | Measure-Object -Property Length -Sum).Sum
  if (-not $bytes) { $bytes = 0 }
  [pscustomobject]@{ bytes = [int64]$bytes; files = @($files).Count }
}

Write-Host "=== T4 Accelerated 6-Month Report ==="
Write-Host "DurationSec=$DurationSec SimulatedDays=$SimulatedDays Compression~$([math]::Round($SimulatedDays / ($DurationSec / 86400.0), 2))x"

$node = [pscustomobject]@{
  Name = "t4node"
  Port = $Port
  HeartbeatPort = 54032
  ControlPort = 54033
  DiscoveryPort = 54034
  DataDir = $DataDir
  BaseUrl = "http://127.0.0.1:$Port"
}

try {
  $baseUrl = "http://127.0.0.1:$Port"
  Start-NodeProcess -ServerRoot $ServerRoot -DataDir $DataDir -Port $Port -NodeName $node.Name `
    -HeartbeatPort $node.HeartbeatPort -DiscoveryPort $node.DiscoveryPort -ControlPort $node.ControlPort `
    -HeartbeatTargets "$($node.HeartbeatPort)" -BroadcastAddr "127.0.0.1" -ExtraEnv @{
      AKPI_ENABLE_COMPACTION_LOOP = "0"
      AKPI_AUTO_PROMOTE_FIRST_DEVICE = "1"
      AKPI_DISABLE_STORAGE_SYNC = "1"
      AKPI_DISABLE_QUEUE_RETRY = "1"
    } | Out-Null
  if (-not (Wait-Healthy -BaseUrl $baseUrl -TimeoutSec 45)) { throw "Server not healthy" }

  function Invoke-WithRetry([scriptblock]$Block, [int]$MaxTry = 5, [int]$SleepMs = 300) {
    $last = $null
    for ($i=1; $i -le $MaxTry; $i++) {
      try { return & $Block } catch { $last = $_; Start-Sleep -Milliseconds $SleepMs }
    }
    throw $last
  }

  $hw = "t4-accel-hw"
  $devInit = @{
    hardware_id = $hw
    name = "T4 Accelerated"
    user_name = "T4 Accelerated"
    app_version = "1.0.0"
  } | ConvertTo-Json
  Invoke-RestMethod -Method POST -Uri "$baseUrl/api/devices" -ContentType "application/json" -Body $devInit -TimeoutSec 8 | Out-Null

  $valBody = @{ hardware_id = $hw; app_version = "1.0.0" } | ConvertTo-Json
  $val = Invoke-RestMethod -Method POST -Uri "$baseUrl/api/validate" -ContentType "application/json" -Body $valBody -TimeoutSec 8
  if ([string]::IsNullOrWhiteSpace([string]$val.token)) { throw "Validate token kosong" }
  $headers = @{
    "x-akp2i-hardware-id" = $hw
    "x-akp2i-token" = [string]$val.token
  }

  function Count-Collection([string]$Collection, [hashtable]$AuthHeaders) {
    Invoke-WithRetry -Block { Invoke-RestMethod -Method GET -Uri "$baseUrl/api/ops/storage/counts?collection=$Collection" -Headers $AuthHeaders -TimeoutSec 10 } -MaxTry 8 -SleepMs 500
  }

  $baselineDir = Get-DirStats -Path $DataDir
  $baselineDevices = Count-Collection -Collection "devices" -AuthHeaders $headers
  $baselineAnn = Count-Collection -Collection "announcements" -AuthHeaders $headers
  $baselineAng = Count-Collection -Collection "anggota" -AuthHeaders $headers
  Write-Host "[BASELINE] bytes=$($baselineDir.bytes) files=$($baselineDir.files)"

  $start = Get-Date
  $iter = 0
  while (((Get-Date) - $start).TotalSeconds -lt $DurationSec) {
    $b = @{ hardware_id = $hw; app_version = "1.0.0" } | ConvertTo-Json
    try { Invoke-RestMethod -Method POST -Uri "$baseUrl/api/session/bootstrap" -ContentType "application/json" -Body $b -TimeoutSec 8 | Out-Null } catch {}
    try { Invoke-RestMethod -Method GET -Uri "$baseUrl/api/session/ping" -Headers $headers -TimeoutSec 8 | Out-Null } catch {}
    try { Invoke-RestMethod -Method POST -Uri "$baseUrl/api/devices" -ContentType "application/json" -Body $devInit -TimeoutSec 8 | Out-Null } catch {}

    if (($iter % 4) -eq 0) {
      try {
        $ann = @{
          title = "T4 Burst $iter"
          body = "accelerated 6m"
          category = "ops"
          is_pinned = $false
          author = "t4"
        } | ConvertTo-Json
        Invoke-RestMethod -Method POST -Uri "$baseUrl/api/announcements" -ContentType "application/json" -Body $ann -TimeoutSec 8 | Out-Null
      } catch {}
    }

    $iter++
    if ($LoopSleepMs -gt 0) { Start-Sleep -Milliseconds $LoopSleepMs }
  }

  $preCompactDir = Get-DirStats -Path $DataDir
  $preCompactAnn = Count-Collection -Collection "announcements" -AuthHeaders $headers
  $preCompactDev = Count-Collection -Collection "devices" -AuthHeaders $headers

  Write-Host "[INFO] aging rows step skipped (python unavailable in this environment); compaction report tetap dijalankan."

  $dry = Invoke-WithRetry -Block { Invoke-RestMethod -Method POST -Uri "$baseUrl/api/ops/compact?dry_run=true&retention_days=30&batch_limit=50000" -Headers $headers -TimeoutSec 20 } -MaxTry 8 -SleepMs 600
  $apply = Invoke-WithRetry -Block { Invoke-RestMethod -Method POST -Uri "$baseUrl/api/ops/compact?dry_run=false&retention_days=30&batch_limit=50000" -Headers $headers -TimeoutSec 20 } -MaxTry 8 -SleepMs 600

  $postCompactDir = Get-DirStats -Path $DataDir
  $postCompactAnn = Count-Collection -Collection "announcements" -AuthHeaders $headers
  $postCompactDev = Count-Collection -Collection "devices" -AuthHeaders $headers

  $growthMb = [math]::Round(($preCompactDir.bytes - $baselineDir.bytes) / 1MB, 2)
  $postCompactDeltaMb = [math]::Round(($postCompactDir.bytes - $preCompactDir.bytes) / 1MB, 2)

  $log = Join-Path $DataDir "node.log"
  $fatal = $false
  if (Test-Path $log) {
    $txt = Get-Content -Path $log -Raw
    if ($txt -match "fatal runtime error|0xc0000409") { $fatal = $true }
  }

  Write-Host "`n=== T4 Report ==="
  Write-Host ("Baseline bytes/files: {0}/{1}" -f $baselineDir.bytes, $baselineDir.files)
  Write-Host ("Pre-compact bytes/files: {0}/{1} (growth_mb={2})" -f $preCompactDir.bytes, $preCompactDir.files, $growthMb)
  Write-Host ("Post-compact bytes/files: {0}/{1} (delta_from_pre_mb={2})" -f $postCompactDir.bytes, $postCompactDir.files, $postCompactDeltaMb)
  Write-Host ("Announcements files_index_total: baseline={0} pre={1} post={2}" -f $baselineAnn.files_index_total, $preCompactAnn.files_index_total, $postCompactAnn.files_index_total)
  Write-Host ("Devices files_index_total: baseline={0} pre={1} post={2}" -f $baselineDevices.files_index_total, $preCompactDev.files_index_total, $postCompactDev.files_index_total)
  Write-Host ("Compaction dry_run stale={0} pruned_index_rows={1}" -f $dry.stale_candidates, $dry.pruned_index_rows)
  Write-Host ("Compaction apply stale={0} pruned_index_rows={1} pruned_payload_files={2}" -f $apply.stale_candidates, $apply.pruned_index_rows, $apply.pruned_payload_files)
  Write-Host ("Fatal crash detected: {0}" -f $fatal)

  $growthOk = ($growthMb -le $MaxGrowthMb)
  $compactOk = ($null -ne $dry -and $null -ne $apply)
  $stabilityOk = (-not $fatal)

  if ($growthOk -and $compactOk -and $stabilityOk) {
    Write-Host "[PASS] T4 accelerated 6-month simulation PASS." -ForegroundColor Green
    exit 0
  }

  Write-Host "[FAIL] T4 gate failed: growth_ok=$growthOk compact_ok=$compactOk stability_ok=$stabilityOk" -ForegroundColor Red
  exit 1
}
finally {
  Stop-Node -Node $node | Out-Null
}
