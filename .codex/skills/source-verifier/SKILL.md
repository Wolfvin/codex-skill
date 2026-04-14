---
name: source-verifier
description: >
  Enforces evidence-backed statements with concrete source references for all
  technical claims.
---

# Source Verifier

## Rule
No evidence, no claim.

## Evidence Mapping
- Code claim -> file:line
- Config claim -> file + key
- Dependency claim -> manifest/lock file
- Behavior claim -> test/runtime output

## Output Contract
Every factual line must include source reference or explicit `UNVERIFIED` tag.
