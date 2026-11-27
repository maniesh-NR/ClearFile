# ADV-ENG — N6 exit gate (2026-11-27, Task N6-EXIT-ENG)

Scope: the ENG lane of the N6 EXIT gate — the epilogue's TERMINAL gate's
exit. Tip 8387202 (f295a27 = the lane, 8387202 = the records) verified
at start; the delta under review is `git diff 1dd84dc..HEAD` (32 files,
+3,734/−200). My entry report's 8 conditions (2026-11-27-n6-
engineering.md) + the CONSENSUS N6 entry record's rulings + the
orchestrator reconciliations (a)–(f) are the contract this gate
verifies. Every condition was re-verified by RUNS, not reads alone: the
local toolchain (tools/rust 1.100.0 + the wasm32-std component, both
wasm variants rebuilt, the header regen forced + diffed, the battery
re-run, all five node suites re-run, tsc re-run) — the same runs the
lane itself is recorded to have made, reproduced independently at the
exit. The tree stays untouched except this report (all build outputs
land in gitignored paths; verified clean at close).

**Execution facts confirmed as recorded:** the lane closed FIRST-GREEN
(run 45991816001 on f295a27, all EIGHT jobs — ONE CI round, the honest
datum against N3=11/N4=5/N5=4); the local pre-run (wasm_parity 17/17 +
the allocator 100-cycle + the params assertion + the bridge 11/11 + the
AI suites 5/5+4/4 + tsc clean) is corroborated by the artifact timeline
(the plain .wasm at 11:20 predates the 11:35:50 push) and fully
reproduced by this gate.

**THE VERDICT'S SHAPE: the engineering core of the lane is SOUND —
every one of my 8 conditions' substantive requirements is discharged and
probe-verified — but the exit pass found TWO moderate defects (a dead CI
assertion + a record-vs-code coverage mismatch) and three minor
discipline gaps, all one-commit, close-rider-class, all in the
suite/records layer, none in the shipped core/adapter logic. At a
TERMINAL gate whose next step is the freeze declaration, these must be
closed WITH the freeze, never frozen in.**

## The condition-by-condition discharge record (each verified by run)

1. **The length-paired alloc/dealloc — DISCHARGED (probe-verified on
   both sides).** The committed shape: `clearfile_alloc(len)` =
   `vec![0u8; len + 1]` (the len+1 zeroed tail — lib.rs:576-580) with
   `input_file_too_large(len as u64)` checked BEFORE the allocation
   (the shared 512 MiB bound + the shared named message; the bound-first
   also protects the +1 arithmetic from overflow), and
   `clearfile_dealloc(ptr, len)` = `Vec::from_raw_parts(ptr, len+1,
   len+1)` (lib.rs:593-603 — the EXACT original layout; interior NULs
   irrelevant, the recorded length governs). The header regenerated
   through the config-emitted flow (build.rs → cbindgen =0.29.4) — the
   freshness LOCALLY RE-PROVEN at this gate: `touch core-ffi/build.rs`
   + rebuild → `git diff` over clearfile.h = ZERO (and the committed
   header carries the four new declarations with the paired-release
   documentation: "Freed ONLY by clearfile_dealloc with the SAME len —
   NEVER clearfile_free"). The trap-class proof, both sides: the
   battery's `alloc_dealloc_length_pair_survives_interior_nuls`
   (boundary.rs:603 — >=100 cycles, ALL-zero payloads = every byte an
   interior NUL, + the bound refusal with INPUT_TOO_LARGE_MESSAGE +
   the dealloc(NULL) no-op) ran NATIVE 12/12 green (re-run locally);
   `wasm_parity_test.mjs`'s 100-cycle module-readiness proof (100
   cycles of `analyzeTaxFile(new Uint8Array(len))` — an all-NUL payload
   through the REAL wasm ABI, the adapter's withInput running the
   write+length-paired-release cycle, wasmReady() asserted before/after
   — "ok" line printed in this gate's local run) runs IN CI on every
   push. The entry gate's probe (interior-NUL free via clearfile_free
   TRAPS at iteration 1; the length-paired dealloc ×200 HEALTHY) stands
   as the ruling evidence; the committed code implements exactly the
   sound alternative. ONE benign deviation from my condition's letter,
   recorded as sound: my condition 1(a) required `clearfile_alloc` to
   REFUSE len==0 — the committed +1-tail design makes len==0 a REAL
   1-byte allocation instead (never the Vec's dangling alignment
   pointer — the concern's actual class), `dealloc(ptr, 0)` =
   from_raw_parts(ptr, 1, 1) = the exact `vec![0u8; 1]` layout, and the
   empty-input path is exercised in CI through the bridge suite's
   `analyzeTaxFile(new Uint8Array(0))` group (green). The spirit — no
   dangling pointer ever crosses — is discharged by a sound mechanism.

2. **The container-export channel — DISCHARGED at the ABI + battery +
   adapter layers; ONE COVERAGE/RIDERS FINDING at the suite layer
   (rider 2).** The ABI: `clearfile_export_tax_container(envelope_text,
   len, out_bytes, out_capacity, out_len)` (lib.rs:616-648) — the
   caller-allocated length-out binary channel, `*out_len = needed`
   written on EVERY path (before the too-small return 1), rc
   0/1/−1 exactly as the header documents, binary never riding the
   CString channel (the C side's `as_utf8` is over the PRE-SERIALIZED
   envelope text — the caller's own `clearfile_encode_envelope`
   output). The battery's `container_export_is_the_length_out_binary_
   channel` (boundary.rs:630): the probe call (capacity 0 → rc 1, the
   needed size, last_error stays ""), the real call, the interior-NUL
   assertion, and the ROUND TRIP back through `clearfile_load_and_
   compute` reproducing the filing — green native 12/12. The adapter's
   dance (core.ts:528-553) verified line-by-line AND end-to-end: the
   4-byte lenSlot via `clearfile_alloc(4)`, the probe call, the
   DataView read (`getUint32(lenSlot, true)` — LE, wasm32's endian)
   BEFORE the next memory-growing call (`clearfile_alloc(needed)`
   follows at :539), the second call, the copy-out
   (`new Uint8Array(new Uint8Array(...))` — a true JS-owned copy, immune
   to later detach), both deallocs length-paired in the finallys. My
   end-to-end probe through the compiled adapter: 1,822-byte container,
   ZIP magic + interior NULs present, `loadAndCompute` returns the
   same filing ("the ClearFile exchange container (.tax)"),
   `analyzeTaxFile` → clearfileContainer=true, 2 entries, filing
   present, module still ready. **The finding:** NO suite exercises the
   adapter's `exportTaxContainer` — the app's actual .tax-export writer
   (steps.tsx:776, filemenu.tsx:71) and the most intricate adapter dance
   has zero mechanical coverage (the bridge suite's ClearFile-container
   group at txf_taxfile_test.mjs:224-242 builds via the SUITE's own
   makeZip + serializeCfr — the retired shape carried forward), and the
   CONSENSUS reconciliation (d) RECORDS the opposite ("the bridge
   suite's ClearFile-container fixture now builds via the adapter's own
   exportTaxContainer"). Record-vs-code mismatch + a coverage gap on
   the writer. My probe proves the swap is green (rider 2's fix is one
   group's rewrite); the function itself is CORRECT today — the gap is
   the pin, not the behavior.

3. **The trap ruling — DISCHARGED in the adapter (end-to-end
   probe-proven); ONE FINDING in the suite-side pin (rider 1).** The
   adapter: `mapped()` (core.ts:311-321) catches exactly
   `WebAssembly.RuntimeError` → poisons the instance → rethrows
   `CoreError('The operation failed unexpectedly — an internal error
   occurred.')` (the guard's own wording family, lib.rs's message
   surface); `assertReady()` refuses all calls on a poisoned module
   with the same wording; `wasmReady()` exposes the poison to the boot
   gate. END-TO-END PROOF at this gate: a hand-assembled 182-byte wasm
   module (the minimal export surface with `clearfile_compute` =
   `unreachable`) loaded through the REAL compiled adapter → the
   trapped call surfaces `CoreError | The operation failed
   unexpectedly — an internal error occurred.` (NOT a raw
   RuntimeError), `wasmReady()` → false, and every subsequent call
   refuses with the same wording. The CI's panic-hook build ORDER
   verified locally: panic (`--features panic-hook-test`) → cp to
   `clearfile_core_ffi_panic.wasm` → the plain build — the panic
   module SURVIVES (318,896 bytes, 16 exports INCLUDING
   `clearfile_test_guard_panic`, zero imports) and the plain module is
   clean of the hook (318,715 bytes, 15 exports, the test hook absent)
   — the shipped artifact never carries the test hook. The trap FACT
   re-proven on the committed panic module: `clearfile_test_guard_
   panic()` → `RuntimeError | unreachable` (never a sentinel return)
   — catch_unwind does not transfer to wasm32, exactly as ruled.
   **The finding:** `wasm_parity_test.mjs`'s trap assertion (:73-92)
   NEVER RUNS — its raw `WebAssembly.instantiate(readFileSync(...))`
   resolves the spec's bufferSource shape `{module, instance}`
   (probe-proven: "resolve keys: module,instance"), so
   `panicInstance.exports` is `undefined` → the 'export missing'
   TypeError → the outer catch → the SKIP line. This gate's local run
   of the suite printed "skip the trap assertion (no panic-hook module
   built)" WITH BOTH module paths passed as argv — the module WAS
   built; the assertion is dead code, and its skip message misleads
   (the CI run 45991816001's suites job necessarily skipped it too —
   Node 20 is the same spec-conforming shape). The irony is exact:
   this is the precise bug class reconciliation (f) fixed in the
   adapter (the both-shapes handling at core.ts:274-282) — re-introduced
   in the suite's own raw instantiate. The assertion, once fixed, is
   green (my direct probe through `res.instance.exports` traps
   correctly).

4. **The adapter disciplines — ALL FIVE DISCHARGED; one discipline
   wrinkle (rider 3).** (a) BigInt year: `BigInt(now.getFullYear())` at
   core.ts:467 (the i64 seam). (b) The length refusal: `len >=
   0x1_0000_0000` → RangeError before any alloc (core.ts:335) — the
   adapter never forwards a caller-supplied length across the ToUint32
   wrap. (c) No cached views: `withInput` re-derives the view AFTER
   alloc (core.ts:343); `readCString` takes a fresh
   `new Uint8Array(w.memory.buffer)` every call, scans bounded by
   `buf.length`, hard-fails at the memory's end rather than scan past
   it; `exportTaxContainer` reads the lenSlot through a fresh DataView
   before the next growth-capable call and copy-outs to JS-owned
   memory. (d) The lazy dual init: no import-time side effects (module
   top level is constants only — the AI suites import the adapter
   transitively through tasks.ts and ran green with no wasm init);
   `initWasmFromBuffer` (the node/suites path) + `initWasm` (the
   browser `fetch('/clearfile-core.wasm')` path); the sync wrappers
   throw the named not-ready error before init (never user-visible
   behind page.tsx's boot gate — which composes `mounted || coreReady`
   and surfaces a load error in the Splash, verified in the delta).
   (e) The both-shapes instantiate handling (reconciliation (f)):
   core.ts:274-282 — verified live (the {module, instance} shape is
   what Node actually resolves; my probes hit both forms). Zero npm
   dependencies: the adapter imports TYPES only from '../tax/config'
   (erased at emit; the module's own display constants carried locally
   per the tsconfig discipline) — package.json's dependency arrays
   byte-untouched in the delta. **The wrinkle:** withInput's and
   exportTaxContainer's `finally { w.clearfile_dealloc(...) }` blocks
   run on the POISONED instance after a trap — a post-trap call, the
   exact class the poison discipline exists to refuse; PROBE-PROVEN
   with a hand-assembled module whose dealloc is also `unreachable`:
   the in-flight call then surfaces a RAW `RuntimeError | unreachable`
   that MASKS the mapped CoreError wording (the poison flag itself is
   still set — subsequent calls refuse correctly; only the in-flight
   surfaced error class breaks the "never a new class" contract, and
   only in the double-residual case trap+dealloc-trap).

5. **The suites-job wasm build — DISCHARGED in substance; ONE SHAPE
   GAP (rider 4).** The step: `rustup target add
   wasm32-unknown-unknown` → the panic build (`--locked --release
   --features panic-hook-test`) → cp → the plain build (`--locked`) →
   the `test -f` emission check → the import-empty guard (node reads
   the module, asserts ZERO `WebAssembly.Module.imports` — the
   strongest no-network proof, the otool-exact-list analogue;
   re-proven locally: "import guard: ok — the wasm module has zero
   imports", 15 exports). The wasm build runs BEFORE the transferred
   node suites in the same job; conflict-free with `cargo test
   --locked` (core/, a different manifest+target). Release profile —
   the right call (the artifact the web serves). **The gap:** my
   condition 5 required the step to carry the android-lane's rustc >=
   1.95 family guard ("the new step carries it") — the committed step
   does NOT (rustup + --locked + the import guard only; the suites
   job's core-test step remains guard-less too). Fail-closed still
   holds (a runner rustc drift reds the cargo build itself — the
   guard's absence costs legibility, not safety), but the condition's
   letter — the android job's exact fail-closed-first form — is one
   block away.

6. **The release-byte-freeze — DISCHARGED as ruled.** release.yml and
   pages.yml are ABSENT from the delta (byte-unchanged — PROD's
   byte-frozen ruling won over the narrow-amendment alternative; the
   nextjs-web job is recorded STALE-BY-DESIGN in the CONSENSUS N6
   entry record's ruling (8): nothing ships at N6, any tag before the
   v2.0.0-GA rework is an owner decision that first resolves the
   web-asset question). The stale job is honestly-stale by
   construction: the adapter fetches at RUNTIME (no build-time
   dependency), so the frozen job's `npm run build` stays green and a
   tarball-deployed app would boot to the adapter's NAMED load error
   — never a silent wrong behavior. .gitignore gains exactly
   `/public/clearfile-core.wasm` (the target-side artifact already
   covered by the core-ffi/target/ block); the blob policy holds by
   construction and by re-run: `check_binary_blobs.py` scans TRACKED
   files only (`git ls-files`, its own header) — zero .wasm files
   tracked (`git ls-files | rg '\.wasm$'` → none) and the checker runs
   clean with both .wasm artifacts present in the working tree.

7. **The test transfer — DISCHARGED, exact.** (a) Fixtures + oracle
   BYTE-UNCHANGED: `git diff 1dd84dc..HEAD -- fixtures/ scripts/
   verify_golden_fixtures.py` → empty. (b) The tolerance semantics
   DIFFED against the retired suite: identical — `Number(fixture.
   tolerance ?? 0.005)`, the DEFAULT_INPUT spread merge (KEPT — the
   exact-semantics transfer; my entry condition's parenthetical
   observation that the raw-input shape also passes stands as
   advisory, not required), `deductionMethodUsed` exact-string,
   `|wasm − pinned| <= tolerance` per key, the same sorted-fixture
   loop, the same no-fixtures exit-2. The wasm suite swaps the engine
   call (`core.compute(input)` through the wasm adapter) for the TS
   call — the one intended change. web_parity_test.mjs retired WITH
   its subject: the +9-line delta is exactly the RETIRED banner (the
   frozen-transition-artifact class), the body byte-unchanged.
   (c) The bridge suite 11/11 green (re-run locally): the TXF v042
   groups, the container groups (the suite's own STORE-ZIP builder —
   the ENG-1 crafted-file class: a from-spec re-expression of the
   STORE-only ZIP structure, NOT a copy of the retired app writer —
   verified against taxfile.ts's makeZip: same format constants,
   different expression), the envelope groups, and the D34 migration
   groups asserting the EXACT ORDERED warning lists from the shared
   fixtures (byte-unchanged) — probe-class: the same lists the Dart
   suite asserts. The divergence-5 legacy-flat assertion changed from
   the retired web-reader's `warnings.some(...'not carried by the web
   prototype')` to `assert.deepEqual(warnings, [])` — the
   WARNING-FREE flat lift through the core, exactly reconciliation
   (e), with the rationale recorded in the suite's own comment (the
   core's documented divergence 5: web-reader-only strings not
   ported). (d) The ADR-009 disposition row honored: the TS engine
   retired per ADR-016's conversion day (the four frozen files carry
   the dated terminal banner, byte-frozen from this edit, out of the
   runtime import graph — `rg` over src/ shows ZERO live imports of
   them — and still tsc-checked: the root `npx tsc --noEmit` over the
   `**/*.ts` include list runs CLEAN, re-verified at this gate);
   config.ts's TABLE removed (labels/formatters live on; the retired
   files reference config.ts TYPES only, so the removal breaks
   nothing); the parity suites SURVIVE as the wasm parity suite over
   the same fixtures — the row's rule, executed. (e) The tsconfigs
   re-pointed correctly: parity.json now compiles the adapter
   (config.ts + wasm/core.ts → .parity-build, es2020 — the wasm
   suite's import path matches); files.json narrows to the adapter
   (CommonJS → .files-build — the bridge suite's initWasmFromBuffer
   path); ai.json swaps engine.ts → wasm/core.ts (tasks.ts's type
   surface; the AI suites ran 5/5+4/4 green through it). The engine's
   compile path retired WITH the engine (parity.json re-used for the
   new subject rather than retired — the honest reuse; my condition's
   "retires" was the wrong verb, the discipline it protected — no
   compile path for a retired serving engine — holds).

8. **The ONE-session box — DISCHARGED, honestly run.** ONE CI round:
   run 45991816001 on f295a27, all EIGHT jobs, FIRST-GREEN (the
   honest datum: N3=11, N4=5, N5=4, N6=1 — the local-verification-
   first discipline my entry condition demanded, PROVEN the
   difference it makes). The local pre-run BEFORE the push is
   corroborated: the plain .wasm build at 11:20 predates the 11:35:50
   lane commit (the suites' green outputs re-produced independently by
   this gate: wasm_parity 17/17 + the allocator 100-cycle + the
   params assertion + the bridge 11/11 + the AI suites 5/5+4/4 + tsc
   clean — every one re-run above). The predicted-red classes (the
   BigInt seam, the length-wrap, the view-detachment) were all
   pre-proven at the entry gate and none fired — the probe-first
   posture's payoff, recorded. TWO named residuals, both rider-class
   (below): the dev-prerequisite documentation (my condition 8(d): the
   README row or the npm script — NEITHER landed; a fresh clone's
   `npm run dev` boots to the adapter's honest named 404 error, but
   the developer has no documented build path; the README
   honest-surface rewrite already rides with the freeze declaration —
   the dev row joins it, rider 5) and the local re-run ordering (the
   11:48-11:52 artifacts show a post-push local re-run in the CI
   order — the pre-push parity run's outputs were overwritten; the
   corroborating evidence is the 11:20 .wasm + the green re-runs).

**The orchestrator reconciliations, verified:** (a) the plain un-gated
exports — verified in the module census (15 plain/16 panic exports;
the header's four new declarations; the battery proves alloc/dealloc +
container on every lane — params_json is the one addition without a
native battery test, covered through the wasm lane it serves;
recorded as a nit, not a defect: its only consumer is the wasm
adapter, and the wasm suite pins it in CI). (b) **clearfile_params_json
— ACCEPTED, with the parity mechanically proven at this gate:** the
table's one true source is the core (config.ts's table removed); the
display walk stays adapter-side glue (bracketWalk reads the
core-served table; zero parameter logic platform-side); the
serialization mirrors the TS interface's field names/per-status keys
exactly, the infinite terminal rung as null (strict JSON cannot carry
Infinity). PROBE (this gate): the retired TS TY2025 (compiled from
the 1dd84dc blob) vs the wasm-served `params()` — value-for-value
IDENTICAL across all 27 top-level fields (the only diffs are
JSON-irrelevant object key order in 5 per-status maps); the wasm
suite's params assertion (year, standard deduction, SALT cap, the
first rate, the null terminal rung) green in CI. The addition is the
honest fourth export — better than the alternative (a duplicated
platform-side table = the D34 divergence class the epilogue exists to
kill). (c) the null-vs-infinite terminal rung — verified in the
serialization + the suite assertion. (d) the suite-side STORE-ZIP
builder — the crafted-file class VERIFIED (above, 7c) — but see
finding/rider 2 (the record's first clause does not match the code).
(e) the warning-free flat lift — verified (7c). (f) the both-shapes
instantiate handling — verified in the adapter (4e) — and its
ABSENCE in the suite's own raw instantiate is finding/rider 1.

## Riders (the close riders — discharged with the freeze declaration, never after it)

1. **Fix the dead trap assertion** (wasm_parity_test.mjs:75): read the
   panic export through the resolved shape — `const panicInstance =
   await WebAssembly.instantiate(...); const inst =
   panicInstance instanceof WebAssembly.Instance ? panicInstance :
   panicInstance.instance;` (the adapter's own both-shapes form) — so
   `clearfile_test_guard_panic` resolves and the assertion RUNS on the
   CI-built panic module (the output flips from "skip the trap
   assertion (no panic-hook module built)" — which today MISLEADS, the
   module IS built — to "ok the trap ruling: ..."). One line; the
   assertion is green once fixed (this gate proved the trap through
   `res.instance.exports` → `RuntimeError | unreachable`); re-run the
   suite locally, no CI-shape change.

2. **Reconcile the CONSENSUS (d) record with the code — either
   direction, never both wrong:** PREFERRED: the bridge suite's
   ClearFile-container group (txf_taxfile_test.mjs:224-242) builds its
   fixture through the ADAPTER's `exportTaxContainer(filing)` (the
   app's own writer — my end-to-end probe proves the swap is green:
   exportTaxContainer → loadAndCompute/analyzeTaxFile round-trip with
   the filing back), keeping the suite's STORE-ZIP builder for the
   synthetic non-ClearFile shapes (the Intuit-modern, low-entropy,
   non-ZIP groups) — this also closes the coverage gap on the
   adapter's most intricate dance (the lenSlot/probe/DataView/copy-out
   path), which today no suite pins. ALTERNATIVE: amend the CONSENSUS
   reconciliation (d) sentence to what the code does (the suite's
   STORE-ZIP builder serves ALL container fixtures; the adapter's
   exportTaxContainer is exercised only by the app's click paths) and
   register the missing pin as a debt row. The record-as-written
   claims coverage the code does not have — at a terminal gate that
   must not freeze in.

3. **Close the poisoned-module finally discipline** (src/lib/wasm/
   core.ts:345-347, 546-551): the `finally { w.clearfile_dealloc(...) }`
   blocks are post-trap calls on a poisoned instance; if the post-trap
   dealloc itself traps (the indeterminate-heap class — probe-proven
   at this gate with a hand-assembled module: the raw RuntimeError
   MASKS the mapped CoreError for the in-flight call), the surfaced
   error is the new class the trap contract forbids. Guard each
   dealloc on the poison flag (`if (!poisoned) w.clearfile_dealloc(...)`)
   or swallow the RuntimeError around it — the buffer is doomed with
   the module anyway. One line per site; probe-provable with the same
   hand-assembled module shape (this gate's probe harness is in the
   verification log).

4. **Add the rustc >= 1.95 family guard to the suites job's wasm32
   step** (the android job's exact fail-closed-first form, hygiene.yml
   :307-319): the committed step carries rustup + --locked + the
   import guard but not the family guard my condition 5 specified.
   Legibility on runner drift (a cryptic cargo red instead of the loud
   named refusal); fail-closed already holds. One block, copy the
   android lane's parsed form verbatim.

5. **The wasm dev-prerequisite documentation** (my condition 8(d)):
   neither the README row nor the npm script landed. The README
   honest-surface rewrite already rides with the freeze declaration
   (the entry record's close riders) — the rewrite's web section must
   name the dev prerequisite (build the .wasm + copy to public/ before
   `npm run dev`, or land the one-line npm script — zero new npm
   dependencies either way), so a fresh clone has a documented path to
   a running app. Documentation-class; rides with the existing
   rewrite.

## Risks register

- R-ENG-33 (the wasm trap class) — UNCHANGED, adapter-contained; the
  end-to-end probe at this gate proves the mapped()+poisoned posture
  works live; rider 3 closes the in-flight masking wrinkle.
- R-ENG-34 (the runner-rustc drift) — stands; rider 4 restores the
  loud-drift half of the mitigation.
- R-ENG-35 (the JS-residue fallback) — RESOLVED-UNUSED: the primary
  container export landed and works; no residue, no debt row owed.
- R-ENG-36 (the dead db.ts scaffold) — stands (registered, out of
  scope at this gate).
- R-ENG-38 (NEW, low): the suite-layer assertion debt — riders 1+2
  are the whole of it; both fixes are green-proven by this gate's
  probes before being demanded.
- R-ENG-39 (NEW, low): the wasm_parity trap block's SKIP message
  misleads until rider 1 lands (it attributes a code defect to a
  missing artifact); resolved by rider 1 itself.

## Advisories (non-binding)

- The SESSION_LOG's N6 session entry (the records lane, at the close)
  should state the honest CI-fix datum comparison explicitly —
  "N6=1 round (first-green) vs N3=11 / N4=5 / N5=4" — the standing
  records-honesty precedent (the N4/N5 exits corrected exactly this
  undercount/omission class).
- The suite header comment promises "stable memory size" for the
  100-cycle allocator proof; the group asserts readiness (wasmReady
  before/after + no trap), not the byteLength. One-word comment fix
  or add the size assertion — either is fine.
- `clearfile_free`'s header comment names the libc-UB direction but
  not the reverse (an alloc'd buffer freed via clearfile_free —
  unsound); the alloc's comment names both directions. Cosmetic doc
  symmetry nit on the next header-touching commit.
- `core/src/params.rs`'s to_json carries a dead `let _ = STATUS_KEYS;`
  (the helpers use inline arrays) — a clippy-class nit for the next
  core commit, never a freeze-blocker.
- The web_smoke wasm-boot advisory (entry report) was not taken —
  optional, stands.
- The panic module's Post-push local re-run (11:48 artifacts) suggests
  the session attempted the trap assertion locally; the {module,
  instance} skip means it silently "passed" as a skip. Rider 1 makes
  the next such attempt honest.

## Files read + verification log

Files read (at tip 8387202): the full delta (git diff 1dd84dc..HEAD —
all 32 files' patches), core-ffi/src/lib.rs (the new exports :549-674),
core-ffi/clearfile.h (all 157 — the four declarations + the paired-
release docs), core-ffi/tests/boundary.rs (the 12-test census + the
two new tests :592-701), core/src/params.rs (to_json :107-200),
scripts/wasm_parity_test.mjs (all 176), scripts/txf_taxfile_test.mjs
(all 433), scripts/web_parity_test.mjs (the retired banner + the body
vs the 1dd84dc blob), scripts/tsconfig.{parity,files,ai}.json,
scripts/fetch_rust_toolchain.sh + scripts/rust_toolchain_manifest (row
2), scripts/harness_check.sh, scripts/check_binary_blobs.py (the
header), src/lib/wasm/core.ts (all 591), src/app/page.tsx, src/
components/clearfile/{steps,filemenu,ai-ui}.tsx, src/lib/ai/tasks.ts,
src/lib/tax/{config,engine}.ts + src/lib/files/{cfr,txf,taxfile}.ts
(the retirement banners + the import census), src/lib/files/taxfile.ts
(the retired makeZip — the crafted-file comparison), package.json (the
scripts + dependency arrays), tsconfig.json, .gitignore,
.github/workflows/hygiene.yml (the suites job :37-140 + the android
job's guard/freshness/battery forms), README.md, harness/adversarial/
CONSENSUS.md (the N6 entry record :2211-2318 — the rulings + the
reconciliations (a)-(f)), harness/memory/ROADMAP.md (the N6 execution
record :778-801), harness/memory/DECISIONS.md (ADR-009's disposition
row :517 + ADR-016), harness/memory/STATE.md (:363-394), SESSION_LOG.md
(the tail), DEBT.md (the register). My entry report (all 585 — the
conditions + the format). The sibling N6 exit reports NOT read (the
parallel-isolation rule).

Runs (this session, tip 8387202, the local toolchain at tools/rust —
cargo/rustc 1.100.0 + the wasm32-std component, all verified present
first; all outputs to gitignored paths; /tmp probes deleted at close):

1. The wasm rebuild in the CI order: panic variant → cp → plain —
   both artifacts fresh (318,896 / 318,715 bytes; cargo fingerprints
   clean = the committed source's builds).
2. THE HEADER FRESHNESS: `touch core-ffi/build.rs` + rebuild (cbindgen
   =0.29.4 re-ran) → `git diff` over core-ffi/clearfile.h = ZERO; the
   tree clean after every build.
3. wasm_parity_test.mjs (both module paths): the allocator 100-cycle
   "ok", the params table "ok", **"skip the trap assertion (no
   panic-hook module built)"** (finding → rider 1), 17 fixtures, 0
   field failures, exit 0.
4. The panic-module probe: 16 exports (incl. clearfile_test_guard_
   panic), 0 imports; `WebAssembly.instantiate(bytes)` resolves
   `{module, instance}` (the keys printed); through `.instance.exports`
   the guard panic → `RuntimeError | unreachable` (the trap fact +
   the suite bug both proven in one probe).
5. The plain-module import-empty guard (the CI form): ok, 0 imports,
   15 exports (no test hook — the shipped artifact clean).
6. txf_taxfile_test.mjs: 11/11 groups passed, exit 0.
7. ai_cascade_fixture_test.mjs 5/5 + ai_injection_test.mjs 4/4, exit 0.
8. `cargo test --locked --manifest-path core-ffi/Cargo.toml --features
   panic-hook-test`: **12 passed, 0 failed** (the battery, native).
9. `npx tsc --noEmit`: clean, exit 0 (the retired files still checked).
10. `python3 scripts/check_binary_blobs.py`: clean (458 tracked, 28
    allow-listed; both .wasm files untracked — never blob-checked).
11. `bash scripts/harness_check.sh`: 0 failures (the checker families:
    FUNDED 0, N-outcomes 10 — updated with the lane, verified).
12. THE PARAMS PARITY PROBE: the retired TS TY2025 (compiled from the
    1dd84dc blob of config.ts) vs the wasm-served `params()` —
    value-for-value identical across all 27 top-level fields (the 5
    per-status key-order diffs are JSON-irrelevant); /tmp tree deleted.
13. THE ADAPTER CONTAINER PROBE: exportTaxContainer(filing) through
    the compiled adapter → 1,822 bytes, ZIP magic + interior NULs →
    loadAndCompute returns the same filing → analyzeTaxFile
    clearfileContainer=true, 2 entries, filing present → wasmReady()
    true. The dance is CORRECT (rider 2 is the pin, not the behavior).
14. THE TRAP-MAPPING PROBE (a hand-assembled 182-byte module: the
    minimal export surface with clearfile_compute = unreachable):
    through the real adapter the trapped call surfaces `CoreError |
    The operation failed unexpectedly — an internal error occurred.`,
    wasmReady() → false, subsequent calls refuse with the same
    wording. The poisoned-dealloc wrinkle probe (the same module with
    dealloc = unreachable): the in-flight call surfaces a RAW
    `RuntimeError | unreachable` (the masked- wording class — rider 3's
    probe-proven basis).
15. git status at report close: only the three sibling N6-exit lane
    reports untracked (the parallel-lane reality, none read) + this
    report — the repo tree otherwise clean.
