param(
  [string]$BaseUrl = "http://192.168.100.74:3000",
  [string]$RawHardwareId = "",
  [int]$TimeoutSec = 10,
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

function Invoke-JsonSafe {
  param(
    [string]$Method,
    [string]$Uri,
    [hashtable]$Headers = @{},
    [object]$Body = $null
  )
  try {
    $args = @{
      Method = $Method
      Uri = $Uri
      TimeoutSec = $TimeoutSec
      Headers = $Headers
      ErrorAction = "Stop"
    }
    if ($null -ne $Body) {
      $args.ContentType = "application/json"
      $args.Body = $Body
    }
    $data = Invoke-RestMethod @args
    return [pscustomobject]@{
      ok = $true
      status = 200
      data = $data
      error = ""
      uri = $Uri
    }
  } catch {
    $status = $null
    $msg = $_.Exception.Message
    try {
      $status = [int]$_.Exception.Response.StatusCode
    } catch {}
    return [pscustomobject]@{
      ok = $false
      status = $status
      data = $null
      error = $msg
      uri = $Uri
    }
  }
}

function Resolve-ArrayPayload([object]$Payload) {
  if ($Payload -is [System.Array]) { return @($Payload) }
  if ($null -ne $Payload.devices -and $Payload.devices -is [System.Array]) { return @($Payload.devices) }
  if ($null -ne $Payload.value -and $Payload.value -is [System.Array]) { return @($Payload.value) }
  return @()
}

function Add-Finding {
  param(
    [string]$Code,
    [string]$Level,
    [string]$Message,
    [string]$Fix
  )
  $script:Findings.Add([pscustomobject]@{
    code = $Code
    level = $Level
    message = $Message
    fix = $Fix
  }) | Out-Null
}

$Findings = New-Object System.Collections.Generic.List[object]

$raw = $RawHardwareId
$hwSource = "manual"
if ([string]::IsNullOrWhiteSpace($raw)) {
  $raw = Get-MachineGuid
  $hwSource = "machine_guid"
}
if ([string]::IsNullOrWhiteSpace($raw)) {
  throw "Tidak bisa menentukan raw hardware id. Isi -RawHardwareId manual."
}

$rawExact = $raw
$rawTrim = $raw.Trim()
$hashExact = Get-Sha256Hex $rawExact
$hashTrim = Get-Sha256Hex $rawTrim
$hashSelected = if ($UseTrimHash) { $hashTrim } else { $hashExact }

Write-Host "=== RESTRICTED ROOTCAUSE DIAG ==="
Write-Host ("BaseUrl             : {0}" -f $BaseUrl)
Write-Host ("HWID source         : {0}" -f $hwSource)
Write-Host ("Raw HWID            : {0}" -f $rawExact)
Write-Host ("Hash(app exact)     : {0}" -f $hashExact)
Write-Host ("Hash(trimmed)       : {0}" -f $hashTrim)
Write-Host ("Hash(selected)      : {0}" -f $hashSelected)

if ($hashExact -ne $hashTrim) {
  Add-Finding -Code "HWID_WHITESPACE" -Level "warn" -Message "Hash exact != hash trimmed. Ada whitespace/karakter tambahan di HWID." -Fix "Pastikan sumber HWID konsisten (trim) di semua node/client."
}

$pingPublic = Invoke-JsonSafe -Method "GET" -Uri "$BaseUrl/api/session/ping"
if ($pingPublic.ok) {
  Write-Host ("`n[NET] /api/session/ping reachable (public) status={0}" -f $pingPublic.status)
} else {
  Write-Host ("`n[NET] /api/session/ping FAILED status={0} err={1}" -f $pingPublic.status, $pingPublic.error)
  Add-Finding -Code "SERVER_UNREACHABLE" -Level "error" -Message "Server tidak terjangkau dari node ini." -Fix "Cek URL server, firewall, port 3000, dan status service server aktif."
}

$bootstrapBody = @{ hardware_id = $rawExact; app_version = "1.0.0" } | ConvertTo-Json
$boot = Invoke-JsonSafe -Method "POST" -Uri "$BaseUrl/api/session/bootstrap" -Body $bootstrapBody

$bootOk = $false
$bootRole = ""
$bootReason = ""
$bootToken = ""
if ($boot.ok -and $null -ne $boot.data) {
  $bootOk = [bool]$boot.data.ok
  $bootRole = [string]$boot.data.role
  $bootReason = [string]$boot.data.reason
  $bootToken = [string]$boot.data.token
  Write-Host "`n=== BOOTSTRAP ==="
  Write-Host ("ok                 : {0}" -f $bootOk)
  Write-Host ("role               : {0}" -f $bootRole)
  Write-Host ("reason             : {0}" -f $bootReason)
  Write-Host ("token.set          : {0}" -f ([bool](-not [string]::IsNullOrWhiteSpace($bootToken))))
} else {
  Write-Host "`n=== BOOTSTRAP ==="
  Write-Host ("FAILED             : status={0} err={1}" -f $boot.status, $boot.error)
  Add-Finding -Code "BOOTSTRAP_FAIL" -Level "error" -Message "Bootstrap gagal, app akan tetap restricted." -Fix "Cek endpoint /api/session/bootstrap, payload HWID, dan log server auth."
}

if ($boot.ok -and (-not $bootOk)) {
  Add-Finding -Code "BOOTSTRAP_DENY" -Level "error" -Message ("Bootstrap mengembalikan ok=false, reason={0}" -f ($bootReason -or "-")) -Fix "Daftarkan device/role di server lokal atau benahi allowlist sesuai kebijakan."
}

if ($boot.ok -and [string]::IsNullOrWhiteSpace($bootToken)) {
  Add-Finding -Code "TOKEN_EMPTY" -Level "error" -Message "Bootstrap ok tapi token kosong." -Fix "Perbaiki response bootstrap agar selalu kirim token valid saat ok=true."
}

if (-not [string]::IsNullOrWhiteSpace($bootToken)) {
  $pingAuth = Invoke-JsonSafe -Method "GET" -Uri "$BaseUrl/api/session/ping" -Headers @{
    "x-akp2i-token" = $bootToken
    "x-akp2i-hardware-id" = $rawExact
  }
  if ($pingAuth.ok -and $null -ne $pingAuth.data) {
    Write-Host "`n=== PING WITH TOKEN ==="
    Write-Host ("ok                 : {0}" -f [bool]$pingAuth.data.ok)
    Write-Host ("role               : {0}" -f [string]$pingAuth.data.role)
    Write-Host ("reason             : {0}" -f [string]$pingAuth.data.reason)
    if (-not [bool]$pingAuth.data.ok) {
      $pingReason = [string]$pingAuth.data.reason
      if ([string]::IsNullOrWhiteSpace($pingReason)) { $pingReason = "-" }
      Add-Finding -Code "PING_DENY" -Level "error" -Message ("Ping token ditolak, reason={0}" -f $pingReason) -Fix "Sinkronkan token cache client dengan token hasil bootstrap terbaru."
    }
  } else {
    Write-Host "`n=== PING WITH TOKEN ==="
    Write-Host ("FAILED             : status={0} err={1}" -f $pingAuth.status, $pingAuth.error)
    Add-Finding -Code "PING_FAIL" -Level "error" -Message "Ping token gagal; app bisa fallback restricted." -Fix "Cek endpoint /api/session/ping + header x-akp2i-token + CORS/network."
  }
}

$devices = Invoke-JsonSafe -Method "GET" -Uri "$BaseUrl/api/devices"
$deviceCount = 0
$match = $null
if ($devices.ok) {
  $arr = Resolve-ArrayPayload -Payload $devices.data
  $deviceCount = $arr.Count
  $match = $arr | Where-Object { [string]$_.id -eq $hashSelected } | Select-Object -First 1
  Write-Host "`n=== DEVICES ==="
  Write-Host ("total              : {0}" -f $deviceCount)
  if ($null -ne $match) {
    Write-Host "[PASS] selected hash ditemukan di /api/devices"
    Write-Host ("is_admin           : {0}" -f [bool]$match.is_admin)
    Write-Host ("is_super_admin     : {0}" -f [bool]$match.is_super_admin)
    Write-Host ("last_seen          : {0}" -f [string]$match.last_seen)
  } else {
    Write-Host "[BLOCK] selected hash TIDAK ditemukan di /api/devices"
    Add-Finding -Code "DEVICE_NOT_IN_INDEX" -Level "warn" -Message "Hash HWID node tidak ada di /api/devices." -Fix "Pastikan node ini benar-benar hit bootstrap ke server yang sama, lalu cek dedupe/upsert devices."
  }
} else {
  Write-Host "`n=== DEVICES ==="
  Write-Host ("FAILED             : status={0} err={1}" -f $devices.status, $devices.error)
  Add-Finding -Code "DEVICES_API_FAIL" -Level "warn" -Message "Tidak bisa baca /api/devices untuk verifikasi identitas." -Fix "Periksa endpoint monitor/auth server."
}

$appData = Join-Path $env:LOCALAPPDATA "Smart Tax Assistance"
$localDb = Join-Path $appData "server\\lokal\\index.db"
$waitingDb = Join-Path $appData "server\\lokal\\waiting_room.db"
Write-Host "`n=== LOCAL FILES ==="
Write-Host ("AppData            : {0}" -f $appData)
Write-Host ("index.db exists    : {0}" -f (Test-Path $localDb))
Write-Host ("waiting_room exists: {0}" -f (Test-Path $waitingDb))

if (-not (Test-Path $localDb)) {
  Add-Finding -Code "LOCAL_DB_MISSING" -Level "warn" -Message "index.db lokal tidak ditemukan." -Fix "Jalankan app sekali sampai server lokal inisialisasi selesai."
}

Write-Host "`n=== VERDICT ==="
if ($Findings.Count -eq 0) {
  Write-Host "[PASS] Tidak ada blocker terdeteksi dari sisi backend/token/devices."
  Write-Host "Jika UI masih restricted, fokus ke cache/gating frontend (localStorage lama / URL server berbeda / token lama)."
} else {
  $idx = 1
  foreach ($f in $Findings) {
    Write-Host ("[{0}] ({1}) {2} - {3}" -f $idx, $f.level.ToUpper(), $f.code, $f.message)
    Write-Host ("     Fix: {0}" -f $f.fix)
    $idx++
  }
}

Write-Host "`n=== NEXT COMMANDS (manual) ==="
Write-Host "1) Jalankan script ini di node yang stuck restricted."
Write-Host "2) Kirim output penuh (dari '=== RESTRICTED ROOTCAUSE DIAG ===' sampai selesai)."
Write-Host "3) Bandingkan BaseUrl + Hash(selected) antar node yang normal vs bermasalah."
