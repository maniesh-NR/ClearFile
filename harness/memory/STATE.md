# Current state (snapshot)

**Updated:** 2026-11-14 (after the Stage-0 adversarial gate closed)

## Repository

- GitHub: `maniesh-NR/ClearFile` (public), branch `main`. Tip after this
  session: the Stage-0 closing backup commit (see SESSION_LOG /
  CONSENSUS). Tag `v1.0.0` (points at the pre-hygiene `13205da`); its
  GitHub Release carries 8 platform assets + the RE protocol doc, and — as
  of 2026-11-14 — a **patched release description** carrying the demo
  disclaimer (HTTP 200 verified).
- Public tree: project-only (`clearfile/`, `src/`, `docs/`, `scripts/`,
  `harness/`, `.github/`, `blueprint-assets/`, `prisma/`, `public/`,
  configs, `README.md`, `LICENSE`, `package-lock.json`). Sandbox
  scaffolding is untracked and gitignored (backup scope, `.gitignore`
  "sandbox backup scope" block — includes `upload/`).
- **History debt:** pre-`df617e8` history retains the scaffolding (no
  secrets — triple-verified); **ADR-008 (accept-and-document) awaits owner
  ratification.**
- Stage-0 gate: **PASSED** (4 × PROCEED-WITH-CONDITIONS; ledger in
  `adversarial/CONSENSUS.md`). **Stage 1 is NOT entered** — owner
  decisions + Stage-1 entry conditions pending.

## Environment facts (sandbox)

- **Flutter SDK 3.47.9: ABSENT** (recycled 2026-11-14). Reinstall from the
  stable Linux tarball to `tools/flutter` (verify sha256), then
  `export PATH="$PWD/tools/flutter/bin:$PATH"`. Gradle note: if
  `gradle-wrapper.jar` is missing again, fetch it from the Gradle v9.3.1
  tag (previous session's fix).
- **`node_modules/` SURVIVED the recycle** (verified: `npx tsc` runs).
  `.next/` is gone — run `npm run build` when web output is needed.
  `npm ci` now works off the committed `package-lock.json`.
- `typescript.ignoreBuildErrors` is **off**; `npx tsc --noEmit` exits 0
  (tsconfig excludes the untracked `examples/` and `skills/` scaffolding).
- Git identity resolves to the platform default (`z@container`). Remote
  auth uses the owner's fine-grained PAT, embedded only in `.git/config`.
- Dart tests: **42/42 green as of 2026-11-03**, +1 delete-regression test
  added 2026-11-14 (43 total, **pending SDK verification at Stage-1
  entry**). `flutter analyze` clean as of 2026-11-03.

## Hard-won quirks (do not relearn these)

1. **Widget tests + filesystem = hang.** In this SDK (Flutter 3.47), any
   `dart:io` Future awaited inside a `testWidgets` body in the binding's
   test zone never resolves. Every FS-touching call in widget tests must
   run inside `tester.runAsync(() async { ... })`. See
   `clearfile/test/widget_test.dart` header. (Plain `test()` bodies are
   unaffected — the delete regression test uses one.)
2. **`AppState.dispose()` is idempotent**; test bodies call it before
   returning because `_verifyInvariants` (no pending timers) runs *before*
   teardown callbacks.
3. **`deleteReturn` cancels the autosave debounce and the timer callback
   is identity-guarded** (2026-11-14) — deleted returns must never
   resurrect; regression test pins it.
4. Dart string literals: `$` must be `\$` (money strings!).
5. `file_picker` 13.x: static `FilePicker.pickFiles()` (cancellation →
   empty list, not null); `FilePicker.saveFile()` returns `Uri?`.
6. `RadioListTile` group params are gone; wrap choices in `RadioGroup<T>`.
7. `dynamic_color` is unusable at Flutter 3.47 (ColorScheme type clash
   with the `material_ui` split) — static teal seed `0xFF00696E`.
8. `upload-artifact` `path:` resolves from the **workspace root**, not
   from `defaults.run.working-directory` (cost one failed macOS job on
   v1.0.0).
9. Root `.gitignore` needs `/test` (not `test`), or the bare pattern hides
   `clearfile/test/` entirely.
10. **Sandbox recycles squash local git history** (one "Initial commit"
    that sweeps in scaffolding) — GitHub is the source of truth; the
    recovery runbook is WORKFLOW.md §4 and it works (executed 2026-11-14).
11. `pubspec.lock` contains 64-hex sha256 checksums — any hex-blob secret
    heuristic must exclude lockfiles (the backup script does).

## Immediately next

Per CONSENSUS.md "Owner decisions required": (1) ratify ADR-008
(nitro_nissi provenance), (2) ratify ADR-009 (web freeze vs parity),
(3) decide the Android INTERNET permission question, (4) set PAT expiry +
branch protection. Then the Stage-1 entry list (reinstall SDK, run 43
tests, privacy-copy fixes) — and only after that does the Stage-1 gate
convene. See `adversarial/CONSENSUS.md` and `memory/ROADMAP.md`.
