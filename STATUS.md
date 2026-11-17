# method-wagwan status

| | |
| --- | --- |
| Proof level | **unit-tested** (see [proof levels](https://github.com/SMC17/SMC17/blob/main/STANDARDS.md#proof-levels)) |
| Last verified | 2026-11-17, macOS on Apple M2 Max, Zig 0.16.0 |
| Command | `zig build test --summary all` |
| Result | 3/3 steps succeeded; 8/8 tests passed |
| What exists | Core deterministic replay engine in Zig ([`src/`](src/)): content-addressed unit hashing and memoization (`store.zig`), ADR 0003 temporal firewall (`firewall.zig`), deterministic `ReplayEngine` and `TraceLog` SHA-256 digest (`replay.zig`), CLI smoke runner (`main.zig`), plus [docs/design.md](docs/design.md) and ADRs 0001-0007 |
| What does not exist yet | External JSON-RPC language adapter process, LLM proposer integration, and full Phase 1 run (#15 pre-registration, #17 substrate) |
| Phase one target | ghostty-org/ghostty, confirmation on tigerbeetle, smoke test on zig-h3 ([ADR 0007](docs/adr/0007-phase-one-target-ghostty.md)) |
| Pre-registration | Draft, not in force: [#59](https://github.com/SMC17/method-wagwan/pull/59) |

Core replay substrate, temporal firewall, and content-addressed memoization are unit-tested; no Phase 1 empirical forecast result is claimed yet.
