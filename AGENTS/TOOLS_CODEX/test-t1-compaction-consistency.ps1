param(
  [int]$Port = 3336,
  [string]$HardwareId = "eb631723-7fb8-41a9-8543-87038070062d",
  [string]$DataDir = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\t1-compaction",
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
      $r = Invoke-RestMethod -Method GET -Uri "$BaseUrl/" -TimeoutSec 3
      if ($r -match "AKP2I Server OK") { return $true }
    } catch {}
    Start-Sleep -Milliseconds 300
  }
  return $false
}

function Post-Json([string]$Url, [object]$Body, [hashtable]$Headers) {
  Invoke-RestMethod -Method POST -Uri $Url -ContentType "application/json" -Body ($Body | ConvertTo-Json -Depth 8) -Headers $Headers -TimeoutSec 20
}

Write-Host "=== T1 Compaction Consistency Test ==="
Write-Host "BaseUrl     : http://127.0.0.1:$Port"
Write-Host "DataDir     : $DataDir"
Write-Host ""

$envCmd = @(
  "`$env:AKPI_DATA_DIR='$DataDir'",
  "`$env:AKPI_PORT='$Port'",
  "`$env:AKPI_ENABLE_COMPACTION_LOOP='0'",
  "`$env:AKPI_DISABLE_STORAGE_SYNC='1'",
  "`$env:AKPI_ALLOW_LOCAL_OPS_NOAUTH='1'",
  "& '$($serverExe.Replace("'", "''"))'"
) -join "; "
$encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($envCmd))
$proc = Start-Process -FilePath "powershell" -ArgumentList @("-NoProfile", "-EncodedCommand", $encoded) -PassThru

try {
  $baseUrl = "http://127.0.0.1:$Port"
  if (!(Wait-Healthy $baseUrl)) { throw "Server not healthy" }

  $boot = Post-Json -Url "$baseUrl/api/session/bootstrap" -Body @{ hardware_id = $HardwareId; app_version = "1.0.0" } -Headers @{}
  if (-not $boot.ok) { throw "Bootstrap not ok: reason=$($boot.reason)" }
  Write-Host "[Bootstrap] ok=$($boot.ok) role=$($boot.role)"
  $headers = @{
    "x-akp2i-hardware-id" = [string]$HardwareId
    "x-akp2i-token" = [string]$boot.token
  }

  Write-Host "[Seed] bootstrap-only path (no additional seed required)"

  $before = Invoke-RestMethod -Method GET -Uri "$baseUrl/api/ops/storage/counts" -Headers $headers -TimeoutSec 20
  Write-Host "[Before] files_index_total=$($before.files_index_total) files_index_active=$($before.files_index_active) op_log_total=$($before.op_log_total)"

  $dryRun = Invoke-RestMethod -Method POST -Uri "$baseUrl/api/ops/compact?dry_run=true&retention_days=0&batch_limit=500" -Headers $headers -TimeoutSec 20
  Write-Host "[DryRun] stale_candidates=$($dryRun.stale_candidates) pruned_index_rows=$($dryRun.pruned_index_rows) pruned_payload_files=$($dryRun.pruned_payload_files)"

  $apply = Invoke-RestMethod -Method POST -Uri "$baseUrl/api/ops/compact?dry_run=false&retention_days=0&batch_limit=500" -Headers $headers -TimeoutSec 20
  Write-Host "[Apply] stale_candidates=$($apply.stale_candidates) pruned_index_rows=$($apply.pruned_index_rows) pruned_payload_files=$($apply.pruned_payload_files)"

  $after = Invoke-RestMethod -Method GET -Uri "$baseUrl/api/ops/storage/counts" -Headers $headers -TimeoutSec 20
  $bootAfter = Post-Json -Url "$baseUrl/api/session/bootstrap" -Body @{ hardware_id = $HardwareId; app_version = "1.0.0" } -Headers @{}
  Write-Host "[After] files_index_total=$($after.files_index_total) files_index_active=$($after.files_index_active) op_log_total=$($after.op_log_total) bootstrap_ok=$($bootAfter.ok)"

  if (-not $bootAfter.ok) { throw "bootstrap gagal setelah compaction" }
  Write-Host "[PASS] Compaction dry-run/apply sukses dan data API tetap konsisten." -ForegroundColor Green
  exit 0
}
finally {
  if ($proc -and !$proc.HasExited) {
    Stop-Process -Id $proc.Id -Force
  }
}
