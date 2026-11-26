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
| RE bench | gitignored `tools/`: REA 6.10.1 over Ghidra 12.2 + Temurin 25 (REA hard-requires ≥12.2); protocol-pinned 12.1.4 + JDK 21 fallback; corpus at `tools/re-corpus/` (sha256-verified by the fetcher). **Bench re-acquisition after a recycle: fetcher + adoptium API asset + `git clone morluto/rea` + tag `rea-agents-<v>` + `npm ci && npm run build:cached`; run `tools/rea_restore.sh` FIRST at every REA call (quirk 21's node_modules/dist hollowing workaround).** | Phase-4 runs under the RE protocol's guardrails (§2/§7): function facts only in notes; no decrypted content, no expression lifts. Password-based access = the shipped target; **the fixed-key layer = SANCTIONED for the shipped bridge scope by ADR-020** (owner risk acceptance; boundary conditions; §2.2/§7.3 amended-in-part; key VALUES only in the quarantined T4 module, by-existence everywhere else). REA checkpoint mode ON (`REA_GHIDRA_CHECKPOINT_DIR`; 84 s import → ~11 s/command). |
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

**Sandbox quirks (shortlist; full register of 21 in
`harness/memory/STATE.md`):** recycles flip file modes 644→755 —
normalize BEFORE editing (quirk 19: `git restore .` reverts unstaged
content edits); brief sessions have twice left unpushed mode-only
amends (2026-11-16, 2026-11-20) — reset to the pushed tip before edits;
background jobs die between Bash calls; tar's trailing restore fails
benignly on this FS; **quirk 21 (2026-11-23): `tools/<pkg>/node_modules`
AND `tools/<pkg>/dist` are hollowed at every Bash-call boundary (root
node_modules unaffected) — keep hardlink backups under other names
(`rea_nm`/`rea_dist`) + `tools/rea_restore.sh` (`cp -ald`) at the start
of every REA call.**

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
- [x] T2 session 3 (2026-11-23): **the InstallShield-layer record walk
      COMPLETED (D40 closed)** — the ISSetupStream v7/v8 record format
      byte-proven + decompile-anchored: the 0x2e stream header; the 0x30
      v4 record header ([u32 namelen][u32 flags=6][u16 0][u32 dsize]
      [u32 0][u32 0][u16 1][FILETIME ×3] + UTF-16 name + payload; the
      table length IS the u16@0x0e version label — 8/8/7 records walked);
      **the payload codec = name-keyed XOR → zlib-wrapped deflate** (the
      key = the record's own UTF-8 filename masked `13 35 86 07`,
      nibble-swap/complement byte op, 1024-phase — engine anchors
      FUN_00452b16/452eda/453675/45374c/452ffa/406780/453c70/4534d8/
      42009f/40c0a8/40c10b/40c1c2 + zlib 1.2.12's lbase/dbase);
      validated on BMP/INI/.isc/.prq/MSI records on BOTH v8 and v7;
      **the app-module inventory ENTERED**: each MSI's OLE parsed
      (corrected FAT block-keying) → the embedded MSCF cabinet →
      **6,503 entries** (a CEF architecture; the format-relevant module
      class identified at existence level: ttax / fps_engine / the MEF
      converter / the interview-service converter / the libcrypto
      family / the `.1pe` FDI packs; the UI IA surface = the CEF/JS
      layer); the CAN-Business classic framing byte-proven (the cab
      manifest cluster + the `ISc` magic + the compressed stream at
      0xef47a); the session-2 header-arithmetic erratum corrected —
      `docs/re-research/2026-11-23-tt-t2-session3.md` (§7.5-clean,
      LEGAL-4 scan clean); D41 opened for the residues.
- [ ] T3: format-family specs incl. the password layer (Phase-5
      template, §7.5-clean; namespace rule: never count toward
      Stage-2's N=4).
- [x] T3 session 1 (2026-11-23): ENTERED — the MSI-cab codec
      byte-proven (the InstallShield MSZIP window-carry variant:
      TComp=0x0001 everywhere; per-block CK-marked COMPLETE
      raw-deflate streams whose distance codes reach the previous
      block's output — the plain-MSZIP decode fails "distance too
      far back", the empirical discriminator; the ctypes zlib
      inflateReset+inflateSetDictionary rolling-window decoder;
      859/859 blocks of folder 87 → the arithmetic closure at exactly
      28,140,152 B); the ttax engine DLL carved (26,137,680 B, the
      one resident gitignored module) + triaged (PE32+ x64
      mixed-mode MFC/mscoree; .text 17.47 MB; 58,890 .pdata
      functions; no ole32 import + zero structured-storage constants
      — the .tax container is NOT OLE in this module); the .tax-layer
      anchors identified (the IData:: serialization family = the
      data-layer API; embedded Crypto++ = the primitives; the
      save-dialog password surface + the read-path password service;
      the z-prefixed bridge commands; the "legacy ttax.dll"
      self-identity); the REA entry map built without Ghidra (the
      lea-rip xref scan → 89 xrefs → 67 .pdata-anchored functions;
      the password constants draw zero direct lea xrefs — indirect
      consumption) — `docs/re-research/2026-11-23-tt-t3-session1.md`
      (§7.5-clean); D42 opened.
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
- **2026-11-23 (later)** — TT program T2 session 3: **D40 CLOSED** (the
  InstallShield-layer record walk + the app-module inventory entry —
  see the playbook checkbox above for the full result). Corpus 4/4
  re-verified + the Ghidra bench rebuilt (doctor healthy); the
  sixteenth recycle spared git/SDK/node_modules; the 1.5 GB tarball
  residue deleted after the SDK smoke test. New quirk 21 (the
  per-call-boundary node_modules/dist hollowing under tools/ +
  `tools/rea_restore.sh` hardlink workaround) + one transient
  single-byte decode anomaly (triple-verified + corpus re-sha256'd
  intact). Files: `docs/re-research/2026-11-23-tt-t2-session3.md`,
  gitignored `tools/re/t3_*.py` bench scripts + `tools/rea_restore.sh`,
  governance syncs (DEBT D40/D41, SESSION_LOG, STATE, this file). No
  app code touched — suites carried from `1ed3c88` (CI authoritative on
  this push). Next: T3's format-family study (the `.tax` + password
  layer, now anchored by the module inventory) → unlocks
  `tax-modern.md` + the Stage-2 EXIT gate; the D41 residues ride the
  T2 lane whenever convenient.
- **2026-11-23 (latest)** — **the prior session's interrupted backup
  normalized (the teardown backup is the fragile step at context
  exhaustion: a UUID-message local commit sat unpushed; verified
  against the SESSION_LOG teardown record, soft-reset + guards
  re-run + pushed as `8f9db50`) + TT program T3 session 1:** the
  MSI-cab codec byte-proven (the InstallShield MSZIP window-carry
  variant + the ctypes zlib setDictionary decoder, 859/859 blocks),
  the ttax engine DLL carved + triaged (the .tax-layer host:
  IData::/Crypto++/password surface; no OLE), the REA entry map
  (67 functions, no Ghidra this session — the 26 MB import exceeds
  the single-call budget). Files:
  `docs/re-research/2026-11-23-tt-t3-session1.md`, gitignored
  `tools/re/tt3_*.py` + `tools/re/ttax_engine.dll`, governance syncs
  (DEBT D42, SESSION_LOG, STATE, this file). No app code touched —
  suites carried from `8f9db50` (CI authoritative on this push).
  Next: T3 session 2 — the password-layer construction chase
  (the IData:: call sites + the entry-map decompile; the REA
  import strategy per D42) → then the format-family spec drafts;
  D41/D42 residues ride their lanes.

## Recent Progress & Git Activity

```diff
### Commit: 37f1a5c - backup(sandbox): N2 session 2 CHECKPOINT 1 - the Linux app + the CI lane land. The app (apps/linux, deadline-recovered: the agent hit the context deadline with complete-but-unverified work, reviewed + completed by the orchestrator): ui/app.slint (the MD3-from-seed themed window - the role colors from the core palette module; the honest demo disclaimer + the no-AI/no-network note + the prototype label), src/main.rs (the ONE shared pipeline fn load_and_compute - structurally shared by the window + the headless mode per ENG-6; the argv surface --headless/--smoke/<path>; the honest named errors in the core's wording family; the ZIP-signature dispatch), the build.rs + the slint-build dependency (the ONE added dependency of the session, documented; the compat-1-18 forward-compat feature the build.rs fail-closed gate requires), the 5 unit tests incl. the migration-idempotence property (a re-encoded v2 model imports warning-free) + the byte-exact headless text pinned by tests/expected-headless.txt (regenerated from the actual output, the path normalized). Local verification: cargo test --locked 5/5 green; the --headless run byte-exact; the window path starts under Xvfb:99 + SLINT_BACKEND=winit-software reaching the expected local libxkbcommon-x11 panic (the CI runner apt-installs it - the recorded finding). The CI lane (hygiene.yml, the existing jobs byte-identical): the new Linux-app job with the rustc>=1.95 fail-closed MSRV guard FIRST, the app unit tests, the headless smoke diffed against the committed expected text, the window smoke (apt libxkbcommon-x11 + DIRECT Xvfb :99 - not xvfb-run, xauth absent - + winit-software + a timeout with failure asserted + no leftover Xvfb), and cargo-deny (the SHA-pinned EmbarkStudios/cargo-deny-action 81891abc19 v2.1.4 - the recorded two-mechanism choice (a), same trust class as the accepted gitleaks action) over the committed 539-package lock. The orchestrator's fixes during review: the Debug derive, the idempotence assertion correction, the compat-1-18 feature, the expected-text regeneration. Core stays 170/170 green. Remaining for session 2: the R1/R2 hardenings + the teardown + the N2 exit gate. 0 failures @ 2026-11-26T17:3xZ @ 2026-11-26T17:24:23Z (Z User, 2026-11-26)
 .github/workflows/hygiene.yml          |  85 +++++
 apps/linux/Cargo.toml                  |  17 +
 apps/linux/build.rs                    |  10 +
 apps/linux/src/main.rs                 | 605 ++++++++++++++++++++++++++++++++-
 apps/linux/tests/expected-headless.txt |  42 +++
 apps/linux/ui/app.slint                | 330 ++++++++++++++++++
 6 files changed, 1076 insertions(+), 13 deletions(-)

### Commit: 39bdc22 - backup(sandbox): N2 session 1 CLOSED - D44 complete + the apps/linux scaffold + every guard joined. The palette chunks (ad6bce2 + 69c8dda): core/src/palette.rs 2037 lines (the color math + Hct with the exact solver incl. the programmatically-extracted 255-entry critical-planes table; the tonal palettes + SchemeTonalSpot + the 34 MaterialDynamicColors roles with the RoleWiring structural restructure, the pair-member contrast curves, the stayTogether push, the highestSurface bindings, the surface-container ladder through the real ContrastCurve lerp) + palette_port.rs (19,998 ladder checks + 2,244 role checks, all ARGB-exact, mutation-sanity-proven) + THIRD-PARTY-NOTICES.md's Apache-2.0 translation entry (the core's first third-party-derived material). cargo test 170/170. The scaffold: apps/linux (Cargo.toml - slint bound 1.19 default-features-off with femtovg+software, skia EXCLUDED, clearfile-core as the direct path dep; the committed 539-package lock; deny.toml with the closed GPL-3.0-only-compatible allow-list + the Slint GPL-3.0-only ELECTION comment with the LicenseRef ids deliberately absent; the main.rs stub documenting the session-2 shape). The guards: the .gitignore target rule landed BEFORE any app build, apps joined the backup scan list, the harness_check palette ledger + scaffold-presence families (25 oks). Session 2 = the window UI + the headless pipeline + the CI lane (rustc>=1.95 guard, cargo-deny, both smokes) + the R1/R2 hardenings + the N2 exit gate. 0 failures @ 2026-11-26T17:0xZ @ 2026-11-26T16:39:48Z (Z User, 2026-11-26)
 .gitignore                    |  4 +++
 PROJECT_MEMORY.md             | 64 +++++++++++++------------------------------
 apps/linux/Cargo.toml         | 24 ++++++++++++++++
 apps/linux/deny.toml          | 54 ++++++++++++++++++++++++++++++++++++
 apps/linux/src/main.rs        | 18 ++++++++++++
 harness/memory/SESSION_LOG.md | 48 ++++++++++++++++++++++++++++++++
 harness/memory/STATE.md       |  4 ++-
 scripts/harness_check.sh      | 39 ++++++++++++++++++++++++++
 scripts/sandbox_backup.sh     |  2 +-
 9 files changed, 210 insertions(+), 47 deletions(-)

### Commit: 69c8dda - backup(sandbox): N2 session 1 CHECKPOINT 3 - D44 COMPLETE: the palette port lands (chunk 2: the tonal palettes + SchemeTonalSpot + the 34 MaterialDynamicColors roles + the full corpus verification). core/src/palette.rs = 2037 lines total (chunk 1's 888 intact): TonalPalette::of/tone (the L*-to-ARGB chain, the Dart cache dropped - pure per-call), the SchemeTonalSpot palettes (primary 36/secondary 16/tertiary hue+60/24/neutral 6/neutralVariant 8/error 25,84 per dynamic_scheme's default), the full role machinery (ContrastCurve, TonePolarity, ToneDeltaPair with the pair members' own contrast curves, the nearer/farther polarity, the delta expansion + the T50-59 awkward-zone stayTogether push, foreground_tone incl. the negligible-difference edge, the highestSurface bindings for onSurface-family + outline-family, the surface-container ladder through the real ContrastCurve lerp path) + the 34-role PaletteRole enum with the exhaustive camelCase name bijection. The corpus verification (core/tests/palette_port.rs): 33 seeds x 6 ladders x 101 tones = 19,998 + 33 x 2 x 34 roles = 2,244 ARGB-exact checks, all green; mutation sanity (a 1-unit chroma tweak fails, revert byte-identical). THIRD-PARTY-NOTICES.md gains the Apache-2.0 entry (the core's first third-party-derived material: a translation of Google's material_color_utilities 0.13.0, derived-not-vendored). cargo test --locked 170/170 green; zero dependencies held. Divergences recorded in-code (the cache drop, the RoleWiring structural restructure making Dart's !-asserted invariants structural, the tonalSpot-unreachable arms dropped, the ALL const). The public API: TonalPalette::of/tone, scheme_tonal_spot_palettes, PaletteRole, scheme_role. Next: the apps/linux scaffold + the session-1 teardown. 0 failures @ 2026-11-26T16:4xZ @ 2026-11-26T16:37:40Z (Z User, 2026-11-26)
 THIRD-PARTY-NOTICES.md     |   19 +
 core/src/palette.rs        | 1165 +++++++++++++++++++++++++++++++++++++++++++-
 core/tests/palette_port.rs |  200 ++++++++
 3 files changed, 1376 insertions(+), 8 deletions(-)
```

