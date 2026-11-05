# Roadmap

The roadmap is gated by results rather than dates. Each phase answers one question cheaply before the next phase spends money on the assumption that the answer was yes, and every phase carries a kill or redesign condition that is written down before work begins.

| Phase | Question | What gets built | Pass gate | Stop or redesign if |
| --- | --- | --- | --- | --- |
| 1. Prove the signal | Does walk-forward review see bugs before humans fix them? | Replay substrate, Zig adapter, oracle layer, `harden`, `predict`, shadow-mode `saturate` on one opted-in repository, baselines, pre-registration, and a tracking fork of upstream Zig | Forecasts beat the churn baseline on commits after the model's training cutoff, and the maintainer accepts verified findings | No edge over the churn baseline after contamination controls |
| 2. Prove the protocol | Can a second language join without changing the core? | C and C++ adapter built on Zig's toolchain, adapter conformance suite, public foresight leaderboard | The second adapter passes conformance with no core changes, and outsiders reproduce published runs | Each new language forces changes to the core |
| 3. Prove the search | Does accumulated skill make later search cheaper? | `branch`, `attack`, `schedule`, `distill` with the temporal firewall enforced in code, the saturation-depth experiment, and the first compatible-tier fork release | Distilled skills cut saturation rounds on held-out repositories, and the fork release passes the compatibility contract | Skills show no transfer to held-out repositories |
| 4. Open the movement | Can growth continue without the core team? | Rust and Python adapters built by the community, opt-in project registry, bounties, open RFC governance | A community adapter earns its conformance badge with no core-team code | Adapters stall without core-team effort |

The down-range sequence that follows phase four, in which the engine is rebuilt on the project's own Zig fork and the pattern repeats for every later language, is described in [`docs/down-range-plan.md`](docs/down-range-plan.md).

## Phase one checklist

- [ ] Choose the first opted-in Zig repository and confirm the maintainer agrees
- [ ] Set the phase one compute budget in tokens and dollars
- [ ] Pre-register metrics, thresholds, baselines, and the cutoff split
- [ ] Stand up the tracking fork of upstream Zig 0.16 with automated rebuilds
- [ ] Build deterministic checkout and sandboxed builds with a pinned toolchain per commit
- [ ] Build the oracle layer with repository tests, testing allocators, fuzzing, and a hidden test set
- [ ] Define code units for the Zig adapter and the content-addressed store
- [ ] Implement `predict` with proper scoring against SZZ, revert, and hand-validated labels
- [ ] Implement `harden` and shadow-mode `saturate`
- [ ] Run the baselines and publish the phase one result, whatever it is
