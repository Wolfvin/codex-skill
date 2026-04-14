param(
  [switch]$SkipB,
  [switch]$SkipC,
  [switch]$SkipD
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Run-Step {
  param(
    [string]$Name,
    [string]$ScriptPath,
    [string[]]$Args = @()
  )

  Write-Host ""
  Write-Host "=== $Name ===" -ForegroundColor Cyan
  Write-Host ("Script: {0} {1}" -f $ScriptPath, ($Args -join " "))

  $psi = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $ScriptPath
  ) + $Args

  $start = Get-Date
  # Jangan biarkan output child script masuk ke return stream function,
  # karena akan mencampur hasil object summary dengan string biasa.
  $null = & powershell @psi
  $code = $LASTEXITCODE
  $sec = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)

  if ($code -eq 0) {
    Write-Host "[PASS] $Name (${sec}s)" -ForegroundColor Green
    return [pscustomobject]@{ name = $Name; ok = $true; code = $code; sec = $sec }
  }

  Write-Host "[FAIL] $Name exit_code=$code (${sec}s)" -ForegroundColor Red
  return [pscustomobject]@{ name = $Name; ok = $false; code = $code; sec = $sec }
}

$root = "D:\Workspace\projects\akp2i_projects\AGENTS\TOOLS_CODEX"
$results = New-Object System.Collections.Generic.List[object]

Write-Host "=== B+C+D Fast Gate Runner ===" -ForegroundColor Yellow
Write-Host "SkipB=$SkipB SkipC=$SkipC SkipD=$SkipD"

if (-not $SkipB) {
  $results.Add((Run-Step -Name "B1 Crash Probe (FullSync-lite)" -ScriptPath (Join-Path $root "test-ac5-fullsync-crash.ps1") -Args @(
    "-NodeCount", "3",
    "-BasePort", "4200",
    "-BaseHeartbeatPort", "56132",
    "-BurstCount", "6",
    "-BurstIntervalMs", "120"
  )))

  $results.Add((Run-Step -Name "B2 Accelerated Soak (stability)" -ScriptPath (Join-Path $root "test-t3-accelerated-soak.ps1") -Args @(
    "-NodeCount", "3",
    "-BasePort", "4300",
    "-BaseHeartbeatPort", "57132",
    "-DurationSec", "90",
    "-SimulatedHours", "24",
    "-LoopSleepMs", "90",
    "-SampleEverySec", "10",
    "-MaxGrowthMb", "60"
  )))
}

if (-not $SkipC) {
  $results.Add((Run-Step -Name "C1 Server Monitor Count Consistency" -ScriptPath (Join-Path $root "test-ac4-server-monitor-count.ps1") -Args @(
    "-Port", "4030",
    "-DataDir", "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\ac4-fast",
    "-ResetData"
  )))
}

if (-not $SkipD) {
  $results.Add((Run-Step -Name "D1 Compaction Consistency" -ScriptPath (Join-Path $root "test-t1-compaction-consistency.ps1") -Args @(
    "-Port", "4336",
    "-DataDir", "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\t1-fast",
    "-ResetData"
  )))

  $results.Add((Run-Step -Name "D2 Accelerated 6-Month Retention Report" -ScriptPath (Join-Path $root "test-t4-accelerated-6month-report.ps1") -Args @(
    "-Port", "4900",
    "-DataDir", "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\t4-fast",
    "-DurationSec", "90",
    "-SimulatedDays", "180",
    "-LoopSleepMs", "100",
    "-MaxGrowthMb", "90"
  )))
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Yellow
$pass = 0
$fail = 0
foreach ($r in $results) {
  if (-not ($r -is [pscustomobject]) -or -not ($r.PSObject.Properties.Name -contains "ok")) {
    $fail++
    Write-Host ("[FAIL] Invalid summary object: {0}" -f ($r | Out-String).Trim())
    continue
  }
  if ($r.ok) { $pass++ } else { $fail++ }
  $state = if ($r.ok) { "PASS" } else { "FAIL" }
  Write-Host ("[{0}] {1} ({2}s)" -f $state, $r.name, $r.sec)
}
Write-Host ("TOTAL: pass={0} fail={1}" -f $pass, $fail)

if ($fail -gt 0) { exit 1 }
exit 0
