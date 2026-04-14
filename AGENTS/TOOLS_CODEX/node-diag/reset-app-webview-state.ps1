param(
  [switch]$StartAppAfterReset
)

$ErrorActionPreference = "Stop"

$appRoot = Join-Path $env:LOCALAPPDATA "Smart Tax Assistance"
$webRoot = Join-Path $env:LOCALAPPDATA "com.smartpdf.autoextractor"
$webView = Join-Path $webRoot "EBWebView"
$backupRoot = Join-Path $webRoot "backup"
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$backupTarget = Join-Path $backupRoot ("EBWebView-" + $ts)
$appExe = Join-Path $appRoot "app.exe"

Write-Host "=== RESET APP WEBVIEW STATE ==="
Write-Host ("app.exe     : {0}" -f $appExe)
Write-Host ("webview dir : {0}" -f $webView)

if (-not (Test-Path $webRoot)) {
  throw "WebView root tidak ditemukan: $webRoot"
}

Write-Host "`n[1/4] Stop proses app/webview..."
Get-Process -Name "app" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process -Name "msedgewebview2" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "[2/4] Backup state lama..."
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
if (Test-Path $webView) {
  Move-Item -LiteralPath $webView -Destination $backupTarget -Force
  Write-Host ("Backup dibuat: {0}" -f $backupTarget)
} else {
  Write-Host "EBWebView belum ada, tidak ada yang dipindah."
}

Write-Host "[3/4] Siapkan folder WebView baru..."
New-Item -ItemType Directory -Force -Path $webView | Out-Null

Write-Host "[4/4] Selesai."
Write-Host "State frontend (localStorage/cache) sudah di-reset."
Write-Host "Catatan: data server lokal di 'Smart Tax Assistance\\server\\lokal' TIDAK dihapus."

if ($StartAppAfterReset) {
  if (Test-Path $appExe) {
    Start-Process -FilePath $appExe | Out-Null
    Write-Host "app.exe dijalankan ulang."
  } else {
    Write-Host "app.exe tidak ditemukan, jalankan manual."
  }
}
