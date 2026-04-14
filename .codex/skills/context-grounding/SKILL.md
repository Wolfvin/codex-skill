---
name: context-grounding
description: >
  Grounds statements in directly read code context. Read first, claim after.
---

# Context Grounding

## Sequence
1. Read source
2. Extract relevant line evidence
3. Make claim with citation

## Large File Rule
- >100 lines: focus section + local re-read
- >500 lines: locate with grep first, then read local block
