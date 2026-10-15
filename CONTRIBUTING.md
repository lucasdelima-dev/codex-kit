# Contributing to Codex Kit

Contributions are welcome.

Changes should preserve the main properties of the project:

- multi-project isolation;
- cross-platform portability;
- idempotent bootstraps;
- predictable version pinning;
- minimal global state;
- local handling of credentials;
- separation between machine, profile and project configuration.

## Development

Use a dedicated branch and keep changes focused.

```bash
git checkout -b feat/my-change
```

Avoid unrelated refactors in the same pull request.

## Validation

Before submitting a change, run at least:

```bash
git diff --check
```

For Bash files, also use `bash -n`.

Changes affecting installation should consider Linux, macOS and Windows.

## Public repository rules

Do not commit secrets, authentication files, API keys, private keys, `.env`
files, production credentials, internal project data or personal absolute paths.

When redistributing third-party material, verify its license and update
`THIRD_PARTY_NOTICES` when required.

## Pull requests

Describe what changed, why it changed, affected platforms or profiles and the
validation performed.

## Protected main branch

The `main` branch is protected by an active repository ruleset.
Changes must be submitted through a pull request from a dedicated branch.

Before merging, these CI checks must pass:

- `Validate (ubuntu-latest)`
- `Validate (macos-latest)`
- `Validate (windows-latest)`

Required status checks use strict mode: the pull request must be up to
date with `main` before merging.

The current ruleset requires zero approving reviews, allowing the
repository maintainer to merge a pull request after all required checks
pass. This does not waive CI or other branch protection rules.

Force pushes and branch deletion are prohibited. No bypass actors are
configured.

For changes affecting installation or native runtimes, run the
`Bootstrap Smoke` workflow on Ubuntu, macOS and Windows before release.
This workflow is dispatched separately from the required PR checks.
