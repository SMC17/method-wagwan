# Architecture decision records

Each record states one decision, the context that forced it, and its consequences. Records are never rewritten after acceptance. A changed decision gets a new record that supersedes the old one.

| Number | Decision | Status |
| --- | --- | --- |
| [0001](0001-language-neutral-core.md) | One language-neutral core with per-language adapters | Accepted |
| [0002](0002-models-propose-programs-dispose.md) | Models propose, deterministic programs decide | Accepted |
| [0003](0003-temporal-firewall.md) | Search signals and evaluation signals are separated in code | Accepted |
| [0004](0004-fork-base-upstream-zig.md) | The Zig fork starts from upstream Zig 0.16, not Bun's fork | Accepted |
| [0005](0005-dual-build-rule.md) | The engine keeps building on upstream until the fork proves itself | Accepted |
| [0006](0006-first-replay-target.md) | Replay zig-h3 first, and treat a self-maintained target as a known bias | Superseded by 0007 |
| [0007](0007-phase-one-target-ghostty.md) | Replay Ghostty for Phase one; keep zig-h3 as the smoke target | Accepted |
