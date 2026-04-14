---
name: anti-hallucination
description: >
  Verification-first response protocol. Use when accuracy is critical and every
  claim must be grounded before delivery.
---

# Anti-Hallucination

## Rules
- Verify before claiming.
- Cite before asserting.
- If unverified, label as uncertainty.

## Verification Hierarchy
1. Direct read evidence (`Read`)
2. Search evidence (`Grep`/`Glob`)
3. Tool output evidence (test/build/bash output)
4. Inference (must be explicitly labeled)

## Required Output Sections
- Verified facts
- Inferences
- Unverified/unknown

## Ban List
- Invented file paths
- Assumed function signatures
- Version claims from memory
- Confident language without evidence
