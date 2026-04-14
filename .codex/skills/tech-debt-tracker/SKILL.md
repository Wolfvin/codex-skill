---
name: tech-debt-tracker
description: >
  Use to identify, score, and prioritize technical debt with clear remediation
  sequencing and business impact framing.
---

# Tech Debt Tracker

## Debt Types

- Code quality debt
- Architecture/coupling debt
- Test coverage debt
- Dependency/security debt
- Documentation/operational debt

## Workflow

1. Inventory
- Find debt signals (`TODO/HACK`, stale deps, flaky tests, duplicated logic).

2. Score each item
- Impact, frequency, risk, and effort.

3. Prioritize
- High impact + low/medium effort first.

4. Plan
- Convert top debt items into executable fix slices.

5. Track
- Record baseline and delta after remediation.

## Output

- Top debt list with severity
- Remediation plan by sprint-sized chunks
- Risks if postponed
