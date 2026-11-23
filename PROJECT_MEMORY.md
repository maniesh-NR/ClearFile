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
| Shared truth | `fixtures/tax/` — 17 IRS-pinned `(TaxReturnData, TaxResult)` JSON pairs | Single source of truth for BOTH engines + the Decimal oracle + the future Rust core (ADR-017). NEVER derive expected values by running an engine. |
| Save format | `.clearfile.json` envelope v2 (ADR-015; `.cfr` = read-only legacy alias) | Version guard in every reader; migrations warned, never silent; spec = `docs/return-format.md`. |
| AI cascade | BYO-key, opt-in, on-device keys only (Gemini → OpenRouter, ADR-005) | Keys never in repo/history; `sendReturnContext` default OFF (ADR-011); Stage-5 hardening pending (D8/D11/D12/D16 halves). |
| CI | `.github/workflows/` — hygiene.yml + release.yml | SHA-pinned actions; `contents: read`; timeouts; no fork/PR surface; suites job = analyze + test + audit gate + tsc + oracle + parity + bridge. |
| Tooling | `scripts/` (see `scripts/README.md`) | SDK install via `scripts/fetch_flutter_sdk.sh` (manifest-sha256; tar quirk tolerated — quirk 20). TT RE corpus re-acquisition via `scripts/fetch_tt_corpus.sh` (ADR-019; blobs gitignored; provenance `docs/re-research/corpus-manifest.md`). **Stage-2 RE tooling (2026-11-22):** `re_entropy` / `re_magic` / `re_diff` (Phase 1–3, security-contract posture) + `test_re_tools` (22 tests) + `check_binary_blobs` (ADR-012 allow-list assertion) + `lint_format_specs` (LEGAL-1) — CI: hygiene `re-tooling` job. |
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
- [x] T2 session 2 (2026-11-22): **the USA container format COMPLETED
      byte-end-to-end** — entry fields resolved (A = Win32 attributes
      bitmask, B = first-chunk compressed size; type 1=dir/2=file/0=end);
      the chunk grammar proven (raw-Deflate chunks + 0x80000000-flag
      stored segments + [u32 0] terminator + type-0 end-entry + ~10 KB
      trailing PKCS#7 SignedData); FUN_0041e5e0 CORRECTED to the
      parent-dir preparer; CAN-Personal inner layer = plain ZIP → the
      same 2022-07-05 bootstrapper + InstallShield ISSetupStream v7;
      CAN-Business manifest table mapped (INI-block size field + entropy
      boundary); all four targets converge on the InstallShield layer
      — `docs/re-research/2026-11-22-tt-t2-session2.md`; D36 closed,
      zero derived bytes on disk (all decodes in-memory).
- [ ] T2 session 3 (D40): the InstallShield-layer record walk
      (ISSetupStream v7/v8 payload records + the classic file-group
      records); then the app-module inventory (where the
      file-format/password routines live) + the UI functional-layout
      study (text-only IA records, §7.4).
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

**Stage-2 (RE tooling) execution — session 1 DONE 2026-11-22 (all entry
conditions landed with the first tooling commit); session 2 = the box's
final one:**

- [x] ADR-012 mechanics: gitignored `fixtures/re/` synthetic fixture
      path (enumerated, the only committable-shape synthetic path);
      allow-listed no-binary-blob CI assertion (28 measured own assets;
      hygiene `re-tooling` job); the same allow-list wired into
      `scripts/sandbox_backup.sh` (post-`git add -A`, exit-2 refusal);
      §7.5 checklist per spec (recorded in each spec + the lint); tooling
      never referenced from `release.yml` (harness_check family 7);
      no tracked Phase-4 binaries (the blob assertion is the proof).
- [x] LEGAL-1 mechanics: synthetic-only unit fixtures (runtime-generated
      under gitignored `fixtures/re/`); the differential tool refuses
      pairs lacking a provenance-manifest entry (§7.1; four refusal
      shapes unit-tested); the backup hex guard ≥32-hex on RE-adjacent
      paths (applied at the TT gate; covers the new docs); the
      `docs/formats/*.md` provenance lint in CI (no ≥32-hex runs, no
      image embeds, no placeholders).
- [x] ENG-3 (debt D33): survivingSpouse (QSS) golden fixture #17 —
      consumed by all three runners, IRS-cited (Pub 501 / QDIVCG lines
      6+13 / Topic 559 / Form 8812 line 9); **found + forced the QSS
      CTC $200,000-threshold fix in all three parameter tables** (the
      debt's $400k premise corrected by the form text).
- [x] Tools per the security contract: `re_entropy` / `re_magic` /
      `re_diff` — write-free (read-only opens; read-only-fixture-dir
      test), resource-bounded (size/block/hits/region caps + wall-clock
      timeouts, EACH with a refusal-on-oversize test: message + exit 3,
      never a crash), crash-safe (ENG-1-shaped battery: empty/truncated/
      adversarial shapes report, never throw), posture in each header +
      `--help` (D38 registered for Phase 1–3; T4 extraction tools still
      owe it).
- [x] First spec toward N=4: `docs/formats/clearfile-json.md`
      (§7.5-clean; the differential tool exercised on a synthesized
      pair inside mandatory family #1).
- [x] Owner's owned-RE-corpus statement on record (ADR-019 +
      `docs/re-research/corpus-manifest.md`: the four TT targets) so N
      is real — TT specs never count toward Stage-2's N=4.
- [x] **Session 2 (the box's final one, 2026-11-23 — box CLOSED at
      exactly two sessions):** specs 2 + 3 of the DoD published
      (`tax-exchange-container.md`, `txf.md`, both §7.5-clean/lint-clean;
      the differential tool now exercised inside mandatory families #1
      AND #2 via the 23rd RE-tool test); `tax-modern.md` awaits T3's
      password-layer findings exactly as planned (no stub — §7.5 forbids
      placeholders; the exit gate convenes when T3 delivers, checklist
      otherwise green); **D34 CLOSED** (the shared `fixtures/migration/`
      family + exact warning lists in BOTH suites + the clamp alignment +
      the store-vs-file W-2 note in return-format.md §3); refusal/cap
      tests green; blob assertion green.

## Verification contracts (prove before closing ANY task)

From the repo root (`export PATH="$PWD/tools/flutter/bin:$PATH"` first;
after a recycle run `bash scripts/fetch_flutter_sdk.sh`):

    cd clearfile && flutter analyze && flutter test    # 115/115 (98 + 17 golden)
    cd .. && npx tsc --noEmit                          # exit 0
    node scripts/txf_taxfile_test.mjs                  # 11/11 groups
    node scripts/web_parity_test.mjs                    # 17/17 fixtures
    python3 scripts/verify_golden_fixtures.py          # 17/17
    python3 scripts/web_smoke.py                       # 6/6
    python3 scripts/test_re_tools.py                   # 23/23 (Stage-2 RE tools)
    python3 scripts/check_binary_blobs.py              # clean (28 allow-listed)
    python3 scripts/lint_format_specs.py               # N/N clean
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
- **2026-11-22 (d)** — TT program T2 session 2 (D36 closed): the USA
  container format COMPLETED byte-end-to-end (A = attributes bitmask,
  B = first-chunk csize; raw-Deflate chunks + 0x80000000-flag stored
  segments + u32-0 terminator + type-0 end-entry + ~10 KB trailing
  PKCS#7 SignedData; FUN_0041e5e0 corrected to the parent-dir
  preparer); CAN-Personal inner layer = plain ZIP → the same
  2022-07-05 bootstrapper + ISSetupStream v7; CAN-Business manifest
  table mapped (INI-block size = entropy boundary); all four targets
  converge on the InstallShield layer (D40 = the next walk). Zero
  derived bytes on disk (all decodes bounded in-memory); no app code
  touched — suites carried (local tsc OOMs at the box memory ceiling;
  CI authoritative). Files: docs/re-research/2026-11-22-tt-t2-session2.md,
  ROADMAP/STATE/DEBT/SESSION_LOG syncs, gitignored tools/re/t2_*.py.
  Next: T2 session 3 (D40) — and Stage-2 session 1 at the next working
  session (PROD-2 tripwire: 1 of 2 elapsed).
- **2026-11-22 (e)** — **Stage-2 EXECUTION session 1 (PROD-2 DISCHARGED,
  2 of 2):** the first tooling commit landed with every entry condition —
  the QSS golden fixture #17 (all three runners; **found + forced the QSS
  CTC $200,000-threshold bug in both engines + the oracle** — Form 8812
  line 9's "All other filing statuses" + Pub 501's "doesn't entitle you
  to file a joint return"; fixed in `tax_year.dart` + `config.ts` +
  `verify_golden_fixtures.py` + `docs/engine.md`); the Phase 1–3 RE tools
  (`re_entropy`/`re_magic`/`re_diff`) under the security contract + the
  22-test suite (synthetic fixtures under gitignored `fixtures/re/`;
  read-only-dir proof; differential on a synthesized clearfile-json
  pair); the ADR-012 mechanics (a)–(f) (blob assertion 28-entry
  allow-list in CI + backup; release.yml-free via harness_check family 7);
  the LEGAL-1 mechanics (manifest refusal ×4 shapes, formats lint); spec 1
  of 4 (`docs/formats/clearfile-json.md`, §7.5-clean). Suites RE-RUN
  (engines touched): analyze clean, 114/114, tsc 0, parity 17/17, bridge
  10/10, oracle 17/17, smoke 6/6, audit 0, tools 22/22, lint clean,
  harness_check 0. Files: the above + `fixtures/tax/16-*.json`,
  `.gitignore`, `scripts/{sandbox_backup,harness_check}.sh`,
  `.github/workflows/hygiene.yml`, `scripts/README.md`, README/engine.md
  count+8812 fixes, governance syncs. Fourteenth recycle hollowed
  node_modules MID-SESSION (npm ci restored); the Ghidra bench deleted
  for SDK disk space (rebuildable ~19 s + re-download; corpus + T2
  artifacts survived). Next: Stage-2 execution session 2 (the final one:
  3 remaining DoD specs + D34 + the exit-gate checklist); T2 session 3
  (D40) in its own lane.
- **2026-11-23** — **Stage-2 EXECUTION session 2 — the box CLOSED at
  exactly two sessions:** specs 2 + 3 of the N=4 DoD published
  (`docs/formats/tax-exchange-container.md` — the `.tax`-extension
  STORE-only ZIP exchange container, writer/reader field layout, the
  honest-labeling disclosure, the analysis behavior, code anchors both
  sides, and a differential note pinned by a NEW test; and
  `docs/formats/txf.md` — ClearFile's TXF v042 profile: grammar, the full
  refnum table, the four hard refusals, the writer profile) — both
  §7.5-clean/lint-clean; `tax-modern.md` awaits T3 as planned (no stub);
  **D34 CLOSED** (the shared `fixtures/migration/` family consumed by
  BOTH suites with EXACT ordered warning lists; the web reader's
  dependent-count clamp aligned to the Dart reference's 0..100 — the
  recorded drift fixed + pinned by the edge fixture on both sides; the
  store-vs-file W-2 shape documented in return-format.md §3); the 23rd
  RE-tool test (the exchange-container differential pair: one wage digit
  ⇒ exactly 3 regions). Suites RE-RUN (code touched): analyze clean,
  115/115, tsc 0, parity 17/17, bridge 11/11, oracle 17/17, smoke 6/6,
  audit 0, tools 23/23, blob clean, lint 3/3, harness_check 0. Files:
  the two specs + the three fixtures/migration files, cfr.ts,
  return_format_test.dart, txf_taxfile_test.mjs, test_re_tools.py,
  docs/return-format.md, README count syncs, governance syncs.
  Fifteenth recycle wiped tools/ (SDK re-fetched + sha256-verified,
  resumable across two calls; the TT corpus + Ghidra bench re-acquired
  at the next T2/Phase-4 session). Next: T2 session 3 (D40) in the TT
  lane; the Stage-2 EXIT gate convenes when T3 unlocks `tax-modern.md`
  (checklist otherwise green).

## Recent Progress & Git Activity

```diff
### Commit: fa678f9 - backup(sandbox): Stage-2 execution session 1 (PROD-2 DISCHARGED, the first tooling commit carries every entry condition): ENG-3/D33 the survivingSpouse (QSS) golden fixture #17 landed (all pins verified from the fetched primary sources: Pub 501's MFJ Tax Table column + Section B TCW + the QSS-under-65 sd row 31,500; the QDIVCG worksheet lines 6/13 naming 'married filing jointly or qualifying surviving spouse' at 96,700/600,050; Topic 559's 250,000 MFJ/QSS NIIT threshold; Form 8812 line 9's 'Married filing jointly-400,000 / All other filing statuses-200,000') and it FOUND A LIVE ENGINE BUG: the QSS CTC phase-out start is 200,000 not the MFJ 400,000 both engines carried (QSS is an 'other filing status' - Pub 501: the status 'doesn't entitle you to file a joint return'; the internal equivalence test sat at 90k wages, below both thresholds, which is why it never fired) - fixed in all three parameter tables (tax_year.dart + config.ts + verify_golden_fixtures.py, each carrying the 8812-line-9 citation) + docs/engine.md; the Dart internal QSS==MFJ rate/sd test still passes (correctly - those mappings stand); the Phase 1-3 RE tools landed tracked under the binding security contract (re_entropy per-block Shannon; re_magic any-offset magic scan with MZ pinned to offset 0 + text/JSON/XML sniff; re_diff differential with offsets/lengths/entropy only, never bytes) - write-free (read-only opens, no shell-outs, no network), resource-bounded (size/block/hits/region caps + signal wall-clock timeouts, EVERY cap refusal-tested: clean message + exit 3, never a crash), crash-safe (ENG-1-shaped empty/truncated/adversarial battery reports, never throws), posture in each header + --help (D38 registered for Phase 1-3; T4 extraction tools still owe it); the 22-test unit suite with synthetic-only fixtures runtime-generated under the gitignored fixtures/re/ path incl. the read-only-fixture-dir write-freedom proof (chmod 0555) and the differential exercised on a SYNTHESIZED pair inside mandatory spec family #1 (two clearfile.json v2 envelopes differing in one W-2 wage digit - exactly one 1-byte region localized); ADR-012 mechanics (a)-(f) all landed with this first tooling commit: (a) fixtures/re/ enumerated + gitignored; (b) check_binary_blobs.py - the allow-listed no-binary-blob assertion (measured 28 own assets: blueprint PNGs/PDF + Flutter-tooling icons; any new binary under fixtures/ tools/ docs/ src/ scripts/ harness/ fails CI) in hygiene.yml's new re-tooling job; (c) the same allow-list wired into sandbox_backup.sh after git add -A (mechanical auto-publish denylist, exit-2 refusal); (d) the 7.5 checklist recorded per spec + lint_format_specs.py enforcing the provenance field + no-32-hex + no image embeds + no placeholders in CI; (e) release.yml references zero RE tooling (asserted); (f) no tracked Phase-4 binaries (the blob assertion is the mechanical proof); LEGAL-1 mechanics: the differential tool's provenance-manifest refusal per 7.1 (four refusal shapes unit-tested: no manifest, missing entry, bad provenance, malformed manifest); the first spec toward N=4 published: docs/formats/clearfile-json.md (owner-authored family: v2 envelope + v1 + legacy flat + .cfr alias; provenance section; per-field verified-by experiments; the applied 7.5 checklist); harness_check grew family 7 (ADR-012 (a)/(e) assertions); suites RE-RUN not carried (the engines were touched): flutter analyze clean + flutter test 114/114 (97 + 17 golden - the QSS fixture green against the fixed engine), tsc --noEmit exit 0 (locally green this time), web parity 17/17 zero field failures, bridge 10/10, oracle 17/17, web smoke 6/6, npm audit --omit=dev --audit-level=critical exit 0 (0 criticals), RE tools 22/22, blob assertion clean (315 tracked / 28 allow-listed), formats lint 1/1 clean, harness_check 0 failures; README/engine.md count + 8812-row syncs (114/17 everywhere); fourteenth recycle hollowed node_modules MID-SESSION (the npm tsc-squatter banner re-appeared, quirk 18 re-confirmed mid-session; npm ci restored it) and disk pressure at the SDK install cost the rebuildable Ghidra bench (tools/ghidra+jdk+rea deleted for the verified Flutter SDK extraction; corpus + T2 chase artifacts + re-env survived; the next T2/Phase-4 session rebuilds it first); DEBT: D33 closed with the premise correction (200k not 400k), D38's Phase 1-3 half discharged; next: Stage-2 execution session 2 (the box's final: the remaining three DoD specs + D34 + the exit-gate checklist) and T2 session 3 (D40) in the TT program's own lane @ 2026-11-22T11:58:42Z (Z User, 2026-11-22)
 .github/ISSUE_TEMPLATE/engine-discrepancy.md     |   0
 .github/ISSUE_TEMPLATE/format-discrepancy.md     |   0
 .github/workflows/hygiene.yml                    |  21 ++
 .github/workflows/release.yml                    |   0
 .gitignore                                       |   8 +
 LICENSE                                          |   0
 PROJECT_MEMORY.md                                | 129 +++++---
 README.md                                        |  10 +-
 SECURITY.md                                      |   0
 THIRD-PARTY-NOTICES.md                           |   0
 blueprint-assets/01-welcome.png                  | Bin
 blueprint-assets/02-status.png                   | Bin
 blueprint-assets/03-income.png                   | Bin
 blueprint-assets/04-results.png                  | Bin
 blueprint-assets/05-settings.png                 | Bin
 blueprint-assets/06-results-dark.png             | Bin
 blueprint-assets/07-mobile.png                   | Bin
 blueprint-assets/architecture.html               |   0
 blueprint-assets/architecture.png                | Bin
 blueprint-assets/body.pdf                        |   0
 blueprint-assets/cover.html                      |   0
 blueprint-assets/cover.pdf                       | Bin
 clearfile/lib/io/return_format.dart              |   0
 clearfile/lib/io/tax_inspect.dart                |   0
 clearfile/lib/io/txf_import.dart                 |   0
 clearfile/lib/models/tax_year.dart               |   7 +-
 clearfile/lib/ui/app_state.dart                  |   0
 clearfile/lib/ui/screens/assistant.dart          |   0
 clearfile/lib/ui/screens/interview.dart          |   0
 clearfile/lib/ui/screens/results.dart            |   0
 clearfile/lib/ui/screens/settings.dart           |   0
 clearfile/lib/ui/screens/welcome.dart            |   0
 clearfile/lib/ui/shell.dart                      |   0
 clearfile/lib/ui/steps/deductions_step.dart      |   0
 clearfile/lib/ui/steps/dependents_step.dart      |   0
 clearfile/lib/ui/steps/income_step.dart          |   0
 clearfile/lib/ui/steps/payments_step.dart        |   0
 clearfile/lib/ui/steps/status_step.dart          |   0
 clearfile/lib/ui/widgets/money_field.dart        |   0
 clearfile/test/delete_regression_test.dart       |   0
 clearfile/test/fakes.dart                        |   0
 clearfile/test/golden_fixtures_test.dart         |   0
 clearfile/test/money_parse_test.dart             |   0
 clearfile/test/privacy_test.dart                 |   0
 clearfile/test/return_format_test.dart           |   0
 clearfile/test/steps_test.dart                   |   0
 clearfile/test/tax_inspect_test.dart             |   0
 clearfile/test/txf_import_test.dart              |   0
 clearfile/web/favicon.png                        | Bin
 clearfile/web/icons/Icon-192.png                 | Bin
 clearfile/web/icons/Icon-512.png                 | Bin
 clearfile/web/icons/Icon-maskable-192.png        | Bin
 clearfile/web/icons/Icon-maskable-512.png        | Bin
 clearfile/web/index.html                         |   0
 clearfile/web/manifest.json                      |   0
 components.json                                  |   0
 docs/blueprint.pdf                               | Bin
 docs/engine.md                                   |   2 +-
 docs/formats/clearfile-json.md                   | 136 ++++++++
 docs/ghidra-sandbox-feasibility.md               |   0
 docs/re-research/2026-11-22-tt-t2-reader.md      |   0
 docs/re-research/2026-11-22-tt-t2-session2.md    |   0
 docs/re-research/2026-11-22-tt-targets-phase1.md |   0
 docs/re-research/corpus-manifest.md              |   0
 docs/return-format.md                            |   0
 docs/reverse-engineering-protocol.md             |   0
 docs/tour.md                                     |   0
 eslint.config.mjs                                |   0
 harness/README.md                                |   0
 harness/WORKFLOW.md                              |   0
 harness/adversarial/CONSENSUS.md                 |   0
 harness/adversarial/ROLES.md                     |   0
 harness/memory/DEBT.md                           |  14 +-
 harness/memory/DECISIONS.md                      |   0
 harness/memory/ROADMAP.md                        |  38 ++-
 harness/memory/SESSION_LOG.md                    | 143 ++++++++
 harness/memory/STATE.md                          | 166 +++++-----
 next.config.ts                                   |   0
 package.json                                     |   0
 postcss.config.mjs                               |   0
 prisma/schema.prisma                             |   0
 public/logo.svg                                  |   0
 public/robots.txt                                |   0
 scripts/README.md                                |  41 +++
 scripts/ai_provider_tests.py                     |   0
 scripts/check_binary_blobs.py                    | 132 ++++++++
 scripts/diag_reasoning.py                        |   0
 scripts/fetch_flutter_sdk.sh                     |   0
 scripts/fetch_tt_corpus.sh                       |   0
 scripts/generate_blueprint.py                    |   0
 scripts/harness_check.sh                         |  22 ++
 scripts/lint_format_specs.py                     | 111 +++++++
 scripts/merge_blueprint.py                       |   0
 scripts/openrouter_explore.py                    |   0
 scripts/re_diff.py                               | 260 +++++++++++++++
 scripts/re_entropy.py                            | 178 ++++++++++
 scripts/re_magic.py                              | 194 +++++++++++
 scripts/repair_spdx_insertion.py                 |   0
 scripts/sandbox_backup.sh                        |  16 +
 scripts/test_re_tools.py                         | 394 +++++++++++++++++++++++
 scripts/tsconfig.files.json                      |   0
 scripts/tsconfig.parity.json                     |   0
 scripts/txf_taxfile_test.mjs                     |   0
 scripts/verify_blueprint.py                      |   0
 scripts/verify_golden_fixtures.py                |   7 +-
 scripts/web_parity_test.mjs                      |   0
 src/app/api/route.ts                             |   0
 src/app/globals.css                              |   0
 src/app/layout.tsx                               |   0
 src/app/page.tsx                                 |   0
 src/components/clearfile/ai-ui.tsx               |   0
 src/components/clearfile/filemenu.tsx            |   0
 src/components/clearfile/settings.tsx            |   0
 src/components/clearfile/shell.tsx               |   0
 src/components/clearfile/steps.tsx               |   0
 src/components/ui/accordion.tsx                  |   0
 src/components/ui/alert-dialog.tsx               |   0
 src/components/ui/alert.tsx                      |   0
 src/components/ui/aspect-ratio.tsx               |   0
 src/components/ui/avatar.tsx                     |   0
 src/components/ui/badge.tsx                      |   0
 src/components/ui/breadcrumb.tsx                 |   0
 src/components/ui/button.tsx                     |   0
 src/components/ui/calendar.tsx                   |   0
 src/components/ui/card.tsx                       |   0
 src/components/ui/carousel.tsx                   |   0
 src/components/ui/chart.tsx                      |   0
 src/components/ui/checkbox.tsx                   |   0
 src/components/ui/collapsible.tsx                |   0
 src/components/ui/command.tsx                    |   0
 src/components/ui/context-menu.tsx               |   0
 src/components/ui/dialog.tsx                     |   0
 src/components/ui/drawer.tsx                     |   0
 src/components/ui/dropdown-menu.tsx              |   0
 src/components/ui/form.tsx                       |   0
 src/components/ui/hover-card.tsx                 |   0
 src/components/ui/input-otp.tsx                  |   0
 src/components/ui/input.tsx                      |   0
 src/components/ui/label.tsx                      |   0
 src/components/ui/menubar.tsx                    |   0
 src/components/ui/navigation-menu.tsx            |   0
 src/components/ui/pagination.tsx                 |   0
 src/components/ui/popover.tsx                    |   0
 src/components/ui/progress.tsx                   |   0
 src/components/ui/radio-group.tsx                |   0
 src/components/ui/resizable.tsx                  |   0
 src/components/ui/scroll-area.tsx                |   0
 src/components/ui/select.tsx                     |   0
 src/components/ui/separator.tsx                  |   0
 src/components/ui/sheet.tsx                      |   0
 src/components/ui/sidebar.tsx                    |   0
 src/components/ui/skeleton.tsx                   |   0
 src/components/ui/slider.tsx                     |   0
 src/components/ui/sonner.tsx                     |   0
 src/components/ui/switch.tsx                     |   0
 src/components/ui/table.tsx                      |   0
 src/components/ui/tabs.tsx                       |   0
 src/components/ui/textarea.tsx                   |   0
 src/components/ui/toast.tsx                      |   0
 src/components/ui/toaster.tsx                    |   0
 src/components/ui/toggle-group.tsx               |   0
 src/components/ui/toggle.tsx                     |   0
 src/components/ui/tooltip.tsx                    |   0
 src/hooks/use-mobile.ts                          |   0
 src/hooks/use-toast.ts                           |   0
 src/lib/ai/ladder.ts                             |   0
 src/lib/ai/tasks.ts                              |   0
 src/lib/db.ts                                    |   0
 src/lib/files/cfr.ts                             |   0
 src/lib/files/taxfile.ts                         |   0
 src/lib/files/txf.ts                             |   0
 src/lib/store.ts                                 |   0
 src/lib/tax/config.ts                            |   7 +-
 src/lib/tax/engine.ts                            |   0
 src/lib/utils.ts                                 |   0
 tailwind.config.ts                               |   0
 tsconfig.json                                    |   0
 update_memory.py                                 |   0
 178 files changed, 1890 insertions(+), 146 deletions(-)

### Commit: c9ec840 - backup(sandbox): T2 session 2 (D36 closed): the USA container format COMPLETED byte-end-to-end - entry fields A/B resolved (A = Win32 attributes bitmask w/ bit-1 alternate-create dispatch + set-attributes-when-not-0x20 post-extraction + the 0x20 archive default; B = the FIRST deflate chunk's compressed size, stream self-terminates at exactly B bytes - session 1's 90,000-B figure was the natural chunk output, not a bound artifact); the payload chunk grammar byte-proven ([deflate, B bytes] then ([u32 csize][raw Deflate] | [u32 0x80000000|size][stored raw])* [u32 0] terminator, next entry; observed output granularities 90,000 B + exactly 1 MiB; stored segments 382x1MiB+1 partial on Personal-USA); end-of-archive = a type-0 entry (observed 0x18141f55) followed by ~10 KB trailing DER PKCS#7 SignedData (SHA-384 + Microsoft OIDs at identifier level, existence recorded only); FUN_00418c60 full decompile: type 1=dir/2=file/0=end + a Thumbs.db create-failure special case + SetFileTime application + the 2,000,000-B working value; FUN_0041e5e0 CORRECTED to the entry parent-directory preparer (the session-1 codec-chain label was wrong; the pump = the indirect vtable call at 0x4191a9); the 0x80/0xc0/0x100 selector unresolved + reader-irrelevant; USA entry inventory (layer 1) = 3 entries (SetUp.exe 1,315,096 B out / config.xml existence-recorded-only per 7.4 / the payload installer) both USA targets; inner installer layer: USA = PE32 GUI link-2022-07-05 + InstallShield ISSetupStream v8 overlay ([u32 0x36][u32 6][u32 ~0x17580000]); CAN-Personal inner layer = plain ZIP (6 entries; setup.exe 7 sections link-2025-12-22) + the SAME 2022-07-05 bootstrapper family + ISSetupStream v7 (USA v8); CAN-Business = InstallShield-classic overlay [u32 19] + 4 UTF-16z fields (lang INI tag / Disk1 path / version / 22480 = the INI block size - the entropy boundary lands exactly at overlay+20,480) + BOM'd UTF-16 INI message table (~20 KiB, not quoted per 7.4) + compressed file-group records from ~0xefa00; ALL FOUR TARGETS CONVERGE ON THE INSTALLSHIELD LAYER where the app modules (file-format/password routines) live -> D40 opened (the InstallShield-layer record walk + the app-module inventory residue); ZERO derived bytes written to disk this session (every decode bounded + in-memory - stricter than ENG-3); thirteenth recycle WIPED tools/ (the twelfth's survival was the exception - standing expectation re-confirmed; rebuilt: corpus 4/4 sha256-verified via the fetcher - SEC-4's mechanic proven on a real re-acquisition, Ghidra 12.2 + Temurin 25.0.5.1 + REA 6.10.1 rebuilt, doctor healthy, checkpoint re-established); 205 mode flips normalized before edits (quirk 19, no unpushed amend); no app code touched - suites carried (root node_modules survived but the box memory ceiling OOMs tsc at default + 2.8 GB - CI authoritative on this push); PROD-2 tripwire clock: 1 of 2 working sessions elapsed - Stage-2 session 1 convenes at the next working session; harness_check 0 failures; next: T2 session 3 (D40) + Stage-2 session 1 @ 2026-11-22T10:35:00Z @ 2026-11-22T10:00:27Z (Z User, 2026-11-22)
 PROJECT_MEMORY.md                             |  70 ++++++++----
 docs/re-research/2026-11-22-tt-t2-session2.md | 130 +++++++++++++++++++++++
 harness/memory/DEBT.md                        |   5 +-
 harness/memory/ROADMAP.md                     |  36 +++++--
 harness/memory/SESSION_LOG.md                 |  88 +++++++++++++++
 harness/memory/STATE.md                       | 147 +++++++++++++++-----------
 6 files changed, 382 insertions(+), 94 deletions(-)

### Commit: e03c589 - backup(sandbox): backup(sandbox): ADR-020 + the TT program's entry gate + T2 session 1 (owner directive: record the explicit risk-acceptance ADR for the shipped decryptor and proceed): ADR-020 recorded BEFORE any implementation exists (the owner's explicit risk acceptance - shipping the TT-format decryptor INCLUDING the fixed-key transport layer in the GPL product; boundary conditions binding: password-gated surface only w/ refusal tests, ONE quarantined key module w/ key values nowhere else, 7.2/7.4 unchanged, the enforcement-response plan; overturn path recorded) + dated protocol amendments (2.2/6/7.3 + the 7.4 runtime-screenshot extension) + the ADR-020 clarification annotation; the TT program's own gate CONVENED and PASSED 4x PROCEED-WITH-CONDITIONS unanimous (four isolated concurrent reviewers, reports filed near-verbatim in adversarial/reports/2026-11-22-tt-*.md, consensus + full condition ledger in CONSENSUS.md): the fixed-key re-argument with the acceptance on record (both sides: 321 Studios contra; 1201(f) texture + public-keys + password-authorization pro), the Canadian-law assessment DELIVERED (the C-11 TPM regime: a civil-only circumvention ban + a providing-services prohibition textually at least as broad as 1201(a)(2), an enumerated interoperability exception without means-sharing text, no fair-dealing override - comparable in principle, lower in practice), the security-contract application bound w/ the T4 merge-gate conditions named; IN-SESSION condition applications all tested: the backup secret guard widened to >=32-hex on RE-adjacent paths w/ the measured allow-list (canary end-to-end: a staged 32-hex file -> REFUSING exit 2, then cleaned) + the NOTE scan (SEC-3 early) + fetch_tt_corpus.sh mechanical sha256 verification vs the manifest (positive 4/4 live + the negative path proven function-level) + the phase-1 offset erratum (0x99000 - found by ADV-ENG's independent re-derivation, in the ENG-1 tradition) + DEBT D36-D39 + harness_check patterns updated for the legitimate advance (PENDING 10->9, the TT-entry count); T2 ENTERED - session 1 (the proceed): the reader pipeline chased to the archive-entry format via the REA pipeline w/ checkpoint mode ON (84 s first import -> ~11 s per command; REA rebuilt in-place after the recycle hollowed its compiled runtime): FUN_004189c0 -> FUN_0042a7a0 -> FUN_0042a850 (the name->value map at this+0x138), FUN_00418a50 IS the map builder (flat [u16 len][blob] stream, <=201 iterations, zero length terminates), FUN_00418710 = the 6-byte internal header ([u32][u16]: low byte = the name-encryption flag, high byte selects 0x80/0xc0/0x100, semantics unresolved, no constants observed), FUN_00401b2b -> FUN_00418c60 = the archive-entry state machine; byte-validated on the real target: entry magic 0x6d27e59b, type byte, u16 name-len, name (SetUp.exe - plaintext: the header flag is 0), u64 FILETIME, two u32 fields (0x20/0x9e67 - unresolved), payload BYTE-PROVEN raw Deflate (clean inflate -> an MZ PE = the inner SetUp.exe bootstrapper: i386, 5 sections, link 2026-10-15); bounded extraction 90,000 B deleted per ENG-3; NO encryption at this container layer (the fixed-key question does not arise at the installer transport; the .tax layer remains the T3/T4 study target); notes docs/re-research/2026-11-22-tt-t2-reader.md (7.5-clean; the LEGAL-4 scan clean); twelfth recycle: tools/ SURVIVED intact (4.0 GB - the quirk register revised to can-not-must; the bootstrap check stays mandatory), disk ~1.6 GB free the watch item; NO app code touched (scripts+docs+governance only - verified by the reviewers; suites carried, the local tsc bench degraded w/ CI authoritative on this push); harness_check 0 failures; next: T2 session 2 (D36: entry fields A/B + the chunked stream + the codec chain + the CAN layers) + Stage-2 session 1 under the PROD-2 starvation tripwire (within two working sessions of 2026-11-22) @ 2026-11-22T08:18:34Z (Z User, 2026-11-22)
 PROJECT_MEMORY.md                                | 128 +++++++++-------
 docs/re-research/2026-11-22-tt-t2-reader.md      | 102 +++++++++++++
 docs/re-research/2026-11-22-tt-targets-phase1.md |  10 ++
 docs/reverse-engineering-protocol.md             |  36 ++++-
 harness/adversarial/CONSENSUS.md                 | 184 +++++++++++++++++++++++
 harness/memory/DEBT.md                           |  15 ++
 harness/memory/DECISIONS.md                      | 104 +++++++++++++
 harness/memory/ROADMAP.md                        |  90 +++++++----
 harness/memory/SESSION_LOG.md                    |  83 ++++++++++
 harness/memory/STATE.md                          | 110 +++++++++-----
 scripts/fetch_tt_corpus.sh                       |  49 ++++--
 scripts/harness_check.sh                         |  12 +-
 scripts/sandbox_backup.sh                        |  23 +++
 13 files changed, 807 insertions(+), 139 deletions(-)
```

