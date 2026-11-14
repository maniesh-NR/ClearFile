# ClearFile — Flutter application

ClearFile is a **clean-room, demonstration-only** US federal TY2025
tax-return prototype. This directory is the Flutter 3.47 app (Android,
iOS, macOS, Windows, Linux, Web) — the full-featured implementation of
the project.

**This is not IRS-authorized software. It cannot e-file. Do not use it to
prepare a real tax return.**

- Project overview, clean-room legal line, engine scope and limitations:
  see the [repository README](../README.md).
- License: [GPL-3.0](../LICENSE) (repository-wide).
- Tests: `flutter test` (engine, AI cascade, CSV import, JSON roundtrip,
  widget smoke, delete regression).
- Build: `flutter build apk --split-per-abi | linux | macos | windows | web`.
- Pre-built binaries: [GitHub Releases](https://github.com/maniesh-NR/ClearFile/releases).

The durable project memory and governance live in [`harness/`](../harness/README.md).
