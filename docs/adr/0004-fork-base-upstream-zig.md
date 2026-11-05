# 0004. The Zig fork starts from upstream Zig 0.16, not Bun's fork

**Status:** Accepted, 2026-11-05

## Context

Zig's code of conduct bans LLM use in issues, pull requests, and bug tracker comments, so the project needs its own fork to ship verified language-level gains. Bun already maintains an AI-assisted Zig fork with parallel semantic analysis and multiple LLVM codegen units, which made it a candidate base. The full analysis is in [`../bun-fork-analysis.md`](../bun-fork-analysis.md).

## Decision

The fork starts from upstream Zig 0.16 and begins as a tracking fork on day one.

## Reasons

- Bun's fork is based on Zig 0.15.2 and predates the 0.16 type-resolution rewrite and the I/O interface change.
- A Zig core contributor stated that parallel analysis without the 0.16 changes is nondeterministic and can randomly produce compile errors. The engine's verdicts are only as trustworthy as its compiler, so determinism is a hard requirement.
- Bun is publicly trialing a port to Rust, which makes the long-term maintenance of its Zig fork uncertain.
- Upstream 0.16 already provides fast debug iteration through the self-hosted x86_64 backend and incremental compilation.

## Consequences

- Multiple LLVM codegen units are re-implemented on 0.16 as a compatible-tier candidate.
- Deterministic parallel semantic analysis on 0.16's acyclic dependency graph becomes the fork's flagship research target, gated by the determinism oracle.
- This decision is revisited if Bun rebases onto 0.16 or later, publishes determinism results, and commits to staying on Zig.
