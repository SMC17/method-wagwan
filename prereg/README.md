# Pre-registrations

Every experiment is pre-registered here before it runs. A file in this folder fixes the hypothesis, targets, model and training cutoff, metrics, baselines, pass threshold, and budget, and it is merged to `main` before the first replay begins. The merge commit is the timestamp that proves the numbers were not chosen after seeing results.

Files are named `NNNN-short-name.md` and link to their Experiment issue. Once a run starts, a pre-registration is never edited. Any change is appended under a `Deviations` heading with the date and the reason.

The first pre-registration is the phase one foresight experiment, tracked in issue #15.
