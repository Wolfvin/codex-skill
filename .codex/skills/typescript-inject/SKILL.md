---
name: typescript-inject
description: TypeScript and JavaScript context injection for safer implementation. Use when agents need diagnostics, symbol/reference impact checks, and refactor-safety gates before or during code changes.
---

# TypeScript Inject

Skill ini menyuntikkan konteks teknis TS/JS agar implementasi lebih aman.

## Trigger
- Task menyentuh TypeScript/JavaScript dengan risiko regresi.
- Perlu validasi cepat sebelum/selama refactor.
- `smart-plan` atau `intelect-inject` butuh guardrail TS/JS.

## Core Workflow

1. Preflight scope:
- identifikasi file/area TS/JS yang terdampak
- petakan symbol/reference penting
2. Diagnostics gate:
- jalankan cek diagnostics/type errors terlebih dulu
- jangan lanjut implementasi jika error kritis belum jelas akar masalahnya
3. Change safety:
- saat perubahan, cek dampak reference/usage untuk symbol yang diubah
- validasi kontrak tipe pada boundary utama (API, props, return type)
4. Refactor guard:
- prefer perubahan bertahap
- verifikasi tiap fase sebelum lanjut
5. Hand-off ke verification:
- kirim ringkasan hasil ke `debug-n-check` atau `review`

## Versioned Iteration Loop (Prompt/Config Sensitive Tasks)

Untuk task agentic TS/JS yang sensitif pada prompt/config:
1. catat baseline versi prompt/config yang aktif
2. lakukan perubahan kecil per iterasi
3. jalankan evaluasi ringkas tiap iterasi (test/log/trace)
4. simpan keputusan lanjut/rollback berbasis evidence

Field minimum:
- `version_tag`
- `change_summary`
- `eval_signal`
- `decision` (`keep`|`rollback`|`iterate`)

## Guardrails
- Hindari rewrite besar tanpa plan.
- Jangan abaikan type errors yang muncul setelah patch.
- Prioritaskan kompatibilitas behavior saat melakukan simplifikasi/refactor.

## Output Wajib
- file TS/JS yang dianalisis
- hasil diagnostics ringkas
- symbol/reference yang berisiko
- rekomendasi aksi aman (lanjut, patch kecil, atau replan)
