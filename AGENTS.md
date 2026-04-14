# Custom Instructions (skills_and_mcp)

## Purpose
This workspace is for improving Codex’s agentic workflow, skills, and MCP tooling. Optimize for autonomy and reuse across sessions.

## Operating Rules
- Read `.codex/memory/MEMORY.md` first. Use it as the only memory source.
- Pick the right skill(s) automatically; use `skill-router` when in doubt.
- Prefer minimal, direct changes that map to the user request.
- Avoid speculative additions; no bulk imports unless asked.

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

## Output Discipline
- Be concise and actionable.
- Use absolute file links for references (e.g. `/home/raymond/...`).
- If blocked, state the blocker and the minimum next step.
