# Roadmap (gated)

Stages advance **only** through adversarial consensus gates
(`../WORKFLOW.md` §2). Gate status is recorded here and in
`adversarial/CONSENSUS.md`. Dates are session dates (UTC+8).

## Gate depth tiering (Stage-0 amendment, ADV-PROD condition 6)

The panel process is calibrated to a single-maintainer project so it
survives contact with reality instead of being quietly abandoned:

- **Full-depth gates** (all four roles, whole-repository review): Stage 1
  entry (it carries the history and two-codebase decisions), Stage 2 entry
  (RE posture — ADV-LEGAL carries extra weight), any history-rewrite
  execution, and the epilogue native program's entry (N1 — it carries the
  Rust-core verification annex of ADR-017).
- **Delta-scoped gates** (all four roles, but scope = "delta since the
  last gate + named risk surfaces for the stage"): Stages 3–6 and spot
  reviews.
- Independence, evidence-based findings, and the verdict vocabulary are
  never relaxed; only the review scope is.
- **Re-sequencing note (Stage-2 entry gate, 2026-11-14):** execution order
  is now Stage 3 (parity & bridges) before Stage 2 (RE tooling); the stage
  IDs stay stable for cross-references. The parity stage's entry was
  discharged by the full-depth Stage-2 entry gate of 2026-11-14 (its agenda
  explicitly reviewed the Stage-3 plan); the next full-depth gate is the
  RE-tooling stage's own entry ("Stage 2 entry", RE posture, ADV-LEGAL
  weighted), which is also Stage 3's exit gate.

## Per-stage implementation targets (amended 2026-11-14 after owner ratification)

**ADR-009 ratified 2026-11-14: FEATURE PARITY** (the owner chose alignment
over the panel's recommended web-freeze — owner prerogative, recorded in
`memory/DECISIONS.md`). The web prototype is a live implementation target;
the Flutter engine is the reference model the web engine must match.
**Narrowed to maintenance parity 2026-11-17 (ADR-016, the tripwire
settlement at the Stage-2 entry gate): no NEW web-engine features — bug
and security fixes, the Stage-5 hardening halves, format-guard compliance,
and reference-mirrored corrections via the shared-fixture contract still
flow; the TS engine retires when the Rust core serves the web (WASM).**

**Cost statement + tripwire (Stage-1 gate, ADV-PROD condition 3):** parity
roughly doubles per-stage engine cost for a single maintainer — risk
knowingly accepted in ADR-009. It is therefore *time-boxed*: the web-engine
parity set is boxed at two working sessions; if the box is exceeded or the
Stage-3 gate slips, the web-freeze option returns to the NEXT gate agenda
as a mandatory item. Inside Stage 3, the shared golden fixtures land FIRST
(they double as the Flutter reference engine's regression suite and keep
producing value even if parity is deferred by the tripwire).

**Tripwire clock (defined at Stage-3 entry, 2026-11-14, per ADV-PROD
PROD-3):** baseline = the Stage-3 entry session (2026-11-14, at the
Stage-2 entry gate); box = two working sessions spent on the web parity
set; slip = the Stage-3 exit gate (the RE-tooling stage's entry gate) not
convened within four total working sessions of entry, fixtures-first
session included. Box exceeded or gate slipped → the web-freeze option
returns to the NEXT gate agenda as a mandatory item.

**Amended 2026-11-15 (ADR-014, owner directive) and SETTLED 2026-11-17
(ADR-017, Stage-2 entry gate): native re-platforming — recorded and
settled, not yet entered.** The forward implementation targets one
native UI stack per OS (Windows raw Win32 + Direct2D; macOS Swift +
AppKit; Linux Rust via gtk3-rs (older tier) and Slint (modern tier);
Android Views + Kotlin Multiplatform) over a **shared Rust core**,
themed **Material You** on every OS for consistency with OS-specific
elements kept (`memory/DECISIONS.md` ADR-014, settled by ADR-017). The
matrix below still describes the CURRENT codebases and stays accurate
for all in-flight work: no native stack exists yet, and the Flutter app
+ web prototype remain the live implementation. The re-platforming
executes as a **finite post-Stage-6 epilogue program** (see "Epilogue
stages" below), entered only behind its own gates — settlement ADR-017
(placement, sequencing, budget, migration shape, core boundary, FFI,
version tiering, the v2.0.0 rule, the ADR-009 disposition, the
verification + licensing annexes).

| Stage | Web prototype (`src/`) | Flutter app (`clearfile/`) |
| --- | --- | --- |
| 1 — Hardening | copy fixes (done 2026-11-14), typecheck (done), lockfile (done), release body (done) | delete-bug fix (done), privacy gating (done 2026-11-14), INTERNET + entitlements (done) |
| 2 — RE tooling | — | — (tooling is repo-level; placement decided at its gate) |
| 3 — Parity & bridges | **engine parity features** (QDI/LTCG stacking, NIIT, SALT cap, OBBBA senior deduction, student-loan interest, exact 5%-of-excess CTC phase-out, cents-not-whole-dollars — **done 2026-11-15**, parity suite 16/16), TXF exporter verification (**done 2026-11-15**: spec v042 codes fixed + `txf_taxfile_test.mjs` in CI), **unified return format done 2026-11-15 (ADR-015: `.clearfile.json` envelope + version guard + migration matrix + `.cfr` unification)** | TXF import (**done 2026-11-15**: spec v042, W-2 copy grouping, hardening caps, 11 tests), `.tax` read-only inspection (**done 2026-11-15**: Intuit shape + entropy, 7 tests), **schema versioning + guards done 2026-11-15 (ADR-015: store + export write the envelope; legacy layouts migrate on read)** |
| 4 — Pages | (hosted Flutter web build) | Flutter web deploy |
| 5 — AI hardening | timeout parity | injection suite, fixture e2e, key header fix |
| 6 — Freeze | docs-only, parameter corrections | parameter corrections |

**Execution order (Stage-2 entry gate, 2026-11-14):** the rows run
1 → 3 → 2 → 4 → 5 → 6 — Stage 3 (parity) executes before Stage 2 (RE
tooling); the stage numbers above are stable identifiers, not sequence.

Parity tests in Stage 3 must cover **both engines** against shared golden
fixtures (`(TaxReturnData, TaxResult)` JSON pairs consumed by the Dart and
TS suites) pinned to IRS-published worked examples — the single source of
truth that settles any disagreement between the two implementations.

---

## Stage 0 — Harness bootstrap (2026-11-14) — gate PASSED

**Goal:** event-driven backup workflow + durable memory infrastructure +
the standing adversarial panel, applied retroactively to everything done so
far.

**Delivered:** `harness/*` docs; `scripts/sandbox_backup.sh` (branch guard,
unpushed-commit check, PAT-sanitized errors, widened secret guard + hex
heuristic, 0600 temp file); public-repo hygiene (df617e8); Stage-0 panel
(4 independent reviewers — reports in `adversarial/reports/`); conditions
applied in-session where safe (see `adversarial/CONSENSUS.md` ledger);
`.gitignore` backup scope (incl. `upload/`); RE protocol §7 guardrails;
README engine-scope truth sweep; delete-return regression fix + test;
`clearfile/README.md` rewrite.

**Gate:** 4 × PROCEED-WITH-CONDITIONS → PASSED with conditions ledgered
(`adversarial/CONSENSUS.md`). Stage 1 **entry** conditions must be applied
before Stage-1 feature work (owner decisions included — see CONSENSUS).

## Stage 1 — Hardening & trust (next)

**Ordered scope (re-sequenced per ADV-PROD F7 — decisions before
artifacts; decisions were ratified 2026-11-14, see CONSENSUS):**

1. ~~**History decision ADR-008 ratified**~~ — DONE 2026-11-14:
   accept-and-document; README NOTICE added.
2. ~~**Two-codebase policy ADR-009 ratified**~~ — DONE 2026-11-14:
   **feature parity** (owner choice against the recommended freeze);
   Stage 3 scope amended accordingly.
3. ~~**Android INTERNET-permission decision**~~ — DONE 2026-11-14:
   add-and-disclose — main manifest INTERNET permission, macOS
   network-client entitlement, in-app + release-page network disclosure.
4. ~~**Privacy copy matches code**~~ — DONE 2026-11-14: review prompt
   de-identified by construction (no employer/dependent names — counts
   and figures only); `sendReturnContext` defaults OFF with the default
   disclosed in copy; Settings/Welcome copy aligned; web auto-fill
   "stores vs transmits" wording fixed; web app title de-"Filing"-ed;
   privacy contract pinned by `clearfile/test/privacy_test.dart`.
5. ~~Release integrity follow-through~~ — **DONE 2026-11-14**: the
   v1.0.1 release carries the first `SHA256SUMS.txt`; one asset
   (`clearfile-linux-x64-v1.0.1.tar.gz`) downloaded and re-verified
   against it locally (`sha256sum -c`: OK). Body disclaimer + network
   disclosure verified in the published body; unsigned-demo posture
   stands.
6. CI: gitleaks scheduled scan **landed + first run green** (hygiene.yml,
   push + weekly + dispatch; gitleaks and harness_check both green on
   `0bbb564`); action SHA pinning **done** (all `uses:` pinned, D10);
   caching verification + dispatch dry-run — **existing-tag dispatch
   verified 2026-11-14**: a dispatch against `v1.0.0` (exists, points
   elsewhere) was REFUSED at the tag-SHA guard in every build job before
   any build ran, publish job skipped (run 43598383213, intentional
   failure); fresh-tag dispatch is the v1.0.1 closing run itself; caching
   verified from that run's logs ("Cache hit for:
   flutter-linux-stable-3.47.9-x64-…" in the android job; npm + SDK cache
   post-steps green on every job).
7. ~~Web reproducibility verification~~ — **DONE 2026-11-14**: the v1.0.1
   run's `Next.js standalone web` job ran `npm ci` + `npx tsc --noEmit` +
   `npm run build` green on a GitHub runner (plus the local web smoke test,
   `scripts/web_smoke.py`, 6/6).
8. ~~Tests~~ — **DONE 2026-11-14**: per-step widget coverage (6 tests), the
   `ReturnStore` seam + `FakeReturnStore` (D4 — new tests escape the
   runAsync tax), web smoke test (`scripts/web_smoke.py`, 6/6 assertions
   incl. reload persistence), `reactStrictMode` flipped ON (ADR-010
   closed). Suite 61/61; `flutter analyze` clean.
9. ~~Docs & tooling~~ — **DONE 2026-11-14**: GPL-3.0-only SPDX headers on
   70 own-code files (D14; vendored shadcn excluded deliberately);
   SECURITY.md (D13); `scripts/harness_check.sh` (D19 — 11 checks,
   dogfooded 0 failures, runs in CI); `parseMoney()` shared util + edge
   tests (D2); `sample_w2.csv` removed + android CI out of the tracked
   tree (D7); duplicate-row guards: ObjectKey keys + identity removal +
   one-row chain removal (D6 — the ValueKey collision was a live crash);
   scripts/README updated.

**Closing event (ADV-PROD Stage-1 condition 1):** Stage 1 ends with a
**v1.0.1 tag** — its rehearsal is item 6's dispatch dry-run — which ships the
Android/macOS network fix, the first `SHA256SUMS.txt`, and the hardened
CI's first full green run.

**DONE 2026-11-14**: dispatched via `workflow_dispatch` (the fresh-tag path,
run 43598726491 — all 8 jobs green in ~6 minutes on restored SDK caches);
release 445310560 carries 11 assets including the first `SHA256SUMS.txt`
(one asset re-verified locally); the tag points at exactly the built commit
`0bbb564` (target_commitish honored). The existing-tag guard was verified
separately by the intentional refusal run 43598383213. **Stage 1 execution is
complete; the Stage-2 entry gate is next.**

**Gate status:** PASSED (full-depth gate, 2026-11-14) — **Stage 1 CLOSED
2026-11-14**: entered, executed end-to-end (all nine ordered scope items
plus the v1.0.1 closing tag), and formally closed at the Stage-2 entry
gate's unanimous review of the execution evidence — all four reviewers
verified it independently against the live release/CI; see
`../adversarial/CONSENSUS.md` and the Stage-2 gate reports.

## Stage 2 — Format-study infrastructure (RE Phases 1–3 only) — re-sequenced AFTER Stage 3

Read-only analysis tooling per `docs/reverse-engineering-protocol.md`
Phases 1–3 (entropy scan, magic scan, differential diff) + crash-safe,
write-free, resource-bounded implementation + unit tests pinned to the
tools; a CI-checkable no-binary-blob assertion on fixture paths; first
`docs/formats/<ext>.md` specs on owner-authored files, following §7.

**Re-sequenced 2026-11-14 (Stage-2 entry gate):** this stage now executes
AFTER Stage 3 (parity & bridges) — the settled ordering (two explicit swap
recommendations, one keep, one neutral-lean; rationale recorded in
`../adversarial/CONSENSUS.md`). Stage IDs stay stable for cross-references.

**Entry-gate agenda — SETTLED 2026-11-17 at the Stage-2 entry gate (=
Stage 3's exit gate; every mandatory item was settled there — see
`../adversarial/CONSENSUS.md` and `memory/DECISIONS.md` ADR-012/016/017):**
- **DoD (PROD-1, PROD condition 2) — FIXED:** **N = 4 published
  `docs/formats/` specs** — (1) `clearfile-json.md` (the unified envelope
  family: v2 + web v1 + legacy flat + `.cfr` alias); (2)
  `tax-exchange-container.md` (this repo's own `.tax`-extension exchange
  container); (3) `txf.md` (ClearFile's TXF v042 profile, verified by the
  shipped round-trip bridges); (4) `tax-modern.md` (the modern `.tax`
  container at shape level — crypto by existence only, §7.3) — in a
  **two-working-session hard time-box** (the parity-box unit, counted per
  SESSION_LOG). Hard rules: no spec for any extension with zero available
  samples; the owner states the owned corpus (product/version/year/count)
  at Stage-2 kickoff so N is real; specs on the owner's own licensed
  `.tax` files are §7.1-compliant bonus, never required for the DoD; each
  additional deposited owner-authored family adds one spec inside the box
  or is declared backlog at box-end (the box never silently grows); the
  differential tool must be exercised on a synthesized pair inside the
  mandatory set. Checkable at the exit gate: `ls docs/formats/*.md` ≥ 4
  with the named files present, each §7.5-clean, ≤ 2 Stage-2 execution
  sessions in SESSION_LOG, refusal/cap tests green, no-binary-blob
  assertion green.
- **Placement ADR-012 — RECORDED (in-repo with six binding mechanics):**
  `memory/DECISIONS.md` ADR-012; the mechanics (enumerated gitignored
  fixture path; allow-listed CI binary assertion with the
  synthetic/owner-authored provenance distinction; the same allow-list in
  the backup script; §7.5 per spec; tooling never in `release.yml`; no
  tracked Phase-4 binaries) land with the FIRST tooling commit, else the
  placement reverts to a separate research repo.
- **Security contract (SEC 1) — RECORDED as the binding spec Stage-2
  execution implements:** any new workflow/job follows the repo posture
  (`permissions: contents: read`, `timeout-minutes`, SHA-pinned actions,
  no `pull_request_target`/fork surface, no secrets); tools are
  **write-free** (read-only opens; no disk-writing shell-outs; no writes
  outside gitignored build dirs; a read-only-fixture-dir test) and
  **resource-bounded** (up-front size refusal; entry/record/line caps
  each with a refusal-on-oversize test — clean refusal message + non-zero
  exit, never a crash; bounded extraction buffers; per-file wall-clock
  timeout; CI timeout as backstop); **crash-safe** (a malformed-input
  battery — truncated headers, fields past EOF, adversarial lengths —
  asserting "reports what it could not establish", never a throw; ENG-1's
  crafted file is the template); tooling **never wired into `release.yml`
  artifact paths**; fixture paths enumerated + gitignored; each tool's
  header/`--help` states the read-only + caps + refusal posture. Verified
  at the exit gate by reading the tool code and tests, not by assertion.
- **Native re-platforming settlement (ADR-014) — SETTLED as ADR-017**
  (staged per-OS over the Rust core as a finite post-Stage-6 epilogue
  program; every open question answered — see `memory/DECISIONS.md`).
- **Parity tripwire outcome — DISPOSED (mandatory):** the box was not
  exceeded; the slip fired; the web-freeze question was argued explicitly
  by all four reviewers and settled as **ADR-016** (TS-engine maintenance
  freeze + retire-on-replacement; owner-overrule path recorded — never
  silence).
- **Stage-3 execution evidence — REVIEWED and accepted:** all four
  reviewers re-verified the suites with their own runs (113/113 Dart, tsc
  0, bridge 10/10, parity 16/16, oracle 16/16, smoke 6/6,
  harness_check 12/12) — see the gate record. In-session condition fixes
  applied at the gate: ENG-1 (the Dart `.tax` inspector's crafted-file
  RangeError — bounds-checked + regression test), ENG-2 (the TXF
  10,000-record cap refusal test), the dependency criticals cleared +
  the `npm audit --omit=dev --audit-level=critical` CI gate (SEC-1),
  the fetcher tar-tolerance hardening (SEC-3/ENG-5), and the 2026-11-16
  unlogged-session record (SEC-2).

**Entry conditions carried into execution (must land with the FIRST
Stage-2 tooling commit):** the ADR-012 mechanics (a)–(f); the LEGAL-1
mechanics (synthetic-only unit fixtures; differential-tool
provenance-manifest refusal; the backup hex guard widened to ≥32-hex on
RE-adjacent paths with a UUID/known-hash allow-list; the
`docs/formats/*.md` provenance lint); ENG-3 (one survivingSpouse golden
fixture consumed by all three runners — assigned to the first Stage-2
execution session) and the TXF/`.tax` crash-battery template applied to
the new tools. The Ghidra sandbox feasibility verdict (ADR-013) is the
pre-gate research record for Phase-4-adjacent decisions.

**Gate status:** **Stage 2: ENTERED 2026-11-17** (full-depth gate,
ADV-LEGAL weighted; 4 × PROCEED-WITH-CONDITIONS, unanimous — see
`../adversarial/CONSENSUS.md`). Execution began 2026-11-22 with the first
tooling commit carrying every entry condition (execution session 1 of the
two-session box):

- **Execution session 1 (2026-11-22):** the ADR-012 mechanics (a)–(f)
  landed (`fixtures/re/` enumerated + gitignored; the allow-listed
  no-binary-blob assertion in hygiene's new `re-tooling` job AND wired
  into `sandbox_backup.sh`; §7.5 checklist + provenance field per spec;
  release.yml RE-tooling-free, asserted by harness_check family 7; no
  tracked Phase-4 binaries); the LEGAL-1 mechanics landed (synthetic-only
  unit fixtures; the differential tool's provenance-manifest refusal per
  §7.1, unit-tested on all four refusal shapes; the ≥32-hex backup guard
  already applied at the TT gate; the `docs/formats/*.md` provenance lint
  in CI); ENG-3/D33 CLOSED — the QSS golden fixture #17 consumed by all
  three runners, **and it found + forced a live engine bug: the QSS CTC
  phase-out start is $200,000 (Form 8812 line 9 + Pub 501's "doesn't
  entitle you to file a joint return"), not the MFJ $400,000 both engines
  carried** — fixed in `tax_year.dart` + `config.ts` + the oracle; the
  Phase 1–3 tools (`re_entropy`/`re_magic`/`re_diff`) landed under the
  binding security contract with the 22-test suite (every cap
  refusal-tested, ENG-1-shaped crash battery, read-only-fixture-dir
  proof, differential exercised on a synthesized pair inside mandatory
  family #1); **spec 1 of 4 published** (`docs/formats/clearfile-json.md`,
  §7.5-clean, lint-clean). **PROD-2 DISCHARGED** (the starvation tripwire:
  convened at 2 of 2). Full suite evidence: flutter 114/114 (97 + 17
  golden), tsc 0, parity 17/17, bridge 10/10, oracle 17/17, smoke 6/6,
  audit gate 0, RE tools 22/22, blob assertion clean, formats lint clean.
- **Execution session 2 (2026-11-23, the box's final one):** **specs 2
  and 3 of the N=4 DoD published** — `docs/formats/tax-exchange-container.md`
  (the owner-authored `.tax`-extension STORE-only ZIP exchange container:
  provenance, identification, the writer/reader field layout incl. the
  CRC-32 coupling, the honest-labeling disclosure, the reader contract
  incl. the ENG-1 name-length bounds check, the analysis behavior, code
  anchors both sides, and a differential note pinned by a NEW test — the
  differential tool now exercised inside mandatory families #1 AND #2;
  `test_re_tools.py` grew to 23 tests) and `docs/formats/txf.md` (the
  TXF v042 profile: the grammar as implemented, the full refnum table
  incl. the spouse copy space, the reader contract with the four hard
  refusals, the writer profile, the bridge-suite verification mirror) —
  both §7.5-clean + lint-clean. **D34 CLOSED** (the shared
  `fixtures/migration/` family — the identical v1 sample + the
  edge-clamp fixture + the provenance README — consumed by BOTH suites
  asserting the EXACT ordered warning lists; the web file reader's
  dependent-count clamp aligned to the Dart reference's 0..100 bound,
  the D34-recorded edge drift fixed and pinned on both sides; the
  store-vs-file W-2 shape difference documented in
  `docs/return-format.md` §3). Full suite evidence: flutter 115/115
  (98 + 17 golden), tsc 0, parity 17/17, bridge 11/11, oracle 17/17,
  smoke 6/6, audit gate 0, RE tools 23/23, blob assertion clean, formats
  lint 3/3 clean.
- **The execution box is CLOSED at exactly two sessions.**
  **Exit-gate slip (recorded 2026-11-26, mandatory agenda item at the
  next convened gate):** T3 session 2's password-layer chase found the
  MSI-record keystream diverging from the recorded formula at payload
  offset 0x24000 (the documented variant-A cipher inflates cleanly to
  0x24000 then dies; 14 cipher variants, 1024 phase deltas and 256 key
  constants swept with a continue-stream oracle — no match; the
  decompile-level chase over the ISSetupStream cipher is required), so
  `tax-modern.md` remains unwritten and the exit gate remains
  unconvened. No DoD claim was falsified: 3/4 named specs §7.5-clean,
  exactly 2 execution sessions, refusal/cap tests green, blob assertion
  green — the checklist is otherwise green.
  `tax-modern.md` (the fourth named spec) was NEVER landable inside the
  box — it awaits T3's format-family findings incl. the password layer,
  exactly as the box's own plan recorded (no stub was written: §7.5
  forbids placeholder specs). The **exit gate** therefore convenes when
  T3 delivers; the checklist is otherwise green: 3 of 4 named specs
  present + §7.5-clean, ≤2 execution sessions (exactly 2), refusal/cap
  tests green, blob assertion green. The owner's corpus statement is on
  record (ADR-019 + `docs/re-research/corpus-manifest.md` — the four TT
  targets; TT specs never count toward N=4 per the namespace rule).

## Stage 3 — Parity & clean-room bridges (highest value)

**Engine parity (owner decision, ADR-009):** bring `src/lib/tax/` to
feature parity with the Flutter reference engine — qualified-dividend/LTCG
stacking with the 0%/15% bands, NIIT, the SALT 30% phase-down, the OBBBA
senior deduction, student-loan-interest deduction with MAGI phase-out, the
exact 5%-of-excess CTC phase-out (replacing the $50-per-$1,000 units), and
cents-level rounding — validated by shared golden-fixture parity tests
covering BOTH engines, pinned to IRS-published worksheet examples.
**Ordering (tripwire):** golden fixtures FIRST (regression suite for the
reference engine), then the web parity set, boxed at two sessions.

**Bridges:** TXF import (Flutter) + verification suite for the existing
exporter (web); `.clearfile.json` schema versioning + migration + **version
guard before any format change ships** (ADV-ENG #11); save-format unification
decision (`.cfr` vs `.clearfile.json`); parser-hardening tests for the first
shipped untrusted-input parsers; `docs/engine.md` (1040 line mapping +
limitations register), repo guided tour, discrepancy-report issue templates,
and the project definition of done (ADV-PROD F5: "v1.1 = a reader can
verify every number against a cited IRS source without reading git
history").

**Fixtures-first progress (2026-11-14 — tripwire clock: working session 1
of the four-session total, fixtures-first included; the two-session parity
box is still untouched): DONE.** 16 shared golden fixtures live in
repo-level `fixtures/tax/`
— each an IRS-pinned `(TaxReturnData, TaxResult)` JSON pair with citation,
derivation and tolerance (Tax Table rows + the instructions' own MFJ
example; QDIVCG worksheet breakpoints incl. the flat $300,000 MFS 15% cap;
Schedule 1-A Part V senior deduction; Schedule A SALT worksheet incl. the
$575k→$17,500 phase-down; Schedule 8812 incl. next-$1,000 phase-out
rounding and the combined CTC+ODC floor; Form 8960 incl. the $125,000 MFS
threshold; the student-loan worksheet at the unambiguous 0.500 midpoint).
Consumed by `clearfile/test/golden_fixtures_test.dart` (suite now 77/77)
and independently re-derived by `scripts/verify_golden_fixtures.py`
(Decimal oracle written from the form text; runs in the hygiene `suites`
CI job). Authoring the fixtures flushed out and closed four reference-
engine divergences (DEBT correction note 2026-11-14): MFS QDI 15% cap,
MFS NIIT threshold, MFS senior-deduction ineligibility, 8812 phase-out
mechanics. Deliberately-unpinned simplifications are D31. **Next inside
Stage 3:** the boxed web parity set (two sessions max, tripwire armed).

**Web parity set progress (2026-11-15 — tripwire clock: working session 2
of the four-session total; the two-session parity box: session 1 of 2
consumed, CLOSED UNDER BUDGET): DONE.** `src/lib/tax/engine.ts` is now a
line-for-line TypeScript port of the reference calculator (same
`TaxReturnData` model, same per-status parameters in `config.ts` — TY2025
only), covering the full parity feature set: QDI/LTCG stacking
(0%/15%/20% incl. the flat $300,000 MFS 15% cap), NIIT (incl. the $125,000
MFS threshold), the SALT 30% phase-down, the OBBBA senior deduction (MFS
ineligible), the student-loan MAGI phase-out (MFS ineligible), the exact
8812 next-$1,000 phase-out with the combined CTC+ODC floor, and cent-level
precision. Validated by the new both-engine requirement: the parity suite
`scripts/web_parity_test.mjs` runs the web engine against the SAME 16
golden fixtures — **16/16, zero field failures, first run** — and it now
runs in the hygiene `suites` CI job after the oracle. The whole web app
was rewired to the reference model (store persist v1→v2 migration, all six
interview steps, `.cfr` schema v2 with v1 file migration, TXF/`.tax`
exporters, AI prompt summaries); `tsc --noEmit` clean and the web smoke
suite 6/6 against the new build. TY2026 support on the web side was
dropped rather than half-supported (D32: the reference has no TY2026
parameter set to mirror).

**Bridges progress (2026-11-15, same session — owner-directed, ADR-013):
TXF import + exporter verification + `.tax` inspection DONE.** Flutter
gains `io/txf_import.dart` (published TXF spec v042: `^`-terminated
records, W-2 copies grouped by the C field with spouse codes in their own
copy space, income/deduction/payment refnums, spec sign convention →
magnitudes, unknown refnums reported not guessed, 5 MB/10k-record/4096-char
hardening caps — 11 tests) and `io/tax_inspect.dart` (read-only ZIP
central-directory scan, STORE extraction, per-entry Shannon entropy with
likely-encrypted flags, modern-Intuit-shape recognition naming the safe
bridges and stating it does not decrypt, ClearFile exchange-container
import — 7 tests; wired into Welcome + AppState). The web TXF exporter
was rewritten to spec-true codes (460/461/466 per W-2 copy, 287, 636,
negative money-paid signs — the previous 425/426 were the 4952
investment-interest family) and `taxfile.ts` gained the same Intuit-shape
+ entropy analysis; both pinned by the new CI bridge suite
`scripts/txf_taxfile_test.mjs` (compiles `src/lib/files/` via
`scripts/tsconfig.files.json`, CommonJS emit so Node resolves the
extensionless intra-module imports). Dart suite 95/95; `tsc --noEmit`
clean. The Ghidra sandbox feasibility study that accompanied this
work is recorded in `docs/ghidra-sandbox-feasibility.md` + protocol §4.E
(pre-gate research for THIS stage's exit gate).

**Close-out progress (2026-11-15, final Stage-3 session — owner-directed,
ADR-015): ALL REMAINING ITEMS DONE; Stage 3 execution COMPLETE.** The
unified return format (`.clearfile.json` envelope, version guard,
migration matrix, sealed import outcomes; closes D1 and the D3 guard
rule; spec `docs/return-format.md`; 14 new Dart tests + 2 container
tests + the extended bridge suite — the store now writes the envelope
and migrates legacy layouts on read). `docs/engine.md` (1040 line
mapping + parameter sources + verification pyramid + limitations
register). `docs/tour.md` (repo guided tour). Discrepancy-report issue
templates (`.github/ISSUE_TEMPLATE/`: engine + format). The project
definition of done (ADV-PROD F5, adopted): **v1.1 = a reader can verify
every number against a cited IRS source without reading git history** —
recorded in `docs/tour.md` and satisfied by the inline-citation docs
(engine.md, fixtures, return-format). **The exit gate (the RE-tooling
stage's entry gate) is the next event.** Tripwire outcome, recorded
honestly: the **box** was NOT exceeded (the web parity set consumed one
of its two box sessions and closed under budget), but the **slip**
condition FIRED — the exit gate was not convened within the four-session
window (the four working sessions since entry: fixtures, parity,
bridges, this close-out; the governance-only ADR-014 session is not
counted as Stage-3 execution). Per the tripwire, the **web-freeze
option returns to the gate agenda as a mandatory item**; the owner's
ADR-009 parity prerogative may still decline it, but the gate must argue
it explicitly, not skip it.

**Gate status:** **Stage 3 CLOSED 2026-11-17** — entered 2026-11-14 at
the Stage-2 entry gate under the re-sequencing, executed end-to-end
(fixtures-first → web parity set → bridges → close-out, ADR-015), and
formally closed at the Stage-2 entry gate of 2026-11-17 (= this stage's
exit gate): the full-depth panel reviewed the execution evidence — every
reviewer re-verified the suites with their own runs — and closed it
unanimously (see `../adversarial/CONSENSUS.md`). The parity-tripwire
outcome (box NOT exceeded; slip fired) was reviewed and disposed at the
closing gate as ADR-016.

## Stage 4 — Demo distribution

GitHub Pages deploy of the Flutter web build (security headers pinned,
welcome disclaimer verified prominent, Stage-1 copy fixes landed first).

**Backlog, cut from the stage** (revisit trigger: a real distribution
need appears): Linux AppImage; Android `.aab` (Play-ready when an account
exists); further packaging breadth.

**Gate status:** **CLOSED 2026-11-26** (delta-scoped gate, the Stages
4+5+6 panel — 4 × PROCEED-WITH-CONDITIONS, unanimous; every condition
discharged in-session: `8622e74` + the governance sync). EXECUTED
2026-11-26 under the owner's blanket directive ("implement everything on
the roadmap that does not require my input" — recorded here and in
CONSENSUS as an after-the-fact sequencing deviation awaiting owner
ratification, the ADR-009 recorded-prerogative pattern): the web-boot fix
(main.dart kIsWeb → MemoryReturnStore + AiSettingsStore.inMemory — the
v1.0.1 web artifact could never boot), the memory persistence disclosed
in-App + README, index.html de-scaffolded + the meta CSP/referrer set
(the *.github.io no-custom-headers limit disclosed), pages.yml (least
privilege, SHA-pinned, the id-token OIDC deviation recorded in-file),
boot verified by scripts/flutter_web_smoke.py + a vision-reviewed
screenshot (PROD-5). The site is LIVE at
https://maniesh-nr.github.io/ClearFile/ (deploy run green; Pages enabled
via the owner PAT after the GITHUB_TOKEN create-site 403 — surfaced for
owner ratification at this gate).

## Stage 5 — AI assistant hardening

Prompt-injection test suite (incl. provider-response error snippets
surfaced into UI); recorded-fixture cascade e2e (MockClient pattern);
timeout parity + Google key via `x-goog-api-key` header; in-app privacy
disclosure generated from actual transmission behaviour; plaintext
key-at-rest disclosure (file + format named in-app).

**Closing event (added 2026-11-17, Stage-2 entry gate, ADV-PROD):**
Stage 5 ends with the **v1.1 tag** — the adopted project DoD ("a reader
can verify every number against a cited IRS source without reading git
history") is reachable on the CURRENT codebases and must not wait for
the epilogue re-platforming; the tag also discharges D29 (the tag-PUSH
trigger verification) as the next tagged release.

**Gate status:** **CLOSED 2026-11-26** (delta-scoped gate, the Stages
4+5+6 panel — 4 × PROCEED-WITH-CONDITIONS, unanimous; conditions
discharged in-session). EXECUTED 2026-11-26 under the owner's blanket
directive (see the Stage-4 note + CONSENSUS): timeout parity (Google 45
s / OpenRouter 90 s, the OpenRouter `.timeout()` now actually applied —
a live unbounded-wait bug), the Google key moved to the x-goog-api-key
header (mirrors the web ladder; pinned by tests), the behavior-generated
disclosure platform-accurate on both sides + pinned by privacy_test,
the prompt-injection suites (Dart 5 + web 4) and the shared-fixture
cascade e2e (fixtures/ai/ driven by both engines). **The v1.1 tag SHIPPED**
(release 459120788, 11 assets + SHA256SUMS, tag → e099bc0); D29 verified
live (the annotated-tag push fired the trigger; the guard refused
fail-closed exactly as the debt predicted — then FIXED + extended to the
6-scenario suite wired into CI). D8 (AI halves)/D11/D12/D16 closed in
DEBT.

## Stage 6 — Freeze & codify (terminal)

Final study documentation; declared maintenance mode: parameter
corrections only; version policy (what earns v1.1 / a major bump). The
roadmap ends here deliberately (ADV-PROD F11: a demo project without a
"done" invites an infinite roadmap).

**Gate status:** **CLOSED 2026-11-26** (delta-scoped gate, the Stages
4+5+6 panel — 4 × PROCEED-WITH-CONDITIONS, unanimous). EXECUTED
2026-11-26 under the owner's blanket directive (see the Stage-4 note +
CONSENSUS): the README maintenance-policy section (parameter
corrections only, the cited-IRS-source rule through the shared fixtures
+ oracle; the v1.x vs v2.0.0 ADR-017 rule; out-of-scope list). The
roadmap's terminal intent stands — the remaining open lanes are the TT
program's own gates (T3/T4) and the unfunded epilogue N1–N6.

---

## Epilogue stages N1–N6 — native re-platforming (post-Stage-6; ADR-017, 2026-11-17)

A **separate, finite program** — not part of the roadmap above, which
still ends at Stage 6 — entered only behind its own gates when the owner
funds it with sessions. **FUNDED 2026-11-26 (owner, in-conversation,
the same message that ratified the Stages-4/5/6 gate's three
surfacings); every stage still enters only behind its own gate per the
tiering — funding gates the program, not any stage.** Full settlement:
`memory/DECISIONS.md` ADR-017
(migration shape, sequencing, Rust-core boundary, FFI seam, macOS/Linux
tiering, KMP, the explicit iOS drop, the v2.0.0 rule, the ADR-009
disposition, the verification + licensing annexes). Recorded variant:
the Rust core alone (N1, no UI stacks) may be entered parallel to Stage
4+ behind its own gate, provided no shipped artifact depends on it and
v1's stages still close first.

- **N1 — Rust core**: the 1040 engine + parameter tables + format codecs
  (TXF import/export, read-only `.tax` inspection, envelope codec incl.
  migrations, exchange container) + MD3-from-seed palette generation;
  pure, offline, fixture-verifiable; validated against the 16 shared
  golden fixtures PLUS the differential/property harness against the Dart
  reference (the verification annex — fixtures pin breakpoints, not the
  continuum). **Gate status: ENTERED 2026-11-26; CLOSED 2026-11-26 (exit PASSED)** —
  the entry gate (4 × PROCEED-WITH-CONDITIONS unanimous, reports at
  `harness/adversarial/reports/2026-11-26-n1-*.md`) + the exit gate
  (4 × PROCEED-family unanimous, no BLOCK, every condition discharged
  in-session; reports at
  `harness/adversarial/reports/2026-11-26-n1exit-*.md`): the box closed
  at exactly two sessions; 17/17 golden + the annex-(a)
  differential/property harness (550 cases × 26 fields exact parity,
  D43 closed) + the annex-(b) ported bridge suites (cargo test
  159/159); the MD3-from-seed palette defers to its first consumer
  session (D44, N2); the ADR-017 variant holds (no shipped artifact
  depends on the core). **Execution box:
  TWO sessions** (session 1 = the toolchain + the std-only `core/`
  scaffold + the TY2025 tables + the ordinary-income path incl. SLI/SALT
  + the third golden-fixture runner; session 2 = 17/17 + the annex (a)
  differential/property harness + the ported bridge tests) — exceeding
  the box fires the Stage-3 tripwire precedent: the slip is logged
  honestly and disposed at the N1 exit gate, never silently extended;
  an extension requires a recorded owner ruling. **Boundary sentence:
  "zero engine code touched" (the v1 maintenance freeze) is scoped to
  the two existing engines (`clearfile/` Dart, `src/` TS); N1 adds a
  third engine under `core/` that is additive by design, whose
  correctness contract is the shared fixtures + oracle, and whose delta
  never touches `clearfile/` or `src/`.** **Count erratum (dated
  2026-11-26):** this bullet and ADR-017's annex say "16 shared golden
  fixtures" — the actual count is 17 (fixture #17, the QSS pair, landed
  later as D33); the annex text predates it, and the runner consumes 17.
  **Session-2 execution (2026-11-26, the box's final session):** the
  exit checklist satisfied — 17/17 held, the annex-(a)
  differential/property harness landed (the tracked Dart generator
  `scripts/generate_differential_cases.dart` seed 771937021 emitting
  the 550-case byte-deterministic corpus `fixtures/differential/
  cases.json`, consumed at exact binary64 parity, + the 7-test property
  harness), the annex-(b) ported bridge suites landed (the envelope
  incl. the v1→v2 migration with the warning strings IN the core, TXF
  import/export, the .tax inspection with the malformed-ZIP crash
  battery, the exchange container, the payload-seam composition); cargo
  test 159/159 green; D43 closed. The execution box closed at exactly
  two sessions. **The N1 EXIT gate convenes next** (the Stage-2 exit
  slip is the mandatory agenda item per the slip record).
- **N2 — Linux native UI**: the owner's two-tier assignment with one
  toolkit per tier — gtk3-rs (older tier) / Slint (modern tier);
  consolidatable at this gate if single-maintainer reality demands it.
  **Gate status: ENTERED 2026-11-26; CLOSED 2026-11-26 (exit PASSED)**
  (the delta-scoped gate, 4 × PWC unanimous, reports at
  `harness/adversarial/reports/2026-11-26-n2-*.md`; the exit gate, 4 ×
  PWC unanimous — SEC 3 / LEGAL 6 / ENG 1 / PROD 5, reports at
  `harness/adversarial/reports/2026-11-26-n2exit-*.md`; the box closed
  at exactly two sessions: the D44 palette + corpus + the scaffold +
  guards (session 1), the Slint window app + the shared pipeline + the
  CI Linux-app lane + the R1/R2 hardenings (session 2); the live-green
  hygiene run #44; cargo test 174/174 + the app 5/5; the remaining
  record-level conditions ride to the next session as the recorded
  list). **The consolidation EXERCISED:** one toolkit =
  Slint (the modern tier, GPL-3.0-only branch) — ADR-017's own "may
  consolidate … if single-maintainer reality demands it (revisitable,
  recorded)" clause, the demand verified live (gtk3-rs unbuildable in
  this sandbox: no libgtk-3-dev, no root; CI could build it — the
  demand is the single-maintainer dev-loop reality, not a global
  impossibility); the gtk3 older tier + its LGPL posture forfeited;
  the Flutter GTK app stays the shipped Linux product until the native
  GA (the distro baseline is a GA-gate decision); the owner may
  re-split by a recorded ADR. **The topology recorded as
  chosen-with-rejected-alternative:** apps/linux is a separate crate
  root; the core keeps its own root (a workspace would break the
  zero-dep assertion as-written — a path-scoped rewrite exists but is
  rejected: separate roots keep the assertion byte-identical). The
  two-session execution box + the disk plan live in CONSENSUS's gate
  record. D44 (the MD3 palette) lands in session 1 against
  material_color_utilities 0.13.0 (the pubspec.lock-resolved version,
  content-hash pinned — NOT the SDK version).
- **N3 — Android native UI**: Android Views + Kotlin Multiplatform
  (Android-only) over the core via a thin JNI shim. **Gate status: FUNDED
  2026-11-26 (owner, in-conversation; the delta-scoped gate convenes at
  its turn).**
- **N4 — Windows native UI**: raw Win32 + Direct2D consuming the
  cbindgen C header. **Gate status: FUNDED 2026-11-26 (owner,
  in-conversation; the delta-scoped gate convenes at its turn).**
- **N5 — macOS native UI**: one Swift+AppKit app, deployment floor
  macOS 13 (confirmable here); requires the `macos-latest` CI runner or
  owner-side builds — this Linux sandbox cannot build or verify AppKit.
  **Gate status: FUNDED 2026-11-26 (owner, in-conversation; the
  delta-scoped gate convenes at its turn).**
- **N6 — web via WASM + terminal freeze**: the Rust core serves the
  web; the TS engine retires per ADR-016; the epilogue program declares
  its own freeze (v2.0.0 territory per the settlement's rule).
  **Gate status: FUNDED 2026-11-26 (owner, in-conversation; the
  delta-scoped gate convenes at its turn).**

The per-OS order after N1 (Android before Windows, macOS last) is
re-settable at the epilogue's own gates without reopening the ADR-017
settlement. **Version-plane note (2026-11-26, the N1 entry gate):** the
`core/` crate's Cargo semver is a FOURTH version plane, separate from
the app semver, the `.clearfile.json` envelope schema version, and the
web package.json version (ADR-017 keeps three planes separate; the
crate adds one). **Extended 2026-11-27 (the N2-exit PROD advisory):**
each native app crate adds its own plane too — `apps/linux` 0.1.0
(`publish = false`) is a FIFTH plane, and every later native app crate
follows the same one-plane-per-crate rule; no app-crate version movement
is ever an app-semver or envelope-schema movement.

---

## TT-compatibility program (T1–T4) — T2 ENTERED 2026-11-22 at its own gate (ADR-019 + ADR-020)

A separate gated program (owner directive 2026-11-22): study the four
TurboTax installer targets with REA over Ghidra (T1 done — corpus +
Phase-1 + the REA first pass; the stub-carving technique makes the
installers tractable in this sandbox), then the per-target deep
Phase-4, the format-family specs including the **password-based**
capability (the user's own password = the authorization; the
LibreOffice/7-Zip interoperability pattern), and the UI
functional-layout study. **ADR-020 (2026-11-22, owner explicit risk
acceptance, recorded before any implementation exists): the shipped
decryptor may include the fixed-key transport layer** — protocol
§2.2's recorded NO is lifted for the T4 bridge scope, bound to
ADR-020's boundary conditions (password-gated surface only — no
bypass/brute-force/recovery; ONE quarantined provenance-labeled key
module, key values nowhere else; §7.2/§7.4 unchanged; the
enforcement-response plan; refusal tests). UI parity stays
functional/informational — no expression/trade-dress copying,
ClearFile's Material You identity stands; Stage-2's DoD box is not
grown by this program. Corpus: gitignored `tools/re-corpus/`
(provenance `docs/re-research/corpus-manifest.md` — mechanically
sha256-verified by `scripts/fetch_tt_corpus.sh` since the TT gate).

- **T1 — DONE 2026-11-22** (corpus + Phase-1 + REA first pass;
  findings in `docs/re-research/2026-11-22-tt-targets-phase1.md` —
  container head at **0x99000** per the gate's erratum; verified
  byte-for-byte at the TT gate by ADV-ENG).
- **T2 — deep per-target Phase-4: ENTERED 2026-11-22** (session 1:
  the reader-vtable chase + the record-table layout + the
  decompression path + first bounded extraction —
  `docs/re-research/2026-11-22-tt-t2-reader.md`. Session 2, same date:
  **the USA container format COMPLETED byte-end-to-end** — entry fields
  resolved (A = Win32 attributes bitmask, B = first-chunk compressed
  size), the chunk grammar proven (raw-Deflate chunks + 0x80000000-flag
  stored segments + terminator + type-0 end-entry + trailing PKCS#7
  SignedData), FUN_0041e5e0 corrected to the parent-dir preparer,
  CAN-Personal's inner layer mapped (plain ZIP → the same 2022-07-05
  bootstrapper family + InstallShield ISSetupStream v7), CAN-Business's
  manifest table mapped (header fields incl. the INI-block size;
  text→compressed entropy boundary) —
  `docs/re-research/2026-11-22-tt-t2-session2.md`; all four targets
  converge on the InstallShield payload layer, where the app modules
  live. Remaining: the InstallShield-layer record walk (D40) → the
  app-module inventory where the file-format/password routines live,
  the UI functional-layout study [text-only IA records per protocol
  §7.4's extension]. Binding execution rules (TT gate, ENG-2/ENG-3):
  stub-only analysis — whole-file 333–404 MB Ghidra imports stay OUT;
  disk discipline — selective per-record/per-module extraction into
  gitignored `tools/re-corpus/extract/<target>/`, intermediates deleted
  immediately, at most one target's payload resident, df watch
  [session 2 ran stricter: all decodes in-memory, zero derived bytes
  on disk].)
- **T3 — format-family specs** (Phase-5 template, §7.5-clean) incl. the
  password layer's clean-room documentation. **Namespace rule (TT
  gate, PROD-3/ENG-6):** TT specs are program deliverables under
  `docs/re-research/` (or `docs/formats/` only with an explicit
  TT/non-DoD provenance marker) and NEVER count toward Stage-2's
  N=4; Stage-2's `tax-modern.md` shape spec and T3's deep
  password-layer spec are distinct files or an explicit recorded
  supersession.
- **T4 — the password-based bridge + UI functional-layout parity** in
  ClearFile's own Material You expression. **Gate rulings binding T4
  (ADV-ENG ruling + the T4 merge-gate conditions in CONSENSUS):**
  Flutter-first — no TT bridge code under `src/` absent a recorded
  owner ADR (ADR-016's freeze reads a new file-format bridge as a
  new web feature, not a parity correction; web reaches TT support
  via the ADR-017 N6 WASM path); the codec layer stays pure/portable
  for the N1 Rust-core port; merge conditions = ADR-020's boundary
  conditions as tests + the save-fidelity rule (fields outside the
  engine's model round-trip verbatim) + the README/SECURITY
  disclosure replacement incl. an Intuit non-affiliation line.

**Gate status: PASSED** (2026-11-22 — 4 × PROCEED-WITH-CONDITIONS,
unanimous; agenda settled: the fixed-key re-argument with ADR-020 on
record, the Canadian-law assessment delivered, the security-contract
application bound; verdicts + full condition ledger in
`adversarial/CONSENSUS.md`, reports in
`adversarial/reports/2026-11-22-tt-*.md`). Standing tripwire (TT gate,
PROD-2): Stage-2 execution session 1 convenes within two working
sessions of T2 session 1 (2026-11-22), else the slippage is a
mandatory agenda item at the next convened gate. **Clock after T2
session 2 (same date): 1 of 2 working sessions elapsed** — if the next
working session is not Stage-2 execution session 1 (or does not convene
a gate with the slip on its agenda), the slippage becomes mandatory.
