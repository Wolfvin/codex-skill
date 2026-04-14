---
name: skill-router
<<<<<<< HEAD
description: Unified routing and skill discovery workflow. Use when user prompt is ambiguous/non-specific, when multiple skills may apply, or when user needs to find/install/manage skills. This router can select one or many skills depending on complexity (especially when smart-plan indicates multi-phase work).
=======
description: >
  Routes user intent to the best-fit skills using a keyword catalog and
  execution priority. Use when prompt can map to multiple skills.
>>>>>>> origin/main
---

# Skill Router

<<<<<<< HEAD
Skill gabungan dari `skill-router` dan `skills-search`.

## Trigger
- Prompt user broad/ambigu.
- User tidak meminta hal spesifik.
- Perlu pilih kombinasi skill paling efektif.
- User ingin search/discover/install/manage skill.

## Routing Protocol

1. Parse intent + complexity.
2. Jika ambigu, jalankan suggestion:
```bash
bash .codex/tools/skill-navigator.sh suggest <user-prompt>
```
3. Pilih skill sesuai kebutuhan:
- sederhana: 1 skill
- menengah: 2-3 skill
- kompleks (smart-plan): bisa >3 skill bila benar-benar diperlukan
4. Urutan eksekusi:
- orchestration/setup
- domain workflow
- verification/quality

## Skills Search Mode (CCPM)

Gunakan ketika user minta cari/install/update skill:
- `ccpm search <query>`
- `ccpm info <skill-name>`
- `ccpm install <skill-name>`
- `ccpm update [name|--all]`
- `ccpm list`
- `ccpm uninstall <skill-name>`

Fallback bila `ccpm` tidak ada:
```bash
npx @daymade/ccpm <command>
```

## Guardrails
- Pakai minimal skill set yang cukup untuk task.
- Hindari workflow konflik.
- Bila confidence rendah, tambahkan quality gate via `smart-plan` verification mode.
=======
## Trigger
- User prompt is broad/ambiguous.
- Multiple skills may apply.
- Need deterministic skill selection order.

## Routing Protocol

1. Parse intent from prompt.
2. Run:
```bash
bash .codex/tools/skill-navigator.sh suggest <user-prompt>
```
3. Select top 1-3 skills by relevance score.
4. Execute in this order:
- orchestration/setup first
- domain workflow second
- verification/quality last

## Guardrails
- Prefer minimal skill set that fully covers the task.
- Avoid parallel/conflicting workflows unless explicitly needed.
- If confidence is low, use `anti-hallucination-suite` for final answer quality gate.
>>>>>>> origin/main
