# ADV-LEGAL — N5 exit gate (2026-11-27, Task N5-EXIT-LEGAL)

The N5 delta (ff127f2..9cfffa7: 8 files, +714 — apps/macos/Package.swift
[the tools-version directive at line 1 by SwiftPM's own rule, the SPDX
header at l.2], the wrapper umbrella header ClearFileFFI.h, the
comment-only shim.c, main.swift; the SPDX-headed .gitattributes
[R-ENG-23]; the .gitignore joins; the macos-app job in hygiene.yml
[purely additive, +134/−0]; the harness_check N5 families) is
adversarially re-verified against my nine entry conditions, the carried
register, and the two standing posture items ((b) the first-conveyance
trigger restated for the macOS artifact, (c) the no-network claim's
guard enforcement). The execution is clean where it matters most
legally: the SPM dependency surface stayed EMPTY and is now asserted
fail-closed in three places; the no-network claim is MECHANICALLY
proven (the otool -L guard over both binaries, denylist extended to
libcurl/libssl — beyond my minimum — green on the live run); nothing
conveys; the honesty family landed verbatim and byte-exact on both
surfaces; and the clean-room line holds (a from-scratch Swift port of
our own text family — the labels are IRS-form terminology dictated by
the domain). Three CI rounds, each honestly diagnosed + fixed +
recorded in the commit messages; a pre-flight audit caught the
throwing write(contentsOf:) defect BEFORE the push — disclosed, not
buried. What does NOT land in the delta is exactly what the gate's own
ledger scheduled for the close: the ADR-017 annex's Swift sentence
(entry condition 3) and the README row (entry condition 7) — both
ruled below as close riders with exact text, plus the one-line D14
root-dotfile class note and the close-record content (the linkage
facts + the no-row ruling + the green run ID). Those riders — not any
violation — are why this is PROCEED-WITH-CONDITIONS rather than a
clean EXIT-PASS.

**VERDICT: PROCEED-WITH-CONDITIONS (4 close riders, all with exact
text below; no legal violation, no BLOCK)**

## Entry conditions, discharged or correctly deferred

1. **The zero-external-SPM-dependency invariant — DISCHARGED, asserted
   three ways.** Package.swift declares exactly two targets (the C
   wrapper + the executable importing it) with no `.package(`, no
   `url:`, no `.binaryTarget`, no `.systemLibrary` (my sweep: probe
   clean — local targets only); no Package.resolved anywhere in the
   tree (repo-wide file search: none; and CI asserts its absence
   POST-BUILD, hygiene.yml l.578 — the assertion that catches a
   dependency that resolves only at build time); no `.gitmodules`, no
   vendored .swift files. The invariant is now held fail-closed
   mechanically — the CI grep (l.565–571) + the resolved-absence
   assertion + the harness_check family (`MAC_DEPS` grep) — the
   N4-exit advisory 1 (make the sweep a CI step) taken for this lane
   without needing a second ask. The tripwire (risk (a)) stays: any
   dependency added later re-opens this gate's lane.

2. **The D14 SPDX sweep — DISCHARGED over every new tracked file,
   with the root-dotfile class note still owed (rider 3).** The
   tracked surface under apps/macos is exactly four text files
   (zero binary assets — `git ls-files apps/macos` → 4 files; the
   no-icon posture holds), all headed: main.swift `// SPDX…` (l.1);
   ClearFileFFI.h `/* SPDX…` (l.2, the C-block form); shim.c `/*
   SPDX…` (l.1 — a comment-only TU still counts as a tracked text
   source, and it got its header); Package.swift carries the SPDX
   header at l.2 — position-FORCED: SwiftPM's own rule (Swift < 6.0)
   puts the tools-version directive at line 1, and the round-1 CI
   finding that proved it is recorded in the manifest's own comment
   (l.18–21) — this is the gradle-precedent class (an own-code
   manifest) with the only lawful header position, not a miss;
   .gitattributes carries `# SPDX-License-Identifier:
   GPL-3.0-only` at l.1 (entry condition 2's option A taken). The
   .gitignore edit preserves its pre-existing un-headed posture (the
   N4-exit precedent class: edits preserve pre-N5 posture) — but my
   condition said "record the class either way, one line", and the
   root-dotfile class is STILL not among D14's recorded un-headed
   classes (DEBT.md l.22: expected-output artifacts / generated
   lockfiles / strict-JSON data — no dotfiles) → rider 3. The
   hygiene.yml/harness_check.sh edits likewise preserve their
   pre-existing un-headed convention (the workflow/scripts class —
   the N4-exit precedent, not a new-N5 gap).

3. **The Swift-toolchain posture RECORDED in-tree — the annex
   sentence is NOT yet landed; correctly deferred to the close, rider
   1 rules the exact text + placement.** Verified: DECISIONS.md is
   absent from the delta; the licensing annex (l.537–548) still ends
   its toolchain sentences at "Kotlin/Apache-2.0 is
   GPL-3-compatible." with NO Swift sentence — the annex lacks
   exactly what my condition required. What DID land in-tree (the
   condition's check allowed "lane comments or the gate record"):
   Package.swift's own header comment (l.8–10: "the platform
   frameworks only (AppKit + Foundation, both under the GPLv3 §1
   system-library carve-out…)"), the workflow's recorded reasoning
   (the Foundation/CFNetwork direct-vs-transitive note, l.503–506),
   and the identity echo (sw_vers + swift --version recorded every
   run — the resolved-toolchain fact, not a transcribed claim). The
   full posture + the annex sentence are now recorded in THIS gate
   record; rider 1 is the in-tree annex discharge. The licenses were
   live-verified at entry (2026-11-27) from the resolved toolchain
   sources — apple/swift LICENSE.txt l.205–210 (the Runtime Library
   Exception text) and apple/swift-package-manager LICENSE.txt
   (Apache-2.0, correcting the proposal's imprecise "Apache-2.0/MIT")
   — the risk-(a) discipline (record from the resolved toolchain,
   never transcribe from a proposal) held.

4. **The first-green linkage facts + the LICENSES-manifest
   row-or-not — RULED HERE (the no-row case); the close record must
   carry it (rider 4).** The lane emits the full otool -L lists for
   BOTH binaries on every run (the workflow l.602–603 says why: "the
   full lists stay visible above for the exit gate's exact-list
   tightening"). From the green run (45977202882 on 9cfffa7,
   all eight jobs): the executable's direct links = the core dylib +
   libSystem.B.dylib + AppKit + CoreGraphics + Foundation + libobjc
   + the /usr/lib/swift/* OS Swift runtime — ALL OS-shipped, nothing
   embedded; the cdylib's direct links = exactly [itself,
   /usr/lib/libSystem.B.dylib]. **RULING:** the /MD-analog no-row
   case holds — NO Swift-runtime row is owed, now or at ANY
   conveyance (the runtime is OS-provided and dynamically linked
   from /usr/lib/swift; no Apache-licensed object code is embedded in
   the binary — contrast the N4 /MT CRT row, which IS owed because
   the CRT object code rides inside the .exe). The per-platform
   LICENSES manifest itself stays DEFERRED to the first tagged macOS
   release (ADR-017 l.545) — nothing tags here (tags exactly
   v1.0.0/v1.0.1/v1.1, unchanged) and the lane uploads nothing, so
   no row is owed NOW; at the first conveyance the macOS rows are
   exactly: (i) the MCU-derived palette inside the .dylib (Apache-2.0
   §4.1 — THIRD-PARTY-NOTICES is its attribution) + (ii) GPL §6
   (the corresponding-source offer naming the exact crate versions)
   — and NOT a Swift-runtime row. The choice is lawful either way
   (the exception waives attribution even for the embedded case) but
   it is NOT silent: rider 1's sentence carries "dynamically linked
   from the OS at /usr/lib/swift, never embedded: no LICENSES row",
   and rider 4 puts the facts + the ruling in the close record.

5. **The otool -L no-network guard — DISCHARGED, extended beyond my
   minimum.** hygiene.yml l.604–618: the guard runs over BOTH the
   built executable AND the cdylib (the N4 both-binaries precedent,
   held), with the denylist `CFNetwork|Network\.framework|libcurl|
   libssl` — my minimum was CFNetwork + Network.framework, my
   advisory 5 asked for libcurl or a reasoned exclusion, and the
   lane took BOTH libcurl and libssl. The step also carries a
   positive control (the cdylib MUST link /usr/lib/libSystem.B.dylib
   — the guard can't pass vacuously) and the honest scope wording
   (the workflow comment l.503–506: Foundation transitively loads
   CFNetwork as an OS fact; the claim proven is "no network library
   directly linked BY the app/core" — the exact-list tightening the
   comment promises is now done by this report's enumeration in
   condition 4). The guard ran green on the live run 45977202882
   (the macos job's step in the all-green lane). The drift rule
   rides the entry report: any network-framework addition must
   change the in-app note in the SAME commit.

6. **The honesty set, macOS-honest on BOTH surfaces — DISCHARGED,
   byte-verified.** Headless: the footer is byte-exact against
   expected-headless.txt l.42–43 (mechanically compared in-session:
   both lines identical byte-for-byte, em-dash included), the
   header identical to l.1 ("ClearFile — TY2025 federal summary
   (demonstration prototype)"), the "File:" line's geometry honest
   (the smoke's cwd is the repo root, the fixture path relative —
   matches l.2 exactly), and the full-stdout diff ran green on
   45977202882 — one canonical text family, three platforms, proven
   mechanically (plus the pre-push independent Python port: 1766
   bytes identical — disclosed in the execution commit). Window: the
   no-file screen carries the three-fact set + the no-AI/no-network
   line + the IRS/Intuit/TurboTax non-affiliation line, all
   byte-identical to the Windows app's family wording
   (main.swift l.384–389 vs main.cpp — verified string-for-string);
   the title bar carries "ClearFile (prototype) — TY2025 federal
   summary" (l.369); the qualified-professional line lives in the
   headless footer (byte-pinned) — the same surface split as the
   Windows family, so the shape is family-consistent, not a gap. The
   no-AI/no-network claim is TRUE (zero network code; condition 5's
   guard is its proof — macOS has no permission manifest, so the
   guard IS the enforcement). The D12 AI-disclosure correctly
   ABSENT; zero Google/Material logos (zero binary assets at all).

7. **The README row — NOT YET LANDED; this is the close rider my
   entry condition 7 scheduled (the gate's ledger item 11 says
   "at close"), and rider 2 rules the exact text.** Verified:
   README.md is absent from the delta (repo-wide: no apps/macos row
   exists yet). The ruled row (rider 2) carries everything
   condition 7 required: the unreleased + Flutter-remains-shipped
   sentence; the built-and-verified-on macOS 26 arm64 ONLY fact;
   all four named non-verifications (no interactive GUI run in CI;
   the macOS 13 floor = a build-time deployment target, never
   runtime-verified; no x64-macOS; no owner-side build); the green
   run number 45977202882 (the N4-registered run-ID convention, at
   last applied at the row it belongs in); the GA clause (the bar
   ruling's debt). A bare "runs on macOS 13+" would advertise a
   build-config setting as a runtime fact — the ruled text frames
   the floor as the deployment target it is.

8. **The .gitattributes renormalize ZERO-DIFF — DISCHARGED, asserted
   and recorded.** The zero-diff is recorded twice in-tree (the
   .gitattributes' own comment l.9–10: "verified by two isolated
   renormalize probes at the N5 gate: zero content deltas" — the
   ENG/PROD isolated-clone probes of the gate record; and the
   execution commit 48d981d: "the renormalize zero-diff
   re-verified in-session"), and re-verified by THIS exit gate
   live: `git add --renormalize .` → zero staged deltas, clean
   status. The byte-pinned family is untouched by the delta
   (expected-headless.txt is absent from the diff — its bytes, the
   CI contracts, unchanged). The mark list covers every tracked
   binary class (png/pdf/ico — the entry tally; the .dll/.lib/.exe
   marks defensive; the new *.dylib/*.wasm marks defensive, noted
   for N6's WASM lane).

9. **The no-ship discipline + the version plane + the bar ruling —
   DISCHARGED.** The macos-app job uploads NOTHING (its steps: the
   guards, the identity echo, the cdylib, the battery, the
   include-line assertion, the zero-dep assertion, the SPM build,
   the floor assertion, the smoke, the link guard — zero upload
   steps; `rg -c "upload-artifact" .github/workflows/` →
   release.yml 6 ONLY; hygiene.yml stays at zero); the hygiene.yml
   diff is PURELY ADDITIVE (+134/−0 — the other seven jobs
   byte-untouched); tags exactly v1.0.0/v1.0.1/v1.1; the protected
   set byte-unchanged (the delta touches NO core/, core-ffi/, or
   release.yml path — the Flutter macOS release lane remains the
   ONLY shipped macOS artifact); apps/macos 0.1.0 is the NEW
   source-side plane, now in-tree as a constant (kAppVersion,
   main.swift l.49–52 — the N4-exit advisory 5 taken: the Windows
   plane was record-only, this one lives in the source too), never
   app-semver, the envelope schema stays 2; the bar ruling + the GA
   debt are recorded (the CONSENSUS gate record l.1955–1957 + the
   STATE agenda l.399–407: a macos-latest CI job alone satisfies the
   demo bar; any macOS GA owes the owner-side build or the recorded
   acceptance). The per-platform LICENSES manifest stays deferred
   (condition 4's ruling).

## The clean-room line (mandate) — HOLDS

main.swift is a from-scratch Swift port of OUR OWN committed
expression: the text family is our own (expected-headless.txt,
GPL-3.0-only — porting our own text across our own platforms is not
copying); the structural mirror is our own apps/windows/main.cpp
(same license, same author — the argv modes, the pipeline shape, the
honesty set are our own expression, reused by us). The labels
("Total income", "Adjusted gross income", the group titles) are
standard IRS-form terminology dictated by the domain — functional,
unprotectable structure under §102(b)/merger/scènes à faire, *CA v.
Altai* abstraction — and the formats (printf-family "%.2f", the
comma grouping) are functional conventions. The Swift/AppKit code
(NSView draw, NSOpenPanel, NSAttributedString, JSONSerialization,
Result/Error) is stock platform idiom — API usage, not expression.
The byte-parity is enforced BY our own CI contract against our own
committed bytes, not by any third-party provenance. Zero third-party
Swift code enters the app (zero external SPM deps — condition 1's
mechanism); the palette stays inside our own attributed Rust module
(the single NOTICES entry remains the attribution); JSON rides the
system framework. No third-party expression found in the
spot-check; nothing to remediate.

## The CI round record's honesty (mandate) — ADEQUATE, no concern

Three rounds, each diagnosed + fixed + recorded in its own commit
message: round 1 (the run on 48d981d) — SwiftPM's tools-version
line-1 rule ("backward-incompatible with Swift < 6.0"); fixed by
cdd25a1 (directive to l.1, SPDX follows), the finding ALSO recorded
in the manifest's own comment (l.18–21) — the best possible home;
round 2 (run 45976627388 on cdd25a1) — Swift-5's Result requires
the failure type to conform to Error (String does not); fixed by
9cfffa7 with the LoadError wrapper — verified in source: the struct
(l.236–238), every failure site constructing LoadError(message:…),
the three consumers reading error.message (l.359/406/447), exactly
as the commit says; round 3 (run 45977202882 on 9cfffa7) — GREEN,
all eight jobs. Each round's message honestly records the GREEN
prefix (what passed, not just what failed), the identity echo
(swift-driver 1.148.6, rustc 1.100, host aarch64-apple-darwin), and
the single red step. The pre-flight audit's catch (the throwing
write(contentsOf:) needing try?) was fixed BEFORE the push and
DISCLOSED in the execution commit ("AUDIT-DEFECTS(1)") — the
opposite of concealment; the fix is in source (try? at l.301/l.307).
Disclosure adequacy: no gap. The ONE bookkeeping residual: neither
the final run ID 45977202882 nor 45976627388 is in-tree yet
(repo-wide grep: zero hits — the commit messages carry the rounds
by SHA, the lane by run) — rider 4's close entry is its discharge
(the N4-exit advisory 6 convention, registered at N4's close and
now applied at the row [rider 2] and the session record [rider 4]).

## Close riders (binding, exact text)

1. **The ADR-017 annex's Swift sentence** — insert into
   harness/memory/DECISIONS.md's licensing annex (l.537–548),
   immediately after "Kotlin/Apache-2.0 is GPL-3-compatible." and
   before "A per-platform LICENSES manifest lands with each
   platform's first tagged release.", this exact sentence:

   > The Swift compiler, standard library, and runtime are
   > Apache-2.0 under the Swift Runtime Library Exception (runtime
   > portions redistributable in binary products without Apache
   > §4 attribution — GPL-3-compatible, and linked dynamically from
   > the OS at /usr/lib/swift, never embedded: no LICENSES row);
   > SPM is Apache-2.0, build-time-only, never distributed (the
   > cbindgen/gradle class); Foundation joins AppKit as an Apple
   > system framework under the same §1 carve-out.

   (One sentence, the annex's own semicolon style; discharges entry
   conditions 3 and 4's disposition record. Recorded from the
   resolved toolchain, live-verified 2026-11-27 at entry — not
   transcribed from the proposal.)

2. **The README apps/macos row** — add to README.md's component
   table immediately after the `apps/windows/` row (l.27), this
   exact row:

   > | `apps/macos/` | The **macOS native UI** (N5 of the ADR-017
   > epilogue, ENTERED 2026-11-27): a Swift + AppKit viewer demo —
   > an SPM package whose C wrapper target (the umbrella header
   > includes the committed `core-ffi/clearfile.h` verbatim; the
   > symlink shape rejected at the gate) feeds the Swift executable.
   > The argv modes mirror the Linux/Windows apps (`--headless
   > <path>` / a bare path / the window), the ONE shared pipeline
   > (the 512 MiB pre-read bound → the composed
   > `clearfile_load_and_compute`), and the headless stdout is the
   > byte-exact same text family (the CI smoke diffs it against the
   > Linux app's committed expected text — one canonical family,
   > three platforms, EOL-normalized). The AppKit window mode
   > renders the summary with the MD3-from-seed palette-FFI theme +
   > the full honesty set; the no-network claim is mechanically
   > proven by the otool -L direct-linkage guard over both the
   > executable and the .dylib. Zero external SPM dependencies,
   > zero engine logic. CI: the macOS-app job on `macos-latest`
   > (the rustc + host-triple `aarch64-apple-darwin` guards, the
   > boundary battery ON MACOS, the SPM build, the
   > deployment-floor assertion via `LC_BUILD_VERSION` minos 13, the
   > headless smoke, the link guard) — hygiene run **45977202882**,
   > all eight jobs green. Built + smoke-verified on macOS 26 arm64
   > ONLY: the macOS 13 floor is a build-time deployment target,
   > never runtime-verified; no x64-macOS; no interactive GUI run in
   > CI (the window mode is the named non-verification); no
   > owner-side build (the GA debt per the bar ruling). A
   > demonstration prototype, unreleased — the Flutter macOS app
   > remains the shipped macOS product. |

3. **The D14 root-dotfile class, one line** — append to DEBT.md's
   D14 recorded un-headed classes (the l.22 amendment's list), this
   exact clause:

   > ; root dotfiles/directives (`.gitignore` — un-headed by the
   > repo's own pre-existing convention, the precedent now
   > recorded)

4. **The close record's content** (the SESSION_LOG N5 close entry +
   the CONSENSUS close-out; discharges entry condition 4's record
   duty + the run-ID convention): the entry must state — (i) the
   linkage facts from run 45977202882's otool output: "the
   executable's direct links = the core dylib + libSystem.B.dylib +
   AppKit + CoreGraphics + Foundation + libobjc + the OS Swift
   runtime at /usr/lib/swift (all OS-shipped — no Swift runtime
   embedded); the cdylib's direct links = exactly itself +
   libSystem.B.dylib"; (ii) the ruling: "no Swift-runtime row at any
   conveyance (nothing Apache-licensed embedded); the macOS
   first-conveyance rows stay the palette (Apache-2.0 via the
   .dylib) + GPL §6 corresponding source; the per-platform manifest
   stays deferred to the first tagged macOS release"; (iii) the
   green run ID **45977202882** on 9cfffa7, all eight jobs, with
   the three-round honest record (round 1 the tools-version line-1
   finding; round 2 run 45976627388 the Result/Error conformance →
   the LoadError wrapper; round 3 green) + the pre-flight
   write(contentsOf:) catch; (iv) the named non-verifications (no
   GUI run in CI; macOS-13 build-time-only; no x64; no owner-side
   build) riding the single-session box record. The standard close
   set (checker N-outcomes 8→9, ROADMAP/STATE close-out) is the
   bookkeeping's own duty, not restated here.

## Risks register (carried, updated)

- **(a) Stated-license-as-fact (carried; held this gate).** The
  annex sentence is ruled from the live-verified resolved toolchain;
  keep the discipline — any future toolchain row records from the
  resolved tool, never from a proposal.
- **(b) First-conveyance trigger, restated for macOS (carried,
  ONE row family only).** The first conveyed macOS native artifact
  (any .app/.zip/share — the accidental vectors of risk (g) stay
  closed) triggers Apache-2.0 §4.1 (the palette inside the .dylib —
  NOTICES is its attribution) + GPL §6. NO Swift-runtime row ever
  (nothing embedded — this gate's ruling). Nothing conveys today.
- **(c) No-network drift (carried; guard is the enforcement).** The
  direct-linkage-only scope is honestly worded in-tree; the
  residual is the same-commit guard-bypass + network-import class —
  the drift rule (the note changes in the same commit) rides the
  entry report.
- **(d) Two-MD3-statements discipline (carried; held).** The macOS
  theme computes from the palette FFI; the NOTICES entry stays the
  attribution; no logos (zero binary assets).
- **(e) Symlink fragility (MOOTED, transmuted).** The symlink never
  landed (the wrapper shape is in-tree; `git ls-files -s` → zero
  mode-120000 entries). The residual risk is the include-path drift
  — guarded mechanically by the CI's include-line assertion +
  harness_check's `MAC_INCLUDE` family; the "replace it with a copy"
  push still re-opens the lane.
- **(f) Toolchain/runner drift (carried).** macos-latest floats; the
  identity echo + the host-triple guard + the floor assertion are
  the tripwires; the runner facts were probed live at entry
  (macOS 26 arm64) — re-read at any lane change (risk noted: the
  N4-exit "terms re-read at green" gap — this gate's facts ARE
  recorded at green via the identity echo).
- **(g) Accidental conveyance (carried; held).** Zero uploads; the
  outputs stay runner-local behind the .gitignore blob rules.
- **(h) The x64 gap (carried).** Any future "universal binary"
  claim carries an untested x64 half — verify on an intel lane or
  label untested.
- **(i) NEW — the tools-version/SPDX position.** Package.swift's
  SPDX header sits at l.2, forced by SwiftPM's line-1 directive
  rule (the round-1 finding, recorded in the manifest's comment).
  Future SPDX sweeps must not flag this as a miss; a Swift-6
  tools bump could re-allow line-1 SPDX — leave the recorded rule
  ("line 1 = directive") as the tree's shape.
- **(j) NEW — the D2D/NSOpenPanel direct-draw shape.** The window
  mode is the named non-verification (no interactive desktop on
  the runner) — its honesty is the README row's fourth
  non-verification + the no-file screen's text; the GA debt (the
  owner-side build) is the recorded close to that gap.

## Advisories (non-binding)

1. THIRD-PARTY-NOTICES rows NOW (carried; still cheap): the
   build-time-only rows (SPM Apache-2.0; the open cbindgen MPL-2.0
   — its attribution currently lives in clearfile.h's banner; the
   Android build-stack rows) — nothing due (nothing conveys; the
   Swift runtime will never need one per this gate's ruling).
2. The .gitattributes' new *.dylib/*.wasm binary marks are
   defensive today (no tracked instances) — *.wasm may go live at
   N6; the mark is already in place.
3. The reports class (50+ un-headed adversarial reports) still
   rides the N4-exit advisory — rider 3's D14 amendment is the
   natural moment to add it if the bookkeeping chooses.
4. The single-session box's in-tree record (entry advisory 8) —
   rider 4's close entry is its natural home.
5. The slip's ELEVENTH surfacing rides with N6's TERMINAL gate
   (PROD's mandatory item) — noted cross-lane, deliberately not
   owned here; nothing in this delta contradicts it.
6. Prefer pinning the Swift tools-version policy as-is (5.9 = the
   Swift-5 language mode, the recorded deliberate choice avoiding
   Swift-6 strict concurrency) — a bump is a lane re-opening, not a
   routine update.

## Files read + verification log

**Records:** my entry report `2026-11-27-n5-legal.md` (full — the 9
conditions + risks (a)–(h)); the N4 exit `2026-11-27-n4exit-legal.md`
(the format + the carried advisories: the run-ID convention [rider
4], the source-side version constant [taken], the reports class
[rider 3's moment]); the N5 delta `git diff ff127f2..9cfffa7` +
`--stat` (8 files, +714; the three execution commits 48d981d /
cdd25a1 / 9cfffa7 with their full messages — the honest round
record); `CONSENSUS.md` l.1938–2089 (the N5 entry record: the
probe findings incl. the wrapper-header ruling + the bar ruling
l.1955–1957, the 13-point ledger — items 8/9/11 are riders 1–4's
scheduling, the ENTERED outcome); `STATE.md` l.363–412 (the N5
agenda incl. the "at close" list + the four named non-verifications
l.399–407); `DECISIONS.md` l.505–548 (the tiering l.512, the
licensing annex l.537–548 — the missing Swift sentence verified);
`DEBT.md` D14 (the recorded un-headed classes — no dotfile class,
rider 3); `SESSION_LOG.md` (the N5 execution session is NOT yet
recorded — the close entry is rider 4's vehicle).

**In-tree (at tip 9cfffa7):** all four apps/macos files (full reads
— Package.swift's line-1 directive + l.2 SPDX + the recorded finding;
ClearFileFFI.h's umbrella include + SPDX; shim.c's SPDX + the one
anchor typedef; main.swift's 457 lines: kAppVersion 0.1.0 l.52, the
LoadError struct l.236–238 + the three .message consumers
l.359/406/447, the try? write fix l.301/307, the byte-exact footer
l.222, the header l.201, the window honesty set l.384–389, the
title l.369, the guard-let/defer ownership l.269–275);
`.github/workflows/hygiene.yml` l.486–618 (the macos-app job: the
guards, the identity echo, the cdylib, the battery, the include-line
assertion, the zero-dep assertion, the SPM build + resolved-absence,
the floor assertion, the smoke geometry, the otool guard with the
extended denylist + the libSystem positive control) + the diff
(verified purely additive, +134/−0); `.gitattributes` (SPDX l.1; the
renormalize-probe comment); `.gitignore` (the N5 block, pre-existing
posture preserved); `scripts/harness_check.sh` (the N5 families —
run in-session: 0 failures).

**Live probes (read-only, 2026-11-27):** `git log`/`git status` →
tip 9cfffa7, clean tree; `git tag --list` → exactly v1.0.0,
v1.0.1, v1.1; `git ls-files apps/macos` → exactly 4 text files
(zero binaries); `git ls-files -s | rg '^120000'` → zero (the
symlink never landed); Package.resolved repo-wide → none;
`.package(|url:|from:|.binaryTarget|.systemLibrary` over
Package.swift → zero; `git add --renormalize .` → zero deltas;
`rg -c upload-artifact .github/workflows/` → release.yml 6 only;
`rg 45977202882|45976627388` repo-wide → zero (rider 4's gap); the
byte-comparison script: main.swift's footer == expected-headless.txt
l.42–43 (True), header == l.1 (True); `bash scripts/harness_check.sh`
→ 0 failures; README.md l.19–27 → no apps/macos row yet (rider 2's
gap); THIRD-PARTY-NOTICES.md → the two entries, unchanged.

**Working-tree discipline:** read-only probes only (the one
renormalize check staged nothing — zero deltas, tree restored);
this report is the sole new file of this lane. Final state:

```
$ git status --short
?? harness/adversarial/reports/2026-11-27-n5exit-legal.md
```
