---
name: vibe-tauri
description: >
  Use for autonomous vibe-coding loops on Tauri apps using Playwright capture
  and iterative fix/test cycles with clear stop conditions.
---

# Vibe Coding (Playwright x Tauri x Codex)

## Trigger

- User asks to copy UI style from website into Tauri app.
- User asks for screenshot-first UI implementation loop.
- User asks "fix/test/fix sampai pass" for Tauri UI flows.

## Preconditions

1. Runtime
- `sandbox_mode = "danger-full-access"`
- `[features] js_repl = true` (for interactive browser loop)

2. Skills/Tools
- `playwright` installed
- `playwright-interactive` installed
- Tauri MCP available (`@hypothesi/tauri-mcp-server`)

3. Project readiness
- Tauri app can run locally (`npm run tauri dev` or equivalent)

## Operating Loop

1. Capture reference first
- Open target UI source and save screenshot evidence.
- Extract only high-signal visual patterns (layout, spacing, nav, cards).

2. Implement in Tauri codebase
- Apply style changes surgically in relevant UI files.
- Avoid unrelated refactors.

3. Validate with runtime evidence
- Use Tauri MCP / Playwright evidence: screenshot, DOM signal, console output.
- Compare against reference and list deltas.

4. Iterate with guardrail
- Repeat fix -> test until pass or max 5 iterations.
- If still failing after 5, escalate with blocker summary and options.

5. Cleanup
- Remove temporary screenshots/artifacts not needed for traceability.

## Output Contract

Always report:
- task goal and iteration count
- reference screenshots used
- changed files
- validation evidence (result screenshot + pass/fail status)
- remaining manual review items (if any)

## Rules

- Screenshot first, code second.
- Do not overwrite/delete user files outside requested scope.
- Keep change log traceable per iteration.
- Prefer CLI for long autonomous loops; extension for lightweight edits.
