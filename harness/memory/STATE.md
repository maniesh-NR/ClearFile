# Current state (snapshot)

**Updated:** 2026-11-23 (final — Stage-2 EXECUTION session 2, the box's
second and final session: specs 2 + 3 of the N=4 DoD published
(`tax-exchange-container.md`, `txf.md` — both §7.5-clean/lint-clean;
`tax-modern.md` awaits T3 exactly as planned, no stub written); D34
CLOSED (the shared `fixtures/migration/` family consumed by BOTH suites
asserting exact ordered warning lists; the web reader's dependent-count
clamp aligned to the Dart reference's 0..100 bound — the recorded edge
drift fixed, not just documented; the store-vs-file W-2 shape documented
in return-format.md §3); the 23rd RE-tool test (the exchange-container
differential pair inside mandatory family #2); the execution box closed
at exactly two sessions; the fifteenth recycle wiped tools/ — the Flutter
SDK re-fetched + sha256-verified; the TT corpus + Ghidra bench re-acquired
at the next T2/Phase-4 session)

## Repository

- GitHub: `maniesh-NR/ClearFile` (public), branch `main`. Tip at this
  session's start: the Stage-2 entry-gate backup `c4982d1`; this session's
  closing backup supersedes it. One inherited anomaly, found and resolved
  in-session BEFORE any edits (the SECOND of its class): an unlogged
  2026-11-20 session had left an **unpushed, mode-only amend** (`f1af2d4` —
  195 files 644→755, zero content delta, message identical); resolved by
  `git reset --hard` to the pushed tip `c4982d1` — recorded as a dated
  SESSION_LOG note and in PROJECT_MEMORY.md's quirk shortlist.
- **TT RE bench + corpus (ADR-019, 2026-11-22, gitignored tools/):** the
  four installer targets (tools/re-corpus/, ~1.4 GB; manifest +
  `scripts/fetch_tt_corpus.sh` re-acquire after recycles — with
  mechanical sha256 verification against the manifest), REA 6.10.1
  (tools/rea) over Ghidra 12.2 + Temurin 25 (REA hard-requires ≥12.2 →
  JDK 25). **Thirteenth recycle WIPED tools/** (the twelfth's survival
  was the exception, not the rule — the standing expectation stands);
  re-acquired + rebuilt this session (corpus fetcher 4/4 sha256-verified;
  Ghidra 12.2 + Temurin 25.0.5.1 + REA 6.10.1 clone/build ≈ 19 s;
  `rea doctor --provider ghidra` healthy; the stub re-carved and the
  checkpoint re-established). T2 chase artifacts under tools/re/.
  Notes: `docs/re-research/2026-11-22-tt-{targets-phase1,tt-t2-reader,
  tt-t2-session2}.md`.
- **Stage-2 EXECUTION session 1 (2026-11-22, this session):** the first
  tooling commit landed with every entry condition recorded at the
  2026-11-17 entry gate. ENG-3/D33: the survivingSpouse (QSS) golden
  fixture #17 (`fixtures/tax/16-surviving-spouse-qss-mapped-thresholds
  .json`, pins verified from Pub 501 / QDIVCG worksheet lines 6+13 /
  Topic 559 / Form 8812 line 9) **found and forced a live bug: the QSS
  CTC phase-out start is $200,000 (“All other filing statuses”,
  8812 line 9 — QSS “doesn't entitle you to file a joint return”
  per Pub 501), not the MFJ $400,000 both engines carried** — fixed in
  tax_year.dart + config.ts + the oracle (+ docs/engine.md). Phase 1–3
  RE tools (re_entropy / re_magic / re_diff — write-free, capped with
  refusal tests, crash-safe, §7.1 provenance-manifest gate) + the 22-test
  unit suite (synthetic fixtures under gitignored fixtures/re/) + the
  ADR-012 mechanics (a)–(f) (blob assertion + allow-list in CI AND in
  sandbox_backup.sh; fixtures/re/ gitignored; release.yml RE-free —
  harness_check family 7) + the LEGAL-1 mechanics (manifest refusal,
  lint_format_specs) + `docs/formats/clearfile-json.md` (DoD spec 1 of
  4, §7.5-clean). PROD-2 DISCHARGED.
- **Stage-2 EXECUTION session 2 (2026-11-23, the box's final one):** specs
  2 + 3 of the N=4 DoD published — `docs/formats/tax-exchange-container.md`
  (the owner-authored `.tax`-extension STORE-only ZIP exchange container:
  provenance, the writer/reader field layout, the honest-labeling
  disclosure, the analysis behavior, code anchors both sides, and a
  differential note pinned by a NEW test) and `docs/formats/txf.md`
  (ClearFile's TXF v042 profile: the grammar as implemented, the full
  refnum table, the reader contract incl. the four hard refusals, the
  writer profile, the bridge-suite verification mirror) — both §7.5-clean
  + lint-clean. D34 closed: `fixtures/migration/` (the identical v1
  sample + the edge-clamp fixture + the provenance README) consumed by
  BOTH suites asserting EXACT ordered warning lists (return_format_test
  15 tests; bridge 11 groups); the web reader's dependent-count clamp
  aligned to 0..100 (the D34-recorded drift, pinned by the edge fixture
  on both sides); the store-vs-file W-2 shape difference documented in
  docs/return-format.md §3. `test_re_tools.py` grew to 23 tests (the
  exchange-container differential pair: one wage digit ⇒ exactly 3
  regions — payload byte + the two CRC-32 couplings). The execution box
  is CLOSED at exactly two sessions; the EXIT gate convenes when T3's
  findings allow `tax-modern.md` (the checklist is otherwise green).
- **Root `PROJECT_MEMORY.md` + `update_memory.py` (ADR-018, 2026-11-22):**
  the engineering memory layer (stack rules / playbook / verification
  contracts / rolling git-activity window; stat-mode, idempotent,
  verified 16 KB) — the pstack token-efficiency protocol, layered over
  `harness/` governance without contradicting it.
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
- Public tree: project-only; **`fixtures/tax/`** — 16→17 IRS-pinned golden
  `(TaxReturnData, TaxResult)` pairs (shared source of truth for both
  engines, per Stage 3 / ADR-009, and designated the future Rust core's
  regression contract by ADR-017) + **`fixtures/migration/`** (D34: the
  shared v1→v2 migration fixtures with the provenance/contract README);
  GPL-3.0-only SPDX headers on own code (vendored shadcn excluded);
  SECURITY.md present.

## Gate status

- Stage 0: PASSED (2026-11-14).
- Stage 1: ENTERED, executed end-to-end, and CLOSED 2026-11-14 at the
  Stage-2 entry gate.
- **Stage 2 (RE tooling): ENTERED 2026-11-17, EXECUTION BOX CLOSED
  2026-11-23 at exactly two sessions** (session 1: 2026-11-22 — the first
  tooling commit with every entry condition + the QSS fixture/engine fix
  + spec 1 of 4; session 2: 2026-11-23 — specs 2+3 of 4 + D34 + the 23rd
  RE-tool test). The EXIT gate itself awaits `tax-modern.md` (spec 4,
  behind T3's format-family findings incl. the password layer — no stub
  was written); the checklist is otherwise green: 3 of 4 named specs
  present + §7.5-clean, ≤2 execution sessions (exactly 2), refusal/cap
  tests green, blob assertion green.
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
- **TT-compatibility program (ADR-019 + ADR-020): T2 ENTERED 2026-11-22**
  at its own gate (4 × PROCEED-WITH-CONDITIONS, unanimous; T1 complete
  and verified at the gate). Stage-2's DoD box is NOT grown — TT specs
  never count toward N=4 (the namespace rule is in ROADMAP's TT
  section).
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

- **Fifteenth recycle at this session's bootstrap** (tools/ wiped — the
  Flutter SDK re-fetched via the resumable fetcher + sha256-verified
  across two tool calls; the TT corpus + Ghidra bench gone as standing
  expectation — the next T2/Phase-4 session re-acquires the corpus via
  `scripts/fetch_tt_corpus.sh` (sha256-verified vs the manifest) and
  rebuilds the bench per the recorded ~19 s clone/build). Clean tree at
  bootstrap, no mode flips, no unpushed amends; node_modules incl.
  `.bin/tsc` SURVIVED (no mid-session hollowing this time). Disk 6.7 GB
  free at bootstrap / ~4.1 GB at close (the SDK resident) — the watch
  item improved.
- The 2026-11-20 mode-flip evidence (195 files 755 after the tenth
  recycle) was folded into an unpushed amend by a brief unlogged session
  instead of being normalized — the SECOND such incident (first:
  2026-11-16, 191 files); see the Repository section above. Quirk 9's
  normalize-first practice is reaffirmed; WORKFLOW §4 step 5 already
  requires `harness_check.sh` at recycle verification (ENG-7), and
  PROJECT_MEMORY.md's quirk shortlist now carries the pattern for
  protocol-layer sessions. This session's bootstrap found the
  **thirteenth-recycle mode flips (205 files 644→755, zero content
  delta, no unpushed amend)** — normalized with `git restore .` BEFORE
  any edits (quirk 19 held).
- Test suite: **115/115 green** (Dart; 98 hand-written + 17 golden) —
  RE-RUN this session, not carried: the session TOUCHED code paths
  (`cfr.ts` migration clamp + `return_format_test.dart` fixture-based
  tests + the bridge suite's fixture groups). The full local battery is
  green this session: flutter analyze clean; flutter test 115/115;
  **tsc --noEmit exit 0**; web parity **17/17**; bridge **11/11** (the two
  new D34 fixture groups); oracle **17/17**; web smoke **6/6**; `npm audit
  --omit=dev --audit-level=critical` exit 0; RE tool tests **23/23** (the
  new container-pair differential); `check_binary_blobs` clean (323
  tracked at tip + 5 new text files this session / 28 allow-listed);
  `lint_format_specs` 3/3 clean; harness_check 0 failures. CI runs on
  this push.
- Live-check quirk (unchanged): unauthenticated api.github.com is
  shared-rate-limited from this sandbox — use public HTML pages or
  sparing authenticated curl per WORKFLOW §5. CI on `52e2c68` was not
  re-verified this session for that reason (the TT gate's orchestrator
  note records it); CI runs on this gate's own push.
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

**T2 session 3 (the TT program's next working session):** the
InstallShield-layer record walk (D40) — the ISSetupStream v7/v8 payload
record format (USA + CAN-Personal inner installers) + the CAN-Business
classic file-group record framing (from ≈0xefa00); then the app-module
inventory where the file-format/password routines live, and the UI
functional-layout study (text-only IA records, §7.4). **Re-acquire the
corpus + rebuild the Ghidra bench first** (the fifteenth recycle wiped
tools/: `scripts/fetch_tt_corpus.sh` with sha256 verification vs the
manifest; Ghidra 12.2 + Temurin 25 re-download; REA clone/build ≈ 19 s;
the checkpoint re-established). T3's format-family findings (incl. the
password layer) then unlock `tax-modern.md` (DoD spec 4) and the
Stage-2 EXIT gate — the checklist is otherwise green (3 of 4 named specs
§7.5-clean, exactly 2 execution sessions elapsed, refusal/cap tests
green, blob assertion green).

Owner-side surfacings standing: Dependabot alerts, branch protection on
`main`, PAT expiry (D30). The epilogue native program (ADR-017) is
PENDING/unfunded — it moves only when the owner funds it with sessions;
the v1.1 tag is Stage 5's closing event and does not wait for it.
