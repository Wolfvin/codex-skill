param(
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataRoot = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\t3-accelerated-soak",
  [int]$NodeCount = 10,
  [int]$BasePort = 3700,
  [int]$BaseHeartbeatPort = 53032,
  [int]$DurationSec = 150,
  [int]$SimulatedHours = 48,
  [int]$LoopSleepMs = 80,
  [int]$SampleEverySec = 15,
  [int]$MaxGrowthMb = 80
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\node-sim-lib.ps1"

function Get-DirStats([string]$Path) {
  if (!(Test-Path $Path)) { return [pscustomobject]@{ bytes = 0L; files = 0 } }
  $files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue
  $bytes = ($files | Measure-Object -Property Length -Sum).Sum
  if (-not $bytes) { $bytes = 0 }
  [pscustomobject]@{ bytes = [int64]$bytes; files = @($files).Count }
}

if (Test-Path $DataRoot) {
  Remove-Item -LiteralPath $DataRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $DataRoot -Force | Out-Null

$nodes = Build-NodeList -NodeCount $NodeCount -BasePort $BasePort -DataRoot $DataRoot -BaseHeartbeatPort $BaseHeartbeatPort -UdpStride 3
$hbTargets = ($nodes | ForEach-Object { $_.HeartbeatPort }) -join ","
$sampleTicks = [math]::Max(1, [int]($SampleEverySec * 1000 / [math]::Max(1, $LoopSleepMs)))

Write-Host "=== T3 Accelerated Soak ==="
Write-Host "NodeCount=$NodeCount DurationSec=$DurationSec SimulatedHours=$SimulatedHours"
Write-Host "Compression ~= $([math]::Round($SimulatedHours / ($DurationSec / 3600.0), 2))x"

try {
  foreach ($n in $nodes) {
    Start-NodeProcess -ServerRoot $ServerRoot -DataDir $n.DataDir -Port $n.Port -NodeName $n.Name `
      -HeartbeatPort $n.HeartbeatPort -DiscoveryPort $n.DiscoveryPort -ControlPort $n.ControlPort `
      -HeartbeatTargets $hbTargets -BroadcastAddr "127.0.0.1" -ExtraEnv @{
        AKPI_ENABLE_COMPACTION_LOOP = "0"
      } | Out-Null
    Start-Sleep -Milliseconds 200
  }

  foreach ($n in $nodes) {
    if (-not (Wait-Healthy -BaseUrl $n.BaseUrl -TimeoutSec 50)) {
      throw "Node not healthy: $($n.Name)"
    }
  }
  Write-Host "[OK] all nodes healthy"

  $baseline = Get-DirStats -Path $DataRoot
  Write-Host "[BASELINE] bytes=$($baseline.bytes) files=$($baseline.files)"

  $trend = New-Object System.Collections.Generic.List[object]
  $start = Get-Date
  $iter = 0
  $tokenByNode = @{}

  while (((Get-Date) - $start).TotalSeconds -lt $DurationSec) {
    foreach ($n in $nodes) {
      $hw = "t3-hw-$($n.Name)"
      $bootBody = @{ hardware_id = $hw; app_version = "1.0.0" } | ConvertTo-Json
      try {
        $boot = Invoke-RestMethod -Method POST -Uri "$($n.BaseUrl)/api/session/bootstrap" -ContentType "application/json" -Body $bootBody -TimeoutSec 8
        $tokenByNode[$n.Name] = [string]$boot.token
      } catch {}

      try {
        $devBody = @{
          hardware_id = $hw
          name = "T3 SOAK $($n.Name)"
          user_name = "T3 SOAK $($n.Name)"
          app_version = "1.0.0"
        } | ConvertTo-Json
        Invoke-RestMethod -Method POST -Uri "$($n.BaseUrl)/api/devices" -ContentType "application/json" -Body $devBody -TimeoutSec 8 | Out-Null
      } catch {}

      $tk = $tokenByNode[$n.Name]
      if ($tk) {
        try {
          Invoke-RestMethod -Method GET -Uri "$($n.BaseUrl)/api/session/ping" -Headers @{
            "x-akp2i-hardware-id" = $hw
            "x-akp2i-token" = $tk
          } -TimeoutSec 8 | Out-Null
        } catch {}
      }
    }

    if (($iter % 8) -eq 0) {
      try {
        $ann = @{
          title = "T3 Burst $iter"
          body = "accelerated soak"
          category = "ops"
          is_pinned = $false
          author = "t3"
        } | ConvertTo-Json
        Invoke-RestMethod -Method POST -Uri "$($nodes[0].BaseUrl)/api/announcements" -ContentType "application/json" -Body $ann -TimeoutSec 8 | Out-Null
      } catch {}
    }

    if (($iter % $sampleTicks) -eq 0) {
      $s = Get-DirStats -Path $DataRoot
      $elapsed = [int](((Get-Date) - $start).TotalSeconds)
      $trend.Add([pscustomobject]@{ sec = $elapsed; bytes = $s.bytes; files = $s.files })
      Write-Host ("[SAMPLE] t={0}s bytes={1} files={2}" -f $elapsed, $s.bytes, $s.files)
    }

    $iter++
    if ($LoopSleepMs -gt 0) { Start-Sleep -Milliseconds $LoopSleepMs }
  }

  $final = Get-DirStats -Path $DataRoot
  $deltaBytes = [int64]($final.bytes - $baseline.bytes)
  $deltaMb = [math]::Round($deltaBytes / 1MB, 2)
  Write-Host "[FINAL] bytes=$($final.bytes) files=$($final.files) delta_mb=$deltaMb"

  $down = @()
  $downDiag = @()
  $fatal = @()
  foreach ($n in $nodes) {
    # Gunakan timeout lebih longgar agar tidak false-negative saat CPU spike.
    $isHealthy = Wait-Healthy -BaseUrl $n.BaseUrl -TimeoutSec 15
    if (-not $isHealthy) {
      $down += $n.Name
      $pidFile = Join-Path $n.DataDir "node.pid"
      $pid = if (Test-Path $pidFile) { (Get-Content $pidFile | Select-Object -First 1) } else { $null }
      $pidAlive = $false
      if ($pid) {
        $pidAlive = (Get-Process -Id $pid -ErrorAction SilentlyContinue) -ne $null
      }
      $portListening = $false
      try {
        $portListening = (Get-NetTCPConnection -LocalPort $n.Port -State Listen -ErrorAction Stop) -ne $null
      } catch {}
      $log = Join-Path $n.DataDir "node.log"
      $tail = ""
      if (Test-Path $log) {
        $tail = (Get-Content -Path $log | Select-Object -Last 5) -join " | "
      }
      $downDiag += "[diag $($n.Name)] pid=$pid pid_alive=$pidAlive port_listen=$portListening tail=$tail"
    }
    $log = Join-Path $n.DataDir "node.log"
    if (Test-Path $log) {
      $txt = Get-Content -Path $log -Raw
      if ($txt -match "fatal runtime error|0xc0000409") { $fatal += $n.Name }
    }
  }

  $growthOk = ($deltaMb -le $MaxGrowthMb)
  $stabilityOk = ($down.Count -eq 0 -and $fatal.Count -eq 0)

  Write-Host ("[GATE] stability_ok={0} growth_ok={1} max_growth_mb={2}" -f $stabilityOk, $growthOk, $MaxGrowthMb)
  if ($downDiag.Count -gt 0) {
    Write-Host "[DIAG] Down node details:"
    $downDiag | ForEach-Object { Write-Host $_ }
  }

  if ($stabilityOk -and $growthOk) {
    Write-Host "[PASS] T3 accelerated soak PASS (no fatal crash + growth terkendali)." -ForegroundColor Green
    exit 0
  }

  Write-Host "[FAIL] T3 gate failed: down=[$($down -join ',')] fatal=[$($fatal -join ',')] delta_mb=$deltaMb" -ForegroundColor Red
  exit 1
}
finally {
  foreach ($n in $nodes) { Stop-Node -Node $n | Out-Null }
}
