# ADV-SEC — N3 exit gate (2026-11-27, Task N3-EXIT-SEC)

Reviewer: ADV-SEC, the N3 EXIT lane. Scope: my entry conditions (SEC-1…SEC-11) as
consolidated into the binding 16-item ledger (CONSENSUS 1496–1711), plus the exit-only
items — the commit-order facts, the variant preconditions, the live-CI evidence
posture, and the supply-chain residue of the whole delta `44929c0..2f3efa1` (13
commits, from the hardenings 3493203 through the two-session close). Method:
read-only probes only — full reads of the entire seam (`core-ffi/clearfile.h`,
`src/lib.rs`, `src/jni.rs`, the battery, the workflow), targeted greps, and git
history probes (merge-base ancestry, pickaxe, name-only/stat diffs, tag
inspection); no cargo run (the boundary battery 10/10 + core 176/176 + apps/linux
7/7 are the in-sandbox facts recorded at the session closes; the Android lane is
CI-primary, its live evidence being hygiene run 45948447173 GREEN on ae9e078, all
six jobs, per the close record). The sibling exit lanes' reports were neither
read nor written (isolation rule).

The delta discharges my lane almost completely, verified by direct read: the ABI
contract is pinned in the header exactly as conditioned (strings/bytes only, every
text input a `(const ptr, explicit len)` pair, zero path parameters, the two
documented return classes — owned buffers freed only by `clearfile_free`, the
borrowed thread-local `last_error` never freed); zero `fs::` in `core-ffi/src`
(the two grep hits are `build.rs`'s build-time header copy and the tests' fixture
reads — build/test lanes, not the shipped library); panic containment holds in
substance (9 of 11 C exports wrap their whole body in the one shared
`ffi_guard`, `jni.rs`'s 9 `Java_*` exports are 9-for-9 wrapped, and the two
unwrapped exports — `clearfile_last_error`, `clearfile_free` — are the guard's
own reporting/dealloc pair, panic-free by construction; the feature-gated
panic-injection test through the real guard is in the battery and the CI runs it
`--features panic-hook-test`); the JNI shim marshals `jbyteArray` end-to-end
with zero `jstring`/`GetStringUTFChars`/`NewStringUTF` anywhere (the only grep
hits are the doc comments banning them); the hardenings commit 3493203 is a
verified ancestor of the first core-ffi commit f496ee4 (both riding batteries
read directly: the hostile-amplification case with the loose 10 s wall-clock +
last-value-wins assertions, the threshold-straddling pair with cross-boundary
slot identity); the 512 MiB bound is enforced at all four surfaces (the core
const + pure fn, the apps/linux metadata pre-check with the sparse-file battery,
the Android SAF length query, and core-ffi's `check_size` at every entry with
the exact-boundary pair); the CI android job is guards-first, SHA-pinned with
zero NEW actions, `--locked` on every cargo invocation, `contents: read`,
`timeout-minutes: 45`, no secrets, and NO uploads (no `upload` step anywhere in
hygiene.yml); the guard joins landed same-commit-before-first-state (verified by
pickaxe: `/core-ffi/target/` at f496ee4, the android set at 7030002), the backup
≥32-hex scan-path list carries `core-ffi` (sandbox_backup.sh:132), and no new
known-hash manifest landed (no fetcher class — CI uses the preinstalled,
guard-asserted tools), so no allow-list join was owed; the variant preconditions
hold exactly (zero `clearfile/`+`src/` paths in the delta; release.yml,
core/Cargo.toml, core/Cargo.lock byte-unchanged; new planes only — core-ffi
0.1.0 `publish = false`, apps/android versionName 0.1.0; no tags at the tip;
nothing shipped or uploaded). ONE ledger clause did not land: item 9's
"`dependencyLocking` + the committed lockfile(s)" — gradle dependency locking is
absent from apps/android (`rg 'dependencyLocking' apps/android` → zero) and no
lockfile is committed, and the session record neither landed it nor recorded a
deviation ruling. The material risk is bounded (repositories google()/mavenCentral
only, exact-pinned AGP 9.5.3 + Kotlin 2.4.21, and the one external artifact of
the whole build is the test-scope JUnit 4.13.2, never linked into the APK —
assembleDebug produces an undistributed debug APK under the nothing-ships
discipline), so it is a condition, not a block.

**VERDICT: PROCEED-WITH-CONDITIONS (1)**

## Conditions

1. **Land ledger item 9's unlanded clause — gradle dependency locking for
   apps/android — or record the owner ruling that accepts the exact-pin-only
   posture.** The binding ledger (CONSENSUS 1615–1622, my entry SEC-8) requires
   "`dependencyLocking` + the committed lockfile(s)"; the session-2 record
   (7030002) landed every other clause (no wrapper jar, the fail-closed Gradle
   version guard, google()/mavenCentral only, exact-pinned plugins, the minimal
   dependency set) but is silent on this one — a silent omission, not a recorded
   deviation. The gap leaves AGP's transitive resolution unlocked (the direct
   pins are exact; the transitive tree is not). Ride to N4's gate, where the app
   lane next moves: either (a) enable `dependencyLocking` for the configurations
   that resolve (the plugin classpath included) and commit the generated
   lockfiles, or (b) a recorded owner ruling accepting the exact-pin-only
   posture for the demo plane. Checkable:
   `rg -n 'dependencyLocking' apps/android` → non-empty + a committed lockfile
   (`git ls-files 'apps/android/**/gradle.lockfile'` non-empty), or the ruling
   recorded in STATE/SESSION_LOG before N4's gate convenes.

## Risks register

1. **Runner-image toolchain drift** (ubuntu-latest remaps; SDK/NDK/JDK/Gradle
   versions move silently). The fail-closed guards turn drift into a red build —
   proven live twice this delta (round 3: the exact Gradle pin caught the
   fleet's 9.9.1→9.9.2 mid-rollout; round 4: the NDK path assertion). Residual:
   the job reds until re-pinned. Accepted, as recorded at entry.
2. **The unlocked gradle transitive tree until condition 1 lands.** Bounded by
   google()/mavenCentral-only repositories, exact-pinned direct plugins, the
   single test-scope external artifact, and the nothing-ships discipline; the
   condition closes it at N4.
3. **The two guard-exempt exports** (`clearfile_last_error`,
   `clearfile_free`) are panic-free by construction today (a RefCell read with
   no reentrancy; a null-checked `CString::from_raw`). Residual: a future edit
   that adds panicking code to either would sit outside the guard's view — the
   exported-count==guarded-count audit discipline should carry them as
   explicitly named exemptions, not as unexamined gaps.
4. **512 MiB on Android RAM ceilings** (carried from entry risk 6): the SAF
   pre-check refuses beyond the bound before any read, but a just-under-bound
   file can still ANR/OOM a low-RAM device. Accepted for the demo plane; the
   recorded tighter-bound option stands.
5. **JNI-surface creep at N4/N5**: the shim is verified thin now (every
   `Java_*` export marshals and calls the same-named C function; zero engine
   logic in Kotlin). The N4/N5 consumers must re-assert the thin-shim shape when
   they touch the seam.

## Advisories (non-binding)

1. **The "existing jobs byte-identical" letter gave way to recorded
   maintenance**: rounds 4–5 added the Xvfb bounded display-socket wait to the
   LINUX job and repaired the workflow file's own python-continuation mangling
   (both honestly logged in SESSION_LOG). Posture is unchanged (same SHA-pinned
   actions, same permissions, still no secrets/uploads); only the additive claim
   should be read posture-scoped, not byte-scoped.
2. **The Kotlin 512 literal** (MainActivity.kt:137 hardcodes `512L * 1024 *
   1024` rather than referencing the core's constant — Kotlin cannot reference
   the Rust const). The boundary re-enforces via `check_size`, so the Kotlin
   check is UX-only and the defense holds regardless; a parity comment or test
   is cheap insurance if the bound ever moves.
3. **Record precision on "no fs anywhere in core-ffi"**: the exact truth is
   zero `fs::` in `src/` (verified by full read), `build.rs` copying the header
   into `OUT_DIR` at build time (standard cbindgen pattern), and the tests
   reading fixtures. The shorthand is fine in session notes but the records
   should keep the build/test-lane distinction when precision matters.
4. **The Gradle 9.9-series guard** tolerates in-series patch drift by design
   (the recorded round-3/4 resolution); revisit exactness at the GA lane.
5. **JUnit 4.13.2 (EPL-1.0)** is test-scope only (`testImplementation`; never
   linked into the APK) — LEGAL lane territory, crossing my supply-chain view
   per the entry advisory-3 precedent.
6. This report cites every digest truncated first8…last6 (the action pins
   below); no ≥32 contiguous hex — no backup allow-list join needed (the
   N2-exit advisory-3 precedent).

## Files read + verification log

- `harness/adversarial/CONSENSUS.md` 1496–1711 (the N3 delta-scoped gate's
  16-item binding ledger + the material corrections); `harness/adversarial/
  reports/2026-11-27-n3-security.md` (all — my own entry conditions SEC-1…11);
  `harness/adversarial/ROLES.md` (all); `harness/memory/SESSION_LOG.md`
  2240–2393 (the two N3 sessions, the eleven-round CI record, the close).
- Full reads: `core-ffi/clearfile.h` (99 lines — the contract: (ptr,len) pairs
  throughout, zero path params, zero struct mirrors, both return classes
  documented, zero Java_ symbols); `core-ffi/src/lib.rs` (566 — the ABI + the
  ONE shared `ffi_guard`; my count audit: 11 `#[no_mangle]` C exports, 9
  `ffi_guard`-wrapped incl. the `panic-hook-test`-gated injection hook,
  `last_error`/`free` the panic-free reporting/dealloc pair; `check_size` at
  every payload entry); `core-ffi/src/jni.rs` (285 — 9 `Java_*` exports, 9/9
  wrapped, `JByteArray`/`jbyteArray` end-to-end, errors as
  IllegalStateException carrying the core's verbatim message, the palette
  0-sentinel surfaced); `core-ffi/tests/boundary.rs` (targeted — the 512 MiB
  exact-boundary pair at :350-361, the panic-injection proof at :365-376, the
  golden fixtures + the 550-case differential corpus through the boundary, the
  last_error/free contracts); `core/src/json.rs` 975–1104 (the hostile-
  amplification battery with the 10 s wall-clock + the straddling pair);
  `.github/workflows/hygiene.yml` (all 397 — the additive android-app job:
  guards-first, the four fail-closed identity guards, `--locked` on all four
  cargo invocations, `contents: read` at workflow + job level,
  `timeout-minutes: 45`, no secrets, zero upload steps, zero NEW actions —
  checkout@11d5960a…677262 and EmbarkStudios/cargo-deny-action@81891abc…ea74fda
  are the existing pins; the header freshness check `cargo build --locked` +
  `git diff --exit-code`); `scripts/sandbox_backup.sh` (targeted — the ≥32-hex
  scan path list at :132 `docs clearfile src scripts fixtures harness core
  core-ffi apps`; the known-hash exclude discipline: no new manifest landed,
  `*.lock` excluded from the hex heuristic so core-ffi's 74-package lock is
  covered by construction); `.gitignore` (targeted — `/core-ffi/target/` :110
  and the android set :127-134 incl. `local.properties` and `*.keystore`).
- Greps (read-only): `fs::|jstring|GetStringUTFChars|NewStringUTF` over
  core-ffi → src/ clean (hits only in the banning doc comments, build.rs,
  tests); `MAX_LINEAR_KEY_SCAN` family over core (the :81 const, the :492-553
  index, the batteries); `MAX_INPUT_FILE_BYTES|INPUT_TOO_LARGE_MESSAGE|
  input_file_too_large` over the repo (core/src/lib.rs:274-284 the const +
  message + pure fn; apps/linux/src/main.rs:65-66 the metadata pre-check,
  :625-652 the battery incl. the sparse 512MiB+1 refusal; core-ffi/src/lib.rs:
  122-127; MainActivity.kt:137 the SAF length query); the android-lane grep
  (System.load at NativeJniHostTest.kt:36 behind the `clearfile.host.lib`
  property with a fail-fast instruction; `implementation(project(":shared"))`
  + `testImplementation junit 4.13.2` only; `dependencyLocking` → ZERO — the
  condition; the zero-permission manifest + `allowBackup="false"`).
- Git probes (read-only, over 44929c0..2f3efa1): the 13-commit chronological
  list; `git merge-base --is-ancestor 3493203 f496ee4` → HARDENINGS-FIRST-OK;
  pickaxe `/core-ffi/target/` → f496ee4 (the FIRST core-ffi commit, before any
  build) and `local.properties` → 7030002 (the FIRST apps/android commit,
  before any gradle state); `git diff --name-only -- clearfile/ src/` → empty;
  `git diff --stat -- .github/workflows/release.yml core/Cargo.toml
  core/Cargo.lock` → empty; `git tag --points-at 2f3efa1` → empty;
  `git show 2f3efa1:core-ffi/Cargo.toml` (version 0.1.0, `publish = false`,
  cbindgen `=0.29.4` as build-dep, jni 0.21 optional behind `host-jni`) and
  `git show 2f3efa1:apps/android/app/build.gradle.kts` (versionCode 1,
  versionName 0.1.0 — no version movement).
- CI evidence (recorded, not re-run — the JRE-only sandbox forbids the lane):
  hygiene run 45948447173 GREEN on ae9e078, all six jobs end-to-end, incl.
  cargo-deny over core-ffi's 74-package lock — the Android lane's live
  verification. Could NOT verify from this sandbox: the runner image's state
  today (mediated by the fail-closed guards — the accepted posture) or the JVM
  test executed locally. No cargo run this lane; nothing modified outside this
  report; no /tmp scratch left behind.

`git status --short` after filing (run live, verbatim):

```
?? harness/adversarial/reports/2026-11-27-n3exit-engineering.md
?? harness/adversarial/reports/2026-11-27-n3exit-legal.md
?? harness/adversarial/reports/2026-11-27-n3exit-product.md
?? harness/adversarial/reports/2026-11-27-n3exit-security.md
```

Only the fourth line is mine (`…n3exit-security.md`, this report — the only
file this lane created or modified). The three sibling reports are the parallel
exit lanes' own filings, landed concurrently while I worked — NOT read, per the
isolation rule; the tree is otherwise clean (no tracked-file changes, no
drift).
