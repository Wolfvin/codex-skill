param(
  [string]$ServerUrl = "http://127.0.0.1:3000",
  [switch]$NoClipboard
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
  Write-Host "`n=== $msg ===" -ForegroundColor Cyan
}

function Try-JsonGet {
  param(
    [Parameter(Mandatory = $true)][string]$Url,
    [int]$TimeoutSec = 5
  )
  try {
    $data = Invoke-RestMethod -Method Get -Uri $Url -TimeoutSec $TimeoutSec
    return @{
      ok = $true
      data = $data
      error = $null
    }
  } catch {
    return @{
      ok = $false
      data = $null
      error = $_.Exception.Message
    }
  }
}

function Get-CountFromPayload($data) {
  if ($null -eq $data) { return 0 }
  if ($data -is [System.Array]) { return $data.Count }
  if ($data.PSObject.Properties.Name -contains "items" -and $data.items -is [System.Array]) { return $data.items.Count }
  return 0
}

Write-Step "Network / Port 3000"
$listeners = netstat -ano | Select-String ":3000"
if ($listeners) {
  $listeners | ForEach-Object { $_.Line } | Write-Host
} else {
  Write-Host "[WARN] Tidak ada listener :3000" -ForegroundColor Yellow
}

Write-Step "Probe endpoint anggota"
$targets = @(
  $ServerUrl,
  "http://127.0.0.1:3000",
  "http://localhost:3000"
) | Select-Object -Unique

$firstPayload = $null
foreach ($base in $targets) {
  $res = Try-JsonGet -Url "$base/api/anggota"
  if ($res.ok) {
    $count = Get-CountFromPayload $res.data
    Write-Host ("[OK] {0,-24} -> /api/anggota count={1}" -f $base, $count) -ForegroundColor Green
    if ($null -eq $firstPayload) {
      $firstPayload = $res.data
    }
  } else {
    Write-Host ("[FAIL] {0,-24} -> {1}" -f $base, $res.error) -ForegroundColor Yellow
  }
}

Write-Step "Local storage server snapshot"
$dataDir = Join-Path $env:LOCALAPPDATA "Smart Tax Assistance\server\lokal"
if (-not (Test-Path $dataDir)) {
  Write-Host "[WARN] Data dir tidak ditemukan: $dataDir" -ForegroundColor Yellow
} else {
  $indexDb = Join-Path $dataDir "index.db"
  $anggotaDir = Join-Path $dataDir "anggota"
  if (Test-Path $indexDb) {
    $size = (Get-Item $indexDb).Length
    Write-Host "[OK] index.db size=$size bytes" -ForegroundColor Green
  } else {
    Write-Host "[WARN] index.db tidak ditemukan" -ForegroundColor Yellow
  }

  if (Test-Path $anggotaDir) {
    $files = Get-ChildItem -Path $anggotaDir -File -ErrorAction SilentlyContinue
    Write-Host "[OK] anggota files count=$($files.Count)" -ForegroundColor Green
    $files | Sort-Object LastWriteTime -Descending | Select-Object -First 5 |
      ForEach-Object {
        Write-Host ("  - {0} ({1})" -f $_.Name, $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"))
      }
  } else {
    Write-Host "[WARN] folder anggota tidak ditemukan" -ForegroundColor Yellow
  }
}

Write-Step "Generate DevTools runtime snippet"
$payloadJson = ($firstPayload | ConvertTo-Json -Depth 10 -Compress)
if ([string]::IsNullOrWhiteSpace($payloadJson)) { $payloadJson = "[]" }
$payloadEscaped = $payloadJson.Replace("\", "\\").Replace("`"", "\`"")

$snippet = @'
(async () => {
  const payload = JSON.parse("__PAYLOAD_JSON__");
  const out = {
    href: location.href,
    serverUrlGlobal: window.__SERVER_URL__ || '',
    serverUrlGetter: typeof window.getServerUrl === 'function' ? window.getServerUrl() : '',
    hasInitAnggotaPage: typeof window.initAnggotaPage,
    hasAnggotaTools: typeof window.akp2iAnggotaTools,
    hasGetDiag: typeof window.getAnggotaDiagLast,
    cacheAnggotaExists: localStorage.getItem('akp2i_anggota') !== null,
    cacheAnggotaTs: localStorage.getItem('akp2i_anggota_ts'),
  };

  // Try normal init first
  if (typeof window.initAnggotaPage === 'function') {
    try {
      await window.initAnggotaPage();
      out.initCalled = true;
    } catch (e) {
      out.initError = String(e?.message || e);
    }
  }

  // If tools exist, force hydrate using module path
  if (window.akp2iAnggotaTools?.forceHydrateFromServerAndRender) {
    try {
      out.forceHydrate = await window.akp2iAnggotaTools.forceHydrateFromServerAndRender();
    } catch (e) {
      out.forceHydrateError = String(e?.message || e);
    }
  } else {
    // fallback manual inject for narrowing root cause
    localStorage.setItem('akp2i_anggota', JSON.stringify(payload));
    localStorage.setItem('akp2i_anggota_ts', String(Date.now()));
    const grid = document.getElementById('anggota-grid');
    const empty = document.getElementById('anggota-empty');
    if (grid) {
      grid.innerHTML = '';
      payload.forEach((a) => {
        const card = document.createElement('div');
        card.className = 'member-card';
        card.innerHTML = `<div class="member-name">${a.nama || a.name || 'Tanpa Nama'}</div>`;
        grid.appendChild(card);
      });
      if (empty) empty.style.display = payload.length ? 'none' : 'block';
      grid.style.display = payload.length ? 'grid' : 'none';
      out.fallbackRendered = payload.length;
    } else {
      out.fallbackRendered = 'grid_not_found';
    }
  }

  out.diagLast = typeof window.getAnggotaDiagLast === 'function' ? window.getAnggotaDiagLast() : null;
  out.domCards = document.querySelectorAll('#anggota-grid .member-card').length;
  out.cacheCountAfter = (() => {
    try {
      const p = JSON.parse(localStorage.getItem('akp2i_anggota') || '[]');
      return Array.isArray(p) ? p.length : -1;
    } catch { return -2; }
  })();

  console.log('[AKP2I Anggota RootCause]', out);
  return out;
})();
'@

$snippet = $snippet.Replace("__PAYLOAD_JSON__", $payloadEscaped)

$tmpDir = Join-Path $PSScriptRoot ".tmp"
New-Item -Path $tmpDir -ItemType Directory -Force | Out-Null
$snippetPath = Join-Path $tmpDir "anggota-rootcause-snippet.js"
$snippet | Set-Content -Path $snippetPath -Encoding UTF8

Write-Host "[OK] Snippet: $snippetPath" -ForegroundColor Green

if (-not $NoClipboard) {
  try {
    Set-Clipboard -Value $snippet
    Write-Host "[OK] Snippet copied to clipboard." -ForegroundColor Green
  } catch {
    Write-Host "[WARN] Gagal copy clipboard: $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

Write-Step "Next"
Write-Host "1) Buka halaman Anggota di app utama." -ForegroundColor White
Write-Host "2) Paste snippet di DevTools console." -ForegroundColor White
Write-Host "3) Kirim object output '[AKP2I Anggota RootCause]' ke saya." -ForegroundColor White
