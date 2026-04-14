param(
  [string]$DataDir = "$env:LOCALAPPDATA\Smart Tax Assistance\server\lokal",
  [string]$BackupRoot = "D:\Workspace\projects\akp2i_projects\AGENTS\TOOLS_CODEX\backups",
  [switch]$SkipBackup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Stop-IfRunning($name) {
  $p = Get-Process -Name $name -ErrorAction SilentlyContinue
  if ($p) {
    Write-Host "[INFO] Stop process $name ..."
    $p | Stop-Process -Force
    Start-Sleep -Milliseconds 500
  }
}

function Rotate-File($path) {
  if (-not (Test-Path $path)) { return $null }
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  $dst = "$path.crash0409-$ts.bak"
  Move-Item -LiteralPath $path -Destination $dst -Force
  return $dst
}

Write-Host "=== Recover 0xc0000409 Runtime ==="
Write-Host "DataDir : $DataDir"

if (-not (Test-Path $DataDir)) {
  throw "DataDir tidak ditemukan: $DataDir"
}

Stop-IfRunning -name 'akp2i-server'
Stop-IfRunning -name 'akp2i-server.exe'

if (-not $SkipBackup) {
  if (-not (Test-Path $BackupRoot)) {
    New-Item -ItemType Directory -Path $BackupRoot | Out-Null
  }
  $zip = Join-Path $BackupRoot ("lokal-backup-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".zip")
  Write-Host "[INFO] Backup data dir -> $zip"
  Compress-Archive -Path (Join-Path $DataDir '*') -DestinationPath $zip -CompressionLevel Optimal -Force
  Write-Host "[OK] Backup selesai"
}

$rotated = @()
$targets = @(
  (Join-Path $DataDir 'index.db'),
  (Join-Path $DataDir 'index.db.wal'),
  (Join-Path $DataDir 'index.db.tmp'),
  (Join-Path $DataDir 'waiting_room.db'),
  (Join-Path $DataDir 'waiting_room.db.wal')
)

foreach ($t in $targets) {
  $r = Rotate-File -path $t
  if ($r) { $rotated += $r }
}

Write-Host "`n=== Rotated Files ==="
if ($rotated.Count -eq 0) {
  Write-Host "[INFO] Tidak ada file target yang perlu dirotasi."
} else {
  $rotated | ForEach-Object { Write-Host "[OK] $_" }
}

Write-Host "`n=== Next ==="
Write-Host "1) Start backend lagi (cargo run atau service SOP)."
Write-Host "2) Cek health: Invoke-RestMethod http://127.0.0.1:3000/"
Write-Host "3) Jalankan gate auth test setelah server up."
