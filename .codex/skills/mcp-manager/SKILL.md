---
name: mcp-manager
description: >
  Use this skill when the user gives a new idea, feature request, or tool they
  want to integrate. Automatically determines if an MCP server exists for it,
  installs it, updates config.toml, and updates this skill's own knowledge.
  Triggers on: "I want to add X", "can we integrate X", "I have an idea", 
  "add support for X", "connect to X". DO NOT use for pure coding tasks.
---

# MCP Manager — Auto-integrate anything via MCP

When the user gives you an idea or tool to integrate, you:
1. Search for an existing MCP server
2. Install and configure it
3. Update `.codex/config.toml`
4. Update `.codex/memory/MEMORY.md`
5. Update this skill's own references (self-updating)

---

## Step 1 — Understand the idea

Parse what the user wants:
- What service/tool? (e.g. Supabase, GitHub, Figma, Stripe)
- What capability? (read data, write, automate, monitor)
- Is there an official MCP for it?

## Step 2 — Find the MCP server

Search in this order:
```bash
# Check official OpenAI MCP registry first
codex mcp list 2>/dev/null || true

# Search npm
npm search @modelcontextprotocol 2>/dev/null | grep -i "<TOOL_NAME>" | head -5

# Search via codex mcp add (dry run)
echo "Known sources: modelcontextprotocol.io, glama.ai/mcp, mcpservers.org"
```

Common official MCPs:
- GitHub → `@modelcontextprotocol/server-github`
- Filesystem → `@modelcontextprotocol/server-filesystem`
- Postgres → `@modelcontextprotocol/server-postgres`
- Supabase → `https://mcp.supabase.com/mcp`
- Figma → `https://mcp.figma.com/mcp`
- Playwright → `@playwright/mcp@latest`
- Tauri → `@hypothesi/tauri-mcp-server`
- Linear → via Codex plugin
- Slack → via Codex plugin
- Notion → via Codex plugin

## Step 3 — Install

```bash
# Via codex CLI (preferred)
codex mcp add <name> -- npx <package>

# Or add manually to ~/.codex/config.toml:
# [mcp_servers.<name>]
# command = "npx"
# args = ["<package>"]
```

For OAuth MCPs:
```bash
codex mcp login <name>
```

## Step 4 — Verify it works

```bash
codex mcp list
# Should show the new server as "enabled"
```

Test with a simple query using the new MCP tool.

## Step 5 — Update .codex/config.toml in project

Append to `.codex/config.toml`:
```toml
[mcp_servers.<name>]
command = "npx"
args = ["<package>", "<args>"]
# Added: [DATE] — [reason]
```

## Step 6 — Self-update this skill

Append the new MCP to the "Known MCPs" list above in this file:
```bash
# Read current SKILL.md
cat .codex/skills/mcp-manager/SKILL.md

# Append new entry to the known MCPs list
# Format: - <ServiceName> → `<package-or-url>`
```

Then update MEMORY.md:
```
## MCP Added [DATE]
- Service: [name]
- Package: [package]
- Reason: [user's idea]
- Status: ✅ working / ⚠️ needs auth
```

## Rules
- Always check if MCP already exists before installing
- Always test after install
- Always update MEMORY.md
- Always self-update the "Known MCPs" list in this SKILL.md
- If no MCP exists, suggest the best alternative (REST API wrapper, CLI tool)
- Prefer official MCPs over community ones for stability
