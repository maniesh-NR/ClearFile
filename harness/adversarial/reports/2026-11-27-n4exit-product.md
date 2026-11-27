# ADV-PROD — N4 exit gate (2026-11-27, Task N4-EXIT-PROD)

**Scope:** the N4 exit gate over the delta `2a3acd1..9e6cf46` (7 commits, 14
paths; the tip `9e6cf46` = the session-2 records backup), ADV-PROD lane per
ROLES.md — roadmap rightness, stage discipline, the working-app bar at the
demo standard, single-maintainer sustainability, records honesty. One of
four parallel isolated reviewers (reports at
`harness/adversarial/reports/2026-11-27-n4exit-*.md`; none read by me).
Verified live at my probe: the working tree CLEAN (`git status --short` →
empty); the box held at exactly TWO sessions (session 1 = `5c4efa2`: the
config-emitted guarded header + the C++ app + the guard joins; session 2 =
`f874371`→`9e6cf46`: the CI windows lane + the rounds + the records); the
five-round CI-fix record honestly kept (each round's finding + fix in
SESSION_LOG, corroborated by the round commit messages `1ebe125`/`467e4b4`/
`ed51621`/`8b3cb95`); the lane's first live-green run **45957061389 on
8b3cb95, ALL SEVEN JOBS** — the headless smoke the byte-exact canonical
text family across platforms (EOL-normalized both sides after the
autocrlf root-cause round); the window mode the named non-verification in
the session records; the variant preconditions all held (measured: the
clearfile/+src/ delta filter EMPTY; release.yml byte-unchanged; tags
exactly v1.0.0/v1.0.1/v1.1; no uploads). The eight entry conditions are
discharge-verified in the log below — three residuals, all one-line
close-bookkeeping riders (Conditions 1–3), none re-opens the box. The
MANDATORY ninth-surfacing restatement + the N5 handoff are bound in below.

VERDICT: **EXIT-PASS (3)** — all three conditions are record-side
close-bookkeeping riders that the exit close already owes; no app change,
no lane change, no BLOCK.

## Conditions (numbered, checkable — all ride the exit close bookkeeping)

1. **The README `apps/windows` row gains the named non-verification
   clause.** Measured: `rg -n "interactive|desktop" README.md` → only the
   marketing line 7; the windows row (line 27) carries the honest scope,
   the unreleased status, the interim statement ("the Flutter Windows app
   remains the shipped Windows product"), the CI-only lane, the no-network
   note (mechanically proven by the PE import-table guard), and the
   honesty set by reference — but NOT the named non-verification my entry
   Conditions 1/2(ii) pinned to the README row itself ("no interactive
   desktop run — the window mode is authored, not desktop-verified; the
   headless mode is the proven surface"). It IS recorded in SESSION_LOG,
   the tip commit, and CONSENSUS — the README slot is the one gap.
   *Checkable:* the close's README edit adds the one clause;
   `rg -n "desktop" README.md` finds it in the windows row.
2. **The run number cited in the close bookkeeping.** Measured:
   `rg -n "45957061389"` repo-wide → ZERO matches. SESSION_LOG's
   session-2 close cites the commit (8b3cb95, ALL SEVEN JOBS) but not the
   run number — the per-lane live-status wording discipline (entry
   Condition 2(iii), the N3-exit hardening: "run N GREEN on <sha>")
   requires both, and the N3 precedent cited 45948447173 on ae9e078 in
   SESSION_LOG + ROADMAP + STATE. The ROADMAP N4 exit-outcome rewrite and
   the STATE refresh (owed at this close anyway) must carry
   "**run 45957061389 GREEN on 8b3cb95**"; a SESSION_LOG line cites it
   too. *Checkable:* `rg -n "45957061389"` finds the citation after the
   close.
3. **The `apps/windows` 0.1.0 version marker — land it or amend the
   record to the record-side-only form.** Measured:
   `rg -n "0\.1\.0|VERSION|version" apps/windows/main.cpp` → ZERO
   matches. The gate ledger's item (8) records "the version lives in the
   source + the record" (the crate-plane form — the app has no crate);
   as measured, it lives ONLY in the record — the ledger's own claim is
   half-undelivered. Either land the one-line marker in `main.cpp`
   (e.g. a `kAppVersion = L"0.1.0"` constant surfaced with the honesty
   set), or amend the CONSENSUS/ROADMAP wording to the record-side-only
   form. No version movement occurred (measured: no existing plane
   touched in the delta) — this is a records-honesty rider, not a variant
   breach. *Checkable:* the marker exists in `main.cpp`, or the record no
   longer claims the source carries it.

**The Stage-2 slip re-agenda — the MANDATORY item, the NINTH surfacing
(the enumeration: 1 N1-exit, 2 N2-entry, 3 N2-exit-convening, 4
N2-exit-close, 5 the 2026-11-27 restatement, 6 the N3 entry, 7 the N3
exit, 8 the N4 entry, 9 THIS exit gate) — restated here in full, required
in the gate record's agenda.** The three owner options,
verbatim-in-substance: (a) **fund a T3 session** (the MSI-record
keystream decompile chase at payload offset 0x24000 + `tax-modern.md`,
debt D42), (b) **supersede the RE-protocol namespace rule** that requires
the modern format's DoD spec, (c) **the default re-agenda** (the slip
keeps re-agenda-ing at every convened gate until ruled). **No ruling
received across EIGHT prior surfacings; (c) continues; the TENTH rides
with N5's gate.** The count stays pinned by enumeration so the ledger
cannot drift. D42 stands (disposition "T3 session 2", untouched by this
delta — confirmed).

## Risks register

- **The run-vs-tip gap:** the lane-green run (45957061389) is on 8b3cb95;
  the tip 9e6cf46 is the records-only backup, and the exit close adds
  further records commits — the same registered non-blocking class as the
  N3 exit's note. The next lane-touching push re-proves; nothing in the
  records overclaims a run on the tip.
- **The window mode stays authored-not-desktop-verified into N5:** the D2D
  render path's silent-wrong classes (the factory failure in a service
  session; the palette ARGB-uint32 → D2D RGBA ColorF byte-order misread)
  remain value-unverified — the entry's Advisory-2 headless theme dump
  was NOT taken (the smoke is byte-parity with the Linux text family, no
  theme values asserted on Windows). Mitigation: Condition 1's named
  non-verification clause carries the honesty; the Android lane's JVM
  palette-seam tests keep the FFI values themselves covered.
- **The EOL normalization is load-bearing in the smoke:** the canonical
  text family is now asserted EOL-independent (tr -d \r both sides, after
  the autocrlf root-cause round) — no future record may cite the Windows
  smoke as byte-exact on EOL. The SESSION_LOG already carries this;
  low residual risk.
- **The version marker gap (Condition 3):** if left, the Windows plane's
  version claim is record-only while the record says otherwise — a small
  records-honesty debt; nothing ships, so no consumer exposure.
- **The slip's indefinite parking:** NINE surfacings without an owner
  word; the proof of the pattern would be a cycle without the item.
  Mitigation: the pinned enumeration + the mandatory restatement above +
  the gate-record agenda requirement.
- **The disk trend:** 1.8 GB (N3 entry) → 1.6 GB (N4 entry); the N4 box
  ran CI-primary so the sandbox cost stayed low — the per-session
  re-measure continues (ENG's lane); re-measured at filing (below).

## Advisories (non-binding)

1. **The close bookkeeping set (the standing N1/N2/N3 pattern, owed with
   this verdict):** ROADMAP N4 bullet → the CLOSED (exit PASSED) record
   (the two-session box + the five-round record + the run citation —
   Condition 2); STATE refresh (header + the epilogue N4 bullet
   gate-status + "Immediately next" → the N5 gate agenda; STATE is
   untouched in this delta — measured — so the refresh is fully owed);
   `harness_check.sh` checker update per the legitimate-advance precedent
   (the funding-posture line at :67 currently encodes "N4 ENTERED
   2026-11-27" → N4 CLOSED; the N-outcomes count 5→6); the CONSENSUS exit
   record with the consolidated verdicts + the NINTH surfacing + the N5
   handoff; the README row clause (Condition 1).
2. **The N5 handoff — the pre-positioned agenda (stands; confirmed in
   CONSENSUS's ledger item 12 + STATE item 5):** (i) the macos-latest
   live-verification list (the current image list, the label resolution,
   the macos-13 retirement window); (ii) the recorded PROD bar ruling
   under the per-lane discipline (macos-latest CI alone satisfies the
   demo bar; the single-maintainer risk recorded; any macOS GA owes an
   owner-side build or the recorded CI-only acceptance); (iii) the
   owner-side-build offer; (iv) the wasm32 target question for N6
   (`wasm32-unknown-unknown` vs `wasm32-wasip1` — the core is
   pure/offline/std-only; N6's gate rules it, ruled nothing now).
3. **The headless theme dump (entry Advisory 2) was not taken** —
   recorded honestly as not-taken; the N5 gate may take the macOS
   equivalent cheaply if it wants the mac app's colors CI-proven.
4. **The window-smoke question (entry Advisory 3 — a D2D WARP
   software-render smoke, no HWND presentation) was not taken** — the
   named non-verification stands honestly; N5 may revisit.
5. **The per-platform LICENSES manifest is NOT owed at N4** (the ADR-017
   licensing annex: it lands with each platform's first TAGGED release;
   Win32+Direct2D are proprietary system libraries under the GPLv3 §1
   carve-out) — record note only, LEGAL's surface.

## Files read + verification log

**Read:** my entry report whole (`2026-11-27-n4-product.md` — the 8
conditions); CONSENSUS.md 1783–1887 (the N4 delta-scoped gate record: the
verdict table, the probe findings, the 12-point ledger incl. items 8/11/12
— the variant form, the EIGHTH surfacing with the pinned enumeration, the
N5/N6 pre-positioning + the wasm32 note); SESSION_LOG.md 2270–2493 (the N3
close + the N4 session-1 and session-2-CLOSED entries — the two-session
box, the five-round honest record, the NINTH-surfacing handoff line);
STATE.md 300–389 (the quirk-register tail + "Immediately next" — still the
N4 gate agenda, i.e. the refresh is owed at this close); ROADMAP.md
655–719 (the N3 execution record with the run citation precedent
45948447173 on ae9e078; the N4 ENTERED bullet + the N5/N6 FUNDED bullets +
the version-plane note); ROLES.md (the ADV-PROD mandate at :47); README.md
25–27 (the android + windows rows); `.github/workflows/hygiene.yml` via rg
(the windows-app job: the rustc + host-triple guard :418–435 — the mingw
rejection enforced mechanically; the cl /utf-8 /std:c++17 /W4 link :457 —
user32/gdi32/comdlg32/d2d1/dwrite only; the dumpbin PE import-table
network guard on BOTH the exe and the .dll :460–461; the
.dll-beside-the-exe copy :471; the headless smoke on the SHARED
migration fixture :472; contents: read :414; no uploads);
`scripts/harness_check.sh` via rg (the N4 windows-scaffold family :339–344
— main.cpp presence + the header's extern-C guards ≥ 2; the
funding-posture checker :67); `apps/windows/main.cpp` via rg (the
version-marker probe — zero).

**Ran (my own read-only probes — git/rg/df only):**

1. `git log --oneline 2a3acd1..9e6cf46` → 7 commits: 5c4efa2 (session 1:
   the guarded header + the app + the guard joins), f874371 → 1ebe125 →
   467e4b4 → ed51621 → 8b3cb95 → 9e6cf46 (session 2: the lane + the five
   rounds + the close) — TWO sessions exactly, the round commits
   corroborating SESSION_LOG's five-round record (rounds: DrawTextW +
   the over-strict rider assertion → the errorlevel/:app quirks → the
   one-sided EOL diagnosis → the autocrlf root cause → green).
2. `git diff --name-only 2a3acd1..9e6cf46` → 14 paths (hygiene.yml,
   .gitignore, README, apps/windows/main.cpp, cbindgen.toml +
   clearfile.h, the four n4 entry reports, CONSENSUS, ROADMAP,
   SESSION_LOG, harness_check); `git diff --name-only 2a3acd1..9e6cf46 |
   grep -E '^(clearfile|src)/'` → **EMPTY** as required.
3. `git diff --quiet 2a3acd1..9e6cf46 -- .github/workflows/release.yml` →
   clean — **release.yml byte-unchanged**; `git tag` → exactly
   v1.0.0/v1.0.1/v1.1 — **no new tags**; `git status --short` → EMPTY at
   the probe.
4. `rg -n "45957061389"` repo-wide → ZERO matches (Condition 2);
   `rg -n "interactive|desktop" README.md` → only line 7 (Condition 1);
   `rg -n "0\.1\.0|VERSION|version" apps/windows/main.cpp` → ZERO
   (Condition 3).
5. The eight entry conditions, discharge-verified: (1) the README row →
   carried except the named non-verification → Condition 1; (2) the
   working-app bar → the headless surface proven green (the smoke, the
   canonical Linux expected text, EOL-normalized both sides), the window
   non-verification recorded in the session records, the fixture PULLED
   from the shared fixtures/migration family (the gate ledger's ruling —
   never a committed copy; no fixture path in the delta), the run-number
   wording gap → Condition 2; (3) the extern-C ruling → discharged by the
   gate's config-emitted option (cbindgen after_includes + trailer, the
   regenerated header, the freshness lane green; both-way verified; the
   RAII + borrowed-error contract in the app); (4) the toolchain ruling →
   recorded (the second-ABI rejection + the mechanically enforced
   host-triple guard), the round-count cost landed BETTER than the named
   N3 datum (five honest rounds vs eleven); (5) the EIGHTH surfacing →
   carried in CONSENSUS ledger item 11 with the pinned enumeration; the
   NINTH is restated above; (6) the N5/N6 pre-positioning → stands
   (ledger item 12 + STATE), carried into the handoff above; (7) the box
   + bookkeeping → two sessions, the rider DISCHARGED by supersession
   (the fail-closed classpath assertions + the re-proving green android
   run, kotlin-stdlib 2.4.21 as the one recorded runtime artifact), the
   close set enumerated in Advisory 1; (8) the variant preconditions →
   all held (measured above), except the 0.1.0 marker's source-side
   half → Condition 3.
6. `df -h /` at filing: 1.6 GB available (the N4-entry level held — the
   CI-primary box cost the sandbox ~nothing; the trend watch continues,
   ENG's lane).

---

Working tree at filing (this lane's ONLY authored file is this report;
any other `2026-11-27-n4exit-*.md` rows are the parallel reviewers' own
concurrent filings — isolation respected, not read, left exactly as
found):

```
$ git status --short
?? harness/adversarial/reports/2026-11-27-n4exit-product.md
```
