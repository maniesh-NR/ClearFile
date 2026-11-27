# ADV-LEGAL — the N6 EXIT gate, the epilogue's terminal gate's close (2026-11-27, Task N6-EXIT-LEGAL)

The N6 execution record (the ONE-session box closed FIRST-GREEN: hygiene
run **45991816001** on f295a27, all EIGHT jobs, one round; the wasm
parity 17/17 + the bridge 11/11 + the AI suites 5/5 + 4/4 proven
locally first; the delta `git diff 1dd84dc..HEAD`) is audited against
my nine entry conditions
(`harness/adversarial/reports/2026-11-27-n6-legal.md`), the CONSENSUS
N6 entry record's rulings + the orchestrator reconciliations (a)–(f)
(CONSENSUS l.2211–2318), ADR-016/ADR-017 (incl. the licensing annex
l.537–555), and my standing register (the N1–N5 entry/exit reports).

This is the epilogue's LAST gate-event. Every condition below is
verified with a live probe at tip 8387202 (records-only over f295a27 —
verified: `git diff f295a27..HEAD` touches only CONSENSUS/ROADMAP/
harness_check, so the f295a27 CI-green covers HEAD). The verdict turns
on three acceptances (the banner form, the four-export set, the
release.yml re-rule) and five close riders with EXACT texts — the
first-conveyance LICENSES-manifest trigger, the STALE-BY-DESIGN
correction (one live finding: PROD's entry "fail-LOUD" claim is
disproven by a local build probe), the README honest-surface rewrite,
the terminal freeze declaration's final form, and the CONSENSUS exit
record's content. Nothing blocks the exit; nothing ships at N6; no
tag exists (verified: exactly v1.0.0/v1.0.1/v1.1).

**VERDICT: PROCEED-WITH-CONDITIONS — the exit is granted; 5 close
riders (discharged at the epilogue close, with the exact texts below).**

## The nine entry conditions — verification ledger

1. **The banner: LANDED, form ACCEPTED with two recorded
   letter-deviations (the freeze forecloses any "fix").** All four
   retired files carry the dated terminal banner as their ONLY delta
   edit (comment-only, +9 lines each; zero token/type/behavior
   delta), placed under the preserved SPDX header:
   `src/lib/tax/engine.ts`, `src/lib/files/{txf,taxfile,cfr}.ts`
   (verified: `git diff 1dd84dc..HEAD -- <the four files>` shows
   exactly the banner hunk per file). `config.ts`'s table removal
   carries its OWN note (a separate 7-line comment: "The parameter
   TABLE retired at N6 (2026-11-27, ADR-016's conversion day)… the
   labels, formatters, and display constants below live on") — correct
   form: config.ts stays LIVE (display surface), so it takes no
   RETIRED banner. Every required element of my ruled text is present
   in the landed banner (the date 2026-11-27; ADR-016 + ADR-017; the
   FROZEN TRANSITION ARTIFACT status; "out of the app's runtime import
   graph"; "kept in-tree as a study artifact"; "still tsc-checked";
   the BYTE-FREEZE clause "no further changes of any class land here,
   bug and security fixes included"; the successor
   `src/lib/wasm/`). TWO letter-level deviations from my ruled wording,
   both ACCEPTED and both RECORDED here (never to be "corrected" in
   the files — the banner's own byte-freeze makes any later edit,
   including a wording polish, a violation): (a) the trailing pointer
   sentence ("See harness/memory/DECISIONS.md ADR-016/ADR-017.") is
   absent — the two ADR numbers are named in-line instead, which
   carries the same provenance; (b) the three codec files say "this
   engine" where my ruled form substituted "module" for the codec
   files — the family reading ("the TS engine code family" per
   ADR-016) keeps it honest, and the first line's "RETIRED" heading
   plus the successor pointer prevent any misreading that txf.ts is
   the compute engine. The files stay at their paths, keep their SPDX
   headers, are never excluded from the root tsconfig (verified: the
   root tsconfig's include stays `**/*.ts` with exclude =
   node_modules/examples/skills), and `npx tsc --noEmit` at tip is
   **exit 0** (run live) — "still tsc-checked" is the root-tsconfig
   check, live-proven. The byte-freeze takes effect FROM the landed
   edit: any later diff over any of the four files is a violation
   re-opening this lane (unchanged tripwire).

2. **Shape A: SERVED, verified through the shipped bundle.** The live
   consumer map is switched: `page.tsx` (the boot gate:
   `initWasm()`/`wasmReady()` + the core-module error surface),
   `steps.tsx`, `filemenu.tsx`, `ai-ui.tsx`, `ai/tasks.ts` all import
   the adapter `@/lib/wasm/core` — the ONLY remaining references to
   the retired modules in live code are `import type` edges
   (`store.ts:6` and the retired files among themselves), erased at
   emit, which my condition 2 expressly ruled acceptable
   (compile-time-erased `import type` re-pointing). The strongest
   check I set — the shipped bundle: `npm run build` ran LIVE at tip
   (green), and a grep of the standalone output for retired-file-unique
   symbols (`saltCapFor|shannonEntropy|makeZip|readZip|CFR_FORMAT`)
   returns **zero files**, while the adapter's own marker
   ("The core module is not loaded yet.") IS in
   `.next/static/chunks/1xtkj3wqaotof.js` — **zero bytes of the
   retired modules ship; the parameter table is gone from TS**
   (config.ts's TY2025 object removed; the table's one true source is
   the core's `clearfile_params_json`, mirrored through
   `core/src/params.rs`'s serialization whose keys mirror the TS
   interface exactly, the infinite terminal rung as `null` —
   reconciliation (c), verified in code).

3. **The suite transfer: LANDED and re-proven locally.** The two
   suite tsconfigs (`scripts/tsconfig.parity.json`,
   `tsconfig.files.json`) are re-pointed: files = `config.ts` +
   `src/lib/wasm/core.ts`, rootDir `../src/lib` (the retired files
   LEAVE the suite builds); `tsconfig.ai.json` likewise. The parity
   CONTRACT transferred byte-for-byte (the same DEFAULT_INPUT merge +
   the same tolerance semantics + the same 17 shared fixtures) to
   `scripts/wasm_parity_test.mjs` — **run live: 17/17 fixtures, 0
   field failures**, plus the allocator ruling (100 interior-NUL
   cycles, module still ready) and the core-served parameter table
   check green (the trap assertion correctly skips locally — no
   panic-hook module; CI builds it). The bridge suite
   (`scripts/txf_taxfile_test.mjs`) carries the TRANSFERRED banner +
   its own STORE-ZIP fixture builder (reconciliation (d)) + the
   divergence-5 warning-free flat lift recorded (reconciliation (e))
   — **run live: 11/11 groups**. The AI suites run over the
   adapter-backed helpers — **5/5 + 4/4 live** (risk (f) discharged:
   the D12 disclosure copy stays true; `settings.tsx`, `shell.tsx`,
   `ladder.ts` diff-empty — the demo-disclaimer + "No telemetry
   exists" + the provider-disclosure copy byte-stable, verified
   diff-empty). The Dart suite + the core suites: diff-empty over the
   whole delta (no `clearfile/` or `core/tests/` file touched). The
   retired suite `web_parity_test.mjs` stays as the frozen transition
   record under its own RETIRED banner — same-class form, lawful. My
   condition 3's "the retired files' DISPOSITION in those configs
   recorded" is met in substance, not letter: the tsconfigs are
   comment-free JSON, and the disposition ("they leave the suite
   builds; the root tsconfig still checks them") is recorded where
   those configs are consumed — the three suite-script banners + the
   ROADMAP execution record ("byte-frozen transition artifacts, out
   of the import graph, still tsc-checked") + ENG's report l.378.
   Noted, not ridden.

4. **The .wasm conveyance posture: the never-tracked + --locked
   halves VERIFIED; the manifest trigger is a close rider (Rider 1).**
   `git ls-files | rg -i '\.(wasm|tar\.xz)$'` → empty (run live); the
   tracked-binary tally is exactly png 25 / pdf 3 / ico 1 (re-counted
   live); the working tree is CLEAN (the stray 23 MB
   `rust-std-wasm32.tar.xz` is GONE — discharged as the CONSENSUS
   entry record item (10) records); `.gitignore` gains
   `/public/clearfile-core.wasm` (and `core-ffi/target/` was already
   ignored — both verified with `git check-ignore -v`). The suites job
   builds the wasm32 target `cargo build --locked --release --target
   wasm32-unknown-unknown` (hygiene.yml diff verified) — the --locked
   discipline holds in the verification lane. The module itself,
   probed live: **ZERO imports** (the strongest no-network proof;
   15 exports = the 11 prior + the 4 new; 318,715 bytes ≈ the
   ~300 KB record). The release-lane half of my condition (the
   shipped .wasm built from the release run's tagged checkout
   --locked) is DEFERRED with the release.yml re-rule (condition 9
   below): nothing ships at N6, so the first conveyance is the next
   tag — where the manifest duty (Rider 1) and the web-asset rework
   (Rider 2) land together as ONE owner decision. ADR-017 l.545's
   first-conveyance trigger is therefore LIT and must be recorded at
   the close (Rider 1) so it cannot be missed at a "too small to owe
   anything" v1.x patch.

5. **The loader's clean-room discipline: ALL FOUR halves verified.**
   (a) `git diff 1dd84dc..HEAD -- package.json package-lock.json` →
   **empty** (byte-unchanged) — zero new npm dependencies
   (fetch/WebAssembly/TextEncoder only, verified in the source);
   (b) SPDX headers on the new tracked files: `src/lib/wasm/core.ts`
   line 1 + `scripts/wasm_parity_test.mjs` line 2 (GPL-3.0-only own
   code; `core/src/params.rs` likewise carries its SPDX header);
   (c) the negative-provenance doc-comment is present and names the
   clean-room ruling (core.ts l.11–15: "written from the committed
   header's own contract alone — no wasm-bindgen, no Emscripten, no
   tutorial code; the alloc/pointer/NUL-terminated-read pattern is
   the unprotectable functional method of that ABI");
   (d) the same-origin fetch pin: `initWasm(url =
   '/clearfile-core.wasm')` — a literal relative asset path, no URL
   constructor, no remote origin, with the standing comment "any
   cross-origin/CDN change re-opens the privacy copy — LEGAL-5"
   (verified in source). §102(b)/merger/scènes à faire/*Altai*
   posture unchanged; DMCA §1201 posture unchanged (the .wasm ships
   the same read-only inspection; no key module in `core/src/`).

6. **The export set: the reconciled FOUR-export set ACCEPTED over my
   one-declaration ruling (CONSENSUS reconciliation (a)).** The
   reconciliation is sound on my own condition's substance: the
   header diff is PURELY ADDITIVE (+51 lines: `clearfile_alloc`,
   `clearfile_dealloc`, `clearfile_export_tax_container`,
   `clearfile_params_json` — no existing declaration touched, no
   signature or semantic altered); every export beyond my ruled one
   was itself RULED by the gate's own headline rulings ((2) the
   length-paired alloc/dealloc — the probe-verified interior-NUL trap
   class makes a strlen-free dealloc REQUIRE the length on the ABI;
   (3) the length-out binary channel — binary may never ride the
   NUL-terminated CString returns; and the orchestrator's addition
   (b) `clearfile_params_json` — the ONE way Shape A's "zero TS-side
   parameter logic" can be served); the exports are PLAIN (un-gated)
   on every target (verified in lib.rs: no target_arch gating on the
   four; only the pre-existing android-gated JNI shim), so the flat C
   ABI remains the ONE audit surface; the freshness check is green —
   re-proven LIVE here: after `cargo test --manifest-path
   core-ffi/Cargo.toml` (build.rs regenerates the header) the working
   tree is clean → the committed `clearfile.h` is byte-identical to
   the regeneration; the battery is 12/12 with
   `--features panic-hook-test` (run live; plain run = 11 — the
   panic-injection test is feature-gated, correctly so); the wasm
   build's Cargo.lock files are byte-unchanged (no lock in the delta),
   `deny.toml` unchanged, the zero-dep assertion holds
   (harness_check: "the core lock stays exactly 1 package" — 0
   failures overall, run live); the N4/N5 consumers are untouched (no
   `apps/` file in the delta) and re-proven green in run 45991816001
   (records). My "exactly one declaration" was a proposal-scoped
   count; the gate's own rulings made the honest set four. ACCEPTED.

7. **The README web rows: correctly NOT yet landed — the close rider
   rules the exact texts (Rider 3).** My entry report ruled this as an
   at-the-switch rewrite and the switch has happened in `src/`; the
   README still carries the now-false claims (the `src/` row's "same
   TY2025 calculation engine as the Flutter app… line-for-line port";
   the `clearfile/` row's "the web engine is a line-for-line
   TypeScript port of this one"; the `fixtures/tax/` row's
   `web_parity_test.mjs` runner; the "Web engine —
   `src/lib/tax/engine.ts` (TY2025, at parity)" section; the "two
   independent implementations" intro's "the web engine is a
   line-for-line port"; the running commands' `web_parity_test.mjs`
   line; the maintenance-policy sentence whose condition has FIRED).
   All are Rider 3's exact texts. The untouched-set duty is already
   verified: the AI section, the demo-disclaimer copy
   (steps.tsx/shell.tsx), the v1.0.0/v1.0.1 network note, and the
   release-body network disclosure (release.yml byte-unchanged) are
   all diff-empty and stay true (the wasm fetch is a same-origin asset
   load — the "only outbound data path" claim holds).

8. **The terminal freeze declaration: PROD's exact text ACCEPTED as
   the declaration, landing verbatim at the close with TWO ruled
   appends + the v2.0.0 row re-anchoring (Rider 4).** PROD-4's text
   (the N6 product report l.201–245) is the declaration; I verified
   it against my condition 8's six elements: (i) program freeze —
   covered (heading "terminal freeze" + "COMPLETE" + the out-of-scope
   list; the date rides the landing — ruled in Rider 4); (ii) ship
   state — the native stacks + the Flutter-app clause covered, but
   MY web clause ("web included — the live Pages demo stays the
   Flutter build; the Next.js prototype is a repo prototype + a
   release tar.gz artifact, never deployed") is NOT in PROD's text —
   Rider 4 rules the appended sentence; (iii) v2.0.0 GA-gated —
   covered by PROD's text; my ruled README row re-anchoring (the
   breaking-return-format alternative + the "froze complete WITHOUT a
   GA" parenthetical) is Rider 4; (iv) the three-engine end-state —
   covered (the Dart reference frozen; the Rust core serving every
   platform through the same flat C ABI; the TS engine + codecs
   RETIRED frozen transition artifacts; parameter corrections reach
   the web through the wasm build — ADR-009's supersession complete);
   (v) the post-freeze maintenance posture — covered, richer than my
   ruling (the four accepted-changes channels + the out-of-scope
   list); one READING clarification ruled in Rider 4 ("keeping them
   compiling" = the root-tsconfig check's continuation duty — the
   banner's byte-freeze stays the artifact-side rule; a future compile
   red on a frozen file is an owner decision, never a silent edit or
   an exclusion); (vi) the TWELFTH slip + parking posture — the
   parked-items sentence is in the declaration; the full enumeration
   + the three options + the no-ruling count land in the CONSENSUS
   exit record (Rider 5), which is the standing pattern's division.

9. **The release.yml re-rule: PROD's byte-frozen + STALE-BY-DESIGN
   ACCEPTED over my narrow amendment — with ONE live-probe correction
   (Rider 2).** Verified byte-unchanged: `git diff 1dd84dc..HEAD --
   .github/workflows/release.yml .github/workflows/pages.yml` →
   empty; `git tag --list` → exactly v1.0.0/v1.0.1/v1.1 (no tag at
   N6). PROD's posture is the legally superior one and I ACCEPT the
   reconciliation recorded in CONSENSUS ruling (8): nothing ships at
   N6 → no conveyance → no GPL §6/Apache-2.0 §4 duty is triggered at
   N6; my narrow amendment would have created a live shipping path
   for a FIRST wasm conveyance before the manifest duty landed;
   PROD's form forces the first conveyance, the manifest (Rider 1),
   and the web-asset rework into ONE deliberate owner decision. My
   condition 9's harness_check flip-clause is therefore MOOT at N6
   and DEFERRED to the rework commit: release.yml byte-unchanged →
   the N1 variant-precondition guard's zero-cargo assertion stays
   LITERALLY TRUE → the guard stays as-is and green (verified:
   harness_check 0 failures, live). **The live finding:** PROD's
   entry report's mechanics claim — "a post-conversion tag would red
   the job — fail-LOUD, never a silent bad asset" (l.296–299) — is
   DISPROVEN by a live probe at tip: `npm run build` (the exact CI
   chain: tsc green, `next build` green, the standalone bundling
   green) with NO `.wasm` under `public/` (gitignored, never tracked —
   the CI checkout has only logo.svg + robots.txt) succeeds, so a
   post-N6 tag would produce a GREEN nextjs-web job and a tar.gz
   whose app cannot boot (the browser-side `/clearfile-core.wasm`
   fetch 404s; the failure is loud IN THE BROWSER, silent IN CI —
   GREEN-THROUGH-BROKEN, not fail-LOUD). CONSENSUS's own record is
   not infected (it records only the stale-by-design + the
   no-tag-before-rework constraint); the correction is owed in the
   close records (Rider 2) so the standing constraint is recorded
   with the TRUE protective framing: the protection is the recorded
   constraint + the owner decision, never a CI red. The
   stated-as-fact class (my risk (c), N3's cbindgen exhibit A) — a
   dated correction at the close, the same class the N5 exit's
   records-honesty correction took.

## The close riders (numbered, checkable; discharged at the epilogue
## close — the same close that lands the terminal freeze declaration;
## exact texts below, transcribed verbatim)

1. **The first-conveyance LICENSES-manifest trigger, recorded NOW in
   three homes (one sentence each, plus the DEBT row).**
   (a) **DEBT.md** — the next row (D45), exact text:

   > **D45** | N6 exit gate LEGAL-4 (2026-11-27) | The WEB platform's
   > first-conveyance LICENSES-manifest trigger (ADR-017's licensing
   > annex, deferred since N2) is LIT: from the N6 close every
   > `release.yml` web build embeds the Rust core compiled to
   > wasm32-unknown-unknown, so the FIRST tagged release pushed after
   > N6 (even a v1.x patch) ships the repo's first Rust-core binary
   > with a real distribution path. That tag owes the per-platform
   > LICENSES manifest with THREE rows: (i) the palette module
   > (Apache-2.0 — `material_color_utilities` inside the .wasm; the
   > THIRD-PARTY-NOTICES entry is the attribution); (ii) the
   > statically-linked Rust standard library (**MIT OR Apache-2.0** —
   > wasm has no dynamic runtime; the std is embedded in the .wasm,
   > the /MT-precedent class CONSENSUS l.1903–1906 ruled for the CRT);
   > (iii) the carried MIT set (the shadcn components the tar.gz
   > already ships). GPL §6 stays covered by the release body's
   > standing sentence ONLY under the same-tag --locked discipline
   > (the shipped .wasm built from the release run's tagged checkout
   > with the committed Cargo.lock). | the next tagged release (with
   > D46)

   (b) **THIRD-PARTY-NOTICES.md** — one sentence appended after the
   palette section (advisory 2, promoted to a rider per my condition
   4's check), exact text:

   > The web `.wasm` build (`clearfile-core.wasm`, compiled from this
   > repository's Rust core and first embedded in a web release
   > tar.gz after N6, 2026-11-27) embeds both third-party entries
   > above that live in the core — the Apache-2.0 palette formulas
   > and the statically-linked Rust standard library (MIT OR
   > Apache-2.0); the per-release LICENSES manifest (ADR-017's
   > licensing annex) carries the full row set at the first tagged
   > web conveyance (DEBT D45).

   (c) **The CONSENSUS exit-gate record** — one sentence (with D46's,
   Rider 2(c)). *Check:* all three homes present at the close;
   `git ls-files | rg -i '\.(wasm|tar\.xz)$'` still empty at every
   close.

2. **The STALE-BY-DESIGN record with the corrected mechanics (the
   dated correction), the deferred guard flip, and the no-tag
   constraint.**
   (a) **DEBT.md** — the next row (D46), exact text:

   > **D46** | N6 exit gate LEGAL-9 / PROD-6 (2026-11-27) |
   > `release.yml`'s `nextjs-web` job is STALE-BY-DESIGN from the N6
   > close: the job (byte-frozen since 47f33a4, the v1.1 ship) builds
   > the web tar.gz from `src/` alone — NO wasm build step — while
   > the converted `src/` boots a loading gate that fetches
   > `/clearfile-core.wasm`. CORRECTED MECHANICS (the N6 exit gate's
   > live probe, superseding the entry report's "fail-LOUD" claim): a
   > post-N6 tag does NOT red the job — `tsc --noEmit` and
   > `next build` both stay green at the tip (verified 2026-11-27),
   > so the job would ship a GREEN-built tar.gz whose app cannot boot
   > (the core-module fetch 404s; the failure is loud in the browser,
   > silent in CI — GREEN-THROUGH-BROKEN). The protection is the
   > recorded constraint, never CI: NO TAG may be pushed before the
   > release.yml web-asset rework (the v2.0.0-GA work; the pre-ruled
   > form is LEGAL's N6 narrow amendment — the wasm build steps land in
   > the nextjs-web job ONLY, built --locked from the tagged
   > checkout, and the harness_check release.yml variant-precondition
   > guard flips IN THAT SAME COMMIT to the references-confined-to-
   > nextjs-web state). Any tag before the rework is an owner
   > decision that first resolves the web-asset question AND
   > discharges D45's manifest in the same release. The v1.1 tarball
   > is the LAST TS-engine web distribution; the first wasm-served
   > web distribution is v2.0.0-GA territory per ADR-017's row. | the
   > release.yml web-asset rework (with D45)

   (b) The README's `src/` row carries the pointer (Rider 3(a)'s
   exact text) — the natural reader-facing home; no separate README
   release-section note is owed (the GitHub-Releases row stays true
   of the existing tagged releases).
   (c) **The CONSENSUS exit-gate record** — one sentence, exact text:

   > The release lane at the N6 close: release.yml stays BYTE-FROZEN
   > (verified) with the nextjs-web job STALE-BY-DESIGN —
   > GREEN-THROUGH-BROKEN on a post-N6 tag (the exit gate's live
   > probe; the entry record's fail-LOUD claim corrected here) — so
   > NO TAG lands before the web-asset rework, and the first
   > conveyance owes D45's LICENSES-manifest rows (palette Apache-2.0
   > + the statically-linked Rust std MIT OR Apache-2.0 + the carried
   > shadcn MIT set) in the same release.

   *Check:* D46 present at the close; the correction worded exactly
   (GREEN-THROUGH-BROKEN); the guard-flip deferral recorded (it
   belongs to the rework commit); `git diff` over release.yml still
   empty at every close until the rework.

3. **The README honest-surface rewrite — the exact row texts (one
   commit, with the layout.tsx metadata line).** The rows that
   become false at the switch are rewritten NOW; the untouched set
   (the AI section, the demo disclaimers, the v1.0.0/v1.0.1 network
   note, the License section, the Pages section, the Engine
   limitations rows — re-read for truth below) stays byte-stable.
   (a) **The `src/` row (l.18)** — replace "with the **same TY2025
   calculation engine as the Flutter app** (ADR-009 parity,
   2026-11-15: line-for-line port validated against the shared golden
   fixtures)" with:

   > whose TY2025 compute, parameter table, and every format codec
   > are served by the **shared Rust core compiled to WASM** (N6,
   > 2026-11-27: a zero-npm-dependency JS loader over the same flat C
   > ABI the native lanes consume; the 17 shared golden fixtures pin
   > the wasm adapter in CI — 17/17; the release lane's web tar.gz
   > is stale-by-design until the v2.0.0-GA rework — DEBT D46)

   (b) **The `clearfile/` row (l.19)** — replace the last sentence
   ("The two codebases share no code; the web engine is a
   line-for-line TypeScript port of this one (Stage-3 parity).")
   with:

   > The two codebases share no code; the web's former line-for-line
   > TypeScript port of this one is RETIRED — a frozen transition
   > artifact (ADR-016 → ADR-017, N6, 2026-11-27) — and the web
   > prototype now computes through the same Rust core the native
   > lanes consume.

   (c) **The `fixtures/tax/` row (l.21)** — replace "and
   `scripts/web_parity_test.mjs` (TypeScript) and" with "and
   `scripts/wasm_parity_test.mjs` (the wasm core adapter — the
   transferred web-parity contract) and" (the three live runners:
   Dart, wasm, Rust).
   (d) **The "Calculation engines" intro (l.67–70)** — replace with:

   > The repository contains **two independent implementations** (no
   > shared code) now held to the same behavior by the shared golden
   > fixtures: the Flutter/Dart engine (the frozen reference) and the
   > Rust core (the live shared engine — serving the web through
   > WASM since N6, 2026-11-27). The web's former line-for-line
   > TypeScript port of the reference (Stage-3 parity, ADR-009) is
   > retired — a frozen transition artifact kept in-tree and still
   > type-checked (ADR-016 → ADR-017).

   (e) **The "Web engine" section (l.94–113)** — the section head and
   first paragraph are replaced with my entry-ruled head text plus
   the honest body, exact text:

   > ### Web engine — the shared Rust core compiled to WASM (N6,
   > 2026-11-27)
   >
   > The web prototype computes via the shared Rust core compiled to
   > WASM (N6, 2026-11-27) — the same 17 shared golden fixtures pin
   > the wasm adapter in CI (17/17); the TS engine and TS codecs are
   > retired frozen transition artifacts (ADR-016 → ADR-017, still
   > tsc-checked, out of the runtime import graph). The adapter
   > (`src/lib/wasm/core.ts`) is a zero-npm-dependency loader over
   > the same flat C ABI the native lanes consume
   > (`core-ffi/clearfile.h`); the app boots a loading gate until the
   > same-origin module loads, and every numeric tax parameter and
   > every format byte on the web path originates in the core. The
   > web still reads and writes the **same unified return file
   > format**: the versioned `.clearfile.json` envelope (ADR-015) —
   > the core's envelope codec, migrations and warning strings
   > included — so saved files round-trip across the Flutter app, the
   > web prototype, and the `.tax`-extension exchange container
   > (`docs/return-format.md`).

   The section's two existing scope notes (the TY2026 drop, D32; the
   UI-level whole-dollar rounding) STAY — both remain true (the wasm
   table serves TY2025 only). The "Engine limitations" bullets stay
   true as written ("Both engines (identically, by construction of
   the parity ports)" — see Rider 4's reading note; "Web engine
   only: TY2026 is not supported" — still true through the wasm
   table's year guard) — re-read, not rewritten.
   (f) **The TurboTax-bridges section (l.194)** — replace "pinned by
   14 Dart tests + the web bridge suite in CI" with "pinned by 14
   Dart tests + the wasm bridge suite in CI (the transferred web
   bridge contract — the codecs are the core's, served through the
   wasm adapter)". The `txf_taxfile_test.mjs` citation at l.207
   stays (the suite name is unchanged and still true).
   (g) **The running commands (l.255–264)** — replace the two suite
   lines and add the wasm build chain, exact block:

   > ```bash
   > cd ClearFile
   > npm install
   > rustup target add wasm32-unknown-unknown   # once per toolchain
   > cargo build --release --target wasm32-unknown-unknown --manifest-path core-ffi/Cargo.toml
   > cp core-ffi/target/wasm32-unknown-unknown/release/clearfile_core_ffi.wasm public/clearfile-core.wasm
   > npm run build      # next build (standalone output)
   > npm start          # serve the standalone build
   > node scripts/wasm_parity_test.mjs   # the wasm core adapter vs the shared golden fixtures (17/17)
   > node scripts/txf_taxfile_test.mjs  # TXF + .tax + envelope contracts over the wasm adapter (the transferred bridge suite)
   > node scripts/ai_cascade_fixture_test.mjs   # AI cascade replays synthetic provider fixtures via a stubbed fetch (Stage-5)
   > node scripts/ai_injection_test.mjs         # AI injection suite: generic error labels + parse-field whitelists (Stage-5)
   > ```

   plus one appended sentence after the self-hostable-bundle note:
   "the bundle needs `public/clearfile-core.wasm` present — the
   core-module load is same-origin; without it the app stays on its
   loading gate."
   (h) **The v2.0.0 row + the maintenance-policy sentence** — see
   Rider 4(c)/(d).
   (i) **`src/app/layout.tsx` l.21** (my entry advisory 1, same
   commit): "simplified TY2025/TY2026 federal engine" → "simplified
   TY2025 federal engine". *Check:* every README claim about the web
   engine true at the tip (the honest-surface pass); the untouched
   set diff-empty; `npx tsc --noEmit` still 0.

4. **The terminal freeze declaration — the final form landing at the
   close.** PROD-4's exact text lands VERBATIM (the session
   transcribes, never drafts) in ROADMAP (the epilogue frame at the
   N6 bullet's close), README (the maintenance-policy section
   extension), and STATE (the close-out), plus the CONSENSUS
   exit-gate record and the SESSION_LOG session record (my condition
   8's five homes). TWO ruled appends to PROD's text (ruled here,
   transcribed verbatim with it) and two README edits:
   (a) the declaration's heading takes the date: "**The epilogue's
   terminal freeze (declared at N6 — the ADR-017 program's close,
   2026-11-27).**" (my element (i)'s "dated");
   (b) the declaration's ship-state paragraph is followed by one
   sentence (my element (ii)'s web clause), exact text:

   > **The ship state, web included:** the live Pages demo at
   > maniesh-Nr.github.io/ClearFile/ stays the FLUTTER (Dart) build —
   > the shipped web product; the Next.js prototype is a repo
   > prototype + a release-tar.gz artifact, never deployed.

   (c) the README's v2.0.0 row (l.282–285) is re-anchored — replace
   "only the ADR-017 epilogue — the Rust core and per-OS native
   stacks —" with "the first GA release whose distributed artifact
   for any OS is the native stack (the ADR-017 rule — the epilogue
   program froze complete WITHOUT a GA; no native stack has shipped
   yet)," keeping the breaking-return-format alternative and its
   ADR-015 parenthetical, and appending PROD's version-plane
   sentence ("Nothing at the N6 close moves any version plane: the
   app semver stays v1.x, the `.clearfile.json` envelope schema
   stays 2, and every crate and package plane stays its own.");
   (d) the fired maintenance-parity sentence (l.285–287: "The web
   prototype stays in maintenance parity (ADR-016) until the Rust
   core serves the web (WASM) and the TS engine retires.") is
   REMOVED — superseded by the declaration landing in that section;
   (e) the READING rule recorded with the declaration (one sentence,
   reconciling the declaration's "beyond keeping them compiling" with
   the banner's byte-freeze): "keeping them compiling" means the
   root tsconfig's check CONTINUES over the frozen artifacts (they
   are never excluded); it is not an edit license — the banners'
   byte-freeze is the artifact-side rule, and a future compile red
   on a frozen file is an owner decision (accommodate or defer the
   toolchain/dependency change), never a silent edit or an
   exclusion. *Check:* all five homes carry the six elements per the
   division verified above; the declaration contains no v2.0.0 bump,
   no tag, no GA claim; the README row matches Rider 4(c) exactly.

5. **The CONSENSUS exit-gate record's own content (the terminal
   gate's last record).** Beyond Riders 1(c)/2(c), the record carries:
   (a) the THIRTEENTH slip surfacing — the pinned per-gate-event
   enumeration extended by THIS exit gate taking its own number
   (…11 the N5 exit, 12 the N6 entry, **13 the N6 exit** — the
   epilogue's last gate-event), "no ruling received across TWELVE
   prior surfacings," the three owner options restated
   ((a) fund a T3 session (the 0x24000 keystream chase +
   tax-modern.md, D42), (b) supersede the RE-protocol namespace
   rule, (c) the default re-agenda), and the TERMINAL-gate parking
   posture verbatim (the Stage-2 exit stays SLIPPED; the MSI chase
   stands as recorded debt D42, disposition "T3 session 2"; D30
   standing — never a silent drop); (b) the exit-gate acceptances so
   the record is self-contained: the banner form accepted with the
   two recorded letter-deviations (condition 1); the four-export
   set accepted (condition 6); PROD's release.yml re-rule accepted
   with the corrected mechanics (condition 9); (c) this gate's rider
   discharge ledger (Riders 1–5 above) with their homes;
   (d) STATE's "Immediately next" is re-pointed at the epilogue
   close-out (the freeze declaration + the final memory sync), and
   SESSION_LOG records the close session per the standing
   single-session directive. *Check:* the enumeration honest
   (13 = this exit); D42/D30 rows unchanged in DEBT; STATE/SESSION_LOG
   synced at the close.

## Risks register

(a) **The first-conveyance trigger, restated for the last time
carried (N2–N6):** Rider 1's three homes + the D45↔D46 coupling make
the next tag's duties un-missable; the residual risk is a future
v1.x-tag session that reads PROD's fail-LOUD claim and trusts CI to
catch it — Rider 2's correction is the guard.

(b) **The GREEN-THROUGH-BROKEN release lane (NEW, the live
finding):** until the rework, a tag push ships a green-built,
non-booting web tar.gz. The guards: D46's no-tag constraint + the
release flow's owner-decision gate + this record. (PROD's exit
report independently reached the same correction class — its Rider
4; the orchestrator reconciles the two texts at the close, both
worded GREEN-THROUGH-BROKEN.)

(c) **The frozen-file edit precedent (carried, unchanged):** the
banner's own text forecloses it; the tripwire is any later diff over
a retired file — now including a "wording polish" of the banner
itself (condition 1's accepted deviations are recorded HERE, never
to be back-ported into the files).

(d) **The toolchain/runner terms drift (carried):** the wasm lane's
resolved toolchain is pinned twice (the sandbox manifest row 2 —
rust-std 1.100.0, sha256-pinned, verified in the fetch script — and
the CI rustup lane's fail-closed rustc ≥ 1.95 guard); any future
claim about the wasm/std license posture is recorded from the
resolved toolchain, never transcribed from a proposal.

(e) **The cross-origin/CDN wasm drift (carried, cheap):** the
adapter's `initWasm` default remains the literal relative path; the
same-commit disclosure rule (condition 5(d)) is the standing guard.

## Advisories (non-binding)

1. SECURITY.md's src/ scope row may optionally add the wasm-boundary
clause ("the parsers now run in the core through the wasm adapter") —
honest, not owed.
2. The license-text-in-the-tarball question rides the existing
posture (the release-body §6 statement + the tagged repo + the README
link) through the existing tags; D45's manifest is the natural home
for the full license-text set at the next tag — do not bolt a partial
fix onto the close.
3. The suite tsconfigs' disposition record lives in the three
suite-script banners + the ROADMAP execution record rather than in
the JSON configs themselves (comment-free by their own emit
discipline) — noted at condition 3; no action owed.

## Files read + verification log

**Records:** my standing register (the N1–N6 entry reports; the N5
exit `2026-11-27-n5exit-legal.md` — the template); the CONSENSUS N6
entry record l.2211–2318 (the rulings, the reconciliations (a)–(f),
the TWELFTH surfacing + the TERMINAL-gate parking posture); the four
N6 entry reports (SEC/LEGAL/ENG/PROD — PROD's conditions 4/6/8/…
quoted above); ROADMAP's N6 execution record (the first-live-green
run 45991816001 on f295a27, all eight jobs); STATE l.363–394 (the N6
agenda + the close-out pointer); DEBT (the D-rows through D44 —
D45/D46 are the next numbers, ruled in Riders 1/2);
THIRD-PARTY-NOTICES (the shadcn MIT row l.7–20, the palette
Apache-2.0 row l.48–67); SESSION_LOG (the standing single-session
directive).

**In-tree (at tip 8387202, over the delta `1dd84dc..HEAD`):** the
four retired files (banners verified above); `config.ts` (the table
note); `src/lib/wasm/core.ts` (full read: the SPDX header, the
negative-provenance comment, the length-paired withInput, the
poisoned-instance trap mapping, the BigInt year, the length guard,
the same-origin fetch pin, the serving surface); the consumers
(page.tsx boot gate, steps.tsx, filemenu.tsx, ai-ui.tsx, ai/tasks.ts,
store.ts — the type-only seam); `scripts/wasm_parity_test.mjs` +
`web_parity_test.mjs` (retired) + `txf_taxfile_test.mjs` +
`ai_*.mjs`; the three suite tsconfigs; `tsconfig.json`;
`package.json` (byte-unchanged); `core-ffi/clearfile.h` (the four
additive declarations + doc comments); `core-ffi/src/lib.rs` (the
four plain exports, the length-paired dealloc, the panic-hook
feature); `core-ffi/tests/boundary.rs` (12 tests);
`core/src/params.rs` (the serialization mirroring the TS keys);
`.github/workflows/hygiene.yml` (the wasm32 --locked build + the
import-empty guard + the transferred suites); `release.yml`
l.496–572 (the nextjs-web job, read for the live finding);
`pages.yml` (untouched); `harness_check.sh` (the counter updates);
`fetch_rust_toolchain.sh` + `rust_toolchain_manifest` (row 2);
`.gitignore`; `README.md` (all rows cited in Rider 3);
`src/app/layout.tsx` l.21.

**Live probes (read-only, 2026-11-27, all run by this lane):**
- `npx tsc --noEmit` → **exit 0** (the retired files still
  root-tsconfig-checked and clean).
- `node scripts/wasm_parity_test.mjs` → **17/17 fixtures, 0 field
  failures** + the allocator ruling ok + the parameter-table check ok
  (trap assertion correctly skipped — no panic-hook module locally).
- `node scripts/txf_taxfile_test.mjs` → **11/11 groups**.
- `node scripts/ai_cascade_fixture_test.mjs` → **5/5**;
  `node scripts/ai_injection_test.mjs` → **4/4**.
- `npm run build` → **green** (the exact release-lane chain, no
  `.wasm` under `public/` — the GREEN-THROUGH-BROKEN probe); bundle
  grep: retired-unique symbols (`saltCapFor|shannonEntropy|makeZip|
  readZip|CFR_FORMAT`) → **zero files**; the adapter's marker string
  present in `.next/static/chunks/`.
- WebAssembly module probe: **imports = 0**, exports = 15, size
  318,715 bytes.
- `cargo test --manifest-path core-ffi/Cargo.toml --release
  [--features panic-hook-test]` → **11 / 12 passed** (the 12th is
  the feature-gated panic-injection test); the header regeneration
  left the tree **clean** (the freshness check's local proof).
- `bash scripts/harness_check.sh` → **0 failures**.
- `git ls-files | rg -i '\.(wasm|tar\.xz)$'` → **empty**; tracked
  binaries = png 25 / pdf 3 / ico 1; `git tag --list` = exactly
  v1.0.0, v1.0.1, v1.1; `git diff 1dd84dc..HEAD -- package.json
  package-lock.json .github/workflows/release.yml
  .github/workflows/pages.yml src/components/clearfile/settings.tsx
  src/components/clearfile/shell.tsx` → **all empty**;
  `git check-ignore -v` confirms both wasm ignore rules;
  `git diff f295a27..HEAD` → records-only (CONSENSUS/ROADMAP/
  harness_check), so the f295a27 CI-green covers HEAD.

**Working-tree discipline:** read-only probes + this report (the
gitignored build outputs `.next/`, `.parity-build/`, `.files-build/`,
`.ai-build/`, `tool-results/` are the probes' residue; the parallel
lane's `2026-11-27-n6exit-product.md` is noted, not read for
substance — parallel isolation). Final state:

```
$ git status --short
?? harness/adversarial/reports/2026-11-27-n6exit-product.md
?? harness/adversarial/reports/2026-11-27-n6exit-legal.md
```

**Gate outcome (this lane): PROCEED-WITH-CONDITIONS — exit granted;
5 close riders (Riders 1–5 above, exact texts ruled) discharged at
the epilogue close with the terminal freeze declaration.**
