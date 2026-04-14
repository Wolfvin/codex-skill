param(
  [int]$Port = 3340,
  [string]$HardwareId = "eb631723-7fb8-41a9-8543-87038070062d",
  [string]$DataDir = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\ops-auth-debug",
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
  for ($i=0; $i -lt 50; $i++) {
    try {
      $r = Invoke-RestMethod -Method GET -Uri "$BaseUrl/" -TimeoutSec 3
      if ($r -match "AKP2I Server OK") { return $true }
    } catch {}
    Start-Sleep -Milliseconds 300
  }
  return $false
}

Write-Host "=== Debug Ops Auth Bootstrap ==="
Write-Host "BaseUrl : http://127.0.0.1:$Port"
Write-Host "DataDir : $DataDir"

$envCmd = @(
  "`$env:AKPI_DATA_DIR='$DataDir'",
  "`$env:AKPI_PORT='$Port'",
  "`$env:AKPI_ENABLE_COMPACTION_LOOP='0'",
  "`$env:AKPI_DISABLE_STORAGE_SYNC='1'",
  "& '$($serverExe.Replace("'", "''"))'"
) -join "; "
$encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($envCmd))
$proc = Start-Process -FilePath "powershell" -ArgumentList @("-NoProfile", "-EncodedCommand", $encoded) -PassThru

try {
  $baseUrl = "http://127.0.0.1:$Port"
  if (!(Wait-Healthy $baseUrl)) { throw "Server not healthy" }

  $body = @{ hardware_id = $HardwareId; app_version = "1.0.0" } | ConvertTo-Json
  $boot = Invoke-RestMethod -Method POST -Uri "$baseUrl/api/session/bootstrap" -ContentType "application/json" -Body $body
  Write-Host "[Bootstrap]" ($boot | ConvertTo-Json -Depth 6)

  $devices = Invoke-RestMethod -Method GET -Uri "$baseUrl/api/devices"
  Write-Host "[Devices]" ($devices | ConvertTo-Json -Depth 6)

  $headers = @{
    "x-akp2i-hardware-id" = $HardwareId
    "x-akp2i-token" = [string]$boot.token
  }

  try {
    $counts = Invoke-RestMethod -Method GET -Uri "$baseUrl/api/ops/storage/counts" -Headers $headers
    Write-Host "[OpsCounts] OK" ($counts | ConvertTo-Json -Depth 6)
  } catch {
    Write-Host "[OpsCounts] FAIL: $($_.Exception.Message)" -ForegroundColor Yellow
    if ($_.Exception.Response) {
      $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
      $reader.BaseStream.Position = 0
      $reader.DiscardBufferedData()
      $respBody = $reader.ReadToEnd()
      Write-Host "[OpsCountsBody] $respBody"
    }
  }
}
finally {
  if ($proc -and !$proc.HasExited) {
    Stop-Process -Id $proc.Id -Force
  }
}

