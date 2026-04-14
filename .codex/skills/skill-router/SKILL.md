---
name: skill-router
description: >
  Routes user intent to the best-fit skills using a keyword catalog and
  execution priority. Use when prompt can map to multiple skills.
---

# Skill Router

## Trigger
- User prompt is broad/ambiguous.
- Multiple skills may apply.
- Need deterministic skill selection order.

## Routing Protocol

1. Parse intent from prompt.
2. Run:
```bash
bash .codex/tools/skill-navigator.sh suggest <user-prompt>
```
3. Select top 1-3 skills by relevance score.
4. Execute in this order:
- orchestration/setup first
- domain workflow second
- verification/quality last

## Guardrails
- Prefer minimal skill set that fully covers the task.
- Avoid parallel/conflicting workflows unless explicitly needed.
- If confidence is low, use `anti-hallucination-suite` for final answer quality gate.
