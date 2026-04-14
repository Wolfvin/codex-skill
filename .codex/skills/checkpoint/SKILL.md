---
name: checkpoint
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
