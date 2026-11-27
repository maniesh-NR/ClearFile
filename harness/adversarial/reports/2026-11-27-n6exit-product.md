# ADV-PROD — N6 exit gate, the TERMINAL gate's exit (2026-11-27, Task N6-EXIT-PROD)

**Scope:** the N6 exit gate over the delta `1dd84dc..HEAD` (2 commits —
`f295a27` the execution landing, `8387202` the entry record + the
checker families; 32 paths, **+3,734 / −200**), ADV-PROD lane per
ROLES.md — roadmap rightness, stage ordering, overreach, platform
priorities, single-maintainer sustainability, records honesty, the
demo-vs-misuse tension. One of four parallel isolated reviewers
(reports at `harness/adversarial/reports/2026-11-27-n6exit-*.md`;
none read by me). My entry report
(`harness/adversarial/reports/2026-11-27-n6-product.md`, 8 conditions)
is the ruling set this gate discharges; the CONSENSUS N6 entry record
(the tail of `harness/adversarial/CONSENSUS.md`, :2211–2318) carries
the rulings + the orchestrator reconciliations (a)–(f), ALL verified
against the landed code below.

**Verified live at my own probes (every claim below is my own
command):** the working tree CLEAN at probe (`git status --short`
empty); `git tag` → exactly v1.0.0/v1.0.1/v1.1 (the nothing-shipped
baseline the GA gate hangs on); **the lane's green re-proven LOCALLY
by me, end to end**: the `.wasm` (318,715 bytes) loaded in node —
**ZERO imports** (the strongest no-network proof, mechanically
re-run by me: `WebAssembly.Module.imports(m).length === 0`) — the wasm
parity suite **17/17 fixtures, 0 field failures** (plus the
allocator ruling 100 interior-NUL cycles ok + the core-served
parameter table ok), the transferred bridge suite **11/11 groups**,
the AI suites **5/5 + 4/4**, the app `tsc --noEmit` exit 0 (the
whole tree, the frozen files still compiled), the boundary battery
**12/12 green** with the panic-hook feature (the CI form; plain run
= 11 of 12 — the panic-injection test is feature-gated, see Rider
8's known-skip note), `harness_check.sh` → **0 failures** at the tip
(FUNDED 0, N-outcomes 10 as landed).

**THE HEADLINE FINDING (records honesty, my lane's own discipline —
the same class my N5-exit finding corrected): the recorded green-run
number is the WRONG run's ID.** ROADMAP.md:788 and the `8387202`
commit message record the N6 execution as "run **45991816001** on
f295a27, all EIGHT jobs". My own live API probe (the repo token, the
same verified-live method as my N5 exit's run-page probe) shows:
**run 45991816001 is the ADJACENT DEPENDABOT run** — workflow
`dynamic/dependabot/dependabot-updates`, event `dynamic`, created
2026-11-27T11:36:06Z, **ONE job ("Dependabot")**. The N6 hygiene run
is **run 45991786766** — workflow `.github/workflows/hygiene.yml`,
event `push`, head `f295a27`, created 2026-11-27T11:35:54Z (four
seconds after the backup push at 11:35:50Z), **completed/success, all
EIGHT jobs success** (Android, Linux, gitleaks, Test suites, macOS,
Harness memory self-check, RE tooling, Windows — every job's
conclusion fetched by me). The LANE's claim is TRUE — first-green, one
round, all eight jobs — of **45991786766**; the citation transcribed
the adjacent run's ID (both runs sit on the same SHA twelve seconds
apart). The dated correction is Rider 1 (the same N4/N5 correction
form: never papered over, never left in the program's terminal
record).

VERDICT: **EXIT-PASS (9)** — the eight entry conditions are
discharged in substance and verified live; every residual item is the
close's own planned set (the freeze declaration, the README honest
surface, the DEBT row, the checker advance, the SESSION_LOG/STATE
close-outs, the run-number correction). No app change, no lane
change, no re-opened question rides past the epilogue's LAST gate.
The exit is granted; the nine close riders below carry the exact
texts the close must land.

## The eight entry conditions, discharge-verified

1. **Shape A served — DISCHARGED, verified live.** The four TS
   modules retire with the exact dated terminal banner (engine.ts,
   txf.ts, taxfile.ts, cfr.ts — each +9 lines: "RETIRED 2026-11-27
   (N6, the epilogue's terminal gate) … FROZEN TRANSITION ARTIFACT —
   out of the app's runtime import graph, kept in-tree as a study
   artifact, still tsc-checked, and BYTE-FROZEN from this edit … they
   go to the Rust core (src/lib/wasm/ is the successor adapter)").
   `config.ts`: the parameter TABLE removed (the YEARS/TY2025 record
   gone — 139 lines removed; the banner comment names the retirement
   + the one true source: "the core's own params (served via
   clearfile_params_json; the adapter's params()/yearParams())"), the
   labels/formatters ALIVE (STATUS_LABELS, STATUS_HELP,
   DEDUCTION_METHOD_LABELS, usd, pct, DEFAULT_YEAR, SUPPORTED_YEARS,
   PARAMETER_SOURCES). The live import graph after the flip: `rg
   "from '@/lib/(tax|files)" src` → exactly one live site
   (`steps.tsx:23` — the labels/formatters surface), and the broader
   relative-path probe (`from '\.\.?/(tax|files)'`) → only
   type-only/import-erased surface reads (`store.ts`'s
   `import type` from `./tax/config` + `./tax/engine`, `tasks.ts`'s
   `usd`, the frozen files' own intra-frozen imports). **Zero live TS
   compute/parameter/codec logic:** the adapter's `compute` is
   `clearfile_compute` through the boundary; the parameter data is
   `clearfile_params_json` parsed once; every codec (`parseCfr`,
   `serializeCfr`, `exportTxf`, `importTxf`, `analyzeTaxFile`,
   `exportTaxContainer`, `loadAndCompute`) rides the wasm exports;
   the only local logic is the ruled display glue (see the
   reconciliation (b) acceptance below) + pure DOM helpers
   (`downloadText`/`downloadBytes` — "nothing codec-shaped"). All five
   consumer sites flipped (steps.tsx, filemenu.tsx, ai-ui.tsx,
   tasks.ts via the adapter; store.ts needed no flip — its imports
   were all surface); `page.tsx` gains the boot gate (the Splash
   until `wasmReady()`, the honest error surface on load failure).
   *Two form-level observations, recorded not papered over:* (i)
   `store.ts` still TYPE-imports `Dependent/TaxReturnData/W2Entry`
   from the frozen engine.ts — type-only (erased at emit), within the
   ruled split (types are SURFACE) and within the banner's own claim
   ("out of the app's RUNTIME import graph"); the adapter carries
   its own copies (core.ts:50–135), so a future GA-era cleanup could
   re-point store.ts — never required, recorded as the form note; (ii)
   the tsconfig.parity/files/ai programs now compile the adapter +
   `tax/config.ts` (type-only imports, the erased-at-emit discipline
   the adapter documents) — the frozen files stay tsc-checked through
   the app's own `tsconfig.json` (`**/*.ts` include; verified: `tsc
   --noEmit` exit 0 with the frozen files in the program).

2. **The wasm32 target + the seam — DISCHARGED; reconciliation (b)
   ACCEPTED.** (a) `wasm32-unknown-unknown` (not wasip1), built in CI
   AND locally (the pinned toolchain + the wasm32-std component,
   manifest row 2, sha256-pinned — `scripts/fetch_rust_toolchain.sh`
   + `scripts/rust_toolchain_manifest`); my own load of the module:
   **ZERO imports**, and the export set is the SAME flat C ABI — no
   `__wbindgen`/framework shims, exactly the 14 `clearfile_*`
   functions (the 10 prior + the four N6 additions). (b) NO
   wasm-bindgen, NO new dependency: `core-ffi/Cargo.toml`,
   `core/Cargo.toml`, `cbindgen.toml` all byte-unchanged in the delta
   (the zero-dep assertion intact), and **`package.json` +
   `package-lock.json` byte-unchanged vs `1dd84dc`** (empty `git
   diff`; my Condition 2's checkable passes exactly) — the loader is
   `WebAssembly.instantiate` + the flat exports, nothing else; the
   npm-audit gate's scope stays meaningful. (c) The FOUR-export set —
   `clearfile_alloc`/`clearfile_dealloc` LENGTH-PAIRED (Vec::
   from_raw_parts with len+1; the interior-NUL trap class
   probe-verified at the gate AND re-proven by me: the battery's
   100-cycle all-NUL alloc/dealloc test + the suite's 100
   interior-NUL cycles through the real ABI), `clearfile_export_tax_container`
   (the caller-allocated length-out binary channel — probe call
   returns 1 with the needed size, never an error; binary never rides
   the CString returns; the NULL out_len is a named error), and
   `clearfile_params_json` — **reconciliation (b) ACCEPTED, on my
   Condition 1's own grounds**: the table's retirement REQUIRES the
   core to serve it (the UI's live bracket display walks the table);
   the addition is append-only (no existing export touched), served
   through the same guard/CString/last_error shape, with the field
   names mirroring the TS interface exactly (reconciliation (c) —
   verified by me: the serialized JSON keys are
   `year/standardDeduction/…/ordinaryBrackets[].rate|upTo`, the
   infinite terminal rung as `null`, per-status keys the FilingStatus
   strings); the display walk stays adapter-side glue with ZERO
   parameter logic platform-side (the walk's every rate/threshold
   comes from the core). My entry condition's letter listed
   `bracketWalk`/`ruleChecks` as "engine"; the reconciliation's ruled
   middle is the correct reading — both are the retired engine's own
   DISPLAY families (the verbatim-carried review-hint heuristic + the
   bracket-table renderer), and the substance of my split ("every
   numeric tax parameter and every compute byte originates in the
   core") holds exactly. (d) The exports are PLAIN/un-gated on every
   target (reconciliation (a)) — the battery proves the
   alloc/dealloc + container exports on every lane (verified: the
   linux/android/windows/macos jobs all green on run 45991786766);
   the committed header `core-ffi/clearfile.h` carries exactly the
   four new declarations (verified: the diff adds alloc/dealloc/
   export_tax_container/params_json, nothing else), regenerated
   through the config-emitted flow (cbindgen build-time-only,
   unchanged). The un-gated choice over SEC's smaller-native-header
   intent is the reconciled ruling — ACCEPTED (the every-target
   battery coverage is the stronger posture; LEGAL-6's
   exactly-one-declaration was superseded by the honest-set finding).

3. **The parity-suite transfer — DISCHARGED, verified live.** The
   transferred suite `scripts/wasm_parity_test.mjs`: the SAME 17
   shared fixtures (`ls fixtures/tax/*.json | wc -l` → 17, unchanged
   in the delta), the same DEFAULT_INPUT merge + tolerance semantics
   + the exact `deductionMethodUsed` enum assert; my local run →
   **17 fixtures, 0 field failures**, plus the allocator ruling (100
   interior-NUL cycles, module still ready) + the params-table
   assertion (year 2025, standardDeduction.single 15750,
   saltBaseCap.single 40000, the null terminal rung). The retired TS
   runner: `web_parity_test.mjs` carries the retirement banner ("the
   parity CONTRACT transferred byte-for-byte to
   scripts/wasm_parity_test.mjs … this script stays as the frozen
   transition record and is no longer the CI contract") and is
   REMOVED from hygiene.yml (the diff replaces the two TS-suite
   steps with the wasm32 build + the import-empty guard + the
   transferred suites). The bridge suite `txf_taxfile_test.mjs`
   transferred per reconciliations (d)/(e) — verified: it now
   compiles the adapter (`tsconfig.files.json` → `src/lib/wasm/
   core.ts`), initializes the wasm module first (node path), carries
   its own STORE-ZIP builder for the synthetic non-ClearFile shapes
   (the retired makeZip's fixture-tooling role), builds the
   ClearFile-container fixture through the adapter's own
   `exportTaxContainer`, and the legacy-flat lift assertion follows
   the core's documented divergence-5 contract
   (`assert.deepEqual(warnings, [])` — the web-reader-only string
   not ported; the suite records WHY in-line). My local run →
   **11/11 groups**. The THREE live runners in the same suites job:
   Dart (flutter analyze + test), the Rust core (cargo test --locked
   — the golden-fixture runner), the wasm adapter
   (wasm_parity_test.mjs + the transferred bridge) — the ADR-009
   survival rule holds (the Dart engine still SHIPS; what died is
   only the runner whose subject was the retired TS engine). The AI
   suites stay UNTOUCHED (both scripts byte-unchanged; the AI cascade
   is per-platform, `src/lib/ai` not retired) — my local runs: 5/5 +
   4/4. The suites job's wasm32 lane: builds the panic-hook variant
   FIRST (copied aside), then the plain build overwrites the output
   path, asserts the emission (`test -f`), then the **import-empty
   guard** (a module with ZERO imports cannot call out at all — the
   otool-exact-list analogue; I re-ran the same check locally: 0
   imports).

4. **The terminal freeze declaration — NOT YET LANDED, AS RULED (it
   lands at THIS close); the text is READY and restated VERBATIM
   below (Rider 2).** Verified: `rg -n "terminal freeze"
   ROADMAP.md README.md STATE.md SESSION_LOG.md CONSENSUS.md` →
   pointer mentions only (the agenda references), no landing with the
   six elements anywhere. ROADMAP's N6 bullet ends "The exit gate +
   the terminal freeze declaration follow at the close." The ruled
   text (my entry Condition 4, unedited) carries the six elements:
   (1) the epilogue COMPLETE sentence (N1–N6 each entered/executed/
   closed behind their own gate with an honest record; the shared core
   serves every platform through the same flat C ABI incl.
   wasm32-unknown-unknown); (2) the demo-prototype honesty sentence
   (every native app unreleased, CI-verified-only; the Flutter app
   remains the shipped product until each OS's native GA; the Dart
   engine the frozen reference); (3) the TS retirement sentence (the
   frozen transition artifacts kept in-tree; cleanup after v2.0.0 GA
   a future owner decision; nothing deletes or rewrites them); (4)
   the v2.0.0-stays-GA-gated paragraph (nothing at the N6 close
   moves any version plane — app semver v1.x, envelope schema 2,
   every crate/package plane its own); (5) the post-epilogue
   maintenance posture (the four accepted channels + the
   out-of-scope list); (6) the parked owner-items paragraph (Stage-2
   exit stays SLIPPED; D42; D30 — never a silent drop). The FIVE
   homes at the close: ROADMAP (the epilogue frame at the N6
   bullet's close), README (the maintenance-policy section
   extended), STATE (the close-out), CONSENSUS (the exit record),
   SESSION_LOG (the close entry) — the entry condition's three
   landings + the two terminal-record homes the close owes.

5. **The TWELFTH surfacing + the TERMINAL-gate parking posture —
   DISCHARGED in the entry record; the close record must REPEAT it
   (restated VERBATIM below, Rider 3).** Verified in CONSENSUS's N6
   entry record (:2292–2307): the pinned enumeration **1** the
   N1-exit, **2** the N2-entry, **3** the N2-exit convening, **4**
   the N2-exit close, **5** the 2026-11-27 restatement, **6** the N3
   entry, **7** the N3 exit, **8** the N4 entry, **9** the N4 exit,
   **10** the N5 entry, **11** the N5 exit, **12** THIS gate; the
   three owner options ((a) fund a T3 session — the 0x24000
   keystream chase + tax-modern.md, debt D42; (b) supersede the
   RE-protocol namespace rule; (c) the default re-agenda); "No
   ruling received across ELEVEN prior surfacings; (c) continues";
   and the explicit TERMINAL-gate parking posture. DEBT.md: D42
   (disposition "T3 session 2") + D30 (owner-side) both stand
   UNCHANGED in the delta (DEBT.md untouched — correct: append-only,
   no disposition change without an owner ruling).

6. **The release.yml / pages.yml re-rules — DISCHARGED; the close
   recording ruled in Riders 5(a)/(b).** Verified: the N6 delta's
   `.github/workflows/` touches ONLY hygiene.yml; `git diff
   47f33a4..HEAD -- release.yml pages.yml` → EMPTY, and **release.yml
   md5-identical to 47f33a4** (`e2e879d5…` both sides — byte-frozen
   through the N6 close, the verified baseline). The RM_NATIVE
   variant precondition stays literally true (nothing shipped; tags
   exactly v1.0.0/v1.0.1/v1.1). pages.yml: trigger `clearfile/**` +
   pages.yml itself (verified in-file), the N6 delta touches neither —
   the live Pages demo (the FLUTTER web build, the Dart engine) is
   unaffected by construction. The nextjs-web job (release.yml:496–
   572) is STALE-BY-DESIGN against the converted `src/` (no wasm
   build step; a post-conversion tag would red the job — fail-LOUD,
   never a silent bad asset): the close records BOTH rulings + the
   stale-by-design note + the no-tag-before-rework constraint in the
   CONSENSUS exit record, and the standing posture lands as a DEBT
   row (Rider 5) — the v1.1 tarball is the LAST TS-engine web
   distribution; the first wasm-served web distribution is
   v2.0.0-GA territory; ANY tag push before the release.yml rework
   is an owner decision that must FIRST resolve the web-asset
   question. (Also verified: the local-run honesty — `public/`
   contains no `clearfile-core.wasm`; the browser copy is a build/
   deploy-time artifact, gitignored by the delta's `.gitignore` line
   — the boot gate fails LOUD with the honest 404 error, and Rider 4
   makes the README state the copy step.)

7. **The ONE-session box — DISCHARGED, with the ordering note
   recorded.** The box closed FIRST-GREEN: ONE round, the push's own
   run green (the honest CI-fix datum **N6=1 round, first-green** —
   zero blind rounds; the entry record's softened posture
   "CI-verified + locally provable" honored: the local lane ran
   before the push — my own re-run of the same local lane is green,
   and the wasm-first ordering executed as the LOCAL-verification
   sequence: the wasm parity + bridge + battery + tsc all green
   BEFORE the flip was pushed; the landing is ONE atomic commit, so
   the pushed tree is whole — never a half-served web, and
   `page.tsx`'s boot gate makes the half-served state unreachable
   even if the .wasm fails to load). My entry Condition 7(vi)'s
   multi-commit checkpoint form ("the commit order shows the
   wasm-parity-green checkpoint preceding the retirement flip") was
   not exercised in commit form — the session never needed a mid-box
   push, and the atomic single-green-push form delivers the SAME
   guarantee at the push boundary (stronger: no intermediate tree
   was ever pushed); recorded as the form note, not a violation. The
   four N5 mitigations carried: wasm-first (local, verified), the
   honest round record (the SESSION_LOG entry rides at the close —
   Rider 8 — and must cite the CORRECTED run number), the
   red-close-absorption rule (not triggered — no red), backup after
   each stage (`f295a27` the execution, `8387202` the entry record —
   both same-session, no silent extension).

8. **The bookkeeping set — the landed half DISCHARGED, the close
   half ruled in the Riders.** LANDED (verified): the checker's
   FUNDED counter expects **0** (the legitimate-advance update, "N1–
   N6 all entered") and the N-outcome count **10** — both verified by
   my `harness_check.sh` run at the tip: **0 failures**. ROADMAP's
   N6 bullet carries the ENTERED record + the execution record (the
   run number needs Rider 1's correction). CONSENSUS's N6 entry
   record: the verdict table, the ten headline rulings, the
   reconciliations (a)–(f) — every one verified against the landed
   code above. NOT YET LANDED (ruled here): the README
   honest-surface update (Rider 4 — the exact row texts), the
   program freeze declaration + the final memory sync (Riders 2/6/7),
   the checker's close advance (Rider 6 — N-outcomes 10 → 11 at the
   close), the DEBT row (Rider 5), the SESSION_LOG entries (Rider 8),
   and `harness_check` 0 failures on the CLOSE push (the close
   push's own proof, per the N5 form).

## Conditions (numbered close riders — the exact texts the close lands)

1. **THE RUN-NUMBER DATED CORRECTION (the records-honesty rider —
   mandatory).** ROADMAP.md:788's "run **45991816001** on f295a27,
   all EIGHT jobs" is the adjacent Dependabot run's ID; the hygiene
   run is **45991786766**. The close lands the dated correction in
   ROADMAP's N6 execution record, in the same correction form as the
   N5 exit's undercount fix — suggested text (the parenthetical
   inserted at the run citation): "**run 45991786766** on f295a27,
   all EIGHT jobs (dated correction at the N6 exit: the entry record
   transcribed the adjacent Dependabot run's ID 45991816001 — the
   same SHA, created 12 seconds later, one job; the hygiene run is
   the push run 45991786766, verified live at the exit gate)". The
   CONSENSUS exit record and the SESSION_LOG N6 entry cite
   **45991786766** from the start. The `8387202` commit message's
   copy is immutable history — the correction rides in the records,
   never a history rewrite. *Checkable:* `rg -n "45991816001"
   harness/ README.md` → after the close, only the dated-correction
   contexts (ROADMAP's correction parenthetical + CONSENSUS's exit
   record if it names the corrected-from ID); `rg -n "45991786766"`
   finds ROADMAP + CONSENSUS + SESSION_LOG.

2. **THE TERMINAL FREEZE DECLARATION — land VERBATIM (no drafting at
   fatigue), in the FIVE homes** (ROADMAP's epilogue frame at the N6
   bullet's close / README's maintenance-policy section extended /
   STATE's close-out / CONSENSUS's N6 exit record / SESSION_LOG's
   close entry). THE EXACT RULED TEXT (my entry Condition 4, to be
   transcribed byte-for-byte; each home may adjust ONLY the
   surrounding context, never the declaration's own words):

   > **The epilogue's terminal freeze (declared at N6 — the ADR-017
   > program's close).** The native re-platforming epilogue (N1–N6) is
   > COMPLETE: the Rust core (N1), the Linux (N2), Android (N3), Windows
   > (N4) and macOS (N5) native lanes, and the web via WASM (N6) each
   > entered, executed, and closed behind their own gate with an honest
   > record; the shared Rust core now serves every platform — the four
   > native demo lanes and the web through the same flat C ABI compiled
   > to wasm32-unknown-unknown. Every native app is a demonstration
   > prototype, unreleased, CI-verified-only; the Flutter app remains the
   > shipped product on every OS until that OS's native stack reaches
   > GA, and the Dart engine remains the frozen reference. The TypeScript
   > engine and the TypeScript codecs are RETIRED frozen transition
   > artifacts per ADR-016/ADR-017 — kept in-tree as the transition
   > record; their cleanup after v2.0.0 GA is a future owner decision;
   > nothing deletes or rewrites them.
   >
   > **v2.0.0 stays GA-gated (ADR-017's rule, unchanged):** v2.0.0 is
   > earned ONLY at the first GA release whose distributed artifact for
   > any OS is the native stack — a user-visible platform-lineage change
   > the owner explicitly releases. Nothing at the N6 close moves any
   > version plane: the app semver stays v1.x, the `.clearfile.json`
   > envelope schema stays 2, and every crate and package plane stays
   > its own.
   >
   > **Post-epilogue maintenance posture (the v1.x policy's form,
   > extended):** accepted changes are (1) tax-parameter corrections
   > backed by a cited IRS source, flowing through the shared golden
   > fixtures + the independent Decimal oracle to every live engine —
   > the Dart reference and the Rust core, with the web receiving them
   > through the wasm build; (2) bug and security fixes with regression
   > tests; (3) format-guard compliance — a future `.clearfile.json`
   > envelope version bump lands in the core's envelope codec, pinned by
   > the shared migration fixtures; (4) dependency security bumps under
   > the existing gates. Out of scope without a new owner directive:
   > new engine features, new platforms, new UI features, the TT
   > compatibility program beyond its own gated lanes (T3/T4 unfunded),
   > and any work on the frozen transition artifacts beyond keeping
   > them compiling.
   >
   > **The standing owner items, parked explicitly at the terminal gate —
   > never a silent drop:** the Stage-2 exit gate stays SLIPPED; the
   > MSI-record keystream chase stands as recorded debt D42 (disposition
   > "T3 session 2"); D30 (the owner-side hardening items) stands.
   > These leave the funded scope with this declaration and remain
   > owner decisions.

   *Checkable:* the declaration's six elements present in each home's
   substance; `rg -n "terminal freeze" harness/memory/ROADMAP.md
   README.md harness/memory/STATE.md harness/memory/SESSION_LOG.md
   harness/adversarial/CONSENSUS.md` finds the landing (or its
   section pointer) in all five.

3. **THE TWELFTH SLIP SURFACING + THE TERMINAL-GATE PARKING POSTURE —
   repeated VERBATIM in the close record** (CONSENSUS's N6 exit
   record; the freeze declaration's homes carry the parked-items
   paragraph in substance). THE EXACT TEXT (the entry record's
   wording, restated so the close carries it exactly — the
   enumeration, the three options, the no-ruling count, the parking
   posture):

   > The Stage-2 slip re-agenda — the TWELFTH surfacing (the TERMINAL
   > gate's mandatory item): the enumeration — 1 the N1-exit, 2 the
   > N2-entry, 3 the N2-exit convening, 4 the N2-exit close, 5 the
   > 2026-11-27 restatement, 6 the N3 entry, 7 the N3 exit, 8 the N4
   > entry, 9 the N4 exit, 10 the N5 entry, 11 the N5 exit, 12 THIS
   > gate. The three owner options: (a) **fund a T3 session** (the
   > MSI-record keystream decompile chase at payload offset 0x24000 +
   > tax-modern.md, debt D42), (b) **supersede the RE-protocol
   > namespace rule**, (c) **the default re-agenda**. No ruling
   > received across ELEVEN prior surfacings; (c) continues. **THE
   > TERMINAL-GATE PARKING POSTURE:** this is the epilogue's LAST
   > gate — the slip cannot ride past it unexamined: if still unruled
   > at the close, the record states explicitly — the Stage-2 exit
   > stays SLIPPED; the MSI-record keystream chase stands as recorded
   > debt D42 (disposition "T3 session 2"); D30 (the owner-side
   > hardening items) stands; these leave the funded scope with the
   > terminal freeze and remain owner decisions — never a silent
   > drop.

   *Checkable:* the close record carries the enumeration 1–12 + all
   three options + the ELEVEN no-ruling count + the parking-posture
   sentence; DEBT.md's D42 (disposition "T3 session 2") + D30 rows
   stand unchanged.

4. **THE README HONEST-SURFACE UPDATE — the exact web-row texts
   (records honesty: every README claim about the web engine true at
   the close tip).** The measured stale spots at the tip (my probes)
   and their ruled replacements:
   (a) **The `src/` row (line 18)** — replace the "same TY2025
   calculation engine as the Flutter app (ADR-009 parity, 2026-11-15:
   line-for-line port validated against the shared golden fixtures)"
   clause with: "the **shared Rust core serving the web through WASM**
   (N6, ADR-017's terminal lane: the same flat C ABI the native lanes
   consume, compiled to wasm32-unknown-unknown, loaded by a
   zero-dependency adapter `src/lib/wasm/core.ts` — the TS engine and
   TS codecs are retired frozen transition artifacts per
   ADR-016/017), deterministic review findings, and an optional
   bring-your-own-key AI assistant. CI-verified in node through the
   real `.wasm` module (no real-browser e2e); the app boots a loading
   gate until the core module loads."
   (b) **The `clearfile/` row (line 19)** — replace "The two
   codebases share no code; the web engine is a line-for-line
   TypeScript port of this one (Stage-3 parity)." with: "The two
   codebases share no code; the web prototype's engine IS the Rust
   core through the wasm build (the retired TypeScript port survives
   in-tree as a frozen transition artifact)."
   (c) **The `clearfile/test/` row (line 20)** — "shared with the web
   engine's parity tests" → "shared with the wasm parity suite".
   (d) **The `fixtures/tax/` row (line 21)** — "three runners are held
   to: `clearfile/test/golden_fixtures_test.dart` (Dart) and
   `scripts/web_parity_test.mjs` (TypeScript) and `core/` (Rust)" →
   "three live runners are held to:
   `clearfile/test/golden_fixtures_test.dart` (Dart), `core/` (Rust),
   and `scripts/wasm_parity_test.mjs` (the wasm core adapter — the
   transferred web-parity contract; the TS runner retired with its
   subject)".
   (e) **The "Calculation engines" section (lines 65–70)** — replace
   the "two independent implementations … the web engine is a
   line-for-line port" framing with: "**two live engines** — the Dart
   reference (`clearfile/lib/tax/calculator.dart`) and the shared
   Rust core (`core/`), which also serves the web through its
   wasm32 build (the TypeScript port is RETIRED, a frozen transition
   artifact per ADR-016/ADR-017 — kept in-tree at
   `src/lib/tax/engine.ts` + `src/lib/files/` as the transition
   record)". The "### Web engine" subsection re-heads as the
   wasm-served story (the adapter over the same flat C ABI; the
   17-fixture wasm parity suite; the retired engine.ts's frozen
   banner quoted or pointed to). Add the one-line
   transition-record pointer (my entry Advisory 4): where the frozen
   artifacts live + which ADRs retired them.
   (f) **The `core-ffi/` row (line 26)** — extend the export
   enumeration: "…the palette role lookup, last-error, free" → "…the
   palette role lookup, last-error, free — plus the four N6 wasm-lane
   exports (the length-paired `clearfile_alloc`/`clearfile_dealloc`,
   the length-out binary container export, `clearfile_params_json`)
   serving the web through the wasm32-unknown-unknown build (the
   committed header carries all of them; the loader is
   dependency-free)". (The old "a dozen extern C functions" count is
   stale — 14 now.)
   (g) **The "Running the web prototype" block (lines 253–264)** —
   replace the retired `node scripts/web_parity_test.mjs` line with
   the wasm lane's honest how-to: build the module first
   (`scripts/fetch_rust_toolchain.sh` then `cargo build --release
   --target wasm32-unknown-unknown --manifest-path
   core-ffi/Cargo.toml`), copy it for the browser
   (`cp core-ffi/target/wasm32-unknown-unknown/release/clearfile_core_ffi.wasm
   public/clearfile-core.wasm`), then `node
   scripts/wasm_parity_test.mjs` (17/17 against the real module) and
   `node scripts/txf_taxfile_test.mjs` (the transferred bridge suite,
   11/11); the AI lines unchanged. State the boot-gate behavior
   (no .wasm → the app shows the honest load error, never a
   compute-less UI).
   (h) **The maintenance policy (lines 270–290)** — the sentence
   "The web prototype stays in maintenance parity (ADR-016) until the
   Rust core serves the web (WASM) and the TS engine retires" has
   FIRED: the section extends with Rider 2's declaration (the
   README home of the freeze text), and the fired sentence is
   replaced by its completion ("the Rust core served the web at N6
   and the TS engine retired — the terminal freeze declaration
   below").
   The bridge section's "verified by `scripts/txf_taxfile_test.mjs`
   in CI" citation stays true (the same script, now wasm-backed —
   the section may add "(served through the wasm adapter since N6)");
   the "Export TXF (both codebases)" phrase stays true with the web
   side served through the core. *Checkable:* `rg -n
   "web_parity_test|line-for-line" README.md` → after the close, no
   stale live-engine claims (the retirement notices excepted); the
   126-test table row's counts untouched.

5. **THE STALE-BY-DESIGN DEBT ROW + THE RE-RULES IN THE EXIT
   RECORD.** (a) DEBT.md gains the append-only row (the next free
   number, **D45**) — suggested text: "| D45 | N6 exit gate (2026-11-27)
   | release.yml is byte-frozen through the N6 close (md5-identical to
   47f33a4, the v1.1 ship); its nextjs-web job (`npm ci → tsc → next
   build`, the `clearfile-web-standalone` tarball) is
   STALE-BY-DESIGN against the converted `src/` — the job has no
   wasm build step, so a post-N6 tag push would RED the job
   fail-loud rather than ship a silently-broken asset. The v1.1
   tarball is the LAST TS-engine web distribution; the first
   wasm-served web distribution is v2.0.0-GA territory (ADR-017's
   rule). ANY tag push before the release.yml rework is an owner
   decision that must FIRST resolve the web-asset question. | the
   v2.0.0-GA release.yml rework (the wasm build step for the web
   tarball + the native GA lanes + the per-platform LICENSES
   manifests) |". (b) The CONSENSUS exit record carries the re-rules:
   release.yml byte-frozen (the verified md5 fact), pages.yml
   untouched with the live-Pages-unaffected-by-construction sentence
   (the demo is the FLUTTER web build; the N6 delta is `src/`-scoped),
   and the no-tag-before-rework constraint. The freeze declaration's
   homes carry the parked posture in substance (Rider 2's text).
   *Checkable:* `rg -n "stale-by-design|STALE-BY-DESIGN"
   harness/memory/DEBT.md harness/adversarial/CONSENSUS.md` finds
   both.

6. **THE CHECKER ADVANCE + THE CLOSE-PUSH PROOF.** The CONSENSUS
   close adds "**N6: CLOSED (exit PASSED)**" → the harness_check
   N-outcome family advances **10 → 11** (the pass message: "N1–N6's
   ENTERED+CLOSED outcomes — all six closed"); FUNDED stays **0**;
   ROADMAP's N6 gate-status line rewrites ENTERED → **CLOSED
   (exit PASSED)** with the execution record carrying Rider 1's
   corrected run number; the close push itself runs
   `harness_check.sh` → **0 failures** (the close's own proof, the
   N5 form). *Checkable:* the checker's expected count reads 11; the
   close push's backup message records "0 failures".

7. **THE STATE CLOSE-OUT.** STATE.md: (a) the **header's "Updated"
   line rewrites to the terminal state** (a measured staleness: the
   header still narrates the N4 close — one close stale since the
   N5 exit synced only the "Immediately next" section; the program's
   terminal close is the place the header catches up): "2026-11-27
   LATEST (N6 CLOSED — exit PASSED; the epilogue COMPLETE: the Rust
   core serves every platform, the four native demo lanes + the web
   via WASM; the TS engine + codecs retired frozen artifacts; the
   program freeze declared …)" with the honest one-liner datums (run
   45991786766 first-green all eight jobs; the .wasm 318,715 bytes,
   zero imports); (b) the epilogue N6 bullet (ENTERED + the
   execution record + CLOSED); (c) "Immediately next" → the epilogue
   program's close-out state: the program freeze declaration landed
   + the final memory sync + the standing owner items (D30 + D42 +
   the Stage-2 slip) parked, per the declaration's own text.
   *Checkable:* `rg -n "N6" harness/memory/STATE.md` shows the CLOSED
   status + the freeze pointer; no "Immediately next" item remains
   that reads as unexecuted funded scope.

8. **THE SESSION_LOG N6 ENTRIES.** SESSION_LOG's tail still ends at
   the N5 flake record (measured — the N6 session has NO entry yet):
   the close lands the N6 entry: ONE session, the box's own record —
   the wasm-first LOCAL verification (the .wasm built with the
   pinned toolchain's wasm32-std component, 318,715 bytes, ZERO
   imports; the parity 17/17 + the bridge 11/11 + the AI 5/5+4/4 +
   the battery 12/12 with the panic-hook variant + tsc clean, all
   green locally BEFORE the push), the atomic landing (`f295a27`:
   the four exports + the adapter + the Shape-A retirement + the
   suite transfers + the CI wasm lane), **round 1 = first-green, run
   45991786766 on f295a27, all EIGHT jobs** (the honest CI-fix datum
   **N6=1 round**; the dated run-number correction noted per Rider
   1), the entry-record backup (`8387202`), the exit gate (this
   gate's verdict table + riders), and the known-skip note: the trap
   assertion runs in CI (the panic-hook variant is built first) and
   SKIPS in plain local runs that did not build the variant — a
   recorded skip, never a silent one. *Checkable:* the SESSION_LOG
   entry cites 45991786766 + the N6=1-round datum + the .wasm size.

9. **THE PRE-POSITIONED v2.0.0-GA READINESS LIST (the N3-gate
   precedent, so it cannot be lost at the close).** The close record
   (CONSENSUS's exit record or STATE's close-out) pre-positions the
   GA session's agenda: (a) the per-OS owner-side build obligations
   (macOS's recorded GA debt — an owner-side build or the recorded
   acceptance); (b) the release.yml rework = DEBT D45's disposition
   (the wasm build step for the web tarball + the native GA lanes +
   the per-platform LICENSES manifests at each first tagged release
   per the ADR-017 licensing annex); (c) the Flutter-target
   retirement sequencing ("each GA retires that one Flutter target",
   ADR-017); (d) the LICENSES-manifest trigger lit at the NEXT tag
   (the palette + the statically-linked Rust std — the /MT precedent
   — + the carried shadcn set; the gate's ruling 7). *Checkable:*
   the close record names all four.

## Risks register (the close's own)

- **The terminal record's permanence:** the freeze declaration is the
  program's closing document; Riders 2/3's verbatim discipline is the
  mitigation (transcription, never drafting — the texts above are
  byte-exact from the gate's rulings).
- **The wrong-run-ID class at the terminal gate:** the correction
  (Rider 1) is the third instance of the adjacent-record
  transcription class (N4's enumeration count, N5's undercount, N6's
  run ID) — the class is now NAMED in the record so future sessions
  check citations against the run page, not the runs list.
- **The half-served-web residue:** none found — the boot gate + the
  atomic flip + tsc's fail-closed consumer map hold; the store.ts
  type-import note (Condition 1 observation i) is the only retired-
  module reference left, and it is type-only + within the ruled split.
- **The frozen-artifact rot:** the banner's own byte-frozen claim is
  CI-enforced (the app tsconfig still compiles the frozen files; the
  suites' tsconfigs compile the adapter + config only — a deliberate
  narrowing, recorded in the tsconfig diffs' own comments); a future
  tsc-config change that silently dropped the frozen files would rot
  them — the freeze declaration's "keeping them compiling" clause is
  the standing guard.

## Advisories (non-binding)

1. The adapter's model-types block may cite `docs/return-format.md`
   (the envelope's `filing` payload spec) in its header — the
   persistence-contract pointer my entry Advisory 2 asked for; the
   payload-shape comments already carry the substance.
2. The exit record may name the wasm lane's own non-verifications
   once, in one place: CI-verified in node through the real module +
   no real-browser e2e (the boot gate authored, not browser-proven);
   the README web row (Rider 4a) already carries it.
3. The `.wasm` provenance datum for the study record: built by the
   pinned toolchain (rustc 1.100.0) from `f295a27`'s tree, sha256
   `6800f11a-39c9fd22-ce6fe5c7-216e9ff1-5d33e7fb (hyphen-grouped by an orchestrator form-note — the backup's raw-hex guard; the value is unchanged)…` (first 40 hex; the
   full digest re-derivable at any rebuild) — the reproducibility
   line my entry Advisory 1 asked for.

## Files read + verification log

**Read:** my entry report (the 8-condition ruling set);
CONSENSUS.md's N6 entry record (:2211–2318 — the rulings, the
reconciliations (a)–(f), the TWELFTH surfacing + the parking
posture) + the N5 exit record (:2090–2210, the correction-class
precedent); ROADMAP.md's N6 bullet (:778–801 — the ENTERED + the
execution record with the wrong run ID at :788); STATE.md whole
header + epilogue + "Immediately next" (:3, :175–200, :363–394);
SESSION_LOG tail (the N5 close — the N6 entry's absence measured);
DEBT.md (D30 :38, D42 :47 standing; no nextjs-web note — Rider 5's
basis); README.md rows 14–38 + engines/bridges/run/maintenance
(:65–134, :182–290 — the stale-claim map for Rider 4); the four
retired TS modules' banners + export surfaces; `src/lib/wasm/
core.ts` whole (the adapter: the rulings' implementations +
reconciliations (b)/(c)/(f) verified in-code); `src/lib/tax/
config.ts` whole (the table removed, the labels alive);
`src/app/page.tsx` (the boot gate); the five consumers' diffs;
`core-ffi/src/lib.rs`'s four new exports + `core-ffi/clearfile.h`'s
four new declarations; `core/src/params.rs` (the table's core
source); `core-ffi/tests/boundary.rs`'s +2 tests; `scripts/
wasm_parity_test.mjs` whole; the `txf_taxfile_test.mjs` +
tsconfig diffs (reconciliations (d)/(e)); hygiene.yml's wasm-lane
diff; `scripts/fetch_rust_toolchain.sh` + `rust_toolchain_manifest`
(row 2); `.gitignore`'s wasm-lane line; `package.json` (the unchanged
dep set + scripts); pages.yml's trigger block; the N5-exit product
report (the format template).

**Ran (my own measurements — every discharge claim above):**

1. `git status --short` → EMPTY; `git tag` → v1.0.0/v1.0.1/v1.1;
   `df -h /` → 4.9 GB available (the re-measure discipline held).
2. `git diff --stat 1dd84dc..HEAD` → 32 paths (+3,734/−200); the
   workflows delta = hygiene.yml ONLY; `git diff 1dd84dc..HEAD --
   package.json package-lock.json` → EMPTY (byte-unchanged — the
   zero-npm-dep loader's manifest proof); `git diff 47f33a4..HEAD --
   release.yml pages.yml` → EMPTY + release.yml md5 `e2e879d5…` =
   47f33a4's (BYTE-FROZEN).
3. `rg "from '@/lib/(tax|files)" src` + the relative-path probe →
   the flip's import graph: labels/formatters/types only + the
   adapter; zero live compute/parameter/codec imports.
4. **The live green re-proof:** node load of
   `clearfile_core_ffi.wasm` → **imports: 0**, 14 `clearfile_*`
   exports (the four new present); `node scripts/
   wasm_parity_test.mjs` → **17 fixtures, 0 field failures** (+
   allocator + params-table proofs ok; the trap assertion's local
   skip — the variant not built locally — recorded); `node scripts/
   txf_taxfile_test.mjs` → **11/11 groups**; `node scripts/
   ai_cascade_fixture_test.mjs` → **5/5**; `node scripts/
   ai_injection_test.mjs` → **4/4**; `npx tsc --noEmit` → exit 0;
   `cargo test --manifest-path core-ffi/Cargo.toml` → 11 passed
   (plain) + `--features panic-hook-test` → **12 passed**;
   `bash scripts/harness_check.sh` → **0 failures** (FUNDED 0,
   N-outcomes 10).
5. **THE RUN-NUMBER PROBE (the headline finding):** the GitHub API
   via the repo token — run `45991816001` → workflow
   `dynamic/dependabot/dependabot-updates`, event `dynamic`,
   created 11:36:06Z, **ONE job**; run `45991786766` →
   `.github/workflows/hygiene.yml`, event `push`, head `f295a27`,
   created 11:35:54Z, completed/**success**, **all EIGHT jobs
   success** (each job's conclusion fetched). The recorded
   first-green/all-eight-jobs claim is TRUE of **45991786766**.
6. `stat` the `.wasm` → **318,715 bytes**; `ls fixtures/tax/*.json
   | wc -l` → **17**; the AI suite scripts + fixtures/ +
   verify_golden_fixtures.py → byte-unchanged in the delta.
7. `rg` the five homes for the freeze declaration → pointer mentions
   only (NOT YET LANDED, as ruled); `rg` DEBT.md → D42/D30 standing,
   no stale-by-design note (Rider 5's basis); `rg
   "45991816001|45991786766"` → the wrong ID at ROADMAP.md:788 +
   the `8387202` message only (the correction is one record-site,
   bounded).

Working tree at filing (this lane's ONLY authored file is this
report; the parallel-isolation discipline the N4/N5/N6 entry filings
recorded):

```
$ git status --short
?? harness/adversarial/reports/2026-11-27-n6exit-product.md
```

The N6-entry probe's stray-tarball anomaly (rust-std-wasm32.tar.xz)
is DISCHARGED at the tip: the file is absent from the tree (the
gate's ruling 10 — the parallel-lane probe artifact, absent from the
tree at the close; my `git status` above is the proof). No other
anomalies observed this lane.
