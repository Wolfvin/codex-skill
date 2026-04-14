---
name: delivery-pipeline
description: >
  Use for end-to-end delivery pipeline: spec, implementation, findings closure,
  and release readiness gates. Curated from buildwithclaude high-signal workflow.
---

# Delivery Pipeline

## Trigger
- User asks to build a feature end-to-end.
- Work needs explicit gates before release.
- You need consistent handoff from design to implementation to QA.

## Pipeline

1. Feature Spec Gate
- Define scope, acceptance criteria, dependencies, and risks.
- Stop if requirements are ambiguous.

2. Implementation Gate
- Implement from approved spec only.
- Add tests for critical paths and edge cases.

3. Findings Closure Gate
- Fix review findings in priority order: Critical then Warning.
- Add/adjust tests per finding.

4. Release Readiness Gate
- Validate docs/changelog impact.
- Validate test + lint + build status.
- Validate security and operational risks.
- Final verdict: `READY` or `BLOCKED` with concrete blockers.

## Output Contract
Always return:
- Current gate
- Files changed
- Verification evidence
- Remaining blockers

## Constraints
- No scope creep beyond approved spec.
- No release recommendation without verification evidence.
- Keep edits surgical and traceable.
