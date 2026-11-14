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

## Per-stage implementation targets (Stage-0 amendment, ADV-PROD condition 4)

| Stage | Web prototype (`src/`) | Flutter app (`clearfile/`) |
| --- | --- | --- |
| 1 — Hardening | copy fixes, typecheck, lockfile, release body | delete-bug fix (done), privacy gating, INTERNET decision |
| 2 — RE tooling | — | — (tooling is repo-level; placement decided at its gate) |
| 3 — Bridges | TXF exporter verification, `.cfr`→`.clearfile.json` migration decision | TXF import, schema versioning + guards |
| 4 — Pages | (hosted Flutter web build; web prototype itself frozen) | Flutter web deploy |
| 5 — AI hardening | timeout parity | injection suite, fixture e2e, key header fix |
| 6 — Freeze | docs-only | parameter corrections |

The two-codebase policy itself (freeze the web prototype as a
first-generation study artifact vs. feature parity) is **ADR-009,
owner ratification required** — see `memory/DECISIONS.md`. Until ratified,
parity work is NOT scheduled and the web prototype is treated as frozen
(recommended default).

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
artifacts):**

1. **History decision ADR-008 ratified** (nitro_nissi provenance +
   rewrite-vs-accept; default: accept-and-document) — *owner decision*.
2. **Two-codebase policy ADR-009 ratified** (freeze vs parity; default:
   freeze) — *owner decision*.
3. **Android INTERNET-permission decision** (add permission + disclose
   network use, or compile the AI UI out of Android release builds) —
   *owner decision*; ADV-SEC #1, also invalidates README AI claims as
   shipped.
4. Privacy copy matches code (ADV-LEGAL #2/#3): `buildReviewPrompt`
   personal fields gated/`sendReturnContext` default flip + copy alignment
   in Settings/Welcome; web auto-fill "collects vs transmits" wording.
5. Release integrity: `SHA256SUMS` (workflow step drafted in Stage 0 —
   verify at next tag), release `body:` disclaimer (drafted in Stage 0;
   live v1.0.0 release description patched), signing story decision.
6. CI: per-job permissions, action SHA pinning, dispatch tag input,
   timeouts + concurrency (drafted in Stage 0 — verify), gitleaks
   scheduled scan (repo hygiene ≠ sandbox backup, so it does not violate
   the no-cron owner directive), pub/npm caching.
7. Web reproducibility: `package-lock.json` + `npm ci` (drafted in Stage
   0 — verify), typecheck step, `store.ts` cast cleared, then flip
   `ignoreBuildErrors` off; ADR for `reactStrictMode: false`.
8. Tests: widget coverage per interview step, `ReturnStore` interface
   seam (fake store escapes the runAsync tax), web smoke test.
9. GPL headers; SECURITY.md; harness self-check (`scripts/harness_check.sh`).

**Gate status:** PENDING (full-depth gate).

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

## Stage 3 — Clean-room bridges & study artifacts (highest value)

TXF import (Flutter) + verification suite for the existing exporter (web);
`.clearfile.json` schema versioning + migration + **version guard before
any format change ships** (ADV-ENG #11); save-format unification decision
(`.cfr` vs `.clearfile.json`); engine parity tests pinned to IRS-published
worksheet examples via a shared golden-fixture format consumed by both
Dart and TS suites; parser-hardening tests for the first shipped
untrusted-input parsers; `docs/engine.md` (1040 line mapping + limitations
register), repo guided tour, discrepancy-report issue templates, and the
project definition of done (ADV-PROD F5: "v1.1 = a reader can verify every
number against a cited IRS source without reading git history").

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
