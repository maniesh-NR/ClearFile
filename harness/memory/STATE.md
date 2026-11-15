# Current state (snapshot)

**Updated:** 2026-11-15 (after the owner-directed bridges session: TXF
import + `.tax` inspection + TXF exporter verification landed with the
Ghidra sandbox feasibility study; this session's closing backup is the tip)

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
  parity set: DONE 2026-11-15. Bridges: TXF import (Flutter) + TXF
  exporter verification (web, spec v042 codes fixed) + `.tax` read-only
  inspection (both codebases): DONE 2026-11-15** (owner-directed,
  ADR-013; the parity-tripwire box stayed closed under budget). Dart
  suite **95/95**; web parity 16/16; web bridge suite green (new in CI);
  `tsc --noEmit` clean. Remaining inside Stage 3: `.clearfile.json`
  versioning + guards + the `.cfr`→`.clearfile.json` unification
  decision, `docs/engine.md`, repo guided tour, discrepancy templates,
  project DoD. The Ghidra sandbox feasibility verdict (12.1.4 + JDK 21
  headless works, 11 s / 417 MiB measured) is recorded in
  `docs/ghidra-sandbox-feasibility.md` + RE protocol §4.E — pre-gate
  research for the Stage-2 entry gate (ADR-012 agenda).
- Owner decisions all stand: ADR-008 accept-and-document; ADR-009 feature
  parity; INTERNET add-and-disclose; PAT unchanged. ADR-010 closed. ADR-011:
  settings schemaVersion 2. ADR-013 (2026-11-15): bridges + Ghidra
  feasibility + Material You (dynamic_color 2.1.0 retry failed — ADR-007
  revisit closed with evidence).

## Environment facts (sandbox)

- **Sandbox recycled again before this session** (fifth observed recycle):
  history intact (HEAD = origin/main = the web-parity closing backup
  `769e57b`), content intact, `node_modules/` survived BUT its typescript
  bin did not (see quirk 18), Flutter SDK (`tools/`) gone — reinstalled.
- **`tools/` now carries**: Flutter SDK 3.47.9 (sha256 `25ed8c3c…`
  re-verified against `releases_linux.json`), **Ghidra 12.1.4** (the
  JDK-21 line; current-latest 12.2 requires JDK 25 and refuses this
  box), **Temurin JDK 21.0.13** (full JDK incl. `javac`), and the
  **`tools/re/` bench harness** (gen_demo.py, FindCryptoConstants.java,
  bench_poll.py, run_bench.sh) — all gitignored, all reinstallable via
  the documented fetchers.
- Test suite: **95/95 green** (Dart suite; 79 hand-written + 16 golden
  fixtures) — re-verified at teardown with `flutter analyze` clean. Web
  parity suite 16/16; **web bridge suite (`scripts/txf_taxfile_test.mjs`)
  6/6, first run, now wired into the hygiene `suites` job after the
  parity suite**; `npx tsc --noEmit` exit 0 (after restoring the local
  typescript bin, quirk 18).
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
17. **Background processes die when the Bash tool call ends** — a `nohup
    … &` fetcher survives only INSIDE the call that launched it (with its
    sleep/timeout window); across calls it is silently reaped. Long
    downloads must run foreground within one call (up to 10 min) or be
    relaunched per call; the `--speed-limit/--speed-time` resuming loop
    still applies (2026-11-15, Flutter tarball fetcher died with an empty
    log).
18. **Recycles can hollow `node_modules` selectively** — the directory
    survived the fifth recycle but `node_modules/.bin/tsc` did not, so
    `npx tsc` fetched the npm "tsc" squatter package and every
    compile-then-run suite failed locally; `npm install --no-save
    typescript@5` restores the bin without touching the lockfile
    (2026-11-15).

## Immediately next

**Stage 3 close-out** (bridges done 2026-11-15): `.clearfile.json`
versioning + guards + the `.cfr` vs `.clearfile.json` unification
decision; `docs/engine.md` (1040 line mapping + limitations register);
repo guided tour; discrepancy-report issue templates; the project
definition of done (ADV-PROD F5). Exit gate = the RE-tooling stage's
entry gate (full-depth, ADV-LEGAL weighted), which now has the measured
Ghidra-sandbox feasibility answer on its agenda (`docs/ghidra-sandbox-
feasibility.md`, protocol §4.E) alongside the DoD fix, placement
ADR-012, and the RE tooling security contract; it also records the
parity-tripwire outcome (box was NOT exceeded) and ADR-013's
dynamic_color negative retry. Owner-side surfacings standing: Dependabot,
branch protection, PAT expiry (D30).
