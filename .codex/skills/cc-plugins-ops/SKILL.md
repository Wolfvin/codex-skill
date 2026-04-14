---
name: cc-plugins-ops
description: Use when users ask about Claude Code plugins, cc-plugins marketplace, or plugin development workflow.
allowed-tools: Bash, Read
---

# cc-plugins Ops

## Scope
This skill covers the `cc-plugins` marketplace and Claude Code plugin structure/versioning rules.

## Install / Manage Plugins
When the user wants to install a plugin from `cc-plugins`:

```bash
claude plugin install <plugin>@cc-plugins
```

If `claude` CLI is missing, report the blocker and ask the user to install Claude Code first.

## Marketplace Structure (Reference)
```
cc-plugins/
├── .claude-plugin/marketplace.json
├── .claude/rules/plugin-development.md
└── plugins/
```

## Plugin Structure (Reference)
```
{plugin-name}/
├── .claude-plugin/plugin.json
├── commands/{command}.md
├── agents/{agent}.md
├── skills/{skill}/SKILL.md
├── hooks/hooks.json
├── .mcp.json
└── .lsp.json
```

## Required Versioning Rule
If plugin content changes, always bump `plugin.json` version (semantic versioning). Claude Code caches by version.

## Context Optimization
For knowledge/reference skills:
- Use `context: fork` to isolate context.
- For hidden reference skills, also set `user-invocable: false`.

## Slash Command Notes
- Commands live in `commands/*.md` and are invoked as `/plugin-name:command`.
- The `!` Bash prefix for dynamic context is valid in commands only, not in skills.

## Plugin Catalog (cc-plugins)
- agent-browser-spec: agent-browser CLI knowledge
- cf-terraforming-spec: Cloudflare cf-terraforming CLI knowledge
- claude-code-spec: Claude Code CLI knowledge
- cloudflare-knowledge: Cloudflare services + Wrangler + Workers/Pages
- codex-cli-spec: OpenAI Codex CLI knowledge
- cursor-cli-spec: Cursor IDE/CLI knowledge
- gemini-api-spec: Gemini API models/features/pricing
- gemini-cli-spec: Gemini CLI knowledge
- git-actions: Git commit/push workflow
- gogcli-spec: Google Suite CLI knowledge
- memory-optimizer: Claude Code memory management workflows
- nano-banana-image: Gemini image generation plugin
- plugin-generator: plugin scaffolding/validation
- plugin-updater: update marketplace + installed plugins
- secret-guard: block secret file access
- web-search-codex: web search via Gemini CLI in Codex CLI
- web-search-gemini: web search via Gemini CLI
- web-search-unified: parallel search aggregation
- wrangler-cli-spec: Cloudflare Wrangler CLI knowledge
