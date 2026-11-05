# Fork strategy

Every language the engine supports gets a project fork, because upstream projects can refuse AI-produced work outright and a fork is the only place verified language-level gains can ship. The design problem is therefore not whether to fork but how to make each fork cheap to carry and safe enough that people adopt it without hesitation. Upstream remains the source of truth for each language, and the fork is where the engine's verified results reach users.

## What Jane Street actually teaches

OxCaml works because four things hold at once, which are an anchor codebase that benefits from every improvement immediately, a dedicated compiler team, strict compatibility so existing code keeps working, and continuous merging of upstream changes. The engine supplies the last two directly through the compatibility contract and the `translate` primitive. The anchor codebase is the engine itself plus every enrolled project. The dedicated team is the scarce input, which is why a fork opens for a language only when it has a named maintainer.

## Three tiers

| Tier | What changes | Promise to users | Entry rule |
| --- | --- | --- | --- |
| Tracking | Nothing, the fork mirrors upstream and rebuilds on every upstream commit | Identical to upstream | Exists from day one as infrastructure |
| Compatible | Compiler throughput, code generation, standard library internals, diagnostics | Every program valid on upstream compiles and behaves identically, so the fork is a drop-in replacement | Passes the compatibility contract and the determinism oracle on every release |
| Extended | New language features and modes behind explicit opt-in flags | Code that opts in builds only on the fork, and code that does not opt in is unaffected | Public RFC plus evidence from `distill` that saturated code repeatedly wants the feature |

## The compatibility contract

Every fork release compiles an ecosystem corpus, made up of every enrolled project, the engine itself, and a broad sample of public packages, with both the upstream compiler and the fork. It then compares test outcomes, program outputs on generated inputs, and compiler diagnostics. Any unexplained divergence blocks a compatible-tier release, and every release ships with a public compatibility report. This turns the whole ecosystem into the test suite, which makes it the strongest oracle in the system and the main reason anyone should trust a fork built with AI assistance.

## The determinism oracle

Every compiler change must produce byte-identical output and identical diagnostics across repeated builds of the whole corpus under different thread counts and scheduling orders. This requirement exists because the engine's verdicts are only as trustworthy as the compiler that produced them, and it is the specific check that Bun's parallel analysis would fail, as described in [`bun-fork-analysis.md`](bun-fork-analysis.md).

## Rebase economics

Fork changes live as an ordered queue of small patches, each carrying its own hardened tests, its measured benefit, and its rationale in the trace. On every upstream release, `translate` carries the queue forward and the compatibility contract verifies the result, so keeping the fork current is itself a continuous demonstration of the engine. The tracked metric is maintainer hours and tokens per upstream release, and any patch whose rebase cost exceeds its measured benefit across two consecutive releases is dropped. Zig's pre-1.0 churn makes this most expensive in Zig, which is exactly why Zig is the right proving ground.

## What the Zig fork optimizes first

1. **Release-build compile throughput**, starting with a re-implementation of multiple LLVM codegen units on 0.16, measured as compile time across the corpus.
2. **Standard library hot paths** such as allocators, hashing, formatting, and I/O, saturated against behavior pinned by `harden`.
3. **Release-mode code generation**, verified by differential execution against upstream builds.
4. **Deterministic parallel semantic analysis**, the flagship research target, built on 0.16's acyclic dependency graph and gated by the determinism oracle.
5. **Extended-tier features** only later, and only where `distill` shows saturated code repeatedly reaching for something the language cannot express.

## Relationship to upstream

The fork carries its own name and describes itself only as compatible with a given Zig release, never as Zig. It credits upstream in every release, does not campaign in upstream spaces, and never files engine output in upstream trackers.

## Forks for the languages that come later

A fork for a later language opens only when three conditions hold, which are that its adapter holds a conformance badge, that a named maintainer has committed to the fork, and that an ecosystem corpus exists for the compatibility contract.

| Language | What gets forked first | First compatible-tier targets | Relative cost |
| --- | --- | --- | --- |
| Zig | Compiler and standard library | Release-build speed, standard library hot paths | Moderate, one repository written in Zig, but heavy upstream churn |
| C and C++ | Runtime libraries and a toolchain distribution built on Zig's toolchain, not Clang or LLVM at first | Allocators, standard library implementations, sanitizer-hardened builds | Highest if the compiler is forked, which is why the library tier proves out first |
| Rust | Compiler and standard library | Compile times, standard library internals | High, a very large codebase on a six-week release train |
| Python | The CPython interpreter and standard library | Interpreter hot paths and C-accelerated modules | High, though performance-focused CPython forks at large companies, such as Meta's Cinder, show it can be sustained |

## Kill rules

- Two consecutive releases with unexplained compatibility divergence freeze the fork back to the tracking tier until the cause is found.
- Rebase cost per release rising for three consecutive releases triggers a cut to the patch queue.
- No measurable user-facing gain after a set number of releases returns the fork to tracking only, which keeps the infrastructure alive at almost no cost.
