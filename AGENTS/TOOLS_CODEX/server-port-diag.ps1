param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [int]$TimeoutSec = 4
)

Write-Host "=== Server Port Diag ==="
Write-Host "BaseUrl    : $BaseUrl"
Write-Host "TimeoutSec : $TimeoutSec"

function Try-HttpGet($url) {
  try {
    $resp = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec $TimeoutSec
    return @{ ok = $true; status = $resp.StatusCode }
  } catch {
    return @{ ok = $false; error = $_.Exception.Message }
  }
}

function Get-ServerPids() {
  $procs = Get-Process akp2i-server -ErrorAction SilentlyContinue
  if ($null -eq $procs) { return @() }
  return @($procs | ForEach-Object { $_.Id })
}

function Get-ListenPortsForPid($procIdParam) {
  $rows = netstat -ano | Select-String -Pattern "LISTENING" | Select-String -Pattern (" " + $procIdParam + "$")
  $ports = @()
  foreach ($r in $rows) {
    $line = ($r.Line -replace "\s+", " ").Trim()
    $parts = $line.Split(" ")
    if ($parts.Length -ge 2) {
      $local = $parts[1]
      $port = $local.Split(":")[-1]
      if ($port -match "^\d+$") { $ports += $port }
    }
  }
  return $ports | Select-Object -Unique
}

$procIds = Get-ServerPids
if ($procIds.Count -eq 0) {
  Write-Host "[FAIL] akp2i-server process not running"
} else {
  Write-Host "[OK] akp2i-server PID(s): $($procIds -join ', ')"
}

$allPorts = @()
foreach ($procId in $procIds) {
  $ports = Get-ListenPortsForPid $procId
  if ($ports.Count -gt 0) {
    Write-Host "[OK] PID $procId listening ports: $($ports -join ', ')"
    $allPorts += $ports
  } else {
    Write-Host "[WARN] PID $procId has no LISTENING ports"
  }
}

$allPorts = $allPorts | Select-Object -Unique
if ($allPorts.Count -eq 0) {
  Write-Host "[WARN] No listening ports detected for akp2i-server"
}

Write-Host "`n=== HTTP Probe ==="
$probe = Try-HttpGet $BaseUrl
if ($probe.ok) {
  Write-Host "[OK] GET $BaseUrl -> $($probe.status)"
} else {
  Write-Host "[FAIL] GET $BaseUrl -> $($probe.error)"
}

if ($BaseUrl -notmatch "127\.0\.0\.1") {
  $localProbe = Try-HttpGet "http://127.0.0.1:3000"
  if ($localProbe.ok) {
    Write-Host "[OK] GET http://127.0.0.1:3000 -> $($localProbe.status)"
  } else {
    Write-Host "[FAIL] GET http://127.0.0.1:3000 -> $($localProbe.error)"
  }
}

Write-Host "`n=== Next Actions (if FAIL) ==="
Write-Host "- If PID exists but no LISTENING port: server failed to bind (check log after startup)."
Write-Host "- If 127.0.0.1 works but LAN fails: firewall or wrong IP."
Write-Host "- If neither works: restart backend, ensure port not in use."
