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

## ADR-008 · History debt: `nitro_nissi` provenance + rewrite-vs-accept (2026-11-14 — RATIFIED: accept-and-document; see ratification record below)

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

## ADR-009 · Two-codebase policy (2026-11-14 — RATIFIED: FEATURE PARITY, owner prerogative over the recommended freeze; see ratification record below)

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

**CLOSURE 2026-11-14 (Stage-1 execution):** the web smoke tests now exist —
`scripts/web_smoke.py` (build + standalone serve + headless Chromium:
welcome copy, sample load, results, and a mid-flow reload that rehydrates
state from localStorage — the persist path strict mode stresses). The
flag was flipped ON the same day and the smoke suite passes against the
strict-mode build. Residual noted in DEBT/SESSION_LOG: dev-mode
double-mounting itself runs only in `next dev`; promote a dev-mode
assertion when Stage 4's Pages deploy gate lands.

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

## ADR-013 · TurboTax-format bridges + sandbox Ghidra feasibility + Material You everywhere (2026-11-15, owner directive)

**Decision.** Three items, all owner-directed in one session prompt:

1. **Ghidra CLI feasibility in this sandbox: RUN AND MEASURE, don't
   guess.** Ghidra 12.1.4 + JDK 21 was installed under gitignored
   `tools/` and `analyzeHeadless` was benchmarked end-to-end on a
   synthetic stand-in binary with a crypto-constant postScript —
   verdict FEASIBLE with measured limits (exit 0, 11 s, 417 MiB peak
   RSS under a 1 GB heap; Ghidra 12.2 needs JDK 25 and is not usable
   here). Evidence and harness: `docs/ghidra-sandbox-feasibility.md`.
   This is pre-gate research feeding the Stage-2 entry gate's ADR-012
   placement decision — NOT a stage re-entry; Stage 2 remains PENDING
   behind its gate.
2. **The TurboTax-format capability shipped as the protocol's safe
   bridges** (§2.5): TXF import (Flutter, spec v042 with W-2 copy
   grouping and parser hardening), read-only `.tax` inspection
   (Intuit-shape detection + entropy flags, no decryption, no key
   material per §2.2/§7), and the web TXF exporter rewritten to
   spec-true codes (the old 425/426 were the 4952 investment-interest
   family; now 460/461/466/287/636 with the spec sign convention),
   pinned by the new CI bridge suite. This closes three Stage-3 bridge
   items inside the entered stage — no gate bypassed.
3. **Material You on every OS = the MD3 tonal system from a seed,
   identical on all platforms** (`ColorScheme.fromSeed` + complete MD3
   component theming). The ADR-007 revisit was executed against
   dynamic_color 2.1.0 (2026-08-20): the same recorded ColorScheme
   clash against the 3.47 material_ui split reproduces
   (`argument_type_not_assignable`), so wallpaper-derived dynamic color
   stays dropped; ADR-007's revisit clause is now closed with evidence
   until a split-compatible release exists.

**Context.** Owner prompt of 2026-11-15: "Explore the feasibility of
Ghidra CLI analyzeHeadless running in the sandbox … analyze turbotax
proprietary file formats and add the full capability to work with these
files formats to ClearFile. Also use material you for the UI on all
operating systems." "Full capability" is bounded by the ratified RE
protocol's clean-room line (§2.2/§7: no shipped keys/IVs/decryptors; the
AES layer is a technological protection measure) — the capability that
CAN ship fully is the documented safe bridges, which is what landed,
all pinned by tests (Dart suite 95/95; web bridge suite green).

**Consequence.** ClearFile now imports TurboTax's own TXF exports and
inspects `.tax` containers read-only on every platform; real Intuit
payload data still flows through TXF/PDF (documented honestly in the
app's inspection summary). The Stage-2 entry gate agenda gains a
measured feasibility answer for its ADR-012 placement debate, and the
sandbox now carries a reinstallable Ghidra 12.1.4 + JDK 21 bench
harness (`tools/re/`, gitignored) for Phase-4 work on owner-authored
corpora. ADR-007's dynamic-color revisit is closed with a negative
result (re-attempt only on a material_ui-split-compatible release).

## ADR-014 · Per-OS native UI stacks over a shared Rust core (2026-11-15, owner directive)

**Decision.** ClearFile's forward UI architecture is one native stack
per operating system over a **shared Rust core**, with **Material You**
theming across all OSes for consistency while keeping OS-specific
elements. Owner-directed stack assignments (2026-11-15, second
directive of that day's session):

| OS | UI stack |
| --- | --- |
| Windows | Raw Win32 + Direct2D (GPU-accelerated 2D vector drawing) |
| macOS | Swift (for newer versions) + AppKit (for older versions) |
| Linux | Rust — gtk-rs / gtk3-rs (older versions); Slint and Qt (modern versions) |
| Android | Android Views + Kotlin Multiplatform |

- **Shared Rust core**: one core under all four native stacks.
- **Material You everywhere, OS-specific elements kept**: extends
  ADR-013 item 3 beyond the Flutter codebase — the MD3 tonal system
  from a seed, identical on all platforms, with OS-idiomatic
  menus/dialogs/title bars/accessibility preserved per platform.

**Context.** Owner prompt (verbatim): "Specific UI stacks for each
operating system. For windows, use Raw Win32 + Direct2 (with
GPU-accelerated 2D vector drawing). For macOs, use Swift (for newer
versions) + AppKit (for older versions). For Linux, use Rust (gtk-rs /
gtk3-rs for older versions; Slint and Qt for modern versions). For
Android, use android views and kotlin multiplatform. Use a shared Rust
core. Use material you across all operating systems for consistency,
while keeping operating system specific elements." ("Direct2" is
recorded as **Direct2D** — the Windows GPU-accelerated 2D
vector-drawing API, which the owner's parenthetical describes exactly;
no such thing as "Direct2" exists to record literally.) The four named
OSes match the existing Flutter targets (Windows, macOS, Linux,
Android); the web prototype (`src/`) is untouched by the UI
assignments.

**Consequence.** This supersedes the Flutter-app-as-single-forward-UI
posture for the platform layer while leaving every in-flight stage
intact: the Flutter app and web prototype remain the live
implementation today, and **no native stack is scaffolded yet** — per
WORKFLOW §2 the re-platforming enters execution only through a gate
(the settlement is a mandatory item on the Stage-2 entry gate's agenda,
mirrored in ROADMAP). Analysis recorded for that gate — deliberately
NOT decided by this ADR:

- A single Rust core collapses the ADR-009 parity cost for native
  platforms (four thin UIs over one engine instead of N engines). If
  the web prototype later consumes the same core via WASM, the TS
  engine port becomes a transition artifact — the ADR-009 parity
  policy's disposition is therefore a gate question, not settled here.
- Open questions for the settlement gate: migration shape (staged
  per-OS vs big-bang; the Flutter app's fate as transition vehicle),
  the Rust core's scope boundary (1040 engine only? + format bridges /
  persistence / AI cascade?), the FFI seam per platform (C ABI for
  Win32/C++; Swift interop on macOS; JNI for Kotlin; direct on
  Linux-Rust), the macOS "newer vs older" deployment-target tiering,
  the Linux modern-vs-older toolkit line (Slint vs Qt bindings), KMP's
  second target, and whether the re-platform earns a v2.0.0 major bump.
- Material You fidelity: ADR-007's dynamic-color negative result binds
  the Flutter app only; the native stacks implement MD3 from the seed
  directly (no `dynamic_color` dependency involved), so the seed-based
  identical-on-all-platforms posture carries over by construction.
