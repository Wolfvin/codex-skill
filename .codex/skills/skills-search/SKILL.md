---
name: skills-search
description: Use when users want to search, discover, install, or manage Claude Code skills via the CCPM registry.
allowed-tools: Bash, Read
---

# Skills Search (CCPM)

## Scope
This skill manages Claude Code skills from the CCPM registry. If the user wants Codex skills, use `official-skill-sync` instead.

## Auto-Bootstrap (Run First)
```bash
which ccpm || npx @daymade/ccpm setup
```

## Core Behavior
- Execute the appropriate `ccpm` command directly (do not ask user to copy-paste).
- If `ccpm` is missing, use `npx @daymade/ccpm` as a drop-in replacement.
- Summarize results clearly and suggest the next step.

## Intent Mapping
| User Intent | Action |
|---|---|
| "find skills for X" / "search X skills" | `ccpm search <query>` |
| "popular skills" / "top skills" | `ccpm popular` |
| "latest skills" / "what's new" | `ccpm recent` |
| "install X" / "add X skill" | `ccpm install <skill-name>` |
| "what does X do" | `ccpm info <skill-name>` |
| "list skills" | `ccpm list` |
| "remove X" | `ccpm uninstall <skill-name>` |
| "update X" | `ccpm update [name]` or `ccpm update --all` |

## Command Reference
```bash
ccpm search <query> [--limit <n>] [--tags <t1,t2>] [--author <name>] [--smart]
ccpm popular [--limit <n>]
ccpm recent [--limit <n>]
ccpm install <skill-name>
ccpm install <name> --project
ccpm install <name> --force
ccpm list
ccpm info <skill-name>
ccpm update [name]
ccpm update --all
ccpm uninstall <skill-name>
```

## Post-Install Reminder
After a successful install, always say:
"Skill installed successfully. Please restart Claude Code (or start a new conversation) for the skill to become available."

## MCP Alternative
```json
{
  "mcpServers": {
    "skill-search": {
      "command": "npx",
      "args": ["-y", "skills-search-mcp"]
    }
  }
}
```

## Troubleshooting
- `ccpm: command not found` -> use `npx @daymade/ccpm`.
- Skill not available after install -> restart Claude Code.
- Permission errors -> try `--project` scope.
