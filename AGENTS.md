# Custom Instructions (skills_and_mcp)

## Purpose
This workspace is for improving Codex’s agentic workflow, skills, and MCP tooling. Optimize for autonomy and reuse across sessions.

## Operating Rules
- Read `.codex/memory/MEMORY.md` first. Use it as the only memory source.
- Pick the right skill(s) automatically; run `skill-router` + `think` as default gate for non-trivial tasks.
- For external context gaps, call `$web-search` by default with efficient escalation:
  - start `mode=quick` + `backend=native_search`
  - escalate to `metasearch_backend` only if evidence is insufficient
  - use `deep_research_orchestrator` only for high-risk/high-complexity tasks
- Prefer minimal, direct changes that map to the user request.
- Avoid speculative additions; no bulk imports unless asked.
- Chunk complex work into small executable slices for faster responses and lower token usage.

## Memory Policy (Strict)
- Single-file memory only: `.codex/memory/MEMORY.md`.
- Do not create archives or extra memory files unless explicitly asked.
- If extra memory files exist, merge critical points into `MEMORY.md` and delete the rest.

## Repo Intake Policy
- When given a repo URL, use the `repo-intake` skill.
- Clone into `.tmp/repo-intake/`, extract high-signal practices into `.codex`, then delete the clone.

## MCP / Plugins
- Use `.codex/tools/agentic-hub.sh` for MCP presets and plugin notes.
- Keep MCP config under `.vscode/mcp.json` updated via the hub.
- Minimize active MCP servers per task phase; keep only relevant servers/tools enabled.

## Session Hygiene
- 1 thread = 1 phase. Use `/new` or `/fork` when switching major topics.
- Run `/compact` proactively after major phases (investigate, implement, verify), not only when context is near limit.
- Use `/status` to monitor context pressure before starting large next steps.
- Save a short handoff to `.codex/memory/MEMORY.md` before thread switches.

## Output Discipline
- Be concise and actionable.
- Use absolute file links for references (e.g. `/home/raymond/...`).
- If blocked, state the blocker and the minimum next step.

## Environment Prelaunch
- Before long execution, verify runtime/deps/env vars are ready to avoid probing tokens.
- Prefer `setup`/`command-center` preflight path before heavy implementation sessions.

## Shell Usage
- Prefer `git status --short` over default `git status`.
- Prefer `ls` over `ls -la` unless permission/detail is required.
- Pipe long output via `head`, `tail`, or targeted filters.
