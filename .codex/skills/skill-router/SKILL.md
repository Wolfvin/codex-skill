---
name: skill-router
description: Unified routing and skill discovery workflow. Use when user prompt is ambiguous/non-specific, when multiple skills may apply, or when user needs to find/install/manage skills. This router can select one or many skills depending on complexity (especially when smart-plan indicates multi-phase work).
---

# Skill Router

Skill gabungan dari `skill-router` dan `skills-search`.

## Trigger
- Prompt user broad/ambigu.
- User tidak meminta hal spesifik.
- Perlu pilih kombinasi skill paling efektif.
- User ingin search/discover/install/manage skill.

## Routing Protocol

1. Parse intent + complexity.
2. Untuk task non-trivial, jalankan `think` dulu:
- lakukan judgment (scope, risiko, gap konteks)
- buat decision jalur skill minimum yang valid
3. Jika problem statement belum jelas, jalankan clarify-first intake:
- tujuan bisnis
- constraint utama
- owner/maintainer
- deadline dan risk tolerance
3. Jika ambigu, jalankan suggestion:
```bash
bash .codex/tools/skill-navigator.sh suggest <user-prompt>
```
4. Pilih skill sesuai kebutuhan:
- sederhana: 1 skill
- menengah: 2-3 skill
- kompleks (smart-plan): bisa >3 skill bila benar-benar diperlukan
5. Urutan eksekusi:
- orchestration/setup
- domain workflow
- verification/quality

## Canonical Workflow Lane

Untuk task produk/fitur non-trivial, gunakan lane ini:
1. `clarify` -> route ke skill klarifikasi (contoh: `think`/interview-style questioning)
2. `plan` -> route ke `smart-plan`
3. `execute` -> pilih mode:
- `team/parallel` jika pekerjaan bisa dipecah aman
- `persistent-owner` jika butuh satu owner sampai selesai
4. `verify` -> route ke `debug-n-check`/`review`

Jangan lompat langsung ke execute jika clarify atau plan belum valid.

Untuk multi-agent orchestration:
- default ke lane tim canonical (`team-plan -> team-prd -> team-exec -> team-verify -> team-fix`)
- surface legacy/deprecated hanya boleh `compat-only`, bukan default route

## Canonical Owner Rule

Untuk domain yang sempit dan sangat operasional:
- utamakan 1 skill owner yang komprehensif
- hindari memecah domain sama ke banyak skill overlap tanpa alasan kuat
- jika ada overlap, pilih canonical owner lalu rujuk skill lain hanya sebagai pelengkap

Canonical owner map (ringkas):
- planning/execution gating -> `smart-plan`
- context sufficiency decision -> `think`
- external context retrieval -> `web-search`
- context injection orchestration -> `intelect-inject`
- frontend design contract injection -> `frontend-inject`
- TS/JS safety context -> `typescript-inject`
- tauri domain injection -> `tauri-inject`
- token/context hygiene -> `token-optimizer`

Capability-tag routing:
- route berdasarkan tag kemampuan, bukan nama skill saja:
  - `planning_gate` -> `smart-plan`
  - `context_retrieval` -> `web-search`
  - `context_injection` -> `intelect-inject`
  - `runtime_verify` -> `debug-n-check`
  - `token_hygiene` -> `token-optimizer`
  - `design_intelligence` -> `frontend-inject`

Role-route matrix (ringkas):
- strategic/product challenge -> lane CEO/planning
- architecture/testing -> lane engineering/review
- UX/UI quality -> lane design/frontend
- onboarding/devex -> lane DX/verification
- runtime issues -> lane debug

## Skills-First, Legacy-Shim Second

- Prioritaskan route ke skill canonical terlebih dahulu.
- Gunakan command legacy hanya jika:
- user eksplisit minta command lama, atau
- compatibility sementara masih dibutuhkan oleh tool/harness tertentu.
- Saat dua jalur tersedia, pilih jalur skill yang paling maintainable.

Alias hygiene:
- route dengan nama skill canonical lebih dulu
- alias/deprecated name hanya fallback kompatibilitas
- jangan merekomendasikan alias sebagai owner skill baru

## Token-Budget Routing Gate

Saat intent sudah jelas, pilih jalur dengan footprint context paling kecil yang tetap aman:
- simple task: command/on-demand flow
- medium/complex task: skill flow dengan quality gate
- high-risk task: skill flow + `smart-plan` verification gate

Curated-tool routing bias:
- pilih tool/skill surface yang paling kecil namun cukup untuk objective
- hindari akumulasi tool tanpa kontrak peran yang jelas

## Skills Search Mode (CCPM)

Gunakan ketika user minta cari/install/update skill:
- `ccpm search <query>`
- `ccpm info <skill-name>`
- `ccpm install <skill-name>`
- `ccpm update [name|--all]`
- `ccpm list`
- `ccpm uninstall <skill-name>`

Fallback bila `ccpm` tidak ada:
```bash
npx @daymade/ccpm <command>
```

## Guardrails
- Pakai minimal skill set yang cukup untuk task.
- Hindari workflow konflik.
- Bila confidence rendah, tambahkan quality gate via `smart-plan` verification mode.

## Refactor Routing Rule

Untuk prompt seperti "rapikan/refactor tanpa ubah behavior":
1. route utama ke `review` (Mode Simplify Safely / Refactor Plan Quality Review)
2. route verifikasi ke `debug-n-check`
3. jika multi-file dan kompleks, tambahkan `smart-plan` untuk phase planning dulu

## Context-Engineering / Multi-Agent Routing

Untuk prompt tentang arsitektur agent, memory/context strategy, atau evaluasi agent:
1. route planning ke `smart-plan`
2. route evaluasi kualitas ke `review`
3. route troubleshooting runtime ke `debug-n-check`

## Low-Context Fallback Rule

Jika confidence routing rendah karena konteks kurang:
1. route ke `think` untuk konfirmasi bahwa gap memang context-related
2. route ke `intelect-inject`
3. jika tidak ada sub-skill domain yang cocok, wajib fallback ke `web-search`
4. setelah konteks cukup, lanjutkan route ke skill eksekusi utama

Jika gejala mengarah ke queue stall/polling timeout/state drift:
1. route prioritas ke `debug-n-check`
2. gunakan `checkpoint` untuk menarik lesson queue/handoff sebelumnya
3. kembali ke `smart-plan` setelah sinyal runtime stabil

## Scope-Lock Rule

Router wajib menolak task creep:
1. kunci domain sesuai intent awal user
2. jangan menambah domain baru tanpa alasan teknis kuat
3. jika perlu perluasan scope, minta konfirmasi singkat dulu

## Route-by-Contract Gate

Sebelum memilih skill final, isi kontrak ini:
1. `needs_retrieval` (`yes`|`no`)
2. `needs_browser_action` (`yes`|`no`)
3. `needs_observability` (`yes`|`no`)
4. `scope_locked` (`yes`|`no`)

Tambahkan:
5. `decision_owner_role`
6. `needs_user_approval` (`yes`|`no`)
7. `host_runtime_ready` (`yes`|`no`)

Jika `scope_locked: no`, route harus berhenti sampai scope dikunci.
Jika `host_runtime_ready: no`, route harus berhenti dan pindah ke `setup` preflight.

## Output Wajib

- `intent_summary`
- `selected_skills[]`
- `why_selected`
- `why_not_others`
- `scope_locked`
- `route_contract` (fields gate di atas)

## Docs/API Routing (Context7)

Untuk prompt terkait library/API documentation:
1. route ke jalur Context7 (resolve library id -> query docs)
2. prioritaskan dokumentasi resmi dan versi library yang diminta
3. teruskan hasil ke `smart-plan`/skill eksekusi sebagai constraint implementasi

## Cross-Harness Compatibility Gate

Untuk workflow lintas Claude/Codex/Cursor/OpenCode/Gemini:
1. verifikasi target harness mendukung surface yang dipilih
2. jika tidak didukung, fallback ke surface canonical yang setara
3. jangan route ke command/skill yang dependency runtime-nya belum siap

## MCP Build/Configure Routing Rule

Jika intent mengandung pola berikut:
- "buat MCP server baru"
- "configure client ke MCP"
- "pilih stdio vs http transport"

Maka route default:
1. `mcp-builder` untuk desain contract + transport/auth decision
2. `setup` untuk scaffold/run/configure/verify pipeline
3. `debug-n-check` jika callable probe gagal
