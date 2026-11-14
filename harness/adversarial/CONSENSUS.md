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
