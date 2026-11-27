# ADV-ENG — N4 exit gate (2026-11-27, Task N4-EXIT-ENG)

Scope: the ENG lane of the N4 EXIT gate — the delta `2a3acd1..9e6cf46`
(seven commits, tip 9e6cf46, tree clean at start; the four entry reports
now committed inside the delta). I re-read my entry report
(2026-11-27-n4-engineering.md — the 8 conditions incl. the extern-C
probe finding), CONSENSUS's "The N4 delta-scoped gate" section (the
four 8-condition verdicts + the consolidated 12-point ledger), the two
N4 SESSION_LOG entries (session 1 + session 2 CLOSED — the five-round
CI record), and ROLES.md; then re-probed the load-bearing claims LIVE
under /tmp/n4exit-eng (removed at close; df 1.6 GB free at start and
close; the pinned tools/rust/bin cargo 1.100.0; the sandbox cc/g++
14.2). The green CI run of record: **45957061389** (the orchestrator's
numbering — the repo-side record anchors it as "Hygiene run GREEN on
8b3cb95, ALL SEVEN JOBS"; the numeric ID lands in THIS exit record per
my entry condition 6's letter).

**VERDICT: N4 EXIT — PASS (8/8 entry conditions discharged, every
probe live-green; two new residual debt items registered,
non-blocking; the window mode remains the named non-verification)**

## Conditions

1. **The extern-"C" header guards — DISCHARGED (probe-verified live
   at the committed header).** cbindgen.toml's `after_includes` +
   `trailer` emit the guard pair (the ruled config-emitted fix, the
   LEGAL-3 precedent — never a hand edit); the regenerated committed
   clearfile.h carries `#ifdef __cplusplus / extern "C" { / #endif`
   at lines 12–14 and the matching close at 104–106, wrapping ONLY
   the declarations (the four system includes stay outside — the
   clean shape). Verified in the exact ruled matrix: a 6-line TU with
   the relative-path include compiled CLEAN both ways
   (`cc -std=c99 -Wall -Wextra -c` and `g++ -std=c++17 -Wall -Wextra
   -c`, zero warnings), and `nm` on the C++ object shows the
   references UNMANGLED — `U clearfile_compute`, `U clearfile_free`,
   `U clearfile_last_error`, identical to the C object (no Itanium
   `_Z` forms): the entry gate's silent link trap is closed for every
   future C++ consumer, at the header itself. The regeneration is
   deterministic: `cargo build --locked` in core-ffi →
   `git diff --exit-code -- core-ffi/clearfile.h` CLEAN. The app
   includes the header BARE (main.cpp line 47 — the ruled primary,
   not the `extern "C" { #include }` fallback). The CI freshness step
   (android job) and harness_check's N4 family (guards ≥ 2) re-prove
   it every run; harness_check green on the recorded run.
2. **The MSVC link shape — DISCHARGED (proven live, all green).** The
   windows-app job asserts the .dll AND the MSVC import library
   `clearfile_core_ffi.dll.lib` fail-closed BEFORE the link
   (hygiene.yml 443–444); the compile is `cl /utf-8 /EHsc /std:c++17
   /W4 /I core-ffi … /link …clearfile_core_ffi.dll.lib user32 gdi32
   comdlg32 d2d1 dwrite` — /utf-8 landed (the em-dashes in the source
   and the summary survive); the host-triple guard asserts
   `x86_64-pc-windows-msvc` fail-closed (the mingw rejection
   enforced mechanically); vswhere→vcvars64 discovery (no hardcoded
   VS path); the .dll copied beside the .exe before the smoke. The
   one deviation from the letter: /W4 without /WX (no
   warnings-as-errors) — within the ruled shape (the gate never ruled
   /WX), advisory-registered below.
3. **The byte-exact headless smoke — DISCHARGED, with the EOL
   evolution honestly kept.** The app sets `_setmode(_fileno(stdout),
   _O_BINARY)` before its raw fwrite (main.cpp 585); the smoke runs
   under `shell: bash` with real `diff -u`; after the autocrlf root
   cause (round 5), BOTH sides are EOL-normalized (`tr -d '\r'`)
   before the byte-exact content diff — the canonical text family
   stays the assertion, EOL-independent. DEVIATION from my entry
   letter (a separate committed apps/windows/tests/expected-headless
   twin): the implemented shape diffs the Linux app's committed
   expected text directly — ONE canonical text family, two platforms
   — achieved by running the same relative fixture path so the
   `File:` line is byte-identical. This is STRONGER for drift (any
   wording drift on either platform reds that platform's smoke;
   cross-platform parity is mechanically enforced; R-ENG-19's
   per-platform-text mitigation superseded by the stronger single
   contract) and is ruled in the consolidated CONSENSUS ledger +
   recorded in SESSION_LOG/README/main.cpp. Discharged with the
   deviation recorded as an improvement, not a gap.
4. **The one-pipeline + zero-engine-logic boundary — DISCHARGED
   (main.cpp read in full, 591 lines).** The ONE pipeline:
   read_file (CreateFileW → GetFileSizeEx → the 512 MiB pre-read
   bound BEFORE ReadFile, refusing with the core's named message
   verbatim, em-dash bytes included) → the composed
   `clearfile_load_and_compute` → the display model. ZERO
   ZIP-signature dispatch platform-side (none exists in main.cpp);
   the JSON scanner is extract-only display glue (find_member /
   get_string / get_number / get_string_array / get_object — no
   validation, no re-derivation, no growth beyond text_summary's
   fields); the text_summary is the byte-exact port, proven by the
   green smoke; wmain (wide argv — the lossless path), CreateFileW/
   ReadFile, GetOpenFileNameW with a double-null-terminated filter;
   the window title/labels carry the honesty set; exit codes 2/1/0
   mirror the Linux app.
5. **The CI windows job shape — DISCHARGED (all seven jobs green on
   run 45957061389 / commit 8b3cb95).** Guards-first (rustc ≥ 1.95
   parse + the host-triple assertion), cargo --locked everywhere,
   the boundary battery ON WINDOWS, the MSVC build + the PE
   import-table network guard in ONE cmd step (dumpbin /DEPENDENTS
   fail on ws2_32/wininet/winhttp/urlmon for BOTH the exe and the
   .dll — the no-network claim's mechanical proof), the
   EOL-normalized headless smoke, permissions contents:read,
   timeout 45, SHA-pinned actions (no new uses), NO uploads. The
   five-round record is HONESTLY kept — every round self-reported in
   the commit messages + SESSION_LOG: the DrawTextW brush bug (mine),
   the over-strict rider assertion, the findstr errorlevel +
   `project :app` classpath quirks, the half-right one-sided EOL
   diagnosis, then the autocrlf root cause. No silent round; no
   round papered over.
6. **SEC's riding item — DISCHARGED BY THE RULED SUPERSESSION (the
   recorded branch of my condition).** The gradle dependencyLocking
   lockfile lane was superseded per the gate's accepted shape
   (CONSENSUS records it): the fail-closed CI classpath assertions
   (kotlin-stdlib 2.4.21 pinned as the ONE recorded runtime external
   artifact; the test classpath exactly junit 4.13.2 +
   hamcrest-core 1.3; exact-pinned plugins; FAIL_ON_PROJECT_REPOS) +
   the re-proving green android run in the same green run of record.
   The over-strict first assertion honestly caught and fixed in
   round 2 (the KMP-built :shared classpath reality). SEC's lane owns
   the disposition's detail; the re-proving run is the green record.
7. **The guard joins + the variant preconditions — DISCHARGED.**
   .gitignore gains the MSVC residue rules scoped under
   /apps/windows/ (x64/, Debug/, Release/, build/, *.obj/*.pdb/
   *.dll/*.exe/*.lib) — landed in the session-1 commit, BEFORE any
   CI build could produce residue (builds go to the ignored
   apps/windows/build/); the backup scan-path list already covers
   `apps` (sandbox_backup.sh line 132) so apps/windows inherits the
   ≥32-hex coverage — verified; harness_check.sh gains the N4
   scaffold family (main.cpp presence + the header's extern-C guards
   ≥ 2) and the funding-count update 3→2 (N5–N6) + the CONSENSUS
   outcome count 5→6 — checker-consistent with ROADMAP/CONSENSUS
   (the green harness-check job proves it). Variant preconditions:
   zero `clearfile/` + `src/` paths in the delta (the file list:
   apps/windows is the only new root); release.yml untouched;
   core/Cargo.{toml,lock} + core-ffi Cargo.toml/Cargo.lock
   byte-unchanged (digests identical to the entry report's
   c7120a7d…423f / 34e0b4bc…d1ba, re-verified before AND after
   every cargo run this session); nothing shipped, uploaded, or
   tagged.
8. **The two-session box — DISCHARGED (two sessions exactly).**
   Session 1 = 5c4efa2 (the guarded header + main.cpp + the guard
   joins); session 2 = f874371…9e6cf46 (the CI lane + the five
   rounds + the records). The window mode is the NAMED
   non-verification — recorded in SESSION_LOG, CONSENSUS, README,
   and the main.cpp header comment (the hosted runner has no
   interactive desktop; the headless mode is the verifiable surface,
   proven green). The red-close rule was never needed (green inside
   the box, exactly as the round budget sized it); the slip rule
   never triggered. The headless-first checkpoint's LETTER was
   superseded by the one-TU single-commit shape (the whole app
   landed session 1) — the PURPOSE held: the parity-verifiable
   headless artifact landed in session 1 and survived (registered as
   R-ENG-25 below, honest bookkeeping, no action).

## Risks register

- R-ENG-16 (the blind C++ lane) — DISCHARGED: the lane went red
  exactly as budgeted (five rounds, all self-reported), green on
  round 5; the box held.
- R-ENG-17 (the MSVC discovery shape) — DISCHARGED: vswhere→vcvars
  worked from the first round; the rounds were app bugs + cmd
  semantics + EOL, never the discovery chain.
- R-ENG-18 (the byte-parity traps) — DISCHARGED with the carried
  residual R-ENG-23: the CRLF trap detonated as predicted (twice),
  both root causes honestly diagnosed, the smoke now
  EOL-normalized-both-sides.
- R-ENG-19 (the wording-family duplication) — DISCHARGED STRONGER:
  the single canonical text family means cross-platform drift reds
  BOTH smokes (supersedes the per-platform-text mitigation).
- R-ENG-20 (the D2D window lane) — STANDS, accepted-class: the
  window mode compiles in CI, never renders; the named
  non-verification, honestly recorded everywhere. The optional
  bounded window-smoke was NOT attempted (advisory was non-binding;
  still the cheap upgrade, still never bet-the-box).
- R-ENG-21 (runner-image drift) — stands, low: the guards fail
  closed; no action.
- R-ENG-22 (probe footprint) — discharged: this session's scratch
  removed; both lockfiles byte-identical after every run; df 1.6 GB
  at start and close; the tree clean except this report.
- R-ENG-23 (NEW, low, accepted-class): the EOL normalization's
  tolerance — `tr -d '\r'` on both sides strips ANY carriage return
  from the content before the diff, so a spurious in-line CR would
  no longer be caught. The canonical text family stays the
  assertion and the root cause (the runner's checkout-side
  autocrlf) is recorded; the hardening path is .gitattributes
  (`apps/linux/tests/expected-headless.txt text eol=lf`) which
  would kill the checkout conversion and let the smoke return to
  the strict byte diff. Registered for the N5 lane's consideration.
- R-ENG-24 (NEW, low, accepted-class): the cmd-step pattern —
  findstr's no-match (the good case) leaves errorlevel 1 and echo
  does not reset it; the explicit `exit /b 0` is load-bearing and is
  honestly commented in the step. Every FUTURE cmd step inherits
  this trap class; the pattern (plus the `2>NUL` mkdir tolerance)
  should be copy-carried with the comment, never re-derived.
- R-ENG-25 (NEW, low): the one-TU app shape makes the headless smoke
  hostage to the window code compiling (the session-2 DrawTextW
  round red the WHOLE lane including the headless smoke, since one
  main.cpp carries both modes). The purpose of the headless-first
  checkpoint held (the artifact landed session 1); if the lane ever
  grows, a TU split (window.cpp / headless.cpp) restores the
  checkpoint's isolation. No action for N4's scope.

## Advisories (non-binding)

- The per-OS order stands: N5 (the Swift+AppKit macOS app) next;
  ROADMAP's funding posture is checker-aligned (2 FUNDED: N5–N6) and
  the green harness-check run proves the bookkeeping. The header's
  __cplusplus guards are C-no-ops (the C99 compile re-proven today),
  so N5's SPM C-interop consumes the same guarded header unchanged.
- N5's lane should pre-check the runner's `core.autocrlf` (macOS
  images default to `input` — usually no checkout-side conversion)
  OR adopt the .gitattributes eol=lf hardening from R-ENG-23 and
  drop the normalization; either way, decide BEFORE the first red.
- The green run number 45957061389 is recorded HERE (the exit
  record) per condition 6's letter; the repo-side record anchors the
  same run by commit (8b3cb95). Consider adding the numeric run ID
  to SESSION_LOG at the next bookkeeping commit (one line,
  non-blocking).
- The optional refusal smoke (a 512 MiB+1 sparse file → --headless →
  nonzero exit + the verbatim INPUT_TOO_LARGE_MESSAGE) remains
  unimplemented — still the cheapest pin on the wording
  duplication; worth one attempt if an N5 round touches the smoke
  machinery anyway.
- The import-lib detail stands as ruled: no `__declspec(dllimport)`
  (the cbindgen C form) — indirect calls, irrelevant at demo scale;
  the fail-closed .dll.lib guard catches any cargo emission change.
- /W4 without /WX landed (within the ruled shape): warnings are
  non-fatal in the C++ build. If a future round wants the strict
  form, /WX is a one-flag, one-round change — not worth reopening
  this gate.

## Files read + verification log

Files read (this session): harness/adversarial/reports/
2026-11-27-n4-engineering.md (all — my entry report, the 8
conditions + the extern-C probe finding),
harness/adversarial/CONSENSUS.md 1783–1887 (the N4 delta-scoped
gate: the four verdicts, the probe-findings ledger, the consolidated
12-point condition ledger, the ENTERED outcome),
harness/memory/SESSION_LOG.md 2427–2493 (the N4 session-1 +
session-2-CLOSED entries: the five-round record, the box, the
non-verification, the N5 handoff), harness/adversarial/ROLES.md
(all), core-ffi/clearfile.h (all 106 — the guards at 12–14/104–106),
core-ffi/cbindgen.toml (all — after_includes/trailer), apps/windows/
main.cpp (all 591 — the pipeline, the scanner, the RAII wrapper, the
borrowed-error copy-out, the pre-check, the window, wmain),
.github/workflows/hygiene.yml (the windows-app job 397–486 in full;
the android freshness/battery/rider sections 323–396; the top shape
1–46), the N4 git delta for .gitignore + scripts/harness_check.sh +
README.md + core-ffi/clearfile.h (git diff 2a3acd1..9e6cf46),
scripts/sandbox_backup.sh (line 132 — the apps scan-path coverage),
harness/memory/ROADMAP.md (the N4/N5 rows + the funding posture), and
the seven N4 commit messages (git log 2a3acd1..9e6cf46 — the
five-round record's raw form).

Runs (this session, tip 9e6cf46, the pinned tools/rust/bin cargo;
scratch /tmp/n4exit-eng, removed at close):

1. df first: 1.6 GB free (83%); cc + g++ at /usr/bin (g++ 14.2 — the
   probe compilers); lockfile digests recorded BEFORE any cargo run:
   core-ffi/Cargo.lock c7120a7d…423f, core/Cargo.lock 34e0b4bc…d1ba
   (identical to the entry report's).
2. **THE EXTERN-C DUAL-COMPILE PROBE (live):** a 6-line TU
   (`#include "../../home/z/my-project/core-ffi/clearfile.h"` — the
   relative-path include — + main calling clearfile_compute /
   clearfile_free / clearfile_last_error) compiled CLEAN both ways:
   `cc -std=c99 -Wall -Wextra -c` OK and `g++ -std=c++17 -x c++
   -Wall -Wextra -c` OK (zero warnings); `nm` on the C object →
   U clearfile_compute / U clearfile_free / U clearfile_last_error;
   `nm` on the C++ object → the IDENTICAL UNMANGLED symbols (no _Z
   mangled forms) — the guards work at the committed header, both
   dialects valid.
3. **The regeneration determinism (live):** `cargo build --locked` in
   core-ffi (Finished dev, 0.20 s) → `git diff --exit-code --
   core-ffi/clearfile.h` CLEAN — the committed header, guards
   included, == the regeneration.
4. **The boundary battery re-run LIVE:**
   `cargo test --locked --manifest-path core-ffi/Cargo.toml
   --features panic-hook-test` → **10 passed; 0 failed** (7.32 s;
   the golden fixtures + the corpus + both cap batteries through the
   boundary).
5. Post-run invariants: both lock digests byte-identical after every
   cargo run (c7120a7d…423f / 34e0b4bc…d1ba); `git status --short`
   EMPTY before this report; df 1.6 GB (83%); /tmp/n4exit-eng
   removed.
6. The run-number cross-check: `rg 45957061389` over the repo tree →
   no match (the repo anchors the green run by commit 8b3cb95; the
   numeric ID is carried by THIS exit record — advisory above).

At report close: `git status --short` →

```
?? harness/adversarial/reports/2026-11-27-n4exit-engineering.md
?? harness/adversarial/reports/2026-11-27-n4exit-legal.md
?? harness/adversarial/reports/2026-11-27-n4exit-product.md
?? harness/adversarial/reports/2026-11-27-n4exit-security.md
```

(the three sibling N4-exit lane reports are the parallel-lane
reality, none read per the isolation rule; the first line is this
report — the only tree change this lane made).
