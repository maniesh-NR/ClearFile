# Current state (snapshot)

**Updated:** 2026-11-15 (Stage-3 close-out session: ADR-015 — unified
return format with version guard + migration + sealed import outcomes;
`docs/engine.md`, `docs/tour.md`, discrepancy templates, the project DoD
adopted; Stage 3 execution COMPLETE, exit gate is next; this session's
closing backup is the tip)

## Repository

- GitHub: `maniesh-NR/ClearFile` (public), branch `main`. Tip at this
  session's start: the UI-stack closing backup `935f782`; this session's
  closing backup supersedes it.
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
  placement ADR-012 (panel split recorded in CONSENSUS), the RE
  tooling security contract, and the native re-platforming settlement
  (ADR-014: scope, sequencing, budget for the per-OS stacks + shared
  Rust core — see ROADMAP's Stage-2 agenda). Stage IDs are stable.
- **Stage 3: ENTERED 2026-11-14. Fixtures-first: DONE 2026-11-14. Web
  parity set: DONE 2026-11-15. Bridges: DONE 2026-11-15. Close-out:
  DONE 2026-11-15 (ADR-015) — unified return format + engine.md + tour
  + discrepancy templates + project DoD — EXECUTION COMPLETE; the exit
  gate (the RE stage's entry gate) is the next event.** Tripwire: box
  NOT exceeded; slip FIRED (gate not convened within the four working
  sessions) → web-freeze returns to the gate agenda as a mandatory item.
  Dart suite **111/111** (95 hand-written + 16 golden); web parity
  16/16; bridge suite 10 groups (now includes the unified-format cfr
  section); oracle 16/16; smoke 6/6; `tsc --noEmit` clean.
  The Ghidra sandbox feasibility verdict (12.1.4 + JDK 21
  headless works, 11 s / 417 MiB measured) is recorded in
  `docs/ghidra-sandbox-feasibility.md` + RE protocol §4.E — pre-gate
  research for the Stage-2 entry gate (ADR-012 agenda).
- Owner decisions all stand: ADR-008 accept-and-document; ADR-009 feature
  parity; INTERNET add-and-disclose; PAT unchanged. ADR-010 closed. ADR-011:
  settings schemaVersion 2. ADR-013 (2026-11-15): bridges + Ghidra
  feasibility + Material You (dynamic_color 2.1.0 retry failed — ADR-007
  revisit closed with evidence). ADR-014 (2026-11-15, second directive of
  that day): per-OS native UI stacks (Win32+Direct2D / Swift+AppKit /
  gtk-rs·gtk3-rs·Slint·Qt / Android Views+KMP) over a shared Rust core,
  Material You with OS-specific elements — direction recorded, execution
  gated (settlement assigned to the Stage-2 entry gate's agenda). ADR-015
  (2026-11-15): unified ClearFile return file (`.clearfile.json` envelope,
  version guard, migration matrix, sealed import outcomes) — D1 closed,
  D3's guard rule closed.

## Environment facts (sandbox)

- **Sandbox recycled again before this session** (seventh observed
  recycle): history intact (HEAD = origin/main = the UI-stack closing
  backup `935f782`), content intact (183 files mode-flipped to 755 —
  normalized with `git restore .` BEFORE any edits, quirk 19),
  `node_modules/` survived WITH its typescript bin, `tools/` gone —
  **Flutter SDK 3.47.9 reinstalled via the new durable
  `scripts/fetch_flutter_sdk.sh`** (sha256 `25ed8c3c…` verified against
  `releases_linux.json`; one call, 81 s download). Ghidra/JDK remain
  uninstalled this session (not needed; reinstallable via the documented
  fetchers).
- **`tools/` now carries**: Flutter SDK 3.47.9 (sha256 `25ed8c3c…`
  verified against `releases_linux.json` via
  `scripts/fetch_flutter_sdk.sh`). Gone again after the seventh recycle
  and NOT reinstalled: **Ghidra 12.1.4** (the JDK-21 line;
  current-latest 12.2 requires JDK 25 and refuses this box), **Temurin
  JDK 21.0.13** (full JDK incl. `javac`), and the **`tools/re/` bench
  harness** (gen_demo.py, FindCryptoConstants.java, bench_poll.py,
  run_bench.sh) — all gitignored, all reinstallable via the documented
  fetchers (`tools/re/run_bench.sh` is the one-command benchmark
  rerun after a reinstall).
- Test suite: **111/111 green** (Dart suite; 95 hand-written + 16 golden
  fixtures) — re-verified at THIS session's teardown (`flutter analyze`
  clean; the 16 new tests: 14 return-format + 2 container). Web
  parity suite 16/16; **web bridge suite (`scripts/txf_taxfile_test.mjs`)
  10 groups (6 prior + 4 new cfr groups)**; oracle 16/16; web smoke 6/6;
  `npx tsc --noEmit` exit 0 — all re-run this session.
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
19. **`git restore .` reverts unstaged CONTENT edits too, not just
    mode flips** — running it after making working-tree edits (the
    post-recycle mode normalization) silently deletes those edits; it
    reverts the working tree to the INDEX, and the index still holds
    HEAD. Normalize modes FIRST (or stage edits, or scope the restore
    to the mode-flipped paths only) before editing (2026-11-15, this
    session: the four ADR-014 doc edits were wiped once and redone).

## Immediately next

**Convene the Stage-2 entry gate (= Stage 3's exit gate)** — full-depth,
ADV-LEGAL weighted. Its agenda (ROADMAP Stage-2): the DoD fix (define N
+ two-session time-box), placement ADR-012 (panel split recorded), the
RE tooling security contract, the native re-platforming settlement
(ADR-014), and — mandatory, the tripwire slip FIRED 2026-11-15 — the
web-freeze question must be argued explicitly (owner may keep parity
via a recorded decision, not silence). The gate also reviews Stage 3's
execution evidence (this session's close-out included) and the
parity-tripwire outcome (box NOT exceeded). Owner-side surfacings
standing: Dependabot, branch protection, PAT expiry (D30).
