param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [string]$HardwareId = "",
  [string]$Token = "",
  [switch]$RunInternal,
  [switch]$RunPeers,
  [switch]$RunUpload,
  [switch]$RunDevicesWrite,
  [int]$TimeoutSec = 8
)

$ErrorActionPreference = "Stop"

function New-Result($name, $status, $detail = "") {
  [PSCustomObject]@{ name = $name; status = $status; detail = $detail }
}

function Invoke-Json($method, $path, $body = $null, $headers = $null) {
  $uri = "$BaseUrl$path"
  $opts = @{ Method = $method; Uri = $uri; TimeoutSec = $TimeoutSec }
  if ($headers) { $opts.Headers = $headers }
  if ($body -ne $null) {
    $opts.ContentType = "application/json"
    $opts.Body = ($body | ConvertTo-Json -Depth 8)
  }
  Invoke-RestMethod @opts
}

$results = @()

if (-not $HardwareId) { $HardwareId = [guid]::NewGuid().ToString() }

Write-Host "[COVERAGE] BaseUrl=$BaseUrl"
Write-Host "[COVERAGE] HWID=$HardwareId"

# 1) Auth/session
try {
  $res = Invoke-Json POST "/api/session/bootstrap" @{ hardware_id = $HardwareId; app_version = "1.0.0" }
  $results += New-Result "POST /api/session/bootstrap" "OK"
  if (-not $Token -and $res.token) { $Token = $res.token }
} catch { $results += New-Result "POST /api/session/bootstrap" "FAIL" $_.Exception.Message }

try {
  $res = Invoke-Json GET "/api/session/ping" $null
  $results += New-Result "GET /api/session/ping" "OK"
} catch { $results += New-Result "GET /api/session/ping" "FAIL" $_.Exception.Message }

try {
  $res = Invoke-Json POST "/api/validate" @{ hardware_id = $HardwareId; app_version = "1.0.0" }
  $results += New-Result "POST /api/validate" "OK"
  if (-not $Token -and $res.token) { $Token = $res.token }
} catch { $results += New-Result "POST /api/validate" "FAIL" $_.Exception.Message }

try {
  $res = Invoke-Json POST "/api/client-log" @{ level = "info"; message = "smoke"; context = "api-coverage" }
  $results += New-Result "POST /api/client-log" "OK"
} catch { $results += New-Result "POST /api/client-log" "FAIL" $_.Exception.Message }

# 2) Devices
$authHeaders = @{}
if ($Token) { $authHeaders["x-akp2i-token"] = $Token }
if ($HardwareId) { $authHeaders["x-akp2i-hardware-id"] = $HardwareId }

try {
  $res = Invoke-Json GET "/api/devices" $null
  $results += New-Result "GET /api/devices" "OK"
} catch { $results += New-Result "GET /api/devices" "FAIL" $_.Exception.Message }

try {
  $res = Invoke-Json GET "/api/devices/slots" $null $authHeaders
  $results += New-Result "GET /api/devices/slots" "OK"
} catch { $results += New-Result "GET /api/devices/slots" "FAIL" $_.Exception.Message }

if ($RunDevicesWrite) {
  try {
    $res = Invoke-Json POST "/api/devices" @{ name = "Coverage Device"; hardware_id = $HardwareId; user_name = "Coverage User"; app_version = "1.0.0" }
    $results += New-Result "POST /api/devices" "OK"
  } catch { $results += New-Result "POST /api/devices" "FAIL" $_.Exception.Message }

  try {
    $res = Invoke-Json PATCH "/api/devices/$HardwareId" @{ is_active = $true } $authHeaders
    $results += New-Result "PATCH /api/devices/:id" "OK"
  } catch { $results += New-Result "PATCH /api/devices/:id" "FAIL" $_.Exception.Message }
}

try {
  $res = Invoke-Json POST "/api/devices/slots/add" @{ amount = 1 } $authHeaders
  $results += New-Result "POST /api/devices/slots/add" "OK"
} catch { $results += New-Result "POST /api/devices/slots/add" "FAIL" $_.Exception.Message }

try {
  $res = Invoke-Json GET "/api/owner/stats" $null $authHeaders
  $results += New-Result "GET /api/owner/stats" "OK"
} catch { $results += New-Result "GET /api/owner/stats" "FAIL" $_.Exception.Message }

# 3) Anggota flow
try {
  $res = Invoke-Json POST "/api/anggota/check" @{ hardware_id = $HardwareId }
  $results += New-Result "POST /api/anggota/check" "OK"
} catch { $results += New-Result "POST /api/anggota/check" "FAIL" $_.Exception.Message }

try {
  $res = Invoke-Json POST "/api/anggota/self-register" @{ hardware_id = $HardwareId; nama = "Coverage User"; role = "anggota"; status = "aktif" }
  $results += New-Result "POST /api/anggota/self-register" "OK"
} catch { $results += New-Result "POST /api/anggota/self-register" "FAIL" $_.Exception.Message }

if ($RunUpload) {
  $results += New-Result "POST /api/upload/avatar" "SKIP" "Use -RunUpload with file support"
} else {
  $results += New-Result "POST /api/upload/avatar" "SKIP" "Use -RunUpload with file support"
}

# 4) Peers / server ops
try {
  $res = Invoke-Json GET "/api/peers" $null
  $results += New-Result "GET /api/peers" "OK"
} catch { $results += New-Result "GET /api/peers" "FAIL" $_.Exception.Message }

try {
  $res = Invoke-Json GET "/api/server/status" $null
  $results += New-Result "GET /api/server/status" "OK"
} catch { $results += New-Result "GET /api/server/status" "FAIL" $_.Exception.Message }

if ($RunPeers) {
  try {
    $res = Invoke-Json POST "/api/server/promote-self" @{ password = "" } $authHeaders
    $results += New-Result "POST /api/server/promote-self" "OK"
  } catch { $results += New-Result "POST /api/server/promote-self" "FAIL" $_.Exception.Message }

  try {
    $res = Invoke-Json POST "/api/server/promote" @{ ip = "127.0.0.1"; password = "" } $authHeaders
    $results += New-Result "POST /api/server/promote" "OK"
  } catch { $results += New-Result "POST /api/server/promote" "FAIL" $_.Exception.Message }

  try {
    $res = Invoke-Json POST "/api/server/broadcast" @{ message = "ping" } $authHeaders
    $results += New-Result "POST /api/server/broadcast" "OK"
  } catch { $results += New-Result "POST /api/server/broadcast" "FAIL" $_.Exception.Message }
}

try {
  $res = Invoke-Json GET "/api/server/host-spec" $null
  $results += New-Result "GET /api/server/host-spec" "OK"
} catch { $results += New-Result "GET /api/server/host-spec" "FAIL" $_.Exception.Message }

try {
  $res = Invoke-Json POST "/api/server/host-spec" @{ cpu_logical = 4; ram_total_gb = 8; ram_free_gb = 4; disk_free_gb = 0; cpu_load_pct = 0 } $authHeaders
  $results += New-Result "POST /api/server/host-spec" "OK"
} catch { $results += New-Result "POST /api/server/host-spec" "FAIL" $_.Exception.Message }

# 5) Internal / ops (optional)
if ($RunInternal) {
  try { $null = Invoke-Json GET "/api/ops/readiness" $null; $results += New-Result "GET /api/ops/readiness" "OK" } catch { $results += New-Result "GET /api/ops/readiness" "FAIL" $_.Exception.Message }
  try { $null = Invoke-Json GET "/api/ops/storage/latest" $null; $results += New-Result "GET /api/ops/storage/latest" "OK" } catch { $results += New-Result "GET /api/ops/storage/latest" "FAIL" $_.Exception.Message }
  try { $null = Invoke-Json POST "/api/internal/global/server/kill" @{ reason = "coverage" } $authHeaders; $results += New-Result "POST /api/internal/global/server/kill" "OK" } catch { $results += New-Result "POST /api/internal/global/server/kill" "FAIL" $_.Exception.Message }
  try { $null = Invoke-Json POST "/api/internal/global/server/force-update" @{ reason = "coverage" } $authHeaders; $results += New-Result "POST /api/internal/global/server/force-update" "OK" } catch { $results += New-Result "POST /api/internal/global/server/force-update" "FAIL" $_.Exception.Message }
  try { $null = Invoke-Json POST "/api/internal/global/device-approval/apply" @{ payload = @{} } $authHeaders; $results += New-Result "POST /api/internal/global/device-approval/apply" "OK" } catch { $results += New-Result "POST /api/internal/global/device-approval/apply" "FAIL" $_.Exception.Message }
  try { $null = Invoke-Json POST "/api/internal/storage/migration/bootstrap-export" @{ } $authHeaders; $results += New-Result "POST /api/internal/storage/migration/bootstrap-export" "OK" } catch { $results += New-Result "POST /api/internal/storage/migration/bootstrap-export" "FAIL" $_.Exception.Message }
}

# 6) Legacy sync (expected to FAIL)
try { $null = Invoke-Json GET "/api/sync/status" $null; $results += New-Result "GET /api/sync/status" "OK" } catch { $results += New-Result "GET /api/sync/status" "FAIL" $_.Exception.Message }
try { $null = Invoke-Json GET "/api/sync/dump" $null; $results += New-Result "GET /api/sync/dump" "OK" } catch { $results += New-Result "GET /api/sync/dump" "FAIL" $_.Exception.Message }
try { $null = Invoke-Json POST "/api/sync/apply" @{ } $authHeaders; $results += New-Result "POST /api/sync/apply" "OK" } catch { $results += New-Result "POST /api/sync/apply" "FAIL" $_.Exception.Message }

"" | Out-Null

Write-Host "\n=== COVERAGE RESULT ==="
$results | Format-Table -AutoSize

