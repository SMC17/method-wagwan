# Bun's Zig fork: what it unlocks and why we start from upstream

**Decision.** The project fork starts from upstream Zig 0.16, not from Bun's fork. Bun's fork is built on Zig 0.15.2, its headline change is nondeterministic by the account of a Zig core contributor, and its owner is publicly trialing a port of Bun to Rust. Building on it would trade a current, deterministic base for a stale base with an uncertain owner. One of its two changes is worth re-implementing on our own fork, and the other becomes our flagship research target, rebuilt the right way.

## What Bun's fork contains

Bun maintains a fork of Zig because Zig's code of conduct bans LLM use in issues, pull requests, and bug tracker comments, and Bun's development is heavily AI-assisted. In that fork Bun added parallel semantic analysis and multiple LLVM codegen units on macOS and Linux, and reported that debug builds of Bun compile more than four times faster. Bun stated it does not plan to upstream the work because of the ban. The fork compares against an `upgrade-0.15.2` branch, so it is based on Zig 0.15.2.

## Why upstream would not take it even without the ban

A Zig core contributor explained that the AI policy is beside the point for this patch, for two separate reasons.

1. **Parallel semantic analysis needs language changes first.** Before Zig 0.16, analysis results could depend on the order in which declarations were analyzed, so some orders compiled and others failed. Single-threaded analysis hid this. The 0.16 type-resolution rewrite moved the compiler's dependency graph from cyclic to acyclic to remove that order dependence. Bun's fork predates those changes, so its parallel analysis can be nondeterministic and can randomly produce compile errors.
2. **Multiple LLVM modules are not worth upstream's effort.** LLVM's speed sets a hard ceiling no matter how the work is split, and upstream is investing instead in its self-hosted x86_64 backend and in incremental compilation.

## What upstream already offers

Zig 0.16.0 shipped on April 14, 2026, with I/O as an interface, the type-resolution rewrite, and incremental compilation that recompiles small edits in milliseconds. The self-hosted x86_64 backend gives roughly a fourfold clean-build speedup over LLVM on the compiler itself. For the engine's debug-build hot loop, upstream is already the faster path.

## Change by change

| Bun fork change | What it unlocks | Problem | Our decision |
| --- | --- | --- | --- |
| Parallel semantic analysis | Large debug-build speedups on big codebases | Nondeterministic without the 0.16 type-resolution changes, which can cause random compile errors | Not taken. Rebuilt on 0.16's acyclic dependency graph as the fork's flagship research target, gated by the determinism oracle |
| Multiple LLVM codegen units | Faster LLVM builds, which matter for the release builds our benchmark oracle needs and for targets the self-hosted backend does not cover | A priority judgment by upstream, not a correctness problem | Candidate to re-implement on 0.16 in the compatible tier, verified by the compatibility contract |
| Proof of concept | Shows AI-assisted compiler work on Zig is feasible and valuable | Not applicable | Kept as a case study and cited in our positioning |

## Why base choice matters more for us than for Bun

Bun needs a compiler that builds Bun fast. We need a compiler that is a trustworthy oracle, because the engine's entire claim rests on deterministic judgment. A compiler that can randomly fail would contaminate every verdict the engine records. That makes determinism a hard requirement for our base, which Bun's fork does not meet.

## Continuity risk

Bun's creator committed a Zig-to-Rust porting guide and has said the team has not committed to a rewrite and that there is a high chance the experimental code is thrown out. Either way, a fork whose owner is evaluating leaving the language is a poor foundation for a multi-year plan.

## When to revisit

Revisit this decision if Bun rebases its fork onto 0.16 or later, publishes determinism results for parallel analysis, and commits publicly to staying on Zig. Until then, Bun's fork is a reference point and not a base.

## The determinism oracle

Every compiler change in our fork must produce byte-identical output and identical diagnostics across repeated builds of the whole corpus under different thread counts and scheduling orders. This is the check Bun's parallel analysis would fail, and it is what lets our fork pursue parallel compilation without inheriting nondeterminism.

## Sources

- [The Zig project's rationale for their firm anti-AI contribution policy, Simon Willison](https://simonwillison.net/2026/Apr/30/zig-anti-ai/)
- [Bun on X, parallel semantic analysis and multiple codegen units](https://x.com/bunjavascript/status/2048427636414923250)
- [Bun's Zig fork got 4x faster compilation times, Ziggit](https://ziggit.dev/t/bun-s-zig-fork-got-4x-faster-compilation-times/15183/19)
- [Anthropic's Bun team trials port from Zig to Rust, The Register](https://www.theregister.com/2026/05/05/bun_rust_port/)
- [Zig is at a crossroads, daily.dev](https://daily.dev/posts/zig-is-at-a-crossroads-5jodjk2fc)
- [Zig 0.16.0 ships Io as an interface, rewrites type resolution, and lands incremental compilation, Machine Herald](https://machineherald-io.pages.dev/article/2026-05/20-zig-0160-ships-io-as-an-interface-rewrites-type-resolution-and-lands-incremental-compilation)
