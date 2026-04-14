---
name: agentic-hub
description: >
  Use when user wants one CLI for bootstrap, repo intake, connector (MCP)
  management, and plugin notes via .codex/tools/agentic-hub.sh.
---

# Agentic Hub

## Trigger
- User asks for a single CLI to run agent workflow
- User asks to add/list connector or plugin references
- User asks to simplify setup + intake + config operations

## Commands

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
bash .codex/tools/agentic-hub.sh plugin import-openclaw <openclaw.plugin.json>
bash .codex/tools/agentic-hub.sh plugin recommend buildwithclaude
bash .codex/tools/agentic-hub.sh plugin recommend ariff
bash .codex/tools/agentic-hub.sh plugin note <name> <source>
bash .codex/tools/agentic-hub.sh checkpoint --goal "<...>" --done "<...>" --next "<...>" --blockers "<...>"
```

## Output
- Unified command center for day-to-day agent operations
- Consistent MCP connector updates in `.vscode/mcp.json`
- Persistent plugin/connector notes in `.codex/memory/plugins_connectors.md`
- OpenClaw/Claude plugin profile snapshots in `.codex/memory/plugin_profiles/`
