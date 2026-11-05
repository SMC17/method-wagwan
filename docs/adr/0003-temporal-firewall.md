# 0003. Search signals and evaluation signals are separated in code

**Status:** Accepted, 2026-11-05

## Context

The first design rewarded the optimizer for changeability measured by the cost of absorbing future upstream commits, which is lookahead bias built into the objective. It also let distilled skills learned from later history flow into replays of earlier history.

## Decision

Every signal belongs to exactly one class. Search signals may steer agents and must be computable at the replay clock. Evaluation signals may only be read after a run is frozen. The core enforces the boundary in code. Distilled skills carry the latest commit date they learned from, and the scheduler refuses to load a skill into any replay whose clock is earlier. Headline results use only commits after the proposing model's training cutoff.

## Consequences

- Changeability steers search only through present-tense proxies such as coupling and API surface, which are validated offline against realized translation cost.
- Contamination is tested by obfuscation, and pre-cutoff and post-cutoff results are published side by side.
- Any result that cannot show it respected the firewall is not reported.
