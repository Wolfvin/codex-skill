---
name: confidence-scorer
description: >
  Adds confidence scoring (0-100) to claims so uncertainty is explicit and
  actionable.
---

# Confidence Scorer

## Scale
- 95-100: directly verified from code now
- 80-94: confirmed by search/tool outputs
- 60-79: strong inference from evidence
- 40-59: weak inference / general pattern
- 0-39: uncertain/speculative

## Threshold
- Security/prod recommendations require >= 90.
- If below threshold, mark as uncertain and propose verification step.
