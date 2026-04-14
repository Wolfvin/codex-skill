---
name: repo-intake
description: >
  Use when user gives a repository URL and wants extraction of actionable
  practices into local .codex, then cleanup of temporary clone.
---

# Repo Intake

## Fast Path (Recommended)

Use intake CLI first to reduce manual overhead:

```bash
bash .codex/tools/repo-intake-cli.sh <repo-url>
```

This will:
- clone repo to temporary folder,
- extract high-signal repository metadata into `.codex/memory/repo_intake_report_*.md`,
- cleanup temporary clone automatically (unless `--keep`).

## Workflow

1. Validate and clone
- Prefer CLI above. If CLI cannot be used, clone manually to temporary folder (`--depth 1`).

2. Extract
- Read README, CI, dependency manifests, agent/skill instructions, key workflows.
- For skill repositories, prioritize official sources and curated subsets over full bulk import.
- Do not import or reuse leaked/proprietary source code. Extract only legal, documented patterns.

3. Integrate
- Update `.codex/skills`, `.codex/README.md`, and `.codex/memory/*` with useful patterns only.
 - Merge any intake summary into `.codex/memory/MEMORY.md` and remove raw intake reports to keep single-file memory policy.

4. Report
- State what was imported and why it matters.
- Reference the generated intake report file when available.

5. Cleanup
- Remove temporary clone and verify deletion.

## Rule

Only keep patterns that improve agentic coding quality, velocity, and safety.
