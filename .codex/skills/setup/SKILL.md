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
- User baru copy folder `.codex` ke root project dan ingin semua skill/tools langsung aktif.

## Mode 1 - Environment Bootstrap
1. Jalankan bootstrap flow untuk siapkan environment AI dev.
2. Deteksi stack/runtime dan dependencies utama.
3. Muat skill/memory/config yang aktif.
4. Buat report setup + rekomendasi langkah awal.
5. Selesaikan prelaunch check sebelum sesi implementasi panjang:
- runtime/venv/env var siap
- dependency inti terpasang
- command utama run/test tersedia
- MCP/tool yang tidak relevan dinonaktifkan

Portable `.codex` bootstrap contract:
1. anggap `.codex` sebagai bundle mandiri yang dipindah ke root project baru
2. jalankan bootstrap script `.codex` (`bootstrap.sh` / `bootstrap.ps1`)
3. validasi `AGENTS.md`, `memory/MEMORY.md`, dan `skills/` bisa dibaca
4. validasi command-center (`.codex/tools/agentic-hub.sh doctor`) sebelum mulai task utama

Jika konteks task adalah refactor kompleks:
5. buat dependency map file/modul sebelum implementasi
6. tandai file high-coupling dan urutan aman disentuh
7. tetapkan preflight checks yang harus lolos per fase

### Plugin-Dir Dev Loop Matrix

Untuk workflow local checkout/plugin-dir:
1. launch dengan `--plugin-dir <path>` atau set `OMC_PLUGIN_ROOT=<path>`
2. jalankan setup dengan `--plugin-dir-mode` agar tidak duplikasi agents/skills
3. jalankan doctor dengan path yang sama saat troubleshooting
4. jika `OMC_PLUGIN_ROOT` dan path launch tidak sama, status `blocked` sampai konsisten

Rule update:
- setelah update plugin/checkout, wajib re-run setup sebelum sesi implementasi berikutnya

### MCP Scaffold -> Configure Client Pipeline

Untuk setup server MCP baru (Arcade-style), jalankan urutan deterministik:
1. scaffold project server (`arcade new <name>` atau setara)
2. jalankan server lokal dengan transport target (`stdio` default)
3. configure client target (`claude`/`cursor`/`vscode`) ke entrypoint server
4. verify minimal 1 tool callable dari client
5. jika callable gagal, jangan lanjut; keluarkan `status: blocked` + `next_step` recovery

### MCP Memory Setup Checklist
- pasang konfigurasi client untuk `server-memory` dengan command yang benar
- jalankan preflight koneksi setelah start (jangan asumsi auto-connected)
- catat bukti pass/fail koneksi ke output setup

### Isolation Boundary Checklist

Sebelum memberi permission penuh ke agent runtime:
1. pastikan eksekusi terjadi di boundary terisolasi (sandbox/worktree/env terpisah)
2. pastikan akses production/system sensitif tidak terbuka by default
3. catat `blast_radius_scope` di output setup

### JS/TS Tooling Extension
- Jika project dominan TypeScript/JavaScript, tawarkan integrasi LSP tooling (`typescript-lsp`) untuk:
- diagnostics error lebih cepat
- symbol/reference navigation
- refactor safety checks

### Testing Observability Matrix

Untuk kebutuhan forensics saat test/debug:
1. tetapkan profil timeout (`normal` vs `debug`)
2. tetapkan level logging yang dapat diaudit
3. jika tracing dipakai, pastikan output path artefak ditentukan
4. simpan ringkasan matrix ini ke output setup

### Agent Browser / Lightpanda Preflight
- Untuk otomasi browser kompleks, jalankan preflight readiness terlebih dulu:
```bash
bash .codex/skills/setup/scripts/browser-preflight.sh
```
- Validasi minimum:
  - tool browser terdeteksi (`agent-browser` atau `lightpanda`)
  - endpoint CDP aktif bila diperlukan
  - konfigurasi MCP browser tersedia (jika mode MCP dipakai)

QA browser preflight tambahan:
- cek session cookie/import path bila perlu halaman terautentikasi
- pastikan fallback headed mode tersedia saat headless gagal

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

Schema output setup (deterministik):
1. `environment_status`
2. `preflight_checks`
3. `runtime_state`
4. `contract_warnings`
5. `next_step`
6. `observability_ready` (`yes`|`no`)
7. `verification_signal` (command/test/log yang dipakai validasi)
8. `status` (`pass`|`fail`|`blocked`)

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
- status prelaunch readiness (`ready`|`blocked`)

## Permission Mode Matrix

Tetapkan mode izin operasional sebelum execute:
1. `safe`: hanya read/check/doctor/preflight
2. `default`: setup + perubahan lokal terkendali
3. `elevated`: operasi berisiko tinggi (network sensitif/release path)

Aturan:
- default mulai dari `safe`
- naik mode hanya jika gate langkah saat ini lulus dan objective menuntut
- catat mode yang dipilih di output setup

## Selective Install and State Lifecycle

Untuk setup paket skill/tool yang besar, gunakan pola selective install:
1. Rencanakan profile/module yang dibutuhkan dulu (jangan full install by default).
2. Apply hanya komponen yang relevan ke objective user saat ini.
3. Simpan install-state agar jejak file terkelola dan bisa diaudit.
4. Sediakan command `doctor` untuk deteksi drift.
5. Sediakan command `repair` untuk pulihkan file managed tanpa reinstall total.

Lifecycle minimum yang wajib ada:
- `install_plan`
- `install_apply`
- `list_installed_state`
- `doctor`
- `repair`

## Cross-Harness Packaging Pattern

Saat setup lintas harness (Codex/Claude/Cursor/OpenCode/dll):
- tetapkan satu sumber canonical untuk workflow knowledge
- turunkan adapter/config per harness dari sumber canonical itu
- hindari divergensi instruksi antar harness dengan sinkronisasi berkala

Target-aware install matrix:
- pilih target harness eksplisit sebelum apply
- verifikasi dependency runtime per target
- tandai `target_ready` (`yes`|`no`) di output setup

## Command vs Skill Loading Discipline

Untuk menjaga token budget:
1. Utamakan command/on-demand flow untuk tugas yang bisa dieksekusi tanpa context panjang.
2. Aktifkan skill penuh hanya saat butuh workflow kompleks dan reusable.
3. Catat tradeoff kecepatan vs kualitas sebelum memilih jalur.
4. Untuk task non-trivial, gunakan `think` sebagai gate keputusan awal (skill-only vs tool+skill vs MCP path).

## Dual Surface Contract (CLI vs In-Session)

Untuk workflow yang punya dua surface (terminal CLI vs in-session skill):
1. tentukan surface dari awal, jangan campur command set secara acak
2. jika operasi butuh environment shell/runtime lokal -> pilih CLI
3. jika operasi butuh orchestration skill di session aktif -> pilih in-session surface
4. tulis mapping singkat di output setup agar operator tidak salah jalur

## Managed Hooks Safety Policy

Saat setup menyentuh `.codex/hooks.json`:
1. update hanya wrapper hooks yang dikelola tool
2. preserve semua hook user yang tidak dikelola
3. uninstall hanya menghapus wrapper managed, bukan file keseluruhan jika user hook masih ada
4. gunakan helper script:
```bash
bash .codex/skills/setup/scripts/hooks-managed-merge.sh --hooks-file .codex/hooks.json --managed-key omx_wrapper --managed-cmd "<command>"
```

Hook duplicate prevention:
- jangan daftarkan hook dua kali lewat dua surface config yang berbeda
- untuk harness yang auto-load plugin hooks, hindari duplicate declaration manual
- jika duplicate terdeteksi, status setup `blocked` sampai governance hooks konsisten

## Token Optimizer Install/Verify Matrix

Saat user ingin optimasi token lintas session, pilih salah satu jalur:
1. `snip`/proxy-filter style:
- verify: proxy aktif, filter rules valid, rollback mudah
2. `engram`/local daemon style:
- verify: service hidup, socket reachable, client hook aktif
3. persistent memory+codegraph style:
- verify: index bisa query, hasil retrieval relevan, fallback ke memory lokal tetap aman

Output wajib matrix:
- `selected_path`
- `install_status`
- `verification_evidence`
- `rollback_command`

Optional toggle yang direkomendasikan:
- `entity_disambiguation: on` untuk query person/brand/product sebelum web-search

## Agentic Integration Preflight Matrix

Untuk integrasi berbasis AI agent/tooling assistant:
1. `runtime_ready`:
- Node/Python/version sesuai requirement
- package manager tersedia
2. `sdk_hygiene`:
- uninstall SDK lama yang konflik
- lockfile konsisten
3. `credential_ready`:
- env var wajib terpasang
- jangan hardcode secret di config
4. `mcp_ready`:
- config server valid
- handshake pass
5. `post_setup_verify`:
- test command integrasi jalan
- fallback command tersedia jika agent-flow gagal

Jika salah satu matriks gagal, keluarkan `prelaunch readiness: blocked`.

## Step-Gating Rule

Jangan lanjut ke langkah setup berikutnya sebelum langkah saat ini punya:
1. output schema valid
2. bukti verifikasi jelas
3. status `pass`

## Composio SDK Preflight (Dual Runtime)

Untuk integrasi Composio, cek dua runtime sekaligus:
1. TypeScript path:
- `@composio/core` tersedia
- provider package sesuai adapter tersedia
2. Python path:
- `composio` tersedia
- provider package sesuai adapter tersedia
3. provider compatibility:
- framework target ada di daftar support provider
4. auth readiness:
- API key/credential source jelas
- state connected-account tidak kosong untuk toolkit yang dipakai
5. toolkit scope:
- hanya toolkit minimum yang dibutuhkan task

## OpenAPI Drift Verification

Jika workflow bergantung contract OpenAPI vendor:
1. jalankan drift check sebelum upgrade/integrasi:
```bash
bash .codex/skills/setup/scripts/openapi-drift-check.sh --url https://backend.composio.dev/api/v3/openapi.json --state-file .tmp/openapi/composio.sha256
```
2. jika fingerprint berubah, tandai `contract_warnings` dan wajib review impact.

## Memory Housekeeping SOP

Untuk workspace yang sering update knowledge:
1. collect insight high-signal dari session/issue selesai
2. score (reusable vs one-off)
3. merge ke source memory canonical
4. prune duplikasi/usang
