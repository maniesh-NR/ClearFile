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
| Tooling | `scripts/` (see `scripts/README.md`) | SDK install via `scripts/fetch_flutter_sdk.sh` (manifest-sha256; tar quirk tolerated — quirk 20). TT RE corpus re-acquisition via `scripts/fetch_tt_corpus.sh` (ADR-019; blobs gitignored; provenance `docs/re-research/corpus-manifest.md`). |
| RE bench | gitignored `tools/`: REA 6.10.1 over Ghidra 12.2 + Temurin 25 (REA hard-requires ≥12.2); protocol-pinned 12.1.4 + JDK 21 fallback; corpus at `tools/re-corpus/` (sha256-verified by the fetcher) | Phase-4 runs under the RE protocol's guardrails (§2/§7): function facts only in notes; no decrypted content, no expression lifts. Password-based access = the shipped target; **the fixed-key layer = SANCTIONED for the shipped bridge scope by ADR-020** (owner risk acceptance; boundary conditions; §2.2/§7.3 amended-in-part; key VALUES only in the quarantined T4 module, by-existence everywhere else). REA checkpoint mode ON (`REA_GHIDRA_CHECKPOINT_DIR`; 84 s import → ~11 s/command). |
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

## Active playbook — TT program T2 (owner's active directive) + Stage-2 standing items

**TT-compatibility program (ADR-019 + ADR-020; T2 ENTERED at its 2026-11-22 gate):**

- [x] T1: acquire the four-target corpus + Phase-1 survey + the REA
      first-pass decompile (done 2026-11-22 —
      `docs/re-research/2026-11-22-tt-targets-phase1.md` + the gate
      erratum: container head 0x99000).
- [x] T2 session 1 (2026-11-22): the reader pipeline chased to the
      archive-entry format — the name/value map builder
      (FUN_00418a50), the internal-header fields
      (FUN_00418710), the entry state machine (FUN_00418c60);
      entry layout byte-validated (magic 0x6d27e59b / type /
      name / FILETIME / two u32 fields); payload codec **byte-proven
      raw Deflate** (→ the inner SetUp.exe PE); no encryption at
      this layer — `docs/re-research/2026-11-22-tt-t2-reader.md`.
- [ ] T2 session 2 (D36): entry fields A/B + the chunked stream +
      the FUN_0041e5e0 codec chain; CAN-Personal inner ZIP;
      CAN-Business InstallShield table; then the app-module
      inventory (where the file-format/password routines live) +
      the UI functional-layout study (text-only IA records, §7.4).
- [ ] T3: format-family specs incl. the password layer (Phase-5
      template, §7.5-clean; namespace rule: never count toward
      Stage-2's N=4).
- [ ] T4: the password-based bridge (read/edit/save with the user's
      own password; **Flutter-first — web stays frozen per ADR-016**;
      codec layer pure for the N1 port) + UI functional-layout parity
      in ClearFile's own Material You expression. The T4 gate carries
      the merge conditions (CONSENSUS's TT-gate ledger: refusal tests,
      the quarantined key module + SEC-2's representation-agnostic
      assertion, the save-fidelity rule, the README/SECURITY
      disclosure replacement + non-affiliation line).
- [x] OWNER DECISION RECORDED: the fixed-key transport layer —
      **accepted for shipping by ADR-020** (2026-11-22, with the
      boundary conditions; the TT gate re-argued it and the
      Canadian-law assessment is on file).

**Stage-2 (RE tooling) execution session 1 — standing entry conditions** (the
first tooling commit carries: the ADR-012 mechanics; the LEGAL-1
mechanics; ENG-3's QSS fixture; the tools per the recorded security
contract; the first docs/formats spec):

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
- **2026-11-22 (a)** — the protocol layer installed (ADR-018):
  `PROJECT_MEMORY.md` + `update_memory.py` at the repo root; WORKFLOW §3
  carries both memory layers at bootstrap/teardown; the 2026-11-20
  unlogged mode-only amend resolved (reset to `c4982d1` before edits).
  Backup `6d3f13d`, CI green.
- **2026-11-22 (b)** — TT program T1 (ADR-019): four TurboTax installers
  acquired (~1.4 GB gitignored corpus + fetcher + manifest); Phase-1
  surveyed (USA = stub + proprietary record container w/ `48 12 90 BF…`
  magic + xmlConfig SfxConfig manifest; CAN-Personal = WinZip SFX →
  MSI chain; CAN-Business = InstallShield-style); REA 6.10.1 + Ghidra
  12.2/JDK 25 installed; the USA stub carved + decompiled via the REA
  pipeline (~83 s) — the container reader pipeline mapped
  (`FUN_004012c4`: open→size→marker→header→args→record-by-name→XML).
  No app code touched; suites carried. Files: tools/re/* (gitignored),
  scripts/fetch_tt_corpus.sh, docs/re-research/{corpus-manifest,
  2026-11-22-tt-targets-phase1}.md, harness records. Next: the owner's
  fixed-key decision + T2 behind the program's gate; Stage-2 Session 1
  still standing.
- **2026-11-22 (c)** — ADR-020 + the TT gate + T2 session 1: the owner's
  explicit risk acceptance for the shipped decryptor recorded
  (fixed-key layer included; boundary conditions; enforcement-response
  plan; precedes any implementation); the TT gate PASSED
  4 × PROCEED-WITH-CONDITIONS (reports + consensus + the Canadian-law
  assessment on file; in-session conditions applied: the ≥32-hex guard
  + canary, the fetcher's sha256 enforcement, the NOTE scan, the
  erratum, protocol §6/§7.4 amendments, DEBT D36–D39); T2 session 1:
  the archive-entry format derived + byte-validated (magic
  0x6d27e59b; name/FILETIME/size fields; payload byte-proven raw
  Deflate → the inner SetUp.exe PE; no encryption at this layer);
  REA checkpoint mode ON (84 s → ~11 s). No app code touched; suites
  carried. Files: DECISIONS (ADR-020), protocol amendments,
  adversarial reports + CONSENSUS, ROADMAP/STATE/DEBT/SESSION_LOG,
  scripts/{sandbox_backup,fetch_tt_corpus,harness_check}.sh,
  docs/re-research/2026-11-22-tt-t2-reader.md. Next: T2 session 2
  (D36) + Stage-2 session 1 under the PROD-2 tripwire.

## Recent Progress & Git Activity

```diff
### Commit: 52e2c68 - backup(sandbox): TT-compatibility program T1 (ADR-019, owner directive): four TurboTax installer targets acquired (Personal USA 2026 403,981,944 B / Personal CAN 2025 369,125,144 B / Business USA 2026 379,141,920 B / Business CAN 2025 333,073,488 B; ~1.4 GB, gitignored tools/re-corpus/, sizes matched CDN Content-Lengths, sha256s recorded in docs/re-research/corpus-manifest.md + durable resumable scripts/fetch_tt_corpus.sh); Phase-1 passive survey of all four (PE32 i386 installers: USA pair = shared 2008-era ~626 KiB stub + proprietary record-container overlay 99.8% w/ magic 48 12 90 BF 49 FF 91 AA + length-prefixed named records, first record xmlConfig carrying a SfxConfig XML manifest, payload H=8.0 compressed, stub imports CryptAcquireContextA/WININET/WS2_32; CAN-Personal = WinZip SFX w/ plain ZIP inside -> setup.exe MSI bootstrapper + 369 MB payload installer + TTConfig.ini facts; CAN-Business = InstallShield-style UTF-16 manifest table; notes docs/re-research/2026-11-22-tt-targets-phase1.md); REA 6.10.1 (morluto/rea, the directed front-end) installed over Ghidra 12.2 + Temurin 25 (REA hard-requires >=12.2 -> JDK 25; protocol-pinned 12.1.4+JDK21 kept as fallback); first-pass Phase-4 via the REA pipeline on the CARVED USA stub (the stub IS the container reader, 626,688 B, well inside the envelope): rea analyze ~83 s, xref on the xmlConfig string -> 0x40143c -> decompiled the reader pipeline FUN_004012c4 = open-self -> size -> find-marker (FUN_00418670 vtable reader class) -> internal header -> internal args -> record-by-name xmlConfig -> XML parse; pseudocode archived tools/re/ (gitignored); BOUNDARIES RECORDED (ADR-019): password-based access IS the shipped target (user's own password = authorization; LibreOffice/7z interoperability pattern), the fixed-key transport layer stays the recorded NO (§2.2) unless the owner records an explicit risk-acceptance ADR - SURFACED FOR OWNER DECISION, UI = functional/informational layout parity only (no expression/trade-dress copying; Material You identity stands); the TT program is separate + gated (T1 started, T2-T4 behind its own gate; Stage-2 DoD box NOT grown; gate agenda: fixed-key question + Canadian-law assessment + security contract); mechanics landed early + recorded: corpus-manifest = the known-hash allow-list first instance (sandbox_backup.sh hex heuristic excludes exactly that path); ROADMAP TT section + harness_check PENDING count 9->10; PROJECT_MEMORY playbook updated (T1 done); eleventh recycle: 197 mode flips normalized BEFORE edits (quirk 19), tools/ rebuilt, archive zips deleted after extraction (disk watch: ~2.5 GB free); NO app code touched - zero TS/Dart source changes, suites carried (local bench degraded: the recycle hollowed node_modules/.bin/tsc + a partial npm install OOMd - tsc needs >2.5 GB locally under the concurrent dev server; CI npm ci+tsc is authoritative and runs on this push); harness_check 0 failures; next: owner fixed-key decision + T2 behind the program's gate + Stage-2 session 1 standing @ 2026-11-22T07:27:06Z (Z User, 2026-11-22)
 PROJECT_MEMORY.md                                |  63 +++++++++----
 docs/re-research/2026-11-22-tt-targets-phase1.md | 115 +++++++++++++++++++++++
 docs/re-research/corpus-manifest.md              |  24 +++++
 harness/memory/DECISIONS.md                      |  83 ++++++++++++++++
 harness/memory/ROADMAP.md                        |  33 +++++++
 harness/memory/SESSION_LOG.md                    |  77 +++++++++++++++
 harness/memory/STATE.md                          |  48 ++++++----
 scripts/README.md                                |   8 ++
 scripts/fetch_tt_corpus.sh                       |  62 ++++++++++++
 scripts/harness_check.sh                         |  13 +--
 scripts/sandbox_backup.sh                        |  10 +-
 11 files changed, 494 insertions(+), 42 deletions(-)

### Commit: 6d3f13d - backup(sandbox): pstack protocol layer (ADR-018, owner directive): PROJECT_MEMORY.md installed at the repo root as the ENGINEERING single source of truth - tech stack & architecture rules (pinned: Flutter 3.47.9/Dart 3.13.7 reference app, Next.js 16 web prototype under ADR-016 maintenance parity, 16 shared IRS-pinned golden fixtures, .clearfile.json envelope v2, GPL-3.0-only) + active playbook (Stage-2 execution session 1 checklist: ADR-012 mechanics, LEGAL-1 mechanics, ENG-3 QSS fixture, tools per the security contract, first docs/formats spec) + verification contracts (the full command set with expected outputs) + session snapshot (zero-noise bullets) + the rolling git-activity window; update_memory.py saved at the root from the uploaded template with the repo's SPDX header (D14) and TWO documented deltas forced by the zero-noise rule + mega-commit granularity (measured: -p window 245KB vs stat 19KB): PATCH_MODE=stat default (owner may flip to patch) + noise excludes (lockfiles, adversarial reports, golden fixtures); section-replacement logic upstream-verbatim; verified compiles + idempotent (16KB); WORKFLOW §3 amended so bootstrap reads PROJECT_MEMORY.md + runs update_memory.py (anchor-retrieval, never whole-file) and teardown writes the zero-noise summary before the backup; layering explicit: harness/ stays the governance memory (ADR-003 stands), PROJECT_MEMORY.md is the engineering layer; scripts/README row + .gitignore __pycache__ entry; SECOND unlogged mode-only amend found + resolved before edits (2026-11-20 session, f1af2d4: 195 files 644->755, zero content delta, message identical -> reset to pushed tip c4982d1; same class as 2026-11-16; pattern now in the quirk shortlist); tenth recycle (tools/ gone, SDK not needed, node_modules+tsc survived); no code paths touched - suites carried from c4982d1 (CI run 44044419879 green): Dart 113/113, tsc 0 re-verified locally, bridge 10/10, parity 16/16, oracle 16/16, smoke 6/6; harness_check 0 failures; readiness confirmed: protocol live, next is Stage-2 execution session 1 under it @ 2026-11-22T02:48:02Z (Z User, 2026-11-22)
 .gitignore                    |   3 +
 PROJECT_MEMORY.md             | 177 ++++++++++++++++++++++++++++++++++++++++++
 harness/WORKFLOW.md           |  22 +++++-
 harness/memory/DECISIONS.md   |  57 ++++++++++++++
 harness/memory/SESSION_LOG.md |  70 +++++++++++++++++
 harness/memory/STATE.md       |  76 +++++++++---------
 scripts/README.md             |   6 ++
 update_memory.py              | 109 ++++++++++++++++++++++++++
 8 files changed, 482 insertions(+), 38 deletions(-)

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
```

