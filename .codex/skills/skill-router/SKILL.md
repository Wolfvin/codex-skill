---
name: skill-router
description: Unified routing and skill discovery workflow. Use when user prompt is ambiguous/non-specific, when multiple skills may apply, or when user needs to find/install/manage skills. This router can select one or many skills depending on complexity (especially when smart-plan indicates multi-phase work).
---

# Skill Router

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
