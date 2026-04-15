---
name: command-center
description: Unified command-center workflow for bootstrap, repo intake, MCP connector operations, and plugin notes via .codex/tools/agentic-hub.sh. Use when the user wants one CLI entrypoint for day-to-day agent operations. Trigger for prompts like "single command center", "agentic cli", "agentic hub", "bootstrap + intake", and "manage connectors/plugins".
---

# Command Center

Skill gabungan dari `agentic-cli` dan `agentic-hub`.

## Merged Sources
- `agentic-cli`
- `agentic-hub`

## Trigger

- User ingin satu command center untuk workflow harian.
- User minta bootstrap + intake + connector management sekaligus.
- User minta manajemen plugin/connector yang konsisten.

## Primary Commands

```bash
bash .codex/tools/agentic-hub.sh doctor
bash .codex/tools/agentic-hub.sh bootstrap
bash .codex/tools/agentic-hub.sh intake <repo-url|local-path> [repo-url|local-path ...]
bash .codex/tools/agentic-hub.sh sync
bash .codex/tools/agentic-hub.sh skill suggest <prompt text>
bash .codex/tools/agentic-hub.sh skill list [category]
bash .codex/tools/agentic-hub.sh mcp list
bash .codex/tools/agentic-hub.sh connector add-http <name> <url>
bash .codex/tools/agentic-hub.sh connector add-stdio <name> <command> [arg ...]
bash .codex/tools/agentic-hub.sh connector preset claude-core
bash .codex/tools/agentic-hub.sh plugin note <name> <source>
```

## Session Hygiene Commands

Gunakan slash command ini untuk performa lintas session:
- `/status` untuk cek token/context pressure
- `/compact` setelah fase besar selesai
- `/new` untuk topik/fase baru
- `/fork` untuk eksplorasi alternatif tanpa merusak thread utama
- `/resume` untuk lanjut session lama secara terkontrol
- `/mcp` untuk audit MCP tools aktif

Tambahan command discipline:
- saat kompleksitas naik dan reasoning drift terasa, jalankan jeda operasional:
  1. `/status`
  2. checkpoint ringkas
  3. `/compact` atau thread baru
  4. lanjut dengan plan fase berikutnya

Sprint command recipe:
1. single sprint lane: think -> plan -> execute -> verify -> release
2. parallel sprint lane: jalankan beberapa lane independen dengan checkpoint integrasi berkala

SOP wajib task panjang:
1. selesai fase besar -> `/compact`
2. simpan handoff ke `checkpoint` (goal/done/next/blockers/confidence)
3. lanjut via `/resume` atau thread baru sesuai phase switch
4. update artifact fase (`PLANS.md` atau setara) sebelum pindah fase berikutnya

## CLI vs In-Session Contract

Pisahkan surface dengan tegas:
1. Terminal CLI:
- jalankan `bash .codex/tools/agentic-hub.sh ...` dari shell
- cocok untuk operasi bootstrap/sync/doctor yang butuh environment lokal
2. In-session slash:
- jalankan `/...` saat orchestration terjadi di session agent
- cocok untuk routing/planning/verification interaktif

Larangan:
- jangan campur runtime CLI dan in-session dalam satu langkah tanpa handoff jelas
- jika handoff dibutuhkan, tulis `surface_handoff` di output operasi

Decision map singkat:
1. jika butuh environment lokal -> pilih CLI
2. jika butuh orchestration skill interaktif -> pilih slash in-session
3. jika butuh validasi lintas runtime -> jalankan CLI dulu, lalu handoff ke in-session

Runtime surface matrix:
1. `local-cli`: default untuk task eksekusi cepat dan audit command
2. `sdk-script`: untuk workflow berulang/otomasi terprogram
3. `local-gui`: untuk monitoring visual, debugging interaktif, dan kolaborasi

## Update Discipline

Setelah update plugin/skill runtime:
1. jalankan ulang setup agar konfigurasi aktif sinkron
2. jalankan `doctor` untuk deteksi drift path/hook/config
3. lanjut operasi normal hanya jika status `pass`

## Default vs Operator Surface

Pisahkan pemakaian command-center jadi dua lapis:
1. `default user flow`:
- setup -> plan -> execute -> verify
- gunakan command yang paling sedikit friction
2. `operator surfaces`:
- doctor, hud/watch, low-level runtime inspect, sparkshell-style bounded verification
- dipakai hanya saat troubleshooting atau observability, bukan jalur default

Curated surface set:
- default set: bootstrap/intake/sync/skill suggest
- operator set: doctor/mcp inspect/session hygiene
- jangan pindah ke operator set tanpa gejala runtime/observability yang jelas

## OpenAPI Spec-Sync Workflow

Untuk vendor integration yang spec-driven:
1. sync/pull spec terbaru
2. jalankan drift check fingerprint
3. hanya lanjut apply/setup jika hasil drift sudah dievaluasi

Contoh command:
```bash
bash .codex/skills/setup/scripts/openapi-drift-check.sh --url https://backend.composio.dev/api/v3/openapi.json --state-file .tmp/openapi/composio.sha256
```

## Install-State Ops Recipe

Untuk lifecycle selective install:
1. buat/install plan
2. apply plan
3. list installed state
4. jalankan doctor jika ada drift
5. jalankan repair sebelum mempertimbangkan reinstall penuh

## Legacy Support

```bash
bash .codex/tools/agentic-cli.sh sync .tmp/repo-intake/reports
```

## Output

- Operasi agent tersentralisasi lewat satu command family.
- Update connector konsisten di `.vscode/mcp.json`.
- Catatan plugin/connector tersimpan di memori project.

## Advanced Runtime Ops (absorbed from `agent-runtime-advanced`)
- Gunakan checkpoint command untuk session recovery:
  - `bash .codex/tools/agentic-hub.sh checkpoint --goal "<...>" --done "<...>" --next "<...>" --blockers "<...>"`
- Untuk pekerjaan panjang, ringkas context ke memory secara periodik (compaction).

Gunakan helper script session hygiene:
```bash
bash .codex/skills/command-center/scripts/session-hygiene.sh
```
