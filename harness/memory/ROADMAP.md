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

**Amended 2026-11-15 (ADR-014, owner directive): native re-platforming
direction — recorded, not yet entered.** The forward implementation
targets one native UI stack per OS (Windows raw Win32 + Direct2D;
macOS Swift + AppKit; Linux Rust via gtk-rs/gtk3-rs and Slint/Qt;
Android Views + Kotlin Multiplatform) over a **shared Rust core**,
themed **Material You** on every OS for consistency with OS-specific
elements kept (`memory/DECISIONS.md` ADR-014). The matrix below still
describes the CURRENT codebases and stays accurate for all in-flight
work: no native stack exists yet, and the Flutter app + web prototype
remain the live implementation. The re-platforming's scope, sequencing,
and budget are a mandatory settlement item at the next full-depth
gate (the RE stage's entry / Stage 3's exit) — see the Stage-2 agenda
below.

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

**Entry-gate agenda (mandatory, carried from the Stage-2 entry gate's
conditions — the gate that enters this stage must settle all of them):**
- **DoD fix (PROD-1, PROD condition 2):** define N (a real number, matched
  to the owner-authored corpus actually available) and the time-box (two
  working sessions, same unit as the parity box) BEFORE entry.
- **Placement ADR-012 (LEGAL-3, PROD-4):** this repo vs a separate research
  repo — panel split recorded in CONSENSUS (ADV-LEGAL default: separate;
  ADV-PROD: in-repo with constraints; ADV-SEC: mild in-repo). If in-repo:
  the no-binary-blob assertion with an explicit synthetic/owner-authored
  fixture provenance distinction runs in `hygiene.yml`; the tools carry
  resource caps with refusal tests (SEC 2 / ENG 2).
- **Security contract (SEC 1):** any new workflow/job follows the repo
  posture (permissions: read, timeouts, SHA-pinned actions); tooling is
  never wired into `release.yml` artifact paths; fixture paths stay
  gitignored.
- **Native re-platforming settlement (ADR-014, 2026-11-15):** scope,
  sequencing, and budget for the per-OS native UI stacks over the
  shared Rust core — which stages absorb the work, the migration shape
  (staged per-OS vs big-bang; the Flutter app's transition fate), the
  ADR-009 parity policy's disposition once one Rust core can serve
  every platform (web via WASM included), the Rust core's scope
  boundary and FFI seams, the macOS/Linux version-tiering definitions,
  and the versioning call (v2.0.0?) — settled BEFORE any native-stack
  code lands.
- **Parity tripwire outcome (MANDATORY, slip fired 2026-11-15):** the
  web-freeze option returns to this gate's agenda. The box was not
  exceeded (parity set closed under budget in one of its two sessions)
  but the gate was not convened within the four-session window, so the
  freeze/parity question must be argued explicitly here — the owner's
  ADR-009 prerogative may still keep parity, but only as a recorded,
  reasoned decision at this gate, not by silence.

**Gate status:** PENDING (full-depth gate; ADV-LEGAL weighted) — convenes
after Stage 3's execution; it is ALSO Stage 3's exit gate.

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

**Gate status:** **Stage 3 ENTERED 2026-11-14** — at the Stage-2 entry
gate, under the re-sequencing: the full-depth panel reviewed this stage's
plan on its agenda and entered it (see `../adversarial/CONSENSUS.md`).
Execution begins with the golden fixtures FIRST (the tripwire's
fixtures-first ordering; clock baseline = 2026-11-14). The exit gate = the
RE-tooling stage's entry gate (full-depth), which reviews this stage's
execution evidence and the parity-tripwire outcome.

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
