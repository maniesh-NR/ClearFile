# Adversarial consensus ledger

Gate records, in order. Append-only: a gate is never edited after its
outcome is recorded; corrections append a dated note.

---

## Gate: Stage 0 → Stage 1 · 2026-11-14

**Reviewers (4, independent):** ADV-SEC (Red Team / Security), ADV-LEGAL
(Counsel / Compliance), ADV-ENG (Staff Engineer / Quality), ADV-PROD
(Product Strategist / Roadmap). Full reports, near-verbatim, in
`reports/2026-11-14-stage0-{security,legal,engineering,product}.md`.

**Independence:** all four ran concurrently as isolated agents with no
visibility of each other's reports; verdicts were computed only after all
four returned. The panel was convened to review (a) all work completed so
far (web prototype, Flutter app, v1.0.0 release, RE protocol, hygiene
pass) and (b) the draft roadmap.

### Verdicts

| Reviewer | Verdict | Blocking? |
| --- | --- | --- |
| ADV-SEC | PROCEED-WITH-CONDITIONS (6) | no |
| ADV-LEGAL | PROCEED-WITH-CONDITIONS (5) | no |
| ADV-ENG | PROCEED-WITH-CONDITIONS (6) | no |
| ADV-PROD | PROCEED-WITH-CONDITIONS (6) | no |

Unanimous non-BLOCK → **consensus reached**. Per WORKFLOW.md §2, the gate
passes when every condition is applied or rebutted; the ledger below shows
each condition's disposition.

### Condition ledger

**Applied in-session (2026-11-14, commit evidence in the backup commit
that closed this session):**

- SEC-1 / ENG-2 — `scripts/sandbox_backup.sh` rewritten: branch guard
  (`main` only), `check_unpushed()` on the no-op path (`git fetch` +
  `origin/main..main` non-empty → exit 1), PAT-sanitized push errors
  (`sed` redaction), 0600 `mktemp` + `trap` cleanup.
- SEC-2 / LEGAL-4 — secret guard widened (classic `ghp_/gho_/ghu_/ghs_`,
  `sk-ant-`/`sk-proj-`, AWS `AKIA`, Slack `xox`, `npm_`, `glpat-`, PEM
  blocks) + raw-64-hex heuristic with lockfile exclusions (verified no
  false positives against the staged tree); `/upload/` added to the
  `.gitignore` backup scope (verified via `git check-ignore`).
- SEC-3 — CI least privilege (`contents: read` workflow-wide, `contents:
  write` only on the release job); pwsh uses `$env:RELEASE_TAG` instead of
  `${{ github.ref_name }}`; every job validates `RELEASE_TAG` against
  `^v[0-9][0-9A-Za-z._-]*$`; `workflow_dispatch` now takes a required tag
  input; `timeout-minutes` + a `concurrency` group on every job.
- SEC-4 / LEGAL-3 / ENG-5 — release integrity: `SHA256SUMS.txt` generated
  into the release (collision-guarded flatten); explicit demo-disclaimer
  `body:`; **live v1.0.0 release description patched via API (HTTP 200,
  verified)**; `package-lock.json` committed + `npm ci` + `npx tsc
  --noEmit` typecheck in CI; `store.ts` migration double-cast fixed;
  `typescript.ignoreBuildErrors` turned **off** (tsc exit 0 for all
  tracked code).
- SEC-6 — PAT policy recorded in WORKFLOW.md §5 (fine-grained profile,
  Contents:RW ≙ repo-admin, rotation at every recycle / ≤90 days /
  immediately if echoed, expiry attestation, branch-protection
  recommendation).
- ENG-1 — delete-return resurrection fixed (`deleteReturn` cancels the
  debounce; timer callback identity-guarded) **+ regression test written**
  (`clearfile/test/delete_regression_test.dart`). ⚠️ Not yet executed: the
  Flutter SDK was recycled away; `flutter test` must show 43/43 at Stage-1
  entry before this is counted verified.
- ENG-3 / PROD-1 / PROD-4 — README truth sweep: two-engine split with
  per-implementation scope, real "Engine limitations" section, GitHub
  Releases row replaces the stale `download/` row, 19-test count fixed;
  `clearfile/README.md` rewritten from template boilerplate.
- ENG-4 — dispatch semantics fixed beyond naming (validated tag input
  flows to the release step's `tag_name`); timeouts + concurrency
  (per SEC-3).
- ENG-6 — harness pointer audit: §-references corrected (session protocol
  §3, recycle runbook §4, backup scope §1), `verdict**` typo, STATE.md
  `node_modules` line corrected in the final refresh.
- LEGAL-5 — RE protocol §7 publication guardrails appended (owner-authored
  corpus only; decrypted content never published; crypto constants by
  existence; no expression lifts; per-spec pre-commit checklist) — applied
  BEFORE any Stage-2 tooling, as required.
- PROD-2 / PROD-4 / PROD-5 / PROD-6 — ROADMAP amended: gate depth tiering
  (full-depth gates for Stage-1 entry + Stage-2; delta-scoped elsewhere),
  per-stage implementation-target matrix, Stage 1 re-sequenced (decisions
  first), privacy disclosure pulled into Stage 1 from Stage 5, Stage 4 cut
  to the GitHub Pages deploy (AppImage/.aab → backlog with revisit
  trigger), terminal "Freeze & codify" stage + definition of work added.
- PROD-3 — this CONSENSUS.md exists with the actual verdicts; the
  pre-recorded SESSION_LOG bullets are reconciled by an appended
  correction note (append-only honored).
- Debt register: ADV-ENG findings 9-19 + SEC/LEGAL minor findings tracked
  in `harness/memory/DEBT.md` (D1-D21) rather than left to be rediscovered.

**Assigned to Stage-1 entry (must be applied before Stage-1 feature work
starts; Stage 1 is NOT entered until these clear):**

1. LEGAL-2 (privacy copy matches code): `buildReviewPrompt` personal
   fields (dependent names/relationships, W-2 employer strings) gated on
   `sendReturnContext` or stripped; `sendReturnContext` default flipped
   or default disclosed in switch copy; Settings/Welcome copy aligned;
   `clearfile/test/` assertion that the review prompt contains no
   dependent-name string when sharing is off; web auto-fill "collects vs
   transmits" wording (D17).
2. ENG-1 verification: reinstall the Flutter SDK; `flutter analyze` +
   `flutter test` = 43/43 green (includes the new delete regression).
3. SEC-4 remainder: signing story decision (or explicit unsigned-demo
   posture on the release page, which the new `body:` already states).
4. ENG conditions carried in ROADMAP Stage 1 items 6-9 (gitleaks CI,
   caching is drafted, action SHA pinning D10, SECURITY.md D13, GPL
   headers D14, harness self-check D19, widget-test expansion +
   `ReturnStore` seam D4, web smoke test).

**Owner decisions required (surfaced in the closing reply; recorded so
the gate does not advance anything silently):**

1. **ADR-008 ratification** — confirm you authored `nitro_nissi`
   (evidence says yes: same-conversation lineage, the repo's own "Rename
   project to ClearFile" commit). Yes → accept-and-document + README
   NOTICE; No/unverifiable → history rewrite with orphan-branch source
   preservation.
2. **ADR-009 ratification** — freeze the web prototype (recommended) or
   commit to feature parity.
3. **D20 / SEC-1** — Android release INTERNET permission: add + disclose
   network use, or compile the AI UI out of Android release builds. Also
   decides whether macOS release gets the network-client entitlement.
4. **PAT hygiene** — set/renew an expiry (≤90 days) on the fine-grained
   PAT and enable branch protection on `main` (owner-side; see WORKFLOW
   §5).

**Orchestrator notes (not conditions; recorded for honesty):** ADV-SEC
and ADV-ENG independently confirmed the cross-run artifact poisoning
surface is closed and the calculator/cascade tests are rigorous. The
panel's own review of the harness (the pre-recorded session log) was
corrected rather than rebutted. The workflow's `concurrency` group uses
`cancel-in-progress: false` so queued releases never cancel mid-flight.

### Gate outcome

**Stage 0: PASSED** (unanimous PROCEED-WITH-CONDITIONS; all conditions
applied, assigned, or surfaced to the owner as recorded above).
**Stage 1: NOT ENTERED** — entry conditions (the four owner decisions and
the Stage-1 entry list above) are pending. Next session's first task per
WORKFLOW.md §3.4 is to confirm/clear them, then convene the Stage-1 gate.

---

## Appendix: owner decisions + Stage-1 entry conditions · 2026-11-14

**Owner decisions received in-conversation (verbatim):** "1. accept and
document  2. pursue feature alignment  3. add and disclose  4. do not
alter PAT". All four were required gate outputs; each is applied and
ratified in `memory/DECISIONS.md`:

1. **ADR-008 RATIFIED — accept-and-document.** README NOTICE paragraph
   added (nitro_nissi = the owner's earlier project iteration, history
   only). No rewrite; v1.0.0 identity stands.
2. **ADR-009 RATIFIED — feature parity** (against the panel's freeze
   recommendation; explicit owner prerogative). ROADMAP Stage 3 carries
   the web-engine parity features; parity tests must cover both engines
   on shared golden fixtures.
3. **D20 DECIDED — add and disclose.** Android main-manifest INTERNET
   permission, macOS network-client entitlement, in-app disclosure
   (welcome footer + settings privacy copy), release-body network
   disclosure.
4. **PAT — unchanged** (risk acknowledged, recorded in WORKFLOW §5).

**Stage-1 entry conditions cleared in the same session:**

- LEGAL-2 (privacy copy matches code): applied — `buildReviewPrompt`
  de-identified by construction (employer/dependent names stripped;
  counts and figures only — the "or stripped" branch of the condition),
  `sendReturnContext` defaults OFF with the default disclosed in the
  switch copy, Settings/Welcome/blueprint-generator copy aligned, web
  auto-fill "stores vs transmits" wording fixed, web title de-"Filing"-ed.
  Contract pinned by `clearfile/test/privacy_test.dart` (4 tests).
- ENG-1 verification: Flutter SDK reinstall in progress at ledger time;
  `flutter analyze` + full `flutter test` (now 44 planned: 19 calculator,
  8 cascade, 9 CSV, 3 JSON, 3 widget, 1 delete-regression, 4 privacy) to
  be recorded in the Stage-1 gate input below when green.
- SEC-4 remainder: signing posture = unsigned-demo (stated on the release
  body); v1.0.0 release description already patched (200, verified).

**Gate plan:** Stage-1 full-depth gate convenes immediately after the
test run is green; its four reports will be filed under
`reports/2026-11-14-stage1-*.md` and its verdict appended below.

---

## Gate: Stage 1 entry · 2026-11-14 (convened after entry conditions cleared)

**Reviewers (4, independent, full-depth):** ADV-SEC, ADV-LEGAL, ADV-ENG,
ADV-PROD. Reports filed near-verbatim in
`reports/2026-11-14-stage1-{security,legal,engineering,product}.md`.
All four independently re-ran verifications (tsc, analyze, guard greps,
test counts, live release page/API where reachable).

**Gate input — verified entry facts (recorded here per ENG-3/PROD-4):**
`flutter analyze` — No issues found (fresh SDK 3.47.9, sha256-verified
install); `flutter test` — **+47: All tests passed** (first run, 2026-11-14,
the run this gate was gated on; after the gate's own condition fixes the
suite re-ran at **+49: All tests passed** — 19 calculator, 8 cascade, 9
CSV, 3 JSON, 4 privacy, 1 delete-regression, 1 switch-regression, 3
widget + 1 findings-leak privacy test);
`npx tsc --noEmit` — exit 0.

### Verdicts

| Reviewer | Verdict | Blocking? |
| --- | --- | --- |
| ADV-SEC | PROCEED-WITH-CONDITIONS (5) | no |
| ADV-LEGAL | PROCEED-WITH-CONDITIONS (4) | no |
| ADV-ENG | PROCEED-WITH-CONDITIONS (4) | no |
| ADV-PROD | PROCEED-WITH-CONDITIONS (5) | no |

Unanimous non-BLOCK → **consensus reached. Stage 1 ENTERED** (its
execution scope = ROADMAP items 5-9 + the v1.0.1 closing event).

### Condition ledger — all conditions applied in-session unless noted

- SEC-1 / LEGAL-2 — README opt-in sentence scoped per implementation
  (Flutter switch vs web always-attached summary), review-button exception
  stated, web auto-fill exception stated; v1.0.0 AI-broken note added to
  README; release body carries the same exception clauses.
- SEC-2 — `check_unpushed()` fetch stderr now goes through the same 0600
  mktemp + sed sanitizer with a script-owned failure message (also clears
  ENG note 5's exit-code drift).
- SEC-3 — `-I` dropped from both guard greps (binary coverage).
- SEC-4 — `bun.lock` deleted (npm lockfiles standardized; CI is `npm ci`).
- SEC-5 — **assigned to Stage-1 execution**: gitleaks CI scan, action SHA
  pinning, dispatch dry-run (fresh-tag AND existing-tag), v1.0.1 tag with
  SHA256SUMS + first full hardened-CI run (the stage's own scope, with
  verification evidence due at the Stage-2 gate).
- LEGAL-1 — blueprint: the three contradictory sentences + all
  "Filing Assistant"/"never collects" strings corrected in the generator
  AND the cover (playwright re-render); regenerated; **verified by text
  extraction** (Filing Assistant gone, never-collects gone, auto-fill
  exceptions present, Study-Prototype title present).
- LEGAL-2 — see SEC-1; **live v1.0.0 release description re-patched (API
  200, verified: "cannot reach AI providers" + GPL §6 corresponding-source
  line present)** — clears the false "noted in the NOTICE" record and adds
  the §6 statement (LEGAL note 11).
- LEGAL-3 — publication sequencing discharged by this session's closing
  backup; verification recorded below (post-push check of NOTICE/privacy
  on origin/main).
- LEGAL-4 — grandfathered consent: settings `schemaVersion: 2` +
  one-time reset of `sendReturnContext` for schema-less legacy files
  (decision recorded in DECISIONS.md); roundtrip/legacy behaviour pinned
  by tests.
- ENG-1 — switch-path autosave flush (`_open` cancels + saves the prior
  return) + switch regression test; 49/49 green.
- ENG-2 — findings-path privacy test (leaky fixture triggers both
  name-bearing findings; asserts prompt clean).
- ENG-3 — this entry itself + README run-block count fixed (47) + the
  correction note below.
- ENG-4 — `store.ts` migrate now performs real shape checks
  (Array.isArray for list fields, object checks for containers).
- PROD-1 — v1.0.0 disclosure + fix vehicle: live release patched, README
  note added, **ROADMAP Stage 1 closing event = v1.0.1 tag** (INTERNET fix
  + first SHA256SUMS + hardened-CI first run; dispatch dry-run is its
  rehearsal).
- PROD-2 — parity tripwire: two-session box on the web parity set; exceed
  or slip → web-freeze returns to the next gate agenda as a mandatory
  item; golden fixtures land FIRST in Stage 3; doubled-cost statement
  added beside the implementation-target matrix.
- PROD-3 — gate-doc reconciliation: WORKFLOW §2.2 now carries the tiering
  cross-reference + a fuller-scope-wins tiebreaker; harness_check
  checklist (ROADMAP item 9) includes the cross-document consistency
  check.
- PROD-4 — this entry + STATE.md refresh.
- PROD-5 — mode normalization before the closing backup (verification
  below).
- Notes applied: dead `buildFieldQuestion` deleted (SEC-7/LEGAL-9);
  concurrency group tag-only (ENG-6); existing-tag dispatch guard folded
  into ROADMAP item 6 (ENG-7); blueprint pipeline portability documented
  (scripts/README.md, ENG-8/PROD-8); RE protocol `ole_cfb.dart` pointer
  fixed (LEGAL-8); pubspec description fixed (LEGAL-5/PROD-10); scripts
  README written (PROD-8). PROD-7 (Stage 2 vs 3 ordering) is noted for the
  Stage-2 gate agenda, per the reviewer's own framing.

### Correction note (append-only)

The appendix above says "now 44 planned" — its own itemization (19+8+9+3+3+1+4)
sums to 47; the correct planned total at that moment was 47, and after the
gate's condition fixes the suite stands at 49 (the switch regression and
findings-leak tests were added). Recorded as a correction, not an edit.

### Gate outcome

**Stage 1: ENTERED** (unanimous PROCEED-WITH-CONDITIONS; every condition
applied in-session or explicitly assigned to Stage-1 execution with a
named verification event). Stage-1 feature work may proceed; its exit
gate is the Stage-2 entry gate.

---

## Gate: Stage 2 entry (closes Stage 1) · 2026-11-14

**Reviewers (4, independent, full-depth):** ADV-SEC, ADV-LEGAL, ADV-ENG,
ADV-PROD. Reports filed near-verbatim in
`reports/2026-11-14-stage2-{security,legal,engineering,product}.md`.
All four ran concurrently as isolated agent contexts with no visibility
of each other's reports; verdicts were computed only after all four
returned. The panel reviewed (a) the Stage-1 execution evidence (commits
`a0e6d34`, `0bbb564`, `7b16e12`, the live v1.0.1 release and CI runs),
(b) the full repository state (full-depth per the tiering), and (c) the
Stage-2 plan plus this gate's agenda: Stage-2-vs-Stage-3 ordering, the
parity tripwire clock, and the RE-tooling repo placement.

**Gate input — verified facts (orchestrator; independently re-verified by
the reviewers, including two separate re-runs of the full suite):**
`flutter analyze` — No issues found; `flutter test` — **+61: All tests
passed**; `npx tsc --noEmit` — exit 0; `bash scripts/harness_check.sh` —
11 checks, 0 failures. Live checks: release 445310560 (11 assets incl.
`SHA256SUMS.txt`; tag `v1.0.1` → exactly `0bbb564` locally and via
`git ls-remote`), run 43598726491 (8/8 success, ~6.4 min), refusal drill
run 43598383213 (6 build jobs fail at the guard step, publish skipped),
hygiene runs 43598360301 and 43599541432 (both success). Two reviewers
independently re-verified the checksum chain (one full download +
`sha256sum -c` OK; one live-asset-vs-tagged-tree sha256 match on the RE
protocol doc). Recorded limitation: the shared sandbox IP exhausted the
unauthenticated api.github.com rate limit; reviewers fell back to public
HTML pages and, sparingly and without echoing it, authenticated calls per
WORKFLOW §5. All 7 action SHA pins were resolved live against upstream
tags by two reviewers independently — every pin exact.

### Verdicts

| Reviewer | Verdict | Blocking? |
| --- | --- | --- |
| ADV-SEC | PROCEED-WITH-CONDITIONS (4) | no |
| ADV-LEGAL | PROCEED-WITH-CONDITIONS (4) | no |
| ADV-ENG | PROCEED-WITH-CONDITIONS (6) | no |
| ADV-PROD | PROCEED-WITH-CONDITIONS (5) | no |

Unanimous non-BLOCK → **consensus reached**.

### Agenda settled (recorded per the gate's mandate)

1. **Stage-1 closure: YES — unanimous.** All four reviewers answered the
   closure question with live-verified evidence: the gitleaks/CI hardening
   is real (pins resolve against upstream), the dispatch guards are proven
   in both directions (fresh-tag publish at the exact built commit;
   existing-tag refusal with zero build steps run), the release checksum
   chain is correct end-to-end, and every memory-record claim probed
   matched reality. Residuals (ENG-1/2/3, SEC-1/2/3/4, LEGAL-1/2/3,
   PROD-4) are ledgered, not closure blockers.
2. **Ordering: SWAP — Stage 3 (parity & bridges) is entered next; Stage 2
   (RE tooling) is re-sequenced after it.** The panel split honestly:
   ADV-ENG and ADV-PROD explicitly recommended the swap (PROD-2: no
   cross-dependency either way, front-loads the owner-ratified parity
   value against single-maintainer abandonment risk, narrative
   coherence; ENG-3: golden fixtures are pure correctness infrastructure
   while RE-tooling value does not decay); ADV-LEGAL found both defensible
   with a fixtures-first lean (IRS-pinned fixtures are §105 government
   edicts — the best clean-room derivation evidence); ADV-SEC recommended
   keeping Stage-2 order (no security payoff to reordering; Stage 3 is
   the shipped-attack-surface milestone). The orchestrator settles the
   swap on the majority recommendation + the value/burnout logic; the
   owner may overrule — if the RE stage is pulled forward instead, PROD's
   fallback applies (define N and the time-box before its entry). SEC's
   standing caution travels regardless: format specs must not drift into
   parser implementation before the version guard ships (D3, inside the
   now-first Stage 3 scope — structurally satisfied).
3. **Parity tripwire: INTACT (all four confirm); the clock is now
   defined** (was PROD-3's finding — "slips" had no baseline): baseline =
   the Stage-3 entry session (2026-11-14, this gate); box = two working
   sessions on the web parity set; slip = the Stage-3 exit gate not
   convened within four total working sessions of entry
   (fixtures-first included); exceed-or-slip → web-freeze returns to the
   next gate as a mandatory item. Recorded in ROADMAP.
4. **Repo placement (RE tooling): DEFERRED to the RE stage's own entry
   gate** — a genuinely split panel (ADV-LEGAL default: separate research
   repo, narrative + auto-publish denylist reasons; ADV-PROD: in this
   repo with constraints, reversing its Stage-0 lean; ADV-SEC: mild
   in-repo under its conditions). The gate that enters the RE stage must
   settle it as ADR-012 with the carried conditions below.

### Condition ledger — dispositions

**Applied in-session (this gate's session; commit evidence is the
closing backup):**

- **SEC-1 / LEGAL-1 — GPL §6 corresponding-source sentence added to the
  release template** (`.github/workflows/release.yml` `body:`, same
  wording as the live-patched v1.0.0 description). Every future tagged
  release carries it. Checkable: template grep + next release body.
- **LEGAL-2 — vendored-code attribution:** `THIRD-PARTY-NOTICES.md`
  created (shadcn/ui MIT attribution for `src/components/ui/**` +
  `src/hooks/**`, MIT notice reproduced) + a README License-section
  pointer row.
- **ENG-1 — the release tag guard is now FAIL-CLOSED on unexpected fetch
  errors** (all 7 copies in `release.yml`): only the "couldn't find
  remote ref" case proceeds as a fresh tag; any other fetch failure
  refuses to build. YAML re-validated; the guard body is functionally
  proven by `scripts/test_tag_guard.sh`, which extracts the guard
  VERBATIM from release.yml and exercises all four branches (4/4
  scenarios green: existing-tag-elsewhere refused, existing-tag-match
  passes, absent tag treated as fresh, non-missing-ref error refused).
- **ENG-2 / SEC-3 — the phantom `-c` flag promise removed** from
  `scripts/harness_check.sh` (the check itself stays fail-closed).
- **ENG-3 / ENG cond 5 — DEBT.md D2 amended** (append-only note): the
  empty-wages-cell→0 semantic was deliberately retained as documented
  behaviour, not converted to a warning; the adjacent `MoneyField`
  silent-ignore asymmetry is now D28 (Stage 3).
- **ENG-4 / ENG cond 3 — push-CI for the suites:** `hygiene.yml` gains
  the `suites` job (flutter analyze + flutter test + npm ci + tsc on
  push to main). A red suite can no longer sit on main until the next
  release. The job follows the repo posture (SHA-pinned actions,
  `contents: read`, timeout) — satisfying SEC cond 1's posture rule for
  any new job.
- **PROD cond 1 — the swap is executed with STABLE stage IDs**
  (re-sequencing, not renumbering — the cross-reference sweep
  README/DECISIONS/DEBT/tripwire text stays true by construction):
  ROADMAP carries the execution-order note (1→3→2→4→5→6), the
  re-sequencing tiering note, and the Stage-2 entry-gate agenda; the
  RE stage's entry remains the designated full-depth gate (and is
  Stage 3's exit gate); `harness_check.sh` patterns updated for the
  legitimate advance; checker re-run green after.
- **PROD cond 3 / PROD-3 — the tripwire clock is defined at Stage-3
  entry** (see agenda item 3; recorded in ROADMAP).
- **PROD cond 5 / PROD-4 — README v1.0.0 AI-broken note fixed** to read
  "Fixed in the v1.0.1 release" (was future-tense for a shipped event).
- **LEGAL-3 — RE protocol header date bumped** to 2026-11-14 (§7 was
  added 2026-11-14).

**Assigned to the RE-tooling stage (re-sequenced after Stage 3; must be
settled at its entry gate — which is also Stage 3's exit gate):**

- **SEC cond 1 — RE tooling security contract:** permissions read,
  timeouts, SHA-pinned actions, no `pull_request_target`/fork surface;
  write-free + resource-bounded tools with crash-safe/refusal tests —
  verified at that gate by reading the tool code and tests, not by
  assertion.
- **SEC cond 2 / ENG cond 2 / PROD-5 — the no-binary-blob assertion is
  CI-checkable and lands with the first tooling commit:** unit-test
  fixtures are program-synthesized bytes; an explicit synthetic vs
  owner-authored provenance distinction (allow-list or runtime
  generation); resource caps pinned by tests.
- **LEGAL cond 2 — synthetic-fixture rule executable:** never real
  proprietary files; fixture paths enumerated; nothing decrypted or
  key-material ever committed (§7.2/§7.3).
- **LEGAL cond 3 / PROD cond 4 — placement ADR-012 recorded BEFORE
  tooling lands**, with the panel split above. If in-repo: enumerated
  fixture path + assertion in `hygiene.yml` + §7.5 checklist
  spot-verification at exit. If separate-repo: pinning,
  least-privilege, and secret-guard/gitleaks standards replicated first
  (SEC cond 3).
- **PROD cond 2 / PROD-1 — the RE stage's DoD fixed:** N defined (a real
  number matched to the owner-authored corpus actually available) + a
  real time-box (two working sessions, same unit as the parity box);
  checkable by counting published specs and sessions at its exit gate.
- **ENG cond 6 (second half) / ENG-5 / D29 — the tag-PUSH trigger path**
  verified once at the NEXT tagged release, or the push trigger is
  dropped for dispatch-only. (The fail-closed guard half is applied
  in-session above.)

**Surfaced to the owner (owner-side actions; the standing PAT posture
in WORKFLOW §5 is unchanged):** SEC-2 / SEC-4 — enable Dependabot alerts,
branch protection on `main`, and PAT expiry when next rotating (tracked
as D30). None blocks the gate; all are re-affirmed standing
recommendations.

**Orchestrator notes (recorded for honesty):** every reviewer
independently re-ran the local suites and at least one live check; two
found the API rate limit and said so in their reports rather than
pretending. The ordering settlement records a split panel, not
unanimity — the swap is the gate's reasoned decision under its mandate
("the gate also settles Stage-2-vs-Stage-3 ordering"), with the owner
overrule path and fallback recorded. The re-sequencing deliberately
avoids renumbering stages (cross-references stay true; harness_check
green). Stage-1's roadmap row for Stage 1 and the README's "Roadmap
Stage 3" phrasing remain correct because stage IDs are stable. One extra
full-depth gate cost is acknowledged (PROD-2's honest cost statement).

### Gate outcome

**Stage 1: CLOSED** (unanimous; the execution evidence held up under
full-depth live verification on all four seats).

**Stage 3: ENTERED** (under the re-sequencing settled at this gate — the
full-depth panel reviewed the Stage-3 plan on this gate's agenda).
Execution begins with the shared golden fixtures FIRST (fixtures-first
per the tripwire; clock baseline 2026-11-14). The stage's exit gate is
the RE-tooling stage's entry gate (full-depth, ADV-LEGAL weighted), which
must also settle the placement ADR-012 and the RE stage's DoD, and review
the parity-tripwire outcome.

**Stage 2: PENDING** (re-sequenced after Stage 3; its entry-gate agenda
is carried in the ledger above and mirrored in ROADMAP).

---

## Gate: Stage 2 entry (closes Stage 3) · 2026-11-17

**Reviewers (4, independent, full-depth):** ADV-SEC, ADV-LEGAL, ADV-ENG,
ADV-PROD. Reports filed near-verbatim in
`reports/2026-11-17-stage2-{security,legal,engineering,product}.md`.
All four ran concurrently as isolated agent contexts with no visibility
of each other's reports; verdicts were computed only after all four
returned. The panel reviewed (a) the Stage-3 execution evidence (commits
`99d6823`, `769e57b`, `74a1286`, `935f782`, `a18b160`), (b) the full
repository state (full-depth per the tiering), and (c) the Stage-2 plan
plus this gate's agenda: the Stage-3 closure question, the parity
tripwire outcome (slip fired — mandatory item), the ADR-014 native
re-platforming settlement, placement ADR-012, the RE stage's DoD fix,
and the RE tooling security contract. Convened 2026-11-17 — two days
after the close-out commit scheduled it (the slip already recorded); the
agenda therefore carried the mandatory web-freeze argument.

**Gate input — verified facts (orchestrator; independently re-verified by
all four reviewers with their own runs, including four separate full
Dart-suite runs and a fifth from the orchestrator):** `flutter analyze`
— No issues found; `flutter test` — **+111: All tests passed** (pre-gate;
113/113 after the in-session ENG-1/ENG-2 condition fixes below);
`npx tsc --noEmit` — exit 0; `scripts/txf_taxfile_test.mjs` — 10/10
groups; `scripts/web_parity_test.mjs` — 16/16 fixtures, 0 field
failures; `scripts/verify_golden_fixtures.py` — 16/16;
`scripts/web_smoke.py` — 6/6; `scripts/harness_check.sh` — 12 checks,
0 failures. Live: `main` = `a18b160` (local HEAD = origin/main; the
ninth-recycle era); tags `v1.0.1` → exactly `0bbb564`, `v1.0.0` →
`a121f11` (via `git ls-remote`); hygiene CI green on `a18b160` (push run
43713252346, weekly run 43872210841). One adversarial repro was
contributed by a reviewer and is now a regression test (ENG-1). One
independence incident, disclosed: ADV-LEGAL's early tree-wide `git grep`
printed ~15 matching lines from *archived 2026-11-14* reports
incidentally; the reviewer did not open any reports file, excluded the
path from every subsequent scan, and disclosed it in its verification
log. ADV-PROD noted an untracked 2026-11-17 report file appearing on
disk mid-session (a concurrent reviewer's own output — not opened). No
reviewer saw another's report.

### Verdicts

| Reviewer | Verdict | Blocking? |
| --- | --- | --- |
| ADV-SEC | PROCEED-WITH-CONDITIONS (6) | no |
| ADV-LEGAL | PROCEED-WITH-CONDITIONS (5) | no |
| ADV-ENG | PROCEED-WITH-CONDITIONS (5) | no |
| ADV-PROD | PROCEED-WITH-CONDITIONS (5) | no |

Unanimous non-BLOCK → **consensus reached**.

### Agenda settled (recorded per the gate's mandate)

1. **Stage-3 closure: YES — unanimous (4/4).** Every reviewer verified
   the execution evidence against the ROADMAP scope with their own
   runs: the parity suite genuinely runs the TS engine on the same 16
   fixtures (ENG read the harness code); the store writes the envelope
   on disk (test-asserted); TXF import is spec-true and hardened;
   `.tax` inspection is read-only with no key material (SEC/LEGAL full
   tree+history scans, zero hits); the unified format genuinely fixed
   the cross-codebase container-import bug; the docs make the study
   legible without git history. Stage 3 is **CLOSED 2026-11-17**.
   Residuals ledgered (ENG-1..5 — ENG-1 fixed in-session below; SEC-1
   applied in-session below), none blocking.
2. **Parity tripwire (the mandatory item): DISPOSED — recorded, not by
   silence.** Argued explicitly by all four. ADV-SEC, ADV-LEGAL, and
   ADV-ENG recommended a freeze in substance (parity value banked in
   the CI fixture contract; ×2 cost per engine change with zero
   mechanical linkage; ADR-014's Rust core makes the TS engine a
   transition artifact). ADV-PROD recommended continued parity narrowed
   to maintenance with retire-on-replacement (a pre-emptive full freeze
   recreates the D32 divergence shape). The positions converge in
   practice; the gate settles **ADR-016: TS-engine maintenance freeze**
   (no NEW web-engine features; bug/security fixes + the staged
   Stage-5 hardening halves + format-guard compliance +
   reference-mirrored corrections via the shared-fixture contract) with
   retire-on-replacement and the owner-overrule path recorded (the
   owner may reinstate full parity or order a hard freeze by a
   recorded reversal ADR — never by silence).
3. **Native re-platforming settlement (ADR-014 → ADR-017): SETTLED
   before any native-stack code lands.** Unanimous: staged per-OS (never
   big-bang; the Flutter app is the transition vehicle; each native GA
   retires that Flutter target; conservative planning assumes v1.0.1
   binaries may be in real users' hands); a **finite post-Stage-6
   epilogue program** (N1 Rust core → N2 Linux → N3 Android → N4 Windows
   → N5 macOS → N6 web-WASM + terminal freeze), with the recorded
   variant that the Rust core alone may run parallel to Stage 4+ behind
   its own gate; core scope = engine + parameter tables + format codecs
   + MD3-from-seed palette (AI cascade, filesystem I/O, and UI excluded
   — the envelope is the ABI); one flat C ABI (cbindgen) with Linux
   linking the crate directly; macOS = ONE Swift+AppKit app tiered by
   deployment floor 13 (the owner's "Swift newer / AppKit older"
   resolves to a deployment-target tier, not two UIs); Linux = the
   owner's two-tier assignment with one toolkit per tier (gtk3-rs
   older / Slint modern; Qt only under GPL-3.0 terms as recorded
   fallback; consolidatable at N2); KMP Android-only; **iOS dropped
   from the native end-state — decided explicitly per PROD-1** (the
   owner may add an iOS row by recorded ADR); **v2.0.0 at the first
   native GA** (envelope version stays 2; app semver ≠ envelope schema ≠
   web package.json); ADR-009 superseded by single-core parity when the
   core serves every platform (TS frozen per ADR-016, retires on WASM;
   Dart stays reference until the core's fixture parity is green).
   Verification annex (ENG): the 16 golden fixtures become the Rust
   regression contract PLUS a differential/property harness vs the Dart
   reference, the bridge suites ported (warning strings live in the
   core), f64-matching-first arithmetic, and the fixture-authoring
   discipline carried over. Licensing annex (LEGAL): GPL-3.0-only core,
   cargo-deny in CI, GPL-2.0-only crates barred, gtk/Slint/Qt terms as
   above, Win32/Direct2D + AppKit as system libraries under GPLv3 §1,
   per-platform LICENSES manifests, Material You as unprotectable
   functional design. Recorded split points: the parity disposition
   (3–1, settled above); the Linux primary toolkit (2–2 — settled by
   the owner's literal tier assignment + one-toolkit-per-tier + the
   licensing constraints); the Android/Windows order (re-settable at
   the epilogue's own gates). v1.1 does not wait (PROD): the project
   DoD is reachable on the current codebases — the v1.1 tag is
   Stage 5's closing event and discharges D29.
4. **Placement ADR-012: IN-REPO — unanimous (ADV-LEGAL updated its
   2026-11-14 separate-repo default on the measured facts; ADV-SEC
   upgraded from mild; ADV-PROD and ADV-ENG held in-repo).** Recorded as
   `memory/DECISIONS.md` ADR-012 with the six binding mechanics
   (enumerated gitignored fixture path; allow-listed CI binary
   assertion with the synthetic/owner-authored provenance distinction;
   the same allow-list in the backup script; §7.5 per spec; tooling
   never in `release.yml`; no tracked Phase-4 binaries) — which land
   with the FIRST tooling commit, else ADV-LEGAL's recorded fallback
   reverts the placement to a separate research repo.
5. **DoD fix (PROD-1): FIXED — N = 4 published `docs/formats/` specs**
   (`clearfile-json.md`, `tax-exchange-container.md`, `txf.md`,
   `tax-modern.md` at shape level) **in a two-working-session hard
   time-box**, matched to the corpus the repo fully controls. Hard
   rules recorded (no spec for any extension with zero samples; the
   owner states the owned corpus at kickoff; owner-corpus specs are
   §7.1 bonus, never required; deposited families add one spec or
   declared backlog — the box never silently grows; the differential
   tool exercised on a synthesized pair). N differs across reviewers
   only as a counting convention (SEC/ENG counted 4; LEGAL 6 by
   finer-grained vintages; PROD 3 + conditional) over the same
   mandatory set — the settlement records 4 with the content unioned
   explicitly. Checkable at the exit gate by counting files and
   sessions.
6. **Security contract (carried SEC-1): RECORDED in full** (see
   ROADMAP's Stage-2 entry conditions — posture rules; write-free and
   resource-bounded with operational definitions; crash-safe with the
   malformed-input battery; never wired into `release.yml`; fixture
   paths enumerated + gitignored; the tool-header posture line). Stage-2
   execution implements it verbatim; the exit gate verifies by reading
   the tool code and tests, not by assertion.

### Condition ledger — dispositions

**Applied in-session (2026-11-17, this gate's session; commit evidence is
the closing backup):**

- **ENG-1 (MAJOR) — the Dart `.tax` inspector's crafted-input crash:**
  ADV-ENG reproduced a `RangeError` in `_readZipDirectory`
  (`tax_inspect.dart` — a central-directory entry whose name field runs
  past EOF; uncaught at `welcome.dart`'s call site), violating the
  "never throws on malformed input" contract. FIXED: the name slice is
  bounds-checked (mirroring the truncated-header branch) and the
  reviewer's crafted file is now a regression test
  (`tax_inspect_test.dart`). Suite 111→112, then 113 with ENG-2.
- **ENG-2 — the untested TXF 10,000-record cap:** refusal test added
  (`txf_import_test.dart`, 10,001 well-formed records → clean refusal).
- **SEC-1 (MAJOR) — live dependency criticals (32 advisories, 2
  critical: `next`, `next-auth`):** `npm audit fix` applied
  (non-breaking — `package.json` untouched, `package-lock.json`
  refreshed; 0 criticals remain; 6 moderate/high remain visible,
  needing breaking changes, non-gating) AND the failing CI gate
  `npm audit --omit=dev --audit-level=critical` added to `hygiene.yml`'s
  suites job (verified exit-0 locally; fail-closed on any future
  critical). All four web suites re-run green against the fixed tree
  (tsc 0, bridge 10/10, parity 16/16, smoke 6/6).
- **SEC-2 — the unlogged 2026-11-16 session:** recorded as a dated,
  append-only SESSION_LOG entry (the mode-only amend `4d4e1d6` and its
  reset-to-pushed-tip resolution; the resolution itself verified sound
  by two reviewers — 191 files, zero content delta).
- **SEC-3 / ENG-5 — `fetch_flutter_sdk.sh` aborting on the sandbox's
  benign tar failure:** hardened — tar's nonzero exit is tolerated with
  an explanatory note while the sha256 check stays strict and the
  SMOKE TEST is the authority; verified end-to-end (reinstall → OK
  line). Recorded as quirk 20 in STATE.
- **SEC-5 / LEGAL conditions 1/4/5 / PROD conditions 1–4 / ENG
  conditions 4–5 — the settlements recorded:** ADR-012 (placement),
  ADR-016 (tripwire disposition), ADR-017 (re-platforming settlement
  with both annexes) appended to DECISIONS.md; the Stage-2 DoD and the
  security contract recorded in ROADMAP; the ROADMAP/WORKFLOW tiering
  updated for the epilogue N1 full-depth gate; `harness_check.sh`
  patterns updated for the legitimate advance (Stage 3 CLOSED, Stage 2
  ENTERED, the epilogue's six PENDING stages).
- **ENG-7 — the WORKFLOW §4 recycle-runbook verification step** now
  explicitly includes `harness_check.sh` (its unpushed-commit check
  would have caught the stale amend in-session).
- **LEGAL-5 — README capability phrasing:** "compiled to … and Web" →
  "compiled to the … targets" (one-word clarification, applied while
  updating the test counts).

**Assigned to Stage-2 execution (must land with the FIRST tooling
commit; verified at the Stage-2 exit gate by reading code and tests):**

- **ADR-012 mechanics (a)–(f)** (enumerated gitignored fixture path;
  allow-listed CI binary assertion + provenance distinction; the same
  allow-list in the backup script; §7.5 per spec; no `release.yml`
  wiring; no tracked Phase-4 binaries) — else placement reverts to a
  separate research repo.
- **LEGAL-1 mechanics:** synthetic-only unit fixtures; the
  differential tool's provenance-manifest refusal (§7.1 made
  checkable); the backup hex guard widened from 64- to ≥32-hex on
  RE-adjacent paths with a UUID/known-hash allow-list (a 16-byte AES
  key as 32 hex characters passes today's 64-hex-only guard); a
  `docs/formats/*.md` lint (provenance field present, no hex runs
  ≥32).
- **SEC condition 3 / the recorded security contract, verbatim** (the
  operational definitions: read-only opens, no disk-writing shell-outs,
  a read-only-fixture-dir test, every cap refusal-tested with a clean
  message + non-zero exit, the malformed-input crash battery with
  ENG-1's crafted file as the template, `git check-ignore` on fixture
  paths in harness_check, the release.yml tooling grep).
- **ENG-3 — one survivingSpouse golden fixture** consumed by all three
  runners (Dart, `web_parity_test.mjs`, the Decimal oracle) — assigned
  to the FIRST Stage-2 execution session (it requires IRS-pinned
  citation work; the parameter-table equivalence is currently pinned
  only by an internal Dart test and nothing on the TS/oracle sides).
- **PROD-5 watch-item:** Stage 4's public Pages deploy must keep the
  welcome disclaimer prominent under a public URL (already in Stage 4's
  scope; carried as a named check).

**Surfaced to the owner (owner-side actions; the standing PAT posture
in WORKFLOW §5 is unchanged):** SEC-4/D30 — enable Dependabot alerts,
branch protection on `main`, and PAT expiry when next rotating
(re-affirmed; the audit CI gate added in-session covers the
repo-side half). The owner-overrule paths recorded at this gate:
ADR-016 (reinstate full parity or hard-freeze the TS engine), any
ADR-017 sub-item (including re-adding iOS), and the placement (ADR-012)
— each by a recorded ADR, never by silence.

### Orchestrator notes (recorded for honesty)

The gate convened two days after its scheduled date (the slip the
tripwire recorded); the agenda honored the mandatory web-freeze item.
Every reviewer independently re-ran the suites (four full Dart runs
total) and at least one live check; all four avoided the GitHub PAT
and the shared-IP api.github.com rate limit hit one reviewer (PROD),
recorded honestly in its report. The ADV-LEGAL weighting was
operationalized as: on RE-posture settlements where the panel splits,
ADV-LEGAL's position is the default unless rebutted in writing with
acceptable rationale — it was exercised at this gate only on the
placement question, where the panel was unanimous in-repo anyway
(LEGAL itself updated its own prior default on the measured facts);
the toolkit split was settled on the owner's literal tier assignment
plus LEGAL's licensing constraints (no rebuttal was needed — the
concerns were incorporated, not outvoted). The 3–1 parity disposition
was settled on the majority with the substance convergence recorded
(ADR-016's maintenance scope IS PROD's recommendation at one year's
distance). One extra full-depth gate cost acknowledged (the epilogue
program's own gates are delta-scoped except N1).

### Gate outcome

**Stage 3: CLOSED** (unanimous; the execution evidence held up under
full-depth live verification on all four seats — including one real
bug found and fixed at the gate itself).

**Stage 2: ENTERED** (unanimous PROCEED-WITH-CONDITIONS; every
condition applied in-session or assigned with a named verification
event — the ADR-012/LEGAL-1 mechanics and the security contract land
with the first tooling commit; ENG-3 lands with the first execution
session). Execution begins with the first Stage-2 tooling commit
carrying those entry conditions; its exit gate counts the DoD (4 specs,
≤2 sessions).

**The epilogue native program (N1–N6): recorded as PENDING/unfunded**
(ADR-017 settled, entered only behind its own gates when the owner
funds it).

---

## Gate: TT-compatibility program entry (T2–T4) · 2026-11-22

*Convened on the owner's ADR-020 instruction ("Record an explicit
risk-acceptance ADR for the shipped decryptor and proceed", trace
`1a2023899589beed`) — the TT program's own gate per ADR-019, carrying
its recorded agenda. Four reviewers ran concurrently in isolated
contexts (Task IDs 4-a…4-d); none saw another's report or any prior
gate record; consensus computed only after all reports were in.
Review scope: the delta since the 2026-11-17 gate (ADR-018 protocol
layer; ADR-019/T1 program start; this session's ADR-020, on disk
before the reviewers ran) plus the named risk surfaces (RE
deliverables, the secret guard, the bench). Reports:
`reports/2026-11-22-tt-{legal,security,engineering,product}.md`.*

### Verdicts

- **ADV-LEGAL: PROCEED-WITH-CONDITIONS** — ADR-020 is coherent AS a
  risk acceptance (not a clearance; it says so itself): both sides of
  the fixed-key argument recorded (*321 Studios* + §1201(a)(2)/(b)
  trafficking theories contra; §1201(f) interoperability texture incl.
  the means-sharing provision, the keys' public documentation since
  2024, the password-authorization frame, the *Lexmark/Chamberlain*
  TPM nexus pro). The Canadian-law assessment delivered in full (its
  finding 2): the 2012 C-11 regime's civil circumvention ban plus a
  providing-services prohibition textually at least as broad as
  §1201(a)(2), enumerated exceptions including interoperability but no
  means-sharing text and no fair-dealing override — exposure
  comparable in principle to the US analysis, lower in practice
  (civil-only, capped remedies, thin enforcement history); T1/T2
  private study sits inside the interoperability/encryption-research
  exceptions (public CDN acquisition — no access control circumvented).
- **ADV-SEC: PROCEED-WITH-CONDITIONS** — tree/history/CI verified
  clean (no tokens anywhere in history; no hex beyond the manifest;
  corpus + bench fully gitignored; RE tooling absent from CI/release;
  the flutter-test job already needs-gates all five platform builds);
  the key-material backstop must widen before it matters (applied —
  ledger below).
- **ADV-ENG: PROCEED-WITH-CONDITIONS** — the T1 evidence independently
  re-derived byte-for-byte and confirmed sound (one offset erratum
  found and fixed at the gate); bench intact after the twelfth
  recycle; the carve strategy confirmed; web-side T4 ruled BLOCKED
  under ADR-016 (T4 lands Flutter-first; web reaches TT support via
  the ADR-017 N6 WASM path).
- **ADV-PROD: PROCEED-WITH-CONDITIONS** — the product framing survived
  the acceptance (password-gated surface; "open without password" is
  a reopening event, never a feature request); the serious product
  risks attach to T4 (save-fidelity rule, disclosure replacement,
  non-affiliation line) and Stage-2 starvation needs a tripwire
  (recorded — ledger below).

### Agenda settled (recorded per the gate's mandate)

1. **The fixed-key-layer question — DISPOSED.** ADR-020 (recorded
   before any implementation exists — verified at tip by two
   reviewers) is the owner's explicit risk acceptance; protocol §2.2's
   recorded NO and §7.3's by-existence rule are lifted for the shipped
   T4 bridge scope, bound to ADR-020's boundary conditions.
   ADV-LEGAL's re-argument is on file in its report with the full risk
   register; the acceptance stands as the owner's disposition, not a
   clearance.
2. **The Canadian-law assessment — DELIVERED** (ADV-LEGAL finding 2;
   summary in the verdicts above). Canadian notices run the identical
   pause-and-reopen enforcement plan; no geo-filtering (GPL §7 — a
   territorial distribution filter would be an impermissible further
   restriction); no user-facing claim of Canadian legality.
3. **The security-contract application — BOUND** to the program: the
   T4 merge-gate contract (crash battery per the ENG-1 template,
   refusal-tested resource caps, uniform clean-failure password gate
   with no timing oracle, no network, runtime-generated fixtures,
   README/SECURITY disclosure) plus the hex-guard widening sequenced
   BEFORE T2's first tracked note (applied in-session — ledger below).

### Condition ledger — dispositions

**Applied in-session (this gate's commit):**

- **LEGAL-2 / SEC-1** (≥32-hex widening + measured allow-list before
  T2's first note commit): applied — `scripts/sandbox_backup.sh`
  RE_HEX_PATTERNS block with the allow-list (corpus manifest,
  `clearfile/.metadata`, lockfile classes); canary-tested end-to-end
  (a staged 32-hex file under `docs/` → REFUSING, exit 2, then
  cleaned).
- **SEC-4** (mechanical corpus verification): applied —
  `scripts/fetch_tt_corpus.sh` now greps the expected sha256 from
  `corpus-manifest.md` and refuses on mismatch; positive test 4/4
  verified against the live corpus; the negative path proven
  function-level (one flipped byte ⇒ different sha ⇒ refusal).
- **SEC-3** (the commit-message channel): applied early — the backup
  NOTE now passes the same TOKEN / ≥32-hex scan before committing.
- **LEGAL-3** (protocol §6 consistency): applied — the dated ADR-020
  note in §6 (the quarantined module = the single sanctioned
  exception; form-text and binary prohibitions absolute).
- **PROD-1** (§7.4 UI-screenshot extension): applied — no runtime
  screenshots of the proprietary UI anywhere; text-only
  information-architecture records.
- **PROD-6** (ADR-020 wording clarification + exit-ramp artifact
  classes): applied — the orchestrator annotation on ADR-020.
- **ENG-1** (phase-1 offset erratum): applied — the note carries the
  0x99000 correction.
- **PROD-2** (Stage-2 starvation tripwire): recorded — Stage-2
  execution session 1 convenes within two working sessions of T2
  session 1 (2026-11-22, this session), else the slippage is a
  mandatory agenda item at the next convened gate; carried in ROADMAP
  and STATE.
- **PROD-3 / ENG-6's placement half** (TT spec namespace/counting
  rule): recorded in ROADMAP's TT section — TT specs are program
  deliverables under `docs/re-research/` (or `docs/formats/` only with
  an explicit TT/non-DoD provenance marker) and NEVER count toward
  Stage-2's N=4; the `tax-modern.md` DoD spec and T3's deep
  password-layer spec are distinct files or an explicit recorded
  supersession.
- **ENG-2** (stub-only remains the rule) and **ENG-3** (disk
  discipline: selective extraction, intermediates deleted, one
  target's payload resident at most): carried as binding T2 execution
  rules (ROADMAP TT section + the T2 session note).
- **LEGAL-1 / LEGAL-5 memory-sync halves**: applied at this session's
  close-out (STATE / ROADMAP / PROJECT_MEMORY / SESSION_LOG all carry
  ADR-020; "OWNER DECISION REQUESTED" retired).

**Assigned with named verification events:**

- **The T4 design/merge gate** (the shipped-decryptor review): SEC-2
  (the representation-agnostic single-provenance assertion — the
  quarantined key module's path joins the guard allow-list as exactly
  one entry); SEC-5 (the full bridge threat model: crash battery,
  refusal-tested resource caps, uniform clean-failure password gate,
  no-network, runtime-generated fixtures); LEGAL-5 (refusal tests +
  quarantined module + README/SECURITY provenance disclosure + the
  enforcement-response plan documented in SECURITY.md or the module
  header); LEGAL-6 / PROD-5's Canadian posture and disclosure
  replacement (README's "does not decrypt" statement rewritten;
  Intuit non-affiliation line; SECURITY.md disclosed-posture entry);
  PROD-4 (save-fidelity rule: fields outside the engine's model
  round-trip verbatim, never silently recomputed or dropped, + a
  round-trip test); ENG-7 (T4 Flutter-first — no TT bridge code under
  `src/` absent a recorded owner ADR per ADR-016's overrule path; the
  codec layer stays pure/portable for the N1 Rust-core port); ENG-8
  (full verification-contract re-run + CI run id when T4 touches
  code; repo-wide key-shape grep outside the quarantined module
  empty).
- **T3 start:** SEC-6 (the docs/formats provenance lint covers
  `docs/re-research/` notes too).
- **T2 sessions:** ENG-4 (the REA checkpoint-mode trial, outcome
  registered in DEBT.md/playbook) + ENG-5 (the security contract for
  the first TRACKED extraction tool; gitignored bench scripts follow
  the same posture voluntarily — this session's parser is bounded,
  crash-safe, and writes only under gitignored `tools/re/`).
- **LEGAL-4** (per-commit by-existence discipline): standing — every
  T2/T3 note/spec commit passes a manual ≥32-hex scan until the lint
  lands (this session's T2 note: scanned, clean).

### Orchestrator notes (recorded for honesty)

- The four reviewers ran as isolated concurrent agent contexts; each
  stated its independence (ADV-ENG disclosed that harness_check's
  output names the TT program in a pass line — counts only, no gate
  content exposed to it).
- ADV-ENG independently re-derived the T1 evidence and found the
  phase-1 offset error (0x99280 → 0x99000) — a gate-quality fix in
  the ENG-1 tradition; the erratum is applied in-session.
- ADR-020 and the protocol amendments were on disk (uncommitted)
  before the reviewers ran — they reviewed the actual records, not
  summaries.
- The ADV-LEGAL weighting was not needed: the panel was unanimous
  PROCEED-WITH-CONDITIONS with convergent substance.
- CI status on tip `52e2c68` was not re-verified this session (the
  documented shared-IP api.github.com rate-limit quirk); the delta
  since `c4982d1` provably touches zero code paths, so the carried
  suites stand, and CI runs on this gate's own push.

### Gate outcome

**T2: ENTERED** (unanimous PROCEED-WITH-CONDITIONS; every condition
applied in-session or assigned to a named verification event above) —
the TT-compatibility program's gated execution opens under ADR-019's
boundaries + ADR-020's acceptance and its amended §2.2/§7.3 scope. T1
(pre-gate research: corpus + Phase-1 + the REA first pass) is
COMPLETE and verified at this gate. **Stage-2's DoD box is unchanged**
(N=4 named specs, ≤2 sessions; TT specs never count toward it);
Stage-2 execution session 1 remains standing with the recorded
starvation tripwire.


---

## 2026-11-26 · The Stages 4+5+6 delta gate (after-the-fact)

**Context:** the owner's blanket directive ("implement everything on the
roadmap that does not require my input within a single session; backup
after each stage; parallelize") executed Stages 4, 5 and 6 ahead of their
delta-scoped entry gates. This panel reviewed the full delta
(`6205222 → 8622e74`) after the fact — a WORKFLOW §2 sequencing
deviation recorded here for **owner ratification** (the ADR-009
recorded-prerogative pattern: owner prerogative is exercised openly,
never silently). All four reviewers worked independently over the repo,
the live release, and the live Pages site.

**Findings (unanimous):** every Stage 4/5/6 roadmap item landed; the
project DoD remains true (zero engine code touched); the owner-exclusion
discipline held (D30 untouched, no epilogue code, no T4, no new ADRs).
All four verdicts were PROCEED-WITH-CONDITIONS, with the conditions
landing in-session (`8622e74` + this governance sync): the guard-test
de-fragilization + CI wiring (SEC-1/ENG-1/PROD-3), the
platform-accurate disclosure + the missing privacy_test pin
(LEGAL-1/LEGAL-2), the flutter_web_smoke.py SPDX header (LEGAL-3), the
README CSP/HSTS wording corrections (SEC-2/PROD-5), the plain-400
classification note (ENG-3), and these very memory syncs (ENG-2/PROD-1).

**Owner-ratification surfacings (decisions only the owner can take):**
1. The after-the-fact gate sequencing itself (ratify or direct a
   remediation).
2. The PAT's use to ENABLE Pages (a repo-settings mutation, executed
   after the workflow's GITHUB_TOKEN was 403-refused on site creation —
   a new PAT-use class adjacent to D30).
3. pages.yml's `id-token: write` OIDC grant on the deploy job (the
   deploy-pages API requirement; a recorded deviation from the Stage-0
   "pages: write + contents: read, nothing more" posture).

**Stage-2 exit-gate slip (mandatory agenda item at the next convened
gate):** T3's password-layer chase found the MSI-record keystream
diverging from the recorded formula at payload offset 0x24000 (the
documented cipher decodes cleanly to 0x24000 then fails; 14 variants +
1024 phase deltas + 256 key constants swept with a continue-stream
oracle, no match); `tax-modern.md` stays unwritten and the Stage-2 exit
gate stays unconvened. No DoD claim was falsified.

**Gate outcome:**

**Stage 4: CLOSED**
**Stage 5: CLOSED**
**Stage 6: CLOSED**
(2026-11-26 — 4 × PROCEED-WITH-CONDITIONS, unanimous; conditions
discharged in-session as recorded above).

**Owner ruling recorded 2026-11-26 (in-conversation, appended):** the
owner RATIFIED all three surfacings — (1) the after-the-fact gate
sequencing stands as valid; (2) the PAT's use to enable Pages is
approved (the use class joins the token's observed profile in WORKFLOW
§5); (3) pages.yml's `id-token: write` OIDC grant is approved as the
deploy-pages API requirement. No remediation directed. The same owner
message FUNDED the epilogue N1–N6 program (ADR-017): ROADMAP's six
epilogue gate statuses became FUNDED — funding gates the program, not
any stage; the gates convene per the tiering (N1 full-depth first).

---

## 2026-11-26 · The N1 full-depth entry gate (the Rust core)

**Context:** the owner funded epilogue N1–N6 in the ruling recorded
above; the first gate of the funded program convenes per the tiering —
N1 (the Rust core) is FULL-DEPTH. The proposal under review: a session-1
slice (the sha256-verified standalone toolchain under gitignored
`tools/rust/`; a single std-only tracked crate at `core/` — GPL-3.0-only,
SPDX headers, zero external dependencies, no build.rs; the TY2025
parameter tables + the ordinary-income path ported from the Dart
reference; the fixture-JSON reader strictly in the test harness; the
third golden-fixture runner consuming the SHARED 17 fixtures with the
Python oracle's exact tolerance semantics; a plain `cargo test` step in
hygiene's suites job) with N1's overall exit (17/17 + the annex's
differential/property harness + the ported bridge tests) explicitly NOT
session-1's claim. All four reviewers worked independently over the
repo at tip `b9008f9`; reports filed at
`harness/adversarial/reports/2026-11-26-n1-{security,engineering,legal,product}.md`.

| Reviewer | Verdict | BLOCK? |
| --- | --- | --- |
| ADV-SEC | PROCEED-WITH-CONDITIONS (7) | no |
| ADV-LEGAL | PROCEED-WITH-CONDITIONS (5) | no |
| ADV-ENG | PROCEED-WITH-CONDITIONS (9) | no |
| ADV-PROD | PROCEED-WITH-CONDITIONS (7) | no |

**Gate-level conditions (discharged at the gate close, this sync):**
(1) the N1 execution box is TWO sessions (session 1 = the reviewed
slice; session 2 = 17/17 + the annex (a) differential/property harness +
the ported bridge tests) with the Stage-3 tripwire edge rule — exceeding
the box logs the slip honestly and disposes it at the N1 exit gate,
never silently extended, and an extension requires a recorded owner
ruling (PROD-1); (2) the third-engine boundary sentence recorded in
ROADMAP + STATE — the v1 maintenance freeze "zero engine code touched"
is scoped to the two existing engines; `core/` is additive by design;
its delta never touches `clearfile/` or `src/` (PROD-5); (3) the
"16 shared golden fixtures" count erratum (actual: 17, QSS #17, D33)
recorded as a dated annotation, never a silent edit (ENG-9/SEC-adv/
PROD-7); (4) the licensing annex's cargo-deny disposition named — the
zero-dependency fail-closed assertion (Cargo.lock = exactly the root
package AND no `[dependencies]` section) IS the license check at
core-landing, upgraded to a real cargo-deny in the same commit as the
first external dependency (SEC-3/LEGAL-2); (5) harness_check gains the
release.yml variant-precondition guard (zero `core/|clearfile-core|cargo`
references) now (PROD-4/SEC-7/LEGAL-4); (6) the tracked
`scripts/fetch_flutter_sdk.sh` SPDX residue repaired same-session
(LEGAL-1's live finding); (7) the crate's Cargo semver recorded as a
FOURTH version plane, separate from app semver / envelope schema /
web package.json (PROD-adv); (8) STATE.md's "when dependencies land"
paraphrase corrected to the annex's "when the core lands" (LEGAL-adv).

**Session-1 binding conditions (the execution's own gate ledger; every
one checkable):** SPDX GPL-3.0-only header on EVERY new tracked file
from the first commit including the fetcher (LEGAL-1); `core/target/`
gitignored BEFORE any cargo invocation + `core/` added to
sandbox_backup.sh's hex-scan path list in the same commit (SEC-1); the
toolchain fetcher verifies sha256 against a TRACKED manifest row
(version+URL+size+hash — the fetch_tt_corpus.sh pattern), the manifest
in the backup hex allow-list, no hardcoded 64-hex constant in scripts/,
unauthenticated fetch only, quirk-20 hardening (strict sha256, benign
tar-status tolerance, `cargo --version` smoke as the authority)
(SEC-2/SEC-6/SEC-adv/LEGAL-3); CI step: `cargo test --locked`, version
echo, no new `uses:` lines, no secrets, existing permissions
(SEC-4/ENG-8); the comparator ported EXACTLY from
verify_golden_fixtures.py (field-set = the fixture's expected keys,
`deductionMethodUsed` exact string, else `|delta| > tolerance` fails —
delta == tolerance passes — per-fixture `tolerance` default 0.005,
fixture 01's 0.505; NOT cent-rounded) + NaN/∞ fail-closed + the
boundary unit tests (ENG-1/ENG-2/PROD-6); the honest-subset mechanism =
a committed per-fixture skip map (`run | deferred{reason}` keyed to
input features) + a guard test asserting map keys == the directory's
fixture set exactly; unported fixtures `#[ignore]`d with a reason,
never red on main (ENG-3/PROD-2/SEC-5); the slice includes SLI + SALT
+ deduction-choice + payments (port calculator.dart whole) or the skip
map accounts for every fixture needing them (ENG-4); the four
arithmetic-semantics traps in the harness doc-comment (operation order;
the CTC cents-normalize BEFORE the $1,000 ceiling and never port the
oracle's +999 idiom; Dart round/ceil == Rust f64::round/ceil; Dart
min/max NaN propagation noted) + fixture 12 in the green set (ENG-5);
the fixture-JSON reader STRICT (named-field errors on missing/misspelled
inputs — unlike the Dart loader's defaults) and strictly in `core/tests/`
(ENG-7/SEC-adv); the differential/property-harness deferral recorded as
a DEBT entry citing annex (a) with the named mechanism (ENG-6/PROD-6);
the Rust suite joins the ledger mechanically (harness_check: green +
ignored == the fixture directory count against a `core/tests/` manifest;
README gains ONE `core/` row "N of 17 fixtures green"; the Dart 126-class
checks untouched) (PROD-3); `release.yml` diff-empty at session close +
pubspec version unchanged (SEC-7/LEGAL-4).

**Gate outcome:**

**N1: ENTERED**
(2026-11-26 — 4 × PROCEED-WITH-CONDITIONS, unanimous; the gate-level
conditions discharged in this sync; the session-1 conditions bind the
first execution session. The ADR-017 recorded variant holds: no shipped
artifact depends on the core, and the v1 stages remain closed/frozen.)

## 2026-11-26 · The N1 exit gate (the Rust core's exit checklist)

**Context:** N1's execution box closed at exactly two sessions (session 1 =
the toolchain + the std-only engine + the golden runner, 17/17; session 2
= the annex-(a) differential/property harness (D43 closed) + the annex-(b)
ported bridge suites + the format codecs, cargo test 159/159, backup
`138e93b`, hygiene run #31 green). The exit gate convened on the combined
N1 delta (`b9008f9..138e93b`) with the **Stage-2 exit slip as the
mandatory agenda item** (the slip record's re-agenda rule — the T3
MSI-record keystream divergence at payload offset 0x24000, the decompile
chase, tax-modern.md unwritten). All four reviewers worked independently
over the pushed tip; reports filed at
`harness/adversarial/reports/2026-11-26-n1exit-{security,legal,engineering,product}.md`.

| Reviewer | Verdict | BLOCK? |
| --- | --- | --- |
| ADV-SEC | PROCEED (0 conditions) | no |
| ADV-LEGAL | PROCEED-WITH-CONDITIONS (1) | no |
| ADV-ENG | PROCEED-WITH-CONDITIONS (3) | no |
| ADV-PROD | PROCEED-WITH-CONDITIONS (4) | no |

**Conditions (all discharged in-session at the gate close):**
(1) LEGAL-1: README's corpus row taxonomy aligned with the corpus's own
class table (300 random + 246 edge + 4 edge-d31b) — applied.
(2) ENG-1: json.rs's "byte-identical to BOTH reference emitters" claim
was FALSE for Dart's `jsonEncode` on whole doubles (Dart appends `.0`;
the corpus itself proves it — verified live by the reviewer at corpus
line 30679) — the module docs now state the exact truth (byte-identical
to V8 `JSON.stringify` everywhere; the one deliberate Dart `jsonEncode`
divergence documented; value-identical everywhere — both forms parse to
the same f64).
(3) ENG-2: the ported exporter test had dropped the mjs group's D-date
shape assertion — restored (and the restoration itself carried a
column-index slip found by the re-run and fixed: the honest note).
(4) ENG-3: SESSION_LOG's "the Dart txf-import 11" corrected to 12.
(5) PROD-1: the dangling "push verified below in its own bullet" promise
completed — hygiene run #31 green on `138e93b`, verified live by the
orchestrator AND independently by the PROD reviewer.
(6) PROD-2: **D44 recorded** — ADR-017's core boundary names
"MD3-from-seed palette generation"; N1's two sessions never included it
(the entry gate's session-1 slice named the engine/runner; session 2 the
annex harnesses/codecs); the deferral is defensible but now EXPLICIT:
the palette lands with its FIRST consumer (the N2 session), as debt D44
with its named target.
(7) PROD-3: the N2 pre-positioning note recorded — (a) the C-ABI seam
(cbindgen) lands when the first FFI consumer exists (N3 Android / N4
Windows / N5 macOS), NOT at N2 (Linux links the crate directly per
ADR-017); (b) the crate-topology question is N2's gate to decide: a cargo
WORKSPACE for the app crates would break the core-scoped zero-dependency
CI assertion (which pins `core/Cargo.lock` to exactly one package) — N2
either keeps app crates as separate workspace roots re-scoping the
assertion, or the core stays its own root (the recorded default).
(8) PROD-4: **the Stage-2 slip owner surfacing** (below).
(9) SEC-adv/ENG-risk (the manual digest check): harness_check gains the
corpus-digest family — the committed cases.json must match the digest
its README records (a drifted-but-self-consistent corpus otherwise
passes the manifest check alone).

**The mandatory Stage-2 slip agenda (disposition):** the Stage-2 exit
gate stays SLIPPED and re-agendas at N2's gate (per the slip record's
own rule). The gate surfaced to the owner: the T3 lane's next session
(the MSI-record keystream decompile chase + tax-modern.md, debt D42) is
NOT covered by the current directive (the owner funded N1–N6; the T3
chase is Stage-2 residue) — the record's cheaper alternative is the
namespace rule's recorded-supersession path (ADR-012(a)-class):
**owner options: (a) fund a T3 session for the chase + tax-modern.md,
(b) supersede the RE-protocol namespace rule that requires the modern
format's DoD spec, or (c) the slip keeps re-agenda-ing at every
convened gate.** No ruling received this session; the default is (c).

**Registered risks (non-blocking, from the reports):** SEC R1 — the
JSON object-key insertion is quadratic in crafted objects (80k keys →
~27 s vs the references' O(n)); harden before the first FFI-wiring
session. SEC R2 — the ZIP STORE-extraction allocation amplification (a
385 KB crafted file can drive >1 GB extraction; inherited by parity
from the shipped Dart/TS readers); same FFI-wiring hardening lane. ENG —
the property harness's fold check is self-referential alone (mitigated:
the differential corpus pins the same fold against the Dart reference);
the execution pattern's "verify, don't discard" disposition assessed
SOUND (the review of the deadline-orphaned work caught the one real bug
— the reversed import-date year tail).

**Gate outcome:**

**N1: CLOSED (exit PASSED)**
(2026-11-26 — 4 × PROCEED-family unanimous, no BLOCK; every condition
discharged in-session; the box closed at exactly two sessions, the
tripwire never fired. The core is golden-fixture green (17/17),
differential-green (550 cases × 26 fields, exact binary64 parity), and
bridge-ported (envelope + TXF + .tax inspection + composition). The
ADR-017 variant holds: no shipped artifact depends on the core. The
epilogue's next gate is N2's delta-scoped gate — the Linux native UI,
with the two-toolkit consolidation question (PROD-3's notes) and the
Stage-2 slip re-agenda on its agenda.)

## 2026-11-26 · The N2 delta-scoped gate (the Linux native UI)

**Context:** N1 CLOSED (exit PASSED) earlier this date; the epilogue's
per-OS order proceeds to N2. The proposal under review: the toolkit
consolidation to Slint under the roadmap's own N2 consolidation right;
the apps/linux separate-crate-root topology; cargo-deny at the first
external dependency; D44's palette module in the core verified by the
differential-generator pattern; an argv-envelope MD3-themed window app
+ a --headless smoke. All four reviewers worked independently over the
pushed tip 78a0213 (and ran their own probes: the gtk3 infeasibility
re-measured, the slint build + the lock's 553-package license audit, the
MCU version extraction, the workspace claim tested empirically, the
working-tree drift caught). Reports at
`harness/adversarial/reports/2026-11-26-n2-{security,legal,engineering,product}.md`.

| Reviewer | Verdict | BLOCK? |
| --- | --- | --- |
| ADV-SEC | PROCEED-WITH-CONDITIONS (8) | no |
| ADV-LEGAL | PROCEED-WITH-CONDITIONS (8) | no |
| ADV-ENG | PROCEED-WITH-CONDITIONS (10) | no |
| ADV-PROD | PROCEED-WITH-CONDITIONS (7) | no |

**The consolidated condition ledger (binding the execution sessions;
every one checkable; the full text in the reports):**
1. **The consolidation is RECORDED (revisitable, recorded per ADR-017's
   own clause):** the right quoted; the live demand evidence (gtk3-rs
   unbuildable in this sandbox — no libgtk-3-dev, no root; re-measured);
   the forfeit stated without overstatement (the gtk3 older tier + its
   LGPL posture forfeited; CI runners COULD build gtk3-rs — the demand
   is the single-maintainer dev-loop reality, not a global technical
   impossibility); the interim consequence (the Flutter GTK app stays
   the shipped Linux product; the native app's distro baseline is a
   GA-gate decision); revisitability (the owner may re-split by ADR).
2. **The topology recorded as chosen-with-rejected-alternative:** the
   no-workspace choice is legitimate, not forced (a workspace breaks the
   zero-dep assertion AS WRITTEN but a path-scoped rewrite preserves the
   posture — the ENG reviewer proved it empirically with a scratch
   workspace); separate roots chosen, the alternative named + rejected.
3. **D44's palette verification corrected + re-scoped (ENG-1, SEC-7):**
   the reference is material_color_utilities **0.13.0** (the version
   clearfile/pubspec.lock resolves, pub.dev, content-hash pinned) — NOT
   "3.47.9" (the SDK version; the mislabel is corrected in the record);
   and the corpus must pin the **scheme roles** (~50 ARGB values per
   seed per brightness — what ColorScheme.fromSeed's DynamicScheme +
   MaterialDynamicColors actually produce: primary…tertiaryFixedVariant,
   the error family, outline/s, the surface family incl. dim/bright/
   container-lowest..highest, onSurface*, the inverse family, shadow,
   scrim, surfaceTint) for light AND dark, in addition to the tonal
   ladders — "tonal palette channel values" alone cannot honestly
   support the same-visual-language claim. The generator calls the
   reference (flutter test or the extracted MCU under the pinned SDK)
   or its mapping is checked field-by-field against the SDK's
   color_scheme.dart at generation time.
4. **The reference resolution is hash-pinned, never floating (SEC-7):**
   the tool consumes the pub-spec content-hash resolution already in
   clearfile/pubspec.lock (0.13.0, digest-pinned) or the SDK-bundled
   preload copy — never an unpinned pub.dev fetch; the corpus provenance
   names package 0.13.0 + its content hash.
5. **The execution box is TWO sessions (ENG-4, PROD-3 — the one-session
   proposal was undersized against the N1 precedent):** session 1 = the
   palette module + the generator + the corpus + the core tests green +
   the apps/linux scaffold with every guard join (the intra-session
   checkpoint: palette + corpus green BEFORE any app work — a session
   death still closes D44); session 2 = the window UI + the headless
   mode + the CI lane + both smokes + the bookkeeping. The slip rule:
   the Stage-3 tripwire precedent (logged honestly, never silently
   extended, an extension needs a recorded owner ruling); a slip
   disposes at the N2 exit gate. **The disk plan (re-measured at the
   gate):** the 1.5G re-fetchable tarball residue deleted (done at the
   gate close; 5.1G→6.6G free); the probe target deleted by the
   reviewer; the app crate declares slint with default-features = false
   + the femtovg/software renderers (the skia-safe CDN prebuilts are
   EXCLUDED from the lock — the probe's 553-package tree with skia is
   not the shipped shape); the standalone sha256-pinned Dart SDK
   fetcher (a NEW tracked fetcher in the fetch_tt_corpus pattern, ~300
   MB, the official dart-archive manifest as the hash source) serves
   the palette reference runtime — the full Flutter SDK does NOT fit
   the disk plan.
6. **The cargo-deny posture (SEC-2, LEGAL-5, ENG-9):** only two
   acceptable mechanisms — (a) EmbarkStudios cargo-deny-action
   SHA-pinned per D10 (the same trust class as the accepted
   SHA-pinned gitleaks action) or (b) `cargo install cargo-deny
   --locked --version <pinned>`; a vendored binary is FORBIDDEN (the
   binary-blob policy) and a plain script alone is insufficient
   (Cargo.lock carries no license metadata). A tracked deny.toml
   (fail-closed) from apps/linux's FIRST commit: `licenses.allow` a
   closed GPL-3.0-compatible list (GPL-3.0-only exactly — not the
   deprecated GPL-3.0 — MIT, Apache-2.0, BSD-2/3-Clause, ISC, Zlib,
   Unicode-3.0/DFS-2016, 0BSD, CC0-1.0), the slint triple-license
   crates passing via their GPL-3.0-only leg with the LicenseRef ids
   deliberately ABSENT (per-crate exceptions with recorded reasons if a
   surprise appears), sources = crates.io-only, targets = the shipped
   triple(s) — the CI check covers the FULL lockfile incl. the
   target-gated packages (the 104 non-compiling-on-Linux ones), the
   first run live-verified green.
7. **The CI app lane (ENG-2):** the runner's rustc is guarded
   fail-closed (parse `rustc --version`, assert ≥ 1.95 — slint 1.19.1's
   declared MSRV) before any cargo call; every cargo invocation
   `--locked` with apps/linux/Cargo.lock committed; slint bound to the
   audited series (`slint = "1.19"` + the feature set) in the
   Cargo.toml — the audited tree IS the built tree.
8. **The smokes (ENG-5, ENG-6):** the window smoke: `--smoke` flag
   constructing the real window, one frame, a marker, exit 0, under
   `SLINT_BACKEND=winit-software` (GL-free), apt `libxkbcommon-x11`
   (Xvfb preinstalled), DIRECT `Xvfb :99 &` (xvfb-run needs xauth —
   absent), inside a `timeout` with failure asserted. The headless
   smoke: consumes a committed fixture, diffs the FULL stdout against
   committed expected text, and is structurally the SAME pipeline
   function the window consumes (one `load_and_compute(path)`).
9. **Guard joins BEFORE the closing backup, same-commit (SEC-1/3/5/6,
   ENG-8):** the N1-exit parser-hardening risks (the O(n²) JSON
   object-key insertion + the ZIP STORE amplification) land at N2 IN
   SUBSTANCE (the first real consumer feeding user files to them) —
   the session lands both hardenings (a member-count/linearity bound +
   a cumulative extracted-bytes cap, each with a battery extension) OR
   records the explicit re-deadline with the direct-linking rationale;
   `.gitignore` gains the app target rule BEFORE any in-repo app build;
   `apps/` joins the backup ≥32-hex scan path list; the palette corpus
   ledger joins harness_check; any palette-digest file joins the backup
   known-hash allow-list in its landing commit; the palette tool +
   corpus live under scripts/ + fixtures/palette/ (zero clearfile/ or
   src/ paths in the N2 delta — the PROD-5 discipline carried).
10. **SPDX + license records (LEGAL-2/3):** every new tracked file
    under apps/linux carries the SPDX header (incl. .slint markup —
    `//` comments); the app crate's Cargo.toml: `license =
    "GPL-3.0-only"` + `publish = false`; the Slint license election
    recorded in-tree (deny.toml comment or adjacent: the GPL-3.0-only
    branch only, the royalty-free/commercial branches NOT elected, the
    pinned version); the palette port carries the provenance
    doc-comment (a translation of Google's Apache-2.0 material_color_
    utilities 0.13.0 — derived-not-vendored) + a THIRD-PARTY-NOTICES.md
    entry (the first third-party-derived material in the core).
11. **The app honesty surfaces (LEGAL-4, PROD-4):** in-window demo
    disclaimer + the AI-absence/no-network note + prototype labeling;
    the README gains the honest apps/linux row; NO downloadable CI
    artifacts of the unreleased binary (conveyance, not tagging, is the
    license-manifest trigger — the manifest lands with the first tagged
    release per ADR-017); no version-plane movement (v2.0.0 discipline:
    nothing this stage ships).
12. **The drift disposal (ENG-10, PROD-2, LEGAL-observed):** the
    working tree was NOT clean at the gate (a reviewer's npm install
    pinned @types/node/typescript/@types/react versions — unauthorized;
    three reviewers flagged it): normalized to the pushed tip
    (`git restore package.json package-lock.json`) at the gate close —
    the SESSION_LOG records the drift's discovery + disposition.
13. **The Stage-2 slip re-agenda (PROD duty, restated):** the standing
    owner options (a) fund a T3 session, (b) supersede the RE-protocol
    namespace rule, (c) default re-agenda — no ruling received; (c)
    continues, re-agenda'd at the N2 exit gate.

**Gate outcome:**

**N2: ENTERED**
(2026-11-26 — 4 × PROCEED-WITH-CONDITIONS, unanimous, no BLOCK; the
consolidation to Slint exercised under the roadmap's own recorded right
with the demand verified live; the two-session box set with the disk
plan; the conditions bind the two execution sessions.)

## 2026-11-26 · The N2 exit gate (convened; PENDING two items)

**Context:** N2's execution box closed at exactly two sessions (session
1: the D44 palette + corpus + the scaffold + guards, checkpointed at
8365249/ad6bce2/69c8dda/39bdc22; session 2: the Slint window app + the
shared pipeline + the headless mode + the CI Linux-app lane + the R1/R2
hardenings, checkpointed at 37f1a5c/7f18fa2). The exit gate convened
on the N2 delta (d227bc7..7f18fa2) with the Stage-2 slip re-agenda.
Three of four reviewers filed (parallel isolation, own probes: the
guard scans replicated, the corpus digest + the MCU content hash
re-verified live, the CI runs #38/#39 checked live); reports at
`harness/adversarial/reports/2026-11-26-n2exit-{security,legal,product}.md`.
**The ENG lane hit the subagent context deadline before filing — its
report is OWED; the gate stays PENDING its re-convening.**

| Reviewer | Verdict | BLOCK? |
| --- | --- | --- |
| ADV-SEC | PROCEED-WITH-CONDITIONS (3) | no |
| ADV-LEGAL | PROCEED-WITH-CONDITIONS (6) | no |
| ADV-PROD | PROCEED-WITH-CONDITIONS (5) | no |
| ADV-ENG | (report owed — the deadline; re-convene) | — |

**The conditions ledger (the reports carry the full text; the
discharged items marked):** SEC-1 (the 539→549 lockfile count
correction — this record corrects it: the committed lock is 549
packages; the earlier count predated the slint-build regeneration) —
CORRECTED here; SEC-2 (the live-green hygiene run over the tip — the
PROD finding: runs #38/#39 were RED at the Linux-app job, the runner
lacked libfontconfig1-dev; FIXED in hygiene.yml's apt line; the green
run is the gate's pending item); SEC-3 (the "skia excluded" wording —
the precise statement: skia-safe/skia-bindings sit in the lock as
never-built optional entries; the no-CDN-prebuilt property holds).
LEGAL-1..6 (the README rows — DISCHARGED; the headless footer's three
demo-disclaimer facts; the Apache-2.0 copyright-year + no-NOTICE-file
notes; the cargo-deny first-green-run evidence — the pending CI run
covers it; the expected-headless.txt SPDX exception note; the n2exit-
legal report's own allow-list join if it carries digests — it does
not). PROD-1 (the CI-red fix + the green run + the honest SESSION_LOG
record — the fix landed, the run pending); PROD-2 (the README rows —
DISCHARGED); PROD-3 (the teardown bookkeeping — the D44-CLOSED DEBT
append + STATE landed; ROADMAP awaits the exit outcome); PROD-4 (the
N3 pre-positioning note — recorded in STATE's next section); PROD-5
(the Stage-2 slip re-agenda — the three owner options restated, no
ruling received, (c) the default).

**Gate outcome:**

**N2: EXIT PENDING (one item)**
(the ENG report is owed — the subagent deadline, the same class the
gate's box-sizing condition predicted. The live-green hygiene run
DISCHARGED: hygiene run #44 GREEN on a592b06 after the four-round CI
fix (the font stack moved before the unit tests' build; the runner's
package name libxkbcommon-x11-0; the BSL-1.0 allow-list join per the
actually-encountered rule; the wildcard disposition for the clearfile-
core path dep — the recorded ADR-017 seam); every code-level finding
is fixed; the gate closes when the ENG report lands.)

## 2026-11-27 · The N2-exit riding list discharged (the record-level conditions + the gate-outcome close)

**Context:** the N2 exit gate closed 2026-11-26 (all four reports filed —
SEC PWC (3) / LEGAL PWC (6) / ENG PWC (1) / PROD PWC (5), no BLOCK), but
the CONSENSUS close line and four record-level conditions rode to the next
session per the close commit (109c3eb). This entry records their
discharge (the opening batch of the 2026-11-27 session; the tree
normalized to the pushed tip after the recycle's mode flips, harness_check
0 failures first, the pinned Rust toolchain re-fetched sha256-verified —
the corpus stays re-acquirable per the ADR-019 fetcher rule):

1. **The gate-outcome close line (owed here): the N2-exit record above
   ends on "EXIT PENDING" — the final close commit touched only
   PROJECT_MEMORY/ROADMAP/SESSION_LOG/the ENG report. Recorded: N2:
   CLOSED (exit PASSED) 2026-11-26 — the ENG retry filed its PWC (1)
   report (`2026-11-26-n2exit-engineering.md`), and the gate closed with
   every code-level finding fixed and the remaining items all
   record-level, riding to this entry.**
2. **ENG-riding (the residual duplicate-scan amplification)** — the
   bound-or-record choice goes to N3's gate as a named agenda item (the
   standing framing: closure before any FFI wiring, and N3 IS the FFI
   wiring; the stronger bound is the default candidate). Not decided
   here — it is execution-scope, not bookkeeping.
3. **LEGAL-2 (the headless footer's three demo-disclaimer facts) —
   DISCHARGED:** `apps/linux/src/main.rs`'s `text_summary` footer now
   carries the three facts verbatim-in-substance from welcome.dart's
   family (not IRS-authorized; cannot e-file; must not be used to file a
   real return), `tests/expected-headless.txt` regenerated from the
   actual output, the app suite **5/5 green**; the core re-verified
   **174/174 green** with the palette-header edit below in place.
4. **LEGAL-3 (the upstream copyright + no-NOTICE notes) — DISCHARGED:**
   `core/src/palette.rs`'s provenance doc-comment names "Copyright 2021
   Google LLC" + the no-NOTICE-file fact; the THIRD-PARTY-NOTICES.md
   entry carries both (verified at the N2 gate). The notices link's
   opening bracket is intact in the live file (the exit advisory's
   one-character typo already absent — nothing to fix).
5. **LEGAL-5 (the expected-artifact SPDX carve-out) — DISCHARGED:** D14's
   policy line (DEBT.md) now records the byte-pinned expected-output
   artifact class; no header added to the file itself.
6. **SEC-riding (the action-SHA↔tag verification) — DISCHARGED LIVE:**
   the GitHub API (2026-11-27) resolves the annotated tag
   `EmbarkStudios/cargo-deny-action` `v2.1.4` (message "Release 2.1.4 -
   cargo-deny 0.22.1", tagged 2026-11-24) to exactly the SHA hygiene.yml
   pins (truncated here per the ≥32-hex harness-citation convention:
   `81891abc19…74fda`; full form reproducible live via the API). The pin
   is the tag's true target; the banner's cargo-deny
   0.22.1 claim corroborated.
7. **PROD-riding (the ledger reconciliation)** — the N2-ENTRY gate table
   says "ADV-PROD PROCEED-WITH-CONDITIONS (7)" while the consolidated
   13-point ledger cites PROD conditions by number only where PROD was
   primary. The mapping, recorded so the audit trail closes: PROD-1 →
   ledger 1 (the consolidation record); PROD-2 → ledger 12 (the drift
   disposal); PROD-3 → ledger 5 (the two-session box + the disk plan);
   PROD-4 → ledger 11 (the honesty surfaces); PROD-5 → ledgers 3+4 (the
   palette verification pinning — ENG-1/SEC-7 carried it in the
   consolidated ledger); PROD-6 (the N3/N4 pre-positioning) → carried by
   the exit record's PROD-4 discharge (recorded in STATE's next section
   + the exit reports), not dropped; PROD-7 → ledger 13 (the slip
   re-agenda). Nothing was silently dropped.
8. **The Stage-2 slip re-agenda (fifth surfacing, standing):** the three
   owner options — (a) fund a T3 session (the MSI-record keystream
   decompile chase + tax-modern.md, debt D42), (b) supersede the
   RE-protocol namespace rule, (c) the default re-agenda — no ruling
   received across four prior surfacings; (c) continues and re-agendas
   at N3's gate (the mandatory agenda item below).

**Next: N3's delta-scoped gate** (Android native UI — Android Views +
KMP Android-only over the core via the thin JNI shim; the agenda: the
SDK/NDK feasibility lane (the measured no-Android-SDK sandbox fact vs the
tracked-fetcher class vs the CI android image), the cbindgen trigger (N3
is the recorded first FFI consumer), the FFI seam shape per ADR-017, the
ENG-riding bound-or-record, the per-OS order standing, and the slip
re-agenda above).

## 2026-11-27 · The N3 delta-scoped gate (the Android native UI)

**Context:** N2 CLOSED (exit PASSED) + every rider discharged (the entry
above). The proposal under review (the orchestrator's consolidation): the
new separate-root `core-ffi/` crate (the ONE flat C ABI over the core,
cbindgen-generated header, cdylib, the thin Android JNI shim), `apps/
android/` (Gradle + Kotlin, KMP-shaped one target, Android Views, the
SAF viewer demo, MD3-from-seed via the palette FFI), verification via
local host FFI tests + a CI android job, the riding hardenings (the
duplicate-scan bound + the file-size pre-check), a two-session box, and
the variant preconditions. All four reviewers worked in parallel
isolation with their own probes over the pushed tip 44929c0 (the tree
verified clean by every lane; the ENG topology probe built a real scratch
cdylib path-depping the core — the proposal's core claim verified live).
Reports at `harness/adversarial/reports/2026-11-27-n3-{security,legal,
engineering,product}.md`.

| Reviewer | Verdict | BLOCK? |
| --- | --- | --- |
| ADV-SEC | PROCEED-WITH-CONDITIONS (11) | no |
| ADV-LEGAL | PROCEED-WITH-CONDITIONS (8) | no |
| ADV-ENG | PROCEED-WITH-CONDITIONS (7) | no |
| ADV-PROD | PROCEED-WITH-CONDITIONS (8) | no |

**Material findings the probes overturned (corrected in this record —
the LEGAL risk-(a) class: proposal license claims are claims, not
facts):** (1) cbindgen is **MPL-2.0**, NOT "MIT OR Apache-2.0" (verified
live three ways; GPL-3.0-compatible, build-time-only, never
linked/distributed — the posture is clean; every in-tree record states
MPL-2.0); (2) free disk measured **1.7–1.8 GB** at the gate (not the
~5 GB the 2026-11-27 close carried — `apps/linux/target` (3.4 GB
re-buildable residue) reclaimed AT this gate close per the disk plan:
~5.2 GB free again); (3) the sandbox's Java is a **JRE only** (no
javac/gradle/kotlinc) — the local JVM-test lane does not exist; the FFI
session is cargo-only in-sandbox, the app session is **CI-primary,
forced not chosen**; (4) the runner image, measured live:
ubuntu-latest ships the Android SDK **and** NDK (27.3.x default, 29.x,
30.x present; platforms 34–37; Gradle 9.9.1; JDK 11/17/21/25-default;
Rust 1.100.0 + rustup) — the CI android job needs NO new download
class, only fail-closed version assertions; (5) the ENG probe verified
end-to-end: the cdylib + cbindgen =0.29.4 build-dep route keeps
`core/Cargo.lock` byte-identical, emits the header (Language::C must be
pinned — the default is C++), and the Java_* host-lane (System.load +
the real mangled symbols) works on this sandbox's JVM.

**The consolidated condition ledger (binding the two execution
sessions; every one checkable; the full text in the four reports):**
1. **The hardenings land FIRST in session 1, green + committed BEFORE
   any FFI work** (the riding items close in substance, not record):
   the **indexed-lookup bound** (ENG-1/SEC-5 — the stronger option): in
   `core/src/json.rs::parse_object`, past a new `pub const
   MAX_LINEAR_KEY_SCAN` (≈64, the session records the exact number), a
   lazily built `HashMap<String, usize>` key→slot index, used ONLY for
   find-or-insert (never iterated — insertion order, the
   last-value-wins-at-first-position contract, and every output byte
   unchanged; below the threshold the linear scan stays), with the
   battery: the hostile-amplification case (a 10,000-member object +
   ~100k duplicate-key occurrences, the R-ENG-1 surface, parses green
   under a generous wall-clock bound), the threshold-straddling
   boundary pairs, and the existing member-cap tests unchanged; PLUS
   the **512 MiB file-size pre-check** (ENG-2/SEC-6): the core-owned
   `pub const MAX_INPUT_FILE_BYTES = 512 MiB` (2× the STORE cap,
   rationale beside it) + the named refusal message family + the pure
   decision fn + enforcement in apps/linux's `load_and_compute` (the
   retrofit) AND the Android SAF path AND the core-ffi boundary
   (payloads >512 MiB refused); the exact-boundary battery at each.
2. **The ABI contract** (SEC-2): strings/bytes only — no `#[repr(C)]`
   struct mirrors (the envelope is the payload boundary), inputs
   `(const ptr, explicit len)` NUL-safe pairs, UTF-8-validated named
   errors, NO path parameters (the platform owns file acquisition);
   exactly TWO documented return classes (owned buffers freed ONLY by
   the single `clearfile_free`; `last_error` a borrowed thread-local
   pointer never freed); zero filesystem access in core-ffi.
3. **Panic containment at every export** (SEC-1/ENG-4): one shared
   catch_unwind(AssertUnwindSafe) wrapper at EVERY export (flat ABI +
   Java_* alike) mapping panics to the sentinel status + the
   thread-local last-error in the core's wording family; no
   `panic = "abort"`; the exported-count == wrapped-count grep audit +
   the panic-injection test.
4. **cbindgen exactly** (ENG-3/SEC-7/LEGAL-1/3): `=0.29.4` as
   core-ffi's BUILD-dep; `Language::C` pinned (not the C++ default);
   the Java_* shim EXCLUDED from the header; the SPDX line EMITTED BY
   THE GENERATOR CONFIG (`cbindgen.toml` header) with cbindgen's own
   banner retained; the header a COMMITTED tracked artifact with the
   CI freshness check (regenerate-to-temp + diff fails on drift);
   `core/Cargo.lock` byte-unchanged after every build; the MPL-2.0
   truth in every record (never the refuted dual id).
5. **The JNI shim** (ENG-3/SEC-3/PROD-2): compiled under
   `cfg(any(target_os="android", feature="host-jni"))`; marshals
   `jbyteArray` NEVER `jstring` (the Modified-UTF-8 corruption class);
   a thin translation only — ZERO engine logic on the Kotlin side
   (all compute through JNI; the C ABI stays the one audit surface);
   the JVM tests load the HOST-built .so and call the REAL Java_*
   mangled symbols.
6. **The battery runs THROUGH the boundary** (SEC-4): core-ffi/tests
   calls every C function over all 17 golden fixtures (parity vs
   direct core calls), the malformed-ZIP crash classes + the malformed
   envelope/JSON classes (named errors, never an abort), both cap
   batteries through the boundary; the 550-case differential corpus
   through the boundary (the non-ASCII marshaling catcher — SEC adv-1).
7. **core-ffi's deny.toml from its FIRST commit** (SEC-7/LEGAL-2): the
   apps/linux closed list + **MPL-2.0** (encountered+reviewed: cbindgen
   build-time-only, never linked/distributed) + the wildcard
   disposition for the clearfile-core path dep; sources crates.io-only;
   yanked/wildcards deny; full-lock incl. the build-dep tree; the first
   live green run's number recorded.
8. **apps/android's shape** (PROD-2/LEGAL-5/8): KMP-shaped with
   EXACTLY `androidTarget()` (a `:shared` module + `:app`) — or the
   plain-module simplification as an EXPLICIT recorded gate ruling;
   Android Views only (no Compose); MD3-from-seed via the palette FFI
   at the corpus seed; SAF open (`.clearfile.json`/`.tax`; TXF the
   optional advisory); the bundled fixture PULLED from the shared
   `fixtures/tax/` family (never newly authored); the honesty surfaces
   (the three-fact disclaimer, the IRS/Intuit non-affiliation line,
   prototype labels, the no-AI/no-network note); the manifest requests
   **zero uses-permission (no INTERNET — the claim OS-enforced)**,
   `allowBackup=false`, launcher-only; the AndroidX-taken-or-avoided
   posture + the resolved AGP/Kotlin versions + the SDK-terms one-line
   analysis recorded.
9. **The gradle supply chain** (SEC-8/ENG-5): NO committed
   `gradle-wrapper.jar` (the blob policy — own-authored binaries only);
   CI-primary gradle with the fail-closed version assertion (never the
   unpinned preinstalled default) — or the tracked sha256-pinned
   fetcher class if reproducibility is demanded (the chosen lane
   recorded); `dependencyLocking` + the committed lockfile(s);
   repositories google()/mavenCentral() only; exact-pinned AGP/Kotlin;
   the minimal dependency set (no network/AI libraries).
10. **The CI android job** (ENG-5/SEC-9/PROD-3): additive to
    hygiene.yml (the existing jobs byte-identical — the N2 audit
    pattern); guards-FIRST (the rustc guard; `rustup target add
    aarch64-linux-android`; the NDK identity guard asserting the EXACT
    pinned version's path under `$ANDROID_HOME/ndk/<ver>` — never the
    default or the env; `JAVA_HOME` explicit; the gradle version
    assertion); the cdylib cross-build `--locked --target
    aarch64-linux-android` (the NDK clang as linker via env — no
    cargo-ndk dep); the host .so (feature `host-jni`) + the JVM unit
    tests through the REAL Java_* seam (golden-fixture parity against
    the shared `fixtures/tax/` family); **`assembleDebug`** (beyond
    compileDebugKotlin — the installable APK proven); cargo-deny over
    core-ffi's lock; permissions contents:read; SHA-pinned actions
    only (any NEW pin resolved live + recorded at landing); timeout;
    no secrets; NO uploads.
11. **The guard joins same-commit BEFORE the first build** (SEC-10/
    ENG-6/PROD-7): `.gitignore` gains `/core-ffi/target/` + the
    apps/android set (`.gradle/`, `build/`, `app/build/`,
    `local.properties`, `*.keystore`) BEFORE any in-repo build state;
    the backup ≥32-hex scan path list joins `core-ffi` (apps covers
    apps/android); any known-hash manifest joins at its landing
    commit.
12. **The variant preconditions at exit** (SEC-11/LEGAL-7/PROD-8):
    zero `clearfile/`+`src/` paths in the N3 delta; release.yml
    byte-unchanged; `core/Cargo.toml`+`core/Cargo.lock` byte-unchanged
    (the hygiene license check keeps asserting exactly 1 package); no
    version movement (core-ffi 0.1.0 + apps/android 0.1.0 = new
    `publish = false` planes); nothing shipped, uploaded, or tagged.
13. **The records at the close** (LEGAL-6/PROD-1/3/7): the README rows
    (apps/android + core-ffi: the honest viewer scope, the
    unreleased/prototype status, the interim statement — the Flutter
    app remains the shipped product, the no-AI/no-network +
    non-affiliation notes); STATE/ROADMAP/DEBT/SESSION_LOG/harness_
    check families (the N2 pattern); **every record states each
    verification lane's live status — never an unqualified "landed"**
    (the landed≠verified hardening).
14. **The Stage-2 slip re-agenda — the MANDATORY item, the count
    PINNED** (PROD-4): the enumeration — 1 the N1-exit surfacing, 2
    the N2-entry, 3 the N2-exit convening, 4 the N2-exit close, 5 the
    2026-11-27 discharge restatement, **6 this gate**. The three owner
    options: (a) fund a T3 session (the MSI-record keystream decompile
    chase at payload offset 0x24000 + tax-modern.md, debt D42), (b)
    supersede the RE-protocol namespace rule, (c) the default
    re-agenda. No ruling received at any surfacing; (c) continues; the
    next surfacing rides with N3's EXIT gate.
15. **The execution box: TWO sessions** (ENG-7/PROD-6): session 1 =
    the hardenings green + committed FIRST (item 1), then the
    core-ffi crate + the header + the JNI shim + the boundary
    batteries + the host tests green — all in-sandbox cargo-only; a
    session death still leaves items 1–7 landed (the checkpoint
    discipline). Session 2 = the CI-primary app (apps/android + the
    CI lane + the records/README). The slip rule stands (logged
    honestly, never silently extended; an extension needs a recorded
    owner ruling). **The CI-flakiness absorption rule:** a session may
    close with the CI lane RED and the record stating the run numbers
    + statuses honestly (the disposition riding to the N3 exit gate) —
    what the box forbids is the silent extension or the unqualified
    "landed". The disk re-measured at each session start (1.8 GB at
    the gate; ~5.2 GB after the target reclamation; the app session
    is CI-primary regardless — the JRE-only Java forbids any local
    JVM lane).
16. **The N4/N5/N6 pre-positioning recorded** (PROD-5): **N4** — no
    mingw in-sandbox (re-measured); the two mitigation lanes (a
    portable user-space mingw cross-build, or CI windows runners); N4's
    gate rules the toolchain lane, the first C-header consumption by
    C++ (Win32+Direct2D), the runner's Rust pin, and its own
    working-app bar (the per-lane-status discipline). **N5** — the
    ADR-recorded sandbox infeasibility stands; N5's gate LIVE-verifies
    the macos-latest image list, the label resolution, and the
    macos-13 retirement window; the recorded PROD position: a
    macos-latest CI job alone (author-blind Swift + CI-verified)
    satisfies the settlement's demo bar under exactly the per-lane
    status discipline, with the single-maintainer risk recorded and
    any macOS GA owing an owner-side build or the recorded acceptance.
    **N6** — its gate rules the wasm target for the std-only core, the
    TS engine's retirement per ADR-016, the parity suites' survival
    rule, and the epilogue's OWN terminal freeze declaration (the
    v2.0.0-territory rule — N6's to declare, never an earlier stage's).

**Gate outcome:**

**N3: ENTERED**
(2026-11-27 — 4 × PROCEED-WITH-CONDITIONS, unanimous, no BLOCK; the
topology claim verified live by the ENG probe; the cbindgen MPL-2.0
correction recorded; the two-session box set with the hardenings-first
checkpoint ordering; the disk plan re-measured and the 3.4 GB
re-buildable residue reclaimed; the CI-primary posture recorded as
forced-not-chosen; the slip's sixth surfacing pinned by enumeration.)
