---
name: tagged-work-intake
description: >
  Use when user message starts with a [] tag (e.g. [bugfix], [feature]).
  Normalizes work intake into explicit task plan + execution mode.
---

# Tagged Work Intake

## Trigger
Message begins with `[...]`, for example:
- `[feature]`
- `[bugfix]`
- `[refactor]`
- `[hotfix]`

## Behavior

1. Parse the tag into work type.
2. Create a minimal execution plan:
- objective
- constraints
- success criteria
- immediate first task
3. Choose execution mode:
- `direct` for small tasks
- `pipeline` for multi-step tasks
4. Execute and verify.

## Output Contract
- Parsed tag and work type
- Chosen mode (`direct` or `pipeline`)
- Plan steps with verification checks
