# 0002. Models propose, deterministic programs decide

**Status:** Accepted, 2026-11-05

## Context

The first design used six model-driven agents, including a model verifier and a model scheduler. Judgment by model is the weakest link in an evaluation system, because it cannot be audited and it can share blind spots with the model that proposed the change.

## Decision

Models generate candidate tests, refinements, forecasts, attacks, and translations. Only deterministic programs decide what is kept: compilers, repository tests, a hidden test set, hardened tests, sanitizers, fuzzers, differential execution, and proper scoring rules. Scheduling is an algorithm, not a model.

## Consequences

- Every recorded result can be rerun and checked without trusting any model.
- Saturation is bounded by oracle strength, so `harden` must grow the oracle before `saturate` runs.
- The adversary is paid only for unambiguous failures, since a model-written failing test proves nothing on its own.
