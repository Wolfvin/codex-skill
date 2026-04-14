---
name: bootstrap
description: >
  Use this skill when the user wants to set up a new project, initialize the AI
  dev environment, or when bootstrap.sh is run. Also triggers when user says
  "setup project", "init environment", "bootstrap", or "prepare this project".
  DO NOT use for general coding tasks.
---

# Bootstrap — Portable AI Dev Environment

You are setting up a self-contained, portable AI dev environment for this project.
The `.codex/` folder IS the environment. Everything needed lives here.

## What bootstrap.sh does (read it first)

Before anything else, run:
```bash
cat .codex/bootstrap.sh
```
Then execute it:
```bash
bash .codex/bootstrap.sh
```

## After bootstrap.sh finishes

### 1. Read project memory
```bash
cat .codex/memory/MEMORY.md
```
If it exists and has content, you already know this project. Skip rediscovery.
If empty or missing, proceed to step 2.

### 2. Discover the project
Scan the project structure:
```bash
find . -maxdepth 3 -not -path '*/.codex/*' -not -path '*/node_modules/*' \
  -not -path '*/.git/*' | head -60
```
Then read key files: `package.json`, `Cargo.toml`, `tauri.conf.json`, `README.md`
(whichever exist).

### 3. Read all installed skills
```bash
ls ~/.codex/skills/
ls .codex/skills/
```
Load and internalize every SKILL.md found. These are your operating procedures.

### 4. Read MCP config
```bash
cat ~/.codex/config.toml
```
Note which MCP servers are active. Use them proactively.

### 5. Update MEMORY.md
Append a bootstrap entry:
```
## Bootstrap [DATE]
- Project: [name]
- Stack: [detected stack]
- Active MCPs: [list]
- Active skills: [list]
- Notes: [anything important discovered]
```

### 6. Report to user
Tell the user:
- ✅ What was set up
- 🔧 MCPs that are active
- 📚 Skills that are loaded
- 💡 Suggested first actions

## Rules
- NEVER skip reading MEMORY.md — it contains prior work
- ALWAYS run bootstrap.sh before anything else in a fresh session
- If bootstrap.sh fails, diagnose and fix before continuing
- After any major feature, update MEMORY.md
