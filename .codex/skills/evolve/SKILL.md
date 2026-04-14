---
name: evolve
description: Unified skill evolution workflow for upgrading multiple skills from external repo/link inputs. Use when user provides a repo URL or reference source and wants extraction of reusable knowledge, distribution into several existing skills, and pruning of weaker/overlapping skills.
---

# Evolve

Skill ini bukan hanya merge skill. Skill ini adalah engine upgrade:
`repo/link -> ekstrak ilmu -> pecah per domain -> upgrade banyak skill -> hapus skill lemah`.

## Approval Rule (Wajib)

Evolve berjalan dalam **recommendation-first mode**:
1. Analisis dulu.
2. Beri rekomendasi tindakan.
3. **Minta konfirmasi user terlebih dahulu.**
4. Eksekusi hanya setelah user menyetujui.

Tanpa approval eksplisit user, jangan:
- membuat skill baru
- merge/enrich skill
- menghapus skill
- mengubah file skill apa pun

## Trigger

- User memberi repo/link untuk dijadikan referensi upgrade skill.
- User meminta: "pecah jadi beberapa ilmu", "upgrade banyak skill", "hapus skill lemah", "konsolidasi dari sumber ini".
- Skill library terlihat overlap/noisy dan perlu kurasi berbasis source baru.

## Source Intake Mode

1. Intake source
- Terima input repo URL, dokumen link, atau folder referensi.
- Ambil hanya bagian high-signal (workflow, guardrail, checklists, command patterns).

2. Normalize knowledge units (`ilmu`)
- Pecah hasil intake menjadi unit ilmu kecil dan reusable:
- planning
- debugging
- verification
- delivery gates
- tooling/automation
- operasional SOP

3. Score each unit
- Nilai: relevance, novelty, reliability, and transferability.
- Buang unit yang lemah, redundant, atau terlalu spesifik source.

## Knowledge Decomposition (Repo/Link -> Multi-Upgrade)

Setelah intake source, wajib pecah jadi unit ilmu granular:
- workflow rules
- gating rules
- toolchain patterns
- verification/check patterns
- operator/runtime practices

Setiap unit harus punya:
- `unit_name`
- `source_link`
- `confidence` (high/medium/low)
- `target_skills[]`
- `action` (`enrich` | `merge` | `create` | `drop`)

## Multi-Skill Upgrade Mode

Untuk setiap unit ilmu:
1. Map ke skill target yang paling cocok (boleh lebih dari satu target).
2. Putuskan tindakan:
- `enrich`: tambah section/aturan baru ke skill existing.
- `merge`: gabung dua/lebih skill overlap lalu pilih canonical.
- `create`: buat skill baru hanya jika tidak ada owner yang cocok.
3. Lakukan patch lintas beberapa skill dalam satu siklus evolve.

## Weak Skill Pruning Mode

Definisi skill lemah:
- overlap tinggi tetapi coverage lebih sempit dari skill lain
- aturan penting kalah lengkap/tidak terverifikasi
- hanya duplicate tanpa nilai unik

Aturan pruning:
1. Pertahankan skill terkuat sebagai canonical owner.
2. Pindahkan insight unik dari skill lemah ke canonical dulu.
3. Hapus skill lemah setelah migrasi selesai.
4. Update `plan.md` agar inventory tetap akurat.

## Decision Flow

1. User kasih repo/link -> jalankan source intake.
2. Pecah menjadi unit ilmu + scoring.
3. Distribusikan ke beberapa skill target (multi-upgrade) sebagai **usulan**.
4. Susun proposal final + minta approval user.
5. Setelah approve, baru eksekusi perubahan.
6. Update registry/status (`plan.md`) dan lapor impact.

## Output Wajib

- daftar unit ilmu yang diekstrak
- mapping `unit ilmu -> skill target -> action (enrich/merge/create)`
- daftar skill yang dipertahankan vs dihapus (dengan alasan)
- file yang diubah
- ringkasan dampak kualitas skill set setelah evolve

## Format Konfirmasi (Wajib Dipakai)

Sebelum eksekusi, tampilkan:

```text
REKOMENDASI EVOLVE
1) <aksi-1>
2) <aksi-2>
3) <aksi-3>

Konfirmasi:
- setujui semua, atau
- sebut nomor aksi yang disetujui, atau
- revisi yang kamu mau
```

## Example Mapping (from external links)

### Source A
- `https://claude.com/plugins/typescript-lsp`
- Ilmu utama: language-server tooling untuk TS/JS (diagnostics, symbol navigation, ref safety).
- Target skill: `intelect_inject` (child: `typescript_inject`), `review`, `debug-n-check`.
- Action default: `enrich`.

### Source B
- `https://skills.sh/obra/superpowers/brainstorming`
- Ilmu utama: design-first brainstorming gate (one-question-at-a-time, 2-3 approaches, approval before implementation).
- Target skill: `smart-plan`, `skill-router`.
- Action default: `enrich`.
