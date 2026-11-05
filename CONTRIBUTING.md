# Contributing

AI-assisted contributions are welcome here. The standard is not who or what wrote a change but whether it is verified, disclosed, and small enough to review.

## What every contribution needs

- **Disclosure.** State in the pull request whether models were used and for which parts.
- **Verification.** Changes to the engine pass its test suite. Changes to the fork pass the compatibility contract and the determinism oracle. Claims about results include the trace that reproduces them.
- **Size.** One change per pull request, sized so a person can review it in one sitting.
- **Ownership.** The contributor answers review questions in their own words and stays accountable for the change after it merges.

## What we will not do

We never file engine output in another project's trackers. Findings about enrolled projects go to their maintainers privately before anything is published, and a maintainer's request to exclude a repository is honored in every future run.

## Adapters

Community adapters are the main way new languages join. An adapter is accepted once it earns its conformance badge by reproducing the reference builds and passing the protocol test suite. The protocol specification will live in `docs/protocol.md` once phase two begins.
