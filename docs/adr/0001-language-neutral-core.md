# 0001. One language-neutral core with per-language adapters

**Status:** Accepted, 2026-11-05

## Context

The first design treated the engine as a Zig engine, to be followed later by separate Rust, C and C++, and Python versions. Four engines would mean four codebases to maintain, four sets of bugs, and a community split four ways.

## Decision

The core knows git, content hashes, schedules, traces, and scores, and knows nothing about any language. Everything language-specific lives in an adapter, a separate process speaking JSON-RPC over standard input and output, which answers six questions for any commit: the toolchain, the build, the tests, the hashed code units, the applicable oracle plugins, and the benchmarks. Adapters earn a conformance badge by reproducing a fixed set of historical builds and test results.

## Consequences

- A new language requires an adapter, not a new engine, and can be written in the language it serves.
- The protocol is the project's most important public interface, and phase two exists to prove it before the community builds on it.
- If a second language forces core changes, the protocol is wrong and is redesigned before phase three.
