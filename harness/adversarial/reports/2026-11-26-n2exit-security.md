# ADV-SEC — N2 exit gate (2026-11-26, Task N2-EXIT-SEC)

Reviewer: ADV-SEC (secrets/CI-CD/supply chain/untrusted-input surfaces + the
gate's condition-9 hardening and guard-join verification). Delta under review:
`d227bc7..7f18fa2` (the whole N2 delta — the palette module + corpus, the
apps/linux scaffold, the window app, the CI lane, the R1/R2 parser hardenings).
Tip `7f18fa2`, tree **clean** (`git status --porcelain` → empty; no dirty
memory files), `HEAD == origin/main` (both sessions' work is pushed, so the
hygiene run has triggered on the tip). Read first, as instructed: CONSENSUS's
N2 gate record (the 13-point condition ledger + the two-session box) and the
N2 SESSION_LOG tail (the four N2 entries). Scope note: the sibling N2-exit
reports (LEGAL/ENG/PROD) were neither read nor written.

**VERDICT: PROCEED-WITH-CONDITIONS**

The delta is security-clean in substance: both registered parser risks are
closed in substance with fail-closed caps and battery extensions, the CI lane
lands with the recorded posture (SHA-pinned actions, least-privilege
permissions, fail-closed MSRV guard, `--locked` everywhere), the supply chain
is 100% crates.io-pinned and license-allow-listed, every guard join landed,
and the token/hex sweep of all 33,108 added lines found zero token-shaped
content and every hex-shaped string accounted for. The three conditions are
record-accuracy and live-verification items, not code defects.

## Conditions (3)

1. **The "539-package lock" figure in the session-2 records is stale — the
   committed lock has 549.** The slint-build addition regenerated
   `apps/linux/Cargo.lock` (+10 build-time crates: crossbeam-deque,
   crossbeam-epoch, lazy_static, natord, rayon, rayon-core, rspolib,
   slint-build, snafu, snafu-derive — verified: the lock is unchanged in
   `37f1a5c..7f18fa2`, and `39bdc22..7f18fa2` adds exactly those entries, no
   version bumps), but the 37f1a5c backup note, the 7f18fa2 backup note, and
   SESSION_LOG's session-2 entries all still say "the committed 539-package
   lock". Amend the recorded count so the audit trail matches the tree —
   checkable: the recorded number equals
   `grep -c '^\[\[package\]\]' apps/linux/Cargo.lock` (549 today).
2. **The gate's own cargo-deny posture ("the first run live-verified green")
   is not yet recorded as discharged.** The session-2 close says only
   "cargo-deny green-configured", and no green hygiene run over the tip is
   recorded anywhere I can read (the N1 precedent recorded run numbers and
   SHAs; the N2 session-2 record does not). Verify the live hygiene run on
   `7f18fa2` is green across all six jobs — in the linux-app job specifically:
   the MSRV guard ok, the app tests, the headless byte-diff, the window smoke
   marker, and the cargo-deny step — and, from that run's log, that
   cargo-deny actually consumed `apps/linux/deny.toml` (the action runs from
   the repo root against `manifest-path: apps/linux/Cargo.toml`; no other
   deny.toml exists in the tree, and both mis-discovery failure modes are RED
   — a default allow-list would fail the GPL-3.0-only slint crates, and a
   missing-config error is red — so only a green run proves discovery), then
   record the run (URL/number) in the gate record — checkable: a green
   linux-app job on the Actions run for `7f18fa2` with the deny.toml
   allow-list in effect.
3. **The recorded skia posture is imprecise in a way that would mislead a
   future auditor.** The gate record says "the skia-safe CDN prebuilts are
   EXCLUDED from the lock" and the Cargo.toml comment says "skia EXCLUDED",
   but `skia-safe` 0.157.0, `skia-bindings` 0.157.0, `i-slint-renderer-skia`,
   and two `tiny-skia` **package entries** are in the committed lock as
   unactivated optional dependencies of `i-slint-backend-winit` (present
   since the session-1 lock — `git show 39bdc22:apps/linux/Cargo.lock`
   contains them). The security-relevant property HOLDS — `renderer-skia` is
   feature-off in the app's dependency set, so these crates are never
   compiled, and the skia-bindings build script (the CDN prebuilt download)
   never runs — but the record should say "excluded from the BUILD, present
   in the LOCK as unactivated optional entries (covered by cargo-deny's
   full-lockfile check)". Amend the wording where the posture is cited —
   checkable: `grep -n 'skia' apps/linux/Cargo.lock` (11 hits) against the
   amended sentence; zero code change.

## Risks register

1. **JSON duplicate-key residual amplification (bounded, registered, not
   introduced).** The member cap closes the registered quadratic-insertion
   risk in substance — the 10,001st NEW member is refused (worst-case
   bounded-object insertion is ~5×10⁷ comparisons, sub-second, down from the
   measured 80,000-keys ≈ 26.8 s) — but the duplicate-key count is
   deliberately unbounded ("duplicates never grow the member count, so they
   never trip it"), and each duplicate still linearly scans the member
   vector: with 10,000 crafted long-common-prefix keys, an attacker's input
   is multiplied by ≤ MAX_OBJECT_MEMBERS (≈10⁴ byte-compares per input byte),
   so a GB-scale crafted `.clearfile.json` can still stall the pipeline for
   tens of seconds. This is the same finding the N1-exit gate registered,
   now bounded instead of unbounded; low severity for a local single-user
   prototype. Candidate closure before any FFI wiring (the N1-exit framing):
   a duplicate-key count cap, or an order-preserving index after a size
   threshold.
2. **Unbounded pre-read before any cap engages.** `load_and_compute` does
   `std::fs::read(path)` — the whole file into RAM — before the parsers'
   caps are reached (both routes: envelope and container), so a multi-GB file
   is fully read (OOM/hang) regardless of the 10,000-member and 256-MiB
   caps. Low severity (a local app opening a user-chosen file); candidate
   closure: an honest file-size pre-check (e.g. refuse >512 MiB with a named
   message in the core's wording family) in the app's pipeline.
3. **The 10 session-2-added crates carry no recorded hand license audit.**
   The N2 gate's license audit ran over the 553-package probe tree (with
   skia), and the session-1 lock was 539; the +10 slint-build compiler tree
   was never hand-audited — the fail-closed cargo-deny lane over the full
   549-package lock (condition 2's live-green run) is the only mechanism
   covering them. Nothing observed suggests a problem (all crates.io-sourced,
   plausible slint-compiler dependencies), and condition 2 discharges the gap
   mechanically; registered so the gap is explicit rather than implicit.

## Advisories (non-binding)

1. The cargo-deny-action SHA↔tag mapping (`81891abc19…74fda` = v2.1.4) could
   not be independently re-verified from this sandbox (GitHub API
   unauthenticated rate-limited on both egress IPs). The session-2 record
   claims the live resolution, and the pin's security property — a full
   40-hex commit SHA, not a mutable tag — holds regardless of the label;
   condition 2's green run corroborates (the action's banner names its
   cargo-deny 0.22.1). No action required beyond condition 2.
2. The window smoke's `sudo apt-get install -y libxkbcommon-x11` is unpinned
   (runner-image drift; Ubuntu-archive trust). Acceptable for a smoke-only
   runtime X11 library that is not a build input; `bash -e` makes an
   apt failure fail the step (fail-closed). Record-keeping nit only.
3. This report cites every digest in truncated form (`81891abc19…74fda`,
   `da1ceaf4…52b7`, `9c337007…c48b`) deliberately: ≥32 contiguous hex in a
   `harness/` file trips the backup guard's known-hash refusal, and this
   report is not on the allow-list. If full-digest citations are preferred
   (the N1-exit precedent — reports are immutable after filing), add this
   report to the allow-list in the same commit it lands; otherwise nothing
   to do.
4. The rustc MSRV guard protects only the linux-app job; the core job (and
   the app job's transitive core build) still run on the runner's default
   rustup toolchain — the pre-existing N1 posture, unchanged by this delta,
   and negligible for the zero-dependency core. Noted for completeness.

## Verified (evidence — what was read/run, read-only; nothing modified, nothing installed)

1. **Tree + push state:** `git status --porcelain` → empty (clean; no dirty
   memory files to note); `git rev-parse HEAD` = `origin/main` = `7f18fa2`
   (both sessions pushed; the hygiene run has triggered on the tip).
2. **Backup-guard replication:** the guard's three scans were re-run verbatim
   against the staged index (TOKEN_PATTERNS over all files; 64-hex text-only
   with the recorded excludes; ≥32-hex over
   `docs clearfile src scripts fixtures harness core apps` with the recorded
   excludes) → **HITS empty** — the guard passes the tip exactly as
   committed, and `apps` is confirmed in the ≥32-hex scan path list (the
   condition-9 join).
3. **Guard joins:** `.gitignore` carries `/apps/linux/target/` (landed in the
   scaffold commit 39bdc22, before the first app build in session 2, per the
   guard-order comment and the commit order); the known-hash allow-list
   carries the palette instances (fixtures/palette/README.md, cases.json,
   the generator) alongside the five prior instances; the palette-corpus
   ledger + scaffold-presence families are in harness_check.sh (+39 lines);
   `scripts/sandbox_backup.sh`'s N2 delta is only the `apps` scan-path join
   + the palette allow-list excludes.
4. **Token/hex sweep of the delta:** all 33,108 added lines of
   `d227bc7..7f18fa2` grepped → **zero TOKEN_PATTERNS hits**; every ≥32-hex
   hit accounted for: 547 Cargo.lock sha256 checksums + 21 palette_tool
   pubspec.lock checksums (lockfile classes, excluded by design), 3 in
   hygiene.yml (the 40-hex action pins — outside the ≥32-hex scan's path
   list and not 64-hex in any case), and 5 on the three allow-listed
   palette-provenance paths (the corpus digest + the MCU 0.13.0 content
   hash, the latter byte-equal across README, cases.json, and the generator).
5. **Variant preconditions:** `git diff --name-only d227bc7..7f18fa2` → 26
   files, all under apps/linux/, core/, scripts/, fixtures/palette/,
   harness/, .github/, .gitignore, THIRD-PARTY-NOTICES.md, PROJECT_MEMORY.md
   — zero `clearfile/` paths, zero `src/` paths, no release.yml change, no
   version movement; hygiene.yml's delta is **purely additive** (no removed
   lines — the existing jobs byte-identical, as recorded).
6. **The caps landed as recorded (condition 9, in substance):** json.rs
   `MAX_OBJECT_MEMBERS = 10_000`, `JsonError::TooManyMembers` raised only in
   the new-member branch of `parse_object` (read in full — duplicates
   replace in place and never grow the count, so they never trip it), with
   the battery pair: 10,001 members → the named error with the exact
   offset/count, and exactly 10,000 parses. tax_inspect.rs
   `MAX_STORED_EXTRACTION_BYTES = 256 MiB`, checked BEFORE extraction with
   the honest stop-note (the analysis path never errors, never panics; the
   writer untouched), with the battery pair: 257×1 MiB STORE entries stop
   the walk at 256 MiB with the exact note (256 listed entries), and the
   just-under-cap twin (2×100 MiB) extracts fully with no note. Both file
   deltas vs `d227bc7` are purely additive — no existing hardening weakened
   (the 128-depth limit, EOCD scan window, 4,096-entry cap, ENG-1 name
   guard, and the Dart-only local-header check all intact in source).
7. **Supply chain:** `apps/linux/Cargo.lock` = 549 `[[package]]` entries —
   547 `source = "registry+https://github.com/rust-lang/crates.io-index"` +
   `clearfile-core` (path dep) + `clearfile-linux` (root); zero git or other
   sources; the session-2 lock delta vs 39bdc22 is exactly the 10 added
   compiler-tree crates (no version bumps); slint/slint-build/slint-macros
   pinned at 1.19.1 (the audited series; the MSRV guard's ≥1.95 target).
   `deny.toml`: the closed 11-id allow-list exactly as the gate condition
   specifies (GPL-3.0-only spelled GNU-pedantically, NOT the deprecated
   GPL-3.0; MIT, Apache-2.0, BSD-2/3-Clause, ISC, Zlib, Unicode-3.0,
   Unicode-DFS-2016, 0BSD, CC0-1.0), the LicenseRef ids deliberately
   absent with the GPL-3.0-only election comment, sources crates.io-only
   (unknown-registry/unknown-git deny, allow-git empty), yanked deny,
   wildcards deny, private ignore, confidence 0.93. `build.rs` is the
   standard slint-build compile, nothing else.
8. **CI lane:** the rustc guard is fail-closed (numeric validation of
   major/minor with named errors on unparsable output; refuses < 1.95 with
   the reason; runs FIRST in the job); every cargo invocation is `--locked`
   with the committed lock; the headless smoke diffs full stdout against the
   committed expected text (verified consistent — the expected file records
   the repo-root-relative path the CI passes); the window smoke runs DIRECT
   `Xvfb :99 &` + `SLINT_BACKEND=winit-software` + `timeout 60` with failure
   asserted, Xvfb killed on both paths, the full output printed on failure,
   and the `window-smoke-ok` marker grepped; the 60-second timeout covers
   execution only — the earlier test + headless steps have already built the
   debug tree, so the smoke run rebuilds nothing (ordering read and
   verified); `permissions: contents: read` at workflow AND job level;
   `timeout-minutes: 45`; no `secrets.*` anywhere in the linux-app job; all
   `uses:` pins in the file are full-SHA (checkout v4.4.0 at
   `11d5960a…262`, unchanged in the other jobs).
9. **argv/file-reading surface:** main.rs's argv handling is mode-selection
   only (`--headless <path>` / `--smoke` / a bare path / no argument; usage
   errors exit 2) — no shell, no eval, no network, no process spawning, and
   the only filesystem access is the single read of the user-given path; the
   untrusted path flows `std::fs::read` → the content-first ZIP-signature
   dispatch (mirroring the core's `looks_zip`; the extension reported, never
   trusted) → the core's now-hardened parsers, and every failure is a named
   message in the core's wording family; the ONE shared `load_and_compute`
   is the only file-to-result path (window, headless, and the tests all call
   it — all three call sites read); the smoke path is bounded (300 ms
   single-shot timer). The in-app honesty claims ("no network connections,
   stores no keys, sends no data") hold against both main.rs and app.slint
   (read; no network/key code exists in the app).

## Files read

- `harness/adversarial/CONSENSUS.md` (the N2 gate record, lines 1207–1363:
  the 13-point ledger + the two-session box + the disk plan)
- `harness/memory/SESSION_LOG.md` (the four N2 entries, lines 1990–2119)
- `.github/workflows/hygiene.yml` (all 250 lines)
- `apps/linux/src/main.rs` (all 597 lines incl. the 5 unit tests),
  `apps/linux/Cargo.toml`, `apps/linux/deny.toml`, `apps/linux/build.rs`,
  `apps/linux/ui/app.slint` (honesty-surface + structure pass),
  `apps/linux/tests/expected-headless.txt`
- `apps/linux/Cargo.lock` (structural: package count, source lines, the
  slint/skia entries, the session-2 additions, checksum classes — not
  line-by-line)
- `core/src/json.rs` (module docs, error enum, parse_value/parse_object, the
  cap tests), `core/src/tax_inspect.rs` (module docs, constants,
  read_zip_directory, the cap; writer headers),
  `core/src/lib.rs` (the palette export line)
- `core/tests/tax_inspect_port.rs` (the two STORE-cap battery extensions +
  the surrounding battery), `core/src/txf.rs` (cap constants, grep-level)
- `scripts/sandbox_backup.sh` (all 199 lines), `.gitignore` (all 120 lines),
  `scripts/harness_check.sh` (the +39-line N2 delta)
- `fixtures/palette/README.md` (all 51 lines — the digest + provenance),
  `THIRD-PARTY-NOTICES.md` (the new MCU entry),
  `harness/memory/STATE.md` + `PROJECT_MEMORY.md` (delta portions)
- Read-only git evidence: `status`, `rev-parse`, `log`, `show`, and
  `diff`/`grep` over `d227bc7..7f18fa2` (the delta review itself); the
  backup-guard scans re-run verbatim; GitHub API tag-verification attempted
  (rate-limited, advisory 1). No installers run; nothing written outside
  this report.
