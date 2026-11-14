# Decision records (ADRs)

Format: decision, context, consequence. Newest last.

---

## ADR-001 · Event-driven backups; no cron (2026-11-14)

**Decision.** Sandbox-to-GitHub backups run as the *last step of every
execution plan* (every reply ends with `scripts/sandbox_backup.sh`), never
on a schedule.

**Context.** Owner directive 2026-11-14. A fixed-interval backup pushes
mid-work snapshots and noise; an end-of-plan backup makes the repository
exactly "the end state of the last finished task". The sandbox recycle
between 2026-11-04 and 2026-11-14 (local git history lost; recovered from
GitHub) is the motivating incident.

**Consequence.** Repository always reflects completed work; no zombie
schedules; a clean tree is a documented no-op. Rule is enforced socially
(WORKFLOW.md §1) plus a secret-pattern guard inside the script.

## ADR-002 · Adversarial consensus gates between stages (2026-11-14)

**Decision.** Every roadmap stage requires a comprehensive review by the
standing adversarial panel before it may start; stages advance only on
independent consensus (unanimous non-BLOCK verdicts; all conditions applied
or rebutted in writing).

**Context.** Owner directive 2026-11-14. Independent = reviewers in isolated
agent contexts, concurrent, no cross-visibility; consensus computed only
afterwards.

**Consequence.** Slower stage transitions; much higher confidence at each
boundary. Owner keeps a documented, explicit risk-acceptance override
(WORKFLOW.md §2).

## ADR-003 · Harness memory lives in `harness/` on GitHub (2026-11-14)

**Decision.** Durable project memory (state, session log, roadmap,
decisions, adversarial records) is stored in-repo rather than relied on
the assistant's conversation memory.

**Context.** Conversation context is compacted/lost across sessions; the
sandbox recycles. GitHub is the only always-current medium.

**Consequence.** A new session bootstraps from the repo in minutes
(harness/README.md defines the reading order). Session logs and consensus
records are append-only — amend by appending, never rewriting history.

## ADR-004 · Backup scope = project state, not sandbox mirror (2026-11-14)

**Decision.** The backup commits only project-relevant state; sandbox
scaffolding (`.env`, `db/`, `.zscripts/`, `Caddyfile`, `tests/`,
`examples/`, `mini-services/`, `tool-results/`, `download/`, `tools/`) is
gitignored and never pushed.

**Context.** An earlier force-push carried scaffolding into the public
repo (fixed by hygiene commit `df617e8`); the public repo should be ClearFile,
not a mirror of a private sandbox.

**Consequence.** Public repo stays clean; user-local data (dev DB,
deliverables, the unrelated `nitro_nissi` app, SDKs) stays private.
Pre-push secret-pattern scan backs the policy.

## ADR-005 · OpenRouter replaces Mistral in the AI cascade (2026-11-03)

**Decision.** Free-tier model chain: Google AI Studio (`gemini-3.1-pro`,
`gemini-3.8-flash`, `gemini-3.5-flash-lite`) → OpenRouter
(`nvidia/nemotron-3.5-super-vl:free`, `nvidia/nemotron-3-ultra-550b-a55b:free`,
`openrouter/free`). Legacy `mistral` entries are dropped on settings load.

**Context.** Mistral's free tier ended 2026-09-21. OpenRouter free rungs
verified live 2026-11-03.

**Consequence.** Cascade remains bring-your-own-key, opt-in, on-device keys
only; 429→degrade, 401→skip-provider behaviour pinned by tests.

## ADR-006 · Widget-test filesystem pattern: `tester.runAsync` (2026-11-03)

**Decision.** All filesystem work in widget tests runs inside
`tester.runAsync`; explicit `pump(Duration)` replaces `pumpAndSettle`
after text entry; `AppState.dispose()` made idempotent.

**Context.** dart:io Futures never resolve inside this SDK's binding test
zone; the autosave debounce Timer trips `_verifyInvariants`. Full story:
`clearfile/test/widget_test.dart` header.

**Consequence.** 42/42 tests green. Documented so future sessions don't
"fix" the pattern away or misread it as a smell without reading the header.

## ADR-007 · `dynamic_color` dropped; static seed `0xFF00696E` (2026-11-03)

**Decision.** No wallpaper-derived color scheme; static teal seed.

**Context.** The package's `ColorScheme` clashes with the `material_ui`
split shipped with Flutter 3.47.

**Consequence.** Slight fidelity loss vs. MD3 dynamic color; correctness and
zero-dependency theming. Revisit if the package publishes a 3.47-compatible
release.

## ADR-008 · History debt: `nitro_nissi` provenance + rewrite-vs-accept (2026-11-14, DRAFT — owner ratification required)

**Decision (recommended default).** Accept-and-document: the pre-`df617e8`
history retains the accidentally-pushed sandbox scaffolding (`.env` with a
local `DATABASE_URL` only, empty 24 KB Prisma `db/custom.db`, `.zscripts`,
`tool-results/`, and `download/nitro_nissi`) — no secrets anywhere (three
independent full-history scans: the platform's, ADV-SEC's, ADV-ENG's).
HEAD is clean. A history rewrite would invalidate `v1.0.0`'s tag SHA for
zero security gain, and anyone who cloned already has the old history.

**Evidence that `nitro_nissi` is the owner's own earlier iteration, not
third-party code:** it is a clean-room GPL-3.0 tax-preparation Flutter app
with the same architecture ClearFile later adopted (RE-adjacent importers,
`.tax` inspection, engine + params files), it self-describes as "Not
affiliated with Intuit/TurboTax or the IRS", it lives in the sandbox's
user-deliverables directory from this same project conversation series,
and the GitHub remote's own second commit is literally "Rename project to
ClearFile" (the repository was renamed after the earlier app name).

**Owner must ratify** (per ADV-LEGAL condition 1): confirm you authored
`nitro_nissi`. If yes → this ADR stands as written + a NOTICE paragraph is
added to the README in Stage 1. If no, or unverifiable → history rewrite
(git-filter-repo + force-push + re-tag from a NEW tag name; preserve the
pre-rewrite tree on an orphan branch so the v1.0.0 binaries' corresponding
source stays publicly retrievable, GPL §6).

## ADR-009 · Two-codebase policy (2026-11-14, DRAFT — owner ratification required)

**Decision (recommended default).** Freeze the Next.js web prototype as a
first-generation study artifact: docs-only maintenance (README already
scopes its engine's limitations), no new web features, web items removed
from Stages 3-5 in ROADMAP's implementation-target matrix. The Flutter app
is the single forward implementation.

**Context.** The engines share zero code and materially diverge (ADV-PROD
finding 1, ADV-ENG finding 3). Feature parity doubles every engine-touching
stage for a single maintainer; freezing makes the divergence honest and
documented instead of a silent overclaim.

**If the owner instead chooses parity:** the missing web engine features
(QDI stacking, NIIT, SALT cap, OBBBA senior deduction, student-loan
interest, exact CTC phase-out) must be added to the Stage-3 scope and the
parity tests must cover both engines against shared golden fixtures.

## ADR-010 · `reactStrictMode: false` stays, temporarily (2026-11-14)

**Decision.** Keep `reactStrictMode: false` until Stage 1's web smoke
tests exist, then flip it on.

**Context.** Strict-mode double-mounting exercises the localStorage
persist/migrate path — precisely the code path ADV-ENG finding 6 flagged
as untested. `typescript.ignoreBuildErrors` was turned OFF today (tsc
clean, typecheck added to CI); strict mode follows once its failure mode is
covered by tests rather than luck.

---

## Ratifications recorded 2026-11-14 (owner, in-conversation)

**ADR-008 — RATIFIED (1. accept and document).** The owner confirmed the
accept-and-document path. README now carries the NOTICE paragraph
describing `download/nitro_nissi/` in history as the same author's earlier
project iteration. No history rewrite; the v1.0.0 tag and release identity
stand.

**ADR-009 — RATIFIED (2. pursue feature alignment = PARITY).** The owner
chose feature parity over the panel's recommended web-prototype freeze —
an explicit owner prerogative against the ADV-PROD/ADV-ENG recommendation.
Consequences (recorded in ROADMAP): the web prototype is a live
implementation target; Stage 3 now carries the web engine parity features
(QDI/LTCG stacking, NIIT, SALT phase-down, OBBBA senior deduction,
student-loan interest, exact CTC phase-out, cents rounding) and the parity
tests must cover BOTH engines against shared golden fixtures pinned to
IRS-published examples. Parity was already implied by the README rewrite;
it is now policy. Risk accepted by the owner: per-stage engine work
roughly doubles in cost; the single-maintainer burnout risk ADV-PROD F1
named applies.

**D20 / SEC-1 — DECIDED (3. add and disclose).** Android main manifest now
declares `INTERNET`; macOS Release.entitlements gains the network-client
entitlement; the network behaviour is disclosed in-app (welcome footer,
settings privacy switch copy) and on the release page (workflow `body:`).
The v1.0.0 release binaries predate this and cannot run the assistant on
Android — noted in the NOTICE/limitations; the next tagged release ships
the fix.

**PAT — DECIDED (4. do not alter).** The owner declined expiry/rotation
changes to the fine-grained PAT at this time. Risk acknowledged and
recorded in WORKFLOW §5 (the rotation policy remains guidance for the
future; branch protection remains recommended, owner-side).

## ADR-011 · Grandfathered-consent migration for `sendReturnContext` (2026-11-14, Stage-1 gate condition LEGAL-4)

**Decision.** Settings files gain `schemaVersion: 2`. Loading a file with no
`schemaVersion` (written before 2026-11-14) is a *legacy* file: its
`sendReturnContext` is reset to the new opt-in default (false) regardless
of the stored value, because pre-fix builds silently defaulted it ON — the
user never affirmatively approved sharing. Files written with
`schemaVersion` present honor the stored value (explicit opt-in/opt-out
survives).

**Context.** ADV-LEGAL Stage-1 finding 4: v1.0.0 wrote `sendReturnContext:
true` by default; without a migration, upgraded users keep transmitting
figures under copy that says "off by default" and "figures you approved".
The alternative (an in-app note) was rejected as weaker: resetting is the
only option that makes the copy true for everyone.

**Consequence.** One-time opt-in loss for legacy users who wanted sharing
(they must re-enable it — the privacy-conservative direction). Round-trip
and legacy-load behaviour pinned by the cascade/privacy tests.
