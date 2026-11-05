# Down-range plan

The long-range goal is a self-reinforcing loop in which the engine produces a better compiler, the engine is rebuilt on that compiler, and the same pattern repeats for every language the project reaches. This document records the sequence and the discipline that keeps each step from undermining the one before it.

## The sequence

1. **Harden the engine on upstream Zig.** The engine is built with stock Zig 0.16 until the phase one and phase two gates in the [roadmap](../ROADMAP.md) pass, because an unproven engine running on an unproven compiler makes every failure impossible to attribute.
2. **Turn the engine on the Zig compiler from the start of its self-hosted history.** Zig's self-hosted compiler became the default in 0.10, and the history before that is the C++ bootstrap compiler. The Zig adapter replays from the self-hosted era forward. The earlier C++ history waits for the C and C++ adapter, which is one more reason that adapter comes second.
3. **Ship the fork as the artifact that falls out of that replay.** The fork begins as a tracking fork on day one, and its first compatible-tier release is made from patches the engine produced and the compatibility contract verified. The fork's contents come out of the engine rather than being written separately from it.
4. **Rebuild the engine on the fork under the dual-build rule.** The engine moves onto the project's own Zig, but it must keep compiling and passing its own tests on upstream Zig until the fork has passed a set number of consecutive compatibility releases. The engine never depends on a compiler that has not proven itself, and if the fork ever regresses, the engine falls back to upstream without losing a day.
5. **Repeat for each later language.** Each language that reaches the fork conditions in [`fork-strategy.md`](fork-strategy.md) follows the same path, ending with a verified fork and, where it makes sense, engine components built on that fork.

## Why the dual-build rule matters

A compiler that builds the tool that improves the compiler is a bootstrapping loop, and bootstrapping loops amplify mistakes as readily as they amplify gains. A subtle miscompilation in the fork could corrupt the engine, which could then approve further corrupt changes to the fork. Keeping an independent upstream build alive, and comparing the engine's own outputs across both builds, breaks that loop. The engine's own test suite becomes part of the compatibility corpus, so the fork has to keep the engine correct in order to ship.

## Why this is the core idea

Most AI coding projects produce code. This project produces a compiler that was improved by verified replay, then uses that compiler to run the replay, which means the strongest evidence for the engine is that it can safely carry its own foundation. Each turn of the loop is measurable, through compile speed across the corpus, rebase cost per upstream release, and the engine's own performance on the fork versus upstream.

## Risks specific to the down-range plan

| Risk | Mitigation |
| --- | --- |
| A miscompilation propagates through the bootstrapping loop | Dual-build rule, determinism oracle, and the engine's tests inside the compatibility corpus |
| Upstream churn makes the fork too expensive to carry | Patch queue with per-patch benefit tracking, and the fork kill rules |
| The engine becomes unusable for anyone not on the fork | The engine keeps building on upstream Zig indefinitely, so the fork is an accelerator rather than a requirement |
| Maintainer bandwidth across many language forks | A fork opens only when a named maintainer commits to it |
