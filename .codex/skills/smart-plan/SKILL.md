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

2. Delivery Gates
- Feature Spec Gate
- Implementation Gate
- Findings Closure Gate
- Release Readiness Gate

3. Intake and Routing
- parse tag/intent ambigu
- tetapkan objective/constraints/success criteria
- pilih mode direct vs pipeline
- jika butuh context tambahan implementasi, panggil `intelect_inject`:
  - child `frontend-design` untuk arah UI/UX
  - child `typescript_inject` untuk konteks TS/JS tooling

4. Verification Pipeline
- grounding
- source/citation verification
- cross-check
- confidence + uncertainty handling
- final audit + answer QA

## Plan-First Discipline
- Untuk task non-trivial, buat plan terstruktur sebelum implementasi.
- Plan minimal memuat objective, scope, success criteria, langkah verifikasi, risiko.
- Update plan saat scope berubah.

## Brainstorming Gate (Design-First)

Untuk task baru/ambigu, jalankan gate brainstorming sebelum implementasi:
1. Explore context singkat (file/doc/runtime yang relevan).
2. Tanyakan klarifikasi satu per satu (jangan bombardir).
3. Ajukan 2-3 pendekatan + tradeoff + rekomendasi.
4. Present design section-by-section dan minta approval.
5. Setelah approved, baru masuk ke plan eksekusi.

Larangan:
- Jangan coding sebelum design disetujui (kecuali user eksplisit minta direct execution).

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

## Stateful Task Lifecycle

Gunakan state eksplisit untuk task kompleks:
- `draft`: ide awal dan ruang lingkup kasar
- `todo`: spesifikasi siap dieksekusi
- `in-progress`: implementasi aktif dengan checkpoint verifikasi
- `done`: semua gate lolos

Jika verifikasi gagal berulang, kembalikan state ke `todo` untuk replanning.

## Context Budget Planning

Untuk task panjang, tetapkan mode context sebelum eksekusi:
- low: command-oriented, minim artefak
- medium: plan + implement standar
- high: plan rinci + verification panel + reflect phase

## Reflect Before Final Verdict

Untuk task high-risk/ambigu, jalankan reflect phase singkat sebelum status `READY`:
1. evaluasi gap requirement vs hasil
2. cek residual risk tersembunyi
3. update final verdict berdasarkan hasil refleksi

## Output Wajib
- plan artifact + current gate
- files changed + verification evidence
- blockers/residual risk
- final verdict: READY | BLOCKED | NEEDS REVISION
