# Current state (snapshot)

**Updated:** 2026-11-14 (after the Stage-3 fixtures-first session — the
16 shared golden fixtures landed with four IRS-pinned engine corrections;
this session's closing backup is the tip)

## Repository

- GitHub: `maniesh-NR/ClearFile` (public), branch `main`. The Stage-3
  fixtures-first session's closing backup is the tip.
- Tag `v1.0.1` (release 445310560): published 2026-11-14 via the fresh-tag
  dispatch path — 11 assets including the first `SHA256SUMS.txt`, the
  Android INTERNET + macOS network-client fix, the network disclosure, and
  the hardened CI's first full green run. The tag points at exactly
  `0bbb564`. (Next tagged release owes D29's tag-PUSH verification.)
- `hygiene.yml`: gitleaks + harness_check on push/weekly/dispatch, plus
  the `suites` job (flutter analyze + test + npm ci + tsc) which now also
  runs `scripts/verify_golden_fixtures.py` (the golden-fixture oracle).
  All workflow actions SHA-pinned.
- Public tree: project-only; **`fixtures/tax/`** — 16 IRS-pinned golden
  `(TaxReturnData, TaxResult)` pairs (shared source of truth for both
  engines, per Stage 3 / ADR-009); 77-test suite; GPL-3.0-only SPDX headers
  on own code (vendored shadcn excluded); SECURITY.md present.

## Gate status

- Stage 0: PASSED (2026-11-14).
- Stage 1: ENTERED, executed end-to-end, and **CLOSED 2026-11-14** at the
  Stage-2 entry gate.
- **Stage 2 (RE tooling): re-sequenced AFTER Stage 3** — PENDING; its
  entry gate (full-depth, ADV-LEGAL weighted; also Stage 3's exit gate)
  must settle: the DoD fix (define N + a two-session time-box), the
  placement ADR-012 (panel split recorded in CONSENSUS), and the RE
  tooling security contract. Stage IDs are stable.
- **Stage 3: ENTERED 2026-11-14. Fixtures-first: DONE 2026-11-14** (tripwire
  clock: working session 1 of the four-session total; the two-session
  parity box untouched). Next inside Stage 3: the boxed web parity set
  (QDI/LTCG stacking, NIIT, SALT phase-down, OBBBA senior deduction,
  student-loan interest, 8812-accurate CTC phase-out, cents rounding in
  `src/lib/tax/`), validated against `fixtures/tax/` from both engines.
- Owner decisions all stand: ADR-008 accept-and-document; ADR-009 feature
  parity; INTERNET add-and-disclose; PAT unchanged. ADR-010 closed. ADR-011:
  settings schemaVersion 2.

## Environment facts (sandbox)

- **Sandbox recycled again before this session** (third observed recycle):
  history INTACT this time (HEAD = origin/main, no squash), remote + PAT
  survived, `node_modules/` and `.next/` survived; `tools/` (Flutter SDK)
  was gone and snapshot file modes flipped (155 mode-only "modified"
  entries, zero content changes — `git restore .` per WORKFLOW §4).
  `bun.lock` reappeared (scaffolding) — now `.gitignore`d in the
  backup-scope block.
- **Flutter SDK 3.47.9 PRESENT** at `tools/flutter` — reinstalled
  2026-11-14 from the stable tarball (resuming curl loop; sha256 verified
  against a freshly fetched `releases_linux.json` — the guard-safe
  truncated form `25ed8c3c…` is written here deliberately: a full 64-hex
  string trips the backup script's raw-hex guard, per quirk 8; the full
  value is re-derivable from that JSON; revision c197ca5199, Dart 3.13.7).
  Download needed the resume loop as before (it stalls silently).
- Test suite: **77/77 green** (2026-11-14, Stage-3 fixtures-first session):
  61 hand-written (19 calculator, 8 cascade, 10 CSV, 3 JSON, 5 privacy,
  2 autosave regressions, 5 money-parsing, 6 step/settings guards, 3
  widget) + 16 golden fixtures via `golden_fixtures_test.dart`. `flutter
  analyze` clean. `npx tsc --noEmit` exit 0. Oracle
  `scripts/verify_golden_fixtures.py`: 16/16 fixtures, 0 field failures.
- Live-check quirk (unchanged): unauthenticated api.github.com is
  shared-rate-limited from this sandbox — use public HTML pages or
  sparing authenticated curl per WORKFLOW §5.
- Git identity: platform default (`z@container`). Remote auth: owner's
  fine-grained PAT in `.git/config` only (owner declined rotation —
  WORKFLOW §5).

## Hard-won quirks (do not relearn these)

1. **Widget tests + filesystem = hang** — FS work inside `testWidgets` must
   run in `tester.runAsync` (plain `test()` is unaffected — the golden
   fixture loader is plain `test()` and reads files freely).
2. `AppState.dispose()` idempotent; call before test-body return.
3. **Autosave contract:** `deleteReturn` cancels the debounce; timer
   callback identity-guarded; `_open` flushes the prior return's pending
   save on switch — pinned by three regression tests.
4. Dart `$` escaping; `file_picker` 13.x static API; `RadioGroup<T>`;
   static teal seed (`dynamic_color` unusable at 3.47).
5. `upload-artifact` path: workspace root, not working-directory.
6. Root `.gitignore` `/test` (not `test`).
7. **Sandbox recycles squash local history** (first recycle) or only flip
   modes (this one) — GitHub is source of truth; runbook WORKFLOW §4
   works (proven three times now).
8. Hex-blob heuristics: lockfiles excluded + `-I` text-only (bitmap bytes
   trip 64-hex). Token patterns scan binaries fine.
9. **Snapshot restores flip file modes to 755** — `git restore .` before
   committing (now also an unpushed-check pass in harness_check).
10. Blueprint regen: generator + playwright cover + merge (`mkdir -p
    download` on fresh clones); not byte-deterministic — never cite it as
    a reproducibility exemplar.
11. **Bulk scripted file edits must be re-verified immediately** — suite
    re-run before commit; never trust the tool's own report.
12. **The PAT is broader than its recorded profile** (Actions write/read
    observed); check permissions in the UI when rotating.
13. **Python `Decimal //` truncates toward zero** (unlike int floor
    division) — the 8812 next-$1,000 ceiling in the oracle uses the `+999`
    offset; the naive `-(-a//b)` idiom silently under-rounds (caught by a
    fixture mismatch, 2026-11-14).
14. **`expect()` outside a running test throws `OutsideTestException`**
    (even in `main()` before tests start) — structural fixture checks
    throw `StateError` instead (2026-11-14, golden test loader).
15. **Background `&` job chains lose the preceding `cd`** — `cd /tmp &&
    curl A & curl B` runs B in the OLD cwd; each download needs its own
    `cd … &&` or explicit output paths (2026-11-14, PDF fetches landing in
    the project root).

## Immediately next

**Stage 3, web parity set (boxed at two working sessions, tripwire
armed):** bring `src/lib/tax/` to the reference engine's feature set
(QDI/LTCG stacking, NIIT, SALT phase-down, OBBBA senior deduction,
student-loan interest, 8812 phase-out semantics, cents handling), validated
against the same `fixtures/tax/` files from the TS side; then the Stage-3
bridges (TXF import/exporter verification suite, `.clearfile.json`
versioning + guards). Exit gate = the RE-tooling stage's entry gate
(full-depth), which also carries ADR-012 + the RE DoD and reviews the
parity-tripwire outcome. Owner-side surfacings standing: Dependabot,
branch protection, PAT expiry (D30).
