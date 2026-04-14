---
name: focused-fix
description: >
  Use for feature/module breakages that need deep end-to-end repair across
  dependencies, tests, and integration points (not tiny one-line bugfixes).
---

# Focused Fix

## Trigger

- "fitur X rusak"
- "make this module work"
- "fix this area end-to-end"

## Iron Rule

No fix before scope + trace + diagnosis complete.

## Workflow

1. Scope
- Define exact feature boundary (`path`, entry points, consumers).
- List files in scope and expected behavior.

2. Trace dependencies
- Inbound: imports, env vars, config, DB/API dependency.
- Outbound: files that depend on this feature.

3. Diagnose
- Run targeted tests and static checks.
- Capture root cause per issue (not symptom).
- Classify risk: high/medium/low.

4. Fix systematically
- Order: dependencies -> types/contracts -> logic -> tests -> integration.
- One issue at a time; verify after each change.

5. Verify
- Run all related tests and affected consumer tests.
- Summarize changed files, validated scenarios, and remaining risks.

## Escalation

Stop and ask user if fixes cascade into architectural issues (multiple new regressions after fixes).
