# Current state (snapshot)

**Updated:** 2026-11-14 (after the Stage-1 execution session — Stage 1
complete pending its exit gate)

## Repository

- GitHub: `maniesh-NR/ClearFile` (public), branch `main`. The Stage-1
  execution session's closing backup is the tip (code work backed up as
  `0bbb564`, memory records in the closing commit).
- Tag `v1.0.1` (release 445310560): **published 2026-11-14** via the
  fresh-tag dispatch path — 11 assets including the first
  `SHA256SUMS.txt` (one asset locally re-verified), the Android INTERNET +
  macOS network-client fix, the network disclosure, and the hardened CI's
  first full green run (8/8 jobs, run 43598726491). The tag points at
  exactly `0bbb564` (target_commitish honored). The existing-tag poisoning
  guard was proven by the intentional refusal run 43598383213.
- `hygiene.yml` (gitleaks weekly + harness_check on push) — first push run
  green. All workflow actions SHA-pinned.
- Public tree: project-only; 61-test suite; GPL-3.0-only SPDX headers on
  own code (vendored shadcn excluded); SECURITY.md present.

## Gate status

- Stage 0: PASSED (2026-11-14).
- **Stage 1: ENTERED + EXECUTION COMPLETE (2026-11-14)** — items 5-9 all
  DONE (ROADMAP carries the evidence); the v1.0.1 closing tag landed.
  Stage 1 formally closes at the Stage-2 entry gate's review of this
  evidence.
- Owner decisions all ratified earlier: ADR-008 accept-and-document;
  ADR-009 feature parity (two-session tripwire + freeze fallback);
  INTERNET add-and-disclose; PAT unchanged. ADR-010 closed (web smoke
  tests exist; strict mode ON). ADR-011: settings schemaVersion 2.

## Environment facts (sandbox)

- **Flutter SDK 3.47.9 PRESENT** at `tools/flutter` (reinstalled
  2026-11-14, sha256 `25ed8c3c…` verified against
  `tools/releases_linux.json`; the tarball download stalls — use a
  resuming loop with `--speed-limit 1024 --speed-time 30`).
- `node_modules/` present; `.next/` absent (`npm run build` when needed).
  `npx tsc --noEmit` exit 0 (tsconfig excludes untracked `examples/`,
  `skills/`).
- Test suite: **61/61 green** (2026-11-14, Stage-1 execution additions):
  19 calculator, 8 cascade, 10 CSV, 3 JSON, 5 privacy, 2 autosave
  regressions, 5 money-parsing, 6 step/settings guards, 3 widget.
  `flutter analyze` clean.
- Git identity: platform default (`z@container`). Remote auth: owner's
  fine-grained PAT in `.git/config` only (owner declined rotation —
  WORKFLOW §5).

## Hard-won quirks (do not relearn these)

1. **Widget tests + filesystem = hang** — FS work inside `testWidgets` must
   run in `tester.runAsync` (plain `test()` is unaffected).
2. `AppState.dispose()` idempotent; call before test-body return
   (`_verifyInvariants` runs before teardown).
3. **Autosave contract (2026-11-14):** `deleteReturn` cancels the debounce;
   the timer callback is identity-guarded; `_open` **flushes the prior
   return's pending save on switch** — three regression tests pin all of
   it (delete, switch, and the privacy contract).
4. Dart `$` escaping; `file_picker` 13.x static API; `RadioGroup<T>`;
   static teal seed (`dynamic_color` unusable at 3.47).
5. `upload-artifact` path: workspace root, not working-directory.
6. Root `.gitignore` `/test` (not `test`).
7. **Sandbox recycles squash local history** — GitHub is source of truth;
   runbook WORKFLOW §4 works (proven twice).
8. Hex-blob heuristics must exclude lockfiles (sha256 checksums) AND stay
t   text-only (`-I`): icon/bitmap pixel data legitimately trips
   `[0-9a-fA-F]{64}` (the Windows app_icon.ico did, six times). Token
   patterns scan binaries fine — they're too distinctive to false-positive.
9. **Snapshot restores flip file modes to 755** — normalize before
   committing or every diff noisies (proven twice; now a pre-backup step
   and a future harness_check item).
10. Blueprint regen: generator + playwright cover + merge (needs
    `mkdir -p download` on fresh clones); not byte-deterministic
    (timestamps) — never cite it as a reproducibility exemplar.
11. **Bulk scripted file edits must be re-verified immediately** — the
    SPDX header script split 15 first lines (line- vs character-offset
    bug); caught by `head` spot-checks + full analyze/test/tsc/smoke
    re-run before commit. Never trust a bulk edit without the suite.
12. **The PAT is broader than its recorded profile** (Actions write/read
    observed 2026-11-14; WORKFLOW §5 carries the correction). Check
    permissions in the UI when rotating.

## Immediately next

**Convene the Stage-2 entry gate** (next session's first task per
WORKFLOW §3.4): full-depth, 4 independent reviewers over (a) the Stage-1
execution evidence (this session's log + ROADMAP marks + the live v1.0.1
release/hygiene runs) and (b) the Stage-2 plan. The gate also settles
Stage-2-vs-Stage-3 ordering (ADV-PROD note 7) and re-checks the parity
tripwire clock (ADR-009: Stage 3 not yet started, box intact).
