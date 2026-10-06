# Security Policy

## Reporting a vulnerability

Do not publish sensitive vulnerability details in a public issue.

Prefer GitHub Private Vulnerability Reporting or a private Security Advisory
when those features are available for this repository.

Include, when applicable:

- affected component and version;
- reproduction steps;
- observed and expected behavior;
- potential impact;
- suggested mitigation.

Never include real credentials, tokens, private project data or production data.

## Scope

Security reports may include issues involving bootstrap scripts, wrappers,
privilege boundaries, unsafe defaults, project isolation, dependency handling,
credential exposure or filesystem behavior.

Vulnerabilities in third-party tools should also be reported to their
respective upstream maintainers when appropriate.

## Database access and DBHub

DBHub is enabled only per project and uses stdio transport.

Database credentials must never be committed. Use a dedicated database
account with the minimum permissions required, preferably SELECT-only.
Do not use administrator, root, superuser or privileged production
credentials with an AI agent.

DBHub read-only mode, query timeout and row limits are defense-in-depth
controls. Database permissions remain the authoritative access boundary.

## Supported versions

Until versioned releases are published, security fixes apply to the latest
version available on the default branch.
