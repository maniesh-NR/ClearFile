# Security policy

ClearFile is demonstration software. This policy covers the code in this
repository: the Flutter application (`clearfile/`), the Next.js web
prototype (`src/`), and the CI/release assets (`.github/workflows/`,
GitHub Releases).

## Reporting a vulnerability

Use GitHub's **private vulnerability reporting** on this repository
(Repo → Security → "Report a vulnerability"). It reaches the maintainer
without public disclosure. Please do not open a public issue for anything
you believe is exploitable.

Include in the report: the file/line or component involved, a minimal
reproduction, and your assessment of impact. Reports are triaged in the
order received; there is no bug bounty and no response-time commitment.

## Scope

In scope:

- `clearfile/` — the Flutter app's on-device storage, import/export
  parsers, and the optional AI-assistant transport.
- `src/` — the web prototype's localStorage persistence, file import
  parsers, and AI transport.
- `.github/workflows/` and release assets (supply-chain integrity:
  tag/SHA handling, action pinning, artifact provenance).

Known, **disclosed** posture — these are accepted and documented; there is
no need to report them:

- Release binaries are **unsigned** (no code-signing certificates are
  held for this project). Integrity comes from `SHA256SUMS.txt` attached
  to every release — verify downloads against it.
- AI provider API keys are stored in cleartext in the app's private
  on-device settings file; the file's location and format are disclosed
  in-app. Keys never leave the device except directly to the provider
  they belong to.
- The optional AI assistant sends de-identified return figures directly
  to the user's own chosen provider (Google AI Studio / OpenRouter) over
  HTTPS. No telemetry of any kind exists.
- This is a tax-return *study prototype*: not IRS-authorized, cannot
  e-file, and must not be used to prepare a real return. Engine accuracy
  is a correctness matter, not a security one.

Out of scope: the tax-calculation accuracy of either engine, and
vulnerabilities in dependencies unreachable from this project's code.

## Supported versions

Only the latest tagged release is supported with security fixes.
