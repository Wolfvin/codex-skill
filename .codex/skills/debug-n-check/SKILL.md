---
name: debug-n-check
description: Unified debug and verification workflow for frontend and backend issues. Use after plan completion for validation, or immediately when user reports a bug. Combines console loop (frontend/js/ui) and terminal loop (backend/api/runtime) with evidence-first iteration.
---

# Debug-n-Check

Skill gabungan dari:
- `debug-console`
- `skill_ps1`
- `focused-fix`

## Trigger Utama
1. Setelah sebuah plan selesai dan harus check.
2. Saat user menemukan bug.

## Anak Skill / Mode

### 1) `console`
Gunakan jika issue dominan di frontend/js/ui.

Workflow:
1. capture evidence (screenshot/DOM/console log)
2. reproduce bug dengan langkah minimum
3. apply fix secara surgical
4. verify per iteration (maks 5 loop)
5. laporkan pass/fail + delta visual/behavior

Tambahan untuk TS/JS:
- pakai signal tooling (`typescript-lsp`) untuk cek:
- diagnostics/type error cepat
- symbol/reference impact setelah perubahan
- indikasi refactor break sebelum lanjut iterasi berikutnya

Output minimal:
- changed files
- screenshot/log evidence
- iteration count
- remaining risks

### 2) `terminal`
Gunakan jika issue dominan di backend/api/runtime.

Workflow:
1. preflight health
2. run debug cycle script (health, GET/POST, verify, cleanup)
3. isolate root cause (dependency/contract/logic/integration)
4. fix bertahap + retest
5. simpulkan status dan blocker

Output minimal:
- command yang dijalankan
- hasil health/check/test
- root cause summary
- next action

## Routing Rule
- Kalau bug di UI/interaction -> mode `console`.
- Kalau bug di API/server/process -> mode `terminal`.
- Kalau mixed issue -> mulai `terminal` (stabilkan backend), lalu `console`.

## Guardrails
- Evidence first, no blind fix.
- One issue at a time.
- No unrelated refactor.
- Stop and escalate jika setelah 5 iterasi belum stabil.
- Jangan rewrite besar kecuali user minta eksplisit.
- Jangan feature creep saat sesi debug.
- Jangan klaim root cause tanpa evidence yang bisa diaudit.

## Session and Runtime Gates (Automation/MCP)

Jika debugging melibatkan automation driver/MCP session, wajib jalankan gate ini:
1. Start session lalu cek status koneksi, jangan asumsi start = connected.
2. Validasi output status yang menunjukkan koneksi aktif sebelum panggil tool lain.
3. Jika muncul error "no active session", ulangi session start + status check.
4. Bedakan masalah session vs daemon:
- session stop: putuskan koneksi kerja saat ini
- daemon restart/stop: untuk proses background yang stale

Failure mode prioritas tinggi yang harus dicek dulu:
- menjalankan tool sebelum session aktif
- percaya start command tanpa verifikasi status koneksi
- salah format flag/arg sehingga command jalan tapi perilaku meleset
- misuse output contract (misalnya mengharap bytes padahal tool menulis file)

## Interrupt/Resume Debug Contract

Jika debug harus pause karena menunggu user/system:
1. simpan `current_state` dan `resume_point`
2. simpan `last_verified_evidence`
3. saat resume, validasi ulang precondition minimum sebelum lanjut
4. jika state drift terdeteksi, kembali ke langkah reproduksi terakhir yang valid

## Plugin-Dir Mismatch Triage

Jika issue terkait setup/plugin runtime:
1. cek `plugin_root_launch_path` vs `OMC_PLUGIN_ROOT`
2. cek apakah setup dijalankan dengan mode yang sesuai (`plugin-dir-mode` vs normal)
3. jika mismatch, klasifikasikan `plugin_root_mismatch` dan stop patch lanjutan
4. recovery default: samakan path -> re-run setup -> re-run doctor

## Guardrail Pipeline (Execution Order)

Untuk issue yang kompleks, jalankan urutan ini:
1. Plan hipotesis + scope reproduksi.
2. Verify precondition (session/runtime/config).
3. Apply fix minimal.
4. Review dampak (regresi/security/performance singkat).
5. Re-verify evidence akhir.

## Refactor Verification Gates (Behavior-Preserving)

Jika debugging/verifikasi dipicu oleh aktivitas refactor:
1. jalankan verifikasi per fase, jangan gabung semua perubahan sekaligus
2. fase yang direkomendasikan: types -> implementation -> tests -> cleanup
3. jika satu fase gagal, stop lanjut fase berikutnya
4. rollback perubahan fase gagal, lalu ulangi dengan scope lebih kecil
5. catat trigger kegagalan agar masuk ke replan berikutnya

## Memory MCP Troubleshooting Playbook

Jika issue terkait MCP memory:
1. cek apakah session/client benar-benar aktif
2. verifikasi command server-memory sesuai config
3. uji operasi read/write sederhana untuk cek kontrak output
4. jika gagal, bedakan masalah reconnect vs restart runtime
5. log evidence per langkah sebelum patch lanjutan

## Browser Automation Contract Gate

Untuk issue pada `agent-browser`/CDP browser:
1. pastikan reference skill/command browser sudah di-load (hindari syntax stale)
2. jalankan preflight browser stack:
```bash
bash .codex/skills/setup/scripts/browser-preflight.sh
```
3. verifikasi session/CDP endpoint sebelum interaksi halaman
4. jika memakai Lightpanda, cek mode `serve`/`mcp` sesuai workflow

Live-browser QA closure:
1. untuk bug UI/web high-risk, prefer lane headed browser dengan bukti screenshot/video/log
2. setelah fix, wajib tambah regression check agar bug tidak kembali

## Selective Install Recovery

Jika bug berasal dari instalasi tooling/skill yang parsial:
- cek install-state yang aktif
- jalankan doctor untuk temukan drift/missing file
- jalankan repair terarah sebelum melakukan reinstall penuh

Klasifikasi khusus install lifecycle:
- `install_state_drift`
- `missing_managed_files`
- `duplicate_hook_registration`

## Replan Fallback Rule

Jika verifikasi gagal berulang (maksimal 3 siklus fix tambahan setelah hipotesis awal):
1. hentikan patch lanjutan
2. rollback ke state perencanaan
3. buat hipotesis baru dan jalur verifikasi baru sebelum lanjut implementasi

## Linear Action Replay Loop

Untuk menjaga debug tetap stabil dan mudah diulang:
1. catat aksi dalam urutan linear (`step_1`, `step_2`, ...)
2. tiap langkah wajib punya `command_or_action` + `evidence`
3. jika gagal di step N, ulang dari step N (jangan lompat step besar)
4. simpan ringkasan replay agar investigasi berikutnya tidak mengulang noise

## Deterministic Output Contract

Output debug wajib pakai field tetap:
1. `mode` (`console`|`terminal`)
2. `scope`
3. `commands_or_steps`
4. `evidence`
5. `root_cause`
6. `status` (`pass`|`fail`|`blocked`)
7. `next_action`

## Input Contract Gate

Sebelum debug dimulai, lock input minimum:
1. `issue_scope`
2. `expected_behavior`
3. `actual_behavior`
4. `repro_steps_min`

Jika salah satu kosong:
- status `blocked`
- keluarkan 1 permintaan data paling kecil untuk lanjut

## Explicit Failure Mode Policy

Jika evidence tidak cukup atau format output tidak valid:
1. set `status: blocked`
2. isi `root_cause` dengan kategori kegagalan yang spesifik
3. berikan 1 `next_action` paling kecil untuk memulihkan evidence

Jika terjadi scope creep saat debug:
1. tolak perluasan scope
2. kembali ke issue utama
3. minta konfirmasi user sebelum domain baru dibuka

## Hook Proof Boundary Contract

Jika investigasi terkait hook/runtime lifecycle, wajib bedakan bukti:
1. `native_hook_proof`:
- evidence event native benar memicu hook wrapper
2. `plugin_hook_proof`:
- evidence dari log/plugin dispatcher
3. `runtime_fallback_proof`:
- evidence berasal dari fallback runtime (tmux/notifier/watcher), bukan native

Larangan:
- jangan klaim "native hook pass" jika yang teruji hanya fallback runtime.

## Composio/Rube MCP Triage

Jika issue terkait Composio SDK atau Rube MCP:
1. cek `provider_adapter` yang dipakai sesuai framework runtime
2. cek auth/connected-account state untuk toolkit target
3. jalankan callable probe pada action minimal toolkit
4. jika gagal:
- klasifikasikan: `auth_issue` | `adapter_mismatch` | `toolkit_scope_issue` | `mcp_transport_issue`
- keluarkan langkah recovery spesifik, bukan generic retry

Taxonomy auth/secret tambahan:
- `missing_secret`
- `auth_not_logged_in`
- `token_injection_failed`
- `plugin_root_mismatch`
- `sandbox_unreachable_recreate_required`

Tambahan taxonomy sampling:
- `sampling_capability_missing`
- `sampling_tools_mismatch`
- `tool_choice_unsupported`

## Session Replay Observability Lane

Untuk issue orchestration/performa:
1. tarik evidence dari replay/session artifact lokal (json/jsonl)
2. korelasikan event timeline dengan titik gagal
3. gunakan sinyal cost/tokens sebagai indikator intervensi (warning, bukan klaim final)
4. jangan simpulkan root cause tanpa bukti timeline

## Replay-First Stateful Triage

Untuk bug pada workflow stateful/durable:
1. audit urutan event/transisi dulu sebelum patch
2. cocokkan state hasil replay dengan state yang diharapkan
3. jika mismatch, klasifikasikan `replay_state_mismatch`
4. patch hanya setelah mismatch terisolasi

## Test Failure Forensics Contract

Saat investigasi test failure:
1. catat `log_level` yang dipakai
2. catat `timeout_profile` (normal/debug)
3. simpan path artefak evidence (`trace/log/replay`)
4. jika artefak tidak ada, status `blocked` untuk root-cause final

## Runtime-Proof Hard Gate

Sebelum menyatakan fix berhasil, wajib ada:
1. command/runtime step yang benar-benar dieksekusi
2. `expected_vs_actual` hasil verifikasi
3. `evidence_artifact_path`

Jika salah satu tidak ada:
- status wajib `blocked_by_missing_runtime_proof`
- jangan klaim fix final

Observability evidence:
- jika tersedia, sertakan `trace_or_session_id` agar hasil bisa direplay/audit

## Source-Conflict Triage Mode

Jika problem muncul dari konflik data riset:
1. kumpulkan klaim per sumber
2. tandai konflik inti (fakta, tanggal, konteks)
3. urutkan sumber berdasarkan evidence level
4. keluarkan rekomendasi resolusi + kebutuhan data tambahan

## Visual Regression Triage Contract

Jika issue terkait visual diff/snapshot:
1. klasifikasikan tiap diff: `irregular` (potensi bug) atau `valid` (perubahan intended)
2. prioritas investigasi: `irregular` dulu, baru `valid`
3. bila AI diff tidak tersedia/konflik, fallback ke diff standar dan tandai sebab fallback
4. gunakan report schema deterministik lewat script:
```bash
bash .codex/skills/debug-n-check/scripts/visual-triage-report.sh \
  --build "<build-id>" \
  --snapshot "<snapshot-id>" \
  --classification "<irregular|valid>" \
  --severity "<high|medium|low>" \
  --summary "<ringkasan>" \
  --evidence "<url-atau-path>" \
  --fallback "<none|standard_diff|manual_review>"
```
5. jangan close issue visual tanpa `classification`, `severity`, `evidence`, dan `next_action`

## UI Pre-Delivery Verification Mode

Untuk validasi akhir task frontend, gunakan checklist pass/fail tetap:
1. `contrast_accessibility` (`pass|fail`)
2. `focus_keyboard_state` (`pass|fail`)
3. `responsive_breakpoints` (`pass|fail`)
4. `hover_active_consistency` (`pass|fail`)
5. `motion_reduced_support` (`pass|fail`)

Output wajib:
- `ui_delivery_checklist`
- `failed_items[]`
- `fix_next_step`
