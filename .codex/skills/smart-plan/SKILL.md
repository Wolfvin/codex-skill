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

## Output Wajib
- plan artifact + current gate
- files changed + verification evidence
- blockers/residual risk
- final verdict: READY | BLOCKED | NEEDS REVISION
