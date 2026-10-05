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
