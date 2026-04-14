param(
  [string]$ServerBaseUrl = "http://192.168.100.74:3000",
  [string]$RawHardwareId = "",
  [int]$TimeoutSec = 8
)

$ErrorActionPreference = "Stop"

function Get-MachineGuid {
  try {
    $v = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid" -ErrorAction Stop
    if ($null -ne $v -and "$v".Trim() -ne "") { return "$v".Trim() }
  } catch {}
  return $null
}

function Call-Bootstrap {
  param([string]$Base, [string]$Hw)
  try {
    $body = @{ hardware_id = $Hw; app_version = "1.0.0" } | ConvertTo-Json
    $res = Invoke-RestMethod -Method POST -Uri "$Base/api/session/bootstrap" -ContentType "application/json" -Body $body -TimeoutSec $TimeoutSec
    return [pscustomobject]@{
      base = $Base
      reachable = $true
      ok = [bool]$res.ok
      role = [string]$res.role
      reason = [string]$res.reason
      token_set = [bool](-not [string]::IsNullOrWhiteSpace([string]$res.token))
      error = ""
    }
  } catch {
    return [pscustomobject]@{
      base = $Base
      reachable = $false
      ok = $false
      role = ""
      reason = ""
      token_set = $false
      error = $_.Exception.Message
    }
  }
}

$hw = $RawHardwareId
if ([string]::IsNullOrWhiteSpace($hw)) {
  $hw = Get-MachineGuid
}
if ([string]::IsNullOrWhiteSpace($hw)) {
  throw "HWID tidak ditemukan. Isi -RawHardwareId."
}

$targets = @(
  $ServerBaseUrl.TrimEnd('/'),
  "http://127.0.0.1:3000",
  "http://localhost:3000"
) | Select-Object -Unique

Write-Host "=== SERVER TARGET MISMATCH DIAG ==="
Write-Host ("HWID: {0}" -f $hw)
Write-Host ""

$rows = @()
foreach ($t in $targets) {
  $rows += Call-Bootstrap -Base $t -Hw $hw
}

$rows | ForEach-Object {
  if ($_.reachable) {
    Write-Host ("[{0}] reachable ok={1} role={2} reason={3} token={4}" -f $_.base, $_.ok, ($_.role -or "-"), ($_.reason -or "-"), $_.token_set)
  } else {
    Write-Host ("[{0}] UNREACHABLE err={1}" -f $_.base, $_.error)
  }
}

$primary = $rows | Where-Object { $_.base -eq $ServerBaseUrl.TrimEnd('/') } | Select-Object -First 1
$local = $rows | Where-Object { $_.base -eq "http://127.0.0.1:3000" -or $_.base -eq "http://localhost:3000" }
$localOk = $local | Where-Object { $_.reachable -and $_.ok } | Select-Object -First 1
$localDeny = $local | Where-Object { $_.reachable -and -not $_.ok } | Select-Object -First 1

Write-Host ""
Write-Host "=== VERDICT ==="
if ($primary -and $primary.reachable -and $primary.ok -and $localDeny) {
  Write-Host "[WARN] Remote server mengizinkan, tapi localhost menolak."
  Write-Host "       Jika app tetap restricted, besar kemungkinan app sedang pakai localhost, bukan server LAN."
} elseif ($primary -and $primary.reachable -and $primary.ok -and -not $localDeny) {
  Write-Host "[INFO] Remote server OK, localhost tidak menunjukkan deny eksplisit."
} elseif ($primary -and -not $primary.reachable) {
  Write-Host "[BLOCK] Server LAN tidak terjangkau dari node ini."
} else {
  Write-Host "[BLOCK] Kondisi auth masih belum hijau di server target."
}
