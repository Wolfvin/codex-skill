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

## Output Wajib
- mode checkpoint: ringkasan knowledge yang disimpan di `MEMORY.md`
- mode onboarding: engineering map ringkas (run/test/risk zones)
