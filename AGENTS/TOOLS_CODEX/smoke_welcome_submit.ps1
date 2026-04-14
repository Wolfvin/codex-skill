param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [int]$TimeoutSec = 40,
  [string]$HardwareId = "",
  [string]$Nama = "Codex Smoke User",
  [string]$Brevet = "anonymous",
  [string]$NomorAnggota = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-JsonPost {
  param(
    [Parameter(Mandatory = $true)][string]$Url,
    [Parameter(Mandatory = $true)][hashtable]$Body,
    [Parameter(Mandatory = $true)][int]$TimeoutSec
  )

  $json = $Body | ConvertTo-Json -Depth 10
  return Invoke-RestMethod -Method Post -Uri $Url -ContentType "application/json" -Body $json -TimeoutSec $TimeoutSec
}

if ([string]::IsNullOrWhiteSpace($HardwareId)) {
  $HardwareId = "codex-smoke-" + [Guid]::NewGuid().ToString("N").Substring(0, 10)
}

$base = $BaseUrl.TrimEnd("/")
Write-Host "[INFO] BaseUrl     : $base"
Write-Host "[INFO] HardwareId  : $HardwareId"
Write-Host "[INFO] TimeoutSec  : $TimeoutSec"

try {
  $sw1 = [System.Diagnostics.Stopwatch]::StartNew()
  $bootstrapResp = Invoke-JsonPost -Url "$base/api/session/bootstrap" -Body @{
    hardware_id = $HardwareId
    app_version = "1.0.0"
  } -TimeoutSec $TimeoutSec
  $sw1.Stop()
  Write-Host "[OK] Bootstrap ${($sw1.ElapsedMilliseconds)} ms"
  Write-Host ("      Response: " + ($bootstrapResp | ConvertTo-Json -Depth 6 -Compress))

  $sw2 = [System.Diagnostics.Stopwatch]::StartNew()
  $registerResp = Invoke-JsonPost -Url "$base/api/anggota/self-register" -Body @{
    hardware_id   = $HardwareId
    nama          = $Nama
    nomor_anggota = $(if ([string]::IsNullOrWhiteSpace($NomorAnggota)) { $null } else { $NomorAnggota })
    brevet        = $Brevet
    role          = "anggota"
    status        = "aktif"
    quotes        = "smoke-test"
    foto_path     = $null
  } -TimeoutSec $TimeoutSec
  $sw2.Stop()
  Write-Host "[OK] Self-Register ${($sw2.ElapsedMilliseconds)} ms"
  Write-Host ("      Response: " + ($registerResp | ConvertTo-Json -Depth 6 -Compress))
}
catch {
  Write-Host "[ERR] Request gagal: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}

