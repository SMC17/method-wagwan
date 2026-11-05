# Security policy

Report vulnerabilities privately through [GitHub security advisories](https://github.com/SMC17/method-wagwan/security/advisories/new), never in a public issue.

This project runs untrusted repository code inside sandboxes and executes model-generated tests and inputs, so the following are in scope and treated as high severity.

- Escapes from the replay sandbox, including network access or reads of git refs past the replay clock
- Any way for a proposer to modify oracle files, the hidden test set, or recorded verdicts
- Miscompilation or nondeterminism in a project fork that could corrupt a recorded result
- Leakage of credentials or private repository content into traces or published reports

Reports are acknowledged within seven days. Fixes for issues that could corrupt published results are disclosed together with a list of every affected result.
