---
name: evolve
description: Unified skill evolution workflow for upgrading multiple skills from external repo/link inputs. Use when user provides a repo URL or reference source and wants extraction of reusable knowledge, distribution into several existing skills, and pruning of weaker/overlapping skills.
---

# Evolve

Skill ini bukan hanya merge skill. Skill ini adalah engine upgrade:
`repo/link -> ekstrak ilmu -> pecah per domain -> upgrade banyak skill -> hapus skill lemah`.

Selain itu, evolve juga bisa membangun **tool + skill** sekaligus:
`repo/link -> ekstrak ilmu -> putuskan skill-only vs tool+skill -> buat tool -> skill memakai tool`.

## Approval Rule (Wajib)

Evolve berjalan dalam **recommendation-first mode**:
1. Analisis dulu.
2. Beri rekomendasi tindakan.
3. **Minta konfirmasi user terlebih dahulu.**
4. Eksekusi hanya setelah user menyetujui.

Tanpa approval eksplisit user, jangan:
- membuat skill baru
- membuat tool/script baru
- merge/enrich skill
- menghapus skill
- mengubah file skill apa pun

## Recommendation/Patch Separation (Wajib)

Pisahkan dua fase ini secara tegas:
1. Recommendation generation: analisis + usulan aksi, tanpa edit file.
2. Patch generation: eksekusi edit file hanya setelah approval.

Larangan:
- jangan campur analisis dan patch dalam satu fase tanpa persetujuan user.

## Think Gate (Wajib untuk Task Non-Trivial)

Sebelum menyusun rekomendasi evolve:
1. jalankan `think` untuk judgment (kecukupan konteks + risiko halusinasi)
2. lakukan decision (aksi terbaik: enrich/merge/create/create_tool/drop)
3. baru generation (proposal audit atau patch setelah approval)

Jika context belum cukup:
- route ke `intelect-inject`
- fallback `web-search`
- stop dari patching sampai context gate lolos

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

Tambahkan `source_quality_score`:
- `code_evidence` (apakah ada bukti implementasi nyata di repo/script)
- `docs_quality` (jelas/tidaknya kontrak penggunaan)
- `claim_risk` (seberapa marketing-heavy dan sulit diverifikasi)

Failure policy intake:
- jika source tidak bisa diakses/kurang data, minta tepat 1 klarifikasi atau 1 sumber pengganti
- jika constraint antar source konflik, laporkan konflik dan stop rekomendasi final sampai jelas
- jika source claim tinggi tapi evidence rendah, tandai `confidence: low` dan wajib minta benchmark lokal sebelum adopsi permanen

Claim-heavy adoption gate:
- untuk klaim produktivitas besar, status adopsi permanen harus `pending_benchmark` sampai ada hasil benchmark lokal.

Observability-first adoption:
- jika perubahan mengklaim peningkatan kualitas/biaya/latensi, simpan baseline before/after
- tanpa baseline lokal, status tetap `pending_benchmark`

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
- `action` (`enrich` | `merge` | `create` | `create_tool` | `drop`)

## Multi-Skill Upgrade Mode

Untuk setiap unit ilmu:
1. Map ke skill target yang paling cocok (boleh lebih dari satu target).
2. Putuskan tindakan:
- `enrich`: tambah section/aturan baru ke skill existing.
- `merge`: gabung dua/lebih skill overlap lalu pilih canonical.
- `create`: buat skill baru hanya jika tidak ada owner yang cocok.
3. Lakukan patch lintas beberapa skill dalam satu siklus evolve.

## Tool+Skill Co-Creation Mode

Gunakan mode ini jika source menunjukkan workflow yang lebih andal bila dijadikan tool:
1. Deteksi kandidat tool:
- langkah berulang dan deterministik
- validasi yang harus konsisten lintas eksekusi
- proses parse/transform yang riskan jika manual
2. Putuskan surface:
- `skill-only` jika instruksi cukup
- `tool+skill` jika reliability jauh lebih baik
- untuk task non-trivial, keputusan surface wajib melewati `think` gate
3. Implementasi tool minimal:
- letakkan di `scripts/` milik skill domain terkait
- definisikan input/output contract yang jelas
- sediakan error output yang operasional
4. Update skill pemakai tool:
- kapan tool dipakai
- fallback manual saat tool gagal
- langkah verifikasi hasil tool
5. Hindari over-engineering:
- jangan buat tool jika manfaatnya kecil atau one-off

Minimal scaffold-first rule:
1. mulai dari versi tool paling kecil yang bisa diverifikasi
2. buktikan manfaat pada satu workflow nyata dulu
3. baru perluas fitur jika evidence menunjukkan kebutuhan berulang

Capability-contract rule (untuk `create_tool`):
1. definisikan `capability_name` yang jelas
2. definisikan `input_contract` minimal
3. definisikan `output_contract` minimal
4. definisikan `owner_skill` yang memakai capability tersebut

Jika salah satu tidak jelas:
- turunkan aksi ke `enrich` dulu
- jangan langsung `create_tool`

Decision bias:
- utamakan komposisi pada framework/surface yang sudah maintainable
- hindari fork atau duplicate orchestration logic jika extension/middleware cukup

Untuk tool dengan klaim efisiensi besar (mis. token reduction):
- wajib benchmark lokal baseline vs sesudah install
- adopsi permanen hanya jika kualitas output tidak turun

## Pattern Frequency Decision Gate

Saat menentukan `enrich` vs `create`:
1. hitung frekuensi pola serupa dari source + memory (`repeat_count`)
2. jika pola berulang tinggi dan belum punya owner jelas -> pertimbangkan `create`/`create_tool`
3. jika pola berulang rendah atau sudah ada owner kuat -> `enrich` skill existing
4. catat keputusan dalam output audit:
- `repeat_count`
- `owner_skill`
- `decision_rationale`

## Skill-Creator Compliance Gate (Wajib untuk merge/create)

Semua aksi `merge`, `create`, dan `create_tool` harus mengikuti standar `skill-creator`.

### Naming Standard
- Skill baru wajib hyphen-case: lowercase, digit, hyphen (contoh: `typescript-inject`).
- Hindari underscore untuk skill baru.
- Folder skill harus sama persis dengan nama skill.

### Struktur Minimum Skill
- Wajib ada:
  - `SKILL.md` (frontmatter `name` + `description`)
  - `agents/openai.yaml` (disarankan, dan diperlakukan wajib di workspace ini)
- Jika butuh otomasi:
  - `scripts/` untuk tool deterministik
- Jangan buat file dokumentasi tambahan yang tidak perlu (`README.md`, `CHANGELOG.md`, dll) di dalam folder skill.

### Merge Protocol
Saat `merge`:
1. pilih canonical owner skill
2. pindahkan insight unik ke canonical
3. hapus duplikasi coverage
4. update referensi/routing ke canonical
5. validasi hasil merge tidak menurunkan coverage kritis

### Metadata and Interface Sync
- Setelah edit SKILL, sinkronkan `agents/openai.yaml` agar:
  - `display_name` jelas
  - `short_description` sesuai trigger aktual
  - `default_prompt` mencerminkan use case utama

### Validation Gate (Hard Stop)
- Wajib jalankan validator skill untuk setiap skill yang dibuat/diubah:
```bash
python3 /home/raymond/.codex/skills/.system/skill-creator/scripts/quick_validate.py <path-skill>
```
- Jika validator gagal:
  - stop finalize
  - perbaiki sampai valid, atau laporkan blocker ke user

### Plan Sync Gate
- Jika terjadi create/merge/drop skill, update `plan.md` agar inventory tetap akurat.
- Jangan tinggalkan mismatch antara jumlah skill aktual vs daftar di plan.

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

## Memory-Merge Evolve Mode

Saat source membahas memory consolidation:
1. ekstrak aturan merge memory dan dedup
2. map ke skill canonical owner (`checkpoint`) lebih dulu
3. sinkronkan implikasi operasional ke `setup` dan routing/upgrade policy terkait
4. pastikan output evolve mencatat anti-knowledge-loss gate

## Memory Saturation Mode (Wajib saat memory terlalu panjang)

Gunakan mode ini ketika:
- user eksplisit minta "serap semua pembelajaran memory", atau
- isi `.codex/memory` sudah panjang/noisy dan sulit dipakai operasional.

Langkah eksekusi:
1. Intake semua file memory:
- baca seluruh `.codex/memory/*.md` (bukan hanya `MEMORY.md`)
2. Ekstrak unit ilmu reusable:
- ambil rule, guardrail, failure pattern, dan workflow yang bisa dipindah ke skill
3. Distribusi ke skill target:
- lakukan enrich lintas skill sesuai domain (`setup`, `smart-plan`, `debug-n-check`, `review`, dst)
4. Cleanup memory setelah ilmu terserap:
- hapus poin detail yang sudah diserap ke skill
- rapikan `.codex/memory/MEMORY.md` menjadi ringkas dan operasional
- hapus file memory tambahan yang isinya sudah sepenuhnya terserap
5. Update long-term memory:
- perbarui `.codex/long_term_memory` hanya dengan informasi umum (prinsip stabil, konteks jangka panjang, bukan detail eksekusi harian)

Integrasi dengan `web-search`:
- perlakukan hasil `web_search_context` di `MEMORY.md` sebagai kandidat utama sub-skill baru
- saat pola berulang terdeteksi, evolve boleh membuat sub-skill/tool baru dari konteks tersebut

Integrasi dengan `think`:
- prioritaskan intake section `think_lessons` di `MEMORY.md` untuk mendeteksi gap reasoning berulang
- map `think_lessons` ke enrich skill yang relevan (`think`, `web-search`, `smart-plan`, `checkpoint`)
- setelah insight terserap ke skill, ringkas ulang memory agar hanya menyisakan rule umum

Integrasi continuous-learning loop:
- treat output pattern extraction berkala sebagai input evolve periodik
- enrich skill canonical dari pattern berulang sebelum membuat surface baru

Guardrail:
- cleanup memory bersifat destruktif ringan, jadi tetap wajib approval user sebelum eksekusi
- jangan hapus insight yang belum benar-benar dipindahkan ke skill/long-term memory
- semua perubahan memory harus bisa diaudit dari laporan evolve

### Canonical Owner Preference
Saat domain bersifat sempit dan sangat operasional, prefer:
- 1 skill canonical owner yang end-to-end
- skill lain hanya sebagai support/referral, bukan duplikasi coverage

Gunakan rule ini untuk menekan overlap dan noise saat proses evolve.

### Alias Hygiene Policy
- Nama canonical skill harus menjadi owner utama.
- Alias/deprecated skill hanya boleh dipertahankan sebagai compat shim.
- Saat merge/enrich, pindahkan isi bernilai ke canonical dan kurangi ketergantungan pada alias.
- Jangan membuat skill baru dengan nama alias atau pola legacy.

### Deprecation Migration Discipline
- Jika source menandai surface deprecated, evolve wajib:
  1. menetapkan pengganti canonical
  2. menandai surface lama sebagai `compat_only`
  3. menambahkan migration note singkat di output audit
- Jangan merekomendasikan surface deprecated sebagai default lane baru.

### Skills-First Compatibility Rule
- Tetapkan `skills/` sebagai workflow surface utama.
- Pertahankan command lama hanya sebagai shim kompatibilitas jika masih dibutuhkan.
- Saat migrate, pindahkan logic utama ke skill lebih dulu, lalu tipiskan shim secara bertahap.

### Surface Consistency Audit
Setiap siklus evolve wajib cek konsistensi metadata lintas surface:
- README/docs
- manifest/plugin metadata
- marketplace listing

Jika ada mismatch, output harus memuat:
- field yang drift
- canonical source of truth
- rencana sinkronisasi minimal

### Mandatory Sync Checklist
Setelah patch evolve dieksekusi, wajib cek:
- versi/metadata plugin atau skill yang berubah
- referensi README/docs/reference tetap sinkron
- command install dan nama plugin/skill konsisten lintas surface
- sinkronisasi AGENTS.md untuk rule operasional baru yang harus persist lintas session
- cek contract drift antara skill behavior baru vs instruksi AGENTS.md

## Decision Flow

1. User kasih repo/link -> jalankan source intake.
2. Jalankan `think` gate (judgment -> decision) untuk memastikan scope dan action set tepat.
3. Pecah menjadi unit ilmu + scoring.
4. Distribusikan ke beberapa skill target (multi-upgrade) sebagai **usulan**.
5. Susun proposal final + minta approval user.
6. Setelah approve, baru eksekusi perubahan.
7. Update registry/status (`plan.md`) dan lapor impact.

Untuk mode `tool+skill`:
1. rekomendasikan tool yang akan dibuat + skill owner
2. minta approval user
3. buat tool + patch skill yang memakainya
4. validasi tool berjalan
5. laporkan dampak ke workflow agentic engineering

Untuk `Memory Saturation Mode`:
1. Intake `.codex/memory/*.md`
2. Ekstrak unit ilmu + proposal enrich skill (prioritaskan `think_lessons` + `web_search_context`)
3. Minta approval user
4. Eksekusi enrich skill
5. Bersihkan `.codex/memory` dan update `.codex/long_term_memory`
6. Laporkan delta memory sebelum/sesudah + file yang dihapus/diringkas

## Output Wajib

- daftar unit ilmu yang diekstrak
- mapping `unit ilmu -> skill target -> action (enrich/merge/create/create_tool)`
- daftar skill yang dipertahankan vs dihapus (dengan alasan)
- file yang diubah
- ringkasan dampak kualitas skill set setelah evolve
- `source_quality_score` per source utama
- status benchmark lokal (`pass|fail|skipped`) untuk source yang claim-heavy

Untuk aksi `merge/create/create_tool`, wajib tambah:
- status compliance `skill-creator` (pass/fail)
- hasil quick-validate per skill yang terdampak
- sinkronisasi `plan.md` (ya/tidak + alasan)

Jika ada `create_tool`, wajib tambah:
- daftar tool/script baru
- path file tool
- input/output contract singkat
- skill yang memakai tool tersebut

Jika memakai `Memory Saturation Mode`, wajib tambah:
- daftar file memory yang diintake
- daftar poin memory yang diserap ke skill
- daftar poin/file memory yang dihapus setelah terserap
- ringkasan isi umum yang dipertahankan di `.codex/long_term_memory`
- daftar kandidat sub-skill baru yang berasal dari `web_search_context`

## Format Audit Ilmu (Wajib)

Gunakan struktur output ini agar audit mudah dan konsisten:

```text
ilmu yang di ekstrak:
1. <unit_name>
source_link: <path/link sumber>
confidence: <high|medium|low>
REKOMENDASI EVOLVE:
- <skill-target-1>
purpose skill lama:
apa yang ditambahkan:
apa yang di gantikan:
- <skill-target-2>
purpose skill lama:
apa yang ditambahkan:
apa yang di gantikan:
- <skill-target-3>
purpose skill lama:
apa yang ditambahkan:
apa yang di gantikan:
2. <unit_name berikutnya>
...
```

Aturan:
- Jangan ubah urutan field.
- Untuk setiap skill target, wajib isi tiga field:
  - `purpose skill lama`
  - `apa yang ditambahkan`
  - `apa yang di gantikan`
- Jika tidak ada yang digantikan, tulis `tidak ada`.

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
- Target skill: `intelect-inject` (child: `typescript-inject`), `review`, `debug-n-check`.
- Action default: `enrich`.

### Source B
- `https://skills.sh/obra/superpowers/brainstorming`
- Ilmu utama: design-first brainstorming gate (one-question-at-a-time, 2-3 approaches, approval before implementation).
- Target skill: `smart-plan`, `skill-router`.
- Action default: `enrich`.

### Source C
- Source memuat workflow teknis berulang dan deterministik.
- Ilmu utama: otomasi lebih aman sebagai tool.
- Target: skill domain terkait + tool di `scripts/`.
- Action default: `create_tool` + `enrich`.
