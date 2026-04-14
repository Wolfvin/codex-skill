# Project Memory (compressed)

## Project
- Name: skills_and_mcp
- Stack: Codex skill workspace (shell, markdown, MCP, skill authoring)
- Last updated: 2026-04-14

## Directives
- Operate autonomously: pick the right skills and execute end-to-end without extra prompting.
- Keep signal high: no bulk imports, no speculative changes.
- Source hygiene: do not reuse proprietary code or leak sources.

## Active MCPs
- context7, openaiDeveloperDocs, filesystem, git, fetch, time, memory, tauri, codeReviewGraph

## Core Skills
- repo-intake, agentic-hub, skill-router, checkpoint, agent-runtime-advanced
- delivery-pipeline, tagged-work-intake, structured-rpi, anti-hallucination-suite
- skills-search, cc-plugins-ops

## Plugins + Connectors (refs only)
- openaiDeveloperDocs MCP | https://developers.openai.com/mcp
- context7 MCP | https://context7.com
- openclaw-claude-code | https://github.com/Enderfga/openclaw-claude-code
- buildwithclaude-curated | marketplace://davepoon/buildwithclaude
- ariff-anti-hallucination-suite | marketplace://a-ariff/ariff-claude-plugins
- claude-core-connectors | preset://claude-core

## Plugin Profiles (compressed)
- openclaw: local profile imported from openclaw.plugin.json (OpenClaw SDK summary)
- ariff: anti-hallucination hooks/agents mapped to local skills

## Recent High-Signal Changes
- Added connector orchestration in `agentic-hub` (claude-core preset + plugin notes).
- Curated buildwithclaude into local skills (`delivery-pipeline`, `tagged-work-intake`).
- Added skill navigation (`skill-map.tsv` + `skill-navigator.sh`).
- Added structured RPI workflow (`structured-rpi`) from claude-code-toolkit.
- Added anti-hallucination suite (truth-finder, answer-analyzer, source/citation checks).
- Added `skills-search` (CCPM registry) and `cc-plugins-ops` (Claude Code plugin marketplace ops).

## Memory Hygiene
- Single-file memory only. No archives unless explicitly requested.
- Checkpoint skill must update this file only and delete extra memory files if found.
