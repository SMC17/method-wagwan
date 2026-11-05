# How work is tracked

Every piece of work in this project is visible, linked to the plan it serves, and merged through a checked and reviewed path, so that anyone can trace a line of code back to the issue, the decision, and the phase gate that justified it.

## The hierarchy

| Level | GitHub feature | Purpose |
| --- | --- | --- |
| Phase | Milestone | Each roadmap phase is a milestone whose description states its pass gate and stop condition |
| Outcome | Epic issue with sub-issues | Each phase, the compile-speed track, and the down-range plan has one epic, and its sub-issues show progress |
| Unit of work | Issue | One issue per deliverable, created from an issue form, with acceptance criteria as a checklist |
| Order | Issue dependencies | "Blocked by" links record what must finish first |
| Change | Pull request | One pull request per logical change, closing its issue |

## Issue forms

Blank issues are disabled. Every issue starts from one of five forms, each of which applies its type label.

| Form | Use it for |
| --- | --- |
| Feature | A new capability, with a required temporal-firewall check |
| Research question | An open question that blocks a decision |
| Experiment | A pre-registered run, with a matching file under `prereg/` committed before execution |
| Decision | A choice that ends in an ADR under `docs/adr/` |
| Bug | Something wrong, with flags for determinism failures and corrupted verdicts |

Open-ended ideas go to Discussions until they are concrete enough for a form.

## Labels

Labels are defined as code in `.github/labels.json` and synced by the Labels workflow whenever that file changes on `main`. Edit the file in a pull request, never in the web UI, because the sync deletes labels that are not in the file.

| Prefix | Meaning |
| --- | --- |
| `type:` | Exactly one per issue: epic, feature, research, experiment, decision, bug, docs, infra |
| `area:` | One or more parts of the system |
| `priority:` | P0 blocks the current phase gate, P1 is needed for the phase, P2 is useful but not blocking |
| `status:` | Blocked, needs a decision, or needs an outside maintainer |
| `track:` | A cross-phase track, such as `track: bun-done-right` |

## Branches, titles, and merges

Branches are named `<type>/<short-description>`, such as `feat/replay-clock` or `adr/fork-name`. Pull request titles follow the conventional format `type(scope): summary`, which the PR title check enforces, because squash merges use the title as the commit subject and release notes are generated from it. Only squash merges are allowed, the branch is deleted on merge, and `main` keeps a linear history.

## Checks

| Check | Workflow | What it enforces |
| --- | --- | --- |
| Markdown lint | `docs.yml` | Consistent Markdown across all documentation |
| Link check | `docs.yml` | Internal links on every pull request, and every link weekly with a tracking issue opened on failure |
| Workflow lint | `docs.yml` | Valid GitHub Actions workflows through actionlint |
| PR title | `pr.yml` | Conventional pull request titles |

Every third-party action is pinned to a full commit SHA with its version in a comment, and Dependabot proposes grouped updates weekly.

## Protection

The `main protection` ruleset requires a pull request, resolved review threads, and all four checks passing on an up-to-date branch, and it blocks force pushes and deletion. Repository settings, the ruleset, and security features are applied by `scripts/apply-repo-settings.sh`, which a maintainer runs with their own login because automation sessions cannot write repository settings.

## Decisions

A decision starts as a Decision issue and ends as an ADR in `docs/adr/` written from `docs/adr/template.md`. Accepted ADRs are never rewritten. A changed decision gets a new ADR that supersedes the old one, and the index in `docs/adr/README.md` is updated in the same pull request.

## Experiments

An experiment starts as an Experiment issue and a pre-registration file in `prereg/`, both merged before the run begins. The result is published whether it passes or fails, and any deviation from the pre-registration is recorded as a deviation rather than an edit.

## The Project board

The board is created by `scripts/create-project.sh`, which adds every open issue and sets Priority and Phase from labels and milestones. Three views are then configured in the web UI.

| View | Layout | Grouping and sorting |
| --- | --- | --- |
| Board | Board | Columns by Status, filtered to the current phase |
| Roadmap | Roadmap | Grouped by Phase, dated by Target date |
| Areas | Table | Grouped by Area, sorted by Priority |

The project's auto-add workflow is enabled for this repository so new issues land on the board automatically.

## Releases

Releases are tagged from `main`, and their notes are generated from merged pull requests, grouped by the categories in `.github/release.yml`.
