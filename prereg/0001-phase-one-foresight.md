# 0001. Phase one foresight on Ghostty

**Status:** DRAFT. Not in force until merged to `main`; the merge commit is the timestamp. Items marked **OPEN** must be closed before merge.

**Experiment issue:** #15 · **Target decision:** ADR 0007

## Hypothesis

At the moment a pull request merges, the engine's `predict` primitive assigns higher probability to the pull requests that later prove to have introduced a bug than a churn heuristic does, measured by a proper scoring rule.

The null hypothesis is that the engine is no better than the churn heuristic. Phase one reports the result whichever way it falls (#28).

## Target and units

- Repository: ghostty-org/ghostty, default branch.
- Unit: a merged pull request. The replay clock for a unit is its merge commit; the engine sees only history at or before that commit (ADR 0003).
- Evaluation window: PRs merged 2026-07-01 through 2026-09-30. Measured 2026-11-12: 594 merged PRs (1,622 commits) in this window.
- Toolchain: whatever `minimum_zig_version` the merge commit declares (0.15.2 to 0.16.0 in this window; ADR 0007).

## Model and training cutoff

- Proposing model: **OPEN** (name and version, pinned for the whole run).
- Its published training cutoff must be on or before 2026-06-30. If it is later, the window moves to start the month after the cutoff and this file records the change before merge.
- Contamination check: rerun `predict` on the same PRs with identifiers obfuscated (consistent renaming of functions, types and files). If the Brier skill score drops by more than half, the headline is reported as contaminated.

## Labels (evaluation only, never visible to search)

- Positive: a PR whose changed lines are blamed (SZZ, ignoring whitespace, comments and pure moves) by a later merged PR that fixes a bug, where "fixes a bug" means it references an issue labelled as a bug or its title or body states a fix of a regression.
- Label horizon: fixing PRs merged by 2026-11-30. Labels are computed once, after that date, by a script committed in this repository before the run.
- A random 50 of the positives and 50 of the negatives are hand-checked; the agreement rate is reported.

## Metrics

- Primary: Brier score of P(PR introduces a bug).
- Secondary: log loss; precision at the flag rate of the static baseline; area under the precision-recall curve.

## Baselines (same units, same clock)

1. **Churn:** logistic regression on lines added, lines deleted, files touched and the author's prior PR count, fitted only on PRs merged before 2026-07-01.
2. **Single-shot model review:** the same model, one prompt per PR diff, no engine, no history.
3. **Static analysis at matched false-positive rate:** **OPEN.** Zig has no mature static analyzer; candidates are compiler warnings at that commit, `zig ast-check` findings, or dropping this baseline and saying so.
4. **Chance** at the engine's flag rate.

## Pass threshold

The engine passes if its Brier skill score against the churn baseline is above zero and the 95% interval from a bootstrap over PRs (10,000 resamples) excludes zero. Nothing else is called a pass.

## Power

Expected positives: **OPEN.** Computed from the label script on PRs merged before 2026-07-01 (no model output involved), then the minimum detectable Brier skill score at 80% power is written here before merge. If it exceeds 0.10, the window is widened before merge, not after.

## Budget

- Token budget for the whole run, including the obfuscation rerun: **OPEN.**
- Wall-clock limit: **OPEN.**
- If the budget runs out, the run stops and reports on the PRs completed, in merge order, with the count stated.

## Publication

- Results about Ghostty are not published before its maintainers have been asked (ADR 0007).
- The write-up states that the engine's author chose the target and the baselines.

## Deviations

None yet. After merge, changes are appended here with the date and reason; this file is otherwise never edited.
