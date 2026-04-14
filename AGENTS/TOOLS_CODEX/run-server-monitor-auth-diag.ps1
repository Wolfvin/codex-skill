param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [string]$HardwareId = "",
  [string]$Token = "",
  [int]$TimeoutSec = 8
)

function Invoke-Api {
  param(
    [string]$Method,
    [string]$Path,
    $Body = $null,
    [hashtable]$Headers = @{}
  )
  $uri = "$BaseUrl$Path"
  try {
    if ($null -ne $Body) {
      $json = $Body | ConvertTo-Json -Depth 6
      Invoke-RestMethod -Method $Method -Uri $uri -Headers $Headers -ContentType "application/json" -Body $json -TimeoutSec $TimeoutSec | Out-Null
    } else {
      Invoke-RestMethod -Method $Method -Uri $uri -Headers $Headers -TimeoutSec $TimeoutSec | Out-Null
    }
    Write-Host "[OK] $Method $Path"
  } catch {
    $msg = $_.Exception.Message
    Write-Host "[FAIL] $Method $Path -> $msg"
  }
}

Write-Host "=== Server Monitor Auth Diag ==="
Write-Host "BaseUrl    : $BaseUrl"
Write-Host "HardwareId : $HardwareId"
Write-Host "Token      : " + ($(if ($Token) { "***set***" } else { "***empty***" }))

$headers = @{}
if ($HardwareId) { $headers["x-akp2i-hardware-id"] = $HardwareId }
if ($Token) { $headers["x-akp2i-token"] = $Token }

Write-Host "`n=== Identity Conflicts (GET) ==="
Invoke-Api -Method "GET" -Path "/identity/conflict/list?status=pending_rebind&limit=200" -Headers $headers

Write-Host "`n=== Device Slots (GET) ==="
Invoke-Api -Method "GET" -Path "/api/devices/slots" -Headers $headers

Write-Host "`n=== Device Slots Add (POST) ==="
Invoke-Api -Method "POST" -Path "/api/devices/slots/add" -Body @{ amount = 1 } -Headers $headers
