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

## Input/Output Contract and Scope Lock

Sebelum review mulai, wajib tetapkan:
1. exact input (file/scope/revisi yang dinilai)
2. exact output (format findings yang diminta)
3. explicit do-not-do (contoh: jangan propose fitur baru, jangan rewrite di luar scope)

Jika input/scope ambigu, minta 1 klarifikasi lalu stop.

## Mode 1 - Simplify Safely
- Scope: file yang baru diubah.
- Aturan: behavior harus identik.
- Fokus: clarity, konsistensi, maintainability.

Checklist wajib sebelum status aman:
1. perubahan bersifat surgical (extract/rename/simplify), bukan rewrite besar
2. tidak mengubah kontrak eksternal (API, schema, event, CLI)
3. ada bukti parity (test/check/log) sebelum dan sesudah
4. dampak symbol/reference utama sudah dicek

## Mode 2 - PR Risk Review
Urutan review:
1. blast radius
2. security risks
3. breaking change checks
4. testing delta
5. performance risks
6. TS/JS diagnostics gate (jika stack TypeScript/JavaScript)
7. urutan fase aman untuk refactor multi-file (types -> implementation -> tests -> cleanup)
8. conflict panel untuk klaim yang berasal dari multi-source riset

Tambahan checks untuk workflow durable/stateful:
9. deterministic workflow boundary (langkah tanpa side-effect tersembunyi)
10. idempotency/retry policy untuk langkah activity/integrasi eksternal

Tambahan checks untuk agent-computer interface:
11. kualitas browse/edit/exec/verify feedback loop
12. kejelasan artefak evidence per langkah untuk replay audit

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

## Mode 7 - Refactor Plan Quality Review
Gunakan saat user minta review rencana refactor kompleks:
1. validasi dependency map dan blast radius per file
2. cek urutan fase perubahan (types -> implementation -> tests -> cleanup)
3. pastikan tiap fase punya verification gate + rollback step
4. tandai coupling risk dan urutan eksekusi yang harus dihindari

## Mode 8 - Issue Ticket Closure Review
Gunakan saat review per issue/ticket:
1. cek acceptance criteria tiap issue
2. pastikan evidence verifikasi cukup untuk close
3. tulis residual risk singkat sebelum issue ditutup

## Mode 9 - AI Visual Review Prioritization
Gunakan saat review melibatkan visual regression/snapshot diff:
1. urutkan snapshot berdasarkan bug-likelihood (`irregular` high->low)
2. pisahkan perubahan `valid` sebagai batch review sekunder
3. jika ada noise rule (ignore/show), cek apakah rule menutupi regression penting
4. jika AI review unavailable, wajib fallback ke perbandingan standar dan catat dampaknya
5. output wajib: `visual_risk_queue`, `ignored_diff_risk`, `fallback_used`

## Mode 14 - Domain-Fit UI Review
Gunakan untuk review hasil UI yang harus sesuai konteks industri:
1. cocokkan `product_domain` vs `style_direction` yang dipilih
2. cek apakah pattern UI mendukung objective domain (trust, conversion, clarity, compliance)
3. tandai mismatch sebagai temuan minimal `medium`
4. output wajib: `domain_fit_status`, `style_domain_mismatch`, `recommended_adjustment`

## Mode 10 - Hook Provenance Review
Gunakan saat review menyangkut lifecycle hooks/runtime hooks:
1. verifikasi evidence dipisah: native vs plugin vs runtime fallback
2. cek claim kesesuaian dengan proof yang tersedia
3. tandai high-risk jika klaim native dibuat tanpa evidence native
4. output wajib: `provenance_matrix`, `claim_mismatch`, `acceptance_decision`

## Mode 13 - Hook Surface Drift Audit
Gunakan saat setup/plugin/runtime mengalami masalah hook:
1. bandingkan hook source antar surface (plugin config, settings, runtime convention)
2. deteksi duplicate registration atau path drift
3. tetapkan source canonical hooks
4. output wajib: `hook_drift_panel`, `canonical_hook_source`, `migration_fix_plan`

## Mode 11 - SDK Drift Risk Review
Gunakan saat perubahan menyentuh SDK/vendor integration:
1. cek kesesuaian branch default, docs, dan package/version install
2. cek contract API/toolkit berubah atau tidak
3. tandai mismatch sebagai risk minimal `medium`
4. output wajib: `sdk_drift_panel`, `version_alignment`, `recommended_guardrail`

## Mode 12 - Human-in-the-Loop Checkpoint Review
Gunakan saat workflow bisa di-interrupt/resume:
1. tetapkan pause criteria (kapan harus berhenti dan minta input user)
2. pastikan state saat pause terdokumentasi (`current_state`, `resume_point`)
3. verifikasi evidence minimum sebelum resume
4. tandai risk `high` jika resume dijalankan tanpa state checkpoint yang valid

## Parallel Test Hygiene & Deprecation Gate

Saat review testing strategy:
1. cek parallel safety untuk test/subtest
2. cek base/helper deprecated sudah diganti canonical replacement
3. tandai risk jika masih bergantung pada surface deprecated sebagai jalur utama
4. output wajib: `test_hygiene_status`, `deprecation_migration_status`

## Test-Strength Signal Gate

Untuk area high-risk, evaluasi kekuatan testing:
1. coverage behavior lintas input (property/fuzz style bila relevan)
2. ketahanan test terhadap mutation/regression signal
3. flaky-risk indicator

Jika hanya ada sinyal pass/fail dangkal:
- turunkan confidence review
- rekomendasikan penguatan test sebelum verdict `READY`

## Agent Evaluation Extension
Untuk task agentic/multi-agent, tambahkan evaluasi:
- kualitas outcome vs objective
- stabilitas workflow/context handoff
- indikasi drift/hallucination yang perlu guardrail

Tambahan observability scoring (jika trace tersedia):
- `quality_score`
- `latency_signal`
- `cost_signal`
- `trace_ref`

## Judgment-Only Gate

Untuk mode risk review, jalankan fase judgment dulu:
1. evaluasi kualitas dan risiko
2. baru setelah itu berikan decision/rekomendasi tindakan

Kontrak pemisahan wajib:
1. `judgment_output`: hanya evaluasi + evidence, tanpa patch proposal detail
2. `decision_output`: pilihan aksi + tradeoff
3. `generation_output`: rekomendasi perubahan konkret (jika diminta)

## Context7 API Verification Gate
Untuk perubahan berbasis library/API docs:
1. pastikan referensi API berasal dari docs terbaru (Context7/source primer)
2. cek versi library yang dipakai sesuai requirement
3. tandai mismatch API signature sebagai temuan high-risk

## Post-Review Reflection Loop
- Untuk temuan critical/high, jalankan satu putaran refleksi:
- critique temuan -> usulkan perbaikan -> re-check cepat
- simpan insight reusable ke checkpoint jika pola berulang

## Guardrail Review Pipeline
- Verifikasi plan/check evidence ada.
- Review correctness + regression.
- Review security-impact.
- Validasi readiness sebelum status READY.

Deterministic backstop checks:
- untuk gate kritis (lint/test/readiness), definisikan sebagai check wajib yang tetap jalan meski langkah agent sebelumnya skip.

## Output Contract
- findings first (severity + file + impact + recommendation)
- residual risk + missing tests
- jika mode simplify: daftar simplifikasi + verifikasi parity
- jika mode debt: debt scorecard + urutan remediasi + risiko jika ditunda
- jika TS/JS stack: sertakan hasil ringkas diagnostics gate
- jika mode misuse: daftar contract violation + correct usage pattern
- jika mode consistency: daftar mismatch surface + canonical fix plan
- jika ada konflik sumber: tampilkan dua sisi + evidence level + keputusan akhir

Jika review menyentuh interface agent:
- sertakan `aci_quality_panel` (`browse|edit|exec|verify`)

Review readiness panel:
- `engineering_ready`
- `design_ready`
- `dx_ready`
- `security_ready`
