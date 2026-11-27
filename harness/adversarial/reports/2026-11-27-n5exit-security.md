# ADV-SEC — N5 exit gate (2026-11-27, Task N5-EXIT-SEC)

Reviewer: ADV-SEC (secrets/CI-CD/supply chain/untrusted-input surfaces + release
integrity + token lifecycle; per ROLES.md). The N5 exit under review, ruled
adversarially: the N5 delta `ff127f2..9cfffa7` (8 files, +714, all additions —
`apps/macos/**` (Package.swift, the wrapper umbrella header, shim.c,
main.swift), `.gitattributes`, `.gitignore`, `.github/workflows/hygiene.yml`
(the new eighth job "macos-app"), `scripts/harness_check.sh` (the N5
families)) — the lane LIVE-GREEN: hygiene run **45977202882** on 9cfffa7, all
8 jobs, in 3 CI rounds with the honest record (round 1: the SPM
tools-version directive must be the manifest's first line — the finding now
recorded in the manifest's own comment; round 2: Result's failure type must
conform to Error — the tiny LoadError wrapper, recorded in-source; round 3:
green), plus 1 defect caught by the blind pre-flight audit before any push
(the throwing `FileHandle.write(contentsOf:)` needing `try?`). Runner
identity: macOS 26.7.2 arm64, swift-driver 1.148.6, rustc 1.100 host
aarch64-apple-darwin; the boundary battery 10/10 ON MACOS; the
deployment-floor assertion green (LC_BUILD_VERSION minos 13.0); the headless
smoke byte-parity green vs the Linux expected text; the linkage facts from
the green run's log: the EXE's direct links = the core dylib + libSystem +
AppKit + CoreGraphics + Foundation + libobjc + the OS Swift runtime (all
OS-shipped, nothing embedded), the CDYLIB's direct links = exactly
[itself, /usr/lib/libSystem.B.dylib]; no uploads anywhere. Read first, as
instructed: my own N5 entry report
(`2026-11-27-n5-security.md`, all — the 7 conditions below are MINE, probed
one by one at this exit), the N4-exit format
(`2026-11-27-n4exit-security.md`), `harness/memory/STATE.md` l.363-413 (the
N5 agenda, the gate's ruling set, the recorded close plan),
`harness/adversarial/CONSENSUS.md` l.1888-1936 (the N4-exit run-ID
convention). The sibling N5-exit reports were neither read nor written
(isolation rule).

All seven of my entry conditions are discharged in substance — every one
with a mechanical check behind it, none on trust alone — with exactly two
checkable elements riding to the close as numbered riders: (a) condition 6's
exact-list assertion on the cdylib was deliberately deferred to THIS gate by
the lane's own in-workflow deferral comment ("the full lists stay visible
above for the exit gate's exact-list tightening") — RULED below: tighten
(rider 2); the green run's log closed my entry blind spot, the cdylib's list
is NOW KNOWN (exactly [itself, libSystem.B.dylib]); (b) condition 7's README
row + run number is assigned by the recorded close plan (STATE l.400-403)
to land at the close (rider 1). The two entry-report conditions that
changed shape at the gate itself (the symlink → the wrapper-include
contract) are superseded by the gate's recorded ruling, not violated by it:
the substance (the SAME committed header reaches the build, depth-correct,
asserted mechanically, freshness walled elsewhere) is discharged in a
stronger shape — zero symlinks repo-wide (the mode-120000 preservation class
is void by construction), the compiler itself pins the include resolution,
and the CI grep pins the contract line byte-exactly. Everything else
measured clean: the job's security shape mirrors the windows lane exactly
(pinned checkout only, job-level contents:read, guards fail-closed first,
zero uploads/secrets/interpolation/new triggers); the SPM zero-dependency
posture is asserted fail-closed both declared and resolved; the .gitignore
guard joined the scaffold in the same commit; the C-ABI discipline in
main.swift is the windows template faithfully ported (guard-let, defer at
the tightest scope, the immediate copy-out, the pre-read bound with the
byte-exact message family); the variant preconditions all hold byte-exactly
(release.yml, core/, core-ffi/, clearfile/, src/ untouched; no tags;
nothing shipped); the gitleaks lane is byte-untouched and green; the
.gitattributes EOL hardening shows no security-relevant side effect on the
other seven lanes (assessed below with the census + three consecutive green
runs); the install-name oddity is sound for a CI-only lane (assessed below).

**VERDICT: PROCEED-WITH-CONDITIONS (2 numbered close riders; 0 BLOCK; all 7 entry conditions discharged in substance)**

## Conditions (the discharge proofs)

1. **The wrapper-include contract (entry condition 1, the gate's superseded
   shape) — DISCHARGED.** The symlink was REJECTED at the N5 gate itself
   (both my entry probe findings recorded: the four-level literal dangles,
   and the sandbox cannot `ln -s` at all), and the gate's ruled replacement
   landed exactly as ruled (STATE l.368-370): the wrapper umbrella header
   `apps/macos/Sources/ClearFileFFI/include/ClearFileFFI.h` — a 12-line file
   (SPDX + the honesty comments + ONE include line) that includes the
   committed header VERBATIM, nothing re-declared, nothing copied. Evidence,
   run live: (a) the CI step's assertion (hygiene.yml l.561-562) is
   `grep -F '#include "../../../../../core-ffi/clearfile.h"' <umbrella>` —
   run VERBATIM in this sandbox: MATCH (the literal is five `../`, the
   depth-correct count my scratch probe proved: include → ClearFileFFI →
   Sources → macos → apps → root); the umbrella's l.12 is byte-identical to
   the grep literal; (b) the include path resolution verified live
   (normpath of the include against the header's directory →
   `core-ffi/clearfile.h`, exists — the dangling-link class is dead); (c)
   the resolution is COMPILER-PINNED — `swift build` consumes the umbrella
   through the ClangImporter, so a wrong or poisoned target reds the build
   (the round-1 log's green prefix proves the assertion step runs before
   the build); (d) `git ls-files -s | grep -c '^120000'` → **0 repo-wide**
   — no symlink anywhere, so the mode-120000-through-backup preservation
   class my entry condition feared is void by construction; (e) the
   freshness wall stays where the ruling puts it (the android job's every-push
   cbindgen regen + diff — byte-untouched, outside the delta);
   (f) `scripts/harness_check.sh` carries the same literal as a local family
   (`MAC_INCLUDE`), and the checker runs green in this sandbox (0 failures).
   Checkable: the verbatim grep above; the ls-files count = 0.
2. **No new actions; the lane's security shape — DISCHARGED.** The macos-app
   job's (l.486-619) only `uses:` is the existing pinned checkout
   `11d5960a…77262` (l.518 — the EIGHTH occurrence of the same pin; the
   full `uses:` census: checkout ×8, gitleaks `ff98106e…70c7`,
   flutter-action `1a449444…d0b2`, setup-node `49933ea5…2002`,
   cargo-deny `81891abc…74fda` ×2 — zero new actions, zero unresolvable
   refs, no swift-setup/toolchain actions: the macOS 26 image ships the
   toolchain, proven green). Job-level `permissions: contents: read`
   (l.514-515) + `timeout-minutes: 45` (l.516); the rustc ≥ 1.95 guard + the
   aarch64-apple-darwin host-triple assertion come FIRST after checkout and
   fail closed (l.523-540: unparsable → exit 1; < 1.95 → exit 1; host ≠
   aarch64-apple-darwin → exit 1 — the green run's identity echo recorded
   rustc 1.100 on exactly that host). Zero upload/artifact steps (grepped:
   every "upload/artifact" hit is a policy comment or a step's own echo
   text); the workflow's only `secrets.*` remains the gitleaks job's
   GITHUB_TOKEN (l.35, pre-existing, outside the delta); zero
   `pull_request` anywhere in the file (grep → 0 — no untrusted-event input
   can reach any `run:` block; the smoke's inputs are committed repo files);
   zero `${{ }}` interpolation in the new job (grep → 0 — no
   script-injection surface; the `-Xlinker` flags are committed literals in
   the single-token form). The whole hygiene.yml delta is ONE purely
   additive hunk at l.483+ (+134/−0: every removed-line grep over the diff
   comes back empty; the trigger-related diff-line count = 0) — the on:
   block, the workflow-level permissions, the gitleaks job, and all seven
   other jobs are byte-identical to ff127f2. The rounds' fix commits were
   surgical (cdd25a1: Package.swift only; 9cfffa7: main.swift only — no
   security-surface drift between rounds). Checkable: the uses census; the
   three greps (upload/artifact, secrets., pull_request) over the delta.
3. **The SPM zero-dependency posture asserted fail-closed — DISCHARGED.**
   The CI grep step (l.565-571) refuses `.package(`, `.binaryTarget`,
   `.systemLibrary`, and any `url:` source — run VERBATIM in this sandbox
   over `apps/macos/Package.swift`: zero matches (grep exits 1, the fail
   direction; the manifest's target-level `dependencies: ["ClearFileFFI"]`
   correctly does not false-trip — the anchored package-level forms); and
   the post-build half (l.578, same step, AFTER `swift build`):
   `test ! -f Package.resolved || exit 1` — with zero external deps SPM
   emits no resolved file, so an emerged Package.resolved means a
   dependency joined and reds the lane. No Package.resolved is committed
   (`git ls-files apps/macos` → exactly 4 files: the manifest, the
   umbrella, the shim, main.swift — sources + manifest only, the N2/N3/N4
   discipline). `scripts/harness_check.sh` carries the same grep as the
   local family (`MAC_DEPS`, green in this sandbox). This is the
   Swift-side supply-chain lock, the android classpath-assertion analogue
   my entry condition demanded. Checkable: both greps above, run verbatim.
4. **The .gitignore guard-order — DISCHARGED.** The rules
   `/apps/macos/.build/` and `/apps/macos/.swiftpm/` are present
   (.gitignore l.153-154, under the l.149-152 comment block), scoped under apps/macos with the exact precedent
   shape (no bare `*.dylib`-class patterns that could shadow anything), in
   the SAME commit as the entire scaffold — verified by commit archaeology:
   `git log -S '/apps/macos/.build/' -- .gitignore` → 48d981d, and
   `git log --diff-filter=A -- apps/macos/…` → 48d981d (the one-session
   execution commit; the sandbox never builds Swift, and the first build
   was CI-side on the push of that very commit — guard-before-any-build by
   construction, belt-and-braces on top of the never-builds-locally fact).
   `git ls-files apps/macos` shows no SPM residue; the tracked binary
   census is 0 across dll/exe/obj/lib/pdb/dylib/wasm/so/a. Checkable: the
   two git-log commands; the 4-file ls-files.
5. **The C-ABI consumption discipline in main.swift — DISCHARGED.** Every
   entry-condition element, measured: (a) guard-let on the owned return —
   l.269-273 (`guard let owned = … else { return .failure(…) }`, never a
   force-unwrap), with the input borrow kept inside the `withUnsafeBytes`
   scope (l.269-271); (b) `defer { clearfile_free(owned) }` at the TIGHTEST
   scope — l.274, inside the same do-block, after the guard, and the
   `String(cString: owned)` copy at l.275 precedes the scope-exit free by
   execution order; `rg clearfile_free apps/macos` → exactly TWO hits: the
   discipline comment (l.34) and the one defer (l.274) — no second free
   path, no manual release, no libc free anywhere; (c) the borrowed
   thread-local `clearfile_last_error()` copied out IMMEDIATELY —
   `lastErrorText()` (l.44-47: guard-let + `String(cString:)`, the copy at
   the point of call) is invoked exactly once, at l.272, directly at the
   NULL-return site and before any further clearfile call on the thread;
   never cached across the AppKit event loop (the failure path returns
   immediately; the panel callback re-enters `loadAndCompute` fresh);
   (d) the single-threaded posture documented in-source (l.36-39: the
   headless path never touches AppKit; the window mode runs the main thread
   only); (e) the palette path consumes by VALUE (`UInt32` — no pointer to
   own; the 0-sentinel is the header's unknown-role contract, l.82-88 of
   clearfile.h — advisory 4); (f) the 512 MiB pre-read bound at the
   file-open path BY METADATA: the `FileManager.attributesOfItem` size
   query (l.244-253) precedes `Data(contentsOf:)` (l.257-259) — refused by
   metadata alone, pre-read — with the byte-exact named message family
   "The file is too large to open — the limit is 512 MiB." (l.255, the
   windows family's wording including the em-dash; the core's own boundary
   the backstop); (g) the output surfaces: `try? FileHandle.write(contentsOf:)`
   (l.299-309) — the pre-flight-audit defect (the throwing write needing
   `try?`) fixed BEFORE any push, exactly the author-blind mitigation the
   entry trade accepted. Checkable: the rg above; the ordering of the size
   query vs the read; the refusal grep in the same wording family.
6. **The otool guard, honestly scoped as DIRECT linkage — DISCHARGED with
   one element RULED at this gate (rider 2).** The landed guard (l.604-618):
   (a) honest wording — the step is named "direct linkage only" and the
   comments state the OS-level fact (Foundation transitively loads
   CFNetwork; the record is "no network framework linked BY the app/core"),
   exactly the scoping my entry condition demanded; (b) the denylist
   CFNetwork/Network.framework/libcurl/libssl over BOTH binaries (the exe
   l.610-612, the cdylib l.613-615); (c) the cdylib
   must-contain-libSystem (l.616-617); (d) BOTH full lists echoed to the run
   log BEFORE the greps (l.606-609) with the explicit deferral comment
   handing the exact-list question to this gate — the green run delivered
   the fact: the cdylib's list is exactly [itself, libSystem.B.dylib]
   (my entry blind spot, now closed); (e) the smoke's CWD pinning: no `cd`
   anywhere; the fixture, the exe, and
   `DYLD_LIBRARY_PATH="$PWD/core-ffi/target/release"` are all anchored at
   the repo root, and the step's own comment records the cwd contract
   ("the smoke's cwd is the repo root (the File: line's byte parity)") —
   pinned by construction and recorded. The exact-list assertion itself
   (my entry checkable) did NOT land — by recorded design, deferred to this
   exit gate's ruling: **RULED: TIGHTEN at the close — rider 2** (the
   ruling's reasoning under the rider). Checkable: the step wording; the
   two denylist arms; the full-list echoes; rider 2's landed form at the
   close.
7. **The variant preconditions — ALL HOLD, one element rides as rider 1.**
   Probed live over `git diff ff127f2..9cfffa7`: (a) `--name-only --
   clearfile src` → **0 paths**; (b) `-- .github/workflows/release.yml core
   core-ffi` → **0 lines** — release.yml byte-unchanged (the shipped-Flutter
   lanes untouched), core + core-ffi byte-unchanged (the `--locked`
   posture, the header-freshness wall, and the committed header itself all
   ride exactly as ff127f2 had them); (c) no tags over the N5 commits
   (`git tag --contains ff127f2` → 0; the three tags v1.0.0/v1.0.1/v1.1 all
   predate); (d) nothing shipped — no upload/artifact step anywhere in the
   delta (verified per condition 2), nothing leaves the runner; (e) the
   envelope schema untouched (core byte-unchanged — the schema lives in
   core/); (f) the version plane: apps/macos 0.1.0 as its own source-side
   constant (`kAppVersion`, main.swift l.52) — no Cargo.toml, no
   package.json, no other plane moved. The ONE element not yet landed: the
   README row + the green run number (the N4-exit run-ID convention,
   CONSENSUS l.1906-1908) — assigned by the recorded close plan to the
   close (STATE l.400-403: "at close: the README row (… the green run
   number …)"), after this gate — **rider 1**. Checkable: the four git
   commands above; rider 1's landed form at the close.

## The ruled questions

**Q2 — the exact-list tightening (my entry report's noted blind spot, now
closed by the green run's log): RULED — TIGHTEN the cdylib side to the
exact-list assertion at the close (rider 2).** The facts that decide it:
(1) the cdylib's direct-link list is now KNOWN — exactly [itself (the id
line), /usr/lib/libSystem.B.dylib] — so the assertion can be exact without
guessing; (2) the cdylib is OUR OWN build product (std-only Rust + the
pinned lock, `--locked` both build and test) — unlike the EXE's list, which
is Xcode-owned (AppKit/Foundation/the OS Swift runtime roll with the image
and legitimately vary), the dylib's list is a property of our crate: any
addition (a dependency pulling a framework link, a build change, a
toolchain roll altering the link set) is drift the lane wants NAMED, not
silently carried — the same fail-closed posture as the host-triple guard;
(3) the denylist's blind class is real: it catches the four network
families, but an unexpected non-network lib (libcrypto, libresolv,
Security.framework, any future rustc-added link) passes silently today — only
the exact list closes that class; (4) the cost is one small block and the
accepted trade of the fail-closed school: a legitimate toolchain roll that
changes the list reds the lane naming the actual list, and the fix is a
one-line update with a recorded reason. The EXE keeps its denylist + BOTH
full-list echoes (the Xcode-owned list must not be exact-pinned across
image rolls; the echoed full list remains the drift surface for the exit
gate to re-read). Precedent symmetry: the android lane's classpath
assertions are exact-set; my N4-exit register item 1 + advisory 1 said the
same for the windows import table (still open there — the asymmetry is
that the macOS core side is now CHEAP to close because the list is known
and two-elements long).

**Q3 — the install-name oddity (the EXE references the core dylib via the
runner-absolute cargo build-tree path): SOUND for a CI-only lane; a close
record note (advisory 2), not a rider.** The mechanics: the EXE's
LC_LOAD_DYLIB for the core dylib carries the dylib's install name as
recorded at ITS build — the runner-absolute build-tree path (the
rustc/cargo cdylib install-name behavior class). Assessment: (1) the smoke
does NOT depend on that path — `DYLD_LIBRARY_PATH="$PWD/core-ffi/target/release"`
takes precedence over the install-name lookup for slash-containing install
names (dyld consults DYLD_LIBRARY_PATH/leafname first), so the resolution
contract is owned by the workflow's own env, covering both install-name
shapes — the step's own comment records exactly this ("absolute — covers
both install-name shapes"), and the path it points at is produced by the
job's own `--locked` cargo build in the same job (the emission test at
   l.551), on an ephemeral runner, in a workflow with no pull_request
   trigger — no untrusted writer can plant that file; (2) the oddity is
   fail-closed everywhere else: off the runner, the absolute path does not
   exist and dyld aborts loudly (Library not loaded) — there is no
   CWD-relative lookup, no bare-leaf search surface, no silent hijack
   vector; the binary is unsigned and CI-only (nothing ships, no uploads,
   no artifacts), so there is no consumer to attack; (3) the env-var
   posture is honored because the debug executable is unrestricted (SIP
   strips DYLD_* only for restricted processes) — the standing entry-gate
   posture, still true; (4) the one real obligation: if the native macOS
   app EVER ships (a GA or an owner-side build re-opening the question per
   the bar ruling), the install name must be rewritten
   (`install_name_tool -id @rpath/…` or
   `-Xlinker -install_name,@rpath/…` at the link) and the smoke re-proven
   on the shipped shape — recorded as advisory 2, not a rider, because
   nothing ships and the bar ruling already records the GA debt. The
   current posture is sound: CI-only, env-owned resolution, fail-closed
   outside the runner.

**Q4 — the .gitattributes EOL hardening (`* text=auto eol=lf` + the
binary marks png/ico/pdf/dll/lib/exe/dylib/wasm): no security-relevant
side effect on the other seven lanes.** Measured: (1) the index is all-LF
today — `git ls-files --eol` over the whole tree: 0 `i/crlf`, exactly 29
`i/-text` (the 25 png + 3 pdf + 1 ico binaries, all now attr/-text via the
explicit marks), everything else `i/lf` — so an eol=lf checkout
materializes working trees BYTE-IDENTICAL to the index on every platform:
zero content transformation anywhere, the renormalize zero-diff holds, and
the N4 autocrlf root-cause class (the Windows runner converting the
committed LF expected text to CRLF at checkout) is dead at the source —
the smoke-side `tr -d '\r'` normalization stays as belt-and-braces, as
recorded; (2) the LF-sensitive classes were censused: zero tracked
.bat/.cmd/.ps1/.sln/.csproj files — the windows lane's cmd surfaces are
inline YAML `run:` blocks (YAML-parsed, not checkout-materialized batch
files), and the cmd errorlevel pattern landed in the N4 delta's own shape
and ran green; (3) the empirical spot-check demanded by the brief: all 8
jobs were green on run 45977202882 — with the .gitattributes active since
48d981d, this is the THIRD consecutive green run across all lanes (rounds
1-3; the round-1 record already notes "all seven other jobs green"), so
the LF checkout is proven compatible with the MSVC compile of main.cpp,
the gradle/Kotlin android lane, the flutter/tsc/node lanes, the python/bash
re-tooling + harness-check jobs, and the linux job — end-to-end, on the
runners, not by inference; (4) gitleaks is unaffected by construction: it
scans git HISTORY blobs (fetch-depth 0) and .gitattributes governs only
working-tree materialization, never blob content — the scan surface is
byte-identical; (5) the binary marks protect future committed binaries
from any normalization mangling (the blob policy remains the wall — the
tracked binary census is 0 for every product class; png/pdf/ico are the
only tracked binary classes, all explicitly marked). The hardening is
strictly positive: it converts a per-runner config state (autocrlf) into a
repo-owned contract.

**Q5 — the gitleaks posture: UNCHANGED and green.** The gitleaks job
(l.25-35: fetch-depth 0, the SHA-pinned gitleaks-action `ff98106e…70c7`,
the workflow's only GITHUB_TOKEN, workflow-level contents: read) is
byte-untouched — the entire hygiene.yml delta is the one purely-additive
macos-app hunk at l.483+ (+134/−0; verified: zero removed lines, zero
trigger-line changes in the diff), so the job, its permissions, its pin,
and its full-history scan are exactly what ff127f2 shipped; the
full-history scan ran green on run 45977202882 with the N5 delta present
(all 8 jobs green). The N5 delta itself adds no secret-bearing surface:
the four tracked apps/macos files are sources + manifest only (read in
full — no tokens, no keys, no URLs); the sandbox-backup secret guard
already covered the new path at entry (the `apps` entry in the ≥32-hex
scan path list, plus the unconditional TOKEN patterns — the standing
posture, unchanged). The token lifecycle is unchanged repo-wide: the only
CI token is the ephemeral gitleaks GITHUB_TOKEN; the PAT-bearing remote
is the standing sandbox-backup posture outside this delta.

## Risks register

1. **Runner-image drift + the `-latest` remap (carried from entry, rider 2
   now arms the core side).** macos-latest silently moving to macOS 27
   moves the lane's OS, Xcode, and triple at once; the fail-closed
   host-triple guard turns any remap into a red naming the value, and —
   once rider 2 lands — a toolchain roll that changes the cdylib's link set
   also reds naming the actual list. The standing note rides: the same
   remap ALREADY rides release.yml's shipped-Flutter-macOS lane (l.339,
   runs-on: macos-latest) — outside this delta; the recorded line is owed
   at the close (advisory 1).
2. **Verification concentration (the standing bar-ruling risk).** The
   whole macOS verification story is one lane on one image family,
   single-maintainer; the interactive window mode is compile-verified only
   (the named non-verification — CI has no desktop); any GA re-opens the
   owner-side-build question by construction.
3. **The blind-authoring trade — discharged as accepted, with the honest
   record intact.** The first compile WAS the CI run; the three-round
   record (the tools-version line-1 finding, the LoadError conformance
   finding) plus the pre-flight audit catch (the throwing write) is
   exactly the mitigation working; the rounds were surgical (one file
   each), and both findings are recorded in-source (Package.swift
   l.18-21; main.swift l.234-238).
4. **The EXE-side denylist blind class stays open BY RULING.** The exact
   list is ruled for the CDYLIB (ours) but not the EXE (Xcode-owned — its
   legitimate platform-framework set rolls with the image); an unexpected
   non-network direct link on the EXE's side would not red the denylist.
   The backstops: the app's own compile provenance (no network API call
   sites exist — zero external deps, the source read in full), the
   full-list echo in every run's log (the drift surface this gate just
   used), and any future EXE-list change is visible for the next exit
   gate to rule on.
5. **The 512 MiB RAM hazard (the standing note).** The uniform bound stays
   the recorded policy; the app-side pre-read refusal is the honest UX,
   the core boundary the backstop.
6. **The smoke's CWD coupling (carried from entry, now pinned + recorded
   in-workflow).** The whole-path stack (fixture, exe, DYLD_LIBRARY_PATH)
   resolves against the repo root; there is no `cd` anywhere in the job,
   and the step comment records the contract — the one-line mitigation
   the entry risk demanded has landed.

## Advisories (non-binding)

1. **The macos-latest/release.yml recorded line (entry advisory 5, still
   open):** one recorded line at the close that macos-latest also serves
   as release.yml's shipped-Flutter-macOS runner (l.339) — the runner-drift
   risk is shared between this CI lane and a SHIPPED lane; outside this
   delta, inside the honest record.
2. **The install-name close-record note (from Q3):** record in the close
   records that the EXE's LC_LOAD_DYLIB for the core dylib carries the
   runner-absolute build-tree install name (the rustc/cargo cdylib
   behavior), that the smoke resolves via the absolute DYLD_LIBRARY_PATH
   by precedence (covering both install-name shapes), and that ANY future
   shipping of the native macOS app must rewrite the install name
   (`install_name_tool` / `-install_name,@rpath/…`) and re-prove the smoke
   on the shipped shape. Off-runner the current shape fails closed
   (loud dyld abort, no search surface).
3. **The *.so / *.a binary marks (entry advisory 1, partially landed):**
   *.dylib and *.wasm are now marked alongside the dll/lib/exe set; *.so
   and *.a remain unmarked (none tracked — the blob policy is the wall);
   one-line symmetric hardening at any future touch.
4. **The palette 0-sentinel doc line:** `roleColor` (main.swift l.58-65)
   mirrors the N4-accepted windows `role_color` shape exactly — the
   mirror is the ruled contract; a one-line comment at the call site
   carrying the header's sentinel contract (0 = unknown-role sentinel,
   never a valid scheme color — clearfile.h l.82-88) is cheap insurance
   against a future role-key drift silently rendering transparent black.

## Close riders (the two numbered conditions this exit carries)

1. **The README row at close, carrying the green run number (the N4-exit
   run-ID convention; entry condition 7's element, assigned by the
   recorded close plan).** The row for `apps/macos/` must land with the
   close records and carry: the green run number **45977202882** (all
   eight jobs); the honest otool scope ("no network framework linked BY
   the app/core" — DIRECT linkage, not "the process contains no network
   code"); the unreleased/CI-only status (nothing ships, no uploads); the
   Flutter-macOS-app-remains-the-shipped-product sentence; all FOUR named
   non-verifications (no interactive GUI run in CI; no macOS-13 runtime
   verification — the image is retired, the floor is build-time-only
   asserted via LC_BUILD_VERSION minos 13.0; no x64-macOS verification;
   no owner-side build — the GA debt per the bar ruling). Checkable at
   close: `rg -n '45977202882' README.md` non-empty; the row carries the
   Flutter-remains-shipped sentence and the four non-verifications.
2. **The exact-list tightening on the cdylib (entry condition 6's
   deferred checkable, RULED at this gate).** In the macos-app job's link
   guard, after the two full-list echoes, tighten the cdylib side: assert
   the cdylib's DEPENDENCY lines (`otool -L` output minus the id line)
   are EXACTLY one line — `/usr/lib/libSystem.B.dylib` — nothing added,
   nothing removed, anything else reds the lane naming the actual list
   (the subsumed must-contain-libSystem may be folded in or left standing;
   the EXE-side denylist CFNetwork/Network.framework/libcurl/libssl stays
   as-is — the Xcode-owned list is not exact-pinned; both full-list echoes
   stay for drift visibility). Land with the close commit; re-proven by
   the next run. Checkable at close: the landed assertion is exact-list
   over the cdylib's dependency lines; the next hygiene run green.

## Files read + verification log

- Read first, as instructed: my own N5 entry report
  `harness/adversarial/reports/2026-11-27-n5-security.md` (all — the 7
  conditions probed one by one above); the N4-exit format
  `harness/adversarial/reports/2026-11-27-n4exit-security.md` (all — the
  report shape this exit follows);
  `harness/memory/STATE.md` l.355-413 (the N5 agenda, the gate's ruling
  set incl. the wrapper-include literal and the smoke geometry, the
  recorded close plan assigning the README row to the close);
  `harness/adversarial/CONSENSUS.md` l.1888-1936 (the N4-exit ledger: the
  run-ID recording convention, the N4 close-rider precedent).
- The N5 delta `git diff ff127f2..9cfffa7` (8 files, +714, purely
  additive — verified: zero removed lines across the whole diff): read in
  full over `apps/macos/Package.swift` (the tools-version directive on
  line 1 per the round-1 finding, `.macOS(.v13)`, the two local targets,
  zero external deps), `apps/macos/Sources/ClearFileFFI/include/
  ClearFileFFI.h` (the 12-line umbrella: the ONE include line, byte-exact
  vs the CI grep), `apps/macos/Sources/ClearFileFFI/shim.c` (the
  comment-only anchor TU), `apps/macos/Sources/ClearFileMacOS/main.swift`
  (all 457 — the discipline block, the display glue, the ONE shared
  pipeline, the output surfaces, the window mode, the argv modes),
  `.gitattributes` (the eol=lf rule + the binary marks), `.gitignore`
  (the scoped SPM-residue rules), `.github/workflows/hygiene.yml` (the
  macos-app job l.486-619 in full + the gitleaks job + the on:/permissions
  blocks re-read), `scripts/harness_check.sh` (the two N5 families).
- Live probes (2026-11-27, read-only, nothing modified outside this
  report): the CI include assertion run VERBATIM → MATCH; the include
  path resolution via normpath → `core-ffi/clearfile.h`, exists; the SPM
  zero-dep grep run VERBATIM → zero matches (exit 1, the fail direction);
  `rg clearfile_free apps/macos` → 2 hits (the comment + the one defer);
  `git ls-files -s` → zero 120000 entries repo-wide; `git ls-files
  apps/macos` → exactly 4 files (no Package.resolved, no residue);
  `git diff ff127f2..9cfffa7 -- .github/workflows/release.yml core
  core-ffi` → 0 lines; `--name-only -- clearfile src` → 0; `git tag
  --contains ff127f2` → 0 (three tags, all predating); the hygiene.yml
  delta → one hunk @@ -483,6 +483,140 @@, +134/−0, zero trigger-line
  changes; `grep -c pull_request` over hygiene.yml → 0; `${{` count over
  the macos job → 0; the `uses:` census (13 job/trigger keys; 8 jobs:
  gitleaks, suites, linux-app, android-app, windows-app, macos-app,
  re-tooling, harness-check); the tracked-binary census (dll/exe/obj/lib/
  pdb/dylib/wasm/so/a) → 0; the .bat/.cmd/.ps1/.sln/.csproj census → 0;
  `git ls-files --eol` → 0 i/crlf, 29 i/-text (the binary assets, all
  attr/-text), everything else i/lf incl. all four new apps/macos files;
  the round-2/3 commit scopes (`git show --stat`): Package.swift only /
  main.swift only; the commit archaeology for the guard-order
  (`git log -S` the ignore rule + `--diff-filter=A` the scaffold → both
  48d981d); `bash scripts/harness_check.sh` → green incl. both N5
  families (0 failures); `git rev-parse --short HEAD` = 9cfffa7 (the tip
  under review, matching the brief).
- Could NOT verify from this sandbox: the raw Actions run log of 45977202882
  (the linkage lists, the runner identity, the minos 13.0 pass, the 10/10
  battery, and the all-8-green status reach me via the brief + the commit
  records — the sandbox's posture excludes the API; the facts are
  consistent with the landed YAML verified here line-by-line, and the
  three-round commit record carries them in order); the interactive window
  mode (no desktop — the named non-verification); Swift compilation
  locally (no toolchain — the accepted trade; the lane's green run is the
  compile proof). No cargo run (ENG lane owns cargo probes); no packages
  installed; no network probes this session (the entry gate's live
  runner-images table stands as the recorded fact).
- Repo state at the exit: HEAD = 9cfffa7; the tree clean before this
  report; the sibling exit reports neither read nor written (isolation).

`git status --short` after filing (run live, verbatim):

```
?? harness/adversarial/reports/2026-11-27-n5exit-legal.md
?? harness/adversarial/reports/2026-11-27-n5exit-security.md
```

Only the second line is mine (`…n5exit-security.md`, this report — the only
file this lane created or modified). The sibling `…n5exit-legal.md` line is
the LEGAL lane's own filing, landed concurrently while I worked — NOT read,
per the isolation rule; the tree is otherwise clean (no tracked-file
changes, no drift).
