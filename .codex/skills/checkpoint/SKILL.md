---
name: checkpoint
<<<<<<< HEAD
description: Unified memory archival and rapid repository onboarding skill. Use when user asks to save learnings/context, prevent rediscovery, or quickly onboard an unfamiliar codebase into an actionable engineering map.
---

# Checkpoint

Skill gabungan dari `checkpoint` dan `codebase-onboarding`.

## Mode 1 - Memory Checkpoint

Gunakan saat user meminta simpan pembelajaran atau context persistence.

1. Scan
- Ambil insight penting dari sesi: problem, failed approaches, solusi, verifikasi.

2. Consolidate
- Gunakan single-file memory policy.
- Hindari duplikasi, simpan hanya high-signal.

3. Save
- Update memory project secara ringkas dan bisa dipakai sesi berikutnya.

4. Report
- Laporkan apa yang ditambah, diubah, dan alasan singkat.

## Mode 2 - Repo Onboarding

Gunakan saat mulai di repo yang belum dikenal.

1. Scan repo signals
- Struktur root, manifest dependency, CI/workflow, config infra.

2. Detect runtime map
- Bahasa, framework, build/test toolchain.

3. Identify execution paths
- Entry points app/API/jobs/migrations.

4. Build onboarding brief
- Cara run/test, area perubahan aman, dan risk zones.

## Output Wajib
- Jika mode checkpoint: ringkasan knowledge yang disimpan.
- Jika mode onboarding: engineering map ringkas yang langsung eksekusi.
=======
description: >
  Use this skill when user asks to save learnings, persist session context, or
  run memory archival (e.g. "checkpoint", "save what we learned", "ingat ini").
  The goal is to prevent rediscovery by updating project memory files.
---

# Checkpoint — Memory Archival for This Project

When triggered, perform complete knowledge archival into project memory.

## Target Files

- Memory index: `.codex/memory/MEMORY.md`
- Memory entries: `NONE` (single-file memory policy)

## Steps

1. **SCAN**
- Review current conversation and recent changes.
- Extract solved problems, failed approaches, user preferences, critical commands, and key config values.

2. **CHECK**
- Read `.codex/memory/MEMORY.md`.
- Detect whether a topic already exists to avoid duplicates.

3. **CONSOLIDATE (light)**
- Enforce single-file memory policy.
- Do not create new memory files.
- If old memory files exist, fold critical info into `MEMORY.md` and delete extras.

4. **SAVE OR UPDATE**
- Update `MEMORY.md` only.
- Keep entries terse and deduplicated.

5. **UPDATE INDEX**
- Keep `MEMORY.md` as hot memory only:
  - persistent directives,
  - current active stack,
  - latest high-signal changes.
- Do not create archives unless explicitly requested by the user.

6. **VERIFY & REPORT**
- Report what was saved, what was updated, and consolidation findings.

## Quality Rules

Each memory entry should include:
- Problem
- Wrong approaches
- Correct solution
- Verification

Do not save:
- Data already obvious from codebase structure alone
- Temporary noise with no long-term reuse value

## Anti-Amnesia Protocol

- Before work: read `.codex/memory/MEMORY.md` first.
- After breakthroughs: checkpoint immediately.
- Before retrying old issue: check memory before re-debugging.
- Retention policy:
  - `MEMORY.md` should stay concise (target <= 120 lines).
  - Keep at most 8 recent high-signal bullets in hot memory.
  - Archive older chronology instead of deleting it.
>>>>>>> origin/main
