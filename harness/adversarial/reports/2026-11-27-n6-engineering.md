# ADV-ENG — N6 delta-scoped gate (2026-11-27, Task N6-GATE-ENG)

Scope: the ENG lane of N6 — THE TERMINAL GATE (ADR-017's last stage:
web via WASM + the terminal freeze). Tip 1dd84dc verified at start
(all CI green; `git status` clean); the tree stays untouched except
this report. The proposal under review: wasm32-unknown-unknown (not
wasip1) for the std-only zero-dep core; core-ffi compiled to wasm
(the same flat C ABI, the JNI shim cfg-gated off, ONE new additive
export `clearfile_alloc`); the JS loader/adapter (src/lib/wasm/,
zero npm dependencies); the Shape A vs B serving question; the test
transfer (web_parity_test.mjs → the wasm parity suite; the bridge
suite under Shape A); the CI shape (hygiene suites + release
nextjs-web); the terminal freeze declaration + the TWELFTH slip +
the ONE-session box.

**Probe posture — DIFFERENT FROM EVERY PRIOR LANE: this sandbox's
proposed "optional local pre-flight" was EXECUTED, not taken on
faith.** The pinned standalone 1.100.0 toolchain (scripts/
rust_toolchain_manifest) + the rust-std-wasm32-unknown-unknown
component from the SAME dist/2026-11-12 tree were fetched into
/tmp/n6-eng (df first: 6.7 GB free; unauthenticated public fetch,
sha-pinned tarball for the toolchain), merged with the fetch
script's own strip-2 layout, and core-ffi was BUILT for
wasm32-unknown-unknown locally (`cargo build --locked --release
--target wasm32-unknown-unknown` → green in 22.85 s). The .wasm was
then run in node (v24.22.3): the full 17-fixture parity with the
exact web_parity tolerance semantics, the ABI surface, the bound,
the binary-input path, the envelope warnings parity, the TXF
export, the palette, the panic guard, and the alloc/free design
were ALL probed live (the probe log is below, every claim in this
report traceable to a run). The repo tree was never touched by a
build (the build ran over /tmp copies of core/ + core-ffi/; both
lockfiles untouched by construction; the one stray download that
landed at the repo root was deleted, verified clean at close).

**THE THREE KEY FINDINGS (each probe-verified):**

**(1) The alloc/free design AS PROPOSED IS MEMORY-UNSOUND — the
freed-by-`clearfile_free` contract breaks the allocator on exactly
the payload class the wasm boundary most needs.** The proposal's own
words: "a leaked Vec the caller writes into, freed by clearfile_free
— JS's only clean way to place input bytes." `clearfile_free` is
`CString::from_raw` (core-ffi/src/lib.rs:541-548): it reconstructs
the Vec's capacity from `strlen(ptr)+1` — the NUL position IS the
length. An alloc'd buffer the caller filled with a **binary payload
containing interior NULs** (a `.tax` container: every ZIP header
carries zero bytes — the container path is the core use case of the
file-analysis menu) frees with the WRONG layout: strlen lands at the
first interior NUL, the reconstructed capacity is k+1 ≠ the true
allocation. PROBE (fresh instance per case): the interior-NUL free
TRAPPED on iteration 1 (a panic inside `__rdl_dealloc` → panic=
abort on wasm → `RuntimeError: unreachable`); the no-NUL-anywhere
free ran 20 iterations with NO trap — the SILENT wrong-size free
class (worse: delayed, non-deterministic breakage). The length-
paired alternative (`clearfile_dealloc(ptr, len)` =
`Vec::from_raw_parts(ptr, 0, len)` — the exact original layout,
freed with the exact original size) ran 200 iterations with
interior NULs + full compute-health checks every 50 — ALL HEALTHY.
Also probed: `alloc(0)` returns the Vec's DANGLING alignment
pointer (ptr=1, not a real allocation — freeing it is UB), and a JS
`len ≥ 2^32` on a call WRAPS SILENTLY through ToUint32 (the callee
saw len=16 for a passed 2^32+16 — probe-verified). The design's
soundness verdict: the alloc/free pair is Rust's allocator on both
sides — TRUE — but the FREE must be LENGTH-PAIRED, never
NUL-derived. This is a condition, not a BLOCK: the fix is one
export's signature, the rest of the design stands.

**(2) The catch_unwind guard does NOT transfer to wasm — a panic
TRAPS, it does not return the sentinel.** The N3 ledger's "No panic
ever crosses the boundary" is a NATIVE-target fact: wasm32-unknown-
unknown links `libpanic_abort` (the wasm link line carries it —
observed in the probe build's linker invocation), and
`catch_unwind` cannot catch an abort. PROBE: the panic-hook-test
build's `clearfile_test_guard_panic()` from node → `RuntimeError:
unreachable`, `last_error` still "" — the sentinel + named-message
contract is NOT delivered on wasm. The post-trap state is
INDETERMINATE (one probe shape ran on after the trap; another
trapped OOB after the panic path GREW memory mid-trap — 17→18 pages
observed). This is a TARGET FACT, not a core bug — and it is
containable: a wasm trap surfaces to JS as a catchable RuntimeError,
the core's panic-free discipline is the same code green on four
native targets, and the parser's own caps (MAX_NESTING_DEPTH 128,
member cap, the 512 MiB bound — all probe-verified reachable
through wasm) make traps a residual class. The condition: the
adapter wraps every call in try/catch mapping RuntimeError → the
core's own wording family, and treats a trapped module as POISONED
(no further calls), with the honest record that the boundary
battery's guard proof is native-only.

**(3) Shape A's "ONE new additive export" is FALSE as stated — the
`.tax` container EXPORT has no ABI function, and the char* return
class cannot carry the binary container bytes.** The web's
`exportTaxContainer` (filemenu.tsx:71-78, steps.tsx:778) writes the
open ZIP container (clearfile.json + README.txt via `makeZip`). The
core HAS the function — `export_tax_container` (core/src/
tax_inspect.rs:762, TAX_CONTAINER_README verbatim at :104) — but the
C ABI does not export it, and the ABI's owned-return class is the
NUL-terminated CString (`to_owned_buffer`, lib.rs:147-154): a ZIP's
bytes carry interior NULs by construction, so a char*-returning
container export would refuse (fail-closed, broken). The honest
full-Shape-A export set is THREE additions, not one: `clearfile_
alloc` + the length-paired `clearfile_dealloc` + a container export
with an EXPLICIT-LENGTH return (e.g. `clearfile_export_tax_container
(envelope_text, len, out_len: *mut uintptr_t) -> char*`, freed via
the length-paired dealloc — a third return class, an ABI-ledger
amendment recorded as such). The FALLBACK (the parking posture): the
container export stays a small JS residue (makeZip + README, ~90
lines, already structure-pinned by the bridge suite) with a debt
row. Both are honest; the proposal's "ONE new additive export" is
not.

**VERDICT: PROCEED-WITH-CONDITIONS**

## The Shape A vs B ruling (ENG's own question, evidence-settled)

**RULING: Shape A — the full serving (compute AND the codecs
through the wasm core) — with the honest export set of condition 2.**

The call graph, measured (not guessed):

- `compute` is SYNC on the RENDER path: `useFilingComputed`
  (steps.tsx:36-41) calls `compute(filing, params)` inline and is
  consumed by SIX step components (steps.tsx:216, 331, 421, 595,
  654, 727) — compute-per-keystroke via the zustand re-render
  (`MoneyInput` onChange → `setIncomeField` → re-render → compute).
  Two more compute calls sit inside async callbacks (ai-ui.tsx:143,
  458 — `send()`/`run()`), still called synchronously within them.
  A wasm call is synchronous once instantiated — the sync call sites
  stay sync. The cadence is sub-millisecond workloads; the wasm
  overhead is the same order.
- THE BOOT GATE ALREADY EXISTS: page.tsx:29-36 defers the ENTIRE
  interview behind `mounted` + a Splash (the zustand-persist
  hydration gate). The wasm-ready state composes into the EXISTING
  gate (`mounted && wasmReady` — the one-time `WebAssembly.
  instantiate` completes before the interview renders). ZERO
  structural change; the AI cascade's compute calls (inside user-
  triggered callbacks) are post-boot by construction.
- The codecs are event-handler calls: the exports (steps.tsx:
  767-778, filemenu.tsx:62-78) run in click handlers; the imports
  (filemenu.tsx:41-60, 80-95) are ALREADY async (`await file.text()`
  / `arrayBuffer()`). No async ripple exists to fear.
- The store's persistence is zustand `persist` → localStorage
  (store.ts:197-313); `src/lib/db.ts`'s PrismaClient is DEAD CODE
  (imported nowhere — measured; the api route is a Hello-world). No
  async ripple from persistence.
- The AI cascade (ai/tasks.ts) imports only TYPES + two trivial
  helpers (`totalWages`/`totalWithholding`, tasks.ts:12-13) — the
  smallest possible surface; ai-ui's compute calls are covered above.
- WHY A OVER B: ADR-016's retire-on-replacement day has arrived by
  its own terms (STATE.md:374-376: "the freeze converts to retirement
  the day the shared Rust core serves the web"); the four-way
  duplication (TS + Dart-legacy + Rust core + the frozen engines)
  ends only under A; the parity debt (D34's triple-implementation
  class) closes; and — the mechanical argument — EVERYTHING the web
  UI does through the four files is already served by the ABI except
  the container export (condition 2), which the core already
  implements. Shape B would leave the four-file freeze half-done at
  the TERMINAL gate — the one gate whose whole point is closure —
  and the TS codecs would ride as debt on a program declaring its
  own freeze. The one-session risk is real (condition 8 sizes it),
  and the fallback parking posture is named (condition 2c).

## Conditions

1. **The alloc/free pair MUST be length-paired (the proposal's
   freed-by-clearfile_free is REJECTED — probe evidence in the
   header findings).** The committed shape: `clearfile_alloc
   (uintptr_t len) -> char*` (a `Vec::with_capacity(len)` the caller
   writes `[0, len)` into — payload bytes may include interior NULs,
   the data functions' explicit lengths are authoritative) + **a new
   `clearfile_dealloc(char *ptr, uintptr_t len)`** (`Vec::
   from_raw_parts(ptr, 0, len)` — the exact-layout free, probe-
   verified sound x200 with interior-NUL payloads + interleaved
   compute-health checks). `clearfile_free` remains the return-value
   free for the CString class it serves today (the header's own
   words preserved: freeing a RETURN via libc is UB; freeing an
   ALLOC'd buffer via clearfile_free is now DOCUMENTED as wrong —
   each class names its paired release function in the header
   comments). THREE design requirements the probe surfaced, all
   REQUIRED: (a) **`clearfile_alloc` refuses `len == 0`** (return
   NULL + `clearfile_last_error` set — the Vec's dangling alignment
   pointer is not an allocation; empty inputs go directly as `(0,
   0)`, which `as_bytes` already accepts as the empty payload,
   lib.rs:110-118); (b) **`clearfile_alloc` enforces the 512 MiB
   bound** (`check_size` + the shared named message — the "enforced
   at every entry surface" doctrine, lib.rs:120-127; without it the
   alloc is an unbounded caller-driven reservation that the data
   functions refuse only after the memory is already held); (c) the
   header regen (cbindgen) flows in the SAME commit — the android
   job's freshness check (hygiene.yml:323-326) regenerates and
   diffs on every push, so the new declarations must be committed
   regenerated, and the boundary battery gains the alloc test: the
   round trip (alloc → write an interior-NUL binary payload →
   compute/inspect over it → the paired free) + the len==0 refusal +
   the bound refusal — on the native side the battery runs green
   with BOTH free designs (glibc ignores the size mismatch — the
   native test would NOT catch the wasm-only unsoundness), so the
   alloc test's assertion set must include the wasm-side paired-free
   path exercised by the transferred parity suite (condition 7).

2. **The container-export ruling (Shape A's honest export set, with
   the fallback parking posture).** (a) PRIMARY: the third addition
   `clearfile_export_tax_container(const char *envelope_text,
   uintptr_t len, uintptr_t *out_len) -> char*` over the existing
   core function (tax_inspect.rs:762) — the return is a length-
   explicit binary buffer freed by `clearfile_dealloc(ptr, *out_len)`
   (the char* NUL-class is impossible for ZIP bytes; the ABI ledger's
   "exactly two return classes" line is AMENDED in its own comment
   to three: owned NUL-terminated text (clearfile_free), borrowed
   thread-local (never freed), owned explicit-length bytes
   (clearfile_dealloc) — the explicit-length doctrine the ledger
   already applies to INPUTS, extended to outputs). The boundary
   battery gains the container round trip (export → inspect →
   load_and_compute → the same filing back). (b) The adapter's JS
   side reads `out_len` through a DataView BEFORE any further wasm
   call that can grow memory (growth detaches views — condition 4c).
   (c) FALLBACK (the explicit parking posture, pre-ruled so the
   one-session box has an honest exit): if the box tightens, the
   container export stays a JS residue — `makeZip` +
   `TAX_CONTAINER_README` (~90 lines, the binary-writer class,
   already structure-pinned by the bridge suite's round-trip group)
   — moved under src/lib/wasm/ as the recorded residue, with a DEBT
   row (the container-export ABI addition as the named future work)
   and the terminal freeze declaration recording it as the ONE
   non-core-served web function. NEVER the silent version: the
   proposal's "ONE new additive export" line is corrected to the
   verified set (alloc + dealloc [+ export-container]) in the
   gate record.

3. **The wasm trap contract (the panic guard does not transfer —
   the adapter owns the containment).** Every adapter wrapper wraps
   its wasm call in try/catch: a `RuntimeError` maps to the core's
   own wording ("The operation failed unexpectedly — an internal
   error occurred." — the guard's own message, lib.rs:98) surfaced
   through the SAME error path the NULL+last_error returns use, so
   the UI's existing error surfaces (the CfrParseError-style toasts)
   never see a new class. After a trap, the module is POISONED: the
   adapter marks itself failed and refuses further calls (the
   post-trap heap state is indeterminate — probe evidence: one
   post-trap call ran on, another trapped OOB after the panic path
   grew memory mid-trap). The honest record, REQUIRED in the N6
   records: the boundary battery's guard proof (panic-hook-test,
   battery line 370) is a NATIVE-target proof; on wasm32-unknown-
   unknown a panic traps (`libpanic_abort` is in the wasm link line
   — observed); the residual-trap risk is bounded by the core's
   caps (nesting 128, member cap, the 512 MiB bound — all reachable
   and green through the wasm boundary in the probe) + the same
   panic-free discipline four native targets run. The wasm parity
   suite gains one guard test: the panic-hook-test build is NOT
   shipped (test-only feature, Cargo.toml:52-56) — the trap test
   belongs to the SUITE side (the suite builds its own panic-hook
   .wasm if it wants to pin the trap-mapping; optional, advisory
   below).

4. **The adapter disciplines (each one probe-proven necessary):**
   (a) **the i64/BigInt seam** — `clearfile_export_txf`'s `year` is
   i64 on wasm: JS must pass `BigInt(year)` (a plain Number throws
   `TypeError: Cannot convert 2026 to a BigInt` — probe-verified;
   the committed header's `int64_t` is the cbindgen view of the same
   seam); (b) **length validation BEFORE every call** — a JS Number
   ≥ 2^32 wraps silently through ToUint32 at the JS→wasm boundary
   (probe-verified: the callee saw len=16 for a passed 2^32+16);
   the adapter's write helper passes only `new TextEncoder().
   encode(text).length` (always a safe integer) and the alloc-bound
   refusal is server-side (condition 1b) — the adapter never
   forwards a caller-supplied length unchecked; (c) **no cached
   memory views across wasm calls** — any wasm call that allocates
   (including clearfile_alloc itself) may grow memory and DETACH
   the old `Uint8Array`; the adapter re-derives the view from
   `memory.buffer` after every alloc/return acquisition, reads
   `out_len`-style out-params before any further call (condition
   2b), and reads NUL-terminated returns with a scan bounded by
   `memory.buffer.byteLength` (the CString terminator is guaranteed;
   the bound is belt-and-suspenders); (d) **the loader is LAZY and
   dual-path** — no import-time side effects (the node ai suites
   transitively import the adapter through tasks.ts; a top-level
   `fetch()` would break them — undici fetch does not support
   file://), and the init exposes `initFromBytes(Uint8Array)` for
   node alongside the browser `fetch('/clearfile-core.wasm')` path;
   the sync wrappers throw a named not-ready error if called before
   init (never user-visible behind the boot gate); (e) **zero npm
   dependencies stays TRUE** — WebAssembly/TextEncoder/TextDecoder
   are platform APIs; package.json's dependency arrays are untouched
   (verified read; the proposal's claim holds with the adapter
   hand-rolled).

5. **The CI shape — the suites job.** The wasm build lands in the
   suites job BEFORE the node suites, in the android lane's exact
   shape: the rustc >= 1.95 family guard (the android job's form,
   hygiene.yml:284-296 — the suites job's existing core-test step
   has NO guard today; the new step carries it) → `rustup target add
   wasm32-unknown-unknown` (the runner-side affordance, green since
   N3 on ubuntu-latest) → `cargo build --locked --release --target
   wasm32-unknown-unknown --manifest-path core-ffi/Cargo.toml` →
   the transferred wasm parity suite reads the .wasm from the BUILD
   path (`core-ffi/target/wasm32-unknown-unknown/release/
   clearfile_core_ffi.wasm` — the probe's exact path; no copy needed
   for the suite; the "runtime location" copy is a release/dev
   concern, condition 6). Release profile is the right call (the
   artifact the web actually serves; the android lane's debug build
   is an APK-packaging choice, not a precedent against it). The
   wasm build in the SAME job as `cargo test --locked` (core/) is
   conflict-free (different manifests/targets). The failure mode
   named: the suites job's node suites currently pass with NO rust
   toolchain assumptions beyond the core-test step — after this
   delta every suite run builds wasm first, so a rustc drift that
   breaks the wasm build (e.g. a future target rename — none
   signaled) reds ALL suites: acceptable, fail-closed, and the
   guard makes the drift loud rather than cryptic.

6. **The CI shape — release.yml's nextjs-web job (the byte-freeze
   re-rule this gate owes per STATE.md:390-392).** The job gains,
   between `npm ci` and `npm run build`: the same guard + rustup +
   wasm-build steps (condition 5's form) + `mkdir -p public && cp
   core-ffi/target/wasm32-unknown-unknown/release/
   clearfile_core_ffi.wasm public/clearfile-core.wasm`. The copy
   BEFORE `npm run build` is correct and sufficient: package.json's
   build script already does `cp -r public .next/standalone/`
   (package.json:7) and the job's Bundle step re-copies (release.yml:
   564-568) — the .wasm rides BOTH automatically into the tarball.
   THE RE-RULE (this gate's ruling, for the record): the release.yml
   delta is CONFINED to the nextjs-web job; the tag-guard block
   (release.yml:510-559) and every other job byte-unchanged; the
   job's new rust dependency is the runner's rustup — the recorded
   CI-primary toolchain stance (the same stance as the android
   .so), with the honest note that the .wasm's bytes are a function
   of the runner's rustc family (a reproducibility note, not a
   freeze violation — the tar.gz was never byte-stable across runs:
   mtimes ride in). pages.yml UNTOUCHED — verified: it deploys the
   FLUTTER web app (clearfile/** path-filtered; N6's delta touches
   neither — the deploy won't even trigger, the live Pages demo
   stays green by not being rebuilt). .gitignore gains the .wasm
   entries (`public/clearfile-core.wasm` + the target-side artifact
   is already covered by core-ffi/target/) in the same commit as
   the loader; the blob policy holds by construction (the checker
   scans TRACKED files only — `git ls-files` — scripts/
   check_binary_blobs.py's own header; an untracked .wasm never
   trips it; the .wasm NEVER tracked, the same class as
   fixtures/re/).

7. **The test transfer — exact, with the fixtures and the oracle
   byte-unchanged.** (a) The wasm parity suite keeps web_parity_
   test.mjs's EXACT semantics (probe-replicated): the same 17
   fixtures sorted, `tolerance ?? 0.005`, every `expected` key
   compared as `|wasm - pinned| <= tolerance`, `deductionMethodUsed`
   exact — the wasm side needs NO DEFAULT_INPUT spread (the core's
   `from_json_map` applies its own defaults — the probe passed the
   raw fixture.input JSON and all 17 went green through
   `clearfile_compute`; the suite asserts the raw input shape).
   (b) The bridge suite's transfer under Shape A maps group-by-group
   to the ABI: the TXF exporter groups → `clearfile_export_txf`
   (fixed date params; the suite's D-line regex and the spec-shaped
   reader mirror stay), the cfr groups → `clearfile_encode_envelope`
   / `clearfile_decode_envelope` (the D34 exact ordered warning
   lists from the shared fixtures — probe-verified EXACT through
   wasm), the .tax analysis groups → `clearfile_inspect_tax` (+
   `clearfile_load_and_compute` for the ClearFile-container
   import), the container round-trip → condition 2's export (or,
   under the fallback, the JS residue keeps its round-trip group
   as-is). (c) The suites compile through the existing tsconfig
   pattern: a scripts/tsconfig for the ADAPTER (the .files-build
   CommonJS shape — the adapter is TS; node cannot import it raw)
   with `initFromBytes`; scripts/tsconfig.parity.json RETIRES with
   web_parity_test.mjs (the TS engine is no longer the serving
   engine — its compile path retires with it); scripts/
   tsconfig.files.json retires or narrows to whatever JS residue
   survives (condition 2c). (d) scripts/tsconfig.ai.json's file
   list swaps `engine.ts` → the adapter's type module (tasks.ts
   imports switch per the type-surface ruling); the ai suites'
   runtime never touches wasm (tasks.ts's pure functions) — the
   lazy-loader discipline (4d) keeps them green. (e) The ADR-009
   disposition row records: the parity suites' survival rule
   ("survive as long as any old engine ships anywhere") — post-N6
   Shape A NO old engine ships anywhere (all four platforms +
   web are core-backed); the suites SURVIVE as the wasm parity
   suite over the same fixtures; the TS-engine suite retires with
   the engine it tested. (f) The frozen four files stay tsc-
   checked (root tsconfig includes `**/*.ts` — verified) but out
   of the runtime import graph, each with the superseded-by banner.

8. **The one-session box + the parity-first ordering + the local-
   verification-first discipline (the owner's standing directive —
   now PROVEN satisfiable).** The box is NOT sized for first-run-
   green: the named predicted reds — (a) the BigInt seam (4a), the
   length-wrap trap (4b), the view-detachment trap (4c) — the three
   probe-proven blind-author classes; (b) the freshness-check regen
   dance (the header diff must land same-commit — condition 1c);
   (c) the node/browser init duality (4d); (d) the release job's
   rust step order (the wasm must exist before `npm run build`,
   and the FIRST local `npm run dev` without public/clearfile-
   core.wasm boots to the loader's named error — the dev
   prerequisite is the wasm build, documented in the README row
   or an npm script, zero new npm deps either way). The local
   pre-flight is the ORDER'S FIRST STEP, exactly as this gate ran
   it: fetch the toolchain + component (the proposal's own
   recipe — VERIFIED WORKING end-to-end, including the strip-2
   merge into the tools/rust layout), build the .wasm, run the
   parity suite IN NODE before any CI round (this report's probe
   IS that run: 17/17 green + the probes). Parity-first in-session
   ordering: (i) the ABI additions + the battery tests + the
   header regen land first (CI-green prefix: the wasm build step +
   the wasm parity suite BEFORE the adapter swap — the suites run
   green with the OLD web app still on TS), (ii) then the adapter
   + the consumer swap + the frozen banners + the suite transfer
   (the second CI round), (iii) the release job delta + the
   freeze records (the third). A session death at any boundary
   leaves a green, parity-verifiable lane. The honest CI-fix
   round record lands in the session log (the N3/N4/N5 precedent
   class); the TWELFTH slip surfacing and the terminal freeze
   declaration are the records lane's items (PROD rules them;
   ENG verifies the mechanics are recordable — the STATE.md
   agenda items exist, the session-log pattern exists).

## Risks register

- R-ENG-33 (the wasm trap class, medium, adapter-contained): a
  residual panic in the core traps on wasm (no unwind — probe
  evidence); the containment is the adapter's try/catch + the
  poisoned-module posture (condition 3). The core's caps make the
  class residual, not expected.
- R-ENG-34 (the runner-rustc drift on the .wasm, low): the wasm
  artifact is a function of the ubuntu-latest rustc family (the
  recorded CI-primary stance, the android .so's class); a mid-
  rollout split (the Gradle 9.9.1/9.9.2 precedent) could
  nondeterministically change .wasm bytes run-to-run. Mitigations:
  the rustc family guard, the release profile, the recorded note
  (the tar was never byte-stable).
- R-ENG-35 (the JS-residue fallback, low-medium, pre-ruled): if
  the one-session box tightens, the container export stays JS
  (condition 2c) — the terminal freeze carries ONE named non-core
  function as debt. Recorded, never silent.
- R-ENG-36 (the dead db.ts scaffold, low, pre-existing): the
  PrismaClient + prisma/ + the Hello-world api route are dead
  weight from the scaffold — imported nowhere (measured). Not
  N6's to remove under the freeze discipline (out-of-scope churn
  at the terminal gate), but the register should carry it: the
  next maintenance window's deletion candidate.
- R-ENG-37 (probe footprint, discharged): /tmp/n6-eng deleted at
  report close (df 6.7 GB free — the 1.4 GB probe tree returned);
  zero repo-tree writes except this report; both lockfiles
  untouched by construction (the build ran over /tmp copies); the
  one stray download at the repo root deleted and verified.

## Advisories (non-binding)

- The envelope app-label shift: the wasm path stamps
  `ClearFile 1.0.1` (envelope.rs:831, the Dart-parity writer
  identity) where the TS wrote `ClearFile prototype 0.2`
  (cfr.ts:35). Informational field; both readers ignore it on
  read; the TXF A-line is IDENTICAL (`A ClearFile {year} (web
  prototype)` — txf.rs:787, byte-verified through wasm in the
  probe). Record the label shift in the N6 records; no action.
- The suite-side trap pin (optional, cheap): the wasm parity
  suite builds the panic-hook-test .wasm once and asserts
  `clearfile_test_guard_panic` THROWS RuntimeError (pinning the
  target fact so a future toolchain change to wasm unwinding
  gets NOTICED rather than silently altering the contract).
- The local web smoke (scripts/web_smoke.py — local-only, never
  in CI) gains the wasm-boot assertion for free once the swap
  lands: it already drives the sample return through the UI, so
  the boot gate + a compute-through-wasm round trip is
  exercised browser-side in the session, complementing the node
  parity suite in CI.
- The dev experience: consider an npm script (`wasm` or
  `predev`) wrapping the wasm build + the public copy — zero new
  npm DEPENDENCIES (a script line, not a package), and it makes
  `npm run dev` work on a fresh clone without reading the README
  first.
- The frozen files' banner wording should name the wasm adapter
  as the successor (and the ADR-016 retirement date), so the
  transition artifact is self-describing for the terminal-freeze
  reader.
- The TWELFTH slip surfacing + the v2.0.0-territory freeze
  declaration + the D30/D42 parking posture: PROD's lane rules
  the content; ENG notes only that the terminal freeze
  declaration must name the R-ENG-35 residue if the fallback
  fires (the freeze with a named debt, never a silent one).

## Files read + verification log

Files read (all at tip 1dd84dc): harness/adversarial/ROLES.md (the
mandate), harness/adversarial/reports/2026-11-27-n5-engineering.md
(all 529 — the format template), core-ffi/Cargo.toml (all 65), core-
ffi/src/lib.rs (all 566 — the jni gate at :56-57 excludes the shim
on wasm; the guard at :87-102; to_owned_buffer :147-154; the free
:541-548; the panic hook :558-565), core-ffi/clearfile.h (all 107),
core-ffi/tests/boundary.rs (the test census), core/src/envelope.rs
(the encode/app-label sections), core/src/txf.rs (export_txf
:781-816 + ts_record), core/src/tax_inspect.rs (export_tax_
container :762, TAX_CONTAINER_README :104, the summary constants),
core/src/json.rs (the caps), src/lib/tax/engine.ts (all 444),
src/lib/tax/config.ts (via imports), src/lib/files/cfr.ts (all
251), src/lib/files/txf.ts (all 85), src/lib/files/taxfile.ts (all
390), src/lib/store.ts (all 352), src/lib/db.ts (all 14 — dead
code), src/lib/ai/tasks.ts (all 182), src/components/clearfile/
steps.tsx (the compute/render sites), filemenu.tsx (all 250),
ai-ui.tsx (the compute sites :120-160, :440-470), src/app/page.tsx
(all 84 — the boot gate), src/app/layout.tsx, src/app/api/route.ts,
next.config.ts (all 19 — output: "standalone"), tsconfig.json (the
include list), package.json (all 93 — the build script's standalone
copy; zero-dep claim verified), scripts/web_parity_test.mjs (all
107 — the tolerance semantics), scripts/txf_taxfile_test.mjs (all
369 — the 11 groups), scripts/tsconfig.parity.json,
scripts/tsconfig.files.json, scripts/tsconfig.ai.json,
scripts/fetch_rust_toolchain.sh (all 78), scripts/rust_toolchain_
manifest, scripts/check_binary_blobs.py (the header + allow-list
posture), .gitignore (the build-output blocks),
.github/workflows/hygiene.yml (the suites job :37-136, the android
job :245-394 — the wasm-lane template), release.yml (the nextjs-web
job :498-573 + the release job), pages.yml (all 97 — the Flutter
web deploy), harness/memory/STATE.md (:363-394 — the N6 agenda),
ROADMAP.md (the N6 + epilogue sections), SESSION_LOG.md (the tail
— the N5 close + the standing directives), CONSENSUS.md (:1684-
1700 — the N6 pre-positioning), DEBT.md (the register rows).

Runs (this session, tip 1dd84dc, scratch /tmp/n6-eng, DELETED at
close; the repo tree verified clean except the sibling lane
reports + this one):

1. df first: 6.7 GB free; node v24.22.3; NO cargo/rustc on PATH
   (the recycled-instance posture the proposal names).
2. The toolchain fetch: the pinned 1.100.0 tarball (sha-pinned
   manifest row) + rust-std-1.100.0-wasm32-unknown-unknown.tar.xz
   from the same dist/2026-11-12 tree (both HTTP 200, fetched);
   the strip-2 merge into one tools/rust layout → `cargo 1.100.0
   (3acc79c0c 2026-11-05)` + `rustc 1.100.0 (0ef1bc386 2026-11-09)`
   + the wasm32 rustlib present.
3. THE WASM BUILD: core-ffi copied to /tmp, `cargo build --locked
   --release --target wasm32-unknown-unknown` → GREEN in 22.85 s
   (cbindgen 0.29.4 fetched + built as the build-dep; the jni shim
   cfg-excluded on wasm by lib.rs:56 — no wasm-side jni tree);
   artifact `clearfile_core_ffi.wasm` = 299,577 bytes; the wasm
   link line OBSERVED carrying `libpanic_abort` + `-z stack-size
   1048576 --stack-first`.
4. The export census: memory + all 10 ABI functions exported
   (compute, decode_envelope, encode_envelope, export_txf, free,
   import_txf, inspect_tax, last_error, load_and_compute,
   palette_scheme_role) — the flat C ABI surfaces verbatim.
5. THE 17-FIXTURE PARITY through wasm (the exact web_parity
   semantics: tolerance ?? 0.005, deductionMethodUsed exact): **17
   fixtures, 0 field failures** — the probe is the transferred
   suite's dry run.
6. The ABI behavior probes through wasm: the 512 MiB+1 bound →
   NULL + the verbatim named message; the empty-payload input via
   (ptr, 0) accepted; the binary interior-NUL input through
   inspect_tax → honest analysis JSON; the D34 migration warnings
   through decode_envelope → the EXACT ordered list (the fixture's
   own four, byte-compared); export_txf through wasm → the exact
   V042 header/A/D lines (the A-line byte-identical to the TS);
   palette_scheme_role → opaque ARGB. ALL GREEN.
7. THE BIGINT TRAP: clearfile_export_txf called with the year as
   a plain Number → `TypeError: Cannot convert 2026 to a BigInt`
   (the i64 param seam); with BigInt(2026) → correct D-line.
8. THE LENGTH-WRAP TRAP: a len of 2^32+16 passed from JS → the
   callee silently saw len=16 (ToUint32 wrap).
9. THE PANIC GUARD ON WASM: the panic-hook-test build's
   clearfile_test_guard_panic() → **RuntimeError: unreachable**
   (no unwind — libpanic_abort), last_error "" — the sentinel
   contract does not hold on wasm; the post-trap state
   indeterminate (one shape ran on; another trapped OOB after the
   panic path grew memory 17→18 pages mid-trap).
10. THE ALLOC/FREE DESIGN PROBES (a /tmp probe crate — clearfile_
    alloc exactly as proposed + the length-paired clearfile_dealloc
    alternative, both extern over the same core-ffi rlib): the
    text-payload NUL-at-end free via clearfile_free ×50 → healthy;
    **the interior-NUL free via clearfile_free → TRAPPED at
    iteration 1** (panic inside __rdl_dealloc → abort); the no-NUL
    free ×20 → NO trap (the silent wrong-size class); **the
    length-paired dealloc ×200 with interior NULs + compute
    health checks every 50 → ALL HEALTHY**; alloc(0) → ptr=1 (the
    dangling alignment pointer, not an allocation).
11. At report close: /tmp/n6-eng deleted (df 6.7 GB avail);
    `git status --short` →

```
?? harness/adversarial/reports/2026-11-27-n6-legal.md
?? harness/adversarial/reports/2026-11-27-n6-product.md
?? harness/adversarial/reports/2026-11-27-n6-security.md
?? harness/adversarial/reports/2026-11-27-n6-engineering.md
```

(the three sibling N6 lane reports are the parallel-lane reality,
none read per the isolation rule; the fourth line is this report —
the only tree change this lane made).
