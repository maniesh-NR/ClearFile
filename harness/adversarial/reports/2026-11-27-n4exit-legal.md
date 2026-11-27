# ADV-LEGAL — N4 exit gate (2026-11-27, Task N4-EXIT-LEGAL)

The N4 delta (2a3acd1..9e6cf46: apps/windows/main.cpp — the first C++
consumer; the guarded committed header; the CI windows-app job; the
rider's supersession discharge; the README row; the guard joins) is
adversarially re-verified against my eight entry conditions, the carried
register, and the two standing posture items ((b) the first-conveyance
trigger, (c) the kotlin-stdlib notice posture). The execution is clean
where it matters most legally: the dependency surface stayed
platform-only, the no-network claim is now MECHANICALLY proven (the PE
import-table guard, green on the live run), nothing conveys, and the
honesty family landed verbatim. Two findings ride out as notes, neither
a violation: the CRT choice RODE the compiler default rather than being
pinned in-tree (the /MT consequence now recorded here), and the green
run is recorded by commit SHA but not by run ID.

**VERDICT: PROCEED (the N4 exit gate PASSES on this lane — 8/8 entry
conditions discharged; 2 recording gaps noted, carried as advisories; no
legal violation, no BLOCK)**

## Conditions

1. **The zero-dependency invariant — DISCHARGED (the recorded sweep,
   this report).** `main.cpp`'s include set is exactly the platform +
   CRT + C++ std + the committed header: `windows.h`, `commdlg.h`,
   `d2d1.h`, `d2d1helper.h`, `dwrite.h` (SDK), `fcntl.h`, `io.h` (CRT),
   `cstdio/cstdint/cstdlib/cstring/string/vector` (std), and
   `#include "clearfile.h"` — the ONLY quoted include, the committed
   ABI header; no third-party include exists. The link line is
   user32/gdi32/comdlg32/d2d1/dwrite + `clearfile_core_ffi.dll.lib` —
   platform + ours only. `rg -in "vcpkg|nuget|gitmodules"` over
   `apps/windows` + `.github/workflows/` → ZERO hits (probe exit 1). No
   vcpkg.json/manifest, no submodule, no vendored header anywhere in
   the delta. The tripwire (risk (a)) stays: any dependency added later
   re-opens this lane; there is no PERMANENT CI include-sweep guard —
   the sweep lives in this report + the entry report (advisory 1).

2. **The D14 SPDX sweep — DISCHARGED.** `git ls-files apps/windows` →
   exactly `main.cpp`, carrying `// SPDX-License-Identifier:
   GPL-3.0-only` (l.1) in the correct `.cpp` `//` syntax; zero binary
   assets (`git ls-files apps/windows | rg -i '\.(png|ico|jpg|jar)$'` →
   empty — the no-icon posture holds; no .rc, no VERSIONINFO, no new
   un-headed class needed). The fixture was never byte-copied: the smoke
   reads the SHARED `fixtures/migration/v1-web-envelope.json` — better
   than the preferred PULL lane; the expected text is the Linux app's
   committed un-headed artifact, not re-committed. The five new
   adversarial reports ride the un-headed convention; the workflow/
   README/.gitignore edits preserve their pre-N4 posture (no SPDX ever,
   the pre-existing non-code convention — not a new-N4 gap). Note: the
   reports class is precedent-backed (50 tracked reports since
   2026-11-14, all un-headed) but NOT among D14's RECORDED un-headed
   classes — advisory 2.

3. **The /MD-vs-/MT CRT choice — DISCHARGED WITH THE FINDING (the
   choice RODE the default; it is now recorded HERE).** The workflow's
   cl invocation carries NO explicit /MD or /MT flag; cl's default for
   a bare command-line compile is **/MT (static libcmt — Microsoft CRT
   object code embedded in the .exe)**. So the linkage is LAWFUL
   (redistribution of the embedded CRT object code is permitted by the
   VS/SDK terms under our own license) but the choice was never pinned
   in-tree: the gate ledger's point (6) "the /MD-vs-/MT CRT choice
   recorded" points at the reports' requirement text, not at a made
   choice. The consequence is therefore recorded by THIS exit report:
   **the CRT row joins the first-conveyance LICENSES-manifest checklist
   (risk (b))** — the .exe at ANY conveyance carries the MSVC CRT row
   alongside the Apache-2.0 palette row. Prefer /MD at the next touch
   of the build line (the UCRT then stays an OS System Library, no row).

4. **The honesty family, Windows-honest — DISCHARGED.** Verified in
   `main.cpp` source: the three-fact disclaimer verbatim-in-substance
   (l.334–336: "not IRS-authorized, cannot e-file, and must not be used
   to file a real tax return" + "Demonstration prototype — not tax
   advice; check with a qualified tax professional"); the
   non-affiliation line (l.454: "an independent study project. It is not
   affiliated with or endorsed by the IRS, Intuit, or TurboTax"); the
   prototype labels in the TITLE BAR (l.529 `L"ClearFile (prototype) —
   TY2025 federal summary"`) + the window body + the headless header
   (l.313 "(demonstration prototype)" — the headless header is the
   canonical Linux text family, byte-parity pinned, so its wording is
   the family's own); the no-AI/no-network note verbatim family
   (l.453: "No AI: this app makes no network connections, stores no
   keys, and sends no data anywhere"); the D12 AI-disclosure correctly
   ABSENT; zero Google/Material logos (zero binary assets at all). The
   D2D theme consumes the palette FFI at the corpus seed. The README
   row's interim statement landed with the literal "unreleased" word
   (entry advisory 5, taken): "A demonstration prototype, unreleased —
   the Flutter Windows app remains the shipped Windows product."

5. **The PE import-table guard — DISCHARGED (the promotion landed
   whole).** The windows job's MSVC step runs `dumpbin /DEPENDENTS` on
   BOTH the .exe AND the .dll, failing closed on
   ws2_32/wininet/winhttp/urlmon — the no-network claim's mechanical
   proof, replacing the OS enforcement Windows lacks; proven live (the
   green run's "import guard: ok"). The findstr-errorlevel gotcha
   (no-match = the GOOD case = errorlevel 1) is fixed by the
   load-bearing `exit /b 0`, honestly recorded in the step comment +
   SESSION_LOG. The drift rule (any network import ⇒ the in-app note
   changes in the SAME commit) rides the committed entry report — see
   advisory 4.

6. **The mingw rejection, recorded + mechanical — DISCHARGED.** The
   gate record (CONSENSUS's N4 ledger: "the local mingw lane REJECTED
   (the recorded second-ABI reasoning") + the README row ("the mingw
   lane rejected: a second ABI surface with no consumer") + the
   **host-triple assertion in the windows job** (rustc host must be
   `x86_64-pc-windows-msvc`, else FAIL) — the rejection is now
   ENFORCED, not just recorded; zero mingw toolchain installation in
   the workflow. The licensing reinforcement (a second header set + a
   second C++ runtime = a second license/notice surface, against the
   annex's one-audit-surface rationale) rides the committed entry
   report only — not restated in the workflow comments; risk (e) keeps
   it loaded for the recurrence.

7. **The no-ship discipline — DISCHARGED.** The windows job uploads
   NOTHING (its steps: checkout, the guards, the cdylib, the battery,
   the MSVC build + import guard, the smoke — zero upload steps;
   `rg -c "upload-artifact" .github/workflows/` → release.yml **6**
   only, and release.yml is byte-untouched, absent from the delta — the
   Flutter release pipeline stays the shipped product). Tags exactly
   v1.0.0/v1.0.1/v1.1 (unchanged). The protected set is byte-unchanged
   (the delta touches NO core/, core-ffi/Cargo.{toml,lock},
   package.json, apps/linux, apps/android, clearfile/, src/, release.yml
   — the variant preconditions hold). `apps/windows` is a NEW 0.1.0
   plane recorded in the gate ledger ("its own new publish=false
   plane… the version lives in the source + the record") — NOTE: no
   version string exists in main.cpp itself; the plane lives in the
   record alone (advisory 5). The .gitignore MSVC rules guard the build
   outputs pre-build (blob policy: .exe/.dll are CI-side only, never
   committed). The named non-verification (no interactive desktop) is
   recorded honestly, twice (SESSION_LOG sessions 1 + 2).

8. **The toolchain terms + live-verification — DISCHARGED, two
   bookkeeping notes.** The use-terms one-liner is in-tree in the
   committed entry report (condition 8's text: use-terms for the
   developer at build time, not distribution terms of the built app —
   the .exe/.dll carries our GPL-3.0-only; Direct2D/DirectWrite/
   User32/GDI32 are System Libraries under the GPLv3 §1 carve-out, the
   annex's sentence). The VS-2026 image facts ARE recorded in-tree
   (CONSENSUS's probe-findings ledger: windows-latest → VS Enterprise
   18.x, Rust 1.100.0, **SDK 10.0.26100.0**, vswhere present, cl
   off-PATH → the vcvars discovery guard) — at entry, i.e. before the
   green run, satisfying "at or before". The green run is recorded
   (SESSION_LOG: "Hygiene run GREEN on 8b3cb95 — ALL SEVEN JOBS") —
   **but the run ID 45957061389 is NOT in-tree** (repo-wide grep: zero
   hits), and a live terms re-read AT the green run is not separately
   recorded (the entry probes — both pages HTTP 200, learn.microsoft
   last-modified 2026-11-02 — were the same day, 2026-11-27, so the
   same-day currency held; the record does not say "re-read at green").
   Neither gap is a violation; both are advisories (6).

## Risks register

- **(a) The stated-license-as-fact class (carried) — the tripwire held
  this gate; keep holding.** The all-ours + platform-only surface
  survived verifiably (condition 1's sweep), but there is still no
  PERMANENT include-sweep guard in CI; the invariant is re-proved only
  when a reviewer re-proves it.
- **(b) The first-conveyance trigger, re-stated for the Windows
  artifact (carried, NOW WITH TWO ROWS).** The .dll embeds the
  Apache-2.0-derived MCU palette (core/src/palette.rs;
  THIRD-PARTY-NOTICES is its in-tree attribution) and the .exe embeds
  the MSVC CRT object code (the /MT default — condition 3's finding).
  The FIRST conveyed Windows artifact — ANY .exe/.dll share: a GitHub
  artifact, a zip, a winget listing — triggers Apache-2.0 §4.1 (the
  palette notice in the per-platform LICENSES manifest), the CRT row,
  and GPL §6 (the corresponding-source offer naming the exact crate
  versions). Until then nothing conveyable may be uploaded (condition
  7 — held).
- **(c) The no-network claim drift (carried, now mechanically guarded).**
  The import-table guard converted the claim from review-trust to
  fail-closed on BOTH binaries; the residual drift is the guard's own
  bypass (removing the guard step + adding a network import in the same
  commit) — the drift rule in the entry report names the same-commit
  note-change duty.
- **(d) The two-MD3-statements discipline (carried).** The palette
  NOTICES entry covers the .dll-consuming .exe now (entry advisory 3);
  no logos; keep the entry with any theme evolution.
- **(e) The mingw recurrence (carried).** The rejection is enforced
  mechanically; a future "build from Linux" push meets the host-triple
  guard + the recorded reasoning (entry report + gate record).
- **(f) The toolchain-terms drift (carried).** Microsoft's pages are
  live-updated; the analysis is recorded against 2026-11-27 text — the
  standing re-read duty applies at the next live windows build / any
  VS-2026 image drift.
- **(g) Accidental conveyance (carried).** Zero uploads held; the
  outputs stay runner-local behind the .gitignore blob rules.
- **(h) The expected-text provenance (carried, moot for N4).** N4
  committed NO new expected text — the Linux artifact is reused; the
  class question only re-opens if Windows ever pins its own bytes.
- **(i) NEW — the un-pinned CRT default.** The linkage rides cl's
  default rather than a named flag: a future toolchain change to the
  default (or an IDE-templated build) silently flips /MD↔/MT and with
  it the first-conveyance row set (risk (b)); pin the flag at the next
  touch of the build line (advisory 3).

## Advisories

1. Add the include-sweep guard as a one-line CI step over
   `apps/windows` (the `#include\s*"` allow-list: SDK/CRT/std +
   `clearfile.h` only) — the same comment-vs-assertion class as the
   entry's advisory 7; the sweep currently lives only in reports.
2. RECORD the adversarial-reports class in D14's un-headed set (50
   tracked reports since 2026-11-14, all un-headed — precedent without
   a recorded rule); or SPDX-stamp them going forward.
3. Pin the CRT flag on the cl line (/MT explicitly + the LICENSES row,
   or /MD + no row) — close risk (i); the choice is currently
   default-inherited.
4. Copy the import-guard drift rule (network import ⇒ the in-app note
   changes in the SAME commit) into the workflow comment beside the
   guard, where the enforcement lives.
5. Put the 0.1.0 version string in-tree where the ledger says it lives
   ("the source + the record" — currently record-only) — one constant
   in main.cpp or a build comment.
6. Record CI run IDs with the green-run entries (the N4 green run
   45957061389 on 8b3cb95 is in-tree by SHA only); note the terms
   re-read state when a live run triggers it.
7. THIRD-PARTY-NOTICES rows NOW (carried from the entry, still cheap):
   (i) the MSVC/Windows-SDK + CRT-choice record (condition 3's finding
   is the text to land), (ii) the kotlin-stdlib row (see (c) below),
   (iii) the still-open cbindgen/Android build-stack rows from N3.

**The kotlin-stdlib notice posture (item (c), re-stated):** the rider's
first-live-run finding (round 2) is recorded correctly in all three
places — the workflow comment ("The ONE recorded runtime external
artifact: the kotlin-stdlib (Apache-2.0, via :shared's KMP build —
pinned exactly; anything else external fails"), the SESSION_LOG, and
the commit's LEGAL-posture note. The posture: Apache-2.0 → the NOTICE
duty (license copy + attribution) rides the per-platform LICENSES
manifest at the ANDROID APK's first conveyance — the carried manifest
trigger, same family as the palette row; nothing due now (nothing
conveys). THIRD-PARTY-NOTICES.md itself has no kotlin-stdlib row —
advisory 7(ii) is its natural home; cheap now, due at conveyance.

## Files read + verification log

**Records:** my entry report `2026-11-27-n4-legal.md` (full — the 8
conditions + risks (a)–(h)); the N4 delta `git diff 2a3acd1..9e6cf46`
+ `--stat` (14 files, +2314/−9; the 6 backup commits 5c4efa2→9e6cf46);
`CONSENSUS.md` l.1795–1885 (the N4 gate record: the probe findings
incl. the VS-2026 image facts + "(6) the /MD-vs-/MT CRT choice
recorded", the 12-point ledger incl. ledger (8)'s variant
preconditions + the 0.1.0 plane form; the EIGHTH slip surfacing; the
ENTERED outcome); `SESSION_LOG.md` l.2427–2492 (N4 sessions 1 + 2: the
guarded header, the app, the five-round honest record, the green run
on 8b3cb95, the named non-verification); `ROLES.md` (the ADV-LEGAL
mandate, read at entry); `DEBT.md` D14 + the N2-exit amendment (the
recorded un-headed classes); the N3-exit verdict line (the format
precedent).

**In-tree (at tip 9e6cf46):** `apps/windows/main.cpp` (SPDX l.1; the
include set l.33–47; the honesty strings l.313–336, l.445–454, l.529;
RAII OwnedBuffer; zero engine logic); `.github/workflows/hygiene.yml`
(the windows-app job: the rustc + host-triple guards, the cdylib + .lib
assertions, the battery on Windows, the vswhere→vcvars MSVC build + the
import guard on BOTH binaries with the load-bearing `exit /b 0`, the
EOL-normalized smoke against the Linux expected text, zero uploads; the
rider's gradle assertions in the android job with the kotlin-stdlib
pin); `core-ffi/clearfile.h` (the config-emitted `extern "C"` guards +
the retained cbindgen banner); `core-ffi/cbindgen.toml` (the
after_includes/trailer emission); `README.md` (the apps/windows row:
the interim statement + "unreleased"); `.gitignore` (the MSVC residue
rules, scoped under apps/windows/); `scripts/harness_check.sh` (the
epilogue-count + N4 family updates); `THIRD-PARTY-NOTICES.md` (NOT
touched by the delta — posture unchanged).

**Live probes (read-only, 2026-11-27):** `git log -1` → tip
**9e6cf46**; `git status --short` → clean at start (the entry reports
are committed); `git tag --list` → exactly v1.0.0, v1.0.1, v1.1;
`git ls-files apps/windows` → main.cpp ONLY (zero binary assets);
includes sweep (l.33–47 enumerated above) + `vcpkg|nuget|gitmodules` →
zero; `rg -c "upload-artifact" .github/workflows/` → release.yml **6**
only; `45957061389` repo-wide → ZERO hits (the run-ID gap, condition
8); the CRT sweep over the workflow/reports → no /MD or /MT flag on the
cl line (the rides-the-default finding, condition 3); SPDX counts:
main.cpp **1**, clearfile.h **1**, cbindgen.toml **4**,
hygiene.yml/README/.gitignore **0** (pre-existing posture, edits
preserved). Digests truncated: main.cpp 6510e9…, hygiene.yml 2eb1f2…,
clearfile.h 187f10…, README 46f7bf… (the diff-index prefixes).

**Working-tree discipline:** read-only probes only; this report is the
sole new file OF THIS LANE. Final state (the other untracked files are
the parallel exit reviewers' own reports — four isolated lanes, one
tree; not touched by this lane):

```
$ git status --short
?? harness/adversarial/reports/2026-11-27-n4exit-legal.md
?? harness/adversarial/reports/2026-11-27-n4exit-product.md
?? harness/adversarial/reports/2026-11-27-n4exit-security.md
```
