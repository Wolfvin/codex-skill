---
name: cross-checker
description: >
  Multi-angle verification skill. Validate claims from independent sources
  before acting or reporting.
---

# Cross-Checker

## Minimum Angles
- Normal code claim: 2 angles
- Security or production claim: 3 angles

## Angles
- Code (`Read`)
- Tests (`Bash` test output)
- Git history (`git log`, `git blame`)
- Docs/config/manifests

## Output
For each claim:
- Claim
- Evidence angles used
- Verdict: VERIFIED | PARTIAL | FALSE | UNVERIFIED
