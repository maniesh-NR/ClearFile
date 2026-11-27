# ADV-PROD — N3 exit gate (2026-11-27, Task N3-EXIT-PROD)

**Scope:** the N3 EXIT gate (the Android native UI over the Rust core; ADR-017's
epilogue, third stage), ADV-PROD lane — roadmap rightness, stage discipline, the
working-app bar, single-maintainer sustainability, records honesty. The box
under review: the N3 delta `44929c0..2f3efa1` (pushed tip `2f3efa1`, the
session-2 close backup; the working tree clean at my probe — `git status
--short` empty, verified live before this report). The record claims: the box
closed at exactly two sessions (session 1 = the hardenings + the core-ffi
crate, cargo-only; session 2 = the CI-primary app + the CI android lane), the
eleven-round CI-fix record honestly kept, the first live-green android run
(hygiene run 45948447173 GREEN on ae9e078, all six jobs end-to-end incl.
assembleDebug + the JVM tests through the real `Java_*` seam + cargo-deny over
core-ffi's 74-package lock), and the variant preconditions held. I ruled every
condition of my lane's entry report (the 8, as consolidated into the gate
record's 16-item ledger) adversarially, with my own live probes over the pushed
tip — the delta shape, the KMP build files, every Kotlin source in
`apps/android`, the JVM host test, the README rows, the harness_check
families, the workflow, and the tag/release surfaces. Every condition
discharged; the residuals I found are advisory-level only (the exit-close
bookkeeping riders per the N2 pattern, and the run-on-commit vs tip naming).

VERDICT: **EXIT-PASS** (8/8 conditions discharged; advisory residuals only —
none blocks N3's exit)

## Conditions

1. **The README rows (entry 1/6) — DISCHARGED.** `apps/android` (README.md
   line 25): the honest viewer scope (KMP-shaped exactly `androidTarget()`,
   no second Kotlin target; Android Views, no Compose, no AndroidX — "the
   recorded zero-AndroidX posture"; the bundled example "PULLED from the
   shared `fixtures/tax/` family at build time"; the SAF open of
   `.clearfile.json`/`.tax`; compute via the same composed pipeline the Linux
   app runs; MD3-from-seed via the palette FFI at the same corpus seed), the
   full honesty set (the three-fact demo disclaimer, the no-AI/no-network
   note with "the manifest requests **zero permissions**, so the network
   claim is OS-enforced", the IRS/Intuit non-affiliation line, the prototype
   label), the CI lane enumerated with assembleDebug named, and the interim
   statement verbatim: "A demonstration prototype, unreleased — the Flutter
   app remains the shipped Android product." `core-ffi` (line 26): the FFI
   seam crate row (`publish = false`, its own version plane, the ONE flat C
   ABI ≈a dozen fns, cbindgen =0.29.4 **MPL-2.0, build-time-only** — the
   refuted dual id nowhere, the committed header freshness-checked in CI, the
   cdylib, the thin jbyteArray JNI shim, the boundary battery through the
   seam). *Checked:* `rg -n "apps/android|core-ffi" README.md` → both rows,
   every named element present.
2. **The KMP shape-matches-record (entry 2/6) — DISCHARGED.**
   `apps/android/shared/build.gradle.kts`: `org.jetbrains.kotlin.multiplatform`
   + `com.android.kotlin.multiplatform.library` (AGP 9's KMP-library plugin —
   the recorded round-6 ruling; it CREATES the android target via
   `androidLibrary`), EXACTLY one Kotlin target (no iOS/JVM/desktop/JS — the
   ADR-017 "KMP second target: None" settlement held as-written, never
   silently simplified). The model lives in **androidMain** (Native.kt, with
   the recorded round-7 ruling in its header: "a second target would move it
   to commonMain"). **Zero engine logic in Kotlin — verified by reading every
   Kotlin file in the delta:** Native.kt = the display model (LoadedReturn +
   role names + THEME_SEED 0xFF00696E, the corpus seed); NativeAndroid.kt =
   the `external fun` JNI surface (one per flat-C fn) + `System.loadLibrary`
   + org.json display-glue parsing of the boundary's own JSON (string
   formatting only — every value from the core) + the palette lookup;
   MainActivity.kt = platform Views UI, the SAF open, the 512 MiB pre-read
   size check (`length > 512L * 1024 * 1024` — the only arithmetic in the
   app, a bound comparison, not tax logic), the light/dark toggle. No
   bracket, rate, phase-out, or deduction constant anywhere in Kotlin.
3. **The working-app bar (entry 3/6) — DISCHARGED.** (i) assembleDebug
   proven: hygiene.yml runs `:app:assembleDebug :app:testDebugUnitTest` and
   the `unzip -l` proof asserts `lib/arm64-v8a/libclearfile_core_ffi.so` is
   packaged into the APK ("beyond compileDebugKotlin" — the condition's
   exact demand); the green run 45948447173 on ae9e078 covers it end-to-end
   (SESSION_LOG's close: "the .so packaged into the installable debug APK —
   the unzip proof"). (ii) the JVM host test (NativeJniHostTest.kt):
   `System.load`s the HOST-built cdylib via `-Dclearfile.host.lib` and calls
   the REAL `Java_*` mangled symbols through `external fun` — asserting
   fixture 01 of the SHARED `fixtures/tax/` family (named by path:
   `../../../fixtures/tax/01-tax-table-single-25225.json`) at its own pinned
   values (totalIncome 40975, taxableIncome 25225, totalTax 2788.5 — the
   raw-value ruling honestly recorded as CI round 11), plus the verbatim
   core error ("The file is not valid JSON." as IllegalStateException) and
   the palette seam (opaque, light≠dark, unknown-role throws). The bundled
   fixture is PULLED by a gradle copy task from the shared family (app
   build.gradle.kts line 48) — never newly authored. (iii) the named
   non-verifications: the no-emulator lane is named in the test's own header
   ("the no-emulator verification lane … proven without an emulator") and the
   session-2 record carries the honest per-lane statuses — the android lane
   is CI-ONLY (JRE-only sandbox, no SDK/NDK/gradle), no instrumented run, no
   on-device run (nothing in any record claims one; the run record lists
   exactly what ran). (iv) per-lane live statuses recorded: "core 176/176 +
   the boundary battery 10/10 + apps/linux 7/7 verified in-sandbox;
   the ANDROID lane is CI-ONLY" — the run number + commit named, never an
   unqualified "landed".
4. **The Stage-2 slip re-agenda — the MANDATORY item, the SEVENTH surfacing
   (entry 4/6, the strengthened duty) — RESTATED HERE IN FULL.** The pinned
   enumeration: 1 the N1-exit surfacing, 2 the N2-entry, 3 the
   N2-exit-convening, 4 the N2-exit-close, 5 the 2026-11-27 restatement, 6
   the N3 entry gate — **7 THIS exit gate**. The three owner options,
   verbatim-in-substance: **(a) fund a T3 session** (the MSI-record keystream
   decompile chase at payload offset 0x24000 + `tax-modern.md`, debt D42),
   **(b) supersede the RE-protocol namespace rule** that requires the modern
   format's DoD spec, **(c) the default re-agenda** (the slip keeps
   re-agenda-ing at every convened gate until ruled). **No ruling received
   across SIX prior surfacings; (c) continues; the next surfacing rides with
   the NEXT convened gate — N4's delta-scoped gate.** The count is pinned by
   enumeration; the gate record's item 14 pinned 1–6, and this report pins 7.
5. **The N4/N5/N6 pre-positioning (entry 5/6) — DISCHARGED in the gate
   record; no updates forced.** CONSENSUS's 2026-11-27 N3 gate record, ledger
   item 16, carries all three: **N4** — no mingw in-sandbox (re-measured at
   the entry gate), the two toolchain lanes (a portable user-space mingw
   cross-build from Linux, or CI windows runners building natively), N4's
   gate ruling the toolchain lane, the runner's Rust pin, its own
   working-app bar — and the first C-header consumption by C++ (Win32 +
   Direct2D) is carried in the ROADMAP N4 bullet + the README's core-ffi row
   ("the committed N4/N5 import contract"). **N5** — the live-verification
   list (the macos-latest image list, the label resolution, the macos-13
   retirement window) + the recorded PROD position (macos-latest CI alone
   satisfies the demo bar under the per-lane discipline, the
   single-maintainer risk recorded, any macOS GA owing an owner-side build
   or the recorded acceptance). **N6** — the wasm target for the std-only
   core, the TS engine's retirement per ADR-016, the parity suites'
   survival rule, and the epilogue's OWN terminal freeze declaration (never
   an earlier stage's). My cheap update: none needed beyond this
   confirmation — the facts are current as of the box close.
6. **The box discipline (entry 6/6, first half) — DISCHARGED.** Exactly TWO
   sessions: session 1 = the hardenings (the indexed-lookup duplicate-scan
   bound in core/src/json.rs + the 512 MiB pre-check with its SAF and
   apps/linux retrofit) green + committed BEFORE any FFI work, then the
   core-ffi crate + header + shim + boundary batteries (the checkpoint
   order held — a session death would have left items 1–7 landed); session
   2 = the CI-primary app + the CI lane + the records. The eleven-round
   CI-fix record honestly kept — including SELF-attributed bugs ("the real
   root cause of 6–7: the model file had NO package declaration (my own
   bug)"; "MainActivity's … call sites (my bugs, fixed)"; round 11's
   rounded-pin-vs-raw-value assertion), the fleet-mid-rollout Gradle catch
   (9.9.1/9.9.2 both live — the guard failed closed exactly as designed),
   and the Xvfb race fix. The box closed with every lane green — the
   red-close absorption rule never fired, and no session was silently
   extended.
7. **The bookkeeping set (entry 7/8, first half) — DISCHARGED at the box
   close, with the exit-close riders named.** README rows (Condition 1);
   `scripts/harness_check.sh` families verified live (`rg -n "core-ffi|
   apps/android" scripts/harness_check.sh` → the 8-file core-ffi scaffold
   surface check, the zero-`Java_`-in-header check, the core-lock=1-package
   vs core-ffi's own ≥2-package lock topology check, the backup scan-path
   join); `.gitignore` guard-order held (the delta is purely additive:
   `/core-ffi/target/` + the apps/android set — `.gradle/`, `build/`,
   `app/build/`, `local.properties`, keystores — with the guard-order
   comment); SESSION_LOG entries per session (both present, the close entry
   appended at the tip); STATE refreshed to the session order + "the N3 EXIT
   gate convenes after the box closes (the slip's SEVENTH surfacing rides
   with it)". The ROADMAP N3 bullet carries the full ENTERED record with the
   box + the ledger pointer; its **exit-outcome rewrite (gate status →
   CLOSED (exit …), the sessions, the deliverables — the N1/N2 bullet
   pattern) and STATE's post-exit refresh are THIS gate's close actions,
   not gaps**: the N2 exit followed exactly this order (box close → exit
   gate → the close's record refresh).
8. **The variant preconditions (entry 8/8, second half) — ALL HELD, verified
   live.** Zero `clearfile/`+`src/` top-level paths in the N3 delta
   (`git diff --name-only 44929c0..2f3efa1 | grep -E '^(clearfile|src)/'` →
   empty, grep exit 1 — the only core-tree touches are the recorded riders:
   core/src/json.rs + core/src/lib.rs); `core/Cargo.toml` + `core/Cargo.lock`
   byte-unchanged (diff-stat empty); release.yml byte-unchanged (diff = 0
   bytes); no new tags (`git tag` → exactly v1.0.0, v1.0.1, v1.1 — the
   newest 2026-11-26, before N3); hygiene.yml's delta is PURELY ADDITIVE
   (136 `+` lines, ZERO deletions — the "existing jobs byte-identical"
   ledger item held literally, even through the Xvfb race fix, which ADDED
   the bounded display-socket wait); the version planes: core-ffi
   `version = "0.1.0"` + `publish = false`, apps/android `versionName
   "0.1.0"` / `versionCode 1` — both new own planes, no app-semver or
   schema movement; the manifest has NO uses-permission element at all +
   `allowBackup="false"`; the CI android job carries permissions
   contents:read and NO uploads — nothing shipped, uploaded, or tagged.

## Risks register

- **The run-on-commit vs tip gap (honest, named, bounded):** the green run
  45948447173 is on ae9e078, and the pushed tip 2f3efa1 is exactly ONE
  commit ahead — measured: `git diff --stat ae9e078..2f3efa1` → 1 file,
  harness/memory/SESSION_LOG.md only (+49 lines, the close entry; zero
  code/workflow delta). The record states the run's commit honestly rather
  than claiming the tip. Residual risk: a future reader conflates the two;
  mitigation: Advisory 1 (the exit-close line names the gap).
- **The explicit "no on-device run" naming is implicit, not checklist
  -verbatim:** the entry Condition 3(iii) asked the records to NAME the
  non-verifications; the session-2 close names the lane statuses (android =
  CI-only, JRE-only sandbox) and the test header names the no-emulator
  lane, but the phrase "no instrumented run, no on-device run" never appears
  verbatim in the close entry. Nothing overclaims (the exact opposite of
  the N2 failure mode), so this is advisory — see Advisory 2.
- **The eleven-round CI tail as a maintenance-cost datum:** N2 took four
  rounds WITH a local lane; N3 took eleven with the lane CI-only. The
  record is honest about it; the cost curve is the single-maintainer
  sustainability question the per-OS stages exist to answer — N4 (Windows)
  repeats the pattern against a header-consuming C++ compiler; the risk is
  N4's round-count, not N3's record.
- **`extractObject` in the JVM test** is a test-only brace-depth JSON
  scanner (no org.json in the unit-test classpath) over controlled fixture
  data — bounded by the fixture-corpus-only comment; acceptable, but N4's
  C++ test lane should not copy the pattern beyond controlled data.

## Advisories (non-binding)

1. **The exit-close CONSENSUS/ROADMAP line should name the run-vs-tip gap
   explicitly** — "hygiene run 45948447173 GREEN on ae9e078; the tip
   2f3efa1 adds only the SESSION_LOG close entry (measured: 1 file, +49
   lines, zero code delta)" — the honest-per-lane-status discipline applied
   to the commit dimension too. Cheap, one sentence.
2. **Restate the non-verification checklist verbatim at the exit close**
   ("no emulator/instrumented run — GitHub-hosted runners have no KVM; no
   on-device run — no owner-side smoke happened; the JVM host lane +
   assembleDebug are the working-app evidence") — closes the Condition-3
   wording gap at zero cost; the owner-side device smoke remains open per
   the entry Advisory 3 (recorded as not-done, never assumed).
3. **The exit-close bookkeeping riders (the N2 pattern, this gate's close):**
   ROADMAP N3 bullet → CLOSED (exit PASSED) + the sessions/deliverables;
   STATE header + "Immediately next" → the exit outcome + the standing
   next-surfacing line (N4's gate); DEBT.md D42 unchanged (no new debt
   opened by the box — confirm at close); CONSENSUS's exit line pins the
   SEVENTH surfacing + the "next rides with N4's gate" handoff.
4. **N4's gate inherits the pinned agenda as-is** (no-mingw measured fact,
   the two toolchain lanes, the first C++ consumption of the committed
   header, the runner's Rust pin, its own working-app bar) — no
   pre-positioning update is owed before it convenes; N5's live-verification
   list and N6's freeze-declaration rule likewise stand as recorded.

## Files read + verification log

**Read:** the entry report `harness/adversarial/reports/2026-11-27-n3-product.md`
whole (the 8 conditions as ruled above); CONSENSUS.md 1496–1710 (the N3
delta-scoped gate record: the 16-item consolidated ledger, the slip's
sixth-surfacing enumeration at item 14, the N4/N5/N6 pre-positioning at item
16, the "N3: ENTERED" outcome); SESSION_LOG.md 2140–2394 (the N2 exit close →
the 2026-11-27 bootstrap + riding-list discharge (the FIFTH surfacing) → the
N3 gate entry (the SIXTH) → N3 session 2 (the app + CI lane landing, the
honest per-lane statuses) → the session-2 close (run 45948447173 GREEN on
ae9e078, all six jobs; the eleven-round honest record incl. the self-attributed
bugs; the box closing at exactly two sessions; the SEVENTH-surfacing
handoff)); STATE.md 340–382 (the quirk register tail + "Immediately next"
carrying the session-1 execution order + the exit-gate/seventh-surfacing
line); ROADMAP.md 634–673 (the N3 ENTERED bullet with the box + ledger
pointer; the N4/N5/N6 bullets FUNDED); README.md whole (the apps/android row
25 + the core-ffi row 26 + the interim shipped-product statement); every
Kotlin file in the delta (shared/build.gradle.kts — the KMP one-target
shape; Native.kt — the androidMain model; NativeAndroid.kt — the JNI surface
+ display glue; MainActivity.kt — the Views UI + SAF + the size pre-check;
NativeJniHostTest.kt — the JVM host lane) + strings.xml (the honesty
surfaces: the three-fact disclaimer, the no-AI/no-network note, the
non-affiliation line, the prototype launcher label) + the manifest facts via
rg (zero uses-permission, allowBackup=false); app build.gradle.kts (the
fixture-pull task line 48, minSdk 24/targetSdk 36, the 0.1.0 plane); the
hygiene.yml android-lane surfaces via rg (assembleDebug + the .so unzip
proof, the REAL Java_* seam comment, the guards).

**Ran (my own measurements, all read-only — git/rg only; no cargo, no
installs; no scratch created under /tmp/n3exit-prod):**

1. `git rev-parse --short HEAD` → 2f3efa1 (the pushed tip, as briefed);
   `git log --oneline ae9e078..2f3efa1` → exactly ONE commit (the session-2
   close backup); `git status --short` → EMPTY at my probe (the tree clean
   before this report).
2. The variant preconditions, live: the delta contains ZERO `clearfile/`+
   `src/` top-level paths (grep exit 1); release.yml diff = 0 bytes;
   core/Cargo.toml+lock diff-stat empty; `git tag` → 3 tags exactly
   (v1.0.0/v1.0.1/v1.1, newest 2026-11-26 — no N3 tag); hygiene.yml delta =
   136 additions, ZERO deletions (purely additive — the existing jobs
   byte-identical, verified rather than trusted); .gitignore delta purely
   additive with the guard-order comment.
3. The delta's file list: the two new roots (core-ffi/ 8 files + apps/
   android 8 files) + the recorded riders (core/src/json.rs, core/src/lib.rs,
   apps/linux/src/main.rs) + the records/workflow set — matches the entry
   gate's scope exactly; `git diff --stat ae9e078..2f3efa1` → 1 file
   (SESSION_LOG only, +49) — the green run covers the tip's functional
   surface.
4. The bookkeeping families: `rg -n "core-ffi|apps/android" scripts/
   harness_check.sh` → the scaffold-surface (8-file), the
   Java_-excluded-from-header, and the lock-topology (core=1, core-ffi≥2)
   checks; the version planes measured in-tree (core-ffi 0.1.0 publish=false;
   versionName 0.1.0).
5. The zero-engine-logic scan: a pattern sweep (`rate|bracket|deduct|credit|
   phase|agi|taxable`, -i) over apps/android's Kotlin flagged all four files
   — resolved by READING each one: every hit is a display label, a JSON key,
   or a comment; the only arithmetic in the app is the 512 MiB bound
   comparison. The claim held under adversarial reading, not just grep.

---

Working tree at filing (this lane's ONLY file; the other lanes' reports were
filed concurrently by their own reviewers — parallel isolation, not read,
left exactly as found):

```
$ git status --short
?? harness/adversarial/reports/2026-11-27-n3exit-product.md
```
