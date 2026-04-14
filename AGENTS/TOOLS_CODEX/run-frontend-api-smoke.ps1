param(
  [string]$BaseUrl = "http://127.0.0.1:3000"
)

$ErrorActionPreference = "Stop"

Write-Host "[SMOKE] Running frontend API smoke test against $BaseUrl"
$env:SMOKE_BASE_URL = $BaseUrl
node ".\\AGENTS\\TOOLS_CODEX\\frontend-api-smoke.mjs"
