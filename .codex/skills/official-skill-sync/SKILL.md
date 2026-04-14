---
name: official-skill-sync
description: >
  Use when user wants to discover, install, or refresh official curated skills
  from openai/skills for Codex without importing noisy/unrelated skill packs.
---

# Official Skill Sync (OpenAI)

## Purpose

Keep local `.codex` focused while still leveraging official curated skills from `openai/skills`.

## Source Priority

1. `openai/skills` curated list (`skills/.curated`)
2. Explicit GitHub skill path user provides
3. Existing local skills in `.codex/skills`

## Workflow

1. Discover
- List curated skills from official source.
- Mark which ones are already installed.

2. Select
- Prioritize skills that improve agentic coding quality:
  - docs accuracy
  - CI/debugging
  - review quality
  - reproducible workflows
- Skip domain bundles not relevant to current project.

3. Install/Sync
- Prefer `$skill-installer` flow for curated skills.
- For explicit GitHub path, install by URL/path.

4. Verify
- Confirm skill directory exists and has `SKILL.md`.
- Mention restart requirement when needed.

5. Record
- Update `.codex/memory/MEMORY.md` with newly added/updated skills.

## Guardrails

- Do not bulk-install all curated skills blindly.
- Keep local skill set lean and high-signal.
- If a skill overlaps heavily with existing local skill, keep one canonical owner.
