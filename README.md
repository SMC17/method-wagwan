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
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | How AI-assisted contributions are accepted here |

The living design document, with diagrams, is at <https://claude.ai/artifact/WhdbtrnFdx9eQwud6X2yR6>. This repository is the durable record and the place where decisions are versioned.

## Status

Planning. No engine code yet. Phase one begins with the replay substrate, the Zig adapter, the oracle layer, and a tracking fork of upstream Zig.

## License

The core and adapters are planned to ship under Apache 2.0. A license file will be added before the first code lands.
