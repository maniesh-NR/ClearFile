# ADV-PROD — N5 exit gate (2026-11-27, Task N5-EXIT-PROD)

**Scope:** the N5 exit gate over the delta `ff127f2..9cfffa7` (3 commits —
`48d981d` the execution landing, `cdd25a1` the round-1 fix, `9cfffa7` the
round-2 fix; 8 paths, **+714**, zero deletions), ADV-PROD lane per ROLES.md
— roadmap rightness, stage ordering, overreach, platform priorities,
single-maintainer sustainability, records honesty, the demo-vs-misuse
tension. One of four parallel isolated reviewers (reports at
`harness/adversarial/reports/2026-11-27-n5exit-*.md`; none read by me).
Verified live at my own probes: the working tree CLEAN; the ONE-session box
held (all pushes same session, one box, no silent extension); the lane
LIVE-GREEN — **my own probe of run 45977202882 on 9cfffa7**: the run page
(11 success check-icons, ZERO failure markers) plus all EIGHT job pages
fetched, **every `data-conclusion="success"` on every step of every job**,
including the macOS job's full 14-step ladder (the rustc + host-triple
guard #3, **the identity echo #4**, the .dylib #5, the boundary battery ON
MACOS #6, the wrapper-header assertion #7, the zero-dep assertion #8, the
SPM build #9, the deployment-floor assertion #10, the headless smoke #11,
the otool -L link guard #12) — the LIVE-GREEN claim mechanically
corroborated by my own fetch, not taken on trust. The eight entry
conditions are discharge-verified in the log below — all residual items are
the ledger's own planned close set (ledger items 11/12: the README row +
the bookkeeping), none re-opens the box, none requires an app or lane
change. The MANDATORY slip restatement (the ELEVENTH surfacing — see the
count reconciliation below) + the N6 terminal-gate ruling are bound in.

VERDICT: **EXIT-PASS (4)** — all four conditions are record-side close
riders the exit close already owes per the gate ledger's own items 11/12
and my entry Condition 7; the execution itself is complete, live-green,
variant-clean, and honestly recorded. No app change, no lane change, no
BLOCK.

## Conditions (numbered, checkable — all discharge at the exit close)

1. **The README `apps/macos` row — land the ruled text at the close.**
   Measured: `grep -n "apps/macos" README.md` → ZERO matches; the apps
   table's rows end at `apps/windows` (line 27). This is exactly the
   ledger's item 11 ("the README row at close") — the row was always a
   close rider, never a box item. The EXACT ruled text (one table row,
   joining the line-24/25/27 row family — the honest scope, the
   unreleased/CI-only status, the Flutter-remains-shipped sentence, all
   FOUR named non-verifications, the green run number, the GA clause, the
   no-network + non-affiliation fact family):

   ```
   | `apps/macos/` | The **macOS native UI** (N5 of the ADR-017 epilogue, ENTERED 2026-11-27): a labeled Swift+AppKit viewer demo — the Swift consumer of the committed flat-C header via the `ClearFileFFI` SPM wrapper target (the umbrella header includes `core-ffi/clearfile.h` verbatim, nothing copied or re-declared; the CI asserts the include line). The argv modes mirror the Linux/Windows apps (`--headless <path>` / a bare path / the window), the ONE shared pipeline (the 512 MiB pre-read bound → the composed `clearfile_load_and_compute`), and the headless stdout is the byte-exact same text family as the Linux app (the CI smoke diffs it against the Linux app's committed expected text — one canonical text family, three platforms, EOL-normalized). The AppKit window renders the summary with the MD3-from-seed palette-FFI theme (the same corpus seed) + the full honesty set (the no-AI/no-network note — no network library is linked BY the app or the core, mechanically proven by the `otool -L` direct-linkage guard — and the IRS/Intuit non-affiliation line). Zero external dependencies (AppKit + Foundation only, both OS system libraries; the SPM zero-dep posture asserted fail-closed), zero engine logic. CI: the macOS-app job on `macos-latest` (the fail-closed rustc + host-triple `aarch64-apple-darwin` guards, the boundary battery ON MACOS, the SPM build, the deployment-floor assertion via the binary's `LC_BUILD_VERSION` minos 13, the headless smoke, the link guard) — hygiene run **45977202882** green on 9cfffa7, all eight jobs. The four named non-verifications: no interactive GUI run in CI (the window mode is authored, not desktop-verified — the headless mode is the verifiable surface); the macOS 13 deployment floor is a build-time target, never runtime-verified (macos-latest = macOS 26 arm64; the macos-13 CI image is retired); no x64-macOS verification; no owner-side build. A demonstration prototype, unreleased, CI-verified-only — the Flutter macOS app remains the shipped macOS product; any macOS GA owes an owner-side build or the recorded owner acceptance. |
   ```

   *Checkable:* the row exists with every named element; `rg -n
   "45977202882" README.md` finds the run citation in the row.

2. **The close records set — the run number + the execution record, in
   every owed slot.** Measured: `rg -n "45977202882|45976627388"`
   repo-wide over tracked `.md` files → ZERO matches — the green run is
   cited only in the round-3 commit message's context so far. The N4-exit
   rider convention (run number + commit, "run N GREEN on <sha>", never an
   unqualified "landed") binds the close: (a) ROADMAP's N5 bullet rewrite
   — ENTERED → **CLOSED (exit PASSED)** with the execution record: ONE
   session exactly (the owner's standing single-session directive), the
   3-round honest CI-fix record (round 1: SwiftPM's tools-version line-1
   rule; round 2: Result's failure-type Error conformance; round 3: green —
   the datums now N3=11, N4=5, **N5=3**), **run 45977202882 GREEN on
   9cfffa7, all eight jobs**, the four named non-verifications, the GA
   clause, and the exact linkage lists now available from the green run's
   log (the ledger item-5 note: "the full output stays visible in the run
   log for the exit gate's exact-list tightening" — the exe: AppKit,
   Foundation, CoreGraphics, libobjc, libSystem, the OS Swift runtime at
   /usr/lib/swift/; the cdylib: exactly libSystem); (b) SESSION_LOG's N5
   session entry (the honest 3-round record + the pre-flight audit defect
   (the `try?` on `write(contentsOf:)`, fixed pre-push) + the run
   citation); (c) CONSENSUS's N5 exit record (the consolidated verdicts +
   the TWELFTH-surfacing handoff with the terminal-gate note); (d) STATE's
   refresh (header + the N5 bullet gate-status + "Immediately next" → the
   N6 gate agenda — the current STATE still carries the N5-execution
   agenda, stale the moment the close lands). *Checkable:* `rg -n
   "45977202882"` finds ROADMAP + SESSION_LOG + CONSENSUS + README
   citations after the close; no record cites the run on the close tip
   (the run-vs-tip discipline — the green is on 9cfffa7, records commits
   ride on top, the next lane-touching push re-proves).

3. **The checker's N-outcomes count 8 → 9 at the close.** Measured:
   `harness_check.sh` at the tip → **0 failures** (my own run), with the
   funding-posture counter already at FUNDED 1 (updated at ENTRY — the
   checker's own pass line records "N6; N1/N2/N3/N4 ENTERED+CLOSED (exit
   PASSED), N5 ENTERED 2026-11-27") and the epilogue N-outcome counter at
   **8** (`:79–85`, expected 8 = N1 ENTERED/CLOSED + N2 ENTERED + N3
   ENTERED/CLOSED + N4 ENTERED/CLOSED + N5 ENTERED — my own grep count
   over CONSENSUS confirms exactly 8). The close adds CONSENSUS's
   **N5: CLOSED (exit PASSED)** bold outcome → the 9th match → the
   checker's expected count must go 8 → 9 at `:81`/`:84` (the
   legitimate-advance precedent, one line + the comment; FUNDED stays 1 —
   N6 is the last funded stage). *Checkable:* `bash scripts/harness_check.sh`
   → 0 failures on the gate-close push; the checker's expected count
   matches ROADMAP's gate-status lines exactly.

4. **The TWELFTH surfacing rides with N6's gate — the epilogue's TERMINAL
   gate — and the N6 record must say exactly this, ruled now so it cannot
   be lost at the close.** The N6 gate record must state: (i) the pinned
   enumeration (… 10 the N5 entry, 11 the N5 exit — this gate, 12 N6's
   gate); (ii) the TERMINAL-GATE FACT — N6's gate is the LAST gate in the
   epilogue's funded scope, so the slip's disposition CANNOT ride past it
   unexamined; (iii) if still unruled there, the record states the
   POST-EPILOGUE PARKING POSTURE explicitly and in full: the Stage-2 exit
   stays SLIPPED, the MSI-record keystream chase stands as recorded debt
   **D42** (disposition "T3 session 2", append-only, D30 standing
   alongside), and the slip's re-agenda duty transfers to the first
   post-epilogue convened gate or owner conversation — **never a silent
   drop**; (iv) the three owner options restated (fund the T3 session /
   supersede the RE-protocol namespace rule / the default re-agenda)
   with the no-ruling count. *Checkable:* the N6 gate record carries all
   four elements verbatim-in-substance.

**The Stage-2 slip re-agenda — the MANDATORY item, the ELEVENTH
surfacing (by the pinned per-gate-event enumeration: 1 N1-exit, 2
N2-entry, 3 N2-exit-convening, 4 N2-exit-close, 5 the 2026-11-27
restatement, 6 the N3 entry, 7 the N3 exit, 8 the N4 entry, 9 the N4
exit, 10 the N5 entry — 11 THIS exit gate) — restated here in full.**
The Stage-2 exit gate has been SLIPPED since 2026-11-23 pending
`tax-modern.md` (spec 4 of 4), which is blocked on the T3 format-family
findings (the MSI-record keystream diverges at payload offset 0x24000 —
the decompile chase has not been funded). The three owner options,
verbatim-in-substance: (a) **fund a T3 session** (the MSI-record
keystream decompile chase at payload offset 0x24000 + `tax-modern.md`,
debt D42 — DEBT.md row D42, disposition "T3 session 2", stands
confirmed), (b) **supersede the RE-protocol namespace rule** that
requires the modern format's DoD spec (allow the Stage-2 exit without
spec 4), (c) **the default re-agenda** (the slip carries to the next
gate). **No ruling has been received across TEN prior surfacings; (c)
continues by default; the TWELFTH rides with N6's gate — the epilogue's
TERMINAL gate** (Condition 4's ruled text). **The count reconciliation,
recorded honestly (my lane):** the N5 entry record's forward pointer
said "the ELEVENTH rides with N6's gate" — the same one-off
forward-pointer undercount class the N4 entry made ("the next surfacing
rides with N5's gate") and the N4 exit resolved by taking its own number
(the NINTH) and re-pointing forward; this exit gate resolves it the same
way — exit gates take their own numbers per the pinned enumeration (the
N2 exit was even counted twice, convening + close), so THIS gate is the
ELEVENTH and N6's terminal gate carries the TWELFTH. The load-bearing
content — the terminal-gate note — is unaffected and rides with
Condition 4. The count stays pinned by enumeration so the ledger cannot
drift.

## The mandate findings (roadmap rightness — verified, not assumed)

- **Stage ordering: right, and now proven.** The per-OS order held exactly
  (N1 core → N2 Linux → N3 Android → N4 Windows → **N5 macOS** → N6
  web-WASM + the freeze); macOS last-native was the recorded plan because
  it is the only lane this Linux sandbox cannot build or verify
  (ADR-017's epilogue-sequence row) — and the risk priced in at entry
  (author-blind Swift, the first compile IS the CI run) materialized as
  exactly the predicted cost, honestly absorbed in 3 rounds (the N3=11 →
  N4=5 → N5=3 datum trend — the pre-flight audit + the N4-accumulated
  pitfall register (R-ENG-26..31) visibly paid off).
- **No missing stages, no overreach.** iOS stays dropped by recorded ADR
  decision (not silently); the KMP second target stays none; the delta is
  ONE app + ONE lane + 3 guard joins (+714) — nothing else moved, nothing
  shipped, no version movement, v2.0.0 untouched (the freeze declaration
  is N6's alone — verified: nothing in the delta declares it).
- **Platform priorities: the artifact serves the stated purpose.** The
  third byte-parity platform joins the ONE canonical text family — the
  Linux app's committed 1,766-byte expected text now proven
  byte-identical by three independent toolchains (Rust+Slint,
  C++/MSVC/D2D, Swift/AppKit) — the repo's strongest cross-platform
  parity statement, at one-lane cost.
- **Single-maintainer sustainability: the honest bound is COMPLETE for
  the demo bar.** The bar ruling (my entry Condition 2, formalized at the
  gate and verified in CONSENSUS's record): a macos-latest CI job alone
  satisfies the settlement's demo bar under the per-lane-status
  discipline (headless = the verifiable surface; every record carries run
  numbers + commits; the window mode's non-verification named) — with the
  identity echo (live-green step #4) killing the `-latest` float risk, the
  host-triple guard killing the ABI-drift risk, and the GA clause
  traveling WITH the trigger (any macOS GA owes an owner-side build or
  the recorded owner acceptance — the open offer, D30's family). What
  makes the lane a liability is only if the records drop the four named
  non-verifications or the GA clause — Conditions 1/2 are exactly that
  mitigation.
- **The demo-vs-misuse tension: bounded, and the bound is structural.**
  The strongest mitigation is that nothing ships (no uploads — verified
  zero `upload-artifact`; tags exactly v1.0.0/v1.0.1/v1.1 — verified; no
  release): no real user can obtain this binary. The artifact is
  read-only compute + display (it never writes a tax file, never
  e-files); the honesty set rides every surface — the headless footer,
  the window text, the source header comments, and (owed) the README
  row. "Useful enough to be misused" stays a non-issue while the
  non-shipment posture holds; the GA clause is the tripwire that
  re-opens the question deliberately, never silently.

## Risks register

- **The run-vs-tip gap (the standing N3/N4-registered class):** the green
  run 45977202882 is on 9cfffa7; the close adds records commits on top;
  the next lane-touching push re-proves. Bound by Condition 2's exact
  "GREEN on 9cfffa7" wording discipline.
- **The window mode stays authored-not-desktop-verified into N6** (the
  third lane carrying it); the palette colors remain value-unverified on
  macOS (the entry Advisory-1 headless theme dump was again not taken —
  the third consecutive advisory-not-taken, honestly recorded). The
  Android lane's JVM palette-seam tests + the 22,242-check palette corpus
  keep the FFI VALUES covered; the rendering stays the named
  non-verification. Honest as long as Condition 1's row text lands.
- **The otool guard's scope is direct-linkage-only** (Foundation
  transitively loads CFNetwork as an OS fact) — the job's wording is
  honest ("no network library linked BY the app/core"); the exact-list
  tightening is folded into Condition 2's record text (the linkage lists
  from the green run's log).
- **The `-latest` float:** the identity echo dates every future run; the
  fail-closed host-triple assertion turns an image flip into a visible
  guard failure, never a silent drift. Residual risk: low.
- **The enumeration-pointer reconciliation (the ELEVENTH/TWELFTH note
  above):** a one-line records-honesty erratum, ruled and recorded here;
  the N6 gate record states the count cleanly per Condition 4.
- **The push-count note:** the context's "5 pushes so far" — git log
  shows **4** commits in the N5 arc (ff127f2 the gate record, 48d981d
  the implementation, cdd25a1 + 9cfffa7 the round fixes), each its own
  push with its own honest record (the backup-after-each-stage discipline
  HELD); the 5th is the close push this verdict rides on (or the count
  included the prior session's same-morning close `2ddcce5`). Recorded
  for exactness — the mitigation's substance is fully satisfied.
- **The disk trend:** 6.7 GB available at filing (`df -h /` — the same
  level as my N5-entry probe; the CI-primary box cost the sandbox
  ~nothing; the per-session re-measure discipline continues, ENG's lane).

## Advisories (non-binding)

1. **The headless theme dump** (entry Advisory 1, the N4 precedent — not
   taken a third time): 2–3 `clearfile_palette_scheme_role` values in the
   headless output would CI-prove the macOS color VALUES at near-zero
   cost. Not owed; the named non-verification carries the honesty; N6
   may take the web analog.
2. **The x64-macOS and macos-15 (one-step-closer-to-floor) lanes** exist
   (the entry Advisory-2 facts) — the single-lane choice stays a
   deliberate bar ruling, not an oversight, and Condition 1's row text
   keeps the non-verifications visibly named.
3. **The window-smoke question** (the entry Advisory 3): not taken; the
   named non-verification stands; revisit only if a macOS GA is ever
   convened (the GA trigger).
4. **The per-platform LICENSES manifest is NOT owed at N5** (the
   ADR-017 licensing annex: it lands with each platform's first TAGGED
   release; AppKit/Foundation/CoreGraphics are proprietary system
   libraries under the GPLv3 §1 carve-out) — record note only, LEGAL's
   surface.
5. **The N6 handoff — pre-positioned intact (verified):** STATE's
   "Immediately next" (:408–412) + CONSENSUS's N5 entry record + ROADMAP's
   N6 bullet (FUNDED) all carry: the wasm32 target question
   (`wasm32-unknown-unknown` vs `wasm32-wasip1` — the core is
   pure/offline/std-only; N6's gate rules it), the TS engine's retirement
   per ADR-016, the parity suites' survival rule (as long as any old
   engine ships anywhere), the epilogue's OWN terminal freeze declaration
   per the v2.0.0-territory rule (N6's to declare, never an earlier
   stage's — verified nothing in this delta declares it), and the
   TWELFTH slip surfacing with the terminal-gate note (Condition 4).

## Files read + verification log

**Read:** my entry report whole (`2026-11-27-n5-product.md` — the 8
conditions); the N4-exit report whole (`2026-11-27-n4exit-product.md` —
the format + the precedent rulings: the run-number convention, the
exit-takes-its-own-surfacing-number pattern, the README-row rider
class); CONSENSUS.md 1938–2089 (the N5 entry record: the 13-point ledger
incl. items 11/12 — the README row at close, the checker families; the
wrapper-header ruling with both probe findings; the macos-latest
three-probe list; the TENTH surfacing with the terminal-gate note);
ROADMAP.md 700–743 (the N4 CLOSED record; the N5 ENTERED bullet WITH the
Condition-3 floor amendment — "confirmable BUILD-TIME-ONLY … the live
probe 2026-11-27: macos-latest = macOS 26 arm64; the macos-13 image is
retired, macos-14 retired 2026-11-02, the oldest available family is
macOS 15"; the ONE-session box note; the N6 FUNDED bullet; the
version-plane note); STATE.md 363–413 ("Immediately next" — the N5
execution agenda + the close-rider list + the N6 pre-positioning);
DECISIONS.md ADR-017 rows 505–520 (the migration shape, the epilogue
sequence, the FFI seam "macOS via the same C header in an SPM target",
the macOS tiering, the v2.0.0 rule, the ADR-009 disposition);
ROLES.md :47–53 (the mandate); DEBT.md (D30 + D42 both standing, D42's
disposition "T3 session 2"); README.md 16–38 (the apps table rows — the
macOS row's slot after `apps/windows` line 27); `apps/macos/Package.swift`
whole (tools 5.9 at line 1 with the round-1 finding recorded in its own
comment; the `.macOS(.v13)` platform pin; zero deps);
`apps/macos/Sources/ClearFileFFI/include/ClearFileFFI.h` (the FIVE-`../`
umbrella include — the ruled shape);
`apps/macos/Sources/ClearFileFFI/shim.c` (the comment-only anchor TU);
`apps/macos/Sources/ClearFileMacOS/main.swift` whole (the C-ABI
ownership contract inline: guard-let :269–273, `defer { clearfile_free }`
:274, the immediate copy-out :275, the borrowed last_error copied out
:44–47, the 512 MiB pre-read bound :232/:254, `kAppVersion = "0.1.0"`
:52 — the N4-exit rider lesson applied source-side, the honesty set in
the headless footer :222 + the window :384–389, zero engine logic);
`.github/workflows/hygiene.yml` 486–618 (the macos-app job: contents:read
:514–515, the rustc + host-triple guard :523–540, **the identity echo**
:543–546, the .dylib :548–551, the boundary battery :553–554, the
wrapper-header assertion :558–563, the zero-dep assertion :565–571, the
SPM build + Package.resolved-absence :574–579, the deployment-floor
assertion :583–587, the headless smoke vs the Linux expected text
EOL-normalized both sides :592–598, the otool -L guard over BOTH
binaries :604–618, no cargo-deny with the recorded reason :509–511, ZERO
uploads); `scripts/harness_check.sh` :65–85 + :347–373 (the FUNDED-1 and
N-outcomes-8 counters; the N5 apps/macos families — presence + the
include + the floor + the zero-dep + the EOL posture); `.gitattributes`
whole (the R-ENG-23 hardening); `.gitignore` tail (the apps/macos joins);
`apps/linux/tests/expected-headless.txt` (1,766 bytes — the canonical
text family).

**Ran (my own read-only probes — git/rg/curl/python/df only):**

1. `git status --short` → EMPTY; `git tag` → exactly v1.0.0/v1.0.1/v1.1;
   `git log --oneline ff127f2..9cfffa7` → 3 commits (48d981d → cdd25a1 →
   9cfffa7); `git log --oneline 2ddcce5..9cfffa7` → **4** (the N5 arc:
   the gate record + the implementation + the two round fixes — the
   push-count note above).
2. `git diff --stat ff127f2..9cfffa7` → 8 files, +714; `git
   diff --name-only … | grep -E '^(clearfile|src)/'` → **EMPTY**;
   `git diff --quiet … -- .github/workflows/release.yml` → clean
   (byte-unchanged); same for core/ + core-ffi/ `Cargo.{toml,lock}` and
   `core-ffi/clearfile.h` → **all byte-unchanged** (the SPM package
   consumes the contract; it never edits it).
3. **The LIVE-GREEN verification (my own probe):** fetched the run page
   `github.com/maniesh-NR/ClearFile/actions/runs/45977202882` (title
   confirms the run is on **9cfffa7**; 11 success check-icons, ZERO
   failure markers, zero "failure"/"cancelled" strings) + all 8 job
   pages (the job IDs 140431801687–140431802309): every job — RE tooling,
   Linux app, Windows app, Test suites, Android app, **macOS app
   (14/14)**, gitleaks, Harness memory self-check — shows every step
   `data-conclusion="success"` and ZERO non-success conclusions; the
   macOS job's full step ladder enumerated in the scope block above.
4. `rg -n "45977202882|45976627388"` over tracked `.md` files → ZERO
   (Condition 2); `grep -n "apps/macos" README.md` → ZERO (Condition 1);
   `grep -cE '\*\*N[1-6]: (ENTERED|PASSED|CLOSED)' CONSENSUS.md` → **8**
   (Condition 3).
5. `bash scripts/harness_check.sh` → **0 failure(s)** (the N5 families
   green at the tip).
6. `git ls-files --eol | awk '{print $1}' | sort | uniq -c` → **419 i/lf
   + 29 i/-text, ZERO crlf/mixed** (the renormalize holds at tip;
   reconciles exactly: 410 at `2ddcce5` + the 4 N5 entry reports
   (`ff127f2`) + the 5 new execution files = 419).
7. `find apps -name "*.h"` → only the wrapper umbrella header (no
   clearfile.h copy anywhere under apps/); `grep -n "clearfile_free\|free("
   apps/macos/.../main.swift` → exactly the one defer at :274 (no libc
   free); the C-ABI symbols used: `clearfile_load_and_compute`,
   `clearfile_palette_scheme_role`, `clearfile_last_error` (borrowed),
   `clearfile_free` — nothing else, no re-declaration.
8. `grep -n "sw_vers\|swift --version" hygiene.yml` → the identity echo
   step (:543–546); `grep -c "upload-artifact" hygiene.yml` → 0; the
   workflow-level `permissions: contents: read` (:17–18) + the macos
   job's own block (:514–515).
9. `df -h /` at filing → 9.9 GB rootfs, **6.7 GB available** (the entry
   level held; the trend watch continues).

---

Working tree at filing (this lane's ONLY authored file is this report;
any other `2026-11-27-n5exit-*.md` rows are the parallel reviewers' own
concurrent filings — isolation respected, not read, left exactly as
found):

```
$ git status --short
?? harness/adversarial/reports/2026-11-27-n5exit-product.md
```
