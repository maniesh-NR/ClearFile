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

## ADR-012 · RE-tooling placement: in this repository, with binding mechanics (2026-11-17, Stage-2 entry gate — inserted at the number reserved for it by the 2026-11-14 gate)

**Decision.** The Stage-2 RE tooling (read-only Phase 1–3 analysis tools,
synthetic fixtures, and `docs/formats/*.md` specs) lives **in this
repository**. Recorded unanimously by the panel at the Stage-2 entry gate
— including ADV-LEGAL, which switched from its 2026-11-14 separate-repo
default on the measured facts below. Six binding mechanics travel with
the placement:

- (a) **one enumerated, gitignored fixture/corpus path** — a dedicated
  `fixtures/re/` synthetic directory is the only committable fixture
  path (program-generated bytes with provenance headers); owner-authored
  licensed corpus files live under gitignored `tools/`-style paths and
  are never tracked;
- (b) the **no-binary-blob assertion runs in `hygiene.yml`**, allow-list
  based (tracked binaries are legal only under the enumerated own-asset
  paths — 28 today, all own-authored icons/blueprint PDFs; any new
  binary under `fixtures/`, `tools/`, `docs/` (beyond the existing PDF),
  `src/`, `scripts/`, or `harness/` fails CI), and it distinguishes
  **synthetic** (committed, generated) from **owner-authored**
  (never committed; specs cite hash + provenance only);
- (c) the **same binary allow-list is wired into
  `scripts/sandbox_backup.sh`** — the auto-publish denylist becomes
  mechanical, not aspirational;
- (d) every `docs/formats/*.md` passes the **§7.5 per-spec checklist
  with a provenance field**, spot-verified at the Stage-2 exit gate;
- (e) **tooling is never wired into `release.yml` artifact paths**;
- (f) **Phase-4 binaries/corpus are never tracked** (Ghidra benches run
  under gitignored `tools/re/`, per the measured ADR-013 posture).

**Context.** The 2026-11-14 Stage-2 entry gate deferred the placement
decision to this gate with a split panel (ADV-LEGAL default separate;
ADV-PROD in-repo with constraints; ADV-SEC mild in-repo). New facts
since: the Ghidra sandbox feasibility is *measured* FEASIBLE in-repo
(ADR-013, `docs/ghidra-sandbox-feasibility.md` — Phase-4 mechanics stay
out of the tracked tree by construction); the safe bridges already
shipped in-repo lawfully with tests (ADR-013: TXF import, read-only
`.tax` inspection); the harness discipline (gates, gitleaks full-history
scan, backup secret guard, `harness_check`) is bound to this repo and a
second repo by the same single maintainer predictably drifts ungated;
and the auto-publish risk is *proven* real by history (the pre-hygiene
`tool-results/` accidentally-tracked incident — SEC-6 of this gate) —
which is exactly what the mechanics neutralize.

**Consequence.** Mechanics (a)–(f) land with the **first Stage-2 tooling
commit**; if any is not applied, ADV-LEGAL's recorded fallback reverts
the placement to a **separate research repo** (with pinning,
least-privilege, and secret-guard/gitleaks standards replicated first).
The LEGAL-1 mechanics from this gate (synthetic-only unit fixtures;
differential-tool provenance-manifest refusal per §7.1; the backup hex
guard widened from 64- to ≥32-hex on RE-adjacent paths with a
UUID/known-hash allow-list; a `docs/formats/*.md` lint requiring the
provenance field and no hex runs ≥32) land with that same commit. The
owner may overrule the placement by a recorded ADR.

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

## ADR-015 · Unified ClearFile return file format (2026-11-15, Stage-3 close-out)

**Decision.** ClearFile's own save format is ONE versioned envelope,
used by both codebases and all media (export file, web download, Flutter
autosave store, and the `clearfile.json` entry inside the `.tax`-extension
exchange container):

- Extension: **`.clearfile.json`** (canonical, self-describing JSON);
  `.cfr` remains a read-only legacy alias.
- Envelope: `{format: "clearfile-return", version: 2, app, savedAt,
  filing: {…TaxReturnData…}}` — version 2 is the parity filing shape
  (ADR-009); no version bump was needed to unify (the payload shape is
  unchanged).
- **Version guard** (closing D3's hard rule): both readers refuse files
  claiming a version they do not support; they never guess.
- **Migration matrix**: v2 envelopes read directly; the web prototype's
  v1 `.cfr` envelopes migrate conservatively (warned drops); the Flutter
  app's pre-unification flat layout (`clearfile.return` +
  `formatVersion`, written through v1.0.1 and by the store until now)
  lifts losslessly; a flat `formatVersion > 1` is refused.
- **Import outcomes are sealed** (closing D1): cancelled /
  failed-with-reason / ok-with-migration-warnings — the Flutter import
  never returns a silent null again, and the migration warnings mirror
  the web parser's wording field-for-field.

**Context.** Stage 3's remaining scope ("`.clearfile.json` versioning +
guards + the `.cfr`→`.clearfile.json` unification decision"). Before
this ADR the two codebases wrote incompatible shapes for the SAME model:
the Flutter app exported a flat unversioned map with its marker and a
`formatVersion` field `fromJson` ignored outright (D3), its import
collapsed cancelled/unreadable/wrong-format into one silent null (D1),
and its `.tax` container importer checked the flat marker — so a
container exported by the WEB prototype (which writes the versioned
envelope) could not be imported by the Flutter app at all. The unifying
decision: the web's disciplined envelope wins as the file identity; the
Flutter app's extension (`.clearfile.json`) wins as the filename; every
existing vintage is read with migration and warnings.

**Consequence.** Spec: `docs/return-format.md`. Implementation:
`clearfile/lib/io/return_format.dart` (codec + sealed import outcome,
wired through `files.dart`, `return_store.dart`, `app_state.dart`,
`welcome.dart`, and the `.tax` container importer) and `src/lib/files/
cfr.ts` (legacy-flat acceptance + guard) + `filemenu.tsx` (the web now
downloads `.clearfile.json`). Pinned by 14 new Dart tests
(`clearfile/test/return_format_test.dart`), 2 new container tests, and
the extended CI bridge suite — the store writes the envelope on disk and
migrates legacy flat store files on read, so an exported file and a
saved return are interchangeable again. Known honest limits: the web
model does not carry Flutter return metadata (warned on import), and
`TaxReturnData.fromJson` still defaults an unparseable date to
1970-01-01 (tolerant-read behaviour, now documented in
`docs/return-format.md` §2 — the D3 guard half is what shipped).

## ADR-016 · Parity-tripwire settlement: TS-engine maintenance freeze, retire-on-replacement (2026-11-17, Stage-2 entry gate)

**Decision.** The web prototype's TypeScript engine is under a
**maintenance freeze**: no NEW web-engine features. What still flows:
bug and security fixes; the already-staged Stage-5 hardening items (the
D8/D11/D16 AI-side halves — timeout parity, Google key via
`x-goog-api-key`, key-at-rest disclosure); format-guard compliance (a
future `.clearfile.json` envelope version bump WILL require a web parser
patch, by the version guard's own design); and parameter corrections
that mirror the reference THROUGH the shared-fixture contract (corrections
to the reference engine are pinned by new golden fixtures, which the web
parity suite runs in CI — corrections never land as independent web-side
feature work). The web prototype stays live, deployable, and CI-green as
the golden-fixture consumer and study artifact. The freeze converts to
**retirement** the day the shared Rust core serves the web (WASM
included) — the TS engine becomes a frozen transition artifact
per ADR-017.

**Context.** The parity tripwire's slip condition FIRED 2026-11-15 (the
gate was not convened within four working sessions of Stage-3 entry; the
BOX was not exceeded — the web parity set closed under budget in one of
its two sessions), which by the tripwire's own text returned the
web-freeze option to this gate as a MANDATORY item requiring an explicit,
recorded disposition — the owner's ADR-009 parity prerogative may still
keep parity, but only as a recorded decision, never by silence. The panel
argued it explicitly at the 2026-11-17 gate: ADV-SEC, ADV-LEGAL, and
ADV-ENG recommended a freeze in substance (parity value is banked in the
16 shared IRS-pinned fixtures running in CI on every push; every future
engine change costs ×2 across two codebases with zero mechanical linkage
between the parameter tables; ADR-014's Rust core makes the TS engine a
declared transition artifact, so further feature parity buys a sunset
product at double cost); ADV-PROD argued continued parity narrowed to
maintenance with retire-on-replacement (a pre-emptive full freeze
recreates the D32 divergence shape — a frozen web engine stuck at one
tax year beside a live reference). The positions converge in practice on
exactly this decision's scope: maintenance-only, fixtures as the
correction channel, replacement as the exit. The gate settles it with
the owner-overrule path recorded.

**Consequence.** ADR-009's feature-parity policy (2026-11-14) is
narrowed to maintenance parity by this decision. Stage 5's web items
remain in scope (they are hardening, not features); Stage 6's parameter
corrections reach the web engine only via pinned shared fixtures; the
README's parity claims stay true (the engines ARE at feature parity —
frozen at it). The owner may reinstate full feature parity or order an
immediate hard freeze by recording a reversal ADR; silence changes
nothing. The both-engine CI enforcement (golden fixtures + parity suite
+ bridge suite + oracle) stays exactly as-is for everything that ships.

## ADR-017 · Native re-platforming settlement: staged per-OS over a shared Rust core, as a finite post-Stage-6 epilogue program (2026-11-17, Stage-2 entry gate)

**Decision.** Settles every ADR-014 open question. The native
re-platforming executes as a **separate, finite epilogue roadmap**
(ROADMAP "Epilogue stages N1–N6"), entered only behind its own gates after
the current pipeline (1→3→2→4→5→6) closes v1 — the current roadmap's
terminal Stage-6 freeze stands unchanged, and v1.1 does not wait for any
of this. Recorded variant: the Rust core alone (N1, no UI stacks) may be
entered parallel to Stage 4+ behind its own gate, provided no shipped
artifact depends on it and v1's stages still close first.

| Question | Settlement |
| --- | --- |
| Migration shape | **Staged per-OS, never big-bang.** The Flutter app is the transition vehicle and stays the shipped product on each OS until that OS's native stack reaches GA; each GA retires that one Flutter target; the last Flutter release happens when the final target retires. Conservative planning assumes v1.0.1 binaries may be in real users' hands (11 shipped assets) — replacement proceeds with no coverage gap. |
| Epilogue sequence | **N1 Rust core → N2 Linux → N3 Android → N4 Windows → N5 macOS → N6 web-WASM + terminal freeze.** Each stage lands a working app before the next starts; each is separately gated (killable without collateral). The Android/Windows order (PROD: user-base first; ENG: effort first) is re-settable at the epilogue's own gates without reopening this settlement. macOS is LAST: it cannot be built or verified from this Linux sandbox (needs the `macos-latest` CI runner or owner-side builds). |
| Rust core boundary | **In:** the 1040 engine + parameter tables + format codecs (TXF import/export, read-only `.tax` inspection, `.clearfile.json` envelope codec incl. migrations, exchange container) + MD3-from-seed tonal palette generation. **Out:** the AI cascade (network, keys, provider policy stay per-platform); filesystem/persistence I/O (the envelope IS the persistence contract — the core is pure, deterministic, offline, fixture-verifiable); UI/interview. FFI surface ≈ a dozen functions (`compute`, `import_txf`, `export_txf`, `inspect_tax`, envelope `encode`/`decode`, palette). |
| FFI seam | **One flat C ABI** (`extern "C"`, cbindgen-generated header), the envelope as payload boundary: Win32+Direct2D C++ consumes the header; Android via a thin JNI shim; macOS via the same C header in an SPM target; **Linux links the crate directly (no FFI)**. One audit surface; the C boundary is the new unsafe seam — fuzzed with the fixtures + malformed inputs. |
| macOS tiering | **ONE Swift+AppKit app.** The owner's "Swift (newer) + AppKit (older)" resolves to a deployment-target tier, not two UIs: Swift language throughout, AppKit framework throughout (the conservative choice, no SwiftUI dependency). Floor **macOS 13 (Ventura)** — confirmable at the N5 entry gate; macOS 11–12 unsupported by the native stack (Flutter remains the vehicle while it lives). |
| Linux toolkits | **One toolkit per tier of the owner's two-tier assignment:** `gtk3-rs` for the older tier (RHEL 8/9-era GTK3; MIT bindings + LGPL GTK dynamic link — the cleanest license posture) and **Slint** for the modern tier (GPL-3.0 option, Rust-native, no system-toolkit dependency). **Qt only under its GPL-3.0 open-source terms as a recorded fallback** (commercial Qt without a purchased license is BLOCKED; the C++ toolchain cost is the recorded reason it is not primary). The two-tier split may consolidate to one toolkit at the N2 entry gate if single-maintainer reality demands it (revisitable, recorded). |
| KMP second target | **None — Android-only.** Sharing is the Rust core's job over JNI; a second Kotlin target adds surface with no consumer. |
| iOS | **Dropped from the native end-state — decided explicitly, not silently** (no iOS asset ever shipped; no distribution path; macOS covers the Apple story; one maintainer cannot carry Apple signing/storefront obligations for a demo). The Flutter app remains the iOS vehicle through the transition. The owner may add an iOS row by a recorded ADR (it would be KMP's natural second target). |
| v2.0.0 | **Earned at the first GA release whose distributed artifact for any OS is the native stack** (a user-visible platform-lineage change). The Rust core landing alone does NOT bump. The `.clearfile.json` envelope version stays 2 — three version planes stay separate (app semver ≠ envelope schema ≠ web package.json), and the Rust core must write bit-compatible envelopes, pinned by porting the existing return-format tests. |
| ADR-009 disposition | **Superseded by single-core parity when the Rust core is fixture-green and serves every platform (web via WASM included):** the TS engine is already frozen per ADR-016 and retires when WASM serves the web; the Dart engine remains the reference until the Rust core's fixture parity is green, then freezes to reference status; the parity suites survive as long as any old engine ships anywhere. The doubled per-stage engine cost ends per-platform, not all at once. |

**Verification annex (how a Rust core is PROVED against the reference —
the gate's engineering requirement).** The 16 shared golden fixtures
become the Rust regression contract (a third runner consuming the same
JSON files with the same tolerance semantics) — necessary but NOT
sufficient. A Rust core additionally needs: (a) a differential/property
harness against the Dart reference on randomized + edge inputs (the
fixtures pin breakpoints, not the continuum — the QSS coverage hole is
exhibit A); (b) the bridge suites ported (TXF spec tests, `.tax`
inspection including the malformed-ZIP crash battery — the ENG-1
crafted file is the template — envelope round-trips + warning-wording,
with user-visible warning strings living IN the core so the wording
contract stays pinned); (c) an arithmetic-semantics rule: port with f64
matching the reference first — no semantic changes during a port; the
Python Decimal oracle stays the tiebreaker; cents-integer arithmetic is
considered later, behind the same fixtures; (d) the fixture-authoring
discipline carried over unchanged (never derive expected values by
running any engine).

**Licensing annex (the gate's counsel requirement).** The Rust core is
**GPL-3.0-only**, matching the project; a `cargo-deny`-style license
check runs in CI when the core lands (GPL-2.0-only and unlicensed crates
barred). gtk3-rs (MIT bindings, LGPL GTK, dynamic link — never static);
Slint under its GPL-3.0 option; Qt only under GPL-3.0 terms with a
recorded license note. Win32+Direct2D and AppKit are proprietary
**system libraries** under the GPLv3 §1 carve-out (no
corresponding-source obligation for SDKs); Kotlin/Apache-2.0 is
GPL-3-compatible. A per-platform LICENSES manifest lands with each
platform's first tagged release. Material You/MD3 is unprotectable
functional design (*Apple v. Microsoft* filtration) — nominal references
fine, no Google/Material logos.

**Context.** ADR-014 (owner directive, 2026-11-15) recorded the direction
— per-OS native stacks over a shared Rust core with Material You and
OS-specific elements kept — and deliberately left every open question to
this gate. The panel was unanimous on: staged per-OS (never big-bang), a
finite epilogue program outside the current pipeline, core scope
excluding the AI cascade, one flat C ABI with Linux direct, KMP
Android-only, v2.0.0 at first native GA, and retire-by-replacement for
ADR-009. Recorded split points: the parity disposition (settled as
ADR-016, 3–1 with convergent substance); the Linux primary toolkit
(SEC/ENG leaned Slint, PROD/LEGAL leaned gtk — settled by the owner's
literal two-tier assignment plus one-toolkit-per-tier plus the licensing
constraints, consolidatable at N2); the Android/Windows order
(re-settable at the epilogue's own gates). Material You fidelity is
unaffected: every native stack implements MD3 from the seed directly
(ADR-007's dynamic-color negative result binds the Flutter app only),
with OS-idiomatic menus/dialogs/title bars/accessibility preserved.

**Consequence.** No native-stack code lands before the epilogue program's
own entry gate (owner-funded sessions); ROADMAP gains the epilogue
section with PENDING gate statuses; harness_check patterns updated for
the new stage counts; the current pipeline proceeds unchanged — next:
Stage 2 (RE tooling) execution. The owner may overrule any settled
sub-item by a recorded ADR; the epilogue's own gates remain the natural
re-settlement points.

## ADR-018 · pstack-style engineering protocol layer: PROJECT_MEMORY.md + update_memory.py (2026-11-22, owner directive)

**Decision.** Adopt the Engineering & Token-Efficiency Protocol (pstack
principles; sources: cursor/plugins pstack + Google Cloud Tech):
a root **`PROJECT_MEMORY.md`** as the engineering layer's single source
of truth — tech stack & architecture rules, the active playbook & todo,
verification contracts, and a rolling git-activity window — maintained
by root **`update_memory.py`** (run at session bootstrap or as a
pre/post-commit hook), with **zero-noise compaction** (milestone
summaries carry decisions, changed files, next steps only — no filler,
no failed-debugging dumps, no raw tool output) and **go-deep-first**
working rules (read-only investigation before code; every task anchored
to a checkable outcome). The layering is explicit: `harness/` remains
the GOVERNANCE memory (gates, ADRs, debt, adversarial records —
ADR-003 stands); `PROJECT_MEMORY.md` is the ENGINEERING memory; neither
contradicts the other, and WORKFLOW §3 carries both at bootstrap and
teardown. Parallel agents retrieve from the memory file by its stable
section anchors (grep/section reads — never the whole file into context)
— that is the token-efficiency mechanism ("RAG" in the directive's
terms).

**Context.** Owner directive 2026-11-22, with the pstack
`update_memory.py` template uploaded. The harness already implements
evidence-based, verification-first culture (gates, verification
contracts, event-driven backups); the protocol adds the layer the
harness lacked: a compact, always-current engineering state file that
survives recycles in-repo (same rationale as ADR-003 — GitHub is the
only always-current medium) and lets sessions bootstrap with minimal
context. This session's bootstrap found and resolved the second
unlogged mode-only amend (2026-11-20, `f1af2d4` — same class as the
2026-11-16 incident; reset to the pushed tip `c4982d1` before any
edits), reinforcing the protocol's persistent-memory rationale.

**Consequence.** Two documented deltas from the uploaded template, both
forced by this repo's mega-commit backup granularity (one backup commit
per session, whole-feature diffs) and the protocol's own zero-noise
rule — measured 2026-11-22: a full `-p` window over the last 3 commits
is **245 KB** (vs **19 KB** in stat mode):
1. `PATCH_MODE = "stat"` by default (commit metadata + per-file stat
   summaries; the patches stay in git history — the window points, it
   does not duplicate). `PATCH_MODE = "patch"` restores the upstream
   full-patch behaviour — the owner-overrule path.
2. Noise excludes in either mode: lockfiles, `harness/adversarial/reports/`
   (near-verbatim reviewer reports already archived in-repo), and
   `fixtures/tax/` (golden data already pinned by CI suites).

The script carries the repo's GPL-3.0-only SPDX header (D14 policy —
own-code files). It is NOT wired into `sandbox_backup.sh` (a post-push
run would dirty the tree after the closing backup — an infinite regress)
nor into CI (it is a local/session tool): bootstrap-run + teardown-author
covers it. A bootstrap refresh may be a session's only tree change —
that is legitimate state, not noise. Section-replacement logic and
`NUM_COMMITS` are upstream-verbatim; verified working and idempotent
this session. Owner overrules (either delta, placement, or scope) are
recorded by editing the script's constants and appending a dated note
here.

## ADR-019 · The TT-compatibility program: four-target RE corpus + REA + the compatibility boundaries (2026-11-22, owner directive)

**Decision.** The owner's directive (four TurboTax installer URLs + "use
REA" + UI-layout parity + password-based file capability) is executed as
a **pre-gate research program with recorded boundaries**, per the
ADR-013 precedent (research feeding a gate, not a stage re-entry):

1. **Corpus:** the four publicly-posted installer targets acquired to
   gitignored `tools/re-corpus/` — never tracked (ADR-012 mechanics) —
   with the provenance manifest
   `docs/re-research/corpus-manifest.md` (URL / bytes / sha256 per
   target) as the durable re-acquisition record and
   `scripts/fetch_tt_corpus.sh` as the resumable re-fetcher (mirroring
   the SDK fetcher; byte-size verification inline; no hashes in the
   script itself). Phase-1 + first-pass Phase-4 findings recorded
   (function facts only) in `docs/re-research/2026-11-22-tt-targets-phase1.md`.
2. **Toolchain:** REA 6.10.1 (morluto/rea — the directed front-end)
   over **Ghidra 12.2 + Temurin JDK 25** under `tools/` (REA
   hard-requires ≥12.2, which requires JDK 25; both installed and
   measured this session — the stub analysis runs in ~83 s). The
   protocol-pinned **12.1.4/JDK-21 line stays installed as the
   fallback** (`docs/ghidra-sandbox-feasibility.md`'s measured
   envelope; GhidraMCP pin).
3. **The compatibility boundary (the directive's lawful core,
   refined):**
   - **Password-based access is the shipped target** — the user's own
     password is the authorization; a clean-room implementation of the
     password-based key derivation + cipher usage (the LibreOffice /
     7-Zip encrypted-archive interoperability pattern) is what
     "work with the file by entering the password, not bypassing the
     password" means in shipping terms. The T-scope studies the
     password layer's structure via the four-target RE and ships
     read/edit/save bridges for it after the program's gate.
   - **The fixed-key transport layer** (embedded per-year product
     keys; no user password involved): private study per §2.1/§1201(f)
     stays lawful research; **shipping keys/IVs/ready-made decryptors
     remains the recorded NO (protocol §2.2, trafficking risk)** —
     unchanged by this ADR. The owner must record an explicit
     risk-acceptance ADR (and ADV-LEGAL should re-argue it at the
     program's gate) before any such implementation could exist.
     Surfaced to the owner at this session's close.
   - **UI: functional-layout parity YES; exact expressive copying NO.**
     Copying the unprotectable functional/information architecture
     (wizard steps, fields, groupings, flows — §102(b), *Altai*
     filtration; the directive's own no-trademarks caveat) is the
     defensible scope; reproducing artwork, iconography, distinctive
     trade dress, or wordmarks is not — "copied exactly" is refined
     to **functionally equivalent layouts in ClearFile's own Material
     You expression** (ADR-013/014/017 identity stands).
4. **Program shape:** a separate gated program (ROADMAP's "TT-compatibility
   program", T1 research → T2 deep per-target Phase-4 → T3 format-family
   specs incl. the password layer → T4 the password-based bridge + UI
   functional-layout study results) — **Stage-2's DoD box (N=4 / two
   sessions) is NOT silently grown** (the never-silently-grows rule);
   the program enters execution behind its own gate, which carries:
   the fixed-key-layer question above, the Canadian-law assessment
   (the protocol is US-law framed; the Canadian targets add Canadian
   copyright/TPM considerations for ADV-LEGAL), and the standard
   security-contract application to any tooling it adds. T1 pre-gate
   research STARTED 2026-11-22 (this session: corpus + Phase-1 + the
   REA first pass).

**Context.** Owner directive 2026-11-22 (four CDN URLs + REA + "copied
exactly" + the password-entering framing). The password framing IS the
defensible path (vs bypassing); the exact-copy framing needed the
expression refinement; the four targets are publicly posted installers
(no access control circumvented by acquisition; studying them is the
protocol's Phase-4 posture — and the STUB-carving technique this session
demonstrated makes the installers tractable in this sandbox without the
§4.A/C environments).

**Consequence.** Mechanics partially landed EARLY (ahead of the first
Stage-2 tooling commit) — justified and recorded, not silent: the
corpus-manifest hex exclusion in `scripts/sandbox_backup.sh` is the
**known-hash allow-list's first instance** (LEGAL-1 mechanics; the
manifest is provenance, not RE tooling — the rest of the LEGAL-1
mechanics still land with the first Stage-2 tooling commit). The
`docs/re-research/` notes follow §6/§7.4 (function facts, paraphrased
strings). Nothing from the corpus is committed except the manifest
(public-fact checksums) and the notes. Next: T2 behind the program's
gate; the owner's explicit decision is requested on the fixed-key-layer
question.

---

## ADR-020 · The shipped decryptor: owner explicit risk acceptance for the fixed-key transport layer (2026-11-22, owner directive)

**Decision.** The owner's instruction this session — "Record an explicit
risk-acceptance ADR for the shipped decryptor and proceed" (trace
`1a2023899589beed`) — is the answer to the decision ADR-019 surfaced at
its close. Recorded as the owner's explicit, deliberate risk acceptance:

1. **Accepted: shipping the TT-format decryptor, fixed-key transport
   layer included.** The distributed GPL-3.0-only product may carry the
   password-based TT bridge (the TT program's T4) as a clean-room
   implementation that includes the per-year fixed-key transport layer
   (no user password in that layer) — the "recorded NO" of protocol
   §2.2 is lifted for exactly this scope. The product's interaction
   model stays password-gated: the user's own password is the
   authorization (ADR-019's lawful core, unchanged); the fixed-key layer
   is container transport beneath that gate, never a user-facing
   bypass.
2. **The risk accepted, on file.** Distribution of decryption means in a
   public repository: §1201(a)(2)/(b) anti-trafficking theories (the
   *321 Studios* analog — user-held keys did not save the shipped
   decryptor there; contra: §1201(f)'s interoperability texture, the
   per-year keys being publicly documented since 2024, the
   password-authorization frame); the Canadian targets' exposure under
   Canada's Copyright Act TPM provisions (the 2012 C-11
   anti-circumvention regime, civil-enforced, with enumerated
   exceptions that include program interoperability — assessed at this
   session's TT gate); Intuit EULA-based claims against the RE
   provenance; and the practical enforcement risk (cease-and-desist /
   takedown attention), which acceptance does not immunize — it makes
   the posture deliberate and recorded. This is the owner's
   disposition, NOT an ADV-LEGAL clearance: per ADR-019, ADV-LEGAL
   re-argues the question at the TT program's gate (convened this
   session, after this ADR).
3. **Boundary conditions — non-negotiable; a violation reopens the
   acceptance:**
   - password-gated product surface only: no bypass, no brute-force,
     no password-recovery, no open-without-password mode; refusal
     tests per the security contract; wrong-password = clean failure,
     nothing logged;
   - key material confined to ONE provenance-labeled module in the T4
     bridge (clean-room derived); key VALUES never appear in research
     notes, specs, docs, tests, or commit messages (§7.3 amended only
     for the bridge's implementation scope — everything else stays
     "by existence");
   - §7.2 unchanged: no decrypted content is ever committed; the
     product computes plaintext at runtime on the user's own files;
   - §7.4 / the ADR-019 UI boundary unchanged: functional-layout
     parity in ClearFile's own Material You expression; no
     trademarks, no expression;
   - the acceptance carries an enforcement-response plan: a
     cease-and-desist or takedown demand against the bridge pauses
     its distribution and re-opens the question at a gate — never
     silent continuation.
4. **Effects.** ADR-013's read-only/no-decrypt product posture is
   superseded IN PART (the TT password-based bridge scope only — the
   `.tax` inspector and everything else unchanged). Protocol §2.2's
   recorded NO and §7.3's by-existence rule are amended IN PART (the
   shipped bridge's key module only; dated amendment note in the
   protocol). The TT program's gate convenes WITH this acceptance on
   record; T2–T4 may execute behind it; Stage-2's DoD box is still not
   grown by any of this.
5. **Overturn path.** A later owner ADR may narrow or revoke this
   acceptance (the same mechanism, never silence); a gate may add
   conditions but not silently revoke the owner's acceptance.

**Context.** ADR-019 executed T1 and recorded the boundary
(password-based access = the shipped target; the fixed-key layer =
recorded NO absent an explicit owner risk-acceptance ADR — "surfaced to
the owner at this session's close"). Nothing has shipped: at tip
`52e2c68` no decryptor exists in the tree (the `.tax` capability is the
read-only inspector under ADR-013's posture); this acceptance governs
the capability the TT program will build, and is recorded BEFORE any
such implementation exists — exactly the ordering ADR-019 required.
The owner's "proceed" opens the TT program's gate (convened this
session: the fixed-key re-argument, the Canadian-law assessment, the
security-contract application) and T2 behind it.

**Consequence.** The acceptance is on file with its full risk register;
the TT gate's conditions bind T2–T4 (recorded in CONSENSUS); the T4
bridge's merge conditions include the boundary conditions above as
refusal tests + the quarantined key module + the ship-time disclosure
(README/SECURITY provenance statement); the protocol file carries the
dated amendment so future sessions read one consistent rule set. The
residual exposure is the owner's, accepted with eyes open;
ADV-LEGAL's re-argument and the Canadian assessment are recorded at
the gate for honesty, not as clearance.

**Orchestrator annotation (2026-11-22, filed at the TT program gate —
wording clarification, gate condition PROD-6; the decision text above
is otherwise verbatim and unedited):** ADR-020 §3's "no
open-without-password mode" reads on files that carry a user password:
*no mode that opens a password-protected file without its password.*
The modern `.tax` family's base encryption is the fixed-key layer,
with no user password on some files (protocol §5); the bridge's
handling of the user's own UNPROTECTED files is a deliberate T4
design decision to record at T4 design time (possession-as-
authorization, the TXF-import analog — not a bypass of anything).
Exit-ramp artifact classes for the enforcement-response plan: the
bridge's distribution pauses (plus a gate re-open); the by-existence
specs/notes (T2/T3 outputs, no key values) are reviewed at that gate,
not auto-removed.

## Ratifications recorded 2026-11-26 (owner, in-conversation)

The Stages-4/5/6 after-the-fact gate (CONSENSUS 2026-11-26) surfaced
three deviations for owner ratification. The owner ruled on all three
in one message, and funded the epilogue program in the same message.

**Gate sequencing — RATIFIED.** The after-the-fact convening of the
Stages-4/5/6 gate stands as valid (the execution preceded the gate
under the owner's own blanket directive; the gate reviewed the full
delta `6205222 → 8622e74` and returned 4 × PROCEED-WITH-CONDITIONS
with every condition discharged). No remediation directed; the
retrospective-gate pattern is acceptable ONLY under an explicit owner
directive, never by default — recorded as the standing reading of
WORKFLOW §2.

**PAT Pages-enablement — RATIFIED.** The owner's fine-grained PAT was
used to mutate repo settings (enable Pages) after the workflow's
GITHUB_TOKEN was 403-refused on site creation. Approved; the use class
joins the token's observed profile in WORKFLOW §5 (Contents:RW +
Actions write/read + repo-settings mutations — treat theft as
full-repo, CI, and settings compromise).

**pages.yml `id-token: write` — RATIFIED.** The OIDC grant on the
deploy job is approved as the deploy-pages API requirement; the
recorded deviation from the Stage-0 "pages: write + contents: read,
nothing more" posture is accepted with eyes open (the grant is
deploy-scoped, short-lived by the OIDC design, and confined to
pages.yml).

**Epilogue N1–N6 — FUNDED.** The owner funded the native re-platforming
program (ADR-017 settlement) in the same message. Funding gates the
program, not any stage: every epilogue stage still enters only behind
its own gate per the WORKFLOW §2 tiering — N1's full-depth entry gate
convenes first; N2–N6 are delta-scoped at their turns. The ADR-017
recorded variant remains available (N1 alone may proceed while later
stages wait). ROADMAP's six epilogue gate statuses updated to FUNDED
2026-11-26; CONSENSUS and DEBT carry the ruling; no epilogue code
exists yet.

**Orchestrator annotation (2026-11-26, filed at the N1 full-depth entry
gate — count erratum, gate conditions ENG-9/SEC-adv/PROD-7; the
decision text above and the annexes are otherwise verbatim and
unedited):** the verification annex's "16 shared golden fixtures" and
ROADMAP's N1 bullet predate D33 (2026-11-22, the QSS fixture #17); the
actual shared-fixture count is **17**, and the Rust runner consumes 17.
The verification annex's licensing annex sentence "runs in CI when the
core lands" is authoritative over any looser paraphrase ("when
dependencies land") that may appear elsewhere — the N1 gate discharged
it with the zero-dependency fail-closed assertion in the same commit
series as the core, upgraded to a real cargo-deny at the first external
dependency.
