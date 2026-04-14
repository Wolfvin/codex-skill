param(
  [string]$OutDir = "D:\Workspace\projects\akp2i_projects\smart_tax_assistance\test\.tmp"
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

$snippet = @'
(async () => {
  const out = {
    hasTauri: Boolean(window.__TAURI__?.window),
    owner: window.__AKP2I_WINDOW_CONTROL_OWNER || null,
    bound: Boolean(window.__AKP2I_TITLEBAR_BOUND),
    hasButtons: {
      minimize: Boolean(document.getElementById('btn-minimize')),
      maximize: Boolean(document.getElementById('btn-maximize')),
      close: Boolean(document.getElementById('btn-close')),
    },
    clicks: [],
    actions: [],
    maximize: { before: null, afterClick: null, afterDirect: null },
  };

  const safeClick = (id) => {
    const el = document.getElementById(id);
    if (!el) return false;
    el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
    return true;
  };

  try {
    const appWindow = (await window.__TAURI__?.window?.getCurrentWindow?.()) || null;
    if (appWindow?.isMaximized) {
      out.maximize.before = await appWindow.isMaximized();
    }

    out.clicks.push({ minimize: safeClick('btn-minimize') });
    out.clicks.push({ maximize: safeClick('btn-maximize') });

    if (appWindow?.isMaximized) {
      out.maximize.afterClick = await appWindow.isMaximized();
    }

    if (appWindow) {
      if (appWindow.minimize) { await appWindow.minimize(); out.actions.push('minimize'); }
      if (appWindow.toggleMaximize) {
        await appWindow.toggleMaximize();
        out.actions.push('toggleMaximize');
        if (appWindow.isMaximized) {
          out.maximize.afterDirect = await appWindow.isMaximized();
        }
      }
    }
  } catch (e) {
    out.actions.push(`tauri_error:${String(e?.message || e)}`);
  }

  console.log('[AKP2I Titlebar Test]', out);
  return out;
})();
'@

$outFile = Join-Path $OutDir "titlebar-test-snippet.js"
Set-Content -Path $outFile -Value $snippet -Encoding ASCII

try {
  Set-Clipboard -Value $snippet
  Write-Host "[OK] Snippet copied to clipboard."
} catch {
  Write-Host "[WARN] Copy to clipboard failed: $($_.Exception.Message)"
}

Write-Host "[OK] Snippet file: $outFile"
Write-Host "Steps:"
Write-Host "1) Buka DevTools Console pada app."
Write-Host "2) Paste snippet (Ctrl+V) dan Enter."
Write-Host "3) Kirim output '[AKP2I Titlebar Test]'."
