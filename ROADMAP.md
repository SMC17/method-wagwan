# Roadmap

The roadmap is gated by results rather than dates. Each phase answers one question cheaply before the next phase spends money on the assumption that the answer was yes, and every phase carries a kill or redesign condition that is written down before work begins. Each phase is a GitHub milestone with an epic issue whose sub-issues are the live checklist, so the issues, not this file, are the source of truth for progress.

| Phase | Question | What gets built | Pass gate | Stop or redesign if | Tracking |
| --- | --- | --- | --- | --- | --- |
| 0. Foundations | Is the repository ready to take engine code? | Settings, ruleset, security features, project board, issue forms, CI, license | Every check is required on `main` and every phase-one issue is triaged | Not applicable | Epic #1 |
| 1. Prove the signal | Does walk-forward review see bugs before humans fix them? | Replay substrate, Zig adapter, oracle layer, temporal firewall, `harden`, `predict`, shadow-mode `saturate` on one opted-in repository, baselines, pre-registration, and a tracking fork of upstream Zig | Forecasts beat the churn baseline on commits after the model's training cutoff, and the maintainer accepts verified findings | No edge over the churn baseline after contamination controls | Epic #2 |
| 2. Prove the protocol | Can a second language join without changing the core? | Protocol specification, C and C++ adapter built on Zig's toolchain, adapter conformance suite, public foresight leaderboard | The second adapter passes conformance with no core changes, and outsiders reproduce published runs | Each new language forces changes to the core | Epic #3 |
| 3. Prove the search | Does accumulated skill make later search cheaper? | `branch`, `translate`, `attack`, `schedule`, `distill` with the skill firewall, the saturation-depth experiment, the compatibility contract, the determinism oracle, and the first compatible-tier fork release | Distilled skills cut saturation rounds on held-out repositories, and the fork release passes the compatibility contract | Skills show no transfer to held-out repositories | Epic #4 |
| 4. Open the movement | Can growth continue without the core team? | Rust and Python adapters built by the community, opt-in project registry, bounties, open RFC governance | A community adapter earns its conformance badge with no core-team code | Adapters stall without core-team effort | Epic #5 |

The down-range sequence that follows phase four, in which the engine is rebuilt on the project's own Zig fork and the pattern repeats for every later language, is described in [`docs/down-range-plan.md`](docs/down-range-plan.md) and tracked in epic #7.

## Compile-speed track: Bun's wins, done right

Bun's Zig fork showed that large compile-speed gains are available, and it also showed the cost of taking them carelessly. This track rebuilds both of Bun's changes on upstream Zig 0.16 so that every gain is deterministic, verified by the compatibility contract, and safe to depend on. The full analysis is in [`docs/bun-fork-analysis.md`](docs/bun-fork-analysis.md), and the track is epic #6.

| Step | What it delivers | Why it is done this way | When | Issue |
| --- | --- | --- | --- | --- |
| Determinism oracle | Byte-identical output and diagnostics across thread counts and scheduling orders, enforced on every fork change | It is the check Bun's parallel analysis would fail, so it must exist before any parallel compilation work lands | Phase 3 | #46 |
| Multiple LLVM codegen units | Faster release builds, which the benchmark oracle depends on, and faster builds on targets the self-hosted backend does not cover | Upstream declined it as a priority judgment, not a correctness problem, so it fits the compatible tier | Phase 3 | #47 |
| Deterministic parallel semantic analysis | Large debug-build speedups on big codebases | Rebuilt on 0.16's acyclic dependency graph, which removed the order dependence that made Bun's version nondeterministic | Down-range | #48 |
| Revisit the base decision | A standing check of whether Bun's fork becomes a viable base | ADR 0004 names three conditions that would reopen it | Every upstream release | #49 |

## Where to look

| Question | Place |
| --- | --- |
| What is being worked on now | The Project board, filtered to the current phase |
| What blocks what | The "Blocked by" links on each issue |
| Why a decision was made | [`docs/adr/`](docs/adr/) |
| How work moves through the repository | [`docs/github-workflow.md`](docs/github-workflow.md) |
