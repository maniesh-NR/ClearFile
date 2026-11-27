# ADV-ENG — N5 exit gate (2026-11-27, Task N5-EXIT-ENG)

Scope: the ENG lane of the N5 EXIT gate — the delta `ff127f2..9cfffa7`
(three commits: 48d981d the landing, cdd25a1 the round-2 fix, 9cfffa7
the round-3 fix; 8 files, +714, tip 9cfffa7, tree clean at start except
the sibling exit-lane reports). The green run of record: **45977202882
on 9cfffa7, ALL EIGHT JOBS GREEN** — the third CI round (round 1 red on
48d981d: SwiftPM's line-1 tools-version rule; round 2 red on cdd25a1,
run 45976627388: Result's failure type must conform to Error; round 3
green). I re-read my entry report (2026-11-27-n5-engineering.md — the
8 conditions + the R-ENG-26..31 register), CONSENSUS's N5 gate section
(1938–2088 — the consolidated 13-point ledger, the four mitigations,
the TENTH slip surfacing), the three delta commit messages in full (the
honest round record), ROLES.md, and the N4 exit report (the format
template). Probes live under /tmp/n5exit-eng (the fresh-clone
renormalize probe; removed at close; df 6.7 GB free at start and close).
The standing author-blind reality holds for this lane: the sandbox has
no Swift and no macOS — the macOS-side evidence is the green run of
record (its otool/identity echoes are the step-log facts cited below);
everything probe-able from this side was probed live.

**VERDICT: N5 EXIT — PASS (8/8 entry conditions discharged, every
probe green at tip; the register closes with one new registered note
(R-ENG-32, no action) + one new class note; two weighed no-action
rulings below — the exact-list tightening ruled NO, the install-name
oddity ruled SOUND-with-note; the window mode remains the named
non-verification, the owner-side build remains GA's standing
obligation)**

## Conditions (the eight discharge proofs)

1. **The wrapper-header shape — DISCHARGED (mechanically probed at
   the committed files).** The umbrella lives at apps/macos/Sources/
   ClearFileFFI/include/ClearFileFFI.h — named for the target
   ClearFileFFI (SPM's include/&lt;TargetName&gt;.h umbrella lookup),
   a PLAIN committed file (mode 100644 — the symlink shape exists
   nowhere; the rejection stands, both probe findings recorded in the
   source comment and the manifest). Its ONE substantive line is
   `#include "../../../../../core-ffi/clearfile.h"` — **FIVE `../`,
   exactly as ruled** (the proposal's four was the off-by-one; the
   landed count verified mechanically: normpath(include-dir, the
   include) resolves to core-ffi/clearfile.h, and samefile() against
   the committed header is True — the include is THE committed header,
   not a copy). The CI assertion is the exact-line grep
   (hygiene.yml:561) plus the swift build itself (the resolution
   proof, :577); the harness_check N5 scaffold family re-proves both
   every push (ran green locally this session, 0 failures). The
   freshness check STAYS with the android job (hygiene.yml:323–326,
   untouched by the delta) with the choice recorded in the job comment
   (497–498, 555–557) — my advisory's "record which" satisfied. The
   round-1 red was NOT a wrapper finding: the include-line assertion
   and the header resolution were green in every round; what failed
   was the manifest's own preamble (below, condition 8's record).

2. **The smoke geometry — DISCHARGED (the green run is the
   byte-proof).** The smoke step (hygiene.yml:592–598) carries NO
   working-directory key → cwd = GITHUB_WORKSPACE = the repo root; the
   command is `DYLD_LIBRARY_PATH="$PWD/core-ffi/target/release"
   ./apps/macos/.build/debug/ClearFileMacOS --headless
   fixtures/migration/v1-web-envelope.json` — the exe path from the
   root (SPM's default debug product path, a plain executable), the
   fixture path exactly the committed File: line's argv (the expected
   text's line 2 carries `fixtures/migration/v1-web-envelope.json`,
   od-verified; the green diff is the proof the exe echoed it
   byte-identically), and DYLD_LIBRARY_PATH ABSOLUTE ($PWD = the
   workspace at step time). `tr -d '\r'` BOTH sides retained
   (595–596) ahead of the real `diff -u` (597) — the canonical text
   family as the assertion, EOL-independent. The otool -L lists are
   echoed into the step log ahead of the guard (606–609) — my
   condition's "keep its output visible" diagnostic satisfied, and it
   is exactly what fed this gate's exact-list review (below).

3. **The byte-parity port discipline — DISCHARGED (main.swift read
   in full, 457 lines; the green smoke is the byte-proof).**
   `String(format:)` non-localized throughout (fmtMoney "%.2f"
   :117, fmtRate "%.1f%%" :135); the **-0.0 normalization ported**
   (:114, `if magnitude == 0.0 { magnitude = 0.0 }` on a var — the
   load-bearing line); the grouping via **`Array(intPart)`** (:125 —
   no String-by-Int subscript) with main.cpp's exact rule
   `index > 0 && (count - index) % 3 == 0` (:128); the em-dash as the
   source UTF-8 literal (:201 — the expected line 1's `342 200 224`
   od-verified; the file LF-only, ends `professional.\n`, 1766 bytes);
   `as? Int` for qualifyingChildren (:91–93, consumed :163) — the
   expected line 27 `  Qualifying children: 2` is green-proven output
   of that path, and the fixture's `"qualifyingChildren": 2` (line 19)
   is the input; the warnings array order preserved + the count line
   (:212–218; expected line 37 `Import warnings (4)` green-proven);
   ONE canonical committed expected file diffed (apps/linux/tests/
   expected-headless.txt — NOT in the delta, never regenerated); the
   stderr/exit surface (:421–456: exit 2 usage / 1 load failure / 0
   success, writeErr/writeOut) honestly NOT smoke-asserted — the
   happy-path-only posture, consistent with the linux/windows twins.
   ONE letter-deviation, benign and recorded: the `as? Int` fallback
   is `?? 0` (not the offered `?? Int(... as? Double ?? 0)` shape) —
   STRICTER than the letter (lossless-checked, nil-coalesced exactly
   like the sibling display fields; the truncation-drift class cannot
   exist in it), and the green smoke is the proof it never fires on
   the real payload.

4. **The C-ABI consumption discipline in Swift — DISCHARGED (read in
   full; rg-proven zero force-try/force-unwrap in the file).** The
   owned payload: `guard let owned = ...` (:269–271 — the NULL return
   is the error path, never force-unwrapped), the input borrow INSIDE
   `bytes.withUnsafeBytes` with
   `raw.bindMemory(to: CChar.self).baseAddress` and **`UInt(raw.count)`**
   (:269–271 — tighter than my letter: the borrow cannot outlive the
   closure), `defer { clearfile_free(owned) }` at the tightest scope
   (the do-block, :274) with the copy-out `String(cString: owned)`
   (:275) before the scope exits — copy-out precedes free, always; the
   borrowed thread-local `clearfile_last_error()` copied out
   immediately, never stored (:44–47); **Bool as Bool** (:62 — `dark`
   passed directly, the header's `bool dark` param at clearfile.h:87);
   the role length `UInt(strlen(cString))` computed INSIDE
   `role.withCString` (:61–62) — the same value as `role.utf8.count`
   (strlen over the null-terminated UTF-8 buffer), structurally immune
   to my register's "7 not 8" off-by-one class (the length is measured
   from the buffer, never hand-counted), and withCString is exactly
   the ruled variable-passing form; utf8.count at the write sites
   (:300–308, `data(using: .utf8)`); the palette FFI parameters match
   the committed ABI verbatim (clearfile.h:86–89: seed, dark, role,
   role_len). Single-threaded as proposed (headless never touches
   AppKit; the window mode main-thread only).

5. **The CI macos-app job — DISCHARGED (read 487–618 in full; the
   eighth job confirmed — the census: gitleaks, suites, linux-app,
   android-app, windows-app, macos-app, re-tooling, harness-check).
   runs-on macos-latest, permissions contents:read, timeout 45, the
   SHA-pinned checkout, NO uploads.** Steps in the ruled order: the
   rustc ≥ 1.95 parse-guard + the host-triple assertion
   `aarch64-apple-darwin` fail-closed (:523–540); the identity echo
   `sw_vers` + `swift --version` RECORDED not asserted (:543–546 —
   the R-ENG-30 posture); the cdylib `cargo build --locked --release`
   with the .dylib emission assert (:548–551); the boundary battery ON
   MACOS (:553–554 — 10/10 on the run of record); the wrapper
   assertion (:558–563); the SPM zero-dep assertion (:565–571, the
   grep over .package(/.binaryTarget/.systemLibrary/url:) — the same
   regex the harness_check family re-proves) plus the
   Package.resolved-absence and exe-emission asserts (:578–579); the
   **-Xlinker SINGLE-TOKEN form** (:577 — `swift build -Xlinker
   -L../../core-ffi/target/release -Xlinker -lclearfile_core_ffi`,
   each -Xlinker carrying exactly ONE joined token; the -L math from
   apps/macos correct: ../../ = the repo root); the deployment-floor
   assertion via `otool -l | LC_BUILD_VERSION | minos 13` (:583–587 —
   the run of record: minos 13.0 ok); the headless smoke (condition
   2); the otool -L guard over BOTH binaries with the four-way
   denylist `CFNetwork|Network\.framework|libcurl|libssl` (:610–615 —
   the libcurl/libssl breadth I required over the bare CFNetwork
   form) + the must-contain-libSystem dylib side (:616–617). The
   grep-no-match discipline is satisfied BY CONSTRUCTION — the deny
   greps run inside `if` conditions, so the good-path no-match exit
   code cannot leak (the bash twin of the N4 findstr gotcha, handled
   by the shape). NO cargo-deny, with the recorded reason in the job
   comment (:509–510 — the android job denies core-ffi's lock every
   push).

6. **The .gitignore joins — DISCHARGED (same-commit, git-proven).**
   `/apps/macos/.build/` + `/apps/macos/.swiftpm/` landed in 48d981d —
   the SAME commit as the scaffold (git show --stat: all 8 delta files
   in the one commit), before any in-repo build state could exist
   (this sandbox has no Swift; .build/ can only materialize on the
   runner — the discipline is the precedent and the owner-side-build
   offer makes it live). The blob allow-list needed no join (zero
   binaries in the delta; rg-proven: no tracked .dylib/.wasm/.dll/
   .lib/.exe anywhere in the tree); the backup scan-path already
   covers `apps` wholesale (measured at entry, unchanged).

7. **The .gitattributes — DISCHARGED, with one benign extension
   recorded.** The landed file (:12–20) carries the probed shape —
   `* text=auto eol=lf` + the binary marks — PLUS TWO EXTRA MARKS:
   `*.dylib` and `*.wasm` (:19–20), beyond my condition's probed
   six. Both are provably no-ops today (zero tracked files of either
   class) and read as belt-and-braces pre-positioning (*.dylib = this
   lane's own never-committed artifact class; *.wasm = N6's future
   class). The zero-diff claim RE-PROVEN BY ME at tip 9cfffa7: fresh
   clone → `git add --renormalize .` staged NOTHING (`git diff
   --cached` empty); the EOL census 419 i/lf w/lf + 29 w/-text, ZERO
   w/crlf or w/mixed — the index is truly all-LF with the landed
   eight-mark file. The autocrlf class is dead at the root
   (attributes beat runner config), and the `tr -d '\r'` smokes
   remain as the belt-and-braces layer.

8. **The ONE-session box — DISCHARGED (the honest record verified in
   the raw commits).** Three commits, timestamps 09:43:21 → 09:47:18
   → 09:51:30 — ONE continuous session (~8 minutes; the box's
   one-session letter held; the red-close rule never approached).
   The CI-fix rounds = THREE, each red diagnosed AND recorded in its
   own commit message: round 1 (the run at 48d981d) — SwiftPM's own
   rule, Swift &lt; 6.0: the tools-version directive must be the
   manifest's FIRST LINE (my SPDX header preceded it;
   "backward-incompatible" at the SPM step) — fixed in cdd25a1, the
   directive moved to line 1 with the finding recorded in the
   manifest's own comment (Package.swift:18–21); round 2 (run
   45976627388 on cdd25a1) — Result's failure type must conform to
   Error (String does not; the Swift-5 bound) — fixed in 9cfffa7 with
   the tiny LoadError wrapper (main.swift:236–238) + the three
   consumers reading `.message`; round 3 (run 45977202882 on 9cfffa7)
   — ALL EIGHT JOBS GREEN. Against the datums N3=11, N4=5: N5=3, the
   cheapest lane yet — and both reds were classes OUTSIDE my register
   (ruled below). The PRE-FLIGHT blind audit honestly recorded: 1
   defect (the throwing `write(contentsOf:)` needing `try?` — landed
   as :301/:307 today) fixed BEFORE the first push, plus the
   auditor's independent Python port proving the formatting logic
   1766-bytes-identical against the committed expected text (the
   file's size wc-verified this session: 1766). The headless-first
   ordering was superseded by the one-file shape (the whole app
   landed session 1 as ONE main.swift — the N4 R-ENG-25 precedent);
   the PURPOSE held (the parity artifact landed, survived, closed
   green) — honest bookkeeping, no action (the R-ENG-25 family note
   below).

## The R-ENG-26..31 register — the close-state ruling

- **R-ENG-26 (the blind Swift lane, high) — CLOSED, with the honest
  finding:** NONE of the register's named trap classes fired in CI —
  (a) main.swift-vs-@main, (b) the -Xlinker single-token, (d) the
  String-no-Int-subscript, (e) the Int→UInt/withUnsafeBytes, (f) the
  include-path off-by-one, (g) the AppKit wiring — each was pre-fixed
  by the entry conditions (the register's own mitigations), and (c)
  fired HALF (the throwing write(contentsOf:)) and was caught
  PRE-FLIGHT by the blind audit, never in CI. The mitigation
  discipline is itself the finding: the pre-carried-condition
  register demonstrably converts predicted rounds into non-rounds.
  What actually burned the two rounds was a class OUTSIDE the
  register — **THE NEW CLASS (registered, one line, for any future
  Swift lane): Swift-basis/manifest preconditions** — SwiftPM's
  line-1 tools-version rule, Result's failure-type Error-conformance
  bound: language/tooling preconditions of the manifest and stdlib
  generics, not ABI-port traps. Pre-check the manifest's own parsing
  rules and the Result/Error shapes before the first push. The item
  closes; the class note carries in the register.
- **R-ENG-27 (the never-CI-run window path, medium, accepted-class) —
  CLOSES AS ACCEPTED (the R-ENG-20 family).** The compile-level half
  is RETIRED: round 3's green swift build compiles runWindow /
  SummaryView / WindowCloseDelegate / NSOpenPanel / the activation
  policy on the real toolchain. The runtime half remains the named
  non-verification (no interactive desktop on the hosted runner;
  recorded in the source comment :312–317, the job comment, and the
  commit messages). The **palette FFI call chain (roleColor →
  clearfile_palette_scheme_role: the seed, the Bool, the UInt length,
  the role bytes) remains the one ABI-carrying path in the app that
  CI never executes** — carried as the standing named non-verification
  plus the --palette-smoke advisory below. The owner-side build (GA's
  standing obligation under the bar ruling) owes the interactive
  verification. No N6 carry (N6 is web-WASM; if a macOS lane ever
  reopens, this family reopens with it).
- **R-ENG-28 (the display-glue parity residue) — CLOSED-DISCHARGED:**
  the live byte-parity smoke green on the real exe (the full stdout
  vs the committed text, on the real runner) + the pre-flight Python
  port. JSONSerialization's correctly-rounded double parse matched
  the C++ scanner's strtod and the Rust serde writer — the one-ULP
  rounding flip never fired.
- **R-ENG-29 (the install-name uncertainty) — CLOSED-RESOLVED:** the
  case is now KNOWN (the green run's otool log: the exe's dylib entry
  is an absolute cargo build-tree path — the ruling below). The
  superset DYLD posture held and is the right permanent form; the
  residual is registered as R-ENG-32.
- **R-ENG-30 (runner-image drift, low) — CLOSED into the standing
  drift posture:** the fail-closed guards (rustc ≥ 1.95, host-triple),
  the tools-version 5.9 manifest contract (the Swift 5 language
  mode), and the recorded-not-asserted identity echo are IN PLACE and
  green on the run of record (macOS 26.7.2 / swift-driver 1.148.6 /
  rustc 1.100 aarch64-apple-darwin) — the mitigation is structural in
  the job; nothing open remains.
- **R-ENG-31 (probe footprint) — CLOSED** (verified at entry; held
  again this session — the scratch removed, the tree untouched except
  this report).
- **R-ENG-32 (NEW, low, accepted-class, no action — the install-name
  note):** the exe's LC_LOAD_DYLIB for the core dylib records an
  absolute build-machine path (cargo's cdylib install-name emission;
  observed in the green run's otool log — kept visible in the step by
  design). Soundness: the exe is non-relocatable without
  DYLD_LIBRARY_PATH (dyld substitutes the leaf name against the
  DYLD_LIBRARY_PATH entry first) or install_name_tool — irrelevant to
  the lane (the binary never leaves the runner: NO uploads), and
  covered in CI by the smoke's absolute DYLD_LIBRARY_PATH, which is
  sufficient in EVERY install-name case (my condition-2 analysis is
  now load-bearing fact). Owner-side note: the owner's own checkout
  embeds the owner's absolute path — the exe runs from the build dir
  as built; moving it needs
  `DYLD_LIBRARY_PATH=<checkout>/core-ffi/target/release` or
  install_name_tool. RECORDED here and for the register sync; no CI
  change.

## The exact-list ruling (the cdylib's now-known direct links)

The run of record's facts: the cdylib's direct links = EXACTLY
[itself (the install name), /usr/lib/libSystem.B.dylib]; the exe's =
the core dylib (the absolute path) + libSystem + AppKit +
CoreGraphics + Foundation + libobjc + the OS Swift runtime
(/usr/lib/swift/*). **RULING: do NOT tighten the CI guard to the
exact-list assertion — the denylist + must-contain-libSystem form
stands.** Weighed: (i) the lists are partly TOOLCHAIN-OWNED — the
exe's OS-Swift-runtime set varies with the Xcode/Swift version, the
dylib's list is rustc/std's linking choice — and the runner floats
(macos-latest; the -latest label migrates gradually, the recorded
identity drifts already: 26.7.2 today). The lane's own convention
(the identity echo: recorded, not asserted; my entry condition
5(viii)) rules exactly this: toolchain-owned facts are RECORDED,
never asserted — an exact-list assertion would assert them and
false-fail on any benign toolchain roll, the round-burning class the
box is not sized for. (ii) The property the guard protects — no
network library DIRECTLY linked, the no-network claim's mechanical
proof — is fully enforced by the four-way denylist over BOTH
binaries regardless of list shape; the exact list adds only
additive-benign detection. (iii) The additive vector that matters
(core-ffi someday gaining a native-crate dependency) is guarded
upstream — the manifests/lockfiles are committed and byte-verified
as the standing variant precondition — and any additive direct link
is REVIEW-VISIBLE anyway, because the step echoes the full otool -L
lists into the run log every push (the step comment records exactly
that intent; the "tightening" that happens is THIS REVIEW — the
baseline is now recorded here as the reviewed fact). THE UPGRADE
PATH (advisory, not a rider): if the threat model ever shifts (a
native dep ever lands in core-ffi), the exact-list-for-the-DYLIB-ONLY
(the stable, rustc-owned two-entry list) is a one-line, one-round
tightening then, reviewed against the new baseline.

## The install-name oddity — the ruling

(As registered: R-ENG-32 above.) Soundness ruling: **SOUND for this
lane, NOTE recorded, NO close rider.** The absolute install name is
cargo's standard cdylib emission on darwin, not an authored defect;
the exe is a CI-side, never-shipped artifact (NO uploads, contents:
read); the smoke's absolute DYLD_LIBRARY_PATH is the documented
superset that resolves the dylib by leaf name in every case — and
the green smoke is the live proof. The owner-side build note is
recorded in R-ENG-32 for the register sync; nothing in CI or the
app needs to change.

## Test honesty — what the lane PINS vs what it papers over

PINS (each mechanically green on run 45977202882):
- The rustc/host-triple identity (fail-closed) + the toolchain
  identity (sw_vers + swift --version, recorded every run — the
  drift detector).
- The .dylib emission + the boundary battery 10/10 ON MACOS — the
  core's real ABI exercised on the third platform family (the golden
  fixtures + the corpus through the C boundary).
- The wrapper-include line + the build resolution — the app compiles
  against THE committed header (nothing re-declared, nothing copied;
  the freshness check on every push in the android lane).
- The SPM zero-dep posture, three ways (the manifest grep, the
  Package.resolved absence, the exe emission) + the harness_check
  family.
- The macOS 13 deployment floor (LC_BUILD_VERSION minos 13.0 —
  build-time-only confirmable, and confirmed).
- The byte-parity text family — the FULL stdout vs the ONE canonical
  committed Linux expected text, EOL-normalized both sides: pins the
  argv plumbing, the happy-path read, the composed pipeline, the JSON
  display glue, and the whole text_summary port (every group, label,
  format, the em-dash bytes, the footer) across three platforms.
- The no-direct-network-link posture (the otool denylist over both
  binaries) + the must-contain-libSystem realness check — honestly
  scoped in the job comment as DIRECT linkage only (Foundation
  transitively loads CFNetwork as an OS fact; the claim owned is
  "no network framework linked BY the app/core").

PAPERS OVER (each named honestly in the source, the job, and the
commits — none silently):
- **THE WINDOW MODE — the named non-verification, and THE UNCOVERED
  SURFACE THAT MATTERS:** NSOpenPanel, SummaryView.draw, the close
  delegate, the activation policy, the nsColor ARGB decode, the
  honesty set's DISPLAY — compiled green, never run on the runner.
  The heaviest residue is the palette FFI chain (the one
  ABI-carrying path CI never executes, a cross-lane parity surface);
  the --palette-smoke argv mode (my entry advisory, ~10 lines + one
  CI line, pins it headlessly) remains unimplemented — carried below,
  non-binding, the same accepted family as every platform's window
  lane.
- The refusal path (the 512 MiB pre-read bound + the verbatim named
  message "The file is too large to open — the limit is 512 MiB.")
  — unexercised (the N4-carried advisory, again unimplemented).
- The stderr/exit surface (exit 2/1/0 + the usage wording) —
  unasserted by CI (consistent with the linux/windows lanes;
  happy-path-only).
- loadAndCompute's platform-failure branches (FileManager/size/JSON
  guard failures) — unexercised.
- The `tr -d '\r'` both-sides residue (R-ENG-23's tolerance: a
  spurious in-content CR would pass) — now structurally near-dead
  (the checkout conversion is killed by .gitattributes eol=lf) but
  still tolerant by design; the standing belt-and-braces trade.
- One family nit, named for completeness, pre-existing (not an N5
  authored defect): extra argv after `--headless <path>` are silently
  ignored — the Windows twin's exact behavior (main.cpp:570–576), so
  the port is faithful; cosmetic, never CI-exercised, no action.

## Advisories (non-binding)

- The close bookkeeping duties (the standing gate-close pattern per
  the entry ledger's consolidated conditions 10–12, listed so the
  close commit carries them all): the variant preconditions
  byte-verified at close (zero clearfile/ + src/ paths in the delta
  ✓ this session; release.yml + core/ + core-ffi/ Cargo.{toml,lock}
  byte-unchanged ✓; nothing uploaded ✓ — no upload steps, contents:
  read; no NEW tags ✓ — the 3 existing tags all pre-date ff127f2;
  apps/macos 0.1.0 as its own new plane ✓; the envelope schema 2 /
  v2.0.0 N6-GA-only untouched ✓); the README row (the honest scope,
  the unreleased/CI-only status, the Flutter-remains-shipped
  sentence, the FOUR named non-verifications — no interactive GUI
  run, no macOS-13 runtime, no x64-mac, no owner-side build — the
  green run number, the GA clause); the checker N-outcomes 8→9 at
  close (the apps/macos families already landed and green);
  the SESSION_LOG N5 session record (the ONE-session box, the
  3-round honest record, the pre-flight audit's 1 defect + the
  Python-port proof, the run ID 45977202882 — the N4 run-ID
  convention); the register close-state sync (R-ENG-26..31 as ruled
  above + R-ENG-32 + the Swift-basis class note); the TENTH slip
  surfacing's disposition (CONSENSUS 2067–2077 — the ELEVENTH rides
  with N6's TERMINAL gate, whose record must note the slip cannot
  ride past it unexamined).
- The D14 SPDX sweep: verified this session — every new source file
  carries the GPL-3.0-only header (Package.swift — after the line-1
  directive; both wrapper files; main.swift; .gitattributes).
- The --palette-smoke argv mode and the refusal smoke: both remain
  the cheapest pins on their surfaces; both non-binding; both worth
  one attempt if any future round touches main.swift's argv surface
  anyway. Neither was owed by this gate.
- Round 1's numeric run ID (the red on 48d981d) is not in the commit
  record ("run at 48d981d"); rounds 2 and 3 carry theirs (45976627388
  red / 45977202882 green). The green run's ID is the one the
  convention needs — it is recorded here and should land in
  SESSION_LOG at close. Non-blocking.
- The per-OS order stands: N6 (web-WASM + the freeze) next; the
  wasm32-target question and the TS retirement are N6's gate. The
  *.wasm binary mark in .gitattributes is already N6's
  pre-positioning.

## Files read + verification log

Files read (this session): harness/adversarial/reports/
2026-11-27-n5-engineering.md (all — my entry report, the 8 conditions
+ the R-ENG-26..31 register),
harness/adversarial/reports/2026-11-27-n4exit-engineering.md (all —
the format template + the register precedent),
harness/adversarial/CONSENSUS.md 1938–2088 (the N5 gate record: the
consolidated 13-point ledger, the four mitigations, the TENTH slip
surfacing, the ENTERED outcome), harness/adversarial/ROLES.md (the
mandate), the three delta commit messages in full (git log
ff127f2..9cfffa7 — the honest round record), apps/macos/Package.swift
(all 49), apps/macos/Sources/ClearFileFFI/include/ClearFileFFI.h
(all 12), apps/macos/Sources/ClearFileFFI/shim.c (all 7),
apps/macos/Sources/ClearFileMacOS/main.swift (all 457),
.github/workflows/hygiene.yml (the macos-app job 487–618 in full;
the android freshness check 323–326; the job census), .gitattributes
(all 20), the .gitignore + scripts/harness_check.sh deltas
(git diff ff127f2..9cfffa7 — the N5 families), core-ffi/clearfile.h
(77–106 — the ABI shapes the importer sees), core-ffi/Cargo.toml +
build.rs (the cdylib crate-type + the header generator — the
install-name context), apps/windows/main.cpp (560–595 — the argv
twin), apps/linux/tests/expected-headless.txt (byte-level), and
fixtures/migration/v1-web-envelope.json (the smoke fixture).

Runs (this session, tip 9cfffa7, scratch /tmp/n5exit-eng, deleted at
close; NO Swift/macOS in this sandbox — the green run of record is
the macOS-side evidence):

1. df first: 6.7 GB free (29% used). The delta census verified:
   git diff --stat ff127f2..9cfffa7 = 8 files, +714; the hygiene.yml
   delta = ONLY the additive macos-app job (+134); 48d981d carried
   all 8 files in ONE commit (the same-commit .gitignore/.gitattributes
   joins proven).
2. The wrapper-include probe (live): normpath(include-dir,
   "../../../../../core-ffi/clearfile.h") → core-ffi/clearfile.h;
   samefile(the committed header) = True — FIVE ../ resolves to THE
   committed header (the four-../ off-by-one never landed).
3. THE RENORMALIZE ZERO-DIFF RE-PROOF (fresh clone of 9cfffa7):
   `git add --renormalize .` staged NOTHING; the EOL census 419
   i/lf w/lf + 29 w/-text, zero w/crlf or w/mixed — the landed
   eight-mark .gitattributes (the two extra marks *.dylib/*.wasm
   provably no-ops) renormalizes the whole tree to zero deltas.
4. harness_check.sh (live): **0 failures** — 36 checks green
   including both N5 families (the scaffold surface + the zero-dep
   posture + the .gitattributes rule).
5. The expected-text byte facts: 1766 bytes (the auditor's
   Python-port parity target matches); line 1's em-dash = 342 200
   224; the File: line's relative fixture path; line 27
   `  Qualifying children: 2`; line 37 `Import warnings (4)`;
   LF-only, ends `professional.\n` — every one of these
   green-proven by the run of record's smoke.
6. The smell pass on apps/macos: zero TODO/FIXME/HACK; zero try!/as!;
   the only `!` forms are the imported IUO ABI signatures; every
   ABI call guard-let (read line-by-line).
7. The variant-precondition pre-check: zero clearfile/ + src/ paths
   in the delta; release.yml, core/, core-ffi/ untouched (not in
   the delta); no upload steps in the job (contents: read); no NEW
   tags (the 3 existing tags — v1.0.0/v1.0.1/v1.1 — all pre-date
   ff127f2, none point into the delta).
8. The argv-twin comparison: main.cpp:569–576 vs main.swift:429–439 —
   the faithful port confirmed (the extra-argv-after-headless
   tolerance is the Windows twin's own shape, not an N5 defect).

At report close: /tmp/n5exit-eng deleted; df 6.7 GB free (29%);
`git status --short` →

```
?? harness/adversarial/reports/2026-11-27-n5exit-engineering.md
?? harness/adversarial/reports/2026-11-27-n5exit-legal.md
```

(the sibling legal lane report is the parallel-lane reality, not
read per the isolation rule; the first line is this report — the
only tree change this lane made).
