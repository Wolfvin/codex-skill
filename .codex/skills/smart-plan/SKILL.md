---
name: smart-plan
description: Unified planning, delivery, intake, routing, and verification workflow for complex execution. Use when user asks for roadmap/planning/spec/RPI/delivery gates, tagged or ambiguous intake, or high-accuracy verification before final delivery.
---

# Smart Plan

Skill gabungan planning + delivery pipeline + verification + intake + framework eksekusi.

## Merged Sources
- previous `smart-plan`
- `delivery-pipeline`
- `user_propt/make_plan` (plan-first discipline and instruction-edit context)
- verification stack
- `skill_codex_framework`

## Core Framework

1. Context -> Plan -> Execute -> Verify -> Finish
- kumpulkan konteks dan dependency map
- susun fase bertahap
- eksekusi incremental
- verifikasi berbukti
- tutup dengan risk log + next step

Default sprint lane:
- Think -> Plan -> Build -> Review -> Test -> Ship -> Reflect
- setiap fase wajib menghasilkan artifact handoff ringkas ke fase berikutnya

2. Delivery Gates
- Feature Spec Gate
- Implementation Gate
- Findings Closure Gate
- Release Readiness Gate

3. Intake and Routing
- parse tag/intent ambigu
- tetapkan objective/constraints/success criteria
- jalankan `think` lebih dulu untuk task non-trivial:
  - judgment: cek gap konteks + risiko halusinasi
  - decision: pilih jalur skill/tool paling tepat
  - generation: eksekusi plan hanya setelah decision valid
- pilih mode direct vs pipeline
- jika butuh context tambahan implementasi, panggil `intelect-inject`:
  - child `frontend-inject` untuk arah UI/UX + design contract
  - child `typescript-inject` untuk konteks TS/JS tooling
  - child `tauri-inject` untuk konteks desktop/mobile Tauri
- fallback `web-search` jika konteks belum cukup atau domain sub-skill belum tersedia

### Command-Tool-Service Boundary Gate

Sebelum eksekusi, klasifikasikan setiap langkah:
1. `command_layer`: aksi user-facing/operator (`/compact`, `/mcp`, shell command)
2. `tool_layer`: tool-call terstruktur untuk read/write/search/automation
3. `service_layer`: runtime adaptor/integrasi di belakang tool

Aturan:
- jangan campur 3 layer dalam satu langkah plan
- jika lintas-layer diperlukan, buat handoff eksplisit per langkah
- jika boundary tidak jelas, tahan execute dan turunkan ke replan

Pre-hydration context gate:
- sebelum execute, tarik konteks dari `AGENTS.md` + issue/thread context yang relevan
- jika konteks sumber belum memadai, status `NEEDS REVISION` dan tahan coding

Jika hasil injeksi masih kurang:
- jalankan `web-search` untuk menambah konteks eksternal berbasis sumber
- simpan ringkasan temuan ke short-term memory (`.codex/memory/MEMORY.md`)

Untuk task yang bergantung dokumentasi library/API:
- jalankan flow Context7 lebih dulu (resolve library id -> query docs)
- jadikan hasil docs sebagai dasar plan dan verifikasi implementasi

Issue lifecycle untuk eksekusi panjang:
- capture issue
- triage priority/risk
- execute fix slice
- verify evidence
- close + catat lesson learned

4. Verification Pipeline
- grounding
- source/citation verification
- cross-check
- confidence + uncertainty handling
- final audit + answer QA

5. Retrieval-First Context Pipeline
- sebelum execute, ukur `context_sufficiency` (`enough`|`insufficient`)
- jika `insufficient`, wajib jalankan retrieval lane:
  - local/context7 docs dulu untuk API/library
  - lanjut `web-search` jika evidence primer belum cukup
- jangan lanjut ke patch/claim kritis sebelum retrieval lane menghasilkan evidence memadai

## Judgment -> Decision -> Generation (Wajib)

Untuk task non-trivial, pisahkan fase:
1. Judgment: evaluasi fakta, constraint, dan risiko tanpa langsung menulis solusi.
2. Decision: pilih aksi paling tepat + tradeoff.
3. Generation: baru eksekusi artefak (plan/patch/output) sesuai keputusan.

## Execution Mode Decision Gate

Sebelum fase execute, wajib pilih satu mode:
1. `parallel/team`:
- gunakan jika task bisa diparalelkan dengan write-scope jelas
- wajib ada checkpoint integrasi hasil
2. `persistent-owner`:
- gunakan jika task butuh kontinuitas satu owner sampai verification pass
- jangan pecah ke banyak executor jika meningkatkan risiko drift

Output decision minimal:
- `execution_mode`
- `reason`
- `handoff_rule`

Surface selection minimal:
- `runtime_surface` (`cli`|`sdk`|`gui`)
- `surface_reason`

## Canonical Team Runtime Lane

Untuk multi-agent non-trivial, gunakan lane canonical:
`team-plan -> team-prd -> team-exec -> team-verify -> team-fix (loop)`

Aturan:
1. gunakan lane di atas sebagai default orchestrasi tim
2. jika lane lama/deprecated muncul di scope, tandai `compat_only`
3. jangan jadikan runtime deprecated sebagai jalur utama eksekusi

## Plan-First Discipline
- Untuk task non-trivial, buat plan terstruktur sebelum implementasi.
- Plan minimal memuat objective, scope, success criteria, langkah verifikasi, risiko.
- Update plan saat scope berubah.
- Wajib pecah task kompleks menjadi slice kecil agar eksekusi cepat dan hemat token.

### Deterministic Step-Gating

Setiap langkah wajib memenuhi output minimal ini sebelum lanjut ke langkah N+1:
1. `step_id`
2. `expected_output`
3. `actual_output`
4. `validation_status` (`pass`|`fail`|`blocked`)
5. `next_gate`

### Refactor Plan Template (Multi-File)
Untuk refactor besar, gunakan template fase ini:
1. dependency map + blast radius
2. phase-1: types/interface stabilization
3. phase-2: implementation migration bertahap
4. phase-3: tests dan parity verification
5. phase-4: cleanup/dead-code removal

## Brainstorming Gate (Design-First)

Untuk task baru/ambigu, jalankan gate brainstorming sebelum implementasi:
1. Explore context singkat (file/doc/runtime yang relevan).
2. Tanyakan klarifikasi satu per satu (jangan bombardir).
3. Ajukan 2-3 pendekatan + tradeoff + rekomendasi.
4. Present design section-by-section dan minta approval.
5. Setelah approved, baru masuk ke plan eksekusi.

Larangan:
- Jangan coding sebelum design disetujui (kecuali user eksplisit minta direct execution).

## UI Design-System Gate

Untuk task UI/frontend, sebelum fase build wajib ada artifact:
1. `product_domain`
2. `chosen_pattern`
3. `chosen_style`
4. `color_typography_summary`
5. `anti_pattern_to_avoid`

Tanpa artifact ini:
- status fase implementasi = `NEEDS REVISION`

## Prompt Workflow Troubleshooting Gate

Untuk task troubleshooting/debug, rencana harus memuat:
1. Prasyarat runtime/session yang harus valid dulu.
2. Urutan workflow prompt/command bertahap (bukan lompat ke fix).
3. Checkpoint verifikasi per langkah (status koneksi, evidence log/screenshot, hasil cek kontrak).
4. Cabang recovery jika gate gagal (retry, restart runtime terkait, atau stop dengan blocker jelas).

Jika command workflow tersedia sebagai slash/prompt template:
- pakai template sebagai baseline runbook
- tetap validasi precondition sebelum eksekusi template
- laporkan output yang bisa diaudit (bukan asumsi sukses)

Jika workflow bergantung hooks/runtime automation:
- jalankan hook governance check sebelum execute
- stop execute jika ada duplicate hook registration atau hook source drift

## Skills-First Surface Policy

- Rencanakan eksekusi berbasis skill sebagai surface utama.
- Gunakan command legacy hanya sebagai compatibility shim saat memang diperlukan.
- Jika ada konflik antara skill flow vs command lama, prioritaskan skill flow yang canonical.

## Guardrail Pipeline (Plan -> Check -> Review -> Security -> Release)

Untuk task delivery non-trivial, masukkan gate berikut ke plan:
1. plan/spec gate
2. verification/check gate
3. review gate (correctness + regression)
4. security gate
5. release/readiness gate

Setiap fase wajib punya:
- verification gate (evidence pass/fail)
- rollback step (aksi saat gagal)
- stop condition (kapan harus kembali ke replanning)

High-risk safety mode:
- untuk flow prod/sensitive, aktifkan mode setara `careful + freeze` sebelum eksekusi.

Deterministic safety-net rule:
- critical post-step (contoh: verify, readiness check, PR readiness) harus tetap dijalankan sebagai backstop meski agent melewatkan langkah.

## Stateful Task Lifecycle

Gunakan state eksplisit untuk task kompleks:
- `draft`: ide awal dan ruang lingkup kasar
- `todo`: spesifikasi siap dieksekusi
- `in-progress`: implementasi aktif dengan checkpoint verifikasi
- `done`: semua gate lolos

Jika verifikasi gagal berulang, kembalikan state ke `todo` untuk replanning.

## Stateful Graph and Resume Contract

Untuk task long-running/multi-step, modelkan plan sebagai graph state:
1. definisikan `state_nodes[]` (contoh: `intake`, `plan`, `execute`, `verify`, `close`)
2. definisikan `transitions[]` yang valid antar node
3. simpan `resume_point` saat langkah gagal/terhenti
4. saat lanjut ulang, mulai dari `resume_point`, bukan dari awal kecuali state rusak

Field audit minimum:
- `current_node`
- `previous_node`
- `resume_point`
- `transition_reason`

## Durable Replay Planning Contract

Untuk workflow stateful jangka panjang:
1. gunakan `event_history` sebagai sumber kebenaran transisi state
2. setiap langkah harus bisa direplay untuk rekonstruksi state saat recovery
3. jika replay gagal menghasilkan state yang sama, status wajib `BLOCKED`
4. pisahkan langkah deterministic vs side-effect agar replay tidak ambigu

Tambahan field audit:
- `event_history_ref`
- `replay_check` (`pass`|`fail`)

## Context Budget Planning

Untuk task panjang, tetapkan mode context sebelum eksekusi:
- low: command-oriented, minim artefak
- medium: plan + implement standar
- high: plan rinci + verification panel + reflect phase

Tambahan context engineering:
- deteksi context degradation saat artefak membengkak
- pakai compression/handoff summary per fase agar token tetap stabil

Aturan token-budget ketat:
- hapus prose/dekorasi yang tidak memengaruhi keputusan eksekusi
- prioritaskan struktur (checklist/schema) dibanding narasi panjang
- simpan hanya konteks yang dibutuhkan langkah saat ini

## Reflect Before Final Verdict

Untuk task high-risk/ambigu, jalankan reflect phase singkat sebelum status `READY`:
1. evaluasi gap requirement vs hasil
2. cek residual risk tersembunyi
3. update final verdict berdasarkan hasil refleksi

## Compaction Survival Gate

Untuk sesi panjang yang berisiko kehilangan konteks saat compaction:
1. catat `pre_compact_snapshot` (constraint utama, files in-flight, next steps)
2. setelah compaction, jalankan `post_compact_audit`:
- cek `ghost_lexicon` (term penting yang hilang)
- cek drift perilaku terhadap objective awal
- cek constraint kritis masih utuh
3. jika drift `high`, jangan finalize; route ke `checkpoint` + `think` untuk recovery context
4. jika perlu external refresh, route ke `web-search` dengan query terarah
5. lakukan `/compact` secara proaktif saat selesai fase besar (investigasi -> implementasi -> verifikasi)

## Thread-Per-Phase Rule

Untuk menjaga context hygiene:
1. gunakan 1 thread untuk 1 fase utama
2. saat pindah fase/domain kerja, gunakan `/new` atau `/fork`
3. sebelum pindah thread, simpan handoff ringkas ke `checkpoint`

## Mandatory Phase Checkpoint

Untuk task kompleks, fase minimum:
1. `investigate`
2. `plan`
3. `implement`
4. `verify`

Aturan:
- jangan loncat fase tanpa alasan eksplisit
- setiap fase wajib punya output singkat + evidence kunci
- setelah tiap fase besar, jalankan checkpoint/compact sebelum lanjut

Multi-hour execution artifact:
- untuk task panjang, gunakan artifact fase di `PLANS.md` (atau file plan setara) berisi:
  - `phase`
  - `goal`
  - `done`
  - `next`
  - `blockers`
  - `owner`

Simple-loop execution contract:
1. `observe`
2. `decide`
3. `act`
4. `verify`
5. lanjut ke langkah berikutnya hanya jika `verify` lulus

## Freshness and Conflict Hard Gate

Untuk plan yang memakai riset eksternal:
1. cek evidence punya tanggal yang sesuai kebutuhan recency
2. jika query bersifat update/trend, gunakan window `last_30_days`
3. jika ada konflik sumber, tampilkan conflict panel sebelum decision final
4. jika source kunci kosong, status wajib `BLOCKED` atau `NEEDS REVISION` (bukan `READY`)

## Output Wajib
- plan artifact + current gate
- files changed + verification evidence
- blockers/residual risk
- final verdict: READY | BLOCKED | NEEDS REVISION

## Deterministic Step-Gating Contract

Setiap langkah plan harus punya output valid sebelum lanjut:
1. `step_id`
2. `status` (`pass` | `fail` | `blocked`)
3. `evidence`
4. `next_action`

Tambahan field wajib:
5. `context_sufficiency` (`enough`|`insufficient`)
6. `evidence_level` (`L1_official`|`L2_primary`|`L3_secondary`|`insufficient`)
7. `gate_reason` (alasan pass/fail/blocked yang bisa diaudit)

## Observable Signals Gate

Sebelum implementasi untuk task non-trivial:
1. definisikan sinyal observasi minimum:
- `success_metric`
- `failure_metric`
- `data_source` (test/log/trace/manual check)
2. jika sinyal belum terdefinisi, status plan `NEEDS REVISION`
3. final verdict `READY` hanya jika sinyal observasi utama sudah tervalidasi

## Toolkit Scope Gate (External Integrations)

Untuk plan yang memakai platform toolkit/connector:
1. tentukan `toolkits_selected[]` sebelum execute
2. pastikan scope toolkit seminimal mungkin
3. verifikasi `auth_state` dan `callable_probe_status` sebelum langkah eksekusi utama
4. jika probe gagal, status langkah wajib `blocked` (jangan lanjut patch)

## Deterministic vs Side-Effect Step Split

Saat menyusun plan:
1. tandai `step_type: deterministic` untuk langkah reasoning/state transition murni
2. tandai `step_type: activity` untuk langkah side-effect (I/O, network, write eksternal)
3. langkah `activity` wajib punya retry/idempotency note sebelum execute
4. jangan campur dua tipe dalam satu langkah jika ingin tetap replay-safe

## Queue-Driven Progress Loop

Untuk task dengan handoff worker/agent:
1. `poll` status task/queue
2. `progress` langkah berikutnya yang valid
3. `verify` output/evidence
4. `requeue_or_finalize` berdasarkan hasil verifikasi

Jika terdeteksi backlog/stall:
- tandai `queue_status: degraded`
- route ke `debug-n-check` sebelum lanjut

## Todo State Invariant

Untuk plan multi-langkah, status task wajib:
1. hanya satu `in_progress` dalam satu waktu
2. task baru tidak boleh `completed` tanpa evidence
3. jika validasi status gagal, stop eksekusi dan perbaiki state dulu

Gunakan validator:
```bash
python3 .codex/skills/smart-plan/scripts/todo-state-validate.py --file <path-json>
```

## Context Isolation for Large Plans

Jika satu langkah butuh eksplorasi besar:
1. jalankan subtask dengan context terpisah (subagent/thread fase khusus)
2. bawa balik hanya output keputusan + evidence ringkas
3. update step berikutnya dari ringkasan, bukan dari seluruh log eksplorasi
