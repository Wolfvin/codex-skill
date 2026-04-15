---
name: review
description: Unified review workflow for code simplification, high-signal PR risk review, and technical debt prioritization. Use when user asks for review, cleanup refactor without behavior change, PR quality gate analysis, or debt scoring/remediation planning.
---

# Review

Skill gabungan dari `code-simplifier`, `pr-review-expert`, dan `tech-debt-tracker`.

## Trigger
- User minta review code/PR.
- User minta simplifikasi kode tanpa ubah behavior.
- User minta quality gate sebelum merge.
- User minta audit/priority technical debt.

## Mode 1 - Simplify Safely
- Scope: file yang baru diubah.
- Aturan: behavior harus identik.
- Fokus: clarity, konsistensi, maintainability.

## Mode 2 - PR Risk Review
Urutan review:
1. blast radius
2. security risks
3. breaking change checks
4. testing delta
5. performance risks
6. TS/JS diagnostics gate (jika stack TypeScript/JavaScript)

### TS/JS Diagnostics Gate
- Gunakan signal language-server (`typescript-lsp`) untuk:
- type diagnostics cepat
- symbol/reference impact checks
- refactor safety sebelum merge

## Mode 3 - Technical Debt Review
1. Inventory debt signals
- TODO/HACK, dependency stale, flaky test, duplicated logic, ops/doc debt.

2. Score each item
- impact, frequency, risk, effort.

3. Prioritize
- high impact + low/medium effort dulu.

4. Remediation slices
- ubah top debt menjadi chunk eksekusi per sprint.

## Mode 4 - Operational Misuse Review
Gunakan untuk review bug yang akar masalahnya salah pemakaian command/runtime:
1. identifikasi kontrak command yang dilanggar
2. klasifikasikan severity misuse (critical/high/medium)
3. tampilkan wrong pattern vs correct pattern
4. rekomendasikan guardrail permanen (checklist, preflight gate, linting/CI check jika memungkinkan)

## Mode 5 - Surface Consistency Audit
Gunakan saat ada banyak permukaan metadata (README, manifest, marketplace, docs):
1. bandingkan angka/metadata penting antar surface
2. catat mismatch (count, version, command install, kategori)
3. tandai source canonical yang benar
4. rekomendasikan update sinkronisasi agar tidak drift lagi

## Mode 6 - Spec Consistency Review
Gunakan untuk workflow specification-driven:
1. cek keselarasan spesifikasi vs implementasi
2. identifikasi requirement yang hilang atau salah tafsir
3. minta perbaikan spesifikasi dulu jika mismatch fundamental

## Post-Review Reflection Loop
- Untuk temuan critical/high, jalankan satu putaran refleksi:
- critique temuan -> usulkan perbaikan -> re-check cepat
- simpan insight reusable ke checkpoint jika pola berulang

## Guardrail Review Pipeline
- Verifikasi plan/check evidence ada.
- Review correctness + regression.
- Review security-impact.
- Validasi readiness sebelum status READY.

## Output Contract
- findings first (severity + file + impact + recommendation)
- residual risk + missing tests
- jika mode simplify: daftar simplifikasi + verifikasi parity
- jika mode debt: debt scorecard + urutan remediasi + risiko jika ditunda
- jika TS/JS stack: sertakan hasil ringkas diagnostics gate
- jika mode misuse: daftar contract violation + correct usage pattern
- jika mode consistency: daftar mismatch surface + canonical fix plan
