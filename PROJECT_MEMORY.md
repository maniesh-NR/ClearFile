# PROJECT_MEMORY.md — ClearFile engineering state (single source of truth)

**Protocol:** pstack-style Engineering & Token-Efficiency Protocol, owner
directive 2026-11-22 (ADR-018, `harness/memory/DECISIONS.md`). **Layering:**
this file is the ENGINEERING memory (stack rules, playbook, verification
contracts, rolling git-activity window). The GOVERNANCE memory (gates,
ADRs, debt, adversarial records — binding) lives in `harness/`; nothing
here may contradict it.

**Zero-noise rule:** at each milestone, update the Playbook / Snapshot
sections with tight summaries — decisions, changed files, next steps.
No conversational filler, no failed-debugging dumps, no raw tool output.
`python3 update_memory.py` (from the repo root) refreshes the
git-activity window — run it at session bootstrap.

**Working rules (ADR-018):** investigation before code (read-only
root-cause work first); every task anchored to a checkable outcome from
the Verification Contracts section; parallel agents retrieve by section
anchor (stable `##` headers below — the file is grep-able state, never
loaded whole into context).

## Tech stack & architecture rules

| Layer | Choice (pinned) | Binding rules |
| --- | --- | --- |
| Reference app | `clearfile/` — Flutter 3.47.9 stable / Dart 3.13.7 | The TY2025 1040 engine here is the calculation REFERENCE. Material 3 from static seed `0xFF00696E` (no `dynamic_color` — ADR-007, negative result). Widget-test FS work needs `tester.runAsync`. |
| Web prototype | `src/` — Next.js 16 + TypeScript | MAINTENANCE PARITY ONLY (ADR-016): no new web-engine features; corrections flow through shared golden fixtures; retires when the Rust core serves the web (WASM). |
| Shared truth | `fixtures/tax/` — 16 IRS-pinned `(TaxReturnData, TaxResult)` JSON pairs | Single source of truth for BOTH engines + the Decimal oracle + the future Rust core (ADR-017). NEVER derive expected values by running an engine. |
| Save format | `.clearfile.json` envelope v2 (ADR-015; `.cfr` = read-only legacy alias) | Version guard in every reader; migrations warned, never silent; spec = `docs/return-format.md`. |
| AI cascade | BYO-key, opt-in, on-device keys only (Gemini → OpenRouter, ADR-005) | Keys never in repo/history; `sendReturnContext` default OFF (ADR-011); Stage-5 hardening pending (D8/D11/D12/D16 halves). |
| CI | `.github/workflows/` — hygiene.yml + release.yml | SHA-pinned actions; `contents: read`; timeouts; no fork/PR surface; suites job = analyze + test + audit gate + tsc + oracle + parity + bridge. |
| Tooling | `scripts/` (see `scripts/README.md`) | SDK install via `scripts/fetch_flutter_sdk.sh` (manifest-sha256; tar quirk tolerated — quirk 20). |
| License | GPL-3.0-only | SPDX header on every own-code file (new scripts included); vendored shadcn stays MIT-labelled (`THIRD-PARTY-NOTICES.md`). |

**Architectural boundaries:** today = two live codebases (Flutter
reference + web prototype), zero native-stack code. Forward (ADR-017
epilogue, UNFUNDED, own gates): shared Rust core (engine + parameter
tables + format codecs + MD3 palette; NO AI cascade, NO filesystem I/O —
the envelope IS the ABI) behind one flat C ABI (cbindgen; Linux links
the crate directly); per-OS stacks: Win32+Direct2D / Swift+AppKit
(floor macOS 13) / gtk3-rs (older tier) + Slint (modern tier) / Android
Views+KMP (Android-only; iOS explicitly dropped). Material You from the
seed on every OS, OS-idiomatic elements kept.

**Sandbox quirks (shortlist; full register of 20 in
`harness/memory/STATE.md`):** recycles flip file modes 644→755 —
normalize BEFORE editing (quirk 19: `git restore .` reverts unstaged
content edits); brief sessions have twice left unpushed mode-only
amends (2026-11-16, 2026-11-20) — reset to the pushed tip before edits;
background jobs die between Bash calls; tar's trailing restore fails
benignly on this FS.

## Active playbook — current objective: Stage-2 (RE tooling) execution, session 1

Stage 2 ENTERED 2026-11-17 (gate record:
`harness/adversarial/CONSENSUS.md`; ADR-012 in-repo placement + DoD +
security contract recorded there and mirrored in
`harness/memory/ROADMAP.md` Stage-2 entry conditions).
**DoD: 4 named `docs/formats/` specs in ≤ 2 working sessions.** The first
tooling commit MUST carry the gate's entry conditions:

- [ ] ADR-012 mechanics: gitignored `fixtures/re/` synthetic fixture
      path; allow-listed no-binary-blob CI assertion (28 own assets
      today); the same allow-list wired into `scripts/sandbox_backup.sh`;
      §7.5 checklist per spec; tooling never referenced from
      `release.yml`; no tracked Phase-4 binaries.
- [ ] LEGAL-1 mechanics: synthetic-only unit fixtures; the differential
      tool refuses pairs lacking a provenance-manifest entry; the backup
      hex guard widened to ≥32-hex on RE-adjacent paths (UUID/known-hash
      allow-list); `docs/formats/*.md` lint (provenance field, no hex
      runs ≥32).
- [ ] ENG-3 (debt D33): survivingSpouse (QSS) golden fixture — consumed
      by all three runners (Dart, `web_parity_test.mjs`, the Decimal
      oracle), IRS-cited.
- [ ] Tools per the security contract: write-free (read-only opens, no
      disk-writing shell-outs, read-only-fixture-dir test);
      resource-bounded (size/entry/line caps, EACH with a
      refusal-on-oversize test); crash-safe (malformed-input battery —
      the ENG-1 crafted file is the template); each tool's header
      states the posture.
- [ ] First spec toward N=4 (`docs/formats/clearfile-json.md`
      recommended first).
- [ ] Owner states the owned RE corpus (product/version/year/count) at
      kickoff so N is real.

## Verification contracts (prove before closing ANY task)

From the repo root (`export PATH="$PWD/tools/flutter/bin:$PATH"` first;
after a recycle run `bash scripts/fetch_flutter_sdk.sh`):

    cd clearfile && flutter analyze && flutter test    # 113/113 (97 + 16 golden)
    cd .. && npx tsc --noEmit                          # exit 0
    node scripts/txf_taxfile_test.mjs                  # 10/10 groups
    node scripts/web_parity_test.mjs                    # 16/16 fixtures
    python3 scripts/verify_golden_fixtures.py          # 16/16
    python3 scripts/web_smoke.py                       # 6/6
    npm audit --omit=dev --audit-level=critical        # exit 0
    bash scripts/harness_check.sh                      # 0 failures
    python3 update_memory.py                           # window refreshed

Governance close-out per session (WORKFLOW §3): SESSION_LOG entry →
STATE.md sync → PROJECT_MEMORY.md zero-noise update →
`bash scripts/sandbox_backup.sh "<note>"` as the LAST action.

## Session snapshot (one bullet per session; decisions / files / next)

- **2026-11-17** — Stage-2 entry gate: 4 × PROCEED-WITH-CONDITIONS, no
  BLOCKs; Stage 3 CLOSED; ADR-012 (in-repo placement) / ADR-016
  (TS-engine maintenance freeze) / ADR-017 (re-platforming settlement)
  recorded; ENG-1 inspector crash fixed + ENG-2 cap test (suite → 113);
  audit criticals cleared + the CI audit gate. Backup `c4982d1`, CI
  green.
- **2026-11-22** — THIS session: the protocol layer installed (ADR-018)
  — `PROJECT_MEMORY.md` + `update_memory.py` at the repo root; WORKFLOW
  §3 amended to carry both memory layers at bootstrap/teardown. The
  2026-11-20 unlogged mode-only amend (`f1af2d4`) found and resolved
  (reset to `c4982d1` before edits). Files changed: the two new root
  files + `harness/{DECISIONS,WORKFLOW,STATE,SESSION_LOG}.md` +
  `scripts/README.md`. No code paths touched; suites carried from
  `c4982d1` (CI run 44044419879 green). Next: Stage-2 execution session
  1 (playbook above).

## Recent Progress & Git Activity

```diff
### Commit: c4982d1 - backup(sandbox): Stage-2 entry gate (closes Stage 3): 4x PROCEED-WITH-CONDITIONS, no BLOCKs - Stage 3 CLOSED unanimous (every reviewer re-verified the suites with their own runs); the parity tripwire's mandatory slip-FIRED agenda item DISPOSED as ADR-016 (TS-engine maintenance freeze + retire-on-replacement when the Rust core serves the web via WASM; owner-overrule path recorded, never silence); Stage 2 (RE tooling) ENTERED with its full agenda settled: DoD fixed (N=4 named docs/formats specs in a two-working-session hard box, no spec without samples, owner states the corpus at kickoff), placement ADR-012 IN-REPO unanimous (ADV-LEGAL switched from its separate-repo default on the measured facts) with six binding mechanics landing with the FIRST tooling commit else revert to separate repo, security contract recorded verbatim (write-free, resource-bounded with refusal tests, crash-safe battery, never wired into release.yml, enumerated gitignored fixture paths); the ADR-014 native re-platforming settlement recorded as ADR-017: staged per-OS over the shared Rust core as a FINITE post-Stage-6 epilogue program (N1 core -> N2 Linux gtk3-rs/Slint -> N3 Android KMP -> N4 Windows Win32+Direct2D -> N5 macOS Swift+AppKit floor 13 -> N6 web-WASM + terminal freeze; one flat C ABI via cbindgen, Linux links the crate direct; KMP Android-only; iOS dropped explicitly per PROD-1; v2.0.0 at first native GA with the envelope staying v2; ADR-009 superseded by single-core parity; verification annex: the 16 golden fixtures + differential harness vs Dart + ported bridge suites + f64-first; licensing annex: GPL-3.0-only core, cargo-deny, Qt only under GPL terms, system-library carve-outs); v1.1 stays reachable now - Stage 5's closing tag, discharging D29; gate condition fixes applied IN-SESSION: ENG-1 real bug found by the panel (Dart .tax inspector RangeError on crafted truncated central-directory entry - name slice bounds-checked + the crafted file as regression test), ENG-2 (TXF 10,000-record cap refusal test; suite 111->113), SEC-1 (npm audit fix non-breaking, 0 criticals remain from 32/2-critical + the fail-closed npm-audit CI gate added to hygiene.yml suites), SEC-3/ENG-5 (fetcher tar-tolerance hardening, recorded as quirk 20), SEC-2 (the unlogged 2026-11-16 session that left unpushed mode-only amend 4d4e1d6 recorded in SESSION_LOG; resolved by reset to the pushed tip a18b160 BEFORE edits - 191 files, zero content delta), ENG-7 (WORKFLOW §4 verify step now requires harness_check), LEGAL-5 (README targets wording + counts 113); ROADMAP: Stage-2 entry conditions recorded, Stage-3 CLOSED status, epilogue N1-N6 PENDING/unfunded, Stage-5 closing event v1.1; DEBT D33-D35 (QSS fixture -> first execution session; migration triple-implementation; store warnings); harness_check patterns updated for the legitimate advance (13 checks, 0 failures); final suites: flutter analyze clean, flutter test 113/113, tsc 0, bridge 10/10, parity 16/16, oracle 16/16, web smoke 6/6, audit gate green; 4 independent gate reports + the CONSENSUS gate record filed; next: Stage-2 execution session 1 - the first tooling commit carries the ADR-012 mechanics + LEGAL-1 mechanics + the security contract + ENG-3's survivingSpouse fixture @ 2026-11-17T08:10:01Z (Z User, 2026-11-17)
 .github/workflows/hygiene.yml        |   8 +
 README.md                            |   6 +-
 clearfile/lib/io/tax_inspect.dart    |   8 +
 clearfile/test/tax_inspect_test.dart |  30 ++++
 clearfile/test/txf_import_test.dart  |  10 ++
 harness/WORKFLOW.md                  |   6 +-
 harness/adversarial/CONSENSUS.md     | 276 +++++++++++++++++++++++++++++++++++
 harness/memory/DEBT.md               |  18 +++
 harness/memory/DECISIONS.md          | 184 +++++++++++++++++++++++
 harness/memory/ROADMAP.md            | 216 ++++++++++++++++++++-------
 harness/memory/SESSION_LOG.md        | 138 ++++++++++++++++++
 harness/memory/STATE.md              | 225 ++++++++++++++++------------
 scripts/fetch_flutter_sdk.sh         |  10 +-
 scripts/harness_check.sh             |  32 ++--
 14 files changed, 1001 insertions(+), 166 deletions(-)

### Commit: a18b160 - backup(sandbox): Stage-3 close-out COMPLETE (ADR-015): unified ClearFile return format - .clearfile.json envelope {format: clearfile-return, version: 2, filing} written by BOTH codebases (Flutter export + autosave store, web download, .tax exchange container entry) with version guard (D3 rule closed), migration matrix (web v1 .cfr conservative mapping + legacy flat clearfile.return lossless lift, warning-wording parity with the web parser) and sealed ReturnImport outcome (D1 closed - cancelled/failed-reason/ok-warnings with dialogs); FIXES cross-codebase bug: web-exported exchange containers now import into the Flutter app; spec docs/return-format.md + 14 new Dart tests + 2 container tests + 4 bridge-suite cfr groups; docs close-out: docs/engine.md (1040/SchA/8812/8960 line map + sources + verification pyramid + limitations register), docs/tour.md (guided tour + adopted project DoD 'verify every number against a cited IRS source without reading git history'), engine- and format-discrepancy issue templates; seventh recycle: SDK reinstalled via new durable scripts/fetch_flutter_sdk.sh (manifest-sha256, resumable); tripwire: box NOT exceeded but slip FIRED - web-freeze returns to the gate agenda as mandatory; suites all re-run: analyze clean, 111/111 Dart, tsc 0, bridge 10 groups, parity 16/16, oracle 16/16, smoke 6/6, harness_check 0; Stage 3 execution COMPLETE - next event: Stage-2 entry gate @ 2026-11-15T12:19:25Z @ 2026-11-15T12:19:25Z (Z User, 2026-11-15)
 .github/ISSUE_TEMPLATE/engine-discrepancy.md |  67 ++++++
 .github/ISSUE_TEMPLATE/format-discrepancy.md |  49 +++++
 README.md                                    |  28 ++-
 clearfile/lib/io/files.dart                  |  32 ++-
 clearfile/lib/io/return_format.dart          | 306 +++++++++++++++++++++++++++
 clearfile/lib/io/return_store.dart           |  20 +-
 clearfile/lib/io/tax_inspect.dart            |  19 +-
 clearfile/lib/ui/app_state.dart              |  19 +-
 clearfile/lib/ui/screens/welcome.dart        |  58 ++++-
 clearfile/test/return_format_test.dart       | 267 +++++++++++++++++++++++
 clearfile/test/tax_inspect_test.dart         |  44 ++++
 docs/engine.md                               | 141 ++++++++++++
 docs/return-format.md                        | 158 ++++++++++++++
 docs/tour.md                                 |  80 +++++++
 harness/memory/DEBT.md                       |   4 +-
 harness/memory/DECISIONS.md                  |  53 +++++
 harness/memory/ROADMAP.md                    |  40 +++-
 harness/memory/SESSION_LOG.md                |  76 +++++++
 harness/memory/STATE.md                      |  98 ++++-----
 scripts/README.md                            |  17 +-
 scripts/fetch_flutter_sdk.sh                 |  67 ++++++
 scripts/txf_taxfile_test.mjs                 | 119 ++++++++++-
 src/components/clearfile/filemenu.tsx        |  10 +-
 src/lib/files/cfr.ts                         |  51 ++++-
 24 files changed, 1698 insertions(+), 125 deletions(-)

### Commit: 935f782 - backup(sandbox): UI-stack directive (ADR-014): per-OS native stacks (Win32+Direct2D / Swift+AppKit / gtk-rs+gtk3-rs+Slint+Qt / Android Views+KMP) over a shared Rust core + Material You with OS-specific elements kept - direction recorded, execution gated (settlement added to Stage-2 entry-gate agenda); inherited-state verification closed (all four 2026-11-14 owner decisions confirmed landed, PAT recovered as the lost 4th; backup chain unbroken at 74a1286; nothing to patch); sixth recycle recorded (tools/ gone, node_modules+tsc survived, 183 mode flips normalized); quirk 19 recorded (git restore . reverts unstaged content edits - ADR-014 edits wiped once and redone); no code changed, suites carried from content-identical 74a1286 (Dart 95/95, parity 16/16, bridge 6/6, smoke 6/6, tsc clean); harness_check 0 failures @ 2026-11-15T02:56:37Z @ 2026-11-15T02:56:37Z (Z User, 2026-11-15)
 harness/memory/DECISIONS.md   | 63 +++++++++++++++++++++++++++++++++++++++
 harness/memory/ROADMAP.md     | 23 +++++++++++++++
 harness/memory/SESSION_LOG.md | 59 ++++++++++++++++++++++++++++++++++++
 harness/memory/STATE.md       | 69 ++++++++++++++++++++++++++++++-------------
 4 files changed, 193 insertions(+), 21 deletions(-)
```

