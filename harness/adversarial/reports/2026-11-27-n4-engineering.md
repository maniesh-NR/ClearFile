# ADV-ENG — N4 delta-scoped gate (2026-11-27, Task N4-GATE-ENG)

Scope: the ENG lane of N4 (the Windows native UI delta gate — the first
C++ consumption of the committed flat-C header). Pushed tip 2a3acd1
verified at close; the tree clean at start except the three sibling N4
lane reports (n4-legal, n4-product, n4-security — the parallel-lane
reality; none read, per the isolation rule). The proposal under review:
apps/windows (a C++17 Win32+Direct2D app: argv dispatch, the 512 MiB
pre-check, clearfile_load_and_compute, the text_summary-family summary,
Direct2D/DirectWrite window or headless stdout, the palette FFI →
D2D_COLOR_F, GetOpenFileNameW, the bundled fixture, the honesty
strings); the CI windows-latest lane (guards → the .dll build → the
boundary battery on Windows → the C++ compile → the headless-smoke
diff; the named non-verification: no interactive desktop run); the
local mingw lane REJECTED; the two-session box; per ADR-017's FFI-seam
row ("Win32+Direct2D C++ consumes the header"). Everything I could
probe was probed live under /tmp/n4-eng (df measured first: 1.6 GB
free; the pinned tools/rust/bin cargo 1.100.0; the sandbox's g++ 14.2
as the C++ probe compiler); both lockfiles re-verified byte-identical
after every cargo run; the repo tree untouched except this report.

**THE KEY FINDING (probe-verified): the committed core-ffi/clearfile.h
carries NO `extern "C"` guards for C++ consumers — a bare C++17 include
COMPILES CLEAN but LINK-FAILS against the flat C ABI.** The trap is
silent at compile time; it detonates at the CI link step on a
blind-authored app. The fix is one cbindgen config delta (the LEGAL-3
config-emitted precedent), probe-verified end to end below. This is a
condition, not a BLOCK: the fix is one-line-class, well-understood, and
probe-carried.

**VERDICT: PROCEED-WITH-CONDITIONS**

## Conditions

1. **The extern-C header fix, config-emitted, once for every future
   C++ consumer (the probe's key finding):** the committed header
   (99 lines, `Language::C` pinned — the C99 dialect, `#include
   <stdbool.h>` form) has no `#ifdef __cplusplus` wrapping; a 20-line
   C++17 TU with the bare include compiled clean under
   `g++ -std=c++17 -Wall -Wextra` (zero warnings — the trap is silent),
   then `nm` on the object showed the references as C++-mangled
   signatures (`clearfile_load_and_compute(char const*, unsigned long)`
   …), and the link against a flat-C mock FAILED (undefined reference
   ×4 — the exact CI-first-run red the blind app would hit). The fix —
   NEVER hand-editing the "Do not edit" header (a hand-add dies on the
   next regeneration; the CI freshness check enforces it): core-ffi/
   cbindgen.toml's `after_includes` gains the guard open after the
   banner (`#ifdef __cplusplus` / `extern "C" {` / `#endif`) and a
   `trailer` gains the matching close — wrapping ONLY the declarations,
   the four system includes staying outside (the clean shape). Probe-
   verified on a simulated copy: a bare C++17 include of the guarded
   header compiled+linked+ran against the same mock, AND the guarded
   header stayed valid C99 (`gcc -std=c99 -Wall -Wextra` clean — the
   guards are preprocessor no-ops in C, so N5's SPM C-interop and N6
   are unaffected). The header delta lands in session 1, same-commit
   with the config change; the regeneration stays deterministic
   (the freshness check + the boundary battery re-prove it).
   Verification: `grep -n __cplusplus core-ffi/clearfile.h` shows the
   pair; `git diff --exit-code -- core-ffi/clearfile.h` clean after a
   rebuild; the CI windows C++ compile green with a BARE include. The
   app-side `extern "C" { #include "clearfile.h" }` wrap (probe-verified
   working on g++ — but it transitively wraps the standard headers
   included inside the header — the known antipattern) is the recorded
   FALLBACK only, for the recorded reason.
2. **The MSVC link shape (the import-lib ruling):** the windows-msvc
   cdylib build emits `clearfile_core_ffi.dll` PLUS the import library
   `clearfile_core_ffi.dll.lib` beside it in target/release/ (cargo's
   documented msvc emission — the gate records the expectation, the CI
   proves it; the LOCAL cross-check is impossible, honestly attempted
   and recorded below). MSVC's link.exe CANNOT link a .dll directly
   (a GNU-ld-only feature) → the CI carries a fail-closed guard
   asserting the .dll.lib exists BEFORE cl runs; the compile is
   `cl /nologo /utf-8 /EHsc /std:c++17 /W4 <sources> /link
   clearfile_core_ffi.dll.lib`, with `/utf-8` MANDATORY (the source
   and the expected text carry UTF-8 em-dashes — without it MSVC
   decodes the source at the system codepage and the honesty strings
   and summary go mojibake); the .dll is copied beside the .exe BEFORE
   the smoke (the loader's search path); the host-triple guard asserts
   `rustc -vV`'s host is x86_64-pc-windows-msvc, fail-closed on a gnu
   host (a different ABI lane than ruled). Delay-load is rejected as
   needless complexity with no consumer (recorded). N4's own mingw
   rejection: ACCEPTED — the recorded reasoning is sound (a second
   ABI/toolchain surface with no consumer; the g++ probe already
   carried the one locally-verifiable fact, the header's C++
   consumability and linkage mechanics; the MSVC-specific surface is
   CI-owned).
3. **The byte-exact headless smoke (the LF/UTF-8/console trap —
   probe-fact-carried):** the app's headless path sets stdout to
   BINARY mode (`_setmode(_fileno(stdout), _O_BINARY)` from
   <io.h>/<fcntl.h>) so `\n` never becomes `\r\n` in the redirected
   capture; the smoke step runs under `shell: bash` (the windows image
   ships Git 2.56.1 — bash available; pwsh's `>` RE-ENCODES stdout and
   its `diff` is Compare-Object — not byte-exact) and byte-diffs the
   FULL stdout with real `diff -u` (or `git diff --no-index
   --exit-code`) against the committed apps/windows/tests/
   expected-headless.txt — a SEPARATE committed file (the linux
   precedent apps/linux/tests/expected-headless.txt verified live:
   UTF-8, LF-only, the em-dash as bytes 342 200 224 in line 1; the
   windows twin differs in the `File:` path line — path separators,
   the fixture path — the WORDING FAMILY is the cross-platform parity,
   recorded as such, never claimed byte-identical-across-OS). The
   expected text is authored ONCE from the family wording and NEVER
   regenerated from the app's output (a regenerated text defeats the
   drift-catching property — the fixture-authoring discipline's
   display-text cousin). The headless path writes raw bytes
   (fwrite/printf of the FFI's UTF-8 strings) — never the wide-char
   console APIs.
4. **The one-pipeline + zero-engine-logic boundary (ADR-017's row):**
   every C++ path (the window render, --headless, any app-side test)
   calls the ONE `clearfile_load_and_compute` pipeline fn; NO
   ZIP-signature dispatch platform-side (it lives inside the committed
   contract — the header's own doc); the 512 MiB pre-check via
   GetFileSizeEx (or std::filesystem::file_size) BEFORE the read,
   refusing with the core's INPUT_TOO_LARGE_MESSAGE verbatim ("The
   file is too large to open — the limit is 512 MiB." — the wording
   duplicated C++-side, honestly recorded as the flat-ABI's known
   cost, the em-dash tying to condition 2's /utf-8); the summary text
   is a PORT of apps/linux's text_summary family — the C++ side
   extracts fields from the returned JSON with a minimal read-only
   reader (presentation marshalling only: extract-only, never
   re-validating, never re-deriving a number — the "zero engine logic
   platform-side" row rides on this; the duplication's drift risk is
   pinned by the committed expected text, condition 3); argv via
   wmain + GetCommandLineW (never ANSI main — non-ASCII paths and the
   `File:` line parity), file reads via the wide path
   (CreateFileW/ReadFile or std::ifstream with std::filesystem::path).
5. **The CI windows job (guards-first, the android-app pattern,
   additive to hygiene.yml):** runs-on windows-latest — verified live
   today = the Windows Server 2025 image WITH Visual Studio 2026
   (labels windows-2025/windows-2025-vs2026): Rust 1.100.0 + Rustup
   1.29.3 preinstalled (the pinned version — no toolchain install
   needed), Windows SDK 10.0.26100.0 (exactly one), VSWhere 3.1.7,
   Git 2.56.1, MSYS2 at C:\msys64 (off PATH), VS2026 including the
   VC.Llvm.Clang 18.12 components. Step order: (i) the fail-closed
   rustc guard (the existing pattern) + the host-triple assertion;
   (ii) the MSVC discovery guard — vswhere (the stable preinstalled
   path) resolving the VS install with the VC tools component, then
   sourcing vcvarsall.bat x64 in-step (cl is NOT on the default PATH —
   the developer-prompt reality; never a hardcoded VS path, it drifts;
   clang-cl exists as a VS COMPONENT, not a PATH binary — the recorded
   fallback, not the primary); (iii) the Windows SDK discovery guard,
   fail-closed on absence (discovery-based rather than pinned-version
   guards — the series-tolerance lesson applied to a runner-OWNED
   toolchain that rolls); (iv) the committed-header freshness check
   (the android job's step: build --locked + git diff --exit-code);
   (v) the boundary battery ON WINDOWS: `cargo test --locked
   --manifest-path core-ffi/Cargo.toml --features panic-hook-test`
   (my audit: ZERO `#[cfg(unix)]` anywhere in core/src, core-ffi/src,
   core-ffi/tests, apps/linux/src — the only non-test cfgs are the
   feature gates and the jni shim's `target_os = "android"`, a no-op
   on Windows; my local re-run 10/10 green, the all-std battery is
   portable); (vi) `cargo build --locked --release` (the .dll +
   .dll.lib); (vii) the C++ compile (condition 2); (viii) the
   headless smoke diff (condition 3); (ix) cargo-deny over core-ffi's
   lock — the same manifest the android job already denies (keep for
   lane self-containment or skip with the recorded reason — either
   recorded). Permissions contents:read, timeout ~45, SHA-pinned
   actions only (no new uses: beyond checkout/deny), no uploads. The
   first run is EXPECTED red (R-ENG-16/17) — the fix rounds are
   session 2's work.
6. **SEC's riding item ruled (the gradle dependencyLocking, the
   disposition this gate owes):** the LOCKED lane: apps/android gains
   `dependencyLocking { lockAllConfigurations() }`; the lockfiles
   (gradle/dependency-locking/*.lockfile) generated CI-SIDE by a
   one-shot `--write-locks` run, then committed as the session's
   artifact (generated, never hand-authored — the fixture-authoring
   discipline family); the android job then builds with the lockfiles
   present (gradle fail-closes on a missing/stale lock — the posture
   needs no new guard); the first live-green android run after the
   join re-proves the lane (the run number recorded). The recorded
   supersession fallback ONLY if AGP's own configurations resist the
   blanket lock (the known AGP wrinkle class): the scoped locklist
   over :app's resolvable configurations, or the honest supersession
   ruling naming the resistance — either way the disposition + the
   re-proving run number land in the N4 exit record. This lands in
   session 2 (it rides the CI session's hygiene.yml/gradle work).
7. **The guard joins + the variant preconditions:** .gitignore gains
   the apps/windows build-output rules (the build/ fixture-copy +
   object/exe residue — the N3 same-commit precedent) BEFORE any
   in-repo build state can exist; the backup ≥32-hex scan-path list
   joins apps/windows (the sandbox_backup.sh family, the N3 precedent)
   in the same commit; the bundled fixture is PULLED from the shared
   fixtures/ family (never newly authored — mirroring the linux
   smoke's fixtures/migration/v1-web-envelope.json is the closest
   parity story, the 4-warning migration path; record which); zero
   `clearfile/` + `src/` paths in the N4 delta (apps/windows is the
   only new root — the Flutter app's clearfile/windows/ untouched);
   release.yml byte-unchanged; core/Cargo.toml + core/Cargo.lock
   byte-unchanged (the hygiene exactly-1-package assertion intact;
   core-ffi's own lock unchanged too — the header config delta does
   not touch dependencies); no version movement (apps/windows carries
   no Cargo plane at all — the C++ app is a non-cargo artifact);
   nothing shipped, uploaded, or tagged.
8. **The two-session box (the sizing ruling + the checkpoint order):**
   session 1 = the header config fix + the app (argv dispatch, the
   headless pipeline, the pre-check, the expected text, the honesty
   strings, the D2D/DW window shell) — blind-authored at the demo
   standard, with the INTRA-SESSION CHECKPOINT: the headless lane +
   the fixed header + the committed expected text land FIRST and are
   self-reviewed BEFORE the Direct2D window work (a session death
   still leaves the parity-verifiable artifact — the N3
   3493203→f496ee4 precedent); session 2 = the CI windows lane + the
   CI-fix rounds + condition 6's disposition + the records/README/
   STATE. The honest sizing given the N3 eleven-round precedent: the
   C++ blind lane's first CI run should be BUDGETED red (compile +
   link + discovery + encoding traps all at once) — session 2 absorbs
   the rounds (the box is NOT sized for a first-run green fantasy).
   The slip rule stands (logged honestly, never silently extended; an
   extension needs a recorded owner ruling); the red-close rule stands
   (a session may close with the CI lane RED and the run numbers +
   statuses honestly recorded); the disk re-measured at each session
   start (1.6 GB at this gate, 1.4 GB at close — the probe footprint
   note below; the app session is CI-primary regardless — no MSVC
   exists in-sandbox, verified).

## Risks register

- R-ENG-16 (the blind C++ lane, medium-high): hundreds of lines of
  never-compiled-anywhere C++ (Win32 + D2D/DW + the console traps)
  hitting the MSVC compiler cold — expect multiple red rounds; the
  N3 eleven-round precedent is the floor of expectation, not the
  ceiling. Mitigations: the headless-first checkpoint (condition 8),
  the probe-carried facts (the extern-C matrix, the import-lib + /utf-8
  + binary-stdout shapes), session 2's fix-round budget, red-close.
- R-ENG-17 (the MSVC discovery shape, medium): the vswhere → vcvars
  → cl environment chain is unverified until the first run (my readme
  fetch is today's snapshot; the image updates weekly). Mitigations:
  discovery-based fail-closed guards with diagnostic listings (the
  NDK-guard pattern), the clang-cl fallback recorded, never a
  hardcoded VS path.
- R-ENG-18 (the byte-parity traps, medium): CRLF translation
  (text-mode stdout), pwsh's re-encoding `>` and Compare-Object `diff`,
  the console codepage — any one silently reds the smoke or tempts a
  tolerance that defeats the byte-parity point. Mitigations:
  condition 3 (binary-mode stdout + `shell: bash` + real diff).
- R-ENG-19 (the wording-family duplication, low-medium): the C++
  text_summary is the SECOND implementation of the family (the
  flat-ABI payload boundary's known cost); cross-platform drift is
  caught only by each platform's own committed expected text.
  Mitigations: the never-regenerate discipline (condition 3), the
  family-wording self-review at the session-1 checkpoint.
- R-ENG-20 (the D2D window lane, low-medium, accepted-class): the
  window code compiles in CI but never renders anywhere (the
  proposal's named non-verification — the N3 no-emulator family).
  The optional bounded window-smoke attempt is the cheap upgrade
  (advisory below); never bet the box on it.
- R-ENG-21 (runner-image drift, low): today's facts (VS2026, SDK
  10.0.26100.0, Rust 1.100.0, Git 2.56.1) are a 2026-11-27 snapshot
  (the R-ENG-6 family); the guards fail closed on drift.
- R-ENG-22 (probe footprint, discharged): /tmp/n4-eng (the probe
  matrix + the two fetched readmes + the check log) deleted at report
  close; the repo-side footprint: the honest msvc cross-check attempt
  rebuilt host-side build-deps into core-ffi/target/debug (gitignored,
  re-buildable class) and its 84 KB partial cross-target dir was
  removed; df 1.6 → 1.4 GB across the session; both locks
  byte-identical after every run.

## Advisories (non-binding)

- The per-OS order stands: N4 → N5 → N6 (macOS last). The header's
  new __cplusplus guards are no-ops for C consumers — the fix is
  once-for-all at the config level; no engineering demand to re-order.
- The optional bounded window-smoke (`--smoke`: construct the window,
  one Present, destroy, print a marker, exit 0) is worth ONE attempt
  in session 2's fix rounds — hosted windows runners host GUI
  processes (the Selenium-class precedent); demote honestly to the
  named non-verification if D2D1CreateFactory fails, with the error
  recorded.
- The optional refusal smoke: a python-truncated sparse 512 MiB+1
  file → `--headless` → assert nonzero exit + the verbatim
  INPUT_TOO_LARGE_MESSAGE — the cheap pin on the wording duplication
  (the 2×-STORE-cap rationale family).
- The engine-logic boundary: keep the C++ JSON field extraction
  visibly read-only and non-validating (extract the fields text_summary
  needs; never re-derive a value); a growing reader is the first step
  to a second engine.
- The console-subsystem shape: ONE exe doing both --headless and the
  window (console subsystem + CreateWindowExW; wmain auto-selects
  wmainCRTStartup) is the demo-standard shape — the headless lane
  needs the console subsystem (WINDOWS detaches stdout).
- The import-lib detail: the header's declarations carry no
  `__declspec(dllimport)` (the cbindgen C form) — linking via the
  import lib still resolves (indirect calls, irrelevant at demo
  scale); if a future cargo ever stops emitting the .dll.lib, the
  fail-closed guard catches it.
- The app include path: `-I ..\..\core-ffi` (or the relative include)
  from apps/windows — record the chosen form; the freshness check
  keeps the header authoritative either way.
- The expected-text authoring: diff both texts side-by-side at the
  session-1 self-review (the linux twin vs the windows twin) — the
  family parity is a review-time fact, the byte-parity a per-platform
  CI fact.

## Files read + verification log

Files read: harness/adversarial/reports/2026-11-27-n3-engineering.md
(all — the 7 conditions + the topology/runner probes),
harness/adversarial/reports/2026-11-27-n3exit-engineering.md (all —
the 7/7 discharge + the live-run lanes), CONSENSUS.md (1490–1782 — the
N3 delta gate ledger, the exit record, SEC's riding item, the N4
pre-positioning), STATE.md (363–390 — "Immediately next", the seven
agenda items), DECISIONS.md (495–574 — ADR-017, the FFI-seam row + the
verification/licensing annexes), core-ffi/clearfile.h (all 99 — the
committed contract, the no-__cplusplus finding), core-ffi/cbindgen.toml
(all — the config-fix landing site, the LEGAL-3 header/after_includes
precedent), apps/linux/src/main.rs (the argv dispatch, the
load_and_compute shape, the text_summary/result_groups family survey),
apps/linux/tests/expected-headless.txt (all — the UTF-8/LF facts),
.github/workflows/hygiene.yml (all — the linux-app headless-smoke
precedent + the android-app guard pattern), fixtures/ (the migration
+ tax listings), harness/adversarial/ROLES.md (all — the ADV-ENG
charter), the actions/runner-images main README + the
Windows2025-VS2026 readme (fetched live, 35,090 B).

Runs (this session, tip 2a3acd1, the pinned tools/rust/bin toolchain;
scratch /tmp/n4-eng, deleted at close):

1. df first: 1.6 GB free (84%); cargo 1.100.0; g++ 14.2 (the probe
   compiler — the sandbox has no MSVC and no mingw, re-confirming the
   CI-primary posture).
2. **THE C++ CONSUMPTION PROBE (the extern-C matrix):** (i) the bare
   `#include "clearfile.h"` TU compiled CLEAN under
   `g++ -std=c++17 -Wall -Wextra`; (ii) `nm -C` showed the references
   as C++-mangled signatures (Itanium `_Z…` family, demangled
   `clearfile_load_and_compute(char const*, unsigned long)` etc.);
   (iii) the link against a flat-C mock FAILED — "undefined reference
   to `clearfile_load_and_compute(char const*, unsigned long)'" ×4,
   ld exit 1 — the ungated header gives C++ consumers C++ linkage;
   (iv) the app-side `extern "C" { #include "clearfile.h" }` wrap
   compiled+linked+ran (printed mock-load-and-compute|mock-last-error|1)
   — works, with the standard-headers-inside-the-wrap antipattern
   noted; (v) the GUARDED copy (after_includes/trailer shape: guard
   open immediately after the banner line, close at the end — only
   the declarations wrapped) included BARE by a C++17 TU
   compiled+linked+ran against the same mock; (vi) the guarded copy
   stayed valid C99 (`gcc -std=c99 -Wall -Wextra` clean); (vii) the
   wrapped variant also passed -fsyntax-only (both shapes legal
   C++; the config fix is the ruled primary, condition 1).
3. The boundary battery re-run LIVE: `cargo test --locked --features
   panic-hook-test` in core-ffi → **10/10 green** (7.42 s; the 17
   golden fixtures + the 550-case corpus through the boundary, the
   512 MiB pair's ~1 GiB transient included); `rg '#\[cfg\('` over
   core/src, core-ffi/src, core-ffi/tests, apps/linux/src → ZERO
   `#[cfg(unix)]` (only test/feature gates + the android jni shim) —
   the battery is Windows-portable; the CI owns the proof.
4. The honest cross-check attempt: `cargo check --target
   x86_64-pc-windows-msvc` → **E0463 "can't find crate for `std`"**
   ("the `x86_64-pc-windows-msvc` target may not be installed …
   consider downloading the target with `rustup target add`"; exit
   101; the sysroot's rustlib holds only x86_64-unknown-linux-gnu —
   the standalone toolchain, no rustup, measured at N3) — the LOCAL
   cross-check is IMPOSSIBLE, recorded; the CI lane owns it. The 84 KB
   partial cross-target dir removed after.
5. The runner facts (fetched live 2026-11-27): windows-latest = the
   Windows Server 2025 + VS2026 image (windows-2025 /
   windows-2025-vs2026 labels); Rust 1.100.0 + Rustup 1.29.3
   (the pinned version, preinstalled); Windows SDK 10.0.26100.0
   (one); VSWhere 3.1.7; Git 2.56.1 (bash for `shell: bash`); MSYS2
   at C:\msys64 (off PATH); the VS2026 install includes the
   VC.Llvm.Clang 18.12 components + the VC++ 14.52 runtimes.
6. The lockfile checks: core-ffi/Cargo.lock c7120a7d…423f and
   core/Cargo.lock 34e0b4bc…d1baa byte-identical before/after every
   cargo run (sha256, digests truncated per convention).
7. At report close: /tmp/n4-eng deleted; df `/ … 9.9G … 1.4G avail
   (86%)`; `git status --short` →

```
?? harness/adversarial/reports/2026-11-27-n4-legal.md
?? harness/adversarial/reports/2026-11-27-n4-product.md
?? harness/adversarial/reports/2026-11-27-n4-security.md
?? harness/adversarial/reports/2026-11-27-n4-engineering.md
```

(the three sibling N4 lane reports are the parallel-lane reality,
none read per the isolation rule; the fourth line is this report —
the only tree change this lane made).
