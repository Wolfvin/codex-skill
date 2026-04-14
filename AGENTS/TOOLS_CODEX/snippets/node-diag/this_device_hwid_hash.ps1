param(
    [string]$RawHardwareId = "",
    [switch]$UseTrim,
    [switch]$CopyHash
)

$ErrorActionPreference = "Stop"

function Get-MachineGuid {
    try {
        $v = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid" -ErrorAction Stop
        if ($null -ne $v -and "$v".Trim() -ne "") {
            return "$v".Trim()
        }
    } catch {}
    return $null
}

function Get-CachedHardwareId {
    try {
        $base = $env:LOCALAPPDATA
        if ([string]::IsNullOrWhiteSpace($base)) { return $null }
        $path = Join-Path $base "Smart Tax Assistance\system\hardware_id.txt"
        if (-not (Test-Path $path)) { return $null }
        $raw = Get-Content -Path $path -Raw
        if ($null -eq $raw) { return $null }
        $v = $raw.Trim()
        if ($v -eq "") { return $null }
        return $v
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

$source = "manual"
$raw = $RawHardwareId

if ([string]::IsNullOrWhiteSpace($raw)) {
    $mg = Get-MachineGuid
    if (-not [string]::IsNullOrWhiteSpace($mg)) {
        $raw = $mg
        $source = "machine_guid"
    } else {
        $cached = Get-CachedHardwareId
        if (-not [string]::IsNullOrWhiteSpace($cached)) {
            $raw = $cached
            $source = "app_cache"
        }
    }
}

if ([string]::IsNullOrWhiteSpace($raw)) {
    Write-Host "[FAIL] Hardware ID tidak ditemukan." -ForegroundColor Red
    Write-Host "Hint: jalankan dengan -RawHardwareId `"<hwid>`" jika mau manual." -ForegroundColor Yellow
    exit 1
}

$rawExact = $raw
$rawTrimmed = $raw.Trim()
$hashExact = Get-Sha256Hex $rawExact
$hashTrimmed = Get-Sha256Hex $rawTrimmed
$selected = if ($UseTrim) { $hashTrimmed } else { $hashExact }

Write-Host "AKP2I HWID Hash Tool" -ForegroundColor Cyan
Write-Host "Source            : $source"
Write-Host "Raw HWID          : $rawExact"
Write-Host "Raw Length        : $($rawExact.Length)"
Write-Host "Hash (app exact)  : $hashExact"
Write-Host "Hash (trimmed)    : $hashTrimmed"
Write-Host "Selected Hash     : $selected"
Write-Host ""
Write-Host "Set env example:"
Write-Host "setx SUPER_ADMIN_DEVICE_IDS `"$selected`""

if ($CopyHash) {
    try {
        Set-Clipboard -Value $selected
        Write-Host "[OK] Selected hash dicopy ke clipboard." -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Clipboard gagal, tapi hash tetap tercetak di atas." -ForegroundColor Yellow
    }
}

if ($hashExact -ne $hashTrimmed) {
    Write-Host "[WARN] Hash exact vs trimmed berbeda. Ini biasanya karena spasi/newline tersembunyi." -ForegroundColor Yellow
}
