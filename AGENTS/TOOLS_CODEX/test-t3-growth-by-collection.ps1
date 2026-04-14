param(
  [string]$ServerRoot = "D:\Workspace\projects\akp2i_projects\server_lokal",
  [string]$DataDir = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp\t3-growth-collection",
  [int]$Port = 3810,
  [int]$DurationSec = 90,
  [int]$LoopSleepMs = 120
)

$ErrorActionPreference = "Stop"
$serverExe = Join-Path $ServerRoot "target\debug\akp2i-server.exe"
if (!(Test-Path $serverExe)) { throw "Binary not found: $serverExe" }

if (Test-Path $DataDir) {
  Remove-Item -LiteralPath $DataDir -Recurse -Force
}
New-Item -ItemType Directory -Path $DataDir -Force | Out-Null

function Wait-Healthy([string]$BaseUrl) {
  for ($i=0; $i -lt 50; $i++) {
    try {
      $r = Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/" -TimeoutSec 3
      if ($r.StatusCode -eq 200) { return $true }
    } catch {}
    Start-Sleep -Milliseconds 300
  }
  return $false
}

Write-Host "=== T3 Growth by Collection ==="
$baseUrl = "http://127.0.0.1:$Port"
Write-Host "BaseUrl=$baseUrl DurationSec=$DurationSec"

$envCmd = @(
  "`$env:AKPI_DATA_DIR='$DataDir'",
  "`$env:AKPI_PORT='$Port'",
  "`$env:AKPI_ENABLE_COMPACTION_LOOP='0'",
  "`$env:AKPI_AUTO_PROMOTE_FIRST_DEVICE='1'",
  "& '$($serverExe.Replace("'", "''"))'"
) -join "; "
$encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($envCmd))
$proc = Start-Process -FilePath "powershell" -ArgumentList @("-NoProfile", "-EncodedCommand", $encoded) -PassThru

try {
  if (-not (Wait-Healthy -BaseUrl $baseUrl)) { throw "Server not healthy" }

  $hw = "t3-growth-hw"
  $devInit = @{
    hardware_id = $hw
    name = "T3 Growth"
    user_name = "T3 Growth"
    app_version = "1.0.0"
  } | ConvertTo-Json
  Invoke-RestMethod -Method POST -Uri "$baseUrl/api/devices" -ContentType "application/json" -Body $devInit -TimeoutSec 8 | Out-Null

  $valBody = @{ hardware_id = $hw; app_version = "1.0.0" } | ConvertTo-Json
  $val = Invoke-RestMethod -Method POST -Uri "$baseUrl/api/validate" -ContentType "application/json" -Body $valBody -TimeoutSec 8
  if ([string]::IsNullOrWhiteSpace([string]$val.token)) { throw "Validate token kosong" }
  $headers = @{
    "x-akp2i-hardware-id" = $hw
    "x-akp2i-token" = [string]$val.token
  }

  function Get-Counts([string]$Collection, [hashtable]$AuthHeaders) {
    Invoke-RestMethod -Method GET -Uri "$baseUrl/api/ops/storage/counts?collection=$Collection" -Headers $AuthHeaders -TimeoutSec 8
  }

  $beforeDevices = Get-Counts -Collection "devices" -AuthHeaders $headers
  $beforeAnggota = Get-Counts -Collection "anggota" -AuthHeaders $headers
  $beforeAnn = Get-Counts -Collection "announcements" -AuthHeaders $headers

  $start = Get-Date
  $iter = 0
  while (((Get-Date) - $start).TotalSeconds -lt $DurationSec) {
    $b = @{ hardware_id = $hw; app_version = "1.0.0" } | ConvertTo-Json
    try { Invoke-RestMethod -Method POST -Uri "$baseUrl/api/session/bootstrap" -ContentType "application/json" -Body $b -TimeoutSec 8 | Out-Null } catch {}
    try {
      $d = @{ hardware_id = $hw; name = "T3 Growth"; user_name = "T3 Growth"; app_version = "1.0.0" } | ConvertTo-Json
      Invoke-RestMethod -Method POST -Uri "$baseUrl/api/devices" -ContentType "application/json" -Body $d -TimeoutSec 8 | Out-Null
    } catch {}
    if (($iter % 5) -eq 0) {
      try {
        $ann = @{ title = "T3COLL $iter"; body = "growth"; category = "ops"; is_pinned = $false; author = "t3" } | ConvertTo-Json
        Invoke-RestMethod -Method POST -Uri "$baseUrl/api/announcements" -ContentType "application/json" -Body $ann -TimeoutSec 8 | Out-Null
      } catch {}
    }
    $iter++
    Start-Sleep -Milliseconds $LoopSleepMs
  }

  $afterDevices = Get-Counts -Collection "devices" -AuthHeaders $headers
  $afterAnggota = Get-Counts -Collection "anggota" -AuthHeaders $headers
  $afterAnn = Get-Counts -Collection "announcements" -AuthHeaders $headers

  $deltaDevices = [int]$afterDevices.files_index_total - [int]$beforeDevices.files_index_total
  $deltaAnggota = [int]$afterAnggota.files_index_total - [int]$beforeAnggota.files_index_total
  $deltaAnn = [int]$afterAnn.files_index_total - [int]$beforeAnn.files_index_total

  Write-Host "[devices] before=$($beforeDevices.files_index_total) after=$($afterDevices.files_index_total) delta=$deltaDevices"
  Write-Host "[anggota] before=$($beforeAnggota.files_index_total) after=$($afterAnggota.files_index_total) delta=$deltaAnggota"
  Write-Host "[announcements] before=$($beforeAnn.files_index_total) after=$($afterAnn.files_index_total) delta=$deltaAnn"

  if ($deltaDevices -le 2 -and $deltaAnggota -le 2 -and $deltaAnn -ge 1) {
    Write-Host "[PASS] Growth per koleksi terkendali (devices/anggota tidak liar, announcements bertambah sesuai workload)." -ForegroundColor Green
    exit 0
  }

  Write-Host "[FAIL] Growth pattern tidak sesuai ekspektasi." -ForegroundColor Red
  exit 1
}
finally {
  if ($proc -and !$proc.HasExited) {
    Stop-Process -Id $proc.Id -Force
  }
}
