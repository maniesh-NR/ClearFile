# ADV-PROD — N1 exit gate (2026-11-26, Task N1-EXIT-gate-PROD)

**Scope:** the N1 exit gate (delta b9008f9..138e93b; sessions 4a55caf +
138e93b), ADV-PROD lane — roadmap rightness, stage discipline, artifact
fitness, single-maintainer sustainability. The mandated agenda item (the
Stage-2 exit slip) is disposed explicitly below. Repo at tip `138e93b`,
tree clean, origin/main == HEAD (verified).

VERDICT: **PROCEED-WITH-CONDITIONS** (4 conditions, all record-level)

Nothing in the N1 delta is dishonest or falsified: every box item
discharged (verified by my own runs, not by trusting the records), both
ADR-017 variant preconditions hold byte-checkably, the two-session box
closed at exactly two with no tripwire. The conditions are record
completeness — one dangling promise, two missing pre-positioning notes,
one owner surfacing the slip's re-agenda now owes.

## Verification log (what I actually read / ran)

**Read:** ROADMAP (gate tiering, Stage-2 section incl. the exit-slip
record, epilogue N1–N6 section incl. the N2 bullet, TT/T3 section);
STATE (snapshot, the T3/0x24000 record, "Immediately next"); CONSENSUS's
N1 full-depth entry-gate record (gate-level + session-1 binding
conditions, the box definition); SESSION_LOG's two N1 entries (session 1
inside "2026-11-26 (later)", session 2 as its own entry) + the
2026-11-26 owner session (Stage A's honest T3 deferral) + T3 session 1;
DEBT (D31b/c, D33, D40–D43 rows + the append-only N1 notes); DECISIONS
ADR-017 (Rust-core boundary, FFI seam, Linux toolkits, verification
annex, licensing annex, ADR-009 disposition rows); README (core/,
fixtures/differential/, fixtures/tax/, clearfile/test/ rows);
fixtures/differential/README.md (whole); core/tests/differential_harness.rs
(the tolerance-0.0 comparator + 26-key contract), property_harness.rs
(7 tests incl. the D33 live $200k-CTC pin), exchange_composition.rs
(6 tests incl. both fall-throughs), tax_inspect_port.rs header (crash
battery), core/src/envelope.rs (warning strings IN the core, lines
~991–996); the hygiene.yml diff over the whole N1 delta;
scripts/harness_check.sh families; scripts/sandbox_backup.sh allow-list.

**Ran (my own verification, not the records'):**

1. `cargo test --locked` (pinned toolchain 1.100.0, fresh CARGO_TARGET_DIR):
   **159/159 green, 0 failed, 0 ignored** — 15 lib + 3 differential +
   6 composition + 2 manifest + 42 runner + 7 property + 25
   return_format + 37 tax_inspect + 22 txf. Breakdown matches the
   session-2 record exactly.
2. `bash scripts/harness_check.sh`: **21 oks, 0 failures** — matches the
   claim. The release.yml variant-precondition guard, the 17-fixture
   manifest ledger (17 run + 0 deferred == directory), the differential
   corpus ledger (caseCount == array == 550, generator named), and the
   session-2 file-presence family all pass.
3. Corpus audit (Python over fixtures/differential/cases.json):
   kind `clearfile-differential`, generator named, seed 771937021,
   **caseCount 550 == array 550**; class histogram **300 random + 246
   edge + 4 edge-d31b** (= README's "300 random + 250 edge"; 10 of the
   random carry negative inputs; all 5 statuses present, QSS 74 ≈ the
   annex's exhibit-A weighting); **every case's expected block has
   exactly the 26 pinned keys, in order; zero cases carry
   `marginalRate`** (the D31c rule held per case, not just on average).
4. `sha256sum fixtures/differential/cases.json` =
   `a15ac79cc5cb…9947` — **matches the digest recorded in
   fixtures/differential/README.md**.
5. `git diff 4a55caf..138e93b --stat -- .github/workflows/` → **EMPTY**
   (session 2 touched no workflow file at all); over the whole N1
   delta b9008f9..138e93b the ONLY workflow touched is hygiene.yml
   (the recorded cargo-test + license-assertion steps; no new `uses:`
   lines, no secrets); **release.yml untouched** (both sessions).
6. `git diff --name-only b9008f9..138e93b | rg '^(clearfile/|src/)'` →
   **zero matches** — PROD-5 held across the entire N1 delta. The
   generator's relocation from `clearfile/tool/` to `scripts/` is
   recorded in three places (SESSION_LOG session 2, DEBT's D43 closure
   note, fixtures/differential/README.md) — recorded as part of the
   honest record, not hidden; `clearfile/tool/` carries no residue and
   the recorded regen path (`tools/flutter/.../dart`) resolves.
7. Live CI (public HTML, per the live-check quirk): runs on main =
   #28 b9008f9, #29 5f7bc33, #30 4a55caf (the recorded session-1
   pushes), and **run 45827841351 on 138e93b (the session-2 push):
   completed successfully** — I verified green live myself (the
   session log had not; see Condition 1).
8. Git discipline: SESSION_LOG carries exactly **two N1 execution
   entries** (session 1, session 2); exactly two commits (4a55caf →
   138e93b); tip pushed; tree clean — **no silent third session; the
   tripwire never fired** (no extension, no owner ruling required).

## Box-item discharge (mandate 1) — all three verified honest

- **17/17**: session 1 landed 47/47 (17 fixture tests, 0 ignored);
  session 2 held it (my run: 42 runner tests green, 0 ignored; the
  manifest's run+deferred == the 17-fixture directory, mechanically
  checked by harness_check).
- **Annex (a) per the recorded D43 mechanism**: D43's entry-gate
  mechanism ("a Dart-side random/edge input generator emitting JSON
  cases that a later cargo test consumes against the Rust core, with
  the Dart reference computing the same cases in-process") is what
  actually landed — tracked generator, seeded corpus, tolerance-0.0
  comparator (`!(delta <= 0.0)`, NaN fail-closed — read in the
  consumer), all 550×26 green, plus the 7-test property harness with
  the live D33 divergence pin. D43 closed exactly per its record.
- **Annex (b) ported bridge tests**: TXF spec tests (txf_port 22, incl.
  the spec-v042 structure + ECMAScript-identical toFixed(2) money
  lines); `.tax` inspection incl. the malformed-ZIP crash battery
  (tax_inspect_port 37, 19 battery extensions, the ENG-1 crafted-name
  regression); envelope round-trips + warning-wording with the strings
  IN the core (return_format_port 25; envelope.rs pushes the verbatim
  warning strings itself); the payload-seam composition (6, incl. the
  Intuit-shape fall-through). All present, all green in my run.

## The mandatory agenda item (mandate 3) — the Stage-2 exit slip

**Disposal:** the recorded disposition — the 0x24000 keystream chase
stays the T3 lane's next-session task (the decompile-level chase over
the ISSetupStream cipher), the Stage-2 exit stays SLIPPED, tax-modern.md
awaits T3's format-family findings, the exit gate convenes when T3
delivers — is **honest and correct for THIS gate**:

- tax-modern.md was never landable inside the Stage-2 box (per the
  box's own plan; §7.5 forbids stub specs), and is not N1-resolvable —
  the TT namespace rule (TT gate PROD-3/ENG-6) keeps Stage-2's
  tax-modern.md and T3's deep password-layer spec distinct files or an
  explicit recorded supersession. N1 touching it would have violated
  its own boundary.
- No DoD claim was falsified (3/4 specs §7.5-clean, exactly 2
  execution sessions, refusal/cap tests green, blob assertion green);
  the slip was logged at the Stages-4/5/6 gate and re-agendaed per that
  record — the tripwire discipline worked.

**But this gate owes one more thing** — see Condition 4: the re-agenda
toward N2's gate must carry an owner surfacing, because (a) the T3
lane has NO funded/committed next session — the 2026-11-26 funding
message funded N1–N6 only and contained no TT-lane ruling (the same
class as D30's "no ruling received") — so the Stage-2 exit currently
hangs on an uncommitted lane and the slip can re-agenda indefinitely;
and (b) the namespace rule's own supersession path (fold the
tax-modern.md shape spec into T3's deliverable via an explicit
recorded supersession) is a cheaper owner alternative to holding a
separate Stage-2 exit gate hostage to a 26 MB mixed-mode decompile
chase. The product question "does the shipped epilogue (N1's own
STORE-only .tax exchange container + read-only modern-.tax inspection)
still need tax-modern.md as a Stage-2 gate artifact at all" is now
legitimate and owner-shaped. Not a BLOCK — but the surfacing must
travel with the re-agenda or this becomes indefinite parking.

## Conditions

1. **Complete the dangling CI-verification record.** SESSION_LOG's N1
   session-2 CI bullet promises "this session's push verified below in
   its own bullet" — no such bullet exists (the entry ends at the
   exit-checklist bullet; the commit message itself claims only
   "#28/#29/#30 … green live pre-push"). The verification is TRUE
   (I checked live: hygiene run 45827841351 on 138e93b completed
   successfully) but the record's promise is unfulfilled. Append-only
   fix: add the verification bullet (run 45827841351, completed
   successfully, verified live at the N1 exit gate) or repair the
   "verified below" reference. *Checkable:* the N1-session-2 entry
   contains no unresolved "verified below" promise.
2. **Record the ADR-017 palette deferral.** ADR-017's Rust-core
   boundary row lists "MD3-from-seed tonal palette generation" as
   core IN-scope (and the FFI surface names `palette`); the landed core
   has no palette module (zero matches in core/), the N1 entry gate's
   box never scoped it, the exit checklist never listed it, and NO
   debt entry carries its deferral — I verified none of
   SESSION_LOG/ROADMAP/DEBT/CONSENSUS records it in the N1 context.
   This is a silent scope gap, not a false claim, and it is the right
   engineering call (a palette API designed without a consumer would
   be an unverifiable surface) — but the epilogue discipline (deferrals
   are recorded, e.g. D43's) requires it written down. Record a DEBT
   row (or a note in this gate's record): the palette lands with the
   first UI stage that consumes it (N2), where its API is designed
   against a real consumer. *Checkable:* a debt row or gate-record note
   names the palette deferral and its N2 target.
3. **Add the N2 pre-positioning note** (N2's gate inherits an accurate
   core-surface + topology inventory): (a) the C-ABI seam — ADR-017's
   flat extern "C" cbindgen surface is unlanded by design and lands
   with the first FFI consumer (N3's JNI shim / N4's header / N5's SPM
   target); N2/Linux links the crate directly and needs no C ABI —
   say so, so N3 isn't surprised; (b) the crate-topology question —
   the CI zero-dependency license assertion greps `core/Cargo.lock`
   for exactly one package; a root Cargo workspace (the natural shape
   when the N2 UI crate joins) would unify the lockfile at the root
   and break that assertion's path and semantics — N2's gate must
   decide standalone-crate vs workspace + a core-scoped re-shaped
   assertion; (c) the standing consolidation question (one toolkit vs
   the gtk3-rs/Slint two-tier) is already recorded in ROADMAP's N2
   bullet + ADR-017 — no action needed beyond keeping it on N2's
   agenda. *Checkable:* the N1-exit gate record (or STATE's
   "Immediately next") names (a) and (b) as N2 gate agenda items.
4. **Send the Stage-2 slip re-agenda with the owner surfacing**
   (per the disposal above): the re-agenda record toward N2's gate
   must carry (a) the fact that the T3 lane has no funded next session
   — the Stage-2 exit hangs on an uncommitted lane unless the owner
   funds T3's next session; and (b) the recorded-supersession /
   re-scope alternative the namespace rule already allows (fold
   tax-modern.md into T3's deliverable, or formally re-scope what the
   Stage-2 exit still owes). *Checkable:* the slip's re-agenda note
   (wherever the exit-gate outcome is recorded) names both points as
   owner-facing.

## Risks register

- **Indefinite slip parking (Stage-2 exit):** the exit's blocker
  (tax-modern.md) chains through an owner-uncommitted decompile chase
  (T3) — the third consecutive gate cycle would be the pattern's
  proof. Mitigation: Condition 4.
- **ADR-017 boundary vs. landed-core drift:** one boundary-row item
  (palette) unlanded + unrecorded; each future unrecorded gap compounds
  into a "what is the core, actually" discovery tax at every gate.
  Mitigation: Condition 2 (and 3's inventory note).
- **CI toolchain drift (low):** CI's `cargo test` runs on the runner's
  default rustup (unpinned — the deliberate "no new uses: lines" gate
  tradeoff) while local dev is sha256-pinned 1.100.0; a future
  runner-default bump can break CI in a way the local pin can't
  reproduce. Mitigation: advisory 1.
- **Parallel-lane timeout class (low, known):** session 2's five-lane
  parallel execution hit three subagent context deadlines (two
  complete-but-unverified products recovered by review — which caught
  a real bug, the reversed import-date year tail). The class is
  honestly recorded "for the next parallel plan"; N2's larger-scope
  sessions should budget for it explicitly.
- **Corpus regeneration depends on the (gitignored, recycle-wiped)
  Flutter SDK:** acceptable — the corpus is tracked and
  sha256-pinned, the digest verifies, and regeneration only matters at
  generator-change time; the recorded quirk-20-hardened fetcher covers
  re-acquisition.

## Non-binding advisories

1. **Pin the CI Rust toolchain when the cargo-deny upgrade lands** (the
   recorded annex-trigger rule: the same commit as the first external
   dependency — likely N2's toolkit crate, not the core). The version
   echo makes the current drift visible, which is honest; a pin makes
   it reproducible. The "no new uses: lines" constraint was the entry
   gate's; the N2 gate can re-visit it.
2. **Fix the stale regen label:** fixtures/differential/README.md's
   regeneration block is headed "Regenerate (from `clearfile/`)" — the
   relocation residue; the command itself (`cd scripts; ../tools/
   flutter/…/dart …`) is correct and works. One-line doc fix.
3. **Record the Dart engine's reference-status transition** (one
   sentence, non-urgent): ADR-017's ADR-009 disposition says the Dart
   engine "remains the reference until the Rust core's fixture parity
   is green, then freezes to reference status" — the trigger condition
   is now met (17/17 + 550×26 exact parity). In practice this is a
   no-op (v1.x maintenance policy already governs: parameter
   corrections flow through the shared fixtures to all three
   runners), but a clarifying sentence in the next memory sync would
   prevent a future reader thinking new features may still land in the
   Dart engine.
4. **The honest-claims audit came back fully clean** (worth stating as
   a finding, not a formality): README's core/ and
   fixtures/differential/ rows and STATE's snapshot all matched reality
   under my own re-runs — 159/159, 550×26 with the D31c 26-key rule
   held per case, 17/17, the exact digest, 21 harness_check oks, zero
   overstatement found (README's "300 random + 250 edge" reconciles
   with the 246+4 class split). The N1 record discipline is a
   sustainability asset for the single maintainer.
