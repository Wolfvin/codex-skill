---
name: command-center
description: Unified command-center workflow for bootstrap, repo intake, MCP connector operations, and plugin notes via .codex/tools/agentic-hub.sh. Use when the user wants one CLI entrypoint for day-to-day agent operations. Trigger for prompts like "single command center", "agentic cli", "agentic hub", "bootstrap + intake", and "manage connectors/plugins".
---

# Command Center

Skill gabungan dari `agentic-cli` dan `agentic-hub`.

## Merged Sources
- `agentic-cli`
- `agentic-hub`

## Trigger

- User ingin satu command center untuk workflow harian.
- User minta bootstrap + intake + connector management sekaligus.
- User minta manajemen plugin/connector yang konsisten.

## Primary Commands

```bash
bash .codex/tools/agentic-hub.sh doctor
bash .codex/tools/agentic-hub.sh bootstrap
bash .codex/tools/agentic-hub.sh intake <repo-url|local-path> [repo-url|local-path ...]
bash .codex/tools/agentic-hub.sh sync
bash .codex/tools/agentic-hub.sh skill suggest <prompt text>
bash .codex/tools/agentic-hub.sh skill list [category]
bash .codex/tools/agentic-hub.sh mcp list
bash .codex/tools/agentic-hub.sh connector add-http <name> <url>
bash .codex/tools/agentic-hub.sh connector add-stdio <name> <command> [arg ...]
bash .codex/tools/agentic-hub.sh connector preset claude-core
bash .codex/tools/agentic-hub.sh plugin note <name> <source>
```

## Legacy Support

```bash
bash .codex/tools/agentic-cli.sh sync .tmp/repo-intake/reports
```

## Output

- Operasi agent tersentralisasi lewat satu command family.
- Update connector konsisten di `.vscode/mcp.json`.
- Catatan plugin/connector tersimpan di memori project.

## Advanced Runtime Ops (absorbed from `agent-runtime-advanced`)
- Gunakan checkpoint command untuk session recovery:
  - `bash .codex/tools/agentic-hub.sh checkpoint --goal "<...>" --done "<...>" --next "<...>" --blockers "<...>"`
- Untuk pekerjaan panjang, ringkas context ke memory secara periodik (compaction).
