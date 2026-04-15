---
name: intelect-inject
description: Context injection orchestrator with pluggable sub-skills. Use when smart-plan or agents need additional context; routes to domain sub-skills and falls back to web-search when no direct sub-skill matches.
---

# Intelect Inject

Skill parent dengan sub-skill context:
- `frontend-inject`
- `typescript-inject`
- `tauri-inject`
- `web-search` (fallback utama saat konteks kurang)

Gunakan skill ini saat eksekusi `smart-plan` butuh injeksi konteks tambahan sebelum implementasi.
Untuk task non-trivial, jalankan `think` dulu agar pemilihan child lebih tepat.

## Child 1: frontend-inject

Tujuan:
- Menentukan direction visual dan UX yang production-grade.
- Menjadikan `DESIGN.md` sebagai kontrak implementasi bila tersedia.
- Menjaga UI tidak generic dan tetap konsisten dengan style intent.

Gunakan ketika:
- Task melibatkan UI baru, redesign, atau polishing frontend.

## Child 2: typescript-inject

Tujuan:
- Menyuntikkan praktik TypeScript/JS berbasis language-server (diagnostics, symbol/reference navigation, refactor safety).

Gunakan ketika:
- Task melibatkan TS/JS dan risiko regress tinggi.
- Perlu verifikasi cepat lewat signal tooling sebelum/selama perubahan.

## Child 3: tauri-inject

Tujuan:
- Menyuntikkan konteks domain Tauri (template, plugin, integration, compatibility).

Gunakan ketika:
- Task melibatkan app desktop/mobile berbasis Tauri.
- Perlu pemilihan stack Tauri yang kecil tapi tepat.

## Routing Rule

Konsep routing mengikuti disiplin `skill-router`:
- gunakan minimal child set yang cukup
- kunci scope sesuai intent user (scope-lock)
- fallback eksternal hanya jika child domain tidak cukup

1. Jalankan `think` untuk cek gap konteks + domain prioritas.
1a. Jalankan clarify-first intake singkat untuk konteks non-teknis:
- tujuan
- constraint bisnis
- SLA/deadline
- siapa owner maintenance
2. Untuk gap konteks umum, cek sumber lokal dulu (memory/codegraph/tooling lokal bila tersedia).
3. Jika fokus visual/UX -> pakai `frontend-inject`.
4. Jika fokus correctness TS/JS -> pakai `typescript-inject`.
5. Jika fokus Tauri desktop/mobile -> pakai `tauri-inject`.
6. Jika kombinasi visual + TS/JS relevan -> jalankan berurutan:
- `frontend-inject` dulu untuk arah UI,
- `typescript-inject` untuk validasi implementasi.
7. Jika kombinasi Tauri + TS/JS relevan -> jalankan:
- `tauri-inject` dulu untuk stack decision,
- `typescript-inject` untuk implementation safety.
8. Jika konteks lokal tetap kurang -> route ke `web-search`.
9. Saat route ke `web-search`, mulai dari mode `quick` (`backend_used: native_search`) dan eskalasi hanya jika evidence belum cukup.
10. Jika evidence membutuhkan interaksi halaman (klik/form/state dinamis), eskalasi ke `web-search` mode browser-action.

Signal route tambahan:
- jika task menyebut multi-platform UI/framework campuran, prioritaskan `frontend-inject` dulu untuk kunci design contract lintas target

Rule tambahan:
- jika domain adalah person/brand/product publik, aktifkan entity handle-resolution sebelum web-search utama
- gunakan identifier resmi sebagai query anchor agar hasil tidak tercampur entitas lain

## Sub-Skill Expansion Rule

- Parent ini dirancang untuk menampung lebih banyak sub-skill ke depan.
- Jika domain baru belum punya sub-skill, gunakan `web-search` untuk menyuplai konteks sementara.
- Hasil `web-search` harus dicatat ke short-term memory (`.codex/memory/MEMORY.md`) sebagai kandidat evolusi sub-skill baru.

Prioritas sumber konteks:
1. local memory/codegraph/index lokal (jika tersedia)
2. domain sub-skill yang cocok
3. `web-search` sebagai fallback eksternal

## Capability Contract (Parent -> Child)

Setiap child harus dipanggil dengan kontrak minimum:
1. `objective`
2. `scope_lock`
3. `expected_output`

Setiap child wajib mengembalikan:
1. `constraints_injected`
2. `confidence`
3. `next_action`

Priority matrix (default):
1. `frontend-inject` (untuk UI/design)
2. `typescript-inject` (untuk correctness TS/JS)
3. `tauri-inject` (untuk domain desktop/mobile Tauri)
4. `web-search` (fallback eksternal)

## Output Wajib

- child yang dipakai
- alasan pemilihan child
- constraint implementasi yang diinjeksikan
- risiko sisa setelah injeksi konteks
- jika fallback ke `web-search`: entri short-term memory yang ditambahkan
- jika pakai browser-action: langkah interaksi + artefak bukti (url/screenshot/log)
