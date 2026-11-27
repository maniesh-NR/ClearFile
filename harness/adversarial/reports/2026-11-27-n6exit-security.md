# ADV-SEC — N6 exit gate (2026-11-27, Task N6-EXIT-SEC)

Reviewer: ADV-SEC (secrets/CI-CD/supply chain/untrusted-input surfaces +
release integrity + token lifecycle; per ROLES.md). The N6 exit under review,
ruled adversarially — the EPILOGUE'S TERMINAL GATE'S EXIT: the N6 arc
`1dd84dc..HEAD` (2 commits, 32 files, +3734/−200: core-ffi's FOUR new
additive exports + the battery +2 (12/12), the regenerated committed
header, the wasm32 adapter `src/lib/wasm/core.ts` (591 lines), the four
retired TS files with LEGAL's terminal banner, config.ts's TABLE removal,
the consumer switches + page.tsx's boot gate, the suites transfer
(wasm_parity_test.mjs NEW + txf_taxfile_test.mjs re-pointed +
web_parity_test.mjs retired), the tsconfig re-points, hygiene.yml's
suites-job wasm steps, .gitignore, the manifest row 2 + the fetcher
extension, the records). The execution facts as briefed: the lane closed
on the FIRST live-green round on f295a27, all 8 jobs. Read first, as
instructed: my own N6 entry report
(`2026-11-27-n6-security.md`, all — the 8 conditions below are MINE,
probed one by one at this exit), CONSENSUS.md's N6 entry record
(l.2211-2318 — the rulings 1-10 + the reconciliations (a)-(f) + the
TWELFTH surfacing + the TERMINAL-gate parking posture), ROADMAP's N6
section (l.778-801), STATE.md l.363-413 (the agenda). The sibling N6-exit
reports were neither read nor written (isolation rule).

**The execution facts verified LIVE, not on trust.** The hygiene run on
f295a27 is real and first-round-green: fetched live via the API — run
**45991786766**, 8/8 jobs success (gitleaks, suites, android, linux,
windows, macos, RE tooling, harness self-check); the suites-job log
fetched and read: the wasm32 build step ran BOTH variants in the ruled
order (panic build → copy → plain build → the `test -f` check), the
import guard green ("import guard: ok — the wasm module has zero
imports"), the parity suite 17/17 ("ok the length-paired allocator: 100
interior-NUL cycles, module still ready" + "ok the core-served parameter
table"), the bridge suite 11/11, the AI suites 5/5 + 4/4; the
android-job log: the expanded battery **12 passed; 0 failed**. I also
re-proved the whole lane LOCALLY with the pinned toolchain (the CI's
exact commands): both wasm variants built (rustc 1.100.0 from tools/rust),
the import guard re-run (imports: 0; 15 exports plain / 16 with the
panic hook), `node scripts/wasm_parity_test.mjs` 17/17 + the allocator +
params assertions, `node scripts/txf_taxfile_test.mjs` 11/11,
`npx tsc --noEmit` exit 0, `harness_check.sh` 0 failures, the blob guard
clean (458 tracked files, 28 allow-listed, no .wasm).

**VERDICT: PROCEED-WITH-CONDITIONS (6 numbered close riders)**

**SHAPE: the ruled shape (A, the full serving) is served and
mechanically verified** — with the verification layer itself carrying the
two material findings: (1) the wasm-side TRAP assertion my condition 2(b)
required is DEAD CODE — the suite's panic block forgot reconciliation
(f)'s own lesson (the bufferSource overload resolves `{module,
instance}`), so `panicInstance.exports` is undefined, the thrown
TypeError is swallowed by a catch-all, and the suite prints a FALSE
"skip the trap assertion (no panic-hook module built)" — the line is IN
THE GREEN RUN'S LOG; the proof has never executed anywhere; (2) the
wasm-side CONTAINER round-trip my condition 3 required exists in no
suite, and the CONSENSUS reconciliation (d) RECORDS a coverage ("the
bridge suite's ClearFile-container fixture now builds via the adapter's
own exportTaxContainer") that the landed code does NOT have. Plus one
records-honesty defect: the execution record cites run **45991816001**
as the "all EIGHT jobs" green round — that ID is the DEPENDABOT run
(1 job); the hygiene run is **45991786766**. None of these are
BLOCK-class: the shipped-artifact posture is sound (the adapter handles
the instantiate shape correctly — (f) landed where it mattered; the app
compiles; every ABI seam is battery-proven on every lane; my own live
proves close the two coverage gaps' substance), and every finding is
mechanically closable at the close. The riders below carry them.

## Conditions (the discharge proofs)

1. **The length-paired alloc/dealloc — DISCHARGED, exactly as ruled
   (reconciliation (a): plain, un-gated, every-target).**
   `clearfile_alloc` (lib.rs): the 512 MiB bound (`input_file_too_large`)
   runs BEFORE the allocation inside `ffi_guard` — this also makes the
   `len + 1` overflow class unreachable (any len > 512 MiB is refused
   first, with the shared named message family + NULL); the buffer is
   `vec![0u8; len + 1]` — zeroed, the +1 zero tail, freed ONLY by
   `clearfile_dealloc` with the SAME len (documented in the source AND
   the committed header: "NEVER clearfile_free — its strlen-derived
   dealloc is unsound for interior-NUL payloads"). `clearfile_dealloc`:
   `Vec::from_raw_parts(ptr, len + 1, len + 1)` — the recorded length
   governs, interior NULs irrelevant (the SAFETY comment); NULL-safe.
   Proofs: the battery's `alloc_dealloc_length_pair_survives_interior_nuls`
   (100 cycles of ALL-zero payloads — every byte an interior NUL — + the
   512 MiB+1 refusal asserting the exact `INPUT_TOO_LARGE_MESSAGE` + the
   NULL-safe dealloc) green in CI 12/12 (the android lane's log, fetched
   live); the wasm side's 100-cycle proof through the adapter's withInput
   green in the CI log. Residual (advisory-grade, my 1(d) leak-probe
   half): no `memory.buffer.byteLength` stability assertion — and at the
   suite's 64-163-byte cycle sizes one would be VACUOUS (< one 64 KiB
   page); see advisory 1. The dealloc pairing is structural (the finally
   + the recorded length), and my local re-run of the suites passed
   through it.

2. **The trap mapping + poisoned posture — the ADAPTER is discharged;
   the SUITE'S PROOF IS DEAD CODE (rider 1).** The adapter
   (`src/lib/wasm/core.ts`): `mapped()` catches `WebAssembly.RuntimeError`
   → `poisoned = true` → throws `CoreError('The operation failed
   unexpectedly — an internal error occurred.')` — the guard's own wording
   family, verbatim; `assertReady()` refuses with the same named message
   when poisoned, and `wasmReady()` gates the UI. Every value-returning
   wasm call is wrapped (grep-verified line by line: the alloc in
   withInput, last_error, params_json, encode_envelope, export_txf, both
   container-export calls, and every compute/import/inspect path through
   callText); the only unwrapped calls are `clearfile_free`/`clearfile_dealloc`
   — the release paths, panic-free by construction (drops of plain bytes).
   The CI step's build order is EXACTLY as ruled, verified in the YAML
   AND the fetched log: panic-hook build FIRST → `cp` to
   `clearfile_core_ffi_panic.wasm` → the plain build → the `test -f`
   check → the import guard. **THE DEFECT:** wasm_parity_test.mjs
   l.75-76 does `const panicInstance = await
   WebAssembly.instantiate(readFileSync(panicModulePath), {})` then
   reads `panicInstance.exports` — the bufferSource overload resolves
   `{module, instance}` (the EXACT shape reconciliation (f) taught the
   ADAPTER to handle at core.ts l.278-281; the suite's trap block forgot
   it), so the hook lookup throws a TypeError, and the block's catch-all
   (l.86-92) swallows ANY non-RuntimeError error into
   `"skip the trap assertion (no panic-hook module built)"` — a FALSE
   skip: the module WAS built and present. Verified twice: locally (the
   suite re-run prints the skip with the panic variant sitting at the
   path), and in the GREEN RUN'S OWN LOG (fetched:
   `11:38:15.3199543Z skip the trap assertion (no panic-hook module
   built)`). The assertion my condition 2(b) required has NEVER
   EXECUTED — not locally, not in CI. I closed the SUBSTANCE with my own
   correct-shape probe: instantiating the panic variant and calling
   `clearfile_test_guard_panic()` throws `RuntimeError` ("unreachable"),
   `instanceof WebAssembly.RuntimeError` === true, and post-trap the
   instance stays callable with `last_error` EMPTY — the trap bypassed
   `catch_unwind` exactly as the ruling states. The ruling is TRUE; the
   suite's proof of it is dead. Discharge: rider 1.

3. **The container export's length-out channel — the ABI + the battery
   DISCHARGED; the wasm-side round-trip MISSING and the (d) record
   mismatched (rider 2).** The ABI:
   `clearfile_export_tax_container(envelope_text, envelope_len, out_bytes,
   out_capacity, out_len)` — the NULL `out_len` is a NAMED error FIRST
   (-1); the input rides the NUL-safe (ptr,len) contract + check_size +
   UTF-8; `*out_len` is ALWAYS written (the probe contract) BEFORE the
   capacity check; return 1 with `last_error` EMPTY when the buffer is
   too small (a return code, never an error — the battery asserts exactly
   this), 0 + copy_nonoverlapping on success. Binary NEVER rides the
   CString channel — every owned return in the delta is text (the
   envelope TXF/JSON/analysis paths); `to_owned_buffer` has no binary
   caller anywhere in the delta (read line by line). The battery's
   `container_export_is_the_length_out_binary_channel`: probe call (rc 1,
   needed > 0, last_error empty) → real call (rc 0, written == needed) →
   the interior-NUL assertion → the round-trip back through
   `clearfile_load_and_compute` (the source identifies container /
   clearfile.json) → the NULL out_len (-1, named error). Green 12/12 in
   CI on every native lane. The ADAPTER's `exportTaxContainer` (the JS
   side of the binary channel — the 4-byte lenSlot, the probe-then-alloc,
   `DataView.getUint32` little-endian, the owned copy-out, the
   length-paired deallocs) is correct by code reading AND by MY LIVE
   PROBE (through the compiled adapter): a 1,822-byte PK container with
   interior NULs, exported + reloaded through `loadAndCompute`
   WARNING-FREE, the filing fields intact. **THE GAP:** ZERO suite
   coverage — `exportTaxContainer` appears in NO script (grep over
   scripts/: no match); the bridge suite's ClearFile-container fixture
   builds via the suite's OWN STORE-ZIP makeZip + `serializeCfr` (txf_taxfile_test.mjs
   l.223-242). The CONSENSUS reconciliation (d) RECORDS the opposite of
   what landed: "the bridge suite's ClearFile-container fixture now
   builds via the adapter's own exportTaxContainer (the app's own
   writer)". The record claims a coverage that does not exist. Discharge:
   rider 2 (either land the recorded shape or correct the record — with
   the wasm-side round-trip covered either way; my probe is the working
   template).

4. **Shape A served — DISCHARGED, one one-line residual (rider 4).**
   The four files carry LEGAL's exact dated terminal banner — comment-only,
   +9 lines each, byte-otherwise-unchanged (the git diff shows nothing
   else; the banner carries the revive-discipline: "no further changes of
   any class land here, bug and security fixes included — they go to the
   Rust core"). config.ts: the TABLE (TY2025 + YEARS, the −139 lines) is
   GONE; the types/labels/formatters/DEFAULT_YEAR live on; zero parameter
   data or compute logic platform-side — the table's one true source is
   `clearfile_params_json` (the null terminal rung serialized as null,
   reconciliation (c), asserted in the parity suite). The consumers all
   switched to `@/lib/wasm/core` (steps.tsx, ai-ui.tsx, filemenu.tsx,
   ai/tasks.ts — compute now takes ONLY the filing; the params argument
   is the core's business). page.tsx's boot gate: `initWasm()` →
   `wasmReady()` gates the render, and a failed fetch surfaces the NAMED
   error inside the Splash (my entry risk 4 — no white screen, no silent
   wrong result). tsc --noEmit: exit 0 (re-proven locally); the suites
   green (parity 17/17 + bridge 11/11, CI + local). web_parity_test.mjs
   retired with its own banner (kept as the frozen transition record).
   **The import graph** (my condition's own checkable, run verbatim):
   the retired modules are referenced ONLY by (a) the frozen files' own
   internals — type-only, frozen↔frozen, allowed — and (b) **store.ts
   l.6: `import type { Dependent, TaxReturnData, W2Entry } from
   './tax/engine'`** — a LIVE file still naming a frozen artifact as its
   type source. `import type` is erased at emit, so the RUNTIME graph is
   clean (the banner's "out of the app's runtime import graph" holds at
   runtime) — but my condition required store.ts to import a LIVE model
   module, and the only wall against a silent value-import revival
   (engine.ts still exports everything) is convention. One line closes
   it: rider 4.

5. **The never-tracked .wasm posture — DISCHARGED.** .gitignore +5
   lines in the SAME commit as the loader + CI (f295a27): the exact
   runtime path `/public/clearfile-core.wasm` (+ the comment naming the
   variant files), with the build outputs under `/core-ffi/target/`
   (pre-existing l.110 — where both the CI and the local builds write)
   and the scratch dirs `/.parity-build/` + `/.files-build/` (pre-existing
   l.51-52) already covered — every location the lane writes is ignored,
   and the blob wall backstops anything else: `check_binary_blobs.py` is
   byte-unchanged in the delta (28 allow-list entries, no .wasm), run
   live: clean, 458 tracked files, no other blobs; `git ls-files` holds
   ZERO .wasm; git status is clean with the artifacts present untracked.
   The import-empty CI guard: `WebAssembly.Module.imports(m).length ===
   0`, fail-closed with the named listing — green in the fetched CI log
   AND re-proven locally (imports: 0; 15 exports plain / 16 with the
   hook — the export census matches the 10 original + 4 new + memory).
   The integrity story: per ruling 8, release.yml stays BYTE-FROZEN with
   the nextjs-web job STALE-BY-DESIGN (nothing ships at N6) — my 5(c)
   tarball-rides story and my 6(b) release-job parity re-run defer to the
   GA rework, recorded in CONSENSUS (the reconciliation my exit accepts;
   the byte-freeze itself verified under condition 6).

6. **The CI shape — DISCHARGED, one small residual (rider 5).**
   `git diff 47f33a4..HEAD` over release.yml AND pages.yml: ZERO lines —
   byte-unchanged since the D29 fix; the last release.yml touch remains
   47f33a4 ✓; pages.yml untouched ✓ (the Flutter-web-only claim intact).
   The workflow delta is hygiene.yml ONLY (33+/10−, one job body): no new
   `uses:` (the suites job's checkout/flutter/node actions pre-exist), no
   new `secrets.*` (the only one remains gitleaks' GITHUB_TOKEN, l.35,
   outside the delta), no uploads (the only artifact flow stays
   release.yml's own), no new triggers (zero `pull_request` triggers
   across all three workflows — the single grep hit is pages.yml's
   pre-existing policy COMMENT at l.16). The wasm steps are plain
   `run:` blocks over committed files, fail-closed (`--locked` both
   builds, the `test -f` check, the import guard), THEN the transferred
   suites. The order ruled for the panic variant: exact (condition 2
   above). **RESIDUAL:** no rustc guard before the wasm build — my 6(a)
   required the android-lane template's "rustc guard FIRST (never the
   runner default silently)"; the step builds with the runner's rustup
   default, unguarded and unechoed (the runner's rustc happened to BE
   1.100.0 — the pinned version — echoed only later in the core-test
   step). Every other Rust lane guards; this one is drift-open. Rider 5.

7. **The pinned-not-TOFU manifest row 2 + the stray-tarball discharge —
   DISCHARGED.** The manifest's row 2:
   `1.100.0 …/2026-11-12/rust-std-1.100.0-wasm32-unknown-unknown.tar.gz
   895cc155…ea066` — the FULL sha256 pinned in the file. The fetcher's
   extension: `read_row2` (awk NR==2, fail-closed on a malformed row),
   the idempotent presence check (the .rlib set at
   tools/rust/lib/rustlib/wasm32-unknown-unknown), the resumable
   foreground unauthenticated download, `sha256sum --check --strict`
   before unpack, the differing component tar layout handled (the
   component's rustlib tree copied into the standalone toolchain's
   rustlib). Verified live: the cached tarball's sha256 = the manifest's
   row-2 hash BYTE-EXACT; tools/rust carries rustc 1.100.0 + the
   installed wasm32 std (the rlibs listed) — the local lane is real
   (ruling 6's "CI-verified + locally provable" posture held: I
   reproduced the CI's exact build + suite commands through it). The
   stray 23,018,664-byte `rust-std-wasm32.tar.xz`: ABSENT from the tree
   (git status fully clean; the root ls empty) — the N2-class
   guard-order violation is discharged; the fetcher's own tarball lives
   in /tmp, never the repo root.

8. **The terminal records set — ON TRACK: the TWELFTH + the parking
   posture RECORDED; the freeze declaration is the post-exit step
   (rider 6), and the run-ID citation is WRONG (rider 3).** Verified in
   CONSENSUS (l.2292-2307): the pinned enumeration ("…12 THIS gate"),
   the three owner options ((a) the T3 session + D42, (b) the namespace
   -rule supersession, (c) the default re-agenda) with "No ruling
   received across ELEVEN prior surfacings", and THE TERMINAL-GATE
   PARKING POSTURE verbatim — the slip cannot ride past the epilogue's
   last gate unexamined; if still unruled at the close: the Stage-2 exit
   stays SLIPPED; the MSI-record keystream chase stands as recorded debt
   D42 ("T3 session 2"); D30 stands; owner decisions — never a silent
   drop. The checker families updated (harness_check.sh: FUNDED 0,
   N-outcomes 10) — run live: 0 failures. **THE RUN-ID DEFECT:** the
   execution record (ROADMAP l.787-788) cites "run 45991816001 on
   f295a27, all EIGHT jobs" — fetched live, **45991816001 is the
   DEPENDABOT run** (dynamic/dependabot/dependabot-updates, 1 job,
   "npm_and_yarn in /. for js-yaml, … minimatch, prismjs, sharp"); the
   hygiene run with all eight jobs green is **45991786766**. The green
   first round is REAL (verified live, job by job, log by log); the
   CITATION points at the wrong run. The remaining records (the freeze
   declaration itself, the README web rows + the named non-verifications,
   the STATE.md/SESSION_LOG syncs, the LICENSES-at-next-tag note) are the
   recorded next step — rider 6 carries the enumeration they must land
   with.

## Risks register

1. **The dead-assertion class (new, rider 1's general form):** a suite
   assertion whose failure mode is a silent skip is FAIL-OPEN — the
   catch-all must distinguish "the artifact is absent" from "the
   assertion threw unexpectedly". The trap block's false skip sat green
   in CI one full round; only the exit's live-log read caught it. Every
   soft-skip in the suites deserves the same audit at any future edit.
2. **The untested JS binary-channel path (until rider 2 lands):** the
   app's `.tax` export button rides an adapter path with ZERO CI
   coverage (my live probe says it works today; coverage is the point).
3. **The record-vs-code drift class:** CONSENSUS (d) describes a suite
   shape the code does not have — at a terminal gate, the freeze
   declaration's claims inherit this risk directly; riders 1-3 must
   land BEFORE the declaration freezes the record set.
4. **Wasm toolchain drift on the CI lane (carried from entry risk 2,
   sharpened by rider 5):** the runner's rustup default is unguarded at
   the wasm step — the suites job's .wasm and the battery's native lanes
   could silently diverge on a future image.
5. **The frozen-artifact rot (carried from entry risk 5):** compile
   health stays CI-caught forever; store.ts's type edge is the last
   reachability hair (rider 4).
6. **release.yml's STALE-BY-DESIGN nextjs-web job (ruling 8's standing
   posture):** any tag before the v2.0.0-GA rework ships a web artifact
   built WITHOUT the wasm steps — the guard is the recorded owner
   decision, and the LICENSES manifest at the next tag (ruling 7) rides
   the same decision.

## Advisories (non-binding)

1. **The leak probe, made real:** a `memory.buffer.byteLength` stability
   assertion over the suite's 64-163-byte cycles is sub-page and vacuous;
   if the leak check is wanted, one large-payload cycle (≥ 1 MiB through
   withInput) or a page-crossing series makes it meaningful.
2. **The adapter-level trap proof (after rider 1):** a child process
   init'ing the adapter with the panic module, calling any function,
   asserting the named CoreError wording + `wasmReady() === false` would
   prove mapped()+poisoned end-to-end (the singleton prevents it
   in-process).
3. **CSP (carried from entry advisory 1):** none today; any future CSP
   needs `'wasm-unsafe-eval'` in script-src — record beside any CSP note.
4. **The same-origin fetch privacy line (carried from entry advisory 4):**
   the README row in rider 6 should keep the "no telemetry / data stays
   on your device" claims exactly true in wording (the boot-time GET
   sends no user data).
5. **The dependabot run observation:** run 45991816001 (the misattributed
   ID) is the pre-existing dependabot machinery updating js-yaml /
   minimatch / prismjs / sharp — the dev-dependency class, package.json
   byte-unchanged in the delta, the prod-tree audit gate unaffected;
   nothing owed by this lane beyond the citation fix (rider 3).

## Close riders (the numbered conditions this exit carries)

1. **The trap assertion made live + the record corrected.** In
   wasm_parity_test.mjs's trap block: destructure the bufferSource
   overload's `{module, instance}` (the exact (f) shape the adapter
   handles at core.ts l.278-281), and make the catch FAIL-CLOSED — only
   the module's ENOENT may skip; any other error reds the suite (never
   the false "no panic-hook module built" line). The close push's
   hygiene run must print "ok the trap ruling: a Rust panic on wasm32 is
   a RuntimeError trap (never a sentinel return)", and the records
   correct run 45991786766's "the allocator/trap/params proofs" claim
   (the trap proof printed skip there — the log line is quoted in this
   report).
2. **The wasm-side container round-trip + the (d) reconciliation
   honesty.** Add the adapter's `exportTaxContainer` round-trip to the
   bridge suite's ClearFile-container group — build via the adapter's
   own writer, assert the PK magic + interior NULs, reload through
   `loadAndCompute` warning-free, assert the filing fields (my live
   probe in this report is the working template) — restoring
   reconciliation (d)'s recorded shape; OR correct the CONSENSUS (d)
   text to the landed shape and record the coverage gap honestly.
   Either way the wasm-side binary-channel JS path (lenSlot / DataView /
   probe-alloc / copy / dealloc) must be suite-covered before the
   epilogue close.
3. **The run-ID correction.** ROADMAP l.787-788: the "all EIGHT jobs"
   first-green round is hygiene run **45991786766** on f295a27 (verified
   live: 8/8 success); **45991816001** is the dependabot run (1 job).
   Correct the citation at the records step; the freeze declaration
   must cite the hygiene run.
4. **store.ts's type rehome.** l.6 `import type { Dependent,
   TaxReturnData, W2Entry } from './tax/engine'` → `'./wasm/core'`
   (one line; the adapter exports all three) — after which the frozen
   artifacts have ZERO live-file references of any kind, my condition
   4's letter.
5. **The rustc guard before the wasm build.** The suites job's wasm step:
   add the fail-closed rustc guard (the >= 1.95 family, the android-lane
   template) + the version echo BEFORE the first wasm build — today the
   step builds with the runner's rustup default silently (1.100.0 by
   luck, not by guard).
6. **The terminal records set at the freeze declaration.** The
   declaration lands with: the pinned enumeration (…12 the N6 gate) +
   the parking posture restated; the terminal freeze + the
   v2.0.0-territory stance (GA-gated per ADR-017's row); the README's
   web rows updated honestly (the wasm-core engine row, the
   parity-runner list gaining the wasm suite, the boot-time
   same-origin fetch line, the named non-verifications: no
   browser-side interactive matrix beyond the smoke class, the
   single-engine Chromium verification status if any); the
   LICENSES-manifest-at-next-tag note (ruling 7); STATE.md + SESSION_LOG
   synced. The exit verdict rides on the declaration landing with
   exactly this set before the epilogue close.

## Files read + verification log

- My own `2026-11-27-n6-security.md` (all — the 8 conditions above);
  `harness/adversarial/CONSENSUS.md` l.2211-2318 (the N6 entry record:
  the rulings, the reconciliations (a)-(f), the TWELFTH + the parking
  posture — verified recorded); `harness/memory/ROADMAP.md` l.778-801
  (the N6 ENTERED + the execution record — the run-ID defect located at
  l.787-788); `harness/memory/STATE.md` l.363-413 (the agenda);
  `harness/memory/SESSION_LOG.md` (the tail — the N5-close state, not
  yet N6-synced, per the recorded next step).
- The delta read in full: `core-ffi/src/lib.rs` (the four new exports +
  the N6 comment block — the length-pairing, the bound-before-alloc, the
  NULL-out_len channel, the params service), `core-ffi/clearfile.h`
  (the regenerated +51: the four declarations through the config-emitted
  flow), `core-ffi/tests/boundary.rs` (the two new tests — the 100-cycle
  interior-NUL proof + the container channel proof; 12 `#[test]` total),
  `core/src/params.rs` (the to_json serialization — the status keys +
  the null terminal rung), `src/lib/wasm/core.ts` (all 591 — mapped()/
  assertReady/poisoned, withInput's finally-dealloc, the 2^32 length
  guard, readCString's bounded scan, exportTaxContainer's lenSlot
  dance, the type/helper re-exports), the four retired files' banners
  (comment-only verified via the diff), `src/lib/tax/config.ts` (the
  TABLE removal; the remaining exports censused), `src/app/page.tsx`
  (the boot gate + the named error), the consumer diffs
  (steps/filemenu/ai-ui/tasks — the switches verified),
  `scripts/wasm_parity_test.mjs` (all 176 — the trap block's defect
  located at l.75-92), `scripts/txf_taxfile_test.mjs` (the transfer +
  the STORE-ZIP builder + the divergence-5 warning-free assertion at
  l.346-352), `scripts/web_parity_test.mjs` (retired with its banner),
  the three tsconfig diffs (the re-points), `.github/workflows/hygiene.yml`
  (the wasm step + the suites order), `.gitignore` (+5),
  `scripts/rust_toolchain_manifest` (row 2),
  `scripts/fetch_rust_toolchain.sh` (the row-2 extension),
  `scripts/harness_check.sh` (FUNDED 0 / N-outcomes 10),
  `package.json`/`scripts/check_binary_blobs.py` (NOT in the delta —
  byte-unchanged, the zero-new-deps + allow-list-stable claims).
- Live probes (read-only except the gitignored build outputs + this
  report): (1) the CI verification via the GitHub API (the remote's
  token, never printed): run 45991786766 on f295a27 — 8/8 jobs success;
  the suites-job log fetched + read (the wasm build order, the import
  guard, the parity 17/17, the trap-SKIP line, the params ok, the bridge
  11/11, the AI 5/5 + 4/4, rustc 1.100.0); the android-job log (the
  battery 12 passed); run 45991816001 identified as the dependabot run
  (1 job) — the misattribution finding. (2) The local re-proofs with
  the pinned toolchain (tools/rust rustc 1.100.0): BOTH wasm variants
  built with the CI's exact commands; the import-empty guard re-run
  (0 imports; 15/16 exports); `node scripts/wasm_parity_test.mjs`
  (allocator ok, trap skip reproduced, params ok, 17/17), `node
  scripts/txf_taxfile_test.mjs` (11/11), `npx tsc --noEmit` (exit 0),
  `bash scripts/harness_check.sh` (0 failures), `python3
  scripts/check_binary_blobs.py` (clean, 458 files, 28 allow-listed).
  (3) The trap-class proof with the CORRECT instantiation shape:
  `clearfile_test_guard_panic()` → RuntimeError ("unreachable"),
  instanceof true, the instance post-trap callable with last_error
  empty. (4) The container round-trip probe through the compiled
  adapter: exportTaxContainer → a 1,822-byte PK container with interior
  NULs → loadAndCompute warning-free → the filing fields intact. (5)
  The manifest row-2 sha256 verified byte-exact against the cached
  tarball; the stray root tarball confirmed ABSENT. (6) `git diff
  47f33a4..HEAD` over release.yml + pages.yml: zero lines. (7) The
  import-graph grep: the four frozen files' own type-only internals +
  store.ts l.6 (rider 4). Could NOT verify from this sandbox: anything
  about the browser runtime beyond node's WebAssembly (no
  single-engine Chromium verification exists — the named
  non-verification rider 6 carries); the runner image's future rustc.
- No packages installed; the only tree changes from this lane are the
  gitignored build outputs (re-created by the CI's own commands) and
  this report.

`git status --short` after filing (run live, verbatim):

```
?? harness/adversarial/reports/2026-11-27-n6exit-product.md
?? harness/adversarial/reports/2026-11-27-n6exit-security.md
```

Only the second line is mine (`…n6exit-security.md`, this report — the
only file this lane created or modified). The first line is a parallel
lane's own exit filing, landed concurrently while I worked — NOT read,
per the isolation rule. The tree is otherwise fully clean — the stray
tarball gone, the .wasm artifacts untracked under the ignored paths, no
drift.
