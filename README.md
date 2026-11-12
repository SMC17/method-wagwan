# method-wagwan

A walk-forward replay engine for code. It replays a repository's git history from the first commit forward, lets language models propose tests, forecasts, and optimizations using only what existed at each moment, and lets deterministic programs decide what is kept, so that every result it reports can be rerun and checked by a skeptic.

The engine is written in Zig, replays Zig first, and is designed from the start to grow into a language-neutral platform in which each language joins through an adapter, gains a project fork for verified language-level improvements, and eventually hosts an engine built on that fork.

## The core bet

Commit history is ground truth for software judgment in the same way price history is ground truth for a trading strategy. A system that sees the past without seeing the future, and is graded by the future once it arrives, can learn which interventions compound and which ones only look good locally.

## Principles

- **Models propose, programs dispose.** Language models generate candidate changes, tests, forecasts, and translations. Compilers, test runners, sanitizers, fuzzers, differential checks, and statistical scoring decide what is true.
- **Saturation is bounded by the oracle.** The engine only optimizes as far as its oracle can certify that behavior is preserved, so it hardens the oracle first and then optimizes to the new boundary.
- **Time is a hard wall.** Every signal that steers search is computable at the replay clock. Signals that depend on later history are used only to evaluate a frozen run.
- **One engine, many languages.** The core knows git, content hashes, schedules, traces, and scores. Everything language-specific lives in an adapter behind a stable protocol.
- **Every language gets a fork.** Upstream projects can refuse AI-produced work, so verified language-level gains ship in project forks that track upstream continuously and pass an ecosystem-wide compatibility contract on every release.

## Repository map

| Path | Contents |
| --- | --- |
| [`ROADMAP.md`](ROADMAP.md) | Phases, pass gates, and kill conditions |
| [`docs/design.md`](docs/design.md) | Architecture, primitives, signals, anti-gaming, and compute budget |
| [`docs/fork-strategy.md`](docs/fork-strategy.md) | Fork tiers, compatibility contract, rebase economics, per-language plans |
| [`docs/bun-fork-analysis.md`](docs/bun-fork-analysis.md) | What Bun's Zig fork offers and why the project forks from upstream Zig 0.16 instead |
| [`docs/down-range-plan.md`](docs/down-range-plan.md) | The long sequence from engine to self-hosted fork to multi-language movement |
| [`docs/adr/`](docs/adr/) | Architecture decision records |
| [`docs/github-workflow.md`](docs/github-workflow.md) | How issues, labels, milestones, checks, and decisions are tracked |
| [`prereg/`](prereg/) | Experiment pre-registrations, merged before any run begins |
| [`scripts/`](scripts/) | Label sync, repository settings, and Project board setup |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | How AI-assisted contributions are accepted here |
| [`SECURITY.md`](SECURITY.md) | How to report vulnerabilities privately |

The design lives in [docs/design.md](docs/design.md); decisions are versioned as ADRs in [docs/adr](docs/adr/). Diagrams will be added to the docs as the engine lands.

## Status

Planning. No engine code yet. Work is tracked in issues grouped under one epic per phase, with milestones carrying each phase's pass gate.

| Epic | Milestone |
| --- | --- |
| #1 Foundations | M0: Foundations |
| #2 Phase 1, prove the signal | Phase 1 |
| #3 Phase 2, prove the protocol | Phase 2 |
| #4 Phase 3, prove the search | Phase 3 |
| #5 Phase 4, open the movement | Phase 4 |
| #6 Track, Bun's wins done right | Phase 3 and Down-range |
| #7 Down-range, self-hosting fork and multi-language forks | Down-range |

## License

[Apache 2.0](LICENSE).
