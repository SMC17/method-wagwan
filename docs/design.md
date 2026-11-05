# Design

This is the condensed engineering design. The living document with diagrams is at <https://claude.ai/artifact/WhdbtrnFdx9eQwud6X2yR6>, and this file is updated whenever a decision there changes.

## Architecture

The engine has four parts. A **core** that knows nothing about any language holds the replay clock, a content-addressed store, the scheduler, and the trace. A **proposal layer** is where models generate tests, refinements, forecasts, attacks, and branch experiments. A **judgment layer** of deterministic programs, made up of repository tests, a hidden test set, hardened tests, sanitizers, fuzzing, differential runs, and proper scoring rules, alone decides what reaches the trace. **Adapters** connect the core to each language through a JSON-RPC protocol over standard input and output.

Signals that depend on history after the replay clock sit outside this loop entirely, in an evaluation stage that reads a run only after it is frozen.

## Incremental replay

The unit of work is a code unit identified by the hash of its body and the hashes of what it depends on, not a commit. A result computed once is reused on every later commit and every branch where that unit is unchanged, so replay cost scales with how much the code churns rather than with how many commits exist. Branches become persistent data structures that share every unit they have not touched.

Under illustrative assumptions (5,000 commits, 50 checkpoints, 30 changed units per checkpoint, 10 rounds of 5 proposals), saturating every commit on whole files costs about 10 billion tokens per path, while forecasting every commit and saturating changed units only at checkpoints costs about 1.3 billion before memoization. The cheap primitives run often, and the expensive primitive runs sparsely and only on what changed.

## Primitives

| Primitive | Who does it | What it does | What it is scored on |
| --- | --- | --- | --- |
| `harden` | Model proposes, program accepts | Writes property tests, fuzz harnesses, and assertions that upstream code at commit N already passes, which pins current behavior | Coverage and mutation-kill gained, accepted only if upstream at N passes |
| `saturate` | Model proposes, oracle decides | Behavior-preserving refinements of changed units, up to the boundary the hardened oracle can certify | Verified gain on the present-tense score vector |
| `predict` | Model proposes, statistics decide | Forecasts which changes introduce bugs, which get reverted, and where the next fix lands | Proper scoring rules against SZZ-traced, revert, and hand-validated labels |
| `attack` | Model proposes, sanitizers decide | Generates inputs aimed at crashes, panics, leaks, undefined behavior, and divergence from upstream | Unambiguous failures only |
| `branch` | Model proposes, evaluation decides | Opens an explicit behavior-changing experiment and carries upstream intent onto it with `translate` | Realized translation cost and checkpoint scores, used only for evaluation |
| `distill` | Program | Packages recurring verified wins as idioms and agent skills, each stamped with the latest commit date it learned from | Whether later saturation converges in fewer rounds |
| `schedule` | Program | Allocates budget across units and branches with bandit rules and successive halving | Verified gain per token |

```zig
// One checkpoint on one branch. Every step is memoized by content hash.
fn checkpoint(b: *Branch, clock: Commit, budget: Budget) !void {
    const changed = try b.changedUnitsSince(b.last_checkpoint, clock);
    for (changed) |unit| {
        try harden(b, unit, clock, budget.slice(.harden)); // grow the oracle first
        try saturate(b, unit, clock, budget.slice(.saturate)); // then optimize to its boundary
    }
    try attack(b, changed, clock, budget.slice(.attack));
    try trace.record(b, clock); // only verified results reach the trace
}
```

## Signals and leakage

| Signal | Class | Allowed to steer search |
| --- | --- | --- |
| Oracle verdicts at commit N | Search | Yes |
| Benchmarks on randomized inputs at commit N | Search | Yes |
| Coupling, API surface, and module-boundary proxies for changeability | Search | Yes |
| Forecast scores on commits already behind the replay clock | Search | Yes |
| Realized translation cost of later upstream commits | Evaluation | No |
| Checkpoint comparisons against upstream's future | Evaluation | No |
| SZZ labels that depend on fixes after the clock | Evaluation | No |

Distilled skills carry the latest commit date they learned from and are refused by any replay whose clock is earlier. Headline results use only commits after the proposing model's training cutoff, and contamination is tested by obfuscating identifiers and checking whether performance collapses.

## Baselines and pre-registration

Every headline metric is reported beside a static analyzer at matched false-positive rate, a single-shot model review with no engine, a churn heuristic, and chance at the same flag rate. Metrics, thresholds, targets, and the cutoff split are committed to this repository before each run.

## Reward hacking defenses

| Exploit | Defense |
| --- | --- |
| Weakening, skipping, or deleting tests | Oracle files are read-only to proposers and checked by hash |
| Special-casing benchmarks or precomputing answers at comptime | Inputs drawn from a hidden distribution, plus binary-size and compile-time checks |
| Passing visible tests while changing behavior elsewhere | Differential execution against upstream on generated inputs, plus a hidden test set |
| Flagging everything to catch every bug | Proper scoring rules make false positives as costly as misses |
| Adversary writing wrong tests | The adversary is paid only for unambiguous failures |
| Hardening that pins a bug as intended behavior | Pinned tests are tagged as behavior, not specification, and never block an upstream fix |
| Proposer and judge sharing a blind spot | The judge is deterministic code |

## Language expansion

The growth model follows the Language Server Protocol, in which one small protocol lets each language community write its own server. Here each community writes its own adapter. An adapter answers six questions for any commit, which are the toolchain, the build, the tests, the hashed code units, the applicable oracle plugins, and the benchmarks. It earns a conformance badge by reproducing a fixed set of historical builds and test results.

The order is Zig, then C and C++ on Zig's toolchain, then Rust, then Python. C and C++ come before Rust because Zig's toolchain already works as a hermetic C and C++ compiler and their sanitizers give the strongest oracles in any ecosystem.
