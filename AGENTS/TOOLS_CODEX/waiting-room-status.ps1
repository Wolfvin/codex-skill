param(
  [string]$DataDir = "$env:LOCALAPPDATA\Smart Tax Assistance\server\lokal",
  [switch]$Detail
)

$dbPath = Join-Path $DataDir "waiting_room.db"
if (-not (Test-Path $dbPath)) {
  Write-Host "[WARN] waiting_room.db not found at $dbPath"
  exit 0
}

$duckdb = Get-Command duckdb -ErrorAction SilentlyContinue
$sqlite = Get-Command sqlite3 -ErrorAction SilentlyContinue
if (-not $duckdb -and -not $sqlite) {
  Write-Host "[FAIL] duckdb/sqlite3 not found in PATH. Install duckdb (recommended) or sqlite3."
  exit 1
}

$query = if ($Detail) {
  @"
SELECT op_id, collection, file_path, retry_count, last_error, next_retry_at_ms, inserted_at_ms, updated_at_ms
FROM waiting_room
ORDER BY next_retry_at_ms ASC;
"@
} else {
  @"
SELECT COUNT(*) AS total,
       MIN(next_retry_at_ms) AS next_retry_at_ms,
       MAX(retry_count) AS max_retry
FROM waiting_room;
"@
}

Write-Host "[INFO] waiting_room.db: $dbPath"
if ($duckdb) {
  duckdb $dbPath $query
} else {
  sqlite3 $dbPath $query
}
