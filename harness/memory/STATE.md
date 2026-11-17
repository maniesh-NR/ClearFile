# Current state (snapshot)

**Updated:** 2026-11-17 (Stage-2 entry gate session — the full-depth gate
that also closed Stage 3: 4 × PROCEED-WITH-CONDITIONS, unanimous; the
ADR-014 re-platforming settlement recorded as ADR-017, the tripwire
disposition as ADR-016, placement as ADR-012, the Stage-2 DoD and
security contract recorded; ENG-1/ENG-2/SEC-1/SEC-3 gate-condition fixes
applied in-session; this session's closing backup is the tip)

## Repository

- GitHub: `maniesh-NR/ClearFile` (public), branch `main`. Tip at this
  session's start: the Stage-3 close-out backup `a18b160`; this session's
  closing backup supersedes it. One inherited anomaly, found and resolved
  in-session BEFORE any edits: an unlogged 2026-11-16 session had left an
  **unpushed, mode-only amend** (`4d4e1d6` — 191 files 644→755, zero
  content delta); resolved by `git reset --hard` to the pushed tip
  `a18b160` (contents identical; canonical modes preserved; fast-forward
  chain intact) — recorded as a dated SESSION_LOG note (SEC-2).
- Tag `v1.0.1` (release 445310560): published 2026-11-14; 11 assets
  including the first `SHA256SUMS.txt`, the Android INTERNET + macOS
  network-client fix, the network disclosure, and the hardened CI's first
  full green run. The tag points at exactly `0bbb564`
  (re-verified live via `git ls-remote` this session). (The next tagged
  release owes D29's tag-PUSH verification — planned as the **v1.1 tag,
  Stage 5's closing event** per the gate's PROD recommendation.)
- `hygiene.yml`: gitleaks + harness_check on push/weekly/dispatch, plus
  the `suites` job (flutter analyze + test + npm ci + **`npm audit
  --omit=dev --audit-level=critical` dependency gate (added this session,
  SEC-1 — fail-closed on any production-tree critical advisory)** + tsc
  + golden-fixture oracle + web parity suite + bridge suite). All
  workflow actions SHA-pinned (all 7 pins re-resolved live against
  upstream tags by ADV-SEC this session — every pin exact).
- Public tree: project-only; **`fixtures/tax/`** — 16 IRS-pinned golden
  `(TaxReturnData, TaxResult)` pairs (shared source of truth for both
  engines, per Stage 3 / ADR-009, and designated the future Rust core's
  regression contract by ADR-017); GPL-3.0-only SPDX headers on own code
  (vendored shadcn excluded); SECURITY.md present.

## Gate status

- Stage 0: PASSED (2026-11-14).
- Stage 1: ENTERED, executed end-to-end, and CLOSED 2026-11-14 at the
  Stage-2 entry gate.
- **Stage 2 (RE tooling): ENTERED 2026-11-17** at the full-depth
  ADV-LEGAL-weighted Stage-2 entry gate (4 × PROCEED-WITH-CONDITIONS,
  unanimous — reports `adversarial/reports/2026-11-17-stage2-*.md`, gate
  record in `adversarial/CONSENSUS.md`). Every mandatory agenda item was
  settled there: the DoD (N = 4 named `docs/formats/` specs —
  clearfile-json family, exchange container, TXF profile, modern `.tax`
  shape — in a two-working-session hard time-box); placement ADR-012
  (IN-REPO with six binding mechanics that land with the first tooling
  commit, else revert to a separate research repo); the security
  contract (recorded verbatim in ROADMAP's Stage-2 entry conditions);
  the native re-platforming settlement (ADR-014 → ADR-017); and the
  parity-tripwire disposition (ADR-016). **Execution begins with the
  first Stage-2 tooling commit carrying the entry conditions** (the
  ADR-012 mechanics (a)–(f), the LEGAL-1 mechanics, and ENG-3's
  survivingSpouse golden fixture in the first execution session).
- **Stage 3: CLOSED 2026-11-17** (entered 2026-11-14, executed
  end-to-end — fixtures → parity → bridges → close-out, ADR-015 — and
  formally closed at the same gate after unanimous live verification of
  the execution evidence; the tripwire outcome — box NOT exceeded, slip
  FIRED — was reviewed and disposed as ADR-16's maintenance freeze).
- **Epilogue native program N1–N6 (ADR-017): PENDING/unfunded** — the
  ADR-014 re-platforming settlement is recorded (staged per-OS over the
  Rust core, a finite post-Stage-6 program with its own gates; entered
  only when the owner funds it; the Rust core alone may run parallel to
  Stage 4+ behind its own gate). **No native-stack code exists**; the
  Flutter app and web prototype remain the live implementation, exactly
  as the ROADMAP matrix says.
- Owner decisions all stand: ADR-008 accept-and-document; ADR-009 feature
  parity — **narrowed to maintenance parity by ADR-016 (2026-11-17, the
  tripwire settlement; owner-overrule path recorded)**; INTERNET
  add-and-disclose; PAT unchanged. ADR-010 closed. ADR-011: settings
  schemaVersion 2. ADR-013 (2026-11-15): bridges + Ghidra feasibility +
  Material You. ADR-014 (2026-11-15): the per-OS native stack direction
  — **settled by ADR-017 at this gate**. ADR-015 (2026-11-15): the
  unified return file. ADR-012/016/017 (2026-11-17): placement, tripwire
  disposition, re-platforming settlement.

## Environment facts (sandbox)

- **Ninth-recycle era observed before this session**: history intact,
  content intact; `tools/` gone again (Flutter SDK reinstalled via the
  hardened `scripts/fetch_flutter_sdk.sh` — manifest-sha256 verified; the
  tar quirk below now tolerated, smoke test authoritative);
  `node_modules/` survived WITH its typescript bin. Ghidra/JDK remain
  uninstalled (reinstallable via the documented fetchers when RE Phase-4
  work needs them; the measured feasibility verdict stands in
  `docs/ghidra-sandbox-feasibility.md`).
- The 2026-11-16 mode-flip evidence (191 files 755 after the eighth
  recycle) was folded into an unpushed amend by a brief unlogged session
  instead of being normalized — see the Repository section above; quirk
  9's normalize-first practice is reaffirmed, and WORKFLOW §4 step 5 now
  requires `harness_check.sh` at recycle verification (ENG-7).
- Test suite: **113/113 green** (Dart; 97 hand-written + 16 golden) —
  re-verified at THIS session's teardown after the gate's ENG-1/ENG-2
  fixes (`flutter analyze` clean; the 2 new tests: the crafted
  truncated-central-directory never-throws guard + the TXF
  10,000-record refusal). Web parity 16/16; bridge suite 10 groups;
  oracle 16/16; web smoke 6/6; `npx tsc --noEmit` exit 0;
  `npm audit --omit=dev --audit-level=critical` exit 0 (0 criticals
  after the in-session `npm audit fix`; 6 moderate/high remain
  visible, non-gating, need breaking changes) — all re-run this session
  against the fixed dependency tree.
- Live-check quirk (unchanged): unauthenticated api.github.com is
  shared-rate-limited from this sandbox — use public HTML pages or
  sparing authenticated curl per WORKFLOW §5. The gate's four reviewers
  all avoided the PAT (one hit the rate limit and said so in its
  report).
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
   modes (these ones) — GitHub is source of truth; runbook WORKFLOW §4
   works (proven repeatedly).
8. Hex-blob heuristics: lockfiles excluded + `-I` text-only (bitmap bytes
   trip 64-hex). Token patterns scan binaries fine.
9. **Snapshot restores flip file modes to 755** — normalize (`git restore
   .` or `git reset --hard <pushed-tip>`) before committing and before
   editing (now also an unpushed-check pass in harness_check). Never
   commit the flips into history (the 2026-11-16 amend lesson).
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
    repo: the four ADR-014 doc edits were wiped once and redone).
20. **This snapshot FS makes tar's trailing directory-status-restore pass
    fail benignly** — "Directory renamed before its status could be
    extracted" AFTER every file extracts; the tarball's manifest sha256
    still verifies and the SDK binary works (analyze/test green prove
    it). `scripts/fetch_flutter_sdk.sh` is hardened accordingly: tar's
    nonzero exit is tolerated with a note, the sha256 stays strict, and
    the `flutter --version` smoke test is the authority (2026-11-17,
    Stage-2 entry gate SEC-3/ENG-5; verified end-to-end twice).

## Immediately next

**Stage-2 (RE tooling) execution, session 1** — the first tooling commit
carries the entry conditions recorded at the gate (ROADMAP Stage-2):
- the **ADR-012 mechanics (a)–(f)**: the enumerated gitignored
  `fixtures/re/` synthetic fixture path; the allow-listed no-binary-blob
  CI assertion with the synthetic/owner-authored provenance distinction;
  the same allow-list wired into `scripts/sandbox_backup.sh`; the
  `git check-ignore` and release.yml-tooling greps in harness_check;
- the **LEGAL-1 mechanics**: synthetic-only unit fixtures, the
  differential tool's provenance-manifest refusal, the backup hex guard
  widened to ≥32-hex on RE-adjacent paths (UUID/known-hash allow-list),
  the `docs/formats/*.md` provenance lint;
- the tools themselves per the recorded security contract (write-free,
  resource-bounded, crash-safe — ENG-1's crafted file is the
  crash-battery template);
- **ENG-3: the survivingSpouse golden fixture** (all three runners);
- and the first `docs/formats/` spec toward the DoD (N = 4, two-session
  box). The owner states the owned corpus (product/version/year/count)
  at kickoff so N is real.

Owner-side surfacings standing: Dependabot alerts, branch protection on
`main`, PAT expiry (D30). The epilogue native program (ADR-017) is
PENDING/unfunded — it moves only when the owner funds it with sessions;
the v1.1 tag is Stage 5's closing event and does not wait for it.
