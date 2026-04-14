param(
  [string]$BaseUrl = "http://192.168.100.74:3000",
  [string]$RawHardwareId = "",
  [switch]$UseTrimHash
)

$ErrorActionPreference = "Stop"

function Get-MachineGuid {
  try {
    $v = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid" -ErrorAction Stop
    if ($null -ne $v -and "$v".Trim() -ne "") { return "$v".Trim() }
  } catch {}
  return $null
}

function Get-Sha256Hex([string]$Text) {
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    return ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join ""
  } finally {
    $sha.Dispose()
  }
}

$raw = $RawHardwareId
$source = "manual"
if ([string]::IsNullOrWhiteSpace($raw)) {
  $raw = Get-MachineGuid
  $source = "machine_guid"
}
if ([string]::IsNullOrWhiteSpace($raw)) {
  throw "Tidak bisa menentukan raw hardware id. Isi -RawHardwareId manual."
}

$rawExact = $raw
$rawTrim = $raw.Trim()
$hashExact = Get-Sha256Hex $rawExact
$hashTrim = Get-Sha256Hex $rawTrim
$hashSelected = if ($UseTrimHash) { $hashTrim } else { $hashExact }

Write-Host "=== NODE QUICK DIAG ==="
Write-Host "BaseUrl          : $BaseUrl"
Write-Host "HWID source      : $source"
Write-Host "Raw HWID         : $rawExact"
Write-Host "Hash(app exact)  : $hashExact"
Write-Host "Hash(trimmed)    : $hashTrim"
Write-Host "Hash(selected)   : $hashSelected"

Write-Host "`n=== BOOTSTRAP CHECK ==="
$body = @{ hardware_id = $rawExact; app_version = "1.0.0" } | ConvertTo-Json
try {
  $boot = Invoke-RestMethod -Method POST -Uri "$BaseUrl/api/session/bootstrap" -ContentType "application/json" -Body $body -TimeoutSec 10
  Write-Host ("bootstrap.ok     : {0}" -f $boot.ok)
  Write-Host ("bootstrap.role   : {0}" -f $boot.role)
  Write-Host ("bootstrap.reason : {0}" -f $boot.reason)
  Write-Host ("token.set        : {0}" -f ([bool](-not [string]::IsNullOrWhiteSpace([string]$boot.token))))
} catch {
  Write-Host ("[FAIL] bootstrap -> {0}" -f $_.Exception.Message)
}

Write-Host "`n=== DEVICES MATCH CHECK ==="
try {
  $dev = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/devices" -TimeoutSec 10
  $arr = @()
  if ($dev -is [System.Array]) { $arr = @($dev) }
  elseif ($dev.devices -is [System.Array]) { $arr = @($dev.devices) }
  elseif ($dev.value -is [System.Array]) { $arr = @($dev.value) }

  $match = $arr | Where-Object { [string]$_.id -eq $hashSelected } | Select-Object -First 1
  if ($match) {
    Write-Host "[PASS] hash ditemukan di /api/devices"
    $match | ConvertTo-Json -Depth 6
  } else {
    Write-Host ("[BLOCK] hash tidak ditemukan. total_devices={0}" -f $arr.Count)
  }
} catch {
  Write-Host ("[FAIL] devices -> {0}" -f $_.Exception.Message)
}
