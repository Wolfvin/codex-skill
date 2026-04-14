---
name: spec-driven-workflow
description: >
  Use when user wants spec-first delivery: requirements, acceptance criteria,
  test mapping, and implementation gated by approved spec.
---

# Spec-Driven Workflow

## Iron Rule

No code without an approved spec.

## Required Spec Sections

1. Context
2. Functional requirements (`FR-*`, use MUST/SHOULD/MAY)
3. Non-functional requirements (`NFR-*`, measurable)
4. Acceptance criteria (`AC-*`, Given/When/Then)
5. Edge cases (`EC-*`)
6. API/data contracts
7. Out of scope

## Workflow

1. Gather requirements
- Clarify goals, constraints, and exclusions.

2. Write spec
- Number all requirements and make each testable.

3. Validate spec
- Ensure each FR has AC; each AC is measurable and unambiguous.

4. Derive tests from AC/EC
- Create failing tests/stubs first.

5. Implement incrementally
- Deliver per AC; no scope creep.

6. Self-review gate
- Confirm all AC/EC covered by passing tests.

## Escalation Rules

Pause and ask user when encountering ambiguity, breaking changes, or security-impacting behavior not covered in spec.
