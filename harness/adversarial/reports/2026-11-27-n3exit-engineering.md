# ADV-ENG — N3 exit gate (2026-11-27, Task N3-EXIT-ENG)

Scope: the N3 execution box (the two sessions, commits 3493203..2f3efa1;
the delta `44929c0..2f3efa1`, 36 files / +5164) audited against my
entry report's 7 conditions and the ENG-owned items of CONSENSUS's
16-item ledger. Everything material was probed LIVE with the pinned
toolchain (tools/rust/bin): the three suites (core, core-ffi incl.
`--features panic-hook-test`, apps/linux) re-run green in-tree on the
existing target caches (df measured first: 1.6 GB free — no fresh
slint/cbindgen build; probe footprint ≈ 0 new disk, df identical
before/after), the header regenerated and diffed, the host cdylib
inspected with nm, the commit history + record provenance mapped.
Scratch under /tmp/n3exit-eng only — created and deleted; the two
sibling exit-lane reports (n3exit-legal, n3exit-product) appeared in
the tree during this run — the parallel-lane reality, neither read,
per the isolation rule. `core/Cargo.lock` (34e0b4bc…d1baa) and
`core-ffi/Cargo.lock` (c7120a7d…423f) re-verified byte-identical after
EVERY build; the tree is untouched except this report.

**VERDICT: PROCEED — N3 EXIT PASSED (7/7 entry conditions discharged
in substance and verified live — the riding item closed via the
stronger indexed-lookup option; zero blocking findings; four register
notes: the SESSION_LOG session-1 entry gap, the linux-job Xvfb hunk
vs the "existing jobs byte-identical" audit rule, the 9.9-series
Gradle guard's recorded tolerance, the "every export wrapped" wording
overclaim at the two provably-panic-free accessors).**

## Conditions

1. **(a — the riding item, CLOSED in substance, the stronger
   option):** `core/src/json.rs::parse_object` (487–565) matches the
   ruled shape exactly: `pub const MAX_LINEAR_KEY_SCAN: usize = 64`
   (81, the module docs 47–49 + the cap's rationale updated — "the
   cap now bounds the walk + allocation — the scan is indexed past
   MAX_LINEAR_KEY_SCAN", 548–553); the lazily built
   `HashMap<String, usize>` key→slot index (498–500) engages exactly
   when the (64+1)-th NEW member arrives (533:
   `hit.is_none() && pairs.len() >= MAX_LINEAR_KEY_SCAN` — a
   duplicate never arrives there, it hits the scan, so the member
   count only grows past the threshold via a new key; the invariant
   "once indexed, every pair's key is in the index" holds by the
   insert-before-push at 560–563); used ONLY for find-or-insert — the
   one iteration is the single build pass over the ≤64 pre-threshold
   members (538–540), never afterwards; below the threshold the
   linear scan stays; insertion order, last-value-wins-at-first-
   position (546), and every output byte unchanged (the battery's
   emission asserts + `object_order_preserved_in_emission`). The
   battery: the hostile-amplification case (10,000 members + 100,000
   duplicate occurrences under the deliberately-loose 10 s wall-clock,
   the CI-variance tolerance noted in-test, 985–1022) + the
   threshold-straddling pair (exactly-64 = all linear, index NOT yet
   built; 65 = built; duplicates of a pre-boundary key AND of the
   boundary key itself both resolve to first position + last value
   across the boundary, with emission asserts, 1024–1096); the
   existing member-cap tests unchanged (961–983). **RUN LIVE:
   `cargo test --locked` in core → 176/176** (26+3+6+2+42+4+7+25+39+22
   + 0 doc-tests), incl. the 2 new — proven BY NAME (`duplicate_scan`
   filter → 2 passed). The whole hostile case parses in 0.05 s: the
   bound is real, not paper (pre-index it was a minutes-class scan).
2. **(b — the 512 MiB pre-check, CLOSED):** the core-owned
   `pub const MAX_INPUT_FILE_BYTES = 512 * 1024 * 1024`
   (core/src/lib.rs:274, the 2×-the-256-MiB-STORE-cap rationale beside
   it, the core-stays-pure note), `INPUT_TOO_LARGE_MESSAGE` ("The file
   is too large to open — the limit is 512 MiB.", 278–279), and the
   pure decision fn `input_file_too_large` (283–285 — 512 MiB itself
   accepted, +1 refused). apps/linux's `load_and_compute`:
   `std::fs::metadata` BEFORE `std::fs::read` (main.rs:63–69), refusal
   verbatim `INPUT_TOO_LARGE_MESSAGE`; the battery: the exact-boundary
   pair (512 MiB accepted / +1 refused / message verbatim, 624–633) +
   the sparse-file integration proof (set_len(512 MiB+1), refused by
   metadata alone under a <5 s wall-clock — the read never happens,
   635–657). The Android SAF size query is the CI-primary lane's
   (proven green end-to-end in run 45948447173; not re-runnable
   in-sandbox — JRE-only Java). core-ffi: `check_size` over the shared
   fn + message at every entry (lib.rs:122–127), with the boundary
   battery's real-payload 512 MiB+1 refusal (boundary.rs:347–362) and
   the just-under pair hitting the parser's own named error, never
   the size error. **RUN LIVE: apps/linux suite → 7/7** (5 + the 2
   new).
3. **(c part 1 — the JNI shim + the header boundary, CLOSED):**
   `grep -c Java_ core-ffi/clearfile.h` == **0** (also mechanical in
   scripts/harness_check.sh:314–320); the shim compiled under
   `#[cfg(any(target_os = "android", feature = "host-jni"))]` (lib.rs:
   56–57). **RUN LIVE:** `cargo build --locked --features host-jni`
   → `nm -D` on the host cdylib shows **9 `T` Java_* exports**
   (Java_dev_clearfile_ffi_Native_{compute, decodeEnvelope,
   encodeEnvelope, exportTxf, importTxf, inspectTax, lastError,
   loadAndCompute, paletteSchemeRole}) alongside the 10 `T`
   `clearfile_*` flat exports — one cdylib, two seams, header
   flat-only. jni.rs (all 284 lines read): `jbyteArray` in/out, NEVER
   `jstring` (the Modified-UTF-8 corruption class avoided by
   construction); a thin translation only — every fn marshals → calls
   the flat C fn of the same name → marshals back, every
   Rust-allocated buffer released inside the same call
   (`owned_c_to_java` — the JVM never frees Rust memory); errors as
   `IllegalStateException` carrying the core's verbatim message; the
   palette 0-sentinel surfaces the exception, never a silent 0.
4. **(c part 2 — the boundary battery + the panic discipline, CLOSED
   with one wording note):** **RUN LIVE:
   `cargo test --locked --features panic-hook-test` in core-ffi →
   10/10** (the 17 golden fixtures + the 550-case differential corpus
   THROUGH the boundary at binary64 parity, the malformed classes,
   both cap batteries incl. the STORE stop-note, the 512 MiB pair,
   the feature-gated panic-injection proof, the 34-role palette
   marshaling, the round-trips, the TXF import). The catch_unwind
   spot audit: the ONE shared `ffi_guard`
   (catch_unwind(AssertUnwindSafe) → sentinel + the thread-local
   last-error in the core's wording family, success CLEARS —
   lib.rs:87–102) wraps **8/10 flat data exports + the feature-gated
   panic hook + 9/9 Java_* exports**. The two unwrapped are the
   accessors, unguarded by semantic necessity: `clearfile_last_error`
   (wrapping it would set-last-error-on-success and CLEAR the very
   slot the caller reads; provably panic-free — a thread-local read
   with a non-failing init) and `clearfile_free` (void, NULL-checked
   `from_raw` drop — no panic path). The substance holds — no panic
   can cross `extern "C"` — but the module doc's "Every export wraps
   its whole body" and the commit's "exported-count==guarded-count"
   phrasing overclaim the accessor exemption (R-ENG-14). No
   `panic = "abort"` anywhere in the crate's profile.
5. **(d — the CI android job's engineering shape + the eleven-round
   record, HONEST):** hygiene.yml android-app (245–367) read in full;
   the step order is EXACTLY the ruled order — guards first (the
   fail-closed rustc guard incl. unparsable-refused + `rustup target
   add aarch64-linux-android`; the NDK identity guard asserting the
   pinned 29.0.14206865 by path, never the default; JAVA_HOME explicit
   21, never the image default 25; the Gradle guard), then the
   committed-header freshness (`cargo build --locked` + `git diff
   --exit-code`), the boundary battery, the host cdylib (host-jni),
   the aarch64 cross-build (`--locked`, the NDK clang wrapper
   `aarch64-linux-android24-clang` via env — minSdk 24 paired by
   record), assembleDebug with the APK-carries-the-.so unzip proof +
   the JVM unit tests through the REAL Java_* seam via
   `-Dclearfile.host.lib`, cargo-deny over core-ffi's lock;
   permissions contents:read, timeout 45, NO uploads. New engineering
   debt from the eleven rounds — probed, each recorded and bounded:
   (1) the 9.9-SERIES Gradle guard (`case 9.9.*`) admits future 9.9.x
   patches without re-verification, fail-closed outside the series —
   forced by the fleet's measured mid-rollout state (9.9.1/9.9.2 both
   live across consecutive runs), the tolerance recorded in the env
   comment (R-ENG-12, accepted); (2) the Xvfb bounded wait (50 × 0.1 s
   `/tmp/.X11-unix/X99` socket poll, fail-closed if never there) is
   adequate for the observed race class (run 45943612134, exit 101);
   the residual theoretical window (socket present before accept) is
   negligible and its failure mode is a RED CI, never a false green;
   (3) no unrecorded workflow residue: the python-continuation class
   was restored to the plain multi-line shell form — no python or
   heredoc remains in the android job (the only python in the
   workflow is the pre-existing re-tooling script family); the
   round-3 gradle fix is recorded in-file at app/build.gradle.kts.
   The full job is green end-to-end in run 45948447173 on ae9e078 —
   honestly cited by number at the close.
6. **(e — the guard joins + the box discipline, CLOSED, one record
   note):** .gitignore timing verified from the history:
   `/core-ffi/target/` joined at f496ee4 — the SAME commit as the
   core-ffi scaffold (before any core-ffi build state could exist);
   the apps/android block (`.gradle/`, `build/`, `app/build/`,
   `shared/build/`, `local.properties`, `.kotlin/`, `.cxx/`,
   `*.keystore`) joined at 7030002 — the SAME commit as the first
   gradle state (no gradle state precedes it in the tree); the backup
   scan-path list joined core-ffi at f496ee4 (the 2-line
   sandbox_backup.sh diff in that commit); core-ffi's deny.toml in
   its FIRST commit with the 74-package lock. Checkpoint order:
   3493203 (the hardenings — ONLY core/src/json.rs + core/src/lib.rs
   + apps/linux/src/main.rs, no FFI path) at 04:14:18Z strictly
   precedes f496ee4 (the first core-ffi path) at 04:36:40Z — a
   session death between the two still closed the riders, the
   intra-session checkpoint discipline executed as ruled. Exactly
   TWO sessions: session 1 = 3493203 + f496ee4; session 2 =
   7030002..2f3efa1 (the app + the CI lane + the eleven CI-fix
   rounds); no third; the close (2f3efa1, 05:59:36Z) is honest per
   lane: the CI green cited by run number (45948447173 on ae9e078),
   the in-sandbox lanes by count (core 176/176, battery 10/10, app
   7/7), the Android lane honestly CI-ONLY — no unqualified
   "landed" anywhere. NOTE: session 1 itself never landed a
   SESSION_LOG entry (the N2 precedent logged session-1 entries) —
   the full session-1 record lives in the two checkpoint commit
   messages (timestamped, with statuses), and the session-2-lands
   entry restates the in-sandbox per-lane statuses; content
   preserved, convention diverged (R-ENG-11).
7. **(f — the per-OS order STANDS; N4's consumption surface
   verified):** the header N4 consumes EXISTS and is COMMITTED
   (core-ffi/clearfile.h, 99 lines, f496ee4), in the C99 form
   (`#include <stdbool.h>`/`<stdint.h>` — Language::C pinned, not the
   C++ default), with the SPDX line emitted by the generator config
   and cbindgen's own banner retained; freshness-checked TWICE over:
   the CI step (git diff --exit-code, green in 45948447173) and MY
   LIVE run (the build.rs regeneration after `cargo test` + `cargo
   build` is byte-identical — `git diff --exit-code -- core-ffi/
   clearfile.h` clean). core/Cargo.lock byte-identical after every
   build (the separate-root topology intact; the hygiene
   exactly-1-package assertion safe). Doing N3 before N4 remains the
   de-risking order — no engineering demand to re-order; macOS stays
   last.

## Risks register

- R-ENG-11 (record convention, low): no SESSION_LOG entry for session
  1 (condition 6). The record content is preserved (the commit
  messages + the session-2 entry's per-lane statuses); the fold is
  the orchestrator's at this exit close.
- R-ENG-12 (CI guard tolerance, low, accepted + recorded in-file):
  the 9.9-series Gradle guard admits future 9.9.x patches without
  this gate's re-verification; fails closed on 9.10/10.0. Gradle's
  own series compatibility is the relied-upon contract.
- R-ENG-13 (audit-rule bend, low): hygiene.yml's delta is NOT purely
  additive — the linux-app job's window-smoke step gained the Xvfb
  bounded wait (round 5's flake fix; ledger item 10 said "existing
  jobs byte-identical"). The bend is recorded, fail-closed, and
  covered by the green run; this report states it so the exit record
  carries it.
- R-ENG-14 (wording overclaim, low): lib.rs's module doc "Every
  export wraps its whole body in the ONE shared guard" (and the
  commit's exported==guarded phrasing) overclaims the two accessor
  exemptions (condition 4) — the exemption is semantically forced and
  the fns are provably panic-free; a one-line doc amendment at next
  touch discharges it.
- R-ENG-15 (pre-existing, NOT N3's): apps/linux's slint deprecation
  warnings (viewport-width/height, ui/app.slint 327–328 — untouched
  by this delta) surfaced in my live run. Next-touch class, N2-era.

## Advisories (non-binding)

- The boundary battery's 512 MiB pair holds ~1 GiB of transient RAM
  (both payload vectors alive simultaneously) — it fit this sandbox
  (3.1 GB available) and the runner; N4/N5 lanes on smaller boxes
  should know before re-running it.
- STATE.md's "Immediately next" still carries the session-1 order —
  per the N2 pattern it is rewritten at the gate close; the N3 exit
  close should do the same (the records-at-the-close family).
- The android job's NDK clang wrapper path and the pinned
  NDK_VERSION must keep moving together (the guard asserts the
  version dir; the linker path hardcodes it) — a one-line
  env-derivation would couple them, but the pair is recorded.
- The wall-clock bounds (10 s hostile / 5 s sparse-refusal) are
  appropriately loose: observed 0.05 s / ~0 s — no CI-variance
  false-trip exposure.

## Files read + verification log

Files read: the entry report harness/adversarial/reports/
2026-11-27-n3-engineering.md (all — the 7 conditions), CONSENSUS.md
(1496–1711, the N3 delta-scoped gate: the 16-item ledger + the
runner-image facts), SESSION_LOG.md (the 2026-11-27 N3 entries,
2236–2393), ROLES.md (all), core/src/json.rs (470–575 the
implementation + 985–1114 the battery), core/src/lib.rs (262–286),
apps/linux/src/main.rs (all — the enforcement + the battery),
core-ffi/src/lib.rs (all), core-ffi/src/jni.rs (all),
core-ffi/tests/boundary.rs (240–379 + the test-name survey),
core-ffi/clearfile.h (1–40 + the Java_ grep over all),
.github/workflows/hygiene.yml (160–370 + the hunk map over the
delta), scripts/harness_check.sh (the core-ffi families),
.gitignore (the delta hunks), the git history of the delta (14
commit messages incl. 3493203/f496ee4/becfff6 in full).

Runs (this session, tip 2f3efa1, the pinned tools/rust/bin toolchain;
scratch /tmp/n3exit-eng created + deleted):

1. df/free baseline: 1.6 GB free on /, 3.1 GB RAM available; the
   in-tree target caches measured (core 174 M, core-ffi 492 M,
   apps/linux 3.0 G) and reused — probe footprint ≈ 0 new disk (df
   identical before/after).
2. `cargo test --locked` (core) → **176/176 green** (0 failures),
   incl. the 2 new; the `duplicate_scan` filter run → 2 passed by
   name; the hostile case parses in 0.05 s.
3. `cargo test --locked --features panic-hook-test` (core-ffi) →
   **10/10 green** (7.42 s; the ~1 GiB transient battery included).
4. `git diff --exit-code -- core-ffi/clearfile.h` after the runs →
   clean (the live regeneration is byte-identical — the local
   freshness proof).
5. `cargo build --locked --features host-jni` (core-ffi) → finished;
   `nm -D` → 9 `T` Java_* exports + 10 `T` clearfile_* flat exports.
6. `cargo test --locked` (apps/linux) → **7/7 green** (0 failures;
   the sparse-file refusal proof ran within it).
7. `sha256sum` of both locks before/after every build →
   core/Cargo.lock 34e0b4bc…d1baa, core-ffi/Cargo.lock
   c7120a7d…423f — byte-identical throughout.
8. `grep -c Java_ core-ffi/clearfile.h` → **0**.
9. The git audits: log/diff over 44929c0..2f3efa1 (.gitignore hunks
   mapped to f496ee4/7030002; the checkpoint order 3493203 → f496ee4;
   SESSION_LOG/STATE/ROADMAP/README/DEBT commit provenance);
   hygiene.yml's delta hunk map (2 hunks: the Xvfb wait in the
   linux job + the additive android job).
10. rm -rf /tmp/n3exit-eng → cleaned.

At report close (pre-write; the two sibling exit-lane reports are the
parallel-lane reality, neither read): git status --short →

```
?? harness/adversarial/reports/2026-11-27-n3exit-legal.md
?? harness/adversarial/reports/2026-11-27-n3exit-product.md
```

plus this report once written; df: `/ … 9.9G … 1.6G avail (84%)`.
