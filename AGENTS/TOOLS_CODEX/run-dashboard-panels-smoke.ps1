param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [int]$TimeoutSec = 8,
  [int]$RetryCount = 2
)

function Write-Section($title) {
  Write-Host ""
  Write-Host ("=== {0} ===" -f $title)
}

function Write-Ok($msg) { Write-Host ("[OK] {0}" -f $msg) }
function Write-Warn($msg) { Write-Host ("[WARN] {0}" -f $msg) }
function Write-Fail($msg) { Write-Host ("[FAIL] {0}" -f $msg) }

function Invoke-HealthCheck($url) {
  try {
    $resp = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec $TimeoutSec
    return ($resp.StatusCode -eq 200)
  } catch {
    return $false
  }
}

function Invoke-JsonGet($path) {
  return Invoke-RestMethod -Method GET -Uri ("{0}{1}" -f $BaseUrl, $path) -TimeoutSec $TimeoutSec
}

Write-Section "Preflight Health"
$healthy = $false
for ($i = 1; $i -le $RetryCount; $i++) {
  if (Invoke-HealthCheck $BaseUrl) { $healthy = $true; break }
  Start-Sleep -Seconds 1
}
if (-not $healthy) {
  Write-Fail ("Health check gagal: {0}" -f $BaseUrl)
  exit 1
}
Write-Ok ("Healthy base URL: {0}" -f $BaseUrl)

Write-Section "Dashboard Stats"
try {
  $stats = Invoke-JsonGet "/api/stats"
  if ($null -eq $stats) { throw "stats null" }
  Write-Ok "/api/stats OK"
} catch {
  Write-Fail ("/api/stats gagal: {0}" -f $_.Exception.Message)
  exit 2
}

Write-Section "Dashboard Panels"
$endpoints = @(
  "/api/dashboard/activity",
  "/api/dashboard/recent-docs",
  "/api/dashboard/deadlines",
  "/api/dashboard/members-preview",
  "/api/dashboard/donut"
)

$fail = 0
foreach ($ep in $endpoints) {
  try {
    $res = Invoke-JsonGet $ep
    Write-Ok ("{0} OK" -f $ep)
  } catch {
    $fail++
    Write-Warn ("{0} gagal: {1}" -f $ep, $_.Exception.Message)
  }
}

if ($fail -gt 0) {
  Write-Fail ("Dashboard panel smoke FAIL: {0} endpoint gagal" -f $fail)
  exit 3
}

Write-Section "Result"
Write-Ok "Dashboard smoke PASS"
exit 0
