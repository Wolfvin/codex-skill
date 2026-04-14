---
name: setup
description: Unified setup and operational SOP workflow. Use when initializing project environment, preparing runtime/tooling, or building operational PowerShell SOP runbooks for run/stop/check/debug in a context-aware way.
---

# Setup

Skill gabungan dari `bootstrap` dan `skill_sop`.

## Trigger
- User minta setup project/init environment/bootstrap.
- User minta SOP operasional run/stop/check/debug.
- Perlu command center operasional berbasis konteks project.

## Mode 1 - Environment Bootstrap
1. Jalankan bootstrap flow untuk siapkan environment AI dev.
2. Deteksi stack/runtime dan dependencies utama.
3. Muat skill/memory/config yang aktif.
4. Buat report setup + rekomendasi langkah awal.

### JS/TS Tooling Extension
- Jika project dominan TypeScript/JavaScript, tawarkan integrasi LSP tooling (`typescript-lsp`) untuk:
- diagnostics error lebih cepat
- symbol/reference navigation
- refactor safety checks

## Mode 2 - SOP Builder (PowerShell)
1. Bangun struktur SOP adaptif per konteks project.
2. Pastikan baseline script: menu, preflight, run, stop, diagnostics.
3. Tambahkan extension bila perlu (security gate, worker, backup, release gate).
4. Jaga idempotency, safety, dan operasional yang mudah dipakai tim.

## Output Wajib
- status setup environment
- mapping SOP script dan fungsi
- command utama run/stop/check/debug
- risiko operasional dan next step
