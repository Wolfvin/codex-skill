# Skill Merge Plan

## Tujuan
Menyederhanakan daftar skill `.codex/skills` dengan mengurangi overlap tanpa menghilangkan kemampuan utama.

## Kandidat Merge (Prioritas Tinggi)

### 1) Verification Suite (gabung jadi satu skill canonical)
Gabungkan skill berikut ke dalam `anti-hallucination-suite`:
- `anti-hallucination`
- `context-grounding`
- `cross-checker`
- `source-verifier`
- `citation-enforcer`
- `confidence-scorer`
- `uncertainty-detector`
- `output-auditor`
- `truth-finder`
- `answer-analyzer`

Alasan:
- Semuanya berada di alur verifikasi klaim/evidence.
- Saat ini fungsi tersebar dan memicu kebingungan routing.

Target:
- `anti-hallucination-suite` menjadi entrypoint tunggal.
- Skill lain di atas menjadi alias/deprecated wrapper atau dihapus bertahap.

### 2) Command Center CLI (gabung jadi satu skill canonical)
Gabungkan:
- `agentic-cli`
- `agentic-hub`

Alasan:
- Deskripsi dan trigger hampir identik.
- Sama-sama berpusat pada `.codex/tools/agentic-hub.sh`.

Target:
- `agentic-hub` jadi skill canonical.
- `agentic-cli` menjadi alias tipis (redirect docs + trigger).

### 3) Workflow Delivery (gabung mode)
Gabungkan:
- `delivery-pipeline`
- `spec-driven-workflow`
- `structured-rpi`

Alasan:
- Ketiganya workflow bertahap/gated.
- Overlap pada phase planning, approvals, dan execution gates.

Target:
- Satu skill workflow dengan mode:
  - `spec`
  - `rpi`
  - `delivery`

### 4) Intake + Onboarding (family tunggal)
Gabungkan:
- `repo-intake`
- `codebase-onboarding`

Alasan:
- Keduanya fase awal pemahaman codebase.
- Bisa dipisah sebagai submode: external intake vs internal onboarding.

## Skill yang Sebaiknya Tetap Terpisah
- `mcp-manager` vs `mcp-server-builder` (ops vs engineering)
- `skills-search` vs `official-skill-sync` vs `cc-plugins-ops` (domain berbeda)
- `debug-tauri`, `frontend-design`, `code-simplifier` (use case khusus)

## Strategi Eksekusi Merge
1. Tetapkan skill canonical per grup (tidak rename dulu).
2. Ubah skill non-canonical menjadi alias:
   - Header jelas: `Deprecated alias -> use <canonical>`.
   - Pertahankan backward compatibility trigger.
3. Update semua referensi di:
   - `.codex/README.md`
   - `.codex/AGENTS.md`
   - skill docs yang saling mereferensikan.
4. Setelah stabil, hapus alias yang sudah tidak dipakai.

## Master Plan Sekali Jalan (Grouped by Tipe)

Tujuan section ini: eksekusi semua titik merge dalam 1 run, bukan per tahap terpisah.

### A. Tipe Verification (Quality/Evidence)
Canonical: `anti-hallucination-suite`

Merge map:
- `anti-hallucination` -> alias ke `anti-hallucination-suite`
- `context-grounding` -> alias ke `anti-hallucination-suite`
- `cross-checker` -> alias ke `anti-hallucination-suite`
- `source-verifier` -> alias ke `anti-hallucination-suite`
- `citation-enforcer` -> alias ke `anti-hallucination-suite`
- `confidence-scorer` -> alias ke `anti-hallucination-suite`
- `uncertainty-detector` -> alias ke `anti-hallucination-suite`
- `output-auditor` -> alias ke `anti-hallucination-suite`
- `truth-finder` -> alias ke `anti-hallucination-suite`
- `answer-analyzer` -> alias ke `anti-hallucination-suite`

Checklist implementasi:
- Update front-matter + trigger di semua skill non-canonical.
- Tambah "Mode internal" di `anti-hallucination-suite` agar cakup semua fungsi turunan.
- Verifikasi tidak ada instruksi kontradiktif antar skill verifikasi.

### B. Tipe Command Center (Orchestrator CLI)
Canonical: `agentic-hub`

Merge map:
- `agentic-cli` -> alias ke `agentic-hub`

Checklist implementasi:
- Samakan trigger dan scope ke command center tunggal.
- Pastikan docs/contoh command hanya menonjolkan `agentic-hub`.
- Sisakan `agentic-cli` sebagai compatibility alias tipis.

### C. Tipe Delivery Workflow (Planning/Gated Execution)
Canonical: `delivery-pipeline` (mode: `spec`, `rpi`, `delivery`)

Merge map:
- `spec-driven-workflow` -> alias/mode `spec` di `delivery-pipeline`
- `structured-rpi` -> alias/mode `rpi` di `delivery-pipeline`

Checklist implementasi:
- Definisikan mode selection rule di skill canonical.
- Migrasikan acceptance criteria dan gate definitions ke canonical.
- Pastikan output format tetap kompatibel dengan flow lama.

### D. Tipe Intake & Onboarding (Discovery)
Canonical: `repo-intake` (submode: `external-intake`, `internal-onboarding`)

Merge map:
- `codebase-onboarding` -> alias/mode `internal-onboarding` di `repo-intake`

Checklist implementasi:
- Satukan langkah discovery, architecture map, dan intake evidence.
- Bedakan jelas jalur "repo eksternal" vs "repo saat ini".

## Urutan Eksekusi 1x Run
1. Freeze canonical map (A-D) dan kunci naming final.
2. Implement alias wrapper di semua non-canonical skill.
3. Enrich canonical skills (mode/submode) agar fitur tidak hilang.
4. Update seluruh referensi lintas dokumen (`README`, `AGENTS`, skill refs).
5. Jalankan audit konsistensi trigger + deskripsi + output format.
6. Tandai skill non-canonical sebagai `deprecated alias`.
7. Final check: satu domain = satu entrypoint canonical.

## Deliverables Sekali Jalan
- Canonical map final untuk semua tipe merge.
- Semua skill non-canonical sudah jadi alias/deprecated wrapper.
- Semua referensi dokumen sudah menunjuk canonical.
- Checklist verifikasi lulus tanpa konflik instruksi.

## Execution Status
- [x] A. Verification merged ke `anti-hallucination-suite` + alias wrappers.
- [x] B. Command center merged ke `agentic-hub` + `agentic-cli` alias.
- [x] C. Workflow merged ke `delivery-pipeline` + mode (`spec`, `rpi`).
- [x] D. Intake/onboarding merged ke `repo-intake` + `codebase-onboarding` alias.
- [x] Navigation map dan README diperbarui ke canonical entrypoint.

## Definition of Done
- Jumlah skill berkurang tanpa kehilangan fitur.
- Routing intent lebih konsisten.
- Tidak ada referensi dokumen yang broken.
- Pengguna cukup memilih 1 skill canonical per domain.
