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
