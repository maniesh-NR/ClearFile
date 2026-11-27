# ADV-SEC — N4 exit gate (2026-11-27, Task N4-EXIT-SEC)

Reviewer: ADV-SEC (secrets/CI-CD/supply chain/untrusted-input surfaces + guard
joins; per ROLES.md). The N4 exit under review, ruled adversarially: the N4
delta `2a3acd1..9e6cf46` — the config-emitted extern-"C" guards
(core-ffi/cbindgen.toml + the regenerated clearfile.h), the NEW
apps/windows/main.cpp (the first C++ consumer), the .gitignore MSVC rules,
the hygiene.yml windows-app job (additive) + the android job's
rider-discharge step, the README row, the harness_check N4 family, the
memory records. Read first, as instructed: CONSENSUS's "The N4 delta-scoped
gate" section (the 12-point ledger, the gate outcome: N4 ENTERED 4 ×
PROCEED-WITH-CONDITIONS), my own entry report
(`2026-11-27-n4-security.md`, all — the 8 conditions ruled below are
MINE, probed one by one at this exit), SESSION_LOG's N4 entries (session 1:
the guarded header + the app + the guard joins; session 2 CLOSED: the
five-round honest CI record ending in the FIRST LIVE-GREEN run 45957061389
on 8b3cb95, ALL SEVEN JOBS). The sibling exit reports were neither read
nor written (isolation rule).

All eight of my entry conditions DISCHARGED — every one with a mechanical
check behind it, none on trust alone. The lane's first live-green run
(45957061389 on 8b3cb95, all seven jobs including the windows lane
end-to-end and the android job with the rider's assertions) is the
re-proving run condition 5 demanded. What rides to N5's gate: three
non-blocking hardening notes (the import guard's dumpbin-ran-itself
assumption, the classpath pattern's pipe-line blind spot, the MSVC-side
drift-naming posture) — registered below, none a condition.

**VERDICT: EXIT-PASS — all 8 entry conditions discharged, 0 BLOCK, 0 riders carried as conditions (3 hardening advisories ride to N5's gate as notes)**

## Conditions

1. **No new actions; the SHA-pinned set covers the windows job —
   DISCHARGED.** The windows-app job's only `uses:` is the existing
   checkout pin `11d5960a…77262` (v4.4.0, re-verified live at my entry
   gate); the rider step adds no `uses:` at all. `rg -n 'uses:' .github/
   workflows/hygiene.yml` → 12 lines, ALL from the pre-existing pinned set
   (checkout ×6, gitleaks `ff98106e…70c7`, flutter-action
   `1a449444…d0b2`, setup-node `49933ea5…2002`, cargo-deny
   `81891abc…74fda` ×2) — the delta introduced ZERO new actions, zero
   unresolvable refs, no msvc-dev-cmd/vcpkg/setup-* toolchain actions (the
   image ships the toolchain; the job discovers it itself, condition 2).
   Checkable: the rg above — the windows job's pins ⊆ the existing set.
2. **Fail-closed identity guards FIRST — DISCHARGED in substance, one
   posture note rides.** The job's first step after checkout is the rustc
   series guard (>= 1.95, unparsable→FAIL) PLUS the host-triple assertion
   (`rustc -vV` host == `x86_64-pc-windows-msvc`) — the mingw rejection
   enforced mechanically at the ABI level. The MSVC side landed as the
   self-locating vswhere→vcvars64 discovery (`-requires
   Microsoft.VisualStudio.Component.VC.Tools.x86.x64`) — the hardcoded
   2022-path trap (my entry finding: the alias remapped to the VS-2026
   `…\18\Enterprise` layout) is closed BY CONSTRUCTION, and every failure
   mode is fail-closed (vswhere missing → VSPATH unset → vcvars call fails
   → cl not found → errorlevel 9009 → `if errorlevel 1 exit /b 1`). The
   explicit cl-family/SDK series-guard echos did NOT land — a red-on-
   toolchain-roll naming for the MSVC family is absent (the rustc/host-
   triple guards carry it for the Rust side). RIDES as a note, not a
   condition: the ABI proof is version-independent (the boundary battery
   on the same cdylib + the C++ link against the same .dll.lib + the -W4
   compile, all on the same runner) — a VS roll that breaks anything reds
   the build; a VS roll that changes nothing observable is not a security
   property. Checkable: the guard step is the job's first step; the
   vswhere line never names a versioned VS path.
3. **RAII consumption of the two return classes — DISCHARGED.**
   `apps/windows/main.cpp` l.59–67: `OwnedBuffer` — explicit ctor, dtor
   calls `clearfile_free(p)`, copy ctor + assignment DELETED (the
   double-free and the raw-copy classes die at compile time);
   `clearfile_free` appears exactly once as CODE (l.62, the deleter; the
   other two hits are comments) — no libc `free`, no `delete[]`, no
   CoTaskMemFree anywhere on a clearfile pointer. The borrowed
   `clearfile_last_error` is copied out IMMEDIATELY (l.71–74: `const
   char *borrowed` → `std::string` return, no deleter path by type, never
   cached), consumed at l.400 right after the failed payload call and
   before any further clearfile call; the single-threaded posture is
   documented in-source (l.50–54) — the message loop and the headless path
   never race the thread-local. Checkable: `rg -n 'clearfile_free|
   free\(|delete' apps/windows/main.cpp`.
4. **The 512 MiB bound at the file-open path — DISCHARGED.** `read_file`
   (l.362–393): `CreateFileW` → `GetFileSizeEx` → the `512ull * 1024 *
   1024` check BEFORE `bytes.resize`/`ReadFile` (refused by metadata
   alone, pre-read), with the core's named message family ("The file is
   too large to open — the limit is 512 MiB.", the \xE2\x80\x94 em-dash —
   the same wording family). The `GetOpenFileNameW` path
   (`open_dialog`, l.466–488: `OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST`
   — no OFN_ENABLEHOOK hook procedure, no OFN_ALLOWMULTISELECT, single
   fixed MAX_PATH buffer) routes through the SAME `load_and_compute` →
   `read_file` (l.478); the argv paths route through it too (wmain l.565+).
   The core-ffi boundary's own pre-parse rejection stays the second wall.
   Checkable: the size-query precedes the read; the refusal greps in
   `apps/windows` in the Linux app's wording family.
5. **SEC's N3 rider — the dependencyLocking supersession discharge —
   DISCHARGED, re-proven.** The android job's new step
   (hygiene.yml l.359–386, `gradle --no-daemon` twice): the RUNTIME
   classpath fails on any `[+\]--- ` tree line that is not `:shared` or
   the ONE recorded artifact `org.jetbrains.kotlin:kotlin-stdlib:2.4.21`
   (pinned exactly — the first live run's honest finding: it rides via
   :shared's KMP build); the TEST classpath asserts junit 4.13.2 present
   AND fails on any tree line beyond {app, shared, junit 4.13.2,
   hamcrest-core 1.3, kotlin-stdlib 2.4.21} — junit/hamcrest stay
   test-scope-only (LEGAL's EPL-1.0 invariant intact). The supersession
   ruling is recorded in CONSENSUS (the entry ledger's finding 5), and the
   FIRST LIVE-GREEN android run after the step landed is run 45957061389
   on 8b3cb95 (all seven jobs) — the re-proving run the rider's own
   disposition required. Residual (register item 3 below): the
   `^[[:space:]]*[+\\]---` pattern does not match `|`-prefixed
   continuation lines (transitives under a non-last top-level root) —
   the round-2/3 iterations closed the `+---` and project-root gaps; the
   pipe gap is unreachable today (see the register) but hardens cheap.
   Checkable: the step is fail-closed on a non-empty residue file; the
   run number recorded here.
6. **Guard joins BEFORE the first build state, same-commit — DISCHARGED.**
   The .gitignore MSVC rules landed in 5c4efa2 (N4 session 1, "the guard
   joins (.gitignore MSVC rules before any build + the harness_check N4
   family)"), which PRECEDES f874371 (session 2, the CI lane and the
   first build) — guard-before-build by commit order. The rules are all
   scoped under `/apps/windows/` (x64/, Debug/, Release/, build/, *.obj,
   *.pdb, *.dll, *.exe, *.lib) — the tracked `clearfile/windows/` Flutter
   template cannot be shadowed (verified: every added rule carries the
   /apps/windows/ prefix; no bare `*.dll`/`*.exe`). The blob policy holds:
   `git ls-files | rg '\.(dll|exe|obj|lib|pdb)$'` → 0 at the tip; the
   built .dll/.exe exist only on the runner, never committed. The
   harness_check N4 family (main.cpp presence + ≥2 header extern-C
   guards) landed in the same delta. Checkable: the commit order; the
   ls-files count = 0; `harness_check.sh` runs green.
7. **The bundled-fixture discipline — DISCHARGED.** The smoke consumes
   the SHARED committed fixture directly
   (`fixtures/migration/v1-web-envelope.json` — the same family the
   Linux smoke asserts against); `git ls-files apps/windows` → exactly
   `apps/windows/main.cpp` — no fixture copy, no newly-authored content,
   nothing to drift. Checkable: the two commands above.
8. **The variant preconditions over the base 2a3acd1 — ALL HOLD.**
   Probed live over `git diff 2a3acd1..9e6cf46`: (a) `-- clearfile src`
   → 0 paths; (b) `-- .github/workflows/release.yml core/Cargo.toml
   core/Cargo.lock core-ffi/Cargo.toml core-ffi/Cargo.lock` → 0 lines —
   release.yml byte-unchanged, core byte-unchanged (the zero-dep
   assertion intact), core-ffi's version plane unmoved, and the
   core-ffi header/cbindgen.toml changes are exactly the entry gate's
   ruled fix (finding 1: the config-emitted extern-"C" guard — the
   "byte-unchanged absent a recorded ruling" precondition holds WITH the
   ruling on record in CONSENSUS); (c) NOTHING shipped or uploaded — no
   upload-artifact step anywhere in the delta (every "upload" rg hit is
   the standing "NO uploads" comment; the only `secrets.` ref is the
   pre-existing gitleaks GITHUB_TOKEN at l.35, outside the delta), no
   `git tag --contains 2a3acd1` (0 tags over the N4 commits); (d) no
   version movement on any plane — no Cargo.toml touched at all;
   apps/windows has no crate (the version lives in the source + the
   record, per the entry ledger). Checkable: the four git commands above.

**The header-guard fix's honesty (the entry gate's own probe finding,
verified at exit):** the guard is CONFIG-EMITTED, not hand-added —
cbindgen.toml's `after_includes` opens `#ifdef __cplusplus / extern "C" { /
#endif` right after the "Do not edit" line, `trailer` closes it, and the
committed clearfile.h carries EXACTLY that emitted form (diff-verified:
the guard open follows the autogenerated line; the trailer closes the
file). The ubuntu-side freshness check (hygiene.yml l.323: "the committed
clearfile.h == the regeneration") ran green in 45957061389 — the
mechanical proof the committed header is the regeneration, so a hand edit
could not have survived; a future regeneration cannot lose the guard. The
C99-consumer side is unaffected (the `#ifdef` is inert pre C++) and was
probe-verified at the entry gate both ways; the boundary battery running
ON WINDOWS in the same green run re-proves the C seam.

## Risks register

1. **The import-table guard's real coverage — a denylist with a
   dumpbin-ran-itself assumption.** The guard (one cmd step):
   `dumpbin /DEPENDENTS` on the .exe AND the .dll, `findstr /i "ws2_32
   wininet winhttp urlmon"` with `&& exit /b 1` — a denylist of the four
   network-DLL families, not my advisory's exact-allowlist import set.
   Two edges: (a) if `dumpbin` itself failed to run while `cl` succeeded
   (both ship in the same vcvars PATH unit — effectively unreachable, and
   a red `cl` never reaches the guard), the pipe's findstr matches
   nothing and the step's trailing `exit /b 0` would FALSE-PASS the
   guard; (b) the denylist covers the classic socket/HTTP families
   (ws2_32/wininet/winhttp/urlmon), not e.g. DNSAPI/IPHLPAPI — moot while
   the code calls no network API at all (the exe's full import set is
   user32/gdi32/comdlg32/d2d1/dwrite + the CRT + the cdylib, by
   construction and -W4-clean compile). LOW: the lane's own compile
   provenance is the stronger fact; hardening is one line (advisory 1).
2. **The classpath pattern's pipe-line blind spot.** The rider step's
   `^[[:space:]]*[+\\]--- ` regex matches top-level and space-indented
   tree lines but NOT `|`-prefixed continuation lines (transitives
   under a non-last top-level root). Unreachable in the current shape:
   the runtime classpath has a single root (`project :shared`, always
   `\---` at column 0) so every runtime tree line IS matched; the test
   tree's roots are the excluded first-party/pinned set, and the pinned
   versions' transitive trees are deterministic (junit 4.13.2 →
   hamcrest-core 1.3 only; kotlin-stdlib 2.4.21 → no runtime transitives)
   — any NEW declared external surfaces at a matched line and reds the
   build. Residual: a future pinned-version bump changing a transitive
   under a non-last root could ride a pipe line undetected. Register:
   harden at the first classpath change (advisory 2).
3. **The MSVC-side drift-naming posture (condition 2's ride).** A
   windows-latest toolchain roll (VS/SDK) that keeps the lane green does
   not announce itself — no red-on-roll for the MSVC family (rustc's
   series guard reds only downward drift; the host-triple guard pins the
   ABI family). The ABI properties are proven per-run regardless; the
   gap is observability, not enforcement.
4. **The cmd errorlevel handling — verified sound, and the gotcha is now
   load-bearing.** `cl …` → `if errorlevel 1 exit /b 1`;
   `dumpbin | findstr … && exit /b 1` per binary; the findstr
   no-match (the GOOD case) leaves errorlevel 1 and `echo` does not
   reset it — the explicit trailing `exit /b 0` (the round-3 lesson,
   recorded in-source as a `rem`) is present and load-bearing. Both
   directions fail closed. The bash steps quote every expansion
   (`"$LINE"`, `"$MAJOR"`, `"$HOST"`, `"$RUNTIME"`, `"$TESTCP"`); no
   `${{ }}` interpolation anywhere in the new steps (no PR-controlled
   script-injection surface); `mkdir … 2>NUL` precedes the errorlevel
   check so its errorlevel is overwritten by `cl`.
5. **The EOL-normalized smoke — content-exactness preserved.** The
   round-4/5 root cause (runner-side autocrlf on the EXPECTED file + the
   MSVC CRT's text-mode translation on the output) is handled by
   normalizing BOTH sides (`tr -d '\r'`) before the `diff -u` — the
   canonical text family stays the assertion, EOL-independent, and the
   diff still reds on any content byte. The named non-verification
   stands honestly everywhere (README row, SESSION_LOG, in-source
   l.417–419): no interactive desktop run — the window path is only
   COMPILE-verified on the lane (the DrawTextW round proved even that
   much catches bugs); the headless mode is the verified surface.
6. **No new untrusted-input surface.** main.cpp: the file path comes from
   argv (Unicode wmain) or GetOpenFileNameW (FILEMUSTEXIST, fixed
   MAX_PATH) → `CreateFileW` directly (no ShellExecute, no command
   spawning, no LoadLibrary of untrusted paths, no registry); the content
   flows only into the boundary (catch_unwind + the core's own bounds)
   and the display glue scans the core's own payload. Zero external
   dependencies (user32/gdi32/comdlg32/d2d1/dwrite only — the import
   guard's subject). The CI: no network in any new step, no secrets, no
   uploads; job-level `permissions: contents: read` +
   `timeout-minutes: 45` present on the windows job.

## Advisories (non-binding)

1. **Harden the import guard's self-verification (one line):** before the
   findstr denylist, assert the dumpbin output actually rendered — e.g.
   `dumpbin /DEPENDENTS … | findstr /c:"Image has the following
   dependencies" || exit /b 1` — so a failed dumpbin can never
   false-pass the guard; and consider asserting the exact allowlist
   import set (my entry advisory, still open) over the denylist.
2. **Harden the classpath pattern at its next touch:** extend to
   `^[|[:space:]]*[+\\]---` (or assert the exact sorted external set
   outright) — closes the pipe-line blind spot for the version-bump
   drift mode (register 2).
3. **The MSVC drift-naming note (register 3):** a one-line `cl 2>&1 |
   findstr /c:"Version"` echo in the build step (or asserting the VC
   tools family from vswhere's `-property catalog_productDisplayVersion`)
   restores red-on-roll observability for the MSVC family at zero cost.

## Files read + verification log

- Read first, as instructed: `harness/adversarial/CONSENSUS.md`
  l.1783–1886 (the "The N4 delta-scoped gate" section: the four verdicts
  (4 × PWC), the 8 probe findings, the 12-point ledger, the N4 ENTERED
  outcome); my own entry report
  `harness/adversarial/reports/2026-11-27-n4-security.md` (all 319 — the
  8 conditions this exit probes); `harness/memory/SESSION_LOG.md`
  l.2427–2492 (N4 sessions 1 + 2 CLOSED: the five-round honest record —
  the DrawTextW bug, the over-strict rider assertion, the cmd errorlevel
  gotcha, the one-sided EOL diagnosis, the autocrlf root cause — ending in
  the FIRST LIVE-GREEN run on 8b3cb95, all seven jobs; the entry report
  cites the run number 45957061389 from the push record).
- The N4 delta `git diff 2a3acd1..9e6cf46` (all 2,314 insertions across
  14 files; the non-harness delta: hygiene.yml +117, .gitignore +13,
  main.cpp +591, cbindgen.toml/clearfile.h +15/+7, harness_check.sh
  ±25/9) — read in full over: `.gitignore` (the scoped MSVC rules +
  the guard-order comment), `core-ffi/cbindgen.toml` +
  `core-ffi/clearfile.h` (the config-emitted guard open/close — the
  committed form matches the config's emitted text exactly),
  `.github/workflows/hygiene.yml` (the rider step + the entire
  windows-app job), `README.md` (the apps/windows row), `scripts/
  harness_check.sh` (the funding/outcome checker updates + the N4
  scaffold family).
- `apps/windows/main.cpp` (l.1–94, 341–490, 520–592 read; rg probes over
  the whole file) — the OwnedBuffer RAII type, the last_error copy-out,
  the ONE shared pipeline with GetFileSizeEx before the read + the 512
  MiB named refusal, the open_dialog routing, the argv modes, the
  in-source honesty set + the single-threaded note.
- Probes (2026-11-27, read-only, no cargo, no packages, nothing modified
  outside this report): `git diff --name-only 2a3acd1..9e6cf46 --
  clearfile src` → 0; `git diff 2a3acd1..9e6cf46 -- .github/workflows/
  release.yml core/Cargo.toml core/Cargo.lock core-ffi/Cargo.toml
  core-ffi/Cargo.lock` → 0 lines; `rg 'upload|secrets\.|artifact'
  .github/workflows/hygiene.yml` → all 11 hits are comments or the
  pre-existing gitleaks GITHUB_TOKEN (l.35, outside the delta) — no
  upload step, no new secrets; `git ls-files | rg '\.(dll|exe|obj|lib|
  pdb)$'` → 0; `git tag --contains 2a3acd1` → 0; `rg -n 'uses:'
  .github/workflows/hygiene.yml` → 12, all the pre-existing pinned set;
  `git log --oneline -- .gitignore` → the N4 rules landed in 5c4efa2
  (session 1), before the first build state (f874371, session 2);
  `rg -c clearfile_free apps/windows/main.cpp` → 3 (one code + two
  comments); `git ls-files apps/windows` → exactly main.cpp; `git
  status --porcelain` before this report → clean.
- Could NOT verify from this sandbox: the interactive window mode (no
  desktop anywhere — the named non-verification, honestly recorded); the
  raw Actions run logs of 45957061389 (its green-all-seven status is the
  SESSION_LOG/commit-record claim — the sandbox's read-only git/rg
  posture excludes the API; the record's five-round shape + the tip
  commit's "ALL SEVEN JOBS" summary are the evidence, consistent with the
  landed workflow YAML verified here line-by-line). No cargo run (ENG
  lane owns cargo probes).
- Repo state at the exit: `git rev-parse HEAD` = 9e6cf46 (the tip under
  review); the tree clean before this report; the sibling exit reports
  (engineering/legal/product) neither read nor written.

`git status --short` after filing (run live, verbatim):

```
?? harness/adversarial/reports/2026-11-27-n4exit-product.md
?? harness/adversarial/reports/2026-11-27-n4exit-security.md
```

Only the second line is mine (`…n4exit-security.md`, this report — the
only file this lane created or modified). The sibling `…n4exit-product.md`
line is the product lane's own filing, landed concurrently while I worked —
NOT read, per the isolation rule; the tree is otherwise clean (no
tracked-file changes, no drift).
