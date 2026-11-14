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
