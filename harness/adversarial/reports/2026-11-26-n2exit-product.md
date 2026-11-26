# ADV-PROD — N2 exit gate (2026-11-26, Task N2-EXIT-PROD)

**Scope:** the N2 exit gate (ADV-PROD lane) over the whole N2 delta
`d227bc7..7f18fa2` (the Linux native UI + D44's MD3 palette, executed in the
gate's two-session box) + the exit checklist. Pushed tip `7f18fa2` verified;
the working tree is clean (my own probes wrote nothing into it — the one
mutating side-effect, a failed app-build attempt under
`apps/linux/target/`, was fully removed as gitignored residue; see the
verification log point 6 and Risk 2).

VERDICT: **PROCEED-WITH-CONDITIONS** (5 conditions, all record-level or
gate-close-dischargeable; none blocks the consolidation, the topology, or
D44 — but Conditions 1–2 are hard prerequisites for calling the exit
checklist's app/CI items satisfied)

The box discipline held exactly as the gate record set it: **exactly two
execution sessions, no tripwire, the intra-session checkpoint discipline
executed through the FIFTH divergence** (session 1: 8365249 → ad6bce2 →
69c8dda → 39bdc22, three checkpoints + close; session 2: 37f1a5c → 7f18fa2,
checkpoint + close; the fifth divergence — uncommitted work lost mid-session
— is recorded in SESSION_LOG with its new class member and was disposed per
protocol with the corpus digest re-matched exactly). The consolidation to
Slint and the no-workspace topology are recorded per the gate's conditions
1–2, with the demand evidence, the forfeit without overstatement, and the
revisitability. D44 is complete and I re-verified it live: the core suite
**174/174 green** under the pinned 1.100.0 toolchain (including the palette
suite's 19,998 ladder + 2,244 role = 22,242 ARGB-exact checks), the corpus
digest matches `da1ceaf4…` exactly, and the app consumes the palette
(`apply_theme` → `scheme_role`, seed 0xFF00696E = the corpus's recorded app
seed). The v2.0.0 discipline held: release.yml byte-unchanged, no tag beyond
v1.1, no existing version plane moved (apps/linux's 0.1.0 is a NEW plane,
`publish = false`), and the delta contains **zero top-level `clearfile/` or
`src/` paths**. The R1/R2 hardenings landed in substance (the 10,000-member
object cap with `TooManyMembers`; the 256 MiB cumulative STORE-extraction
cap with the honest walk note; battery extensions — my live run covered
tax_inspect_port's 39).

What fails the audit — and it is a product-level honesty failure, not just a
CI flake: **the new `Linux app` CI job is RED on both session-2 pushes**
(runs #38 on 37f1a5c and #39 on 7f18fa2 both fail at the `app unit tests`
step; the headless smoke, window smoke, and cargo-deny steps are all
SKIPPED — none has ever run green anywhere), the failure is deterministic
(the runner lacks `libfontconfig1-dev` — `yeslogic-fontconfig-sys`, pulled by
slint's femtovg font chain, panics in its build script at `pkg-config
fontconfig`), and **nowhere in SESSION_LOG/STATE is the red CI recorded**
(the session-2 close's "0 failures @ 17:5xZ" is the local harness_check
only; CI run #39 failed at 17:42, before that timestamp). The exit-checklist
claim "the app + smokes + cargo-deny **landed**" is true at the code level
and honest as written — but the gate's own condition 6 ("the first run
live-verified green") is unmet, and the local window smoke also never
completed in-sandbox (the recorded libxkbcommon-x11 finding), so the window
smoke has passed nowhere. Second, the **README `apps/linux` row is missing**
(gate condition 11's named item; the delta does not touch README.md; the
core/ row is stale and fixtures/palette has no row at all). Third, the
teardown bookkeeping is owed: STATE.md still says "N2 session 1 CLOSED" and
its "Immediately next" points at the already-convened-and-closed N2 delta
gate; DEBT.md has no "D44 CLOSED" append (the D43 precedent); the ROADMAP N2
bullet awaits its exit outcome. Fourth, my entry-gate Condition 6 (the N3/N4
pre-positioning note) was **dropped from the consolidated 13-point ledger**
(the measured Android facts live only in my filed entry report). The Stage-2
slip re-agenda carries — no ruling received.

## Verification log (what I actually read / ran)

**Read:** CONSENSUS's N2 gate record whole (the 13-point consolidated
condition ledger + the two-session box + the disk plan + the drift disposal
12 + the slip re-agenda 13); SESSION_LOG's N2 entries whole (the gate entry
1946–1988, the fifth-divergence checkpoint, the session-1 close, the
session-2 close 2080–2119); ROADMAP's N2 bullet 609–632 + the per-OS-order
re-settable note 651–657; DEBT's D44 record (the N1-exit append-only note,
211–220); DECISIONS' tail (the last entry is the 2026-11-26 ratification
register — no ruling since); the whole N2 delta file list; apps/linux's
Cargo.toml / deny.toml / build.rs / main.rs (597 lines) / app.slint (330
lines) / expected-headless.txt; core/src/json.rs + tax_inspect.rs hardening
markers; core/tests/palette_port.rs (200 lines, the 4 corpus tests);
fixtures/palette/README.md; THIRD-PARTY-NOTICES.md's new Apache-2.0 entry;
hygiene.yml whole; my own entry report (2026-11-26-n2-product.md, PROD's 7).

**Ran (my own measurements):**

1. `git diff --name-only d227bc7..7f18fa2` → 26 files: **zero top-level
   `clearfile/` or `src/` paths** (apps/linux/src/ + core/src/ are the new
   engine's own trees per the boundary sentence). `git diff` on
   release.yml → **empty** (unchanged). core/Cargo.toml, package.json,
   clearfile/pubspec.yaml, core/src/envelope.rs all absent from the delta —
   **no version plane moved**. `git tag` → v1.0.0, v1.0.1, v1.1 only —
   nothing shipped.
2. The hygiene.yml delta is **purely additive** (the new linux-app job; the
   existing jobs byte-identical — no removed lines at all).
3. **The core suite, live under the pinned toolchain** (tools/rust, cargo
   1.100.0): `cargo test --locked` in core/ → **174/174 green** (lib 24,
   differential 3, composition 6, manifest 2, fixtures 42, palette_port 4,
   property 7, return_format 25, tax_inspect 39, txf 22) — the session-2
   close's "174/174 (170+4)" claim verified exactly.
4. **The corpus vs its README:** `sha256sum fixtures/palette/cases.json` →
   `da1ceaf4…` **matches the recorded digest exactly**; metadata verified
   (kind clearfile-palette, seedCount 33 == len(cases), roleCount 34,
   paletteCount 6, mcuSha256 `9c337007…` matching BOTH
   scripts/palette_tool/pubspec.lock and clearfile/pubspec.lock — the
   reference is pinned, not floating); seed[0] = 4278217070 = 0xFF00696E —
   **the app's seed is a corpus case**; harness_check's palette-ledger family
   green; full harness_check run → **0 failures** (25 families).
5. **The CI status, live via the API (sparing, authenticated per the
   standing pattern):** hygiene run #39 (7f18fa2, the tip) = **failure**; run
   #38 (37f1a5c) = **failure**; runs #35–#37 (session 1) = success. In both
   failures the failing job is exactly the new `Linux app` job, the failing
   step is `app unit tests`, and headless/window smokes + cargo-deny are
   **skipped** (never executed anywhere). The downloaded log shows the root
   cause: `yeslogic-fontconfig-sys v6.0.1`'s build script panics —
   `pkg-config … fontconfig … Package 'fontconfig' not found` — i.e. the
   runner image lacks `libfontconfig1-dev`. (The runner's rustc is 1.100.0 —
   same as the local pin; the MSRV guard passed.) The linux-app job has
   **never been green**; the cargo-deny lane has never run. Nothing in
   SESSION_LOG/STATE records this.
6. **The app suite could NOT be re-verified live at this gate — the disk
   plan's margin is exhausted:** with ~2.9 GB free I launched the app build
   (debug-stripped); it ENOSPC'd mid-compile at i-slint-backend-winit. I
   removed `apps/linux/target/` (gitignored) fully; disk now ~2.0 GB free,
   with ~0.9 GB of crate registry cache now resident (reusable). The
   "app 5/5" claim therefore rests on the session record (the 5 unit tests
   exist in main.rs and are structurally what the record claims: money
   formatting, the envelope pipeline on the migration fixture, the
   byte-exact headless text vs the committed expected file, the container
   round-trip incl. migration idempotence, the honest core-wording errors)
   — honest as far as it goes, but the durable lane (CI) is red, which is
   exactly what Condition 1 discharges.
7. The honesty surfaces, in-app: verified present — the demo disclaimer
   ("not IRS-authorized, cannot e-file, must not be used to file a real tax
   return"), the no-AI/no-network/no-key-storage note, the prototype labels
   (window title + header + About), the argv-only naming in the honest
   no-file card, and the IRS/Intuit non-affiliation line. The README
   apps/linux row: **absent** (README.md untouched by the delta; the core/
   row still reads "ENTERED 2026-11-26" with no palette/D44 mention; no
   fixtures/palette row).
8. The box discipline, from git + SESSION_LOG: exactly the two sessions'
   commits exist; no third session, no extension, no slip-rule invocation —
   **no tripwire**. The intra-session checkpoints executed in both sessions
   ("green = backed up"), and the FIFTH divergence record is complete
   (the stale-snapshot recycle, uncommitted files lost, disposal per
   protocol, the digest re-match, the new class member recorded).
9. The drift-disposal note (gate condition 12 / my entry condition 2):
   recorded in SESSION_LOG's gate entry (the npm-install drift, three
   reviewers, `git restore`, the class note) ✓.

## Conditions (all dischargeable at this gate's close, the N1-exit
in-session precedent; the box is NOT reopened — these are gate-close work,
not a session 3)

1. **Make the CI app lane green and record the red honestly.** Fix: install
   the runner's missing dev packages — at minimum
   `sudo apt-get install -y libfontconfig1-dev` — BEFORE the `app unit
   tests` step in the `linux-app` job (the current apt install lives in the
   later window-smoke step and covers only libxkbcommon-x11; audit for any
   further `-sys` needs the same way — the first green run is the proof, per
   the gate's own rule). Then: the **first green run live-verified** — all
   five steps green (rustc guard, app unit tests, the headless byte-diff
   smoke, the Xvfb window smoke with the marker, cargo-deny over the full
   committed 539-package lock) — and the SESSION_LOG/STATE record gains the
   failure's discovery + disposition (runs #38/#39 red at the unit-tests
   step, `yeslogic-fontconfig-sys`'s `pkg-config fontconfig` panic on a
   runner without `libfontconfig1-dev`; smokes + cargo-deny skipped; the
   fix; the green run). The exit-checklist claim "the app + smokes +
   cargo-deny landed" gains its green half. *Checkable:* a green hygiene run
   on the gate-close push with the linux-app job's five steps green; the
   SESSION_LOG note exists.
2. **The README rows — the honest-claims audit's named gap.** Add the
   `apps/linux` row (the gate condition 11 / entry condition 4 item): the
   honest scope (an argv-envelope viewer demo — load a `.clearfile.json` or
   `.tax` container by path, compute via the shared core pipeline, render
   the themed window; `--headless` prints the same summary; a labeled
   demonstration prototype, not a filing product) + the interim statement
   (the Flutter GTK app remains the shipped Linux product until the native
   GA — the distro/glibc baseline is a GA-gate decision). Refresh the stale
   `core/` row (the palette module + D44 + the 22,242-check corpus
   verification + N1's exit status). Add the `fixtures/palette/` row (the
   corpus taxonomy — 33 seeds × 6 ladders × 101 tones + 34 roles ×
   light/dark, the MCU 0.13.0 content-hash-pinned reference, byte-
   deterministic with the recorded digest — the differential-corpus row's
   pattern). *Checkable:* `rg "apps/linux" README.md` finds the row with the
   viewer-scope + interim sentences; the core/ and palette rows exist.
3. **The teardown bookkeeping (this gate's own record duties).** STATE.md:
   refresh the header to N2 session 2 + the exit outcome; rewrite
   "Immediately next" (it still points at the already-closed N2 delta gate —
   it must point at the N3 delta gate / the exit-gate outcome); give the
   epilogue gate-status bullet its N2 entry. DEBT.md: the **D44 CLOSED**
   append-only note (the D43 precedent), naming the closure evidence (the
   palette module + the corpus + palette_port's 22,242 ARGB-exact checks +
   the consumer in apps/linux). ROADMAP: the N2 bullet's exit outcome +
   execution record (the N1 bullet's pattern — gate status → CLOSED (exit
   …), the two sessions, the deliverables). Checkers: the legitimate-
   advance updates (the N-outcome counter). *Checkable:* STATE/DEBT/ROADMAP
   carry all four; harness_check 0 failures on the gate-close push.
4. **Record the N3 pre-positioning note in the gate record** (my entry
   Condition 6 — dropped from the consolidated 13-point ledger; currently
   the facts live only in my filed entry report): the measured sandbox facts
   (no Android SDK/NDK anywhere — `/opt`, `/usr/lib/android-sdk`,
   `$ANDROID_HOME`, `tools/` all checked; Java 21 present; no dart/flutter;
   no mingw for N4), the mitigations (a NEW tracked sha256-pinned fetcher
   class in the fetch_tt_corpus / fetch_rust_toolchain pattern —
   `sdkmanager` needs no root — and/or the CI ubuntu runners, which ship the
   Android SDK), the per-OS order standing (N3 before N4; re-settable at
   the epilogue's own gates without reopening the settlement), and what
   N3's gate must rule: the SDK/NDK feasibility lane (the fetcher class vs
   the CI android image), the JNI shim design per ADR-017's FFI seam (one
   flat C ABI, cbindgen-generated header — **N3 is the recorded cbindgen
   trigger** ("lands with the first FFI consumer"); the thin JNI shim over
   it; the envelope-as-payload-boundary discipline), and KMP per the
   settlement (Android-only; no second Kotlin target). *Checkable:* the
   CONSENSUS exit record (or ROADMAP's N3 bullet) carries the measured
   facts + the three ruling questions.
5. **The Stage-2 slip re-agenda continues — fourth cycle, no ruling
   received.** DECISIONS' latest entry is the 2026-11-26 ratification
   register; no ruling on the slip exists. The standing owner options,
   restated verbatim in substance: (a) **fund a T3 session** (the
   MSI-record keystream divergence chase at payload offset 0x24000 +
   `tax-modern.md`, debt D42), (b) **supersede the RE-protocol namespace
   rule** that requires the modern format's DoD spec, or (c) **the default
   re-agenda** (the slip keeps re-agenda-ing at every convened gate until
   ruled). (c) continues; the next surfacing rides with N3's gate. The gate
   record carries them. *Checkable:* the exit-gate record names all three
   options + "no ruling received".

## Risks register

- **The CI fix lands blind on the runner's dev-package set** — fontconfig is
  the proven gap; a further `-sys` crate could fail the same way (wayland/
  gbm/drm families are in the 539-package lock). Mitigation: Condition 1's
  "the first green run is the proof" rule (the gate's own posture), applied
  before the gate close is called done.
- **Disk margin at the gate is thin:** ~2.0 GB free after my probe (the app
  tree needs more than the plan's ~1.3 GB once the registry cache is
  resident); the local app-suite re-verification is disk-bound until the
  next recycle/teardown — CI (once green) is the authoritative lane. A
  gate-close session wanting a local app build must first free space (the
  re-fetchable residues) or accept CI-only verification.
- **"Landed" ≠ "verified" drift hardening into the record:** the exit
  checklist's app/CI items were recorded as landed while the durable lane
  was red and unrecorded. Mitigation: Condition 1's recording duty; future
  exit checklists must pair every "landed" with its verification lane's
  actual status.
- **The second README-row miss of its class** (an exit-checklist honesty
  surface that the closing session skipped). Mitigation: Condition 2 + the
  pattern that exit gates re-run the honest-claims audit on README/STATE.
- **The fourth slip cycle without a ruling** — the indefinite-parking risk
  stands; the proof would be a fifth cycle at N3's gate without an owner
  word. Mitigation: Condition 5 keeps the options visible.

## Advisories (non-binding)

1. **THIRD-PARTY-NOTICES.md typo:** the new Apache-2.0 entry's markdown link
   lost its opening bracket ("…Dart package
   aterial_color_utilities](https://pub.dev/…)") — should be
   `[material_color_utilities](`. One-character fix in the gate-close
   session (the LEGAL lane's surface; cosmetic, but it is the core's first
   third-party-derived notice and deserves a clean link).
2. **The CI toolchain-pin advisory is presently moot:** the runner's rustc is
   1.100.0 — identical to the local pinned toolchain (verified in the run
   #39 log; the ≥ 1.95 MSRV guard green). Revisit only on runner drift; the
   guard already covers the fail-closed half.
3. **The app's About area could name the roadmap** (my entry condition 4's
   "no editing, no file picker, and their roadmap" wording): the delivered
   surfaces label argv-only + viewer honestly, but never say where editing
   and the picker come from. A one-line About addition alongside the README
   row (Condition 2) closes it cheaply.
4. **SPDX carve-out for generated/pinned app files:** expected-headless.txt
   (byte-exact pinned stdout — an SPDX header would break the CI diff) and
   apps/linux/Cargo.lock carry no SPDX header, unlike every authored app
   file. Record the carve-out if the LEGAL lane wants the "every tracked
   file" discipline stated with its exception rather than left implicit.
5. **The file-picker constraint is still unrecorded anywhere** (second
   surfacing): `rfd` is GTK-backed on Linux and would reintroduce the
   forfeited build dependency; the eventual route is xdg-desktop-portal
   (D-Bus, no toolkit) or Slint's own offering. It belongs in the GA-lane
   notes before anyone rediscovers it mid-session.
6. **The version-plane note extension:** apps/linux's 0.1.0 is a FIFTH
   version plane; the ROADMAP note still names only the core crate's
   fourth. Fold into Condition 3's ROADMAP edit (one sentence).
