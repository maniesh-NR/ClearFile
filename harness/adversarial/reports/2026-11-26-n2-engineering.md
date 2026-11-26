# ADV-ENG — N2 delta gate (2026-11-26, Task N2-GATE-ENG)

VERDICT: PROCEED-WITH-CONDITIONS

Scope: the N2 delta proposal (Slint 1.19 consolidation; `apps/linux` as a
separate crate root; cargo-deny from first commit; D44's palette in
`core/src/palette.rs`; the MD3-themed Slint app + `--headless` CI smoke; the
one-session execution box). Adversarially re-verified with my own probes,
no repo modifications, no slint rebuild (the probe at `/tmp/n2-probe` was
inspected and its binary RUN — never rebuilt): the gtk3-rs infeasibility
(`pkg-config gtk+-3.0` ABSENT, uid 1001, no sudo), the xkbcommon wall (probe
runs under `Xvfb :99` → panics in `xkbcommon-dl-0.4.2`: "Library
libxkbcommon-x11.so could not be loaded" — the blocker is exactly as
claimed), the fromSeed reference chain (read from the pinned SDK tarball
itself), the workspace-topology claim (tested empirically with a scratch
workspace at `/tmp/ws-test`, since deleted), slint 1.19.1's MSRV and
license (read from the fetched crate manifest), and the disk state
(`df -h /`: **1.5G avail**, not ~4G — see condition 3).

What is sound, stated plainly: the Slint consolidation is ADR-sanctioned
verbatim ("may consolidate to one toolkit at the N2 entry gate if
single-maintainer reality demands it (revisitable, recorded)" —
`harness/memory/DECISIONS.md` ADR-017, Linux toolkits row, line 513), the
sandbox evidence is real, the direct-crate (no-FFI) Linux seam matches the
ADR-017 FFI row, the zero-dep posture of `core/` survives the topology
(core's lock is untouched by a consumer's separate root), the MCU reference
is pure Dart (no `dart:ui` — verified in the extracted package), so the
differential-generator pattern extends to the palette with integer parity
achievable at the same f64-discipline N1 already proved, and a headless
text mode + Xvfb window smoke is a reasonable CI shape. The flaws below are
correction-shaped, not architecture-shaped.

## Conditions

1. **The palette verification reference is mislabeled and its corpus is
   under-scoped: the reference is `material_color_utilities` 0.13.0 (the
   version `clearfile/pubspec.lock:283-290` resolves, hosted on pub; the
   SDK tarball preloads the identical
   `flutter/.pub-preload-cache/material_color_utilities-0.13.0.tar.gz`),
   not "material_color_utilities 3.47.9" (that is the Flutter SDK version),
   and `ColorScheme.fromSeed` in the pinned SDK builds a `DynamicScheme`
   (`SchemeTonalSpot` + a straight `MaterialDynamicColors.*.getArgb`
   pass-through — read live from the tarball's
   `flutter/packages/flutter/lib/src/material/color_scheme.dart:309-470`
   and `:2174-2191`), so "seed → the tonal palette channel values" alone
   cannot honestly support "the same visual language as the Flutter app":
   the corpus must pin the **scheme roles** (~50 ARGB values per seed per
   brightness: primary…tertiaryFixedVariant, error family, outline/s,
   surface/surfaceDim/Bright/ContainerLowest..Highest, onSurface*, inverse
   family, shadow, scrim, surfaceTint) for light AND dark, in addition to
   the tonal-palette tone ladders. Verification: the committed corpus (the
   app seed `0xFF00696E` from `clearfile/lib/main.dart:58` plus a
   deterministic seed sample) contains both layers, the core test asserts
   integer parity on both, and the tool either calls `ColorScheme.fromSeed`
   itself under `flutter test` or its role mapping is checked field-by-field
   against the SDK's `color_scheme.dart` mapping at generation time.

2. **The CI app lane must guard the rustc version fail-closed, not with the
   version-echo-only precedent** (`hygiene.yml:131-136`): slint 1.19.1
   declares `rust-version = "1.95"` (verified in
   `~/.cargo/registry/src/index.crates.io-*/slint-1.19.1/Cargo.toml`), the
   pinned `tools/rust` is 1.100.0 (satisfies it), but the runner's rustup is
   an unguarded unknown that drifts monthly, and an MSRV short-fall reds the
   build with no diagnosis. Verification: the new job parses `rustc
   --version` and asserts ≥ 1.95 fail-closed (or runs `rustup toolchain
   install 1.100.0` matching `scripts/rust_toolchain_manifest`) before any
   `cargo` call, and the first green run shows the guard executing.

3. **The execution session must reclaim disk as step 0 — free space is
   1.5G, not the ~4G the premise claims** (`df -h /`: 9.9G total, 85% used),
   because the proven probe's build tree alone is 3.7G
   (`/tmp/n2-probe/target`), and a full slint debug build of that shape
   needs ~3G+; additionally the probe's default features pulled
   `skia-safe/skia-bindings` (553-package lock), whose CDN-download of
   prebuilt skia binaries is what made the 1m33s number possible and what
   the app crate should drop. Verification: the session's first action
   deletes or quarantines `/tmp/n2-probe/target` and asserts ≥3G free
   before the first cargo invocation in `apps/linux`, and `apps/linux`'s
   dependency declares `slint = { version = "1.19", default-features =
   false, features = ["std", "backend-winit", "renderer-femtovg",
   "renderer-software", "compat-1-2", "accessibility"] }` (or equivalent),
   making the lock exclude skia.

4. **The one-session execution box is undersized against the repo's own
   precedent and must be re-cut to at least two execution sessions**:
   N1 spent two sessions on a smaller surface (159 tests, no GUI, no new
   CI lane) and still saw 3 of 5 parallel subagent lanes hit the context
   deadline (SESSION_LOG:1865), while N2 carries the palette port — HCT
   solver + CAM16 + viewing conditions + gamut mapping + `DynamicScheme`/
   `MaterialDynamicColors`, by inspection of the extracted MCU 0.13.0 the
   largest single numeric module in the core yet — plus the corpus and
   generator tool, plus a full GUI app (markup, state, file loading, error
   surfaces, headless mode), plus a new CI job, plus every guard update.
   Verification: the gate record fixes the box at two sessions (session 1 =
   palette module + corpus + tool + core tests + the `apps/linux` scaffold
   with all guard joins; session 2 = the window UI + headless mode + the CI
   lane + both smokes), with the parallel-lane plan citing the recorded
   timeout class.

5. **The window smoke must be bounded, self-terminating, and
   xauth-independent, because verified locally `xvfb-run` fails outright
   (no `xauth` on this image) while direct `Xvfb :99 &` + `DISPLAY=:99`
   reaches the real wall (the xkbcommon panic)**, and an unbounded window
   app hangs the CI job until timeout; GL under Xvfb on shared runners is
   the other flake source, and slint compiles the software renderer into
   the default probe already (`i-slint-renderer-software` in its lock).
   Verification: the smoke installs `libxkbcommon-x11` (plus nothing more —
   `Xvfb` is preinstalled), launches `Xvfb :99 &` directly (not `xvfb-run`),
   runs the app with a `--smoke` flag that constructs the real window,
   renders one frame, prints a marker, and exits 0 — under
   `SLINT_BACKEND=winit-software` (or with a documented GL fallback) — all
   inside a `timeout` with a non-zero exit asserted on failure.

6. **The headless CI smoke must assert content, not just exit status, and
   must not be a twin of the window path**: an exit-0 check cannot
   distinguish "computed" from "printed garbage," and a headless path that
   re-implements loading/compute drifts silently from the path the window
   paints. Verification: the smoke consumes a committed fixture and diffs
   the full stdout against a committed expected text (or its tracked
   digest), and the headless mode is structurally the SAME pipeline
   function the UI consumes (one `load_and_compute(path)`; verified by a
   test or by code identity in review).

7. **The crate-topology decision must be recorded as chosen-with-rejected-
   alternative, not as forced**: the standing claim ("a cargo workspace
   would break the core-scoped zero-dep CI assertion" — SESSION_LOG:1920)
   is true only of the assertion AS WRITTEN (hygiene.yml:114-118 greps
   `core/Cargo.lock`, which a workspace hoists to the root — grep then
   exits 2 and reds the step, fail-closed), but I verified empirically with
   a scratch workspace (`/tmp/ws-test`, since deleted: root lock with 2
   packages, no member lock) that a path-scoped rewrite — `cargo tree -p
   clearfile-core -e normal,build,dev --prefix none` yielding exactly one
   line — preserves the posture verbatim-equivalently, so separate roots is
   a legitimate choice (assertion stays byte-identical, the 553-package
   app lock never enters core's lane or history) that must be recorded as
   a decision with the workspace alternative named and rejected.
   Verification: the gate record (CONSENSUS + STATE) states the claim as
   "breaks the assertion as-written" and names the path-scoped alternative
   as considered-and-rejected, with separate roots chosen.

8. **The N2 delta must hold the N1 boundary discipline and join every
   guard BEFORE the closing backup**: no `clearfile/` or `src/` paths in
   the delta (the palette tool and corpus live tracked under `scripts/` +
   `fixtures/palette/`); `.gitignore` gains `/apps/linux/target/` (the
   exact class of the N1 note at the file's tail) BEFORE any cargo
   invocation in the app dir; if the corpus README carries a regeneration
   digest (the differential precedent, `fixtures/differential/README.md`),
   `scripts/sandbox_backup.sh:121-135`'s exclude lists must gain the new
   README path in the same commit; and `scripts/harness_check.sh` gains
   the palette-corpus ledger family (the mechanical-ledger precedent).
   Verification: `git diff --name-only` over the session shows zero
   `clearfile/`/`src/` paths, the closing backup runs green with the corpus
   tracked, and harness_check reports the new family green.

9. **cargo-deny needs a concrete mechanism and the slint license expression
   proven green in its first run**: the proposal names cargo-deny "from its
   first commit" without a mechanism, and the repo's CI posture ("no new
   uses: lines", `cargo install` compiles the tool every run) leaves the
   SHA-pinned action or a versioned prebuilt-binary download (the
   toolchain-fetcher posture) as the only sane options, while slint
   1.19.1's license is `GPL-3.0-only OR LicenseRef-Slint-Royalty-free-2.0
   OR LicenseRef-Slint-Software-3.0` (verified in its manifest), which a
   default deny.toml rejects as unallowed non-SPDX identifiers.
   Verification: the first commit's CI run shows `cargo deny check`
   (licenses, bans, advisories as configured) green on the 553-package lock
   with a deny.toml that allows the expression via its GPL-3.0-only leg and
   handles the LicenseRef terms explicitly, and the chosen install
   mechanism is recorded (action vs binary, with version pin).

10. **The working tree is NOT clean at gate time and the session must
    reset it before any edit** (`git status`: `package.json` modified —
    `@types/node` added, `@types/react`/`typescript` pinned — plus 225
    lines of `package-lock.json` churn; environment-side npm drift, not a
    repo change), because the closing mega-commit would otherwise absorb
    unrelated churn into the N2 delta — the exact class of the 2026-11-20
    mode-flip incident the ADR-018 context records. Verification: the
    session log records a `git status`/`git stash`-or-reset to the pushed
    tip `78a0213` as its first action, and the N2 delta's file list
    contains neither `package.json` nor `package-lock.json`.

## Risks register

- **R1 — palette port drift (highest):** the HCT tone solver and CAM16
  gamut mapping are the most numerically fiddly surface in the core; a
  subtle porting error yields plausibly-wrong colors only the corpus
  catches. Mitigation: condition 1's two-layer corpus at integer parity
  over a broad seed sample + the N1 f64-operation-order discipline; the
  Dart reference is pure Dart so the generator runs under plain `dart`
  with no engine bindings.
- **R2 — skia prebuilt CDN download:** if default features survive
  (rejected in condition 3), every CI build fetches a large opaque binary
  from the slint CDN — availability fragility plus an unverified
  supply-chain surface in the GPL tree.
- **R3 — per-push CI cost without caching:** the 553-crate cold build
  (~10–20 min + ~200MB source downloads, partially cached at 525M in
  `~/.cargo/registry` locally but cold on every runner) lands on every
  push to main unless the gate consciously accepts it or adds a SHA-pinned
  rust-cache action (a posture change to record).
- **R4 — window-smoke flakiness:** X/GL timing on shared runners is the
  classic flake source; the software-renderer fallback + bounded auto-quit
  + a single retry keep it defensible; if it still flakes, the honest
  de-scope is build+headless+instantiation checks, with the window
  evidence degrading to session-time manual runs — a visible claim
  downgrade, not a silent one.
- **R5 — reference-version coupling:** the corpus pins MCU 0.13.0 +
  Flutter 3.47.9's fromSeed; any future SDK bump regenerates the corpus
  (MCU 0.14+ changes fromSeed outputs). The regeneration rule (the
  differential corpus's byte-deterministic regen precedent) must be
  recorded before the first bump, and the core's scope stays
  `tonalSpot`/`contrastLevel 0.0` (the app's exact usage,
  `main.dart:62-64`) with other variants explicitly out of scope.
- **R6 — GUI-run evidence shape:** "local GUI run blocked only by
  libxkbcommon-x11" is verified true in this sandbox, but no local human
  has seen the window; the CI Xvfb smoke is the *only* automated window
  evidence — treat a later removal of that smoke as a claim downgrade.

## Advisories

- The consolidation evidence is stronger than the proposal states:
  slint with the software renderer has **no system-toolkit dependency at
  all** — arguably *more* viable on the RHEL-8/9-era older tier than
  gtk3-rs (which drags the system GTK version), so the ADR's older-tier
  rationale inverts in slint's favor; record that alongside the sandbox
  infeasibility.
- Prefer a NEW parallel job in `hygiene.yml` over appending to the
  `suites` job (timeout-minutes 45 at line 45, already serialized
  flutter+npm+cargo): the app lane's 10–20-min cold build does not belong
  on core's critical path, and a separate job keeps the no-new-uses
  posture cheap (runner rustup + apt-get only).
- The palette port derives from Apache-2.0 MCU source (license header
  verified in the extracted package): cheap and correct to add the
  attribution to `THIRD-PARTY-NOTICES.md` at port time rather than waiting
  for the annex's LICENSES-manifest-at-first-tagged-release trigger —
  LEGAL's lane should cross-check.
- "The container composition where applicable" is vague: pick the concrete
  input set (envelope primary; TXF and read-only `.tax` composition if
  claimed) and pin every claimed path in the condition-6 golden, else the
  demo can quietly shrink.
- The MCU 0.13.0 preload inside the SDK tarball gives the corpus generator
  an offline reference path if pub.dev fetch is ever a concern; either way
  the tool's pubspec pins 0.13.0 exactly (matching `clearfile`'s lock).
- The probe's build evidence stands: lock mtime 13:52:27 → binary
  13:55:02 (≈2m35s wall incl. the skia prebuilt download), binary runs to
  the verified xkbcommon wall; trimming features (condition 3) will make
  the app crate leaner than the probe, not heavier.
- `core/Cargo.toml` already carries `license = "GPL-3.0-only"` (line 6), so
  cargo-deny over the app lock resolves the path-dep clearfile-core
  cleanly — no unlicensed-flag surprise there.

## Files read (citations)

- `.github/workflows/hygiene.yml` (zero-dep assertion 112-123; core lane
  131-136; suites job 37-136; timeout 45; pages/release unread but listed)
- `core/Cargo.toml`, `core/src/lib.rs` (purity doc line 8, module layout)
- `clearfile/lib/main.dart:1-100` (seed 0xFF00696E at :58; fromSeed :62-64)
- `clearfile/pubspec.lock:283-290` (material_color_utilities 0.13.0 hosted)
- `harness/memory/DECISIONS.md` ADR-017 (495-573: boundary 510, FFI 511,
  toolkits 513, "lands a working app" 509, annexes 519-548)
- `harness/memory/ROADMAP.md` (547-638: N1 record 563-608, N2 bullet
  609-613, version-plane note 634-638)
- `harness/memory/DEBT.md:205-221` (D44 deferral text)
- `harness/memory/STATE.md:337-359` (N2 agenda incl. topology note)
- `harness/memory/SESSION_LOG.md:1860-1945` (timeout class 1865; workspace
  note 1920-1922; N1 exit record)
- `scripts/sandbox_backup.sh:95-165` (hex scan, excludes, *.lock exclusion)
- `scripts/fetch_flutter_sdk.sh` (pinned 3.47.9, sha256 manifest, resumable)
- `.gitignore` (tail: `/core/target/` N1 note), `THIRD-PARTY-NOTICES.md`
- `harness/adversarial/ROLES.md`, report-format precedent
  `harness/adversarial/reports/2026-11-26-n1exit-engineering.md`
- Probe `/tmp/n2-probe/` (Cargo.toml `slint="1.13"`→resolved 1.19.1; lock
  553 pkgs incl. skia/femtovg/software/linuxkms/testing backends; main.rs;
  binary RUN twice: no-DISPLAY error, then under `Xvfb :99` the
  xkbcommon-dl panic; target 3.7G)
- Flutter SDK tarball `tools/flutter_linux_3.47.9-stable.tar.xz` (paths
  listed; extracted & read:
  `flutter/packages/flutter/lib/src/material/color_scheme.dart` — fromSeed
  309-470, `_buildDynamicScheme` 2174-2191;
  `flutter/.pub-preload-cache/material_color_utilities-0.13.0.tar.gz` —
  extracted: `lib/{hct,dynamiccolor,scheme,palettes}` incl.
  `scheme_tonal_spot.dart`, `tonal_palette.dart`; no `dart:ui` imports;
  Apache-2.0 headers)
- `~/.cargo/registry/src/index.crates.io-*/slint-1.19.1/Cargo.toml`
  (`rust-version = "1.95"`, license with LicenseRef-Slint terms)
- Scratch workspace `/tmp/ws-test` (created, verified, deleted): root lock
  2 packages, `cargo tree -p clearfile-core` = exactly one line
- Live environment: `pkg-config` gtk+-3.0/gtk4 absent; `id -u` 1001; no
  sudo; `Xvfb` present; `xvfb-run` fails on missing `xauth`; `ldconfig`
  libxkbcommon.so.0 + libGL.so.1 present; `df -h /` 1.5G avail;
  `tools/rust/bin/{rustc,cargo}` 1.100.0; `git status` dirty on
  package.json/package-lock.json
