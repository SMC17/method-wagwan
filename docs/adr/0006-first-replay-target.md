# 0006. Replay zig-h3 first, and treat a self-maintained target as a known bias

**Status:** Superseded by 0007, 2026-11-12

**Decision issue:** #13

## Context

Phase one replays exactly one Zig repository whose maintainer has opted in and whose policy accepts AI-assisted work. The candidate needs enough history to split around a model training cutoff, a test suite strong enough to act as an oracle, and a maintainer who will answer within days.

Candidates measured on 2026-11-12 (commit counts from the default branch):

| Repository | License | Commits | First commit | Test oracle | AI policy |
|---|---|---|---|---|---|
| SMC17/zig-h3 | AGPL-3.0 (+ vendored libh3 Apache-2.0) | 52 | 2026-05-13 | 211 tests, cross-validated against libh3 v4.1.0, property trials across 16 resolutions; passes from a clean clone on Zig 0.16.0 | Same maintainer; accepts AI-assisted work |
| SMC17/logic-zig | Apache-2.0 | 57 | 2026-07-17 | CDCL / BMC / DRAT with proof checking | Same maintainer |
| SMC17/mast | AGPL-3.0 | 65 | 2026-05-13 | 180 tests (local) | Same maintainer |
| SMC17/tokenizers-zig | AGPL-3.0 | 51 | 2026-05-21 | 191 tests, 29 skip without model files | Same maintainer |
| An outside Zig project | varies | hundreds to thousands | varies | varies | Must be confirmed with its maintainer |

## Decision

Phase one replays SMC17/zig-h3. The maintainer of zig-h3 is the maintainer of this project and agrees. Before Phase one results are published, at least one outside Zig repository with a longer history is opted in for a confirmation run.

## Reasons

- zig-h3 has the strongest external oracle of the candidates: every function is checked against an independent C implementation, so "behaviour preserved" is decided by a program, as ADR 0002 requires.
- It builds and tests from a clean clone on the pinned toolchain today, which is the precondition for deterministic checkout in #17.
- It is public, so every replayed commit and every finding can be checked by a stranger.
- logic-zig and mast have slightly longer histories but weaker independent oracles; tokenizers-zig depends on model files that are not in the repository.

## Consequences

- **Known bias.** The maintainer of the target also designed the engine. Findings the maintainer "accepts" carry less weight than an outside maintainer's acceptance. The Phase one write-up must say this plainly and report the outside confirmation run separately.
- **Short history.** 52 commits, of which 50 landed in six days (2026-05-13 to 2026-05-19) and 2 in November 2026. This limits statistical power severely. The pre-registration in #15 must state the minimum detectable effect for this sample and must not claim more.
- **Cutoff split.** Most zig-h3 history predates the cutoffs of current models, so contamination controls in #15 matter more than usual.
- Closes the selection half of #13; the outside opt-in stays open as a follow-up.

## Correction (2026-11-12)

The first version of this ADR described zig-h3's history as "52 commits over six months". Measured from the default branch: 50 commits between 2026-05-13 and 2026-05-19, then 2 commits on 2026-11-12. Commits after 2026-07-01: 2. Fix or revert commits in the whole history: about 2.

None of the other self-maintained candidates is materially better. Commits after 2026-07-01 / distinct days / fix commits: logic-zig 58 / 6 / 3, tokenizers-zig 13 / 4 / 5, faiss-zig 12 / 6 / 1, zag 39 / 4 / 1. Each was written in short agent-driven bursts.

Consequence: zig-h3 can serve as a smoke target for the replay substrate (#17) and the Zig adapter, but it cannot support a pre-registered foresight result. The headline Phase one target needs an outside Zig repository with hundreds of post-cutoff commits and a real fix history. That choice is tracked in a follow-up decision issue, and #15 must not be merged until it is made.
