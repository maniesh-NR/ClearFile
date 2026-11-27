# ADV-ENG — N3 delta-scoped gate (2026-11-27, Task N3-GATE-ENG)

Scope: the ENG lane of N3 (the Android native UI delta gate). Pushed tip
44929c0 verified, tree clean at start (two sibling-lane reports, n3-legal
and n3-product, appeared in the tree DURING this run — the parallel-lane
reality; neither was read, per the isolation rule). The proposal under
review: the new separate-root `core-ffi` crate (clearfile-core-ffi) with
the ONE flat C ABI + the thin JNI shim + cbindgen as its build-dep;
`apps/android` (Gradle, KMP-shaped one target, Android Views); the CI
android job; my riding condition (the duplicate-scan bound-or-record) +
SEC's file-size pre-check; the two-session box. Every claim I could probe
was probed live under /tmp/n3-eng (the repo untouched — re-verified
byte-identical `core/Cargo.lock` after every build; git clean). The
proposal's core topology claim is TRUE, verified end to end (below); the
rest is shape-ruling, not feasibility.

**VERDICT: PROCEED-WITH-CONDITIONS**

## Conditions

1. **The riding condition CLOSES in substance this delta with the
   indexed-lookup bound (the stronger option, the standing default
   candidate), not the budget refusal:** in `core/src/json.rs::parse_object`,
   past a new `pub const` threshold (suggested `MAX_LINEAR_KEY_SCAN = 64` —
   the exact number is the session's to set and record), maintain a
   lazily built `std::collections::HashMap<String, usize>` mapping key →
   member slot, built when `pairs.len()` first crosses the threshold and
   used ONLY for find-or-insert (never iterated, so insertion order, the
   last-value-wins-at-first-position contract, and every byte of output
   are unchanged); below the threshold the existing linear scan stays.
   `MAX_OBJECT_MEMBERS` stays, with its O(n²) rationale comment updated.
   Battery extension (all in `core/tests/`): (a) the hostile-amplification
   test — a 10,000-member object plus ~100k duplicate-key occurrences
   (minutes of CPU today, R-ENG-1's exact surface) parses green, asserts
   last-wins-at-first-position, and asserts a generous wall-clock bound
   (< 10 s; two-plus orders of magnitude under the hostile case, with the
   CI-variance tolerance noted in-test); (b) threshold-straddling boundary
   tests (exactly-at-threshold: index not yet built; threshold+1: built;
   duplicates before/after the boundary update the same first-position
   slot); (c) the existing member-cap tests unchanged. The budget-refusal
   alternative is recorded ONLY as the in-session fallback if the index
   hits an unexpected wrinkle. Verification: `cargo test --locked` in
   `core` green (174 + the new tests); `rg -n 'MAX_LINEAR_KEY_SCAN'
   core/src/json.rs` shows the threshold + the updated cap comment.
2. **The file-size pre-check lands as a core-owned constant with
   app-side enforcement, BEFORE any read, in BOTH app pipelines:** the
   core stays pure (no I/O — its own module docs), so the shared constant
   (`pub const MAX_INPUT_FILE_BYTES: u64 = 512 * 1024 * 1024;` in the
   core, visible to every consumer; 512 MiB = 2× the 256 MiB STORE cap,
   generous over KB-scale legitimate envelopes) + enforcement in
   `apps/linux/src/main.rs::load_and_compute` (metadata check before
   `std::fs::read`) and in the Android app's file-open path (SAF size
   query before the stream read), refusing with a named message in the
   core's wording family ("The file is too large to open … 512 MiB …" —
   the session words it; the message is battery-pinned). Battery: the
   exact boundary via the pure decision fn (512 MiB accepted, 512 MiB + 1
   refused, message verbatim) + one sparse-file integration test proving
   the refusal happens without the read. Verification: the apps/linux
   suite green (5/5 + new); `rg -n 'MAX_INPUT_FILE_BYTES' core/src
   apps/linux/src apps/android` shows one constant, both enforcements.
3. **The JNI shim's host-test lane is honest only if the Java_\* symbols
   exist in the HOST-built .so — and the C header stays the flat ABI
   only:** compile the JNI shim under
   `cfg(any(target_os = "android", feature = "host-jni"))` (the exact
   shape I verified live: a `Java_…` symbol built for host exports from
   the host cdylib and binds + calls through `System.load` on this
   sandbox's JVM; unconditional compilation is also acceptable and
   simpler — the symbols are inert on a non-JVM host), with the CI host
   build enabling the feature; the JVM unit tests MUST call the Java_\*
   symbols (the proposal's own "through the JNI layer"), never a
   hand-rolled second wrapper, and assert golden-fixture parity there.
   cbindgen must NOT emit the Java_\* symbols into `clearfile.h` (my
   probe caught cbindgen happily emitting a `Java_…` fn into the header —
   place the shim in its own module and exclude it via the cbindgen
   config, or use the `only`/`exclude` parse config). Verification:
   `nm -D --defined-only <host .so> | grep Java_` shows the symbols;
   `grep -c Java_ core-ffi/clearfile.h` returns 0; the CI gradle test
   step green.
4. **The boundary discipline (one audit surface, one allocator):** every
   exported fn — flat ABI and Java_\* alike — wraps its body in
   `std::panic::catch_unwind(AssertUnwindSafe(…))` (unwind across
   `extern "C"` is UB; the core is panic-unlikely but not panic-proof),
   maps panic to the sentinel return + a thread-local last-error string
   in the core's wording family, and the ~dozen-fn surface keeps the ONE
   `clearfile_free_string` (all cross-boundary buffers Rust-allocated,
   freed only by it — the JVM side never frees Rust memory; the shim
   copies then frees). The crate keeps the default unwind profile (no
   `panic = "abort"` — catch_unwind requires it). Verification: the
   exported-fn count equals the catch_unwind-wrapped count (grep audit);
   the malformed-ZIP + hostile-input battery runs THROUGH the C boundary
   with no panic and named errors.
5. **The CI android job is CI-primary (the measured disk forbids any
   local android lane), additive to hygiene.yml, guards-first:** step
   order — (i) the fail-closed rustc guard (the existing pattern; note
   the ubuntu-latest (26.04) image ships Rust 1.100.0 + rustup 1.29.3,
   exactly the pinned toolchain version), `rustup target add
   aarch64-linux-android`; (ii) a fail-closed NDK identity guard
   asserting the PINNED version's path exists under
   `$ANDROID_HOME/ndk/<exact version>` (today's image: 27.3.13750724
   default, 29.0.14206865, 30.0.16248370 — never trust the default or
   the env, they drift weekly); (iii) `JAVA_HOME` set EXPLICITLY to the
   image's 17 or 21 (the image default is 25 — AGP compatibility is the
   session's to verify; never rely on the default); (iv) the pinned
   Gradle distribution via a fetcher in the fetch_rust_toolchain /
   fetch_tt_corpus pattern (sha256-pinned URL, ~131 MB measured) — the
   gradle-WRAPPER route commits `gradle-wrapper.jar`, a third-party
   binary the no-blob policy (own-authored allow-list only, verified)
   forbids WITHOUT an explicit recorded exception; pick one, record it;
   never the image's preinstalled Gradle 9.9.1 (unpinned drift); (v) the
   cdylib cross-build `--locked` `--target aarch64-linux-android` with
   the NDK clang as linker via env (no cargo-ndk dependency needed);
   (vi) the host .so (with the host-jni feature) + the JVM unit tests;
   (vii) `compileDebugKotlin`; (viii) cargo-deny over core-ffi's lock
   (its first external dep is cbindgen — condition 6). The AGP/Kotlin/
   androidx maven tree (~0.5–1 GB class, docs-ruled per the task's own
   probe boundary) lives only on the runner. Verification: the
   hygiene.yml delta is purely additive (existing jobs byte-identical —
   the N2 precedent audit); the first run live-green.
6. **The guard joins land same-commit with the scaffold:** `.gitignore`
   gains the apps/android gradle-output rules (`build/`, `.gradle/`,
   `local.properties`, `.kotlin/` — the `/apps/linux/target/` precedent
   at line 120) BEFORE any in-repo gradle state can exist; core-ffi's
   `deny.toml` lands with its FIRST commit (the N2 first-external-dep
   rule; cbindgen `=0.29.4` exact-pinned, the version verified live
   below); any new ≥32-hex-bearing provenance file joins the backup
   guard's known-hash allow-list in its landing commit (cite digests
   truncated in reports, per the convention). Verification: first
   core-ffi commit contains deny.toml; `git status` clean after a local
   host build of core-ffi.
7. **The execution box is TWO sessions (confirmed, N1/N2 precedent)
   with the checkpoint order that protects the riding condition:**
   session 1 = the json.rs index hardening + its battery + core
   174/174 re-verified FIRST (the intra-session checkpoint: hardening
   committed and green BEFORE any FFI work — a session death still
   closes the riding item), then the core-ffi crate + header + JNI shim
   + boundary discipline + host FFI tests + the JVM host-lane test
   green; session 2 = apps/android + the CI lane + the records/README.
   The slip rule stands (logged honestly, never silently extended; an
   extension needs a recorded owner ruling). Session 2 carries the
   repo's first-ever gradle work — if it overruns, the CI lane outranks
   app polish in the fallback order. Verification: the session-1
   checkpoint commit exists before any core-ffi path in the tree; the
   SESSION_LOG records the box state.

## Risks register

- R-ENG-5 (session-2 overrun, medium): the repo's first gradle/AGP
  bring-up is exploratory (no local android lane is possible — the NDK
  zip alone is 689 MB measured, unpacking to ~3 GB class against 1.6 GB
  free). Mitigations: CI-primary verification, the two-round CI-fix
  precedent from N2 runs #38/#39–44, the slip rule.
- R-ENG-6 (SDK drift, medium): the measured runner facts are a
  2026-11-27 snapshot (ubuntu-latest = Ubuntu 26.04; Gradle 9.9.1;
  JDK default 25; NDK default 27.3; platforms android-34…37.2) — the
  image updates weekly and any default can move. Mitigations: condition
  5's explicit-version guards; compileSdk pinned to a
  verified-present platform; the guard fails closed on drift rather
  than building against a surprise.
- R-ENG-7 (the JNI marshalling surface, low-medium): ~a dozen fns ×
  string/byte-buffer conversions is where the real bug class lives
  (UTF-8/UTF-16, truncation, invalid input), not in the pure core
  behind it. Mitigations: the JVM parity tests through the Java_\*
  layer, the malformed-ZIP battery through the C boundary, last-error
  on every failure path.
- R-ENG-8 (header dialect drift, low): the probe caught cbindgen's
  DEFAULT emitting a C++ header (`<cstdint>`, `extern "C"` C++-style);
  the session must pin `Language::C` (I verified the C emission too —
  `#include <stdbool.h>` C99 form) or record C++ as N4's dialect.
  N4/SPM consume whatever is recorded.
- R-ENG-9 (Android UI-thread compute, low, accepted-class): the
  synchronous load-then-compute on the UI thread (R-ENG-2's family)
  persists on Android — prototype-acceptable, same standing
  re-visit trigger (real import paths hardening).
- R-ENG-10 (probe footprint/cleanup, discharged): /tmp/n3-eng peaked at
  173 MB (target dir included) and is deleted at report close; the repo
  tree was verified byte-unchanged except this report.

## Advisories (non-binding)

- One target only: aarch64-linux-android. armv7 is a GA-lane decision
  (a second .so multiplies CI + audit surface for no N3 consumer);
  x86_64 only ever matters for an emulator lane, which N3 explicitly
  does not run.
- KMP-shaped with exactly one target is acceptable per ADR-017's
  language, but a plain `kotlin-android` application module is simpler
  for the same single-target outcome; either shape is fine — record
  which. The Android-Views (no Compose) + SAF-open + bundled-golden-
  fixture + MD3-from-seed-via-palette-FFI demo shape is sound.
- cbindgen route: I took the build-dependency route with an exact pin
  (`=0.29.4`, the newest, rust_version 1.74, compatible with the pinned
  1.100.0), matching the proposal's own shape; `cargo install` would
  also work but moves the header generation out of the crate's build.
- Keep the FFI surface at the ≈a-dozen-fn set from ADR-017 (compute,
  import_txf, export_txf, inspect_tax, envelope encode/decode+migrate,
  palette scheme_role, last-error, free) — every added fn multiplies the
  marshalling surface (R-ENG-7).
- The 512 MiB figure: record the 2×-STORE-cap rationale beside the
  constant so a future cap move carries its reasoning.
- minSdk: record the chosen API level beside the NDK clang wrapper name
  (e.g. `aarch64-linux-android24-clang` ⇒ API 24) so the linker choice
  and the manifest floor cannot drift apart.
- The per-OS order stands: N3 produces the cbindgen header that N4
  (Win32/Direct2D) consumes — doing N3 first DE-RISKS N4; macOS stays
  last (unverifiable from this sandbox). No engineering demand to
  re-order.

## Files read + verification log

Files read: harness/memory/ROADMAP.md (547–670, the epilogue + version
planes), harness/memory/DECISIONS.md (ADR-017, 495–574, the FFI seam +
annexes), harness/adversarial/reports/2026-11-26-n2exit-engineering.md
(all — the riding condition's terms), harness/adversarial/reports/
2026-11-26-n2-security.md (all — R1/R2, the pre-read candidate),
harness/adversarial/CONSENSUS.md (1190–1489, the N2 gate + exit + the
riding-list discharge: "closure before any FFI wiring, and N3 IS the FFI
wiring"), harness/memory/STATE.md (341–382, this gate's agenda),
core/src/lib.rs (all), core/src/json.rs (480–539, the duplicate-scan
branch + caps survey), core/src/envelope.rs + txf.rs + tax_inspect.rs +
palette.rs (public-surface survey), apps/linux/src/main.rs (all — the
ONE pipeline fn + the ZIP-signature dispatch + the wording family),
apps/linux/Cargo.toml + build.rs, .github/workflows/hygiene.yml (all —
the linux-app job pattern), .gitignore (109/120 area),
scripts/sandbox_backup.sh (126–130 area), scripts/check_binary_blobs.py
(policy header — own-authored allow-list only).

Runs (this session, tip 44929c0, /tmp/n3-eng only):

- **THE TOPOLOGY PROBE (the proposal's core claim — TRUE, verified
  end to end):** a scratch crate at /tmp/n3-eng/n3ffi with
  `clearfile-core = { path = "/home/z/my-project/core" }`,
  `crate-type = ["cdylib"]`, cbindgen `=0.29.4` as BUILD-dep (route
  noted), one build.rs calling `cbindgen::generate`, and two
  `#[no_mangle] pub extern "C"` fns (one palette-path, one
  compute-path over the real core): (i) `cargo build` (pinned
  toolchain 1.100.0, CARGO_TARGET_DIR=/tmp/n3-eng/target) **succeeded**
  in 44 s; (ii) `sha256sum -c` of core/Cargo.lock (34e0b4bc…d1baa,
  cited truncated) **byte-identical after every build**, `git status`
  clean in the repo — the separate-root topology keeps the zero-dep
  assertion intact, exactly as at N2; (iii) the header **emitted with
  `extern "C"` symbols** — default C++ dialect first, then pinned
  `Language::C` (`#include <stdbool.h>` form) on rebuild, both shown;
  (iv) `nm -D` shows `n3ffi_primary_color`/`n3ffi_compute_refund` as
  `T` exports of libn3ffi_probe.so; (v) cbindgen **0.29.4** resolved
  under the exact pin (newest, pubtime 2026-06-09, not yanked), probe
  lock = 53 packages, nearly all served from the local cargo registry
  cache. Note: the probe also caught cbindgen emitting a `cfg`-gated
  `Java_…` fn into the header — condition 3's header-cleanliness rule.
- **The JVM host-lane probe (end to end on this sandbox's Java
  21.0.13):** the JNI symbol `Java_Probe_version` behind
  `cfg(any(target_os = "android", feature = "host-jni"))` built for
  HOST, exported (`nm -D` shows it), and a `System.load` +
  `native`-method Java class called it successfully through the JVM
  (printed `version=41`) — proving the host-built .so + Java_\*
  name-binding + call lane with no Android anything. The probe's flat
  C fns declared as Java `native` methods correctly FAILED with
  `UnsatisfiedLinkError` (Java binds Java_\*-shaped names only) —
  demonstrating the exact boundary rule: the flat C ABI is exercised by
  Rust-side host tests; JVM tests go through the JNI shim.
- **The disk/size measurements (curl HEADs, no downloads beyond the
  53-package registry cache):** Android cmdline-tools zip
  commandlinetools-linux-11076708_latest.zip = **153,607,504 B
  (~147 MB)**; NDK r28b linux zip = **722,264,879 B (~689 MB)** (HEAD
  only, never downloaded — with ~1.6–1.8 GB free and a multi-GB unpack,
  any local NDK/android lane is INFEASIBLE; the probe itself peaked at
  173 MB); gradle-8.14.3-bin.zip = **137,393,837 B (~131 MB)**.
- **The runner-image facts (fetched live, 2026-11-27):**
  actions/runner-images main README + images/ubuntu/Ubuntu2604-Readme.md
  (15,898 B) — ubuntu-latest = **Ubuntu 26.04**; Android section:
  cmdline-tools 20.0, build-tools 34.0.0–37.0.0, platform-tools 37.0.1,
  platforms android-34…android-37.2, **NDK 27.3.13750724 (default),
  29.0.14206865, 30.0.16248370**; `ANDROID_HOME=/usr/local/lib/android/sdk`
  + NDK env vars; Gradle **9.9.1** preinstalled; JDKs 11/17/21/**25
  (default)**; **Rust 1.100.0 + rustup 1.29.3** (the pinned version,
  and rustup presence means `rustup target add aarch64-linux-android`
  works on the runner — it cannot on this sandbox's standalone
  tools/rust, which has no rustup: verified by the bin listing).
- `df -h /` before/after: 1.8 GB → 1.6 GB free across the session (the
  probe's 173 MB + rounding).
- /tmp/n3-eng deleted at report close (the cleanup note below).
