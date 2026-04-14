---
name: truth-finder
description: >
  Agent-style verification workflow for checking whether technical claims are
  true against code, docs, config, and git history.
---

# Truth Finder

## For each claim
- Identify claim type (file/function/behavior/dependency/history/config)
- Verify using tools
- Return verdict: VERIFIED | FALSE | UNVERIFIABLE | OUTDATED
- Provide correction for FALSE claims

## Required Evidence
At least one direct source reference per verdict.
