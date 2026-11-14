# Current state (snapshot)

**Updated:** 2026-11-15 (after the Stage-3 web-parity session — the TS
engine is a line-for-line port of the reference, 16/16 on the shared
golden fixtures; this session's closing backup is the tip)

## Repository

- GitHub: `maniesh-NR/ClearFile` (public), branch `main`. The Stage-3
  web-parity session's closing backup is the tip.
- Tag `v1.0.1` (release 445310560): published 2026-11-14 via the fresh-tag
  dispatch path — 11 assets including the first `SHA256SUMS.txt`, the
  Android INTERNET + macOS network-client fix, the network disclosure, and
  the hardened CI's first full green run. The tag points at exactly
  `0bbb564`. (Next tagged release owes D29's tag-PUSH verification.)
- `hygiene.yml`: gitleaks + harness_check on push/weekly/dispatch, plus
  the `suites` job (flutter analyze + test + npm ci + tsc), which also
  runs the golden-fixture oracle `scripts/verify_golden_fixtures.py` AND
  (2026-11-15) the web parity suite `scripts/web_parity_test.mjs`
  (compiles `src/lib/tax/` via `scripts/tsconfig.parity.json` to the
  gitignored `.parity-build/`, then asserts the TS engine against every
  fixture). All workflow actions SHA-pinned.
- Public tree: project-only; **`fixtures/tax/`** — 16 IRS-pinned golden
  `(TaxReturnData, TaxResult)` pairs (shared source of truth for both
  engines, per Stage 3 / ADR-009); 77-test Dart suite; web parity suite
  (16/16); GPL-3.0-only SPDX headers on own code (vendored shadcn
  excluded); SECURITY.md present.

## Gate status

- Stage 0: PASSED (2026-11-14).
- Stage 1: ENTERED, executed end-to-end, and **CLOSED 2026-11-14** at the
  Stage-2 entry gate.
- **Stage 2 (RE tooling): re-sequenced AFTER Stage 3** — PENDING; its
  entry gate (full-depth, ADV-LEGAL weighted; also Stage 3's exit gate)
  must settle: the DoD fix (define N + a two-session time-box), the
  placement ADR-012 (panel split recorded in CONSENSUS), and the RE
  tooling security contract. Stage IDs are stable.
- **Stage 3: ENTERED 2026-11-14. Fixtures-first: DONE 2026-11-14. Web
  parity set: DONE 2026-11-15** (tripwire clock: working session 2 of the
  four-session total; the two-session parity box closed in session 1 of 2,
  UNDER BUDGET). The web engine is a line-for-line port of the reference
  (QDI/LTCG stacking, NIIT, SALT phase-down, OBBBA senior deduction,
  student-loan interest, 8812-exact CTC phase-out, cents precision),
  validated against `fixtures/tax/` from the TS side — 16/16, zero field
  failures, in CI. TY2026 on the web side was dropped, not half-supported
  (D32). Remaining inside Stage 3: the bridges (TXF import + exporter
  verification, `.clearfile.json` versioning + guards + save-format
  unification decision, parser-hardening tests, `docs/engine.md`, guided
  tour, discrepancy templates, project DoD).
- Owner decisions all stand: ADR-008 accept-and-document; ADR-009 feature
  parity; INTERNET add-and-disclose; PAT unchanged. ADR-010 closed. ADR-011:
  settings schemaVersion 2.

## Environment facts (sandbox)

- **Sandbox recycled again before this session** (fourth observed recycle):
  same shape as the third — history INTACT (HEAD = origin/main = the
  fixtures-first closing backup `99d6823`), content intact, 174 mode-only
  flips (zero content changes; `git restore .` per WORKFLOW §4),
  `node_modules/` survived, Flutter SDK (`tools/`) gone — NOT reinstalled
  this session (the parity work is TS-side; reinstall when Dart work
  resumes, per the WORKFLOW §4 resuming-loop runbook).
- **Flutter SDK 3.47.9 ABSENT at `tools/flutter`** (reinstallable; last
  verified sha256 `25ed8c3c…` against `releases_linux.json` — the
  guard-safe truncated form per quirk 8; revision c197ca5199, Dart 3.13.7).
- Test suite: **77/77 green** (Dart suite; re-verified state at this
  session's teardown via the CI-pinned declarations) — 61 hand-written + 16
  golden fixtures via `golden_fixtures_test.dart`; plus, since 2026-11-15,
  the web parity suite: `node scripts/web_parity_test.mjs` — 16/16
  fixtures, 0 field failures — and the independent Decimal oracle 16/16.
  `npx tsc --noEmit` exit 0. Web smoke suite (`scripts/web_smoke.py`, incl.
  the persist v2 migration rehydrate path) 6/6 against the parity build.
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
16. **tsconfig `files`/`include` paths resolve relative to the tsconfig's
    own directory, not the invoking cwd** — `scripts/tsconfig.parity.json`
    needs `../src/...` prefixes even when tsc is run from the repo root
    (2026-11-15, parity suite first run failed on `scripts/src/...`).

## Immediately next

**Stage 3, the bridges** (parity set closed 2026-11-15, under the
tripwire's two-session box; working sessions consumed: 2 of 4): TXF
import (Flutter) + a verification suite for the existing TXF exporter
(web); `.clearfile.json` schema versioning + migration + **version guard
before any format change ships** (ADV-ENG #11 — the `.cfr` v2 migration
this session is the web-local precedent); the save-format unification
decision (`.cfr` vs `.clearfile.json`); parser-hardening tests for the
first shipped untrusted-input parsers; `docs/engine.md` (1040 line
mapping + limitations register), repo guided tour, discrepancy-report
issue templates, and the project definition of done (ADV-PROD F5). Exit
gate = the RE-tooling stage's entry gate (full-depth), which also carries
ADR-012 + the RE DoD and reviews the parity-tripwire outcome (box was
NOT exceeded — record that at the gate). Owner-side surfacings standing:
Dependabot, branch protection, PAT expiry (D30).
