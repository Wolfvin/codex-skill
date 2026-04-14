---
name: intelect_inject
description: Context injection orchestrator for design and TypeScript tooling guidance. Use when smart-plan needs extra implementation context, especially for frontend quality and TS/JS language-server driven checks.
---

# Intelect Inject

Skill parent dengan 2 anak context:
- `frontend-design`
- `typescript_inject`

Gunakan skill ini saat eksekusi `smart-plan` butuh injeksi konteks tambahan sebelum implementasi.

## Child 1: frontend-design

Tujuan:
- Menentukan direction visual dan UX yang production-grade.
- Menjaga UI tidak generic dan tetap konsisten dengan style intent.

Gunakan ketika:
- Task melibatkan UI baru, redesign, atau polishing frontend.

## Child 2: typescript_inject

Tujuan:
- Menyuntikkan praktik TypeScript/JS berbasis language-server (diagnostics, symbol/reference navigation, refactor safety).

Gunakan ketika:
- Task melibatkan TS/JS dan risiko regress tinggi.
- Perlu verifikasi cepat lewat signal tooling sebelum/selama perubahan.

## Routing Rule

1. Jika fokus visual/UX -> pakai `frontend-design`.
2. Jika fokus correctness TS/JS -> pakai `typescript_inject`.
3. Jika keduanya relevan -> jalankan berurutan:
- `frontend-design` dulu untuk arah UI,
- `typescript_inject` untuk validasi implementasi.

## Output Wajib

- child yang dipakai
- alasan pemilihan child
- constraint implementasi yang diinjeksikan
- risiko sisa setelah injeksi konteks
