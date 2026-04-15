---
name: checkpoint
description: Unified memory checkpoint and rapid codebase onboarding workflow. Use when user asks to save learnings/context, persist session insights, avoid repeating failed approaches, or quickly onboard unfamiliar repositories into an executable engineering map.
---

# Checkpoint

Skill gabungan dari memory checkpoint dan codebase onboarding.

## Mode 1 - Memory Checkpoint

Gunakan saat user meminta simpan insight sesi.

1. Ringkas masalah, pendekatan gagal, solusi benar, dan bukti verifikasi.
2. Terapkan single-file memory policy: update `.codex/memory/MEMORY.md` saja.
3. Hindari duplikasi; simpan hanya high-signal yang reusable.
4. Laporkan poin yang ditambah/diperbarui.

Aturan token-budget untuk memory:
- no decorative explanation
- no background panjang yang tidak reusable
- ringkas dalam format poin operasional

## Mode 2 - Repo Onboarding

Gunakan saat mulai di repo yang belum familiar.

1. Petakan struktur root, stack, dan toolchain utama.
2. Identifikasi entry point run/test/build dan area risiko.
3. Susun engineering map ringkas untuk eksekusi cepat.

## Reflection Learning Capture

Saat ada review/reflection loop, simpan insight dengan format:
- Problem pattern
- Wrong approaches
- Correct strategy
- Verification evidence

Jika insight tidak menambah nilai jangka panjang, jangan simpan.

## Trace/Eval Learning Format

Untuk task agentic/tooling, simpan lesson dalam format observability ringkas:
- `symptom`
- `root_cause`
- `fix_applied`
- `verification_signal` (test/log/trace)
- `confidence` (`high`|`medium`|`low`)
- `reusable_rule`

Aturan:
- hindari narasi panjang; simpan hanya field operasional
- jika belum ada verification signal, jangan naikkan confidence di atas `low`

## Think-Lesson Capture

Saat input berasal dari `think`, simpan hanya trace ringkas (bukan chain-of-thought mentah):
- `task_pattern`
- `context_gap_detected`
- `search_query_used`
- `evidence_level`
- `decision_taken`
- `failure_mode`
- `reusable_rule`

Aturan:
- deduplicate jika pola sama sudah ada
- pertahankan hanya rule yang reusable lintas task

Tambahkan taxonomy retrieval failure:
- `missing_source_type` (no_results|off_topic|stale|undated|blocked)
- `conflict_type` (source_disagreement|ranking_shift|evidence_mismatch)

## UI Anti-Pattern Learning Capture

Untuk task UI yang selesai, simpan ringkas:
1. `ui_anti_pattern_detected`
2. `ui_fix_applied`
3. `ui_verification_evidence`
4. `ui_reusable_rule`

## Compaction Snapshot and Recovery

Untuk mencegah hilangnya konteks pasca compaction, simpan dua artefak ringkas:
1. `pre_compact_snapshot`:
- objective aktif
- constraint penting
- file/work item in-flight
- next step
2. `post_compact_audit`:
- `ghost_lexicon` (term/domain yang hilang)
- `drift_score` (`low|medium|high`)
- recovery action

Jika `drift_score: high`:
- prioritaskan recovery dari memory lokal dulu
- jangan finalize jawaban sampai audit kembali stabil

Resume-point schema wajib:
1. `goal`
2. `done`
3. `next`
4. `blockers`
5. `confidence` (`high|medium|low`)

## Plan Artifact Sync

Jika task memakai artifact fase (`PLANS.md` atau setara):
1. sinkronkan `done/next/blockers` ke `MEMORY.md` saat phase close
2. jangan copy seluruh plan; simpan hanya delta high-signal

## Memory Consolidation and Dedup

Saat knowledge tersebar di banyak catatan:
1. kumpulkan lessons yang sudah matang
2. deduplicate (gabungkan poin overlap)
3. simpan hasil final hanya ke `.codex/memory/MEMORY.md`
4. pastikan tidak ada knowledge loss pada keputusan/guardrail penting

## Closed Learning Loop (Capture -> Compress -> Retrieve -> Reuse)

Gunakan loop ini agar memory benar-benar dipakai lintas sesi:
1. `capture`: simpan lesson high-signal dari task selesai
2. `compress`: ringkas lesson jadi rule operasional singkat
3. `retrieve`: saat task baru mirip, tarik rule terkait dari `MEMORY.md`
4. `reuse`: terapkan rule ke plan/checklist aktif, lalu catat hasilnya

Rule retrieval:
- cocokkan berdasarkan `task_pattern` + `failure_mode`
- jika retrieval tidak cukup evidence, tandai `insufficient-memory-evidence`

Anti-memory-explosion guard:
- saat volume memory naik, lakukan compact berkala dan simpan hanya high-signal reusable rules
- tandai item detail non-reusable untuk dipruning pada siklus berikutnya

## Wiki Lifecycle Boundary

Jika workspace memakai wiki/session capture:
1. startup context bersifat read-mostly dan ringkas
2. session-end capture harus best-effort dan non-blocking
3. jangan biarkan capture/refresh berat memblokir jalur eksekusi utama
4. simpan hanya ringkasan high-signal, bukan dump penuh log runtime

## Issue-Centric Capture

Untuk issue yang sudah ditutup, simpan ringkas:
- issue pattern
- root cause
- fix yang terbukti
- regression guardrail

## Replay/Session Artifact Intake

Jika tersedia artefak observability lokal:
- `.omc/state/*.jsonl`
- `.omc/sessions/*.json`

Maka ekstrak hanya sinyal high-value:
1. bottleneck event utama
2. failure transition paling berulang
3. intervention signal (stale/cost spike/wait state)
4. reusable rule untuk pencegahan sesi berikutnya

Tambahan field capture untuk workflow queue/stateful:
- `queue_signal` (`healthy`|`backlog`|`stalled`)
- `handoff_outcome` (`ok`|`dropped`|`timeout`)
- `evidence_artifact_path`
- `source_thread_assumptions`

Rule confidence memory:
- lesson dengan confidence `high` wajib punya `evidence_artifact_path`
- jika tidak ada artefak, maksimal `confidence: medium`

## Sprint Handoff Artifact Schema

Untuk lane sprint default, simpan artifact minimum:
1. `plan_artifact_ref`
2. `review_delta`
3. `test_delta`
4. `release_note_ref`

## Output Wajib
- mode checkpoint: ringkasan knowledge yang disimpan di `MEMORY.md`
- mode onboarding: engineering map ringkas (run/test/risk zones)
