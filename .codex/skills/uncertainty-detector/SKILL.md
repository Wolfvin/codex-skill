---
name: uncertainty-detector
description: >
  Detects guessing masked as certainty and rewrites output to reflect true
  confidence.
---

# Uncertainty Detector

## Trigger Signals
- "probably", "likely", "should work" without evidence
- claim about code not yet read
- claim about runtime not yet tested

## Required Rewrite
Convert uncertain certainty into:
- what is verified,
- what is not,
- next verification command.
