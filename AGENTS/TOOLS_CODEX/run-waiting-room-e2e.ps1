param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [string]$HardwareId = "",
  [int]$PollSeconds = 60,
  [int]$MaxPollMinutes = 12
)

if (-not $HardwareId) {
  Write-Host "[FAIL] HardwareId is required. Example: -HardwareId \"eb631723-7fb8-41a9-8543-87038070062d\""
  exit 1
}

Write-Host "=== Waiting Room E2E ==="
Write-Host "BaseUrl     : $BaseUrl"
Write-Host "HardwareId  : $HardwareId"
Write-Host "PollSeconds : $PollSeconds"
Write-Host "MaxMinutes  : $MaxPollMinutes"

$body = @{ hardware_id = $HardwareId; app_version = "1.0.0" } | ConvertTo-Json
Write-Host "`n=== Trigger bootstrap (allowlist) ==="
try {
  Invoke-RestMethod -Method POST -Uri "$BaseUrl/api/session/bootstrap" -ContentType "application/json" -Body $body | Out-Null
  Write-Host "[OK] bootstrap triggered"
} catch {
  Write-Host "[WARN] bootstrap failed: $($_.Exception.Message)"
}

$dbPath = "$env:LOCALAPPDATA\Smart Tax Assistance\server\lokal\waiting_room.db"
$deadline = (Get-Date).AddMinutes($MaxPollMinutes)

Write-Host "`n=== Poll waiting_room.db ==="
while ((Get-Date) -lt $deadline) {
  try {
    $count = python -c "import duckdb, os; db=os.path.expandvars(r'%LOCALAPPDATA%\\Smart Tax Assistance\\server\\lokal\\waiting_room.db'); con=duckdb.connect(db); print(con.execute('SELECT COUNT(*) FROM waiting_room').fetchone()[0])" 2>$null
    Write-Host ("[{0}] waiting_room count = {1}" -f (Get-Date).ToString("HH:mm:ss"), $count)
    if ($count -eq "0") {
      Write-Host "[OK] waiting_room cleared"
      exit 0
    }
  } catch {
    Write-Host "[WARN] waiting_room query failed: $($_.Exception.Message)"
  }
  Start-Sleep -Seconds $PollSeconds
}

Write-Host "[WARN] waiting_room still not cleared within time window."
exit 2
