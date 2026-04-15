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

## Operational Contract Gates

Untuk tooling CLI/MCP saat setup, terapkan kontrak operasional berikut:
1. Wajib jalankan preflight konektivitas/runtime sebelum workflow utama.
2. Setelah start session, wajib validasi status koneksi aktif.
3. Gunakan format parameter yang benar sesuai kontrak CLI (hindari alias/format tidak resmi).
4. Verifikasi bentuk output tool (file path/json/text) sebelum dijadikan input langkah berikutnya.
5. Jika runtime tidak sehat, lakukan recovery terarah (restart komponen terkait lalu ulangi preflight).

Checklist hasil setup minimal:
- preflight pass/fail dengan bukti command
- status session/runtime terakhir
- kontrak command penting yang harus diikuti tim

## Selective Install and State Lifecycle

Untuk setup paket skill/tool yang besar, gunakan pola selective install:
1. Rencanakan profile/module yang dibutuhkan dulu (jangan full install by default).
2. Apply hanya komponen yang relevan ke objective user saat ini.
3. Simpan install-state agar jejak file terkelola dan bisa diaudit.
4. Sediakan command `doctor` untuk deteksi drift.
5. Sediakan command `repair` untuk pulihkan file managed tanpa reinstall total.

## Cross-Harness Packaging Pattern

Saat setup lintas harness (Codex/Claude/Cursor/OpenCode/dll):
- tetapkan satu sumber canonical untuk workflow knowledge
- turunkan adapter/config per harness dari sumber canonical itu
- hindari divergensi instruksi antar harness dengan sinkronisasi berkala

## Command vs Skill Loading Discipline

Untuk menjaga token budget:
1. Utamakan command/on-demand flow untuk tugas yang bisa dieksekusi tanpa context panjang.
2. Aktifkan skill penuh hanya saat butuh workflow kompleks dan reusable.
3. Catat tradeoff kecepatan vs kualitas sebelum memilih jalur.
