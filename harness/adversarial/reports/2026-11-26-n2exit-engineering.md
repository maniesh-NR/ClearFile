# ADV-ENG — N2 exit gate (2026-11-26, Task N2-EXIT-ENG)

Scope: the ENG lane of the N2 exit gate (the re-convening after the first
run's subagent-context deadline). Tip 8478a09 verified, working tree clean.
The gate's CI pending item (the live-green hygiene run) was already
discharged before this run: hygiene run #44 green on a592b06, all five
jobs. The other three reports' verdict lines (read ONLY those): ADV-SEC
PROCEED-WITH-CONDITIONS, ADV-LEGAL PROCEED-WITH-CONDITIONS (6), ADV-PROD
PROCEED-WITH-CONDITIONS — no BLOCK anywhere.

VERDICT: PROCEED-WITH-CONDITIONS

## Conditions

1. The JSON member cap closes the registered wide-object quadratic but
   leaves a residual CPU-amplification surface: duplicate keys over a
   max-width (10,000-member) object still scan up to 10,000 key
   comparisons per occurrence (≈ seconds-to-minutes of single-core parse
   for a crafted 10–100 MB file; a local-UI freeze, recoverable, no
   memory amplification beyond O(file size)) — the next session must
   either bound it (a duplicate-scan work budget or an indexed lookup
   past a threshold, with a battery extension) or record the accepted
   residual in the risk register with the local-app rationale.
   Verification: the bounding code + battery test pinning whichever
   bound lands, OR the STATE/risk-register entry naming the residual —
   greppable in the N3 delta (search "duplicate" near json.rs or the
   risk register; a bare absence of both is the condition unmet).

## Risks register

- R-ENG-1 (the condition's subject, low-medium, local-only): the
  duplicate-key linear scan is O(distinct members) per key occurrence
  with distinct members capped at 10,000 — bounded but large; the app
  reads any user-supplied file (main.rs `std::fs::read` → parse) with
  no upstream size cap, so the freeze duration scales with hostile-file
  size. Recoverable (kill the app); the writer/store paths are
  unaffected; the failure mode is slowness, never a panic or error.
- R-ENG-2: `run_window` calls `load_and_compute` synchronously on the
  UI thread before the event loop (apps/linux/src/main.rs:387) — any
  large/hostile file freezes window construction for the parse's
  duration (same class as R-ENG-1 plus honest disk I/O). A
  worker-thread handoff is the eventual fix; prototype-acceptable now,
  re-visit when real import paths harden.
- R-ENG-3: the STORE-cap battery allocates a real ~257 MiB container
  (documented in-test: one shared 1 MiB buffer, no per-entry copies)
  and accounts for ~8.5 s of the suite's runtime — acceptable; if it
  ever becomes CI-painful, a forger that aliases shared STORE bytes
  (the code path the cap exists for) can pin the same boundary at a
  fraction of the footprint.
- R-ENG-4 (accepted, guarded): `TooManyMembers`'s Display hardcodes
  "10,000-member" beside `MAX_OBJECT_MEMBERS` — if the cap ever moves,
  the string must move with it; the error-display test pins the exact
  wording, so drift is CI-caught either way.

## Advisories

- The palette-formula spot-check ran against the pub-cache copy of
  material_color_utilities 0.13.0 (the gone /tmp/mcu-0.13.0's
  replacement — the same pinned version whose content hash
  9c337007…c48b the corpus README and clearfile/pubspec.lock record);
  the spot-checks corroborate, but the 22,242-check corpus parity
  (19,998 ladder tones + 2,244 role ARGBs) remains the evidence of
  record.
- Grep `#[test]` in fixtures_runner.rs reads 44, but two are
  doc-comment mentions; the live count is 42 (verified by the run
  below) — count audits should use the test-result lines, not grep.
- The CONSENSUS ledger says PROD-5 while the PROD report's own header
  says 7 conditions — an owner-side reconciliation at the re-convening
  (record-level; not ENG's to fix, flagged in passing).
- The window smoke's `|| ( … && exit 1)` chains rely on shell
  left-associativity; walked: `exit 1` is reached on every branch
  including kill failure, and the success path kills Xvfb too — correct
  as written, no change needed.
- The app re-build was skipped per the task's own budget rule (the
  sandbox had ~3.9 GB free — marginal for a second full slint tree);
  CI run #44 green is the authoritative app-lane evidence, and the
  pipeline-sharing audit below is code-identity based.

## Spot-audit findings (the task's four lanes, all pass)

1. **Hardening caps (correct).** json.rs: the member-cap check sits in
   the None (new-member) branch after the duplicate scan (parse_object,
   :502–517) — duplicates update the existing slot in place, never grow
   `pairs.len()`, never trip the cap (pinned by
   `parse_object_member_cap_fail_closed` at the 10,001st NEW member,
   with offset + count asserted, and
   `parse_object_member_cap_exactly_10_000_parses` at the boundary).
   tax_inspect.rs: `extracted + size > MAX` stops the walk BEFORE
   extracting the tripping entry (:637–650) — the boundary entry is not
   extracted and therefore not listed (honest listing), the analysis
   path never errors; battery: 257×1 MiB stops at 256 entries with the
   exact "Extraction stopped after 268435456 bytes …" note, the
   2×100 MiB just-under twin extracts fully with no note.
2. **Palette port structural honesty (correct).** All three declared
   divergences are present with rationale: the TonalPalette `_cache`/
   `keyColor` drop (:1214–1222, pure recompute-only-outputs rationale),
   the RoleWiring enum restructure for Dart's `!`-asserted nullables,
   and the dropped `_isFidelity`/`_isMonochrome` arms with named Dart
   line ranges (:1372–1380 — constant-false for Variant.tonalSpot).
   Spot-checked verbatim against the Dart 0.13.0 source: `primary`,
   `onPrimary`, `primaryContainer`, `onPrimaryContainer` (tones,
   backgrounds, ContrastCurve constants, ToneDeltaPair args), the full
   seven-rung surface-container ladder (all fourteen ContrastCurve
   constants), `ContrastCurve.get` lerp breakpoints,
   `foregroundTone` incl. the negligible-difference edge, and the
   ToneDeltaPair resolution (delta expansion, stayTogether push,
   awkward-zone 49/60 handling) — every constant and branch matched.
3. **App pipeline sharing (correct).** ONE `load_and_compute` (main.rs
   :54); the window path (:387), `run_headless` (:424), and every test
   (:467, :562, :582, :590) call the same symbol — no reimplementation
   exists in the file; the smoke constructs the window only.
4. **CI job correctness (correct; run #44 green corroborates).** The
   rustc guard strips the `rustc ` prefix, cut-splits major/minor,
   fails closed on non-numeric fields, and the comparison
   (`<1 || (==1 && <95)`) puts 1.94 fail-side, 1.95/2.x pass-side of
   the boundary; the headless smoke diffs the FULL stdout against the
   committed expected text; the window smoke runs under `timeout 60`
   with failure asserted (exit-status branch + the
   window-smoke-ok marker grep) and kills Xvfb on both paths
   (left-associativity walked); the cargo-deny step is SHA-pinned
   (81891abc…74fda, v2.1.4) over the committed lock; the N2 delta to
   hygiene.yml is purely additive (96 insertions, 0 deletions — the
   existing four jobs byte-identical). deny.toml carries the closed
   GPL-3.0-only-compatible allow-list (the BSL-1.0 join comment names
   the encounter), the Slint GPL-3.0-only election note,
   crates.io-only sources, yanked=deny, wildcards=warn naming the
   clearfile-core path-dep seam.

## Files read + verification log

Files read: harness/adversarial/CONSENSUS.md (tail — the N2 exit-gate
record), harness/memory/SESSION_LOG.md (tail — the N2 session 1/2 and
CI-green entries), core/src/json.rs (cap + battery), core/src/
tax_inspect.rs (cap), core/tests/tax_inspect_port.rs (the two
STORE-cap battery tests + the 4,096 walk-cap test), core/src/palette.rs
(module headers, the TonalPalette/RoleWiring/divergence notes, the
spec() role table, foreground_tone, the ToneDeltaPair resolution),
core/tests/palette_port.rs (all four tests), apps/linux/src/main.rs
(pipeline + run_window/run_headless/run_smoke), apps/linux/Cargo.toml,
apps/linux/deny.toml, .github/workflows/hygiene.yml (full),
fixtures/palette/README.md (digest lines only), the other three n2exit
reports' verdict lines only. Dart reference (read-only, pub cache):
material_color_utilities-0.13.0's material_dynamic_colors.dart,
contrast_curve.dart, dynamic_color.dart.

Runs (this session, tip 8478a09):
- `git log --oneline -3` + `git status --short` → tip 8478a09, tree clean.
- `cargo test --locked` (core; CARGO_TARGET_DIR=/tmp/n2eng-target,
  cargo at tools/rust/bin) → **174/174 green, 0 failed, 0 ignored**, the
  exact expected breakdown: 24 lib + 3 differential + 6 composition +
  2 manifest + 4 palette_port + 42 runner + 7 property + 25
  return_format + 39 tax_inspect + 22 txf (first run completed in
  foreground; an earlier background attempt died with its shell and
  was re-run clean — no result was taken from the dead attempt).
- `bash scripts/harness_check.sh` → 0 failures (the palette-corpus
  ledger family green).
- `sha256sum fixtures/palette/cases.json` → matches the recorded
  da1ceaf4…52b7 (live corpus-digest confirmation).
- `git diff d227bc7..8478a09 -- .github/workflows/hygiene.yml` →
  96 insertions, 0 deletions, the linux-app job only.
- Spot-audit reading only (no runs): the Dart-source formula
  comparisons, the main.rs code-identity audit, the CI-shell walk.
- Not run (per the task's budget rule): the app re-build; CI run #44
  green is the authoritative app-lane evidence.
