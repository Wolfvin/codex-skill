param(
  [string]$ServerUrl = "http://127.0.0.1:3000",
  [switch]$NoClipboard
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
  Write-Host "`n=== $msg ===" -ForegroundColor Cyan
}

function Invoke-JsonGet {
  param(
    [Parameter(Mandatory = $true)][string]$Url,
    [int]$TimeoutSec = 6
  )
  try {
    $resp = Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec $TimeoutSec
    return @{
      ok = $true
      data = $resp
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

Write-Step "Probe backend anggota"
$probe = Invoke-JsonGet -Url "$ServerUrl/api/anggota"
if (-not $probe.ok) {
  Write-Host "[FAIL] GET $ServerUrl/api/anggota -> $($probe.error)" -ForegroundColor Red
  exit 1
}

$anggota = @($probe.data)
$count = $anggota.Count
Write-Host "[OK] GET /api/anggota -> count=$count" -ForegroundColor Green

if ($count -eq 0) {
  Write-Host "[INFO] Backend hidup tapi data anggota kosong. Render UI akan kosong juga." -ForegroundColor Yellow
}

$payloadJson = $anggota | ConvertTo-Json -Depth 10 -Compress
$payloadJsonEscaped = $payloadJson.Replace("\", "\\").Replace("`$", "`$").Replace("`"", "\`"")

$snippet = @'
(async () => {
  const payload = JSON.parse("__PAYLOAD_JSON__");

  // Persist cache first so reload does not go blank
  try {
    localStorage.setItem('akp2i_anggota', JSON.stringify(payload));
    localStorage.setItem('akp2i_anggota_ts', String(Date.now()));
  } catch (e) {
    console.warn('[tools-anggota-render] gagal menulis cache anggota', e);
  }

  // Prefer official tool if available
  if (window.akp2iAnggotaTools?.injectPayloadAndRender) {
    const result = window.akp2iAnggotaTools.injectPayloadAndRender(payload, 'tools-anggota-render.ps1');
    console.log('[tools-anggota-render] injected via akp2iAnggotaTools', result);
    return result;
  }

  // Fallback renderer if module/global tool not loaded
  const grid = document.getElementById('anggota-grid');
  const empty = document.getElementById('anggota-empty');
  if (!grid) {
    console.warn('[tools-anggota-render] #anggota-grid tidak ditemukan. Pastikan kamu ada di page Anggota.');
    return { ok: false, reason: 'grid_not_found' };
  }

  const toRole = (role) => ({
    admin: 'Admin · Developer',
    ketua: 'Ketua',
    sekretaris: 'Sekretaris',
    bendahara: 'Bendahara',
    senior: 'Konsultan Senior',
    menengah: 'Konsultan Menengah',
    junior: 'Konsultan Junior',
    anggota: 'Konsultan',
  }[String(role || '').toLowerCase()] || role || 'Konsultan');

  const inisial = (name) =>
    String(name || 'Tanpa Nama')
      .split(' ')
      .map(w => w[0] || '')
      .join('')
      .slice(0, 2)
      .toUpperCase();

  grid.innerHTML = '';
  const normalized = Array.isArray(payload) ? payload : [];
  normalized.forEach((a, i) => {
    const name = String(a.nama || a.name || 'Tanpa Nama').trim() || 'Tanpa Nama';
    const statusAktif = String(a.status || '').toLowerCase() === 'aktif' || a.aktif === true;
    const role = toRole(a.role);
    const color = a.warna_card || 'linear-gradient(90deg, #0d4a2f, #3dab69)';
    const quote = a.quotes || a.quote || '';
    const foto = a.foto_path || a.foto || null;
    const card = document.createElement('div');
    card.className = 'member-card';
    card.style.setProperty('--card-color', color);
    card.style.animationDelay = `${i * 40}ms`;
    card.innerHTML = `
      <div class="member-avatar">
        ${foto ? `<img src="${foto}" alt="${name}">` : inisial(name)}
      </div>
      <div class="member-name">${name}</div>
      <div class="member-role">${role}</div>
      <div class="member-quote">${quote}</div>
      <div class="member-footer">
        <div class="member-status">
          <span class="status-dot ${statusAktif ? 'on' : 'off'}"></span>
          ${statusAktif ? 'Aktif' : 'Non-aktif'}
        </div>
      </div>`;
    grid.appendChild(card);
  });

  if (empty) empty.style.display = normalized.length ? 'none' : 'block';
  grid.style.display = normalized.length ? 'grid' : 'none';

  const totalEl = document.getElementById('stat-total');
  const aktifEl = document.getElementById('stat-aktif');
  if (totalEl) totalEl.textContent = String(normalized.length);
  if (aktifEl) aktifEl.textContent = String(normalized.filter(x => String(x.status || '').toLowerCase() === 'aktif' || x.aktif === true).length);

  console.log('[tools-anggota-render] fallback render done', { count: normalized.length });
  return { ok: true, rendered: normalized.length };
})();
'@

$snippet = $snippet.Replace("__PAYLOAD_JSON__", $payloadJsonEscaped)

$tmpDir = Join-Path $PSScriptRoot ".tmp"
New-Item -Path $tmpDir -ItemType Directory -Force | Out-Null
$snippetPath = Join-Path $tmpDir "anggota-render-snippet.js"
$snippet | Set-Content -Path $snippetPath -Encoding UTF8

Write-Step "Snippet generated"
Write-Host $snippetPath -ForegroundColor Green

if (-not $NoClipboard) {
  try {
    Set-Clipboard -Value $snippet
    Write-Host "[OK] Snippet copied to clipboard." -ForegroundColor Green
  } catch {
    Write-Host "[WARN] Gagal copy clipboard: $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

Write-Step "Cara pakai"
Write-Host "1) Buka app di halaman Anggota." -ForegroundColor White
Write-Host "2) Buka DevTools console." -ForegroundColor White
Write-Host "3) Paste snippet dari clipboard lalu Enter." -ForegroundColor White
Write-Host "4) Jika berhasil, berarti issue ada di init/hook module runtime, bukan data backend." -ForegroundColor White
