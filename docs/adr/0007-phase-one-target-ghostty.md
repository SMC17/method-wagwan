# 0007. Replay Ghostty for Phase one; keep zig-h3 as the smoke target

**Status:** Accepted

**Decision issue:** #57

## Context

ADR 0006 chose zig-h3, then its correction showed only 2 zig-h3 commits after 2026-07-01, so it cannot support a pre-registered foresight result. The maintainer's other Zig repositories have the same burst-written history. Phase one needs an outside Zig repository with hundreds of commits after the proposing model's training cutoff, a real fix history for labels, and a contribution policy compatible with model-assisted work.

The Zig compiler and ZLS enforce a strict no-LLM, no-AI policy, so they are excluded both as targets and as destinations for any output of this project.

## Decision

- The Phase one headline target is **ghostty-org/ghostty** (MIT).
- **tigerbeetle/tigerbeetle** (Apache-2.0) is the confirmation target, subject to its maintainers agreeing.
- **SMC17/zig-h3** is the smoke target for the replay substrate (#17) and the Zig adapter. No foresight result is reported on it.
- No result about Ghostty or TigerBeetle is published before their maintainers have been asked, personally, by the maintainer of this repository. Replay itself only reads public history.

## Reasons

Measured 2026-11-12 through the GitHub API:

| Repository | Commits since 2026-07-01 | Matching "fix" | Matching "revert" | Policy |
|---|---:|---:|---:|---|
| ghostty-org/ghostty | 2,408 | 451 | 11 | AI_POLICY.md: AI use allowed with full disclosure; the human must understand all code |
| tigerbeetle/tigerbeetle | 573 | 66 | not measured | No policy file found |
| Vexu/arocc | 173 | 3 | not measured | Not checked |
| zigtools/zls | 106 | 19 | not measured | Strict no-LLM / no-AI (excluded) |

- Ghostty has roughly five times the post-cutoff history of the next candidate and enough fix commits for SZZ-style labels.
- Its written policy permits disclosed AI assistance, which matches this project's own disclosure rules.
- TigerBeetle's deterministic simulation testing is the strongest independent oracle among the candidates, which is what a confirmation run needs.

## Consequences

- **Toolchain per commit.** Ghostty's `minimum_zig_version` was 0.15.2 on 2026-07-01, 0.16.0 on 2026-09-01 and 0.17.0 on 2026-11-01. The substrate (#17) must provision the toolchain each commit declares; a single pinned Zig is not enough.
- **Scale.** Thousands of commits make the memoized, content-addressed replay in docs/design.md necessary rather than optional, and the budget in #15 must be sized for it.
- **Outside maintainers.** Their acceptance of findings carries weight that self-maintained acceptance did not. If they decline, this ADR is revisited before any write-up.
- Supersedes the target choice in ADR 0006; its smoke-target role for zig-h3 stands.
