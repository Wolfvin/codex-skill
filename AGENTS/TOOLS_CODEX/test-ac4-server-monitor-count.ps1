param(
  [int]$Port = 3030,
  [string]$DataDir = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\ac4-data",
  [switch]$ResetData
)

$ErrorActionPreference = "Stop"
$serverExe = "D:\Workspace\projects\akp2i_projects\server_lokal\target\debug\akp2i-server.exe"
if (!(Test-Path $serverExe)) { throw "Server binary not found: $serverExe" }

if ($ResetData -and (Test-Path $DataDir)) {
  Remove-Item -LiteralPath $DataDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $DataDir | Out-Null

$env:AKPI_DATA_DIR = $DataDir
$env:AKPI_PORT = "$Port"
$env:AKPI_HEARTBEAT_PORT = "47932"
$env:AKPI_DISCOVERY_PORT = "47934"
$env:AKPI_CONTROL_PORT = "47933"
$env:AKPI_ENABLE_COMPACTION_LOOP = "0"
$env:AKPI_DISABLE_QUEUE_RETRY = "1"
$env:AKPI_DISABLE_WAITING_ROOM = "1"

$baseUrl = "http://127.0.0.1:$Port"
Write-Host "=== AC4 Server Monitor Count ==="
Write-Host "BaseUrl : $baseUrl"
Write-Host "DataDir : $DataDir"
Write-Host ""

function Wait-Healthy([string]$Url) {
  for ($i = 0; $i -lt 40; $i++) {
    try {
      $resp = Invoke-RestMethod -Method GET -Uri "$Url/"
      if ($resp -match "AKP2I Server OK") { return $true }
    } catch {}
    Start-Sleep -Milliseconds 300
  }
  return $false
}

function Bootstrap([string]$Url, [string]$Hw) {
  $body = @{ hardware_id = $Hw; app_version = "1.0.0" } | ConvertTo-Json
  return Invoke-RestMethod -Method POST -Uri "$Url/api/session/bootstrap" -ContentType "application/json" -Body $body
}

function RegisterDevice([string]$Url, [string]$Hw, [string]$Nama) {
  $body = @{
    hardware_id = $Hw
    name = $Nama
    user_name = $Nama
    app_version = "1.0.0"
  } | ConvertTo-Json
  $lastErr = $null
  for ($i=1; $i -le 4; $i++) {
    try {
      Invoke-RestMethod -Method POST -Uri "$Url/api/devices" -ContentType "application/json" -Body $body -TimeoutSec 30 | Out-Null
      return $true
    } catch {
      $lastErr = $_
      Start-Sleep -Seconds 4
    }
  }
  if ($lastErr) { throw $lastErr }
  return $false
}

function Ping([string]$Url, [string]$Hw, [string]$Token) {
  $headers = @{
    "x-akp2i-hardware-id" = $Hw
    "x-akp2i-token" = $Token
  }
  return Invoke-RestMethod -Method GET -Uri "$Url/api/session/ping" -Headers $headers
}

$proc = Start-Process -FilePath $serverExe -PassThru
try {
  if (-not (Wait-Healthy $baseUrl)) { throw "Server not healthy: $baseUrl" }
  Start-Sleep -Seconds 8

  $hws = @(
    "ac4-hw-001",
    "ac4-hw-002",
    "ac4-hw-003"
  )

  foreach ($hw in $hws) {
    $null = RegisterDevice -Url $baseUrl -Hw $hw -Nama ("AC4 " + $hw)
    $boot = Bootstrap -Url $baseUrl -Hw $hw
    $token = [string]$boot.token
    if (-not [string]::IsNullOrWhiteSpace($token)) {
      for ($i=0; $i -lt 5; $i++) {
        $null = Ping -Url $baseUrl -Hw $hw -Token $token
      }
    }
  }

  $devices = @()
  for ($i=1; $i -le 5; $i++) {
    $tmp = Invoke-RestMethod -Method GET -Uri "$baseUrl/api/devices"
    $devices = @($tmp)
    if ($devices.Count -ge 3) { break }
    Start-Sleep -Seconds 2
  }
  $total = if ($devices -and $devices.Count -gt 0) { $devices.Count } else { 0 }
  $unique = @(
    $devices |
      ForEach-Object {
        if ($_.PSObject.Properties.Name -contains "hardware_id" -and -not [string]::IsNullOrWhiteSpace([string]$_.hardware_id)) {
          [string]$_.hardware_id
        } elseif ($_.PSObject.Properties.Name -contains "id" -and -not [string]::IsNullOrWhiteSpace([string]$_.id)) {
          [string]$_.id
        } else {
          ""
        }
      } |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
      Select-Object -Unique
  ).Count
  $expectedText = if ($unique -lt $total) { "$unique / $total" } else { "$total" }

  Write-Host "[INFO] total=$total unique=$unique expected_panel='$expectedText'"
  if ($total -ge 3 -and $unique -ge 3) {
    Write-Host "[PASS] AC4 data representatif: perhitungan unique/total valid." -ForegroundColor Green
    exit 0
  }
  Write-Host "[FAIL] AC4 gagal: data devices tidak sesuai ekspektasi minimum." -ForegroundColor Red
  exit 1
}
finally {
  if ($proc -and -not $proc.HasExited) {
    Stop-Process -Id $proc.Id -Force
  }
}
