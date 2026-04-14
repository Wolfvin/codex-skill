param(
    [string]$ProjectRoot = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance"
)

$ErrorActionPreference = "Stop"

$frontend = Join-Path $ProjectRoot "src\js\core\Frontend.js"
if (-not (Test-Path -LiteralPath $frontend)) {
    throw "Frontend.js tidak ditemukan: $frontend"
}

$raw = Get-Content -LiteralPath $frontend -Raw

Write-Host "=== Frontend Runtime Guard Check ==="
Write-Host "File: $frontend"

$checks = @(
    @{ Name = "dynamic import dashboard-stats exists"; Pattern = "import\('../pages/dashboard-stats\.js'\)" },
    @{ Name = "dynamic import dashboard-panels exists"; Pattern = "import\('../pages/dashboard-panels\.js'\)" },
    @{ Name = "dynamic import anggota exists"; Pattern = "import\('../pages/page-anggota\.js'\)" },
    @{ Name = "dynamic import pengumuman exists"; Pattern = "import\('../pages/page-pengumuman-agenda\.js'\)" },
    @{ Name = "dynamic import server monitor exists"; Pattern = "import\('../pages/page-server-monitor\.js'\)" }
)

$fail = 0
foreach ($c in $checks) {
    if ($raw -match $c.Pattern) {
        Write-Host "[OK]   $($c.Name)" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $($c.Name)" -ForegroundColor Red
        $fail++
    }
}

if ($fail -gt 0) {
    Write-Host "`n[FAIL] runtime guard check gagal ($fail masalah)." -ForegroundColor Red
    exit 1
}

Write-Host "`n[PASS] runtime guard check lulus." -ForegroundColor Green
exit 0
