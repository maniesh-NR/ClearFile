# Session log (append-only)

One entry per work session. Append at teardown, before the closing backup
(WORKFLOW.md §3). Never rewrite past entries.

---

## 2026-11-03 → 2026-11-04 · Continuation session (pre-harness)

**Context carried in from a compacted conversation** (this is why the
harness now exists — see ADR-003).

- Fixed 31 first-compile errors across `clearfile/` (imports, nullability,
  `\$` escaping, RadioGroup migration, file_picker 13.x API).
- Built the entire Flutter UI from the counter template (5 steps, results,
  assistant, settings, shell; teal MD3 seed).
- Diagnosed and fixed the widget-test hang (runAsync FS pattern; idempotent
  `dispose`). 42/42 tests green; analyze clean.
- Wrote README, expanded RE protocol §2 (17 USC §102(b), Merger Doctrine,
  scènes à faire, *CA v. Altai* 1992, *Apple v. Microsoft* 1994).
- Added `.github/workflows/release.yml`; pushed to GitHub; tagged v1.0.0.
  First run failed on the macOS upload path (workspace-root resolution);
  fixed, re-tagged; second run green — 8 platform assets on the release.
- **Mistake found later:** the force-push carried the local repo's
  scaffolding into the public repo (initial-commit baggage). See
  2026-11-14 entry.

## 2026-11-14 · Harness bootstrap session (Stage 0)

- **Sandbox recycle incident:** between sessions the sandbox was reset;
  working files survived but git history was squashed to one "Initial
  commit" (including scaffolding), and `origin`, the Flutter SDK,
  `node_modules`, `.next/` were gone. Recovered per WORKFLOW.md §4:
  re-added remote, `git reset origin/main` + `git restore .` (the "136
  modified files" were pure permission flips), history restored.
- **Hygiene pass (`df617e8`):** untracked `.env`, `db/`, `.zscripts/`,
  `Caddyfile`, `tests/`, `examples/`, `mini-services/`, `tool-results/`,
  `download/` (incl. unrelated `nitro_nissi`), `tools/` from the public
  repo; codified backup scope in `.gitignore`; copied the blueprint PDF to
  `docs/blueprint.pdf` (fixes the release-workflow gap — v1.0.0 silently
  shipped without it). Full-history secret pattern scan: clean.
- **Harness built:** `harness/` memory + governance docs (README, WORKFLOW
  with the two owner directives, ROLES, STATE, ROADMAP with gates,
  DECISIONS), `scripts/sandbox_backup.sh` (event-driven backup, secret
  guard, clean-tree no-op).
- **Stage-0 adversarial gate convened:** four independent reviewers
  (security / legal / engineering / product) examined work-so-far and the
  draft roadmap. Reports filed under `adversarial/reports/`; consensus in
  `adversarial/CONSENSUS.md`.
- **Closing action:** event-driven backup push (first execution of the new
  workflow — this very step).

---

## 2026-11-14 (later) · Stage-0 gate outcome — reconciliation note (append-only)

The entry above pre-recorded the gate and the closing backup before they
happened (ADV-PROD finding 3 was right to call this out). Actual outcome:

- The Stage-0 panel ran AFTER the entry was written: 4 independent
  reviewers, all returned **PROCEED-WITH-CONDITIONS**, no BLOCKs —
  consensus reached. Verdicts and the full condition ledger (applied /
  Stage-1-entry / owner-decisions) are in `adversarial/CONSENSUS.md`;
  reports in `adversarial/reports/`.
- Corrections to the entry above: `node_modules/` DID survive the
  recycle (STATE.md now reflects this); the calculator test count is
  **19**, not 20 (total was 42; now 43 with the delete-regression test,
  pending SDK verification); the "closing backup" pre-recorded above is
  performed by the actual backup run at the end of this session.
- Conditions applied in-session (same session, post-review): backup-script
  hardening (branch guard, unpushed check, PAT sanitization, widened guard
  + hex heuristic), `/upload/` ignore, RE protocol §7, README truth sweep
  + `clearfile/README.md` rewrite, ROADMAP re-sequencing (decisions first,
  privacy → Stage 1, Stage 4 cut to Pages, freeze stage, gate tiering,
  impl-target matrix), release workflow hardening (least privilege, tag
  validation, timeouts, concurrency, SHA256SUMS, disclaimer body), live
  v1.0.0 release description patched, `package-lock.json` + `npm ci` +
  typecheck + `ignoreBuildErrors` off, `store.ts` cast fixed,
  `z-ai-web-dev-sdk` dropped, delete-return fix + regression test,
  ADR-008/009/010 drafted, DEBT.md register (D1-D21).
- Open at teardown (next session's first task, per CONSENSUS.md): the
  four owner decisions (ADR-008 nitro_nissi ratification, ADR-009
  web-prototype freeze-vs-parity, Android INTERNET permission, PAT
  expiry + branch protection) and the Stage-1 entry list.
- Closing action: event-driven backup (this run) + a failure drill of the
  backup script (commit → unpushed → script must exit 1 → push → clean).
- drill 08:33:13: backup script must refuse (exit 1) while unpushed

---

## 2026-11-14 (late) · Owner decisions applied + Stage-1 entry gate

The owner answered all four gate decisions in-conversation: accept-and-
document; pursue feature alignment; add and disclose; do not alter PAT.

**Decisions recorded (all four, verbatim in CONSENSUS/DECISIONS):**
- ADR-008 ratified (accept-and-document): no history rewrite; README
  NOTICE paragraph added; v1.0.0 identity stands.
- ADR-009 ratified as FEATURE PARITY (against the panel's freeze
  recommendation - owner prerogative): ROADMAP Stage 3 rewritten for the
  web engine parity features with both-engine golden-fixture tests;
  implementation matrix updated; two-session tripwire + freeze fallback.
- INTERNET add-and-disclose: Android main-manifest permission, macOS
  network-client entitlement, in-app + release-page disclosures.
- PAT unchanged: risk acceptance recorded in WORKFLOW SS5.

**Entry conditions cleared:** Flutter SDK 3.47.9 reinstalled (sha256
verified; note the tarball download needs a resuming loop with stall
detection); analyze clean; 47/47 green at entry; privacy de-identification
applied (review prompt strips employer/dependent names - counts +
figures only; sendReturnContext defaults OFF; copy aligned in Flutter +
web; privacy tests added).

**Stage-1 gate convened (full-depth, 4 independent reviewers):**
4 x PROCEED-WITH-CONDITIONS, no BLOCKs - consensus; Stage 1 ENTERED.
Conditions applied in-session: README opt-in scoping + v1.0.0 AI-broken
note; live v1.0.0 release description re-patched (API 200, verified
content); fetch-stderr sanitization; -I dropped from the guard; bun.lock
deleted (npm standard); blueprint fully corrected + regenerated (title +
all privacy sentences; verified via pdftotext; playwright re-rendered the
cover); switch-path autosave flush + regression test; findings-leak
privacy test; store.ts real shape checks; grandfathered-consent migration
(ADR-011: settings schemaVersion 2 + legacy reset); WORKFLOW tiering
reconciliation (fuller-scope-wins tiebreaker); parity tripwire;
concurrency group tag-only; dead buildFieldQuestion deleted; RE protocol
ole_cfb pointer + pubspec description + scripts/README fixes. Suite
re-ran 49/49 green after the fixes.
Conditions assigned to Stage-1 execution: gitleaks CI, action SHA
pinning, dispatch dry-run (fresh-tag AND existing-tag), widget/web test
expansion, GPL headers, SECURITY.md, harness_check.sh, v1.0.1 closing tag.

**Session quirks hit:** one malformed inline shell command (unbalanced
quote -> hang; no damage, re-executed correctly via file tools); the
Flutter tarball download stalls silently - the looping resume with
--speed-limit/--speed-time completed it.

**Closing action:** mode normalization (no 100755 flips in the commit) +
event-driven backup + origin verification.

### Correction note (append-only, same session)

The Stage-1 session log entry above predates two in-session incidents worth
recording: (1) the Flutter tarball download stalls silently — the resuming
loop with --speed-limit/--speed-time is now the documented approach; (2)
the widened no-I secret guard refused the first backup run on a FALSE
POSITIVE — clearfile/windows/runner/resources/app_icon.ico trips the
64-hex heuristic six times on plain bitmap pixel bytes (0x44/0x11/... are
ASCII hex digits). The guard now scans binaries for TOKEN patterns only and
keeps the hex heuristic text files for the hex check — reasoning documented
in the script itself. Suite/test counts at close: 49/49.

---

## 2026-11-14 (Stage-1 execution session) · Stage 1 executed end-to-end

Baseline at entry: analyze clean, 49/49, tsc exit 0, tree clean at `a0e6d34`.

**Code work (local, all verified green before commit):**
- D2: shared `parseMoney()` in `util/money.dart` (both callers rewired);
  comma-plus-1/2-digit shapes ("6,5") refused instead of silently parsing
  as 65; 5 edge tests + a CSV-path warning test. D6 was a LIVE crash
  discovered in the process (W2Entry/Dependent are value-equal → two blank
  rows = duplicate ValueKeys → build crash): ObjectKey identity keys +
  identity removal in both list steps; settings chain removal now drops
  exactly one row (removeAt); 3 guard tests pin all of it.
- D4: `ReturnStore` abstracted (+ `FileReturnStore`); `test/fakes.dart`
  FakeReturnStore — the new per-step widget tests run OUTSIDE runAsync.
- Suite: 61/61 (19 calc, 8 cascade, 10 CSV, 3 JSON, 5 privacy, 2 autosave
  regressions, 5 money, 6 step/settings guards, 3 widget).
- Web: `scripts/web_smoke.py` — build + standalone serve + headless
  Chromium; 6/6 assertions incl. mid-flow reload persistence (the
  localStorage persist/rehydrate path); `reactStrictMode` flipped ON
  (ADR-010 closed).
- D7: `clearfile/assets/sample_w2.csv` removed (duplicate of the template
  const, unreferenced); android CI collects APKs under gitignored
  `clearfile/build/release-apks/`.

**CI hardening (SEC-5/D10/ENG-7):**
- All `uses:` in `release.yml` + new `hygiene.yml` pinned to 40-hex SHAs
  (lightweight tags resolved via `git ls-remote`; version in comments).
- Tag-SHA poisoning guard in all 7 RELEASE_TAG-consuming jobs; fresh tags
  pinned to the run's SHA via `target_commitish`.
- `hygiene.yml`: gitleaks (weekly + push + dispatch) + harness_check —
  **first push run green on `0bbb564`** (run 43598360301).

**Docs & tooling:** SECURITY.md (D13, no invented SLAs); GPL-3.0-only SPDX
headers on 70 own-code files (D14; shadcn `src/components/ui/**` +
`src/hooks/**` deliberately excluded — MIT-derived, never relabelled);
`scripts/harness_check.sh` (D19) — its first dogfood run caught 5 REAL
drifts (README said 47 tests; STATE line; ROADMAP Stage-1 still "PENDING";
plus its own extraction bug) — all fixed; 11 checks green after.

**Incidents (recorded for honesty):**
1. `add_spdx_headers.py` first run had a line-vs-character-offset bug that
   split the first line of 15 shebang/'use client' files
   (`#!/usr/bin/env bash` → `## SPDX…` + `!/usr/bin/env bash`).
   `scripts/repair_spdx_insertion.py` restored all 15; full
   analyze/test/tsc/smoke re-run green afterward. Both scripts kept
   (scripts/README documents the incident).
2. The PAT dispatched workflows (HTTP 204) and read Actions job logs
   (HTTP 200) — Actions permissions beyond the recorded Contents-only
   profile. WORKFLOW §5 corrected with a dated note.

**v1.0.1 closing event (fresh-tag dispatch path):**
- Existing-tag guard test FIRST: dispatch with tag=v1.0.0 (exists, points
  elsewhere) → every build job REFUSED at the guard before building,
  publish job skipped (run 43598383213 — intentional failure; the ADV-ENG
  note-7 poisoning vector is closed).
- Fresh-tag dispatch with tag=v1.0.1: run 43598726491, **8/8 jobs green in
  ~6 minutes** (log evidence: "Cache hit for:
  flutter-linux-stable-3.47.9-x64-…" — caching verified; nextjs-web ran
  npm ci + tsc + build green on the runner).
- Release 445310560: 11 assets including the first `SHA256SUMS.txt`; the
  linux asset downloaded and re-verified locally (`sha256sum -c`: OK);
  body verified to carry demo disclaimer, unsigned posture, SHA256SUMS
  pointer, and the network disclosure.
- Tag `v1.0.1` → `0bbb564` exactly (target_commitish honored — the tag
  equals the built commit).

**Backups:** `0bbb564` (code work, pre-release) + this closing backup.

**Open at teardown:** the Stage-2 entry gate is the NEXT session's first
task (full-depth; reviews this session's evidence and decides Stage-2 vs
Stage-3 ordering per ADV-PROD note 7). Residuals: dev-mode strict-mode
assertion deferred to Stage 4 (ADR-010 closure note); harness_check's
per-stage patterns must be updated when a stage legitimately advances
(self-documented in the checker).

---

## 2026-11-14 (Stage-2 entry gate session) · Stage 1 CLOSED, Stage 3 ENTERED (re-sequenced)

Baseline at entry: tree clean at `7b16e12` (Stage-1 closing backup, pushed,
in sync with origin); analyze clean; 61/61; tsc exit 0; harness_check 0
failures (all re-verified by the orchestrator as gate input, then
independently by the reviewers — two re-ran the full suite).

**The gate (full-depth, 4 independent reviewers, concurrent, isolated):**
- ADV-SEC, ADV-LEGAL, ADV-ENG, ADV-PROD — reports filed
  `adversarial/reports/2026-11-14-stage2-*.md`; consensus in
  `adversarial/CONSENSUS.md`. Verdicts: **4 × PROCEED-WITH-CONDITIONS, no
  BLOCKs**. Independence held (reports written only after all four
  returned; each was given no sight of the others).
- Live verification highlights: all 7 action SHA pins resolved against
  upstream; release 445310560's checksum chain re-verified twice
  independently (download + `sha256sum -c` OK; live-asset-vs-tagged-tree
  sha256); tag `v1.0.1` → exactly `0bbb564` (local + ls-remote); refusal
  run 43598383213's six guard failures confirmed; whole-history +
  all-object-store token scan clean (including unreachable objects).
- Honest limitation recorded: the shared sandbox IP exhausted the
  unauthenticated GitHub API rate limit (60/hr) with four reviewers
  running concurrently — fallbacks used (public HTML; sparing authenticated
  calls per WORKFLOW §5, token never echoed). Two reviewers recorded it in
  their reports rather than pretending.

**Gate outcomes:**
1. **Stage 1: CLOSED** (unanimous, live-verified).
2. **Ordering settled: Stage 3 (parity & bridges) entered next; Stage 2
   (RE tooling) re-sequenced after it.** Split panel recorded honestly
   (ENG+PROD swap; LEGAL fixtures-first lean; SEC keep) — the gate's
   reasoned decision under its mandate, with the owner overrule path
   recorded. Stage IDs deliberately kept stable (no renumbering):
   cross-references in README/DECISIONS/DEBT stay true by construction.
3. **Tripwire clock defined** (PROD-3): baseline 2026-11-14; box = two
   working sessions on the web parity set; slip = exit gate not convened
   within four total working sessions; exceed-or-slip → web-freeze returns
   to the next gate as a mandatory item.
4. **Placement deferred** to the RE stage's entry gate (ADR-012;
   panel split: LEGAL separate-repo default, PROD in-repo with
   constraints, SEC mild in-repo).

**Conditions applied in-session:** GPL §6 corresponding-source sentence in
the release `body:` (SEC-1/LEGAL-1); `THIRD-PARTY-NOTICES.md` + README
License row for vendored shadcn/ui, MIT notice reproduced (LEGAL-2); the
release tag guard made FAIL-CLOSED on unexpected fetch errors in all 7
copies, with `scripts/test_tag_guard.sh` extracting the guard verbatim
from release.yml and proving all four branches 4/4 (ENG-1); phantom `-c`
hint removed from harness_check (ENG-2/SEC-3); DEBT D2 amended
(append-only; empty-cell→0 was deliberate, MoneyField asymmetry → D28)
(ENG-3); `hygiene.yml` `suites` push-CI job — analyze/test/tsc on push to
main (ENG-4); README v1.0.0 note → "Fixed in the v1.0.1 release" (PROD-4);
RE protocol date bumped (LEGAL-3); ROADMAP re-sequencing (execution-order
note 1→3→2→4→5→6, tiering note, Stage-2 entry-gate agenda) +
harness_check stage patterns updated for the legitimate advance.

**Conditions assigned to the RE stage's entry gate** (see CONSENSUS
ledger): security contract, no-binary-blob assertion + synthetic-fixture
rules, placement ADR-012, the RE DoD fix (define N + time-box), tag-PUSH
path verification at the next tagged release (D29).

**Owner-side surfacings (standing, non-blocking):** Dependabot alerts,
branch protection on `main`, PAT expiry when next rotating (D30;
WORKFLOW §5 posture unchanged).

**Session quirks (recorded for honesty):**
1. The unauthenticated API rate limit above (now a STATE quirk).
2. A MultiEdit batch reported "no replacement performed" while having
   applied most of its edits (one old_str was non-unique); the re-run
   duplicated three insertions, caught by `git diff` review and fixed
   before anything was committed. Reinforces STATE quirk 11: re-verify
   every bulk edit immediately, never trust the tool's own report alone.

**Closing action:** full re-verification (harness_check green on the new
patterns, YAML validation on both workflows, guard test 4/4, README/DEBT/
ROADMAP/CONSENSUS/STATE consistency) + mode normalization check +
event-driven backup (this run) — the last action before this reply.

---

## 2026-11-14 (Stage-3 fixtures-first session) · Golden fixtures landed + four engine corrections

Baseline at entry: tree clean at `e47c4a2` (in sync with origin) — but the
sandbox had recycled AGAIN between sessions (third observed): history
intact, `node_modules` survived, Flutter SDK gone, 155 mode-only flips,
`bun.lock` back as scaffolding. Recovery per WORKFLOW §4: `git restore .`
for the modes; SDK 3.47.9 reinstalled via the resuming loop (sha256
`25ed8c3c…` verified against a freshly fetched `releases_linux.json`;
revision c197ca5199); `bun.lock` added to the `.gitignore` backup-scope
block so it stops being noise.

**Session task (STATE "Immediately next"): Stage 3 execution, fixtures
FIRST — the shared golden fixtures as the reference engine's regression
suite. DONE:**

- **Research first, numbers only from IRS publications.** Fetched and read
  the actual TY2025 forms/instructions: i1040gi (QDIVCG worksheet lines 1-25,
  Tax Table with its own MFJ worked example at $25,300 → $2,562, Tax
  Computation Worksheet constants, Student Loan Interest Deduction
  Worksheet, Schedule 1-A instructions), f1040s1a (Part V senior-deduction
  worksheet: 6% phase-out, married-must-file-jointly caution),
  i1040sca (SALT worksheet: 30% over $500k/$250k, $10k floor),
  f1040s8 + i1040s8 (Schedule 8812: $2,200/$1,700/$500, next-$1,000 excess
  rounding, COMBINED CTC+ODC floor, 15%-over-$2,500 ACTC), i8960 ($125,000
  MFS NIIT threshold, 3.8%-of-the-lesser rule).
- **16 golden fixtures** in repo-level `fixtures/tax/` (+ README with the
  authoring discipline): every file pins its `source` (verbatim quotations
  or exact table rows), carries a line-referenced `derivation`, and a
  `tolerance` (0.005 exact; 0.505 where the pin is an IRS whole-dollar
  Tax Table row). Coverage: tax-table rows (single + the instructions'
  own MFJ example), QDI stacking across 0/15/20% bands, the flat $300,000
  MFS 15% cap, NIIT (single + MFS threshold), senior deduction (single
  phase-out, MFJ both-65, MFS ineligibility), SALT phase-down (the
  Fidelity-cross-checked $575k→$17,500 case + MFS floor), 8812 phase-out
  (next-$1,000 rounding + combined floor), refundable ACTC, student-loan
  0.500 midpoint, zero-income edge.
- **Independent oracle:** `scripts/verify_golden_fixtures.py` — the whole
  1040 flow re-implemented as Decimal arithmetic from the form text
  (deliberately not from the Dart engine), verifying every fixture's
  expected values. 16/16 fixtures, 0 field failures; now runs in the
  hygiene `suites` CI job. It also caught its own bug: Python `Decimal //`
  truncates toward zero, so the 8812 ceiling used the `+999` offset.
- **Four reference-engine corrections forced by the fixtures** (each
  pinned to a form line, recorded in DEBT's correction note):
  1. MFS QDI 15% cap 300,025 → **300,000** (QDIVCG worksheet line 13 —
     a flat statutory number, not half of MFJ's 600,050);
  2. MFS NIIT threshold 200,000 → **125,000** (Form 8960 instructions);
  3. MFS senior deduction → **ineligible** (Schedule 1-A Part V: married
     filers must file jointly);
  4. CTC phase-out → **8812 semantics**: excess rounded UP to the next
     $1,000 before ×5%, and the phase-out floors the COMBINED CTC+ODC
     (engine previously used raw-excess ×5% with per-credit flooring).
  Deliberately-unpinned simplifications (ACTC allocation zone, SLI
  three-place reading, ordinary-only marginal rate) recorded as **D31**.
- **Suites:** `golden_fixtures_test.dart` (data-driven loader; structural
  checks throw StateError, never bare `expect()` outside tests —
  OutsideTestException quirk recorded). **77/77 green** (61 hand-written +
  16 fixtures); `flutter analyze` clean; `npx tsc --noEmit` exit 0;
  harness_check green after teaching it to count data-driven fixtures
  (fixture JSON count instead of the single static declaration — its
  README/STATE test-count checks now expect 77, all three rows updated).
- **Docs:** README test-table + fixtures row + run-block; scripts/README
  (oracle entry); tax_year.dart parameterSources gained the
  Schedule 1-A/Schedule A/8812/8960 URLs; fixtures/tax/README.md.

**Session quirks (recorded for honesty):** my own hand arithmetic was
wrong four times mid-session (22% band treated as 24%, 12% run past
48,475, etc.) — the python Decimal pre-check caught every one before any
fixture was written; the fixtures are derived from the form text and the
oracle, never from the engine. One background `cd /tmp && curl … & curl …`
chain lost the cd for the second/third downloads (files landed in the
project root; moved, lesson recorded as STATE quirk 15).

**Tripwire status:** working session 1 of the four-session total consumed
(fixtures-first included by definition); the two-session web-parity box
is untouched. Next session = the boxed web parity set against these same
fixtures.

**Closing action:** full re-verification (oracle 16/16, analyze clean,
77/77, tsc exit 0, harness_check 0 failures, YAML validated) + mode
normalization check + event-driven backup (this run) — the last action
before this reply.

---

## 2026-11-15 · Stage-3 web parity session — TS engine ported to reference parity

Baseline at entry: tree clean at `99d6823` (in sync with origin) — after the
FOURTH observed sandbox recycle: history intact, content intact, 174
mode-only flips (normalized via `git restore .` per WORKFLOW §4),
`node_modules/` survived, Flutter SDK gone (NOT reinstalled — this
session's work is TS-side).

**Session task (STATE "Immediately next"): Stage 3, the boxed web parity
set. DONE — and under budget (parity-box session 1 of 2):**

- **Session start = handoff verification first** (the inherited context was
  a context-exhausted MultiEdit with unknown landing state): read the
  harness end-to-end before touching anything. Result: the four owner
  decisions AND their implementation items had all landed (README NOTICE,
  Android INTERNET manifest, macOS network-client entitlement, ROADMAP
  parity scope, v1.0.1 release chain) and the repo had advanced three
  sessions BEYOND that task (Stage-1 execution, Stage-2 entry gate,
  Stage-3 fixtures-first). Only true residual: DECISIONS.md ADR-008/009
  headers still said "DRAFT — owner ratification required" below their
  recorded ratifications — headers synced (status-field fix, ADR-010
  inline-closure precedent).
- **The engine port** (`src/lib/tax/engine.ts`, line-for-line from
  `clearfile/lib/tax/calculator.dart`; parameters in `config.ts` mirror
  `tax_year.dart`): QDI/LTCG stacking (0%/15%/20%, flat $300,000 MFS 15%
  cap), NIIT ($125,000 MFS threshold), SALT 30% phase-down, OBBBA senior
  deduction (MFS ineligible), student-loan MAGI phase-out (MFS ineligible),
  exact 8812 next-$1,000 CTC phase-out with cents normalization and the
  combined CTC+ODC floor, cent-level precision. **The parity suite passed
  16/16, zero field failures, on its FIRST run** — no engine corrections
  were needed; the port was written from the reference + oracle, never by
  adapting fixture numbers.
- **New both-engine harness:** `scripts/web_parity_test.mjs` +
  `scripts/tsconfig.parity.json` (compiles the two tax files to the
  gitignored `.parity-build/`, then asserts every expected key within
  tolerance; `deductionMethodUsed` exact) — wired into the hygiene
  `suites` CI job after the oracle. `.parity-build/` gitignored.
- **Model rewiring across the whole web app:** store persist v1→v2
  migration (conservative: interest→interestIncome, dividends→ordinary,
  adjustments/medical/other dropped, counts→placeholder dependents,
  statuses renamed, year forced to 2025); `.cfr` schema v2 with v1-file
  migration + version guard; all six interview steps (65+/blind switches,
  QSS fifth status, qualified-dividend/LTCG fields, deduction-method
  radio + SALT/charity/student-loan inputs, dependents card editor with
  the two credit flags); TXF/`.tax` exporters and AI prompt summaries
  on the new model. `tsc --noEmit` exit 0; web smoke suite 6/6 against
  the new standalone build (including the persist-migration rehydrate
  path). Disclaimer copy fixed (the old text claimed "no preferential
  capital-gain rates" — now that the engine HAS them, the claim moved to
  the honest remaining simplifications).
- **TY2026 dropped from the web engine** (D32): the reference has no
  TY2026 parameter set, so parity cannot be invented — the old projected
  brackets were removed rather than half-supported; old saves migrate to
  TY2025. README engine sections rewritten (web "at parity", both-engine
  limitations, parity run-block line).
- **Tripwire:** working session 2 of the four-session total; the
  two-session parity box CLOSED in session 1 of 2 (under budget — record
  at the exit gate). Remaining Stage-3 scope: the bridges (TXF import +
  exporter verification, `.clearfile.json` versioning + guards,
  save-format unification decision, parser-hardening tests,
  `docs/engine.md`, guided tour, discrepancy templates, project DoD).

**Session quirks (recorded for honesty):** tsconfig `files` paths resolve
relative to the tsconfig's own directory (first parity run failed on
`scripts/src/...` — STATE quirk 16); `lucide-react` exports `UserPlus`, not
`PersonAddAlt`, and dropping an icon from an import list while it is still
used (`Check`) breaks tsc — both caught by the immediate re-run the bulk
edits mandate (quirk 11 discipline held: tsc + parity + oracle + smoke all
re-ran after every batch, never trusting a single tool's success report).

**Closing action:** full re-verification (web parity 16/16, oracle 16/16,
tsc exit 0, YAML validation on both workflows, web smoke 6/6, harness_check)
+ mode normalization check + event-driven backup (this run) — the last
action before this reply.

## 2026-11-15 · Owner-directed bridges session — TXF import + .tax inspection + Ghidra sandbox feasibility

**Session task (owner prompt, verbatim intent):** explore the feasibility
of Ghidra CLI `analyzeHeadless` running in the sandbox for TurboTax
proprietary-file analysis; add the full capability to work with these
formats to ClearFile; use Material You for the UI on all OSes.

**Bootstrap:** fifth observed recycle — history intact (HEAD = origin/main
= `769e57b`), node_modules survived minus its typescript bin (quirk 18),
tools/ gone. Restored per WORKFLOW §4: Flutter 3.47.9 (sha `25ed8c3c…`
verified), plus NEW Ghidra 12.1.4 + Temurin JDK 21 + bench harness
(`tools/re/`, all gitignored). Recorded as ADR-013.

**Ghidra feasibility verdict (measured, not guessed):** Ghidra 12.1.4 +
JDK 21 runs analyzeHeadless end-to-end in this sandbox — exit 0, 11 s
wall, 416.9 MiB peak RSS under a 1 GB heap (`GHIDRA_HEADLESS_MAXMEM`),
26 functions auto-identified on a 16 KB synthetic stand-in binary, and a
Java postScript located the embedded AES S-box (computed from the
Rijndael definition — zero proprietary material) at `00102060` and the
ZIP magic at `00102040`. Ghidra 12.2 (latest) requires JDK 25 and
refuses this JDK 21 box — 12.1.4 is the JDK-21 line and matches the
protocol's GhidraMCP pin. Limits: 2 cores / ~1.8 GB free / no swap —
fine for scripted sweeps, heavy proprietary executables belong in
§4.A/C. Evidence: `docs/ghidra-sandbox-feasibility.md` + protocol §4.E;
this is pre-gate research feeding the Stage-2 entry gate (ADR-012), NOT
a stage re-entry.

**Bridges (Stage-3 scope, done):**
- Flutter `io/txf_import.dart` — TXF spec v042 import: `^`-terminated
  records, W-2 copies grouped by C (460/461/466 + spouse 506/507/513 in
  their own copy space), income 287/286/683/488/257, deductions
  275/544/276/283/545/280/485, payments 268/521, adjustment 636; spec
  sign convention (expenses negative) → magnitudes; unknown refnums
  reported not guessed; hardening caps 5 MB / 10k records / 4096-char
  lines; 11 tests.
- Flutter `io/tax_inspect.dart` — read-only `.tax` inspection: ZIP
  central-directory scan (STORE extraction, deflate listed), per-entry
  Shannon entropy + likely-encrypted flag (≥7.5 bits/byte), modern
  Intuit-shape recognition (`manifest.xml` + `tax:<uuid>`) with copy
  that names the safe bridges and states it does not decrypt (§2.2/§7),
  ClearFile exchange-container import; 7 tests. Wired into
  Welcome/AppState (import TXF + inspect .tax buttons + dialogs).
- Web TXF exporter rewritten to spec-true codes — the old 425/426 are
  the 4952 investment-interest family; now 460/461/466 per W-2 copy +
  287 + 636 with negative money-paid signs; `taxfile.ts` gained the same
  Intuit-shape + entropy analysis (additive API). New CI bridge suite
  `scripts/txf_taxfile_test.mjs` (+ `scripts/tsconfig.files.json`,
  CommonJS emit so Node resolves extensionless intra-module imports),
  wired into the hygiene `suites` job after the parity suite.

**Material You:** main.dart upgraded to complete MD3-from-seed theming
(flat surfaces, floating snackbars, filled-button comfort, dialog/app-bar
surface tones) — identical on all six platforms; the ADR-007 revisit
was executed against dynamic_color 2.1.0 (2026-08-20) and the recorded
ColorScheme clash reproduced verbatim (`argument_type_not_assignable`
against the 3.47 material_ui split) → reverted; revisit closed with
evidence.

**Verification:** flutter analyze clean; flutter test 95/95 (77 + 18
new); tsc --noEmit exit 0; web parity 16/16 (regression); bridge suite
6/6; Ghidra bench exit 0. Quirks 17 (background processes die between
tool calls) and 18 (selectively hollowed node_modules / tsc squatter)
recorded in STATE.

**Decisions:** ADR-013 (this session's scope: feasibility-run-and-measure,
bridges-as-safe-bridges, Material-You-as-MD3-seed + negative dynamic_color
retry).

**Honest limits carried forward:** no TurboTax binary was analyzed (none
owned here), no `.tax` file was decrypted, no key material exists
anywhere (protocol §2.2/§7); the AES layer remains gated behind the
Stage-2 entry gate's placement decision.

**Closing action:** re-verification (analyze + 95/95 + tsc + parity +
bridge suite + harness_check) + this event-driven backup — the last
action before the reply.

### Correction note (append-only, same session)

The bridges-session entry above predates two teardown facts worth recording:
(1) the web smoke suite also ran against the new build — 6/6, including the
localStorage persist/rehydrate path — completing the re-verification set
(analyze + 95/95 Dart + tsc + parity 16/16 + bridge suite + smoke + Ghidra
bench + harness_check); (2) the user-facing deliverable was produced as
`download/ghidra-sandbox-feasibility.pdf` (6 pages, cover Template 01 +
ReportLab body, QA pass) alongside the in-repo
`docs/ghidra-sandbox-feasibility.md`, with the cover HTML source kept next
to it per the delivery convention.
