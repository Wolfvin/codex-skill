param(
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataRoot = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\t2-soak-10nodes",
  [int]$NodeCount = 10,
  [int]$BasePort = 3400,
  [int]$BaseHeartbeatPort = 50032,
  [int]$DurationSec = 180,
  [int]$LoopSleepMs = 300,
  [switch]$Fast
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\node-sim-lib.ps1"

if (Test-Path $DataRoot) {
  Remove-Item -LiteralPath $DataRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $DataRoot -Force | Out-Null

$nodes = Build-NodeList -NodeCount $NodeCount -BasePort $BasePort -DataRoot $DataRoot -BaseHeartbeatPort $BaseHeartbeatPort -UdpStride 3
$hbTargets = ($nodes | ForEach-Object { $_.HeartbeatPort }) -join ","

Write-Host "=== T2 Soak 10 Nodes ==="
Write-Host "NodeCount=$NodeCount DurationSec=$DurationSec BasePort=$BasePort"
if ($Fast) {
  $DurationSec = 45
  $LoopSleepMs = 50
  Write-Host "[FAST] duration=$DurationSec loop_sleep_ms=$LoopSleepMs"
}

try {
  foreach ($n in $nodes) {
    Start-NodeProcess -ServerRoot $ServerRoot -DataDir $n.DataDir -Port $n.Port -NodeName $n.Name `
      -HeartbeatPort $n.HeartbeatPort -DiscoveryPort $n.DiscoveryPort -ControlPort $n.ControlPort `
      -HeartbeatTargets $hbTargets -BroadcastAddr "127.0.0.1" -ExtraEnv @{
        AKPI_ENABLE_COMPACTION_LOOP = "0"
        AKPI_DISABLE_QUEUE_RETRY = "1"
      } | Out-Null
    Start-Sleep -Milliseconds 200
  }

  foreach ($n in $nodes) {
    if (-not (Wait-Healthy -BaseUrl $n.BaseUrl -TimeoutSec 45)) {
      throw "Node not healthy: $($n.Name) $($n.BaseUrl)"
    }
  }
  Write-Host "[OK] all nodes healthy"

  $start = Get-Date
  $iter = 0
  while (((Get-Date) - $start).TotalSeconds -lt $DurationSec) {
    foreach ($n in $nodes) {
      $hw = "t2-soak-hw-$($n.Name)"
      $bootstrapBody = @{ hardware_id = $hw; app_version = "1.0.0" } | ConvertTo-Json
      try {
        $boot = Invoke-RestMethod -Method POST -Uri "$($n.BaseUrl)/api/session/bootstrap" -ContentType "application/json" -Body $bootstrapBody -TimeoutSec 8
        $token = [string]$boot.token
      } catch { $token = "" }

      try {
        $devBody = @{
          hardware_id = $hw
          name = "T2 SOAK $($n.Name)"
          user_name = "T2 SOAK $($n.Name)"
          app_version = "1.0.0"
        } | ConvertTo-Json
        Invoke-RestMethod -Method POST -Uri "$($n.BaseUrl)/api/devices" -ContentType "application/json" -Body $devBody -TimeoutSec 8 | Out-Null
      } catch {}

      if ($token) {
        try {
          Invoke-RestMethod -Method GET -Uri "$($n.BaseUrl)/api/session/ping" -Headers @{
            "x-akp2i-hardware-id" = $hw
            "x-akp2i-token" = $token
          } -TimeoutSec 8 | Out-Null
        } catch {}
      }
    }

    if (($iter % 5) -eq 0) {
      try {
        $aBody = @{
          title = "T2 Soak Iter $iter"
          body = "mixed workload"
          category = "ops"
          is_pinned = $false
          author = "t2-soak"
        } | ConvertTo-Json
        Invoke-RestMethod -Method POST -Uri "$($nodes[0].BaseUrl)/api/announcements" -ContentType "application/json" -Body $aBody -TimeoutSec 8 | Out-Null
      } catch {}
    }

    $iter++
    if ($LoopSleepMs -gt 0) { Start-Sleep -Milliseconds $LoopSleepMs }
  }

  $down = @()
  $fatal = @()
  foreach ($n in $nodes) {
    if (-not (Wait-Healthy -BaseUrl $n.BaseUrl -TimeoutSec 6)) { $down += $n.Name }
    $log = Join-Path $n.DataDir "node.log"
    if (Test-Path $log) {
      $txt = Get-Content -Path $log -Raw
      if ($txt -match "fatal runtime error|0xc0000409") { $fatal += $n.Name }
    }
  }

  if ($down.Count -eq 0 -and $fatal.Count -eq 0) {
    Write-Host "[PASS] Soak selesai: semua node up, tanpa crash fatal." -ForegroundColor Green
    exit 0
  }

  Write-Host "[FAIL] down=[$($down -join ',')] fatal=[$($fatal -join ',')]" -ForegroundColor Red
  exit 1
}
finally {
  foreach ($n in $nodes) { Stop-Node -Node $n | Out-Null }
}
