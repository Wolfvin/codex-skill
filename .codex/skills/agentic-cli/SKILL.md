---
name: agentic-cli
description: >
  Use to orchestrate intake, bootstrap, MCP connectors, and plugin notes from
  one command family via .codex/tools/agentic-hub.sh.
---

# Agentic CLI

## Trigger
- User wants a single command center for agent workflow
- User wants intake + MCP connector management + bootstrap automation
- User asks about plugin/connector convenience

## Main Command

```bash
bash .codex/tools/agentic-hub.sh doctor
bash .codex/tools/agentic-hub.sh intake <repo-url|local-path> [repo-url|local-path ...]
bash .codex/tools/agentic-hub.sh mcp list
bash .codex/tools/agentic-hub.sh connector add-http <name> <url>
bash .codex/tools/agentic-hub.sh connector add-stdio <name> <command> [arg ...]
bash .codex/tools/agentic-hub.sh plugin note <name> <source>
```

## Legacy Intake CLI (Still Supported)

```bash
bash .codex/tools/agentic-cli.sh sync .tmp/repo-intake/reports
```

## Output
- Summary + synthesis markdown files
- MCP connector updates in `.vscode/mcp.json`
- Plugin references in `.codex/memory/plugins_connectors.md`
