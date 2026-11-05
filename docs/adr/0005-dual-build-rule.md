# 0005. The engine keeps building on upstream until the fork proves itself

**Status:** Accepted, 2026-11-05

## Context

The down-range plan rebuilds the engine on the project's own Zig fork, which creates a bootstrapping loop. A miscompilation in the fork could corrupt the engine, which could then approve further corrupt changes to the fork.

## Decision

The engine must keep compiling and passing its own tests on upstream Zig until the fork has passed a set number of consecutive compatibility releases. The engine's test suite is part of the compatibility corpus, and the engine's outputs are compared across both builds.

## Consequences

- The fork is an accelerator for the engine, never a requirement for using it.
- A fork regression never stops the engine, because it falls back to upstream immediately.
- The cost is keeping the engine within the common subset of upstream and fork features until the threshold is met, which also keeps it usable by anyone outside the project.
