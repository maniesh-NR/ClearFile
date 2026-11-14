# Roadmap (gated)

Stages advance **only** through adversarial consensus gates
(`../WORKFLOW.md` §2). Gate status is recorded here and in
`adversarial/CONSENSUS.md`. Dates are session dates (UTC+8).

## Gate depth tiering (Stage-0 amendment, ADV-PROD condition 6)

The panel process is calibrated to a single-maintainer project so it
survives contact with reality instead of being quietly abandoned:

- **Full-depth gates** (all four roles, whole-repository review): Stage 1
  entry (it carries the history and two-codebase decisions), Stage 2 entry
  (RE posture — ADV-LEGAL carries extra weight), and any history-rewrite
  execution.
- **Delta-scoped gates** (all four roles, but scope = "delta since the
  last gate + named risk surfaces for the stage"): Stages 3–6 and spot
  reviews.
- Independence, evidence-based findings, and the verdict vocabulary are
  never relaxed; only the review scope is.

## Per-stage implementation targets (amended 2026-11-14 after owner ratification)

**ADR-009 ratified 2026-11-14: FEATURE PARITY** (the owner chose alignment
over the panel's recommended web-freeze — owner prerogative, recorded in
`memory/DECISIONS.md`). The web prototype is a live implementation target;
the Flutter engine is the reference model the web engine must match.

**Cost statement + tripwire (Stage-1 gate, ADV-PROD condition 3):** parity
roughly doubles per-stage engine cost for a single maintainer — risk
knowingly accepted in ADR-009. It is therefore *time-boxed*: the web-engine
parity set is boxed at two working sessions; if the box is exceeded or the
Stage-3 gate slips, the web-freeze option returns to the NEXT gate agenda
as a mandatory item. Inside Stage 3, the shared golden fixtures land FIRST
(they double as the Flutter reference engine's regression suite and keep
producing value even if parity is deferred by the tripwire).

| Stage | Web prototype (`src/`) | Flutter app (`clearfile/`) |
| --- | --- | --- |
| 1 — Hardening | copy fixes (done 2026-11-14), typecheck (done), lockfile (done), release body (done) | delete-bug fix (done), privacy gating (done 2026-11-14), INTERNET + entitlements (done) |
| 2 — RE tooling | — | — (tooling is repo-level; placement decided at its gate) |
| 3 — Parity & bridges | **engine parity features** (QDI/LTCG stacking, NIIT, SALT cap, OBBBA senior deduction, student-loan interest, exact 5%-of-excess CTC phase-out, cents-not-whole-dollars), TXF exporter verification, `.cfr`→`.clearfile.json` migration decision | TXF import, schema versioning + guards |
| 4 — Pages | (hosted Flutter web build) | Flutter web deploy |
| 5 — AI hardening | timeout parity | injection suite, fixture e2e, key header fix |
| 6 — Freeze | docs-only, parameter corrections | parameter corrections |

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
5. Release integrity follow-through: `SHA256SUMS` (workflow step drafted —
   verify at next tag), release `body:` disclaimer + network disclosure
   (drafted; live v1.0.0 description patched), signing story decision
   (unsigned-demo posture already stated; revisit only if a need appears).
6. CI: gitleaks scheduled scan (repo hygiene ≠ sandbox backup, so it does
   not violate the no-cron owner directive), action SHA pinning (D10),
   caching verification, dispatch dry-run of the hardened workflow
   (explicitly covering both fresh-tag and existing-tag dispatch —
   ADV-ENG Stage-1 note 7).
7. Web reproducibility verification: `npm ci` + typecheck + build in CI
   on the next tag (steps drafted 2026-11-14; verify they pass).
8. Tests: widget coverage per interview step, `ReturnStore` interface
   seam (fake store escapes the runAsync tax), web smoke test; flip
   `reactStrictMode` on when web tests exist (ADR-010).
9. GPL headers (D14); SECURITY.md (D13); harness self-check
   (`scripts/harness_check.sh`, D19 — checklist to include: CONSENSUS ↔
   ROADMAP gate-status AND gate-scope consistency, STATE-vs-ledger
   freshness, stated test total vs actual test declarations, staged-mode
   drift); money-field `parseMoney()` shared util + edge tests (D2);
   sample_w2.csv wiring or removal (D7); ValueKey duplicates guard (D6);
   scripts/ README or untrack for the sandbox-research scripts
   (ADV-PROD Stage-1 note 8).

**Closing event (ADV-PROD Stage-1 condition 1):** Stage 1 ends with a
**v1.0.1 tag** — its rehearsal is item 6's dispatch dry-run — which ships the
Android/macOS network fix, the first `SHA256SUMS.txt`, and the hardened
CI's first full green run.

**Gate status:** PENDING (full-depth gate) — convening 2026-11-14 (this
session) after entry-condition verification (SDK + tests) completes.

## Stage 2 — Format-study infrastructure (RE Phases 1–3 only)

Read-only analysis tooling per `docs/reverse-engineering-protocol.md`
Phases 1–3 (entropy scan, magic scan, differential diff) + crash-safe,
write-free, resource-bounded implementation + unit tests pinned to the
tools; a CI-checkable no-binary-blob assertion on fixture paths; first
`docs/formats/<ext>.md` specs on owner-authored files, following §7.

**Repo placement decided at its gate** (this repo vs a separate research
repo — ADV-PROD F: keep the clean-room narrative clean). Time-boxed with
its own definition of done: published specs for N formats.

**Gate status:** PENDING (full-depth gate; ADV-LEGAL weighted).

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

**Gate status:** PENDING (delta-scoped gate).

## Stage 4 — Demo distribution

GitHub Pages deploy of the Flutter web build (security headers pinned,
welcome disclaimer verified prominent, Stage-1 copy fixes landed first).

**Backlog, cut from the stage** (revisit trigger: a real distribution
need appears): Linux AppImage; Android `.aab` (Play-ready when an account
exists); further packaging breadth.

**Gate status:** PENDING (delta-scoped gate).

## Stage 5 — AI assistant hardening

Prompt-injection test suite (incl. provider-response error snippets
surfaced into UI); recorded-fixture cascade e2e (MockClient pattern);
timeout parity + Google key via `x-goog-api-key` header; in-app privacy
disclosure generated from actual transmission behaviour; plaintext
key-at-rest disclosure (file + format named in-app).

**Gate status:** PENDING (delta-scoped gate).

## Stage 6 — Freeze & codify (terminal)

Final study documentation; declared maintenance mode: parameter
corrections only; version policy (what earns v1.1 / a major bump). The
roadmap ends here deliberately (ADV-PROD F11: a demo project without a
"done" invites an infinite roadmap).

**Gate status:** PENDING (delta-scoped gate).
