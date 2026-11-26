# ADV-LEGAL — N2 exit gate (2026-11-26, Task N2-EXIT-LEGAL)

VERDICT: PROCEED-WITH-CONDITIONS (6 conditions)

The N2 delta (d227bc7..7f18fa2, 24 files, two sessions exactly as boxed) is
reviewed against my lane's eight entry-gate conditions (all of which map into
the consolidated 13-point ledger) plus the exit checklist. The licensing spine
is sound and verified live where verification is possible offline: the Slint
GPL-3.0-only election is recorded in-tree in the same commit as the first
dependency; the cargo-deny config is the exact closed allow-list shape ordered
(with the LicenseRef ids absent); the MCU notices entry is substantively
accurate Apache-2.0 derivative-work attribution; the app's demo disclaimer is
the same facts as the Flutter app (two sentences verbatim); the no-network
claim is TRUE as worded; the manifest deferral is the recorded rule and
nothing was shipped, tagged, version-moved, or uploaded. The gaps are all
record-keeping honesty items, each a one-line/one-commit discharge.

**Verification log (evidence actually pulled, all live 2026-11-26, read-only).**

Records read first: `harness/adversarial/CONSENSUS.md` l.1207–1363 (the N2
gate record: the consolidated 13-point ledger; my lane = items 6, 10, 11
principally, 12 as observer); my own N2-delta report
`harness/adversarial/reports/2026-11-26-n2-legal.md` (all 8 conditions
re-read); `harness/memory/SESSION_LOG.md` l.1990–2119 (the N2 session-1
checkpoint/close + session-2 checkpoint/close entries, incl. the exit
checklist); `PROJECT_MEMORY.md`'s 7f18fa2/37f1a5c/39bdc22/69c8dda entries;
`harness/memory/ROADMAP.md` l.609–633 (the consolidation + topology recorded
with reasons, forfeit, and revisitability — LEGAL-1's discharge verified);
`harness/memory/DECISIONS.md` ADR-017 (l.495–573 re-read: the licensing annex
l.537–548, the v2.0.0 rule, the manifest sentence). The delta file list
pulled (git diff --name-only d227bc7..7f18fa2) and every licensing-relevant
file read in full or header-swept:

- **SPDX sweep (LEGAL-2):** `apps/linux/Cargo.toml`, `build.rs`, `deny.toml`,
  `src/main.rs` (598 lines, full read), `ui/app.slint` (331 lines, full
  read) — all line-1 `SPDX-License-Identifier: GPL-3.0-only`.
  `core/src/palette.rs` (2038 lines; header + 165 per-item Dart-source
  citations), `core/tests/palette_port.rs`,
  `scripts/palette_tool/pubspec.yaml`,
  `scripts/palette_tool/test/generate_palette_fixtures.dart` — header
  present. Modified core files (`json.rs`, `lib.rs`, `tax_inspect.rs`,
  `core/tests/tax_inspect_port.rs`) retain their headers. No-header files,
  each convention-checked: `apps/linux/Cargo.lock` +
  `scripts/palette_tool/pubspec.lock` (the generated-lockfile convention,
  excepted by the condition's own sentence); `fixtures/palette/cases.json`
  (JSON data — strict JSON admits no comment; the
  `fixtures/differential/cases.json` + `fixtures/migration/*.json`
  precedent); `fixtures/palette/README.md` (no README in this repo carries
  SPDX — root `README.md` + `fixtures/differential/README.md` precedent);
  and `apps/linux/tests/expected-headless.txt` — a byte-pinned
  expected-stdout artifact under `apps/linux/` whose bytes ARE its contract
  (a header would break the full-stdout diff + the byte-equality unit test);
  NOT one of the condition's recorded exceptions → condition 5.
- **The election (LEGAL-3):** `deny.toml` l.5–14 records it exactly — the
  project consumes the slint crates under their **GPL-3.0-only branch
  only**, the royalty-free/commercial branches (attribution-badge terms)
  NOT elected, the two LicenseRef ids deliberately ABSENT from the
  allow-list with any LicenseRef-only crate routed to a per-crate exception
  with a recorded reason; `Cargo.toml` `license = "GPL-3.0-only"` +
  `publish = false`; both landed in the same commit as the first slint
  dependency (39bdc22, per the commit record). The pinned 1.19 series is
  recorded adjacent (`Cargo.toml` "the audited 1.19 series", `build.rs`,
  `hygiene.yml` "slint 1.19.1's declared MSRV"); the election comment itself
  does not name 1.19 (advisory 1).
- **The allow-list shape (LEGAL-4 / ledger 6):** closed v2 semantics
  (`version = 2`); `allow` = exactly 11 ids — GPL-3.0-only, MIT, Apache-2.0,
  BSD-2-Clause, BSD-3-Clause, ISC, Zlib, Unicode-3.0, Unicode-DFS-2016,
  0BSD, CC0-1.0; `GPL-3.0-only` exactly (not the deprecated `GPL-3.0`, the
  pedantic note at l.31); `LicenseRef-Slint-*` grep-confirmed absent from
  the allow-list (appears only inside the election comment, as prose);
  sources: `allow-registry = crates.io-index` only, unknown-registry/git
  deny; advisories `yanked = "deny"`; bans `wildcards = "deny"`; no
  `[graph]`/targets restriction — the full lockfile is covered incl. the
  target-gated families and the build-dep tree (`slint-build` is in the
  committed lock) — the stronger of the two readings of ledger item 6, as
  its final sentence requires. No pre-added `exceptions` (no global
  widening).
- **The mechanism (LEGAL-5):** `hygiene.yml` l.154–221 — the new Linux-app
  job: the rustc ≥ 1.95 fail-closed guard first, every cargo invocation
  `--locked` against the committed 539-name lock, the headless diff smoke,
  the window smoke (apt libxkbcommon-x11 + DIRECT Xvfb :99 +
  SLINT_BACKEND=winit-software + `timeout` with failure asserted), and
  cargo-deny via `EmbarkStudios/cargo-deny-action@81891abc19297b21343b15ef67dc61e4aea74fda
  # v2.1.4` — SHA-pinned per D10, the recorded two-mechanism choice (a).
  Zero `upload-artifact` anywhere in hygiene.yml (grep over
  `.github/workflows/`: uploads exist only in `release.yml`, which the delta
  does not touch). cargo-deny is NOT installed in this sandbox, and no
  in-tree record shows any CI run on the N2 delta commits (the last
  recorded runs are #28–#31, all N1) — the first-run live-green element of
  LEGAL-5 is therefore NOT yet evidenced → condition 4.
- **THIRD-PARTY-NOTICES.md (LEGAL-6):** the MCU entry read in full. Its
  substance is accurate: the translation/derivative-work framing is
  correct ("a translation — a derivative work, derived not vendored; no
  Google code text is copied" — matches the port's actual shape: a Rust
  translation with 165 per-item Dart-source citations, math/order
  preserved, no code text vendored); version 0.13.0 + pub.dev + Apache-2.0
  + the one-way GPL-3.0-compatibility statement + the license-text URL;
  the corpus cross-reference; landed in the same commit as the port
  (69c8dda). Missing vs LEGAL-6's own checklist ("names upstream + version
  + copyright"; "no NOTICE file upstream"): the `Copyright 2021 Google LLC`
  line and the no-NOTICE-file note are absent (the upstream archive has no
  NOTICE file — verified at the entry gate) → condition 3. No Slint row
  (the unadopted entry-gate advisory — advisory 2).
- **The corpus provenance (LEGAL-7):** `fixtures/palette/README.md` read in
  full. MCU **0.13.0** + content hash
  `9c337007e82b1889149c82ed242ed1cb24a66044e30979c44912381e9be4c48b`
  verified live against BOTH `clearfile/pubspec.lock` AND the scratch
  `scripts/palette_tool/pubspec.lock` (identical sha256 + version — the
  README's own check command executed); the "NOT '3.47.9'; that is the
  Flutter SDK version" mislabel correction recorded; the
  differential-contract distinction stated exactly as required ("These are
  NOT golden fixtures (the annex-(d) authoring discipline applies to
  `fixtures/tax/`): every expected value is the reference implementation's
  own output"); the corpus digest
  `da1ceaf4b37f1ac851fcef7fde0833c7c90d746842986c1a14737177ef3252b7`
  verified live (`sha256sum fixtures/palette/cases.json` — byte-identical
  match to the README's recorded value); the regeneration instructions +
  the scratch-lock hash discipline; the generator header (read) states the
  app's-exact-API provenance (ColorScheme.fromSeed via the scratch
  package, no reimplementation) + the D43-differential framing; the corpus
  carries inline `generator`/`reference` provenance fields. The recorded
  post-divergence regeneration proof (SESSION_LOG: the corpus regenerated
  after the fifth snapshot divergence with the digest matching exactly)
  is the standing evidence for "regenerating reproduces the digest".
- **The disclaimers (LEGAL-8 / ledger 11):** `ui/app.slint` About area —
  "ClearFile prepares a simplified 2025 US federal return for study and
  demonstration. It is not IRS-authorized, cannot e-file, and must not be
  used to file a real tax return." — the first two sentences are VERBATIM
  from `clearfile/lib/ui/screens/welcome.dart` l.97–99 (read and compared),
  plus the qualified-professional extension: same facts, platform-idiomatic
  wording — discharged. Prototype labeling: window title, header subtitle,
  About title, and the headless header line all carry it. The AI-absence /
  no-network note is present in-window. The D12 AI privacy disclosure is
  correctly NOT imported (no disclosure.dart strings anywhere in the app —
  full read of main.rs + app.slint). The core's `.tax` non-affiliation
  wording (tax_inspect.rs l.101–169, read) flows verbatim through
  `container_error`/the warnings; the About non-affiliation line is a new,
  accurate general statement (fact-family consistent). The headless text
  mode's footer carries only "Demonstration prototype — not tax advice;
  check with a qualified tax professional." — the three demo-disclaimer
  facts are absent from the results-printing surface → condition 2. The
  README apps/linux row is absent entirely (README.md not in the delta;
  grep-verified: zero mentions of slint/native/apps) → condition 1.
- **The no-network claim verified TRUE:** `main.rs` (full read): the only
  I/O is `std::fs::read` (+ temp writes in tests only); no networking code;
  `app.slint` (full read): no URL/callback surfaces; `clearfile-core`:
  pure std, zero deps. The committed lock (510 unique package names):
  zero `reqwest`/`hyper`/`ureq`/`curl`/`openssl`/`native-tls`/`rustls`.
  Reverse-dependency analysis over the lock: `webbrowser` ←
  `i-slint-backend-winit` only (it opens the system browser — it makes no
  network connections itself — and NO code path reaches it: no
  `slint::open_url`, no URL in the markup); `tokio` ← `wasm-bindgen-futures`
  only (wasm-target-gated; not linked into the Linux binary); `zbus` ←
  `accesskit_unix`/`atspi-*` + `i-slint-backend-winit` (D-Bus — a local
  unix-socket IPC, the accessibility bridge). The honest precision: the
  window necessarily talks to the user's local display server
  (X11/Wayland socket) and, via the accessibility feature, the local atspi
  session bus — local IPC, standard for any GUI, nothing leaves the
  machine; the in-window claim as worded ("makes no network connections,
  stores no keys, and sends no data anywhere") is TRUE. The app writes no
  files at all in shipped behavior ("stores no keys" — TRUE).
- **The manifest timing (LEGAL-8's second half):** `release.yml` NOT in
  the delta (nothing there could ship anything); `core/Cargo.toml` +
  `package.json` NOT in the delta (no version movement — the v2.0.0 rule
  intact: v2.0.0 is earned only at the first GA whose distributed artifact
  is the native stack); `apps/linux` 0.1.0 is a new `publish = false`
  crate's initial version, not a shipped plane; no tag or release event in
  any N2 SESSION_LOG entry; the new CI job uploads nothing (no conveyance
  — Actions artifacts on a public repo being the conveyance surface
  LEGAL-8 guards). The ADR-017 l.545 manifest rule (first tagged release)
  holds with nothing to manifest yet.
- **Guard joins (adjacent, verified):** `scripts/sandbox_backup.sh`'s
  exclude lists carry the three palette-provenance files
  (`fixtures/palette/README.md`, `fixtures/palette/cases.json`, the
  generator) — the sixth/seventh/eighth known-hash instances as recorded.

## Conditions (numbered, checkable)

1. **The README's honest apps/linux row (ledger item 11, LEGAL-4/PROD-4)
   did not land.** `README.md` (299 lines) is absent from the delta;
   grep-verified: zero mentions of `apps`, `slint`, or a native/Linux-app
   row. Add the honest row (prototype status; Slint under the recorded
   GPL-3.0-only election; unreleased — no manifest, no downloadable
   artifact; the one shared pipeline over clearfile-core; the demo +
   no-AI/no-network posture) and, in the same pass, extend the `core/`
   row with the palette module (D44) so the table stays accurate.
   *Check:* `grep -n "apps/linux" README.md` returns the row; the row
   states the unreleased/prototype status honestly.
2. **The headless text mode's disclaimer does not carry the three
   demo-disclaimer facts** (LEGAL-8's letter: "any results-printing
   headless mode carries the demo-disclaimer facts"). `text_summary`'s
   footer says "Demonstration prototype — not tax advice; check with a
   qualified tax professional." — add the three facts (not
   IRS-authorized; cannot e-file; must not be used to file a real return
   — platform-idiomatic wording, same fact family as welcome.dart),
   regenerate `tests/expected-headless.txt` from the actual output, keep
   the byte-test green. *Check:* both the `--headless` stdout and the
   committed expected text carry the three facts; `cargo test --locked`
   on apps/linux green (currently 5/5).
3. **The palette provenance is missing two elements of LEGAL-6's own
   checklist** ("the doc-comment names upstream + version + copyright";
   the entry's "no NOTICE file upstream" note). Add `Copyright 2021
   Google LLC` to `core/src/palette.rs`'s provenance doc-comment (or the
   notices entry) and the one-line "no NOTICE file upstream (verified at
   the N2 gate)" note to the THIRD-PARTY-NOTICES.md entry.
   *Check:* `grep -n "Copyright 2021 Google LLC" core/src/palette.rs
   THIRD-PARTY-NOTICES.md` non-empty; the entry still states
   derived-not-vendored with the version + license.
4. **The cargo-deny first-run live-green run is not evidenced in-tree**
   (LEGAL-5: "its first run is live-verified green with the Slint crates
   present — the OR/LicenseRef satisfaction path is the one behavior to
   prove, not assume"). cargo-deny is not installed in this sandbox; the
   last recorded CI runs are #28–#31 (all N1). Verify the pushed tip's
   Actions run (the Linux-app job, incl. the cargo-deny step over the
   committed 539-name lock) is green and record the run number in the
   gate-close bookkeeping. *Check:* a green run on 7f18fa2 (or the
   gate-close backup commit) covering the new job is cited in
   SESSION_LOG/STATE.
5. **`apps/linux/tests/expected-headless.txt` has no SPDX header and is
   not covered by LEGAL-2's recorded exception** (the condition binds
   "every new tracked file under apps/linux/", excepting only generated
   Cargo.lock). The file's bytes are pinned by the full-stdout diff + the
   byte-equality test — a header would break its contract, so the honest
   fix is bookkeeping, not a header: extend the recorded no-header
   generated-artifact convention (D14's policy line or the gate record)
   to byte-pinned expected-output artifacts. Do NOT add a header to the
   file. *Check:* the recorded policy names the class; an SPDX sweep over
   tracked apps/linux files returns only the recorded exceptions
   (Cargo.lock, expected-headless.txt).
6. **This report joins the backup known-hash allow-list.** The
   verification log above cites the two 64-hex provenance digests
   (da1ceaf4…, 9c337007…) as evidence, in the exact class of the
   fourth/fifth instances (the N1-exit reports); reports are never edited
   after filing per ROLES.md, so the gate-close commit must add
   `harness/adversarial/reports/2026-11-26-n2exit-legal.md` to
   `scripts/sandbox_backup.sh`'s exclude lists (both scans) or the next
   backup refuses. *Check:* the backup run after the gate close passes
   with this report tracked.

## Risks register

(a) **Apache-2.0 §4.1 at first conveyance:** the notices entry links the
   license text (while the MIT entry reproduces its text — an asymmetry to
   resolve); the first Linux LICENSES manifest must bundle the full
   Apache-2.0 text + the palette provenance + (if it survives link-time
   analysis) the webbrowser note below. (b) **The no-network claim's
   precision:** local display-server/atspi sockets are standard GUI IPC
   (nothing leaves the machine — the claim is TRUE as worded); any future
   network-adjacent feature (update check, telemetry, font fetch) must
   change the in-window note in the same commit or the surface goes
   dishonest — the D12 single-source discipline applied to the absence
   note. (c) **`webbrowser` rides the lock** via i-slint-backend-winit;
   unreachable today (verified); keep it uncallable and describe the
   linked-but-unused surface honestly in the eventual manifest. (d)
   **cargo-deny semantics drift** (carried): the closed-allow-list OR
   satisfaction is documented but version-sensitive; the CI run
   (condition 4) is the standing tripwire; the core's zero-dep assertion
   is the second layer. (e) **The two-MD3-statements discipline**
   (carried): the design language is unprotectable while Google's palette
   CODE is protected expression riding the Apache-2.0 path — the notices
   entry is what keeps both statements true; keep it with any palette
   evolution. (f) **GPL §6 release-body sentence at first native
   release** (carried): extend "the tagged public commit" with "plus the
   exact crate versions pinned in Cargo.lock, sources available from
   crates.io". (g) **STATE.md's "Immediately next" tail still reads
   pre-N2-gate** while its header says session-1 closed (both in the
   delta) — the gate-close bookkeeping should refresh it (observed;
   PROD-adjacent).

## Non-binding advisories

1. Make the deny.toml election comment self-contained: name the pinned
   1.19 series in the comment itself (the version is currently recorded
   only in the adjacent Cargo.toml/build.rs/CI comments).
2. The one-line THIRD-PARTY-NOTICES.md Slint row (the unadopted entry-gate
   advisory): election + pinned version + crates.io provenance — cheaper
   now than at manifest time, and the natural home for the version note.
3. Condition 2's regenerated footer is the natural place for a text-mode
   AI-absence line if one is wanted (optional; the three demo facts are
   the required element).
4. Keep the window and headless wordings in the same fact family as the
   row builders already implement — one source per fact.
5. Keep the corpus's "unprotectable generated facts" framing and the
   regeneration/hash-check discipline exactly as landed; the recorded
   post-divergence byte-identical regeneration is the proof pattern to
   repeat.
6. The Stage-2 slip re-agenda (T3 keystream chase / tax-modern.md /
   RE-protocol namespace rule) rides with this gate per the standing
   record — surface the owner's three options (fund T3 / supersede the
   namespace rule / default re-agenda) rather than defaulting silently.

**Summary:** The N2 delta's licensing substance exits clean: the
consolidation + topology are recorded (ROADMAP), the Slint GPL-3.0-only
election + `publish = false` landed same-commit with the first dependency,
deny.toml is the exact closed 11-id GPL-3.0-compatible allow-list with the
LicenseRef ids deliberately absent and full-lock coverage, the MCU 0.13.0
notices entry is substantively accurate derivative-work attribution, the
demo disclaimer is the Flutter app's own facts (two sentences verbatim) with
the no-network claim verified TRUE against the entire app + lock, and the
manifest deferral is the recorded rule with nothing shipped, tagged,
version-moved, or uploaded. Six checkable conditions remain — all
record-keeping honesty items (the README row, the headless disclaimer
facts, the upstream copyright line + no-NOTICE note, the cargo-deny
first-green-run evidence, the expected-artifact SPDX exception bookkeeping,
and this report's backup allow-list join) — none block-worthy for an
unreleased prototype, all one-commit discharges.
