---
name: anti-hallucination-suite
description: >
  Orchestrates anti-hallucination workflow using grounding, citation,
  cross-checking, confidence scoring, uncertainty detection, and final audit.
---

# Anti-Hallucination Suite

## Trigger
- High-stakes explanation or recommendation
- Code-review findings and root-cause claims
- User asks for high accuracy / no guessing

## Execution Order
1. `context-grounding`
2. `source-verifier`
3. `citation-enforcer`
4. `cross-checker`
5. `confidence-scorer`
6. `uncertainty-detector`
7. `output-auditor`
8. `answer-analyzer` (critical responses only)

## Output Contract
- Verified claims with citations
- Unverified items explicitly flagged
- Confidence score per major claim
- Final verdict: `SAFE TO DELIVER` or `NEEDS REVISION`
