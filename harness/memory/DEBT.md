# Technical-debt register

Findings accepted as debt (tracked here so future reviewers don't
"discover" them again). Source: Stage-0 adversarial review, 2026-11-14.
Each item carries its owner stage.

| ID | From | Debt | Stage |
| --- | --- | --- | --- |
| D1 | ADV-ENG #9 | `importReturn` conflates cancelled/unreadable/wrong-format into one silent null — needs a sealed result type + user feedback | **DONE 2026-11-15** (ADR-015): `ReturnImport` sealed outcome (cancelled / failed-with-reason / ok-with-warnings) returned from `files.dart`/`app_state.dart`, dialogs in `welcome.dart` mirror the TXF treatment; 14 codec tests pin it |
| D2 | ADV-ENG #10 | Money parsing duplicated (`money_field.dart` vs `csv_import.dart`); decimal-comma "6,5" parses as 65 silently; empty CSV wages cell parses as 0 — one shared `parseMoney()` + edge tests | **DONE 2026-11-14** — `util/money.dart parseMoney()` shared by both callers; comma-plus-1/2-digit shapes refused; 5 edge tests + CSV-path warning test |
| D3 | ADV-ENG #11 | `readDate` fabricates 1970-01-01 on unparseable dates; `fromJson` accepts any `formatVersion` — **no format change ships before a version guard** | **version-guard half DONE 2026-11-15** (ADR-015: unified envelope + refusal of unsupported versions in both readers, `docs/return-format.md` §7); the `readDate` epoch default is retained as documented tolerant-read behaviour (`docs/return-format.md` §2) |
| D4 | ADV-ENG #12 | FS I/O + raw autosave Timer inside a ChangeNotifier force the `runAsync` test convention — extract a `ReturnStore` interface seam so new widget tests use a fake store | **DONE 2026-11-14** — abstract `ReturnStore` + `FileReturnStore` + `test/fakes.dart` FakeReturnStore; step tests run outside runAsync |
| D5 | ADV-ENG #13 | AppState god-object: every keystroke recomputes + rebuilds the shell; `settingsStore.save()` fire-and-forget; `testConnection()` bypasses error state. Register only; rebuild not warranted at demo scale | — (register) |
| D6 | ADV-ENG #14 | `ValueKey(w2)` over value-equal mutable models — breaks if models become immutable (`copyWith`); settings `removeWhere` deletes ALL duplicate chain entries at once | **DONE 2026-11-14** — it was a LIVE crash (two blank W-2s = duplicate keys): ObjectKey identity keys + identity removal in both list steps; settings removeAt drops exactly one row; 3 guard tests pin it |
| D7 | ADV-ENG #15 | `clearfile/assets/sample_w2.csv` tracked but undeclared in pubspec + unreferenced (duplicated as `w2CsvTemplate`); android CI writes into tracked `clearfile/assets/` | **DONE 2026-11-14** — file removed (duplicate of the template const); android CI collects APKs under gitignored `clearfile/build/release-apks/` |
| D8 | ADV-ENG #17 | Parity drift: AI timeouts (Flutter 90 s both vs web 45/90 s); Google key in URL query (Flutter) vs header (web); web CTC $50-per-$1,000 units vs Flutter exact 5% | **DONE 2026-11-26 (Stage 5, both halves)** — the engine half 2026-11-15; the AI halves: googleAiTimeout 45 s / openrouterAiTimeout 90 s mirroring the web ladder (the OpenRouter `.timeout()` now actually APPLIED — it previously plumbed in without calling it, a live unbounded-wait bug), pinned by cascade_test's D8 test |
| D9 | ADV-ENG #19 | Slash-bearing tags (`v1.0.0/rc`) break artifact paths — now mitigated by RELEASE_TAG validation regex (only `[0-9A-Za-z._-]` after `v<digit>` passes) | mitigated (verify at next release) |
| D10 | ADV-SEC #7 | All actions pinned to mutable major tags — pin commit SHAs | **DONE 2026-11-14** — every `uses:` in `release.yml` + `hygiene.yml` pinned to 40-hex SHAs (lightweight tags resolved via `git ls-remote`, version in comment) |
| D11 | ADV-SEC #8 | Gemini key sent as URL query param in Flutter — switch to `x-goog-api-key` header | **DONE 2026-11-26 (Stage 5)** — providers.dart sends `x-goog-api-key`, never `?key=`; pinned by the header-discipline test (asserts the URL query is key-free) |
| D12 | ADV-SEC #9 | AI keys at rest in plaintext JSON, undisclosed in-app — disclose file+format in the Stage-1/5 privacy copy; `flutter_secure_storage` as stretch | **DONE 2026-11-26 (Stage 5)** — disclosure.dart (single source of truth, platform-accurate native/web) rendered in Welcome + Settings; the file+format named in-app (aiSettingsFileName); pinned by the two privacy_test disclosure tests (the secure-storage stretch remains out of scope per the maintenance freeze) |
| D13 | ADV-SEC #13 | No SECURITY.md; no vulnerability-disclosure channel | **DONE 2026-11-14** — root `SECURITY.md` (GitHub private vulnerability reporting, scope, disclosed postures, no invented SLAs) |
| D14 | ADV-LEGAL #5 | GPL per-file SPDX headers absent | **DONE 2026-11-14** — `SPDX-License-Identifier: GPL-3.0-only` line on 70 own-code files (vendored shadcn `src/components/ui/**` + `src/hooks/**` deliberately excluded — MIT-derived, never relabelled); insertion incident + repair recorded in SESSION_LOG |
| D15 | ADV-LEGAL #6 | `z-ai-web-dev-sdk` — REMOVED from package.json 2026-11-14 ✓ | done |
| D16 | ADV-LEGAL #7 | Flutter Google transport key-in-URL (= D11) | 5 |
| D17 | ADV-LEGAL #8 | Web auto-fill copy — **FIXED 2026-11-14** ("does not store" + auto-fill exception wording in ai-ui.tsx + settings.tsx; README scoped) | done |
| D18 | ADV-LEGAL #12 | Title de-"Filing"-ed — **FIXED 2026-11-14** (layout.tsx + blueprint PDF + cover) | done |
| D19 | ADV-PROD #6 | Harness self-enforcement: add `scripts/harness_check.sh` (CONSENSUS ↔ ROADMAP gate-status consistency; SESSION_LOG last entry postdates nothing unpushed) | **DONE 2026-11-14** — 11 checks (gate status, tiering, STATE freshness, test totals, mode drift, unpushed); dogfooded 0-failures; runs in CI via `hygiene.yml` |
| D20 | ADV-SEC #1 | INTERNET decision — **APPLIED 2026-11-14** (owner: add-and-disclose; manifest + entitlement + disclosures; v1.0.0 release description patched with the AI-broken note) | done |
| D21 | ADV-ENG #8 | Harness pointer drift — FIXED 2026-11-14 (§-refs audited, typo, STATE node_modules) ✓ | done |
| D22 | ADV-SEC Stage-1 #1 / LEGAL | README web-figures scoping — **FIXED 2026-11-14** (opt-in scoped to Flutter; web copilot + review-button + auto-fill exceptions stated) | done |
| D23 | ADV-ENG Stage-1 #1 | Switch-path autosave drop — **FIXED 2026-11-14** (`_open` flush + regression test) | done |
| D24 | ADV-ENG Stage-1 #4 | `store.ts` migrate shape checks — **FIXED 2026-11-14** (Array.isArray/object checks) | done |
| D25 | ADV-LEGAL Stage-1 #4 | Grandfathered `sendReturnContext` consent — **FIXED 2026-11-14** (ADR-011: schemaVersion 2 + legacy reset) | done |
| D26 | ADV-SEC Stage-1 #4 | `bun.lock` drift — **FIXED 2026-11-14** (deleted; npm standardized) | done |
| D27 | ADV-SEC Stage-1 #1 | Web figures toggle equivalent — deferred to Stage-3 parity scope (documented in README now) | 3 |
| D28 | ADV-ENG Stage-2 ENG-3 | `MoneyField` silently ignores comma shapes (`money_field.dart:69-70`) while CSV import warns — fold into the Stage-3 parser-hardening tests | 3 |
| D29 | ADV-ENG Stage-2 ENG-5 | Tag-PUSH trigger path of the release guard unverified (both live proofs were dispatches; an annotated-tag push may peel to the tag-object SHA and be refused fail-closed) — verify once at the NEXT tagged release, or drop the push trigger for dispatch-only | **DONE 2026-11-26 (the v1.1 release)** — verified live: the annotated-tag push fired the trigger and the guard REFUSED fail-closed (on a tag-push event the runner already holds the tag from checkout, so the guard's fetch of the same refspec clobbers — a non-missing-ref error; and an annotated tag's GITHUB_SHA is the tag OBJECT). The release shipped via the proven dispatch path (run green, release 459120788). The guard then FIXED in all 7 bodies (prefer the LOCAL tag when present; peel BOTH sides via `^{commit}`) + test_tag_guard.sh extended 4 → 6 scenarios (de-fragilized at the gate: scenario 6 pinned to the provably-different v1.0.1 target) and wired into hygiene CI |
| D30 | ADV-SEC Stage-2 SEC-2/SEC-4 | Owner-side hardening standing recommendations: Dependabot alerts, branch protection on `main`, PAT expiry (see WORKFLOW §5) — re-affirmed by the Stage-2 entry gate | owner-side |
| D31 | Stage-3 fixtures-first (2026-11-14) | Engine simplifications deliberately NOT pinned by the golden fixtures: (a) ACTC allocation between CTC and ODC in the partial-absorption zone (engine subtracts the whole non-refundable credit from the CTC portion; Schedule 8812's Part II-A has its own allocation) — fixtures avoid the ambiguous zone; (b) the student-loan worksheet's "rounded to at least three places" is read as exact precision (existing calculator test pins 1,333.33 at MAGI 92k where a 3-place worksheet gives 1,332.50) — the SLI fixture uses the unambiguous 0.500 midpoint; (c) marginal rate is computed on ordinary taxable only (QDI-heavy returns report the ordinary schedule's rate) — no fixture asserts marginalRate | Stage-3 parity set (**shared by both engines since the 2026-11-15 port**) |
| D32 | Stage-3 web parity (2026-11-15) | The web engine's previously projected TY2026 parameters were **dropped**: the reference engine (the parity truth per ADR-009) has no TY2026 parameter set, and inventing one would re-open the silent-divergence gap ADR-009 closed. Web store + `.cfr` v1 loader migrate old saves to TY2025 (conservative field mapping; adjustments/medical/other dropped — warnings shown; counts → placeholder dependents). Reinstate when the reference gains verified TY2026 parameters. | whenever the reference gains TY2026 |
| D33 | Stage-2 entry gate ENG-3 (2026-11-17) | No golden fixture exercises **survivingSpouse (QSS)** — the parity contract's only completely unpinned filing status (currently pinned only by an internal Dart equivalence test; the TS/oracle sides by nothing). One QSS fixture (pins the MFJ-column table lookup + sd 31,500 + CTC 400k + QDI 96,700/600,050 + NIIT 250k) consumed by ALL THREE runners (Dart, `web_parity_test.mjs`, `verify_golden_fixtures.py`), cited to the IRS publication carrying the QSS→MFJ-column rule. | **DONE 2026-11-22 (Stage-2 execution session 1)** — `fixtures/tax/16-surviving-spouse-qss-mapped-thresholds.json`, all three runners green. **Correction to the debt's own premise: the CTC threshold is $200,000 for QSS, NOT $400k** — Form 8812 (2025) line 9: "Married filing jointly—$400,000 / All other filing statuses—$200,000", and Pub 501: the status "doesn't entitle you to file a joint return"; the fixture found and forced the fix in all three parameter tables (the QSS→MFJ column equivalence applies to rates/sd/QDI/NIIT thresholds — 96,700/600,050/250,000 name QSS explicitly — never to the joint-return-keyed CTC threshold). The QDI breakpoints are not numerically discriminated at this fixture's income (ordinary taxable exceeds every 0% cap); they are pinned structurally by the parameter-table citations (QDIVCG lines 6/13 name "married filing jointly or qualifying surviving spouse"). |
| D34 | Stage-2 entry gate ENG-4 (2026-11-17) | The v1→v2 conservative migration is triple-implemented (`cfr.ts:73`, `store.ts:140`, `return_format.dart:172`) with fragment-level warning pinning and edge drift (Dart clamps child counts at 100; warning lists pinned only by `contains` fragments; `store.ts:155` reads the v1 *store* W-2 shape vs the file readers' v1 *file* shape — legitimate vintages, documented nowhere). Fix: lift the identical v1 sample into a shared fixture, assert exact warning lists in both suites, document the store-vs-file W-2 shape difference in `docs/return-format.md` §3. | **DONE 2026-11-23 (Stage-2 execution session 2)** — `fixtures/migration/` (the identical v1 sample + the edge-clamp fixture + the provenance/contract README) consumed by BOTH suites asserting the exact ordered warning lists (`return_format_test.dart` 15 tests; bridge suite 11 groups); the recorded edge drift FIXED not just documented (the web file reader's dependent-count clamp aligned to the Dart reference's 0..100 bound, pinned by the edge fixture on both sides); the store-vs-file W-2 shape difference documented in `docs/return-format.md` §3 incl. the silent-by-design store migration note |
| D35 | Stage-2 entry gate ENG-8 (2026-11-17) | `listReturns` drops decode warnings silently (`return_store.dart:57` uses only `.filing`). Harmless today (store-origin legacy files produce no warnings) but a future envelope bump would make store-dir warnings invisible. Register, don't fix. | register |
| D36 | TT gate / T2 session 1 (2026-11-22) | The USA container's entry semantics are partially derived: field A (0x20) and field B (0x9e67) after the entry FILETIME are unresolved (chunk-size / compressed-size candidates); the payload stream's chunking (first bounded decode yielded 90,000 B before the 1 MiB bound) and the codec chain (FUN_0041e5e0 et al.) are un-chased; the CAN-Personal inner ZIP and CAN-Business InstallShield layers are not yet entered. Full map: `docs/re-research/2026-11-22-tt-t2-reader.md`. | **DONE 2026-11-22 (T2 session 2)** — `docs/re-research/2026-11-22-tt-t2-session2.md`: A = Win32 attributes bitmask, B = first-chunk compressed size; chunk grammar byte-proven (raw-Deflate chunks + 0x80000000-flagged stored segments + [u32 0] terminator + type-0 end-entry + ~10 KB trailing PKCS#7 SignedData); FUN_0041e5e0 corrected to the parent-dir preparer; CAN-Personal inner layer mapped (plain ZIP → same bootstrapper family + ISSetupStream v7); CAN-Business manifest table mapped (header fields + INI-block size field + entropy boundary). Residue transferred to D40 |
| D40 | T2 session 2 (2026-11-22) | The InstallShield-layer record walk is un-entered: the ISSetupStream v7/v8 payload record format, and the CAN-Business classic file-group record framing (from ≈0xefa00); the app-module inventory (the file-format/password routines) stops at the InstallShield boundary. Residue: the internal-header selector (0x80/0xc0/0x100) semantics unresolved but reader-irrelevant; the end-entry's trailing-field semantics ambiguous; the pump's vtable identity at 0x4191a9 (indirect — codec byte-proven regardless). | **DONE 2026-11-23 (T2 session 3)** — `docs/re-research/2026-11-23-tt-t2-session3.md`: the ISSetupStream v7/v8 record format byte-proven + decompile-anchored (the 0x2e stream header + the 0x30 v4 record header + the name-keyed XOR-then-zlib payload codec — the key = the record's own UTF-8 name masked with `13 35 86 07`, nibble-swap/complement, 1024-phase; validated on BMP/INI/.isc/.prq/MSI records on BOTH the v8 and v7 targets); the tables walked end-to-end (8/8/7 records for Personal-USA/Business-USA/CAN-Personal incl. each MSI's dsize); the app-module inventory ENTERED via the MSI's embedded MSCF cabinet (6,503 entries parsed — the 106-DLL/CEF architecture + the format-relevant module class incl. ttax/fps_engine/mefpp/interview/libcrypto); the CAN-Business classic framing byte-proven (the cab-manifest cluster + the ISc magic + the compressed stream start at 0xef47a). Residue transferred to D41 |
| D41 | T2 session 3 (2026-11-23) | The D40 residues: (a) the CAN-Business classic `ISc` cabinet's internal file table + the InstallShield-classic compression codec are un-entered (the CAN-Business app-module inventory is one layer in); (b) the MSI table-stream name encoding (the CJK-range transformed names) is observed but not deciphered — the inventory method (the MSCF entry table) does not depend on it; (c) the UI functional-layout study is entered (the CEF/JS surface identified) but not executed; (d) the MSI's own table decode (File/StringData columns) not needed for the census but available as a future refinement. | next T2/T3 session |
| D42 | T3 session 1 (2026-11-23), updated 2026-11-26 | The .tax-layer construction chase residues: (a) the password-layer construction (the KDF/cipher over the embedded Crypto++, the password check path, the ADR-020 fixed-key transport boundary) is un-entered — the entry map is built (`docs/re-research/2026-11-23-tt-t3-session1.md`: 67 .pdata-anchored functions) but no decompile ran this session; (b) the .tax CONTAINER format's host is unresolved — the engine module has no ole32 import and zero structured-storage constants (not OLE inside it); candidates: the IData:: stream layer itself or CommonUtils/fps-engine; (c) the REA import strategy for the 26 MB module (single-call budget vs the .pdata-bounded targeted decode); (d) the mixed-mode export-table parse glitch (the `.nep` section mapping). | T3 session 2 |
| D37 | TT gate ENG-7 (2026-11-22) | The T4 bridge's codec layer must stay pure/portable (no Flutter I/O imports) so the ADR-017 N1 Rust-core port does not face a second unplanned migration — the TT codecs sit outside ADR-017's recorded core scope. | T4 design |
| D38 | TT gate ENG-5 (2026-11-22) | The security contract (write-confined to gitignored dirs, resource-bounded with refusal tests, crash battery per the ENG-1 template, never wired into release.yml, posture stated in the header) must be REGISTERED before the first TRACKED extraction tool lands — gitignored bench scripts (e.g. `tools/re/t2_walk.py`) follow it voluntarily meanwhile. | **Phase 1–3 half DONE 2026-11-22 (Stage-2 execution session 1)**: the tracked `re_entropy.py` / `re_magic.py` / `re_diff.py` implement the contract (headers + `--help` posture, per-cap refusal tests, crash battery, read-only-fixture-dir proof, release.yml-free) — registered in `scripts/README.md` + harness_check family 7; **the first tracked EXTRACTION tool (T4) still owes the same contract, per the T4 merge-gate conditions** |
| D39 | TT gate T4 bundle (2026-11-22) | The T4 design/merge-gate conditions carried in CONSENSUS's TT-gate ledger: save-fidelity rule (unmodeled fields round-trip verbatim), README/SECURITY disclosure replacement + the Intuit non-affiliation line, SEC-2's representation-agnostic single-provenance assertion for the quarantined key module, and the ADR-020 refusal tests. Tracked here so the debt register mirrors the gate ledger. | the T4 design gate |

**D2 correction (2026-11-14, Stage-2 entry gate ENG-3, append-only):** the
DONE note above overstates the empty-cell half of the original finding. What
shipped: `parseMoney('')` → 0 (documented and pinned by
`money_parse_test.dart:13-18`) — the blank-means-zero semantic was
**deliberately retained as documented behaviour**, not converted to a
warning; only the decimal-comma shapes are refused/warned. So `A,,5` CSV
rows still import wages=0 silently by design. The adjacent `MoneyField`
silent-ignore asymmetry is now tracked as D28.

**Stage-2 entry-gate new items (2026-11-14):** D28–D30 recorded above; the
fail-closed tag-guard fix (ENG-1) is APPLIED with its functional test
`scripts/test_tag_guard.sh` (4/4 scenarios green) — not debt; the GPL §6
release-body line (SEC-1/LEGAL-1), push-CI suites job (ENG-4), and
THIRD-PARTY-NOTICES.md (LEGAL-2) are likewise applied in-session.

**Stage-3 fixtures-first corrections (2026-11-14):** the golden fixtures
exposed and closed four reference-engine divergences from the published
forms — MFS QDI 15% cap 300,025→300,000 (QDIVCG worksheet line 13), MFS
NIIT threshold 200,000→125,000 (Form 8960 instructions), MFS senior-
deduction ineligibility (Schedule 1-A Part V caution), and the 8812
phase-out (next-$1,000 ceiling + combined CTC+ODC floor, form lines
9-12). These are fixed, not debt; recorded here so the correction
trail exists. D31 above holds what was deliberately left simplified.

**Stage-2 entry-gate new items (2026-11-17):** D33–D35 recorded above.
Applied in-session, NOT debt: ENG-1 (the Dart `.tax` inspector's
crafted-input `RangeError` — bounds-checked + regression test, suite
111→113 with ENG-2), ENG-2 (the TXF 10,000-record cap refusal test),
SEC-1 (dependency criticals cleared via non-breaking `npm audit fix` +
the fail-closed `npm audit --omit=dev --audit-level=critical` CI gate in
hygiene.yml), SEC-3/ENG-5 (the fetcher tar-tolerance hardening, quirk
20), and SEC-2 (the unlogged 2026-11-16 session recorded in
SESSION_LOG). ENG-6 (the two parameter tables' zero mechanical linkage)
becomes structurally fixable only by the epilogue Rust core — the
ADR-017 verification annex (the differential harness) is the recorded
fix, at N1; until then the shared fixtures + oracle remain the
enforcement. D30 re-affirmed (owner-side: Dependabot, branch
protection, PAT expiry).

**TT-program gate new items (2026-11-22):** D36–D39 recorded above.
**T2 session 2 (same date, later):** D36 closed by the session's byte-proofs
(see the row); the InstallShield-layer walk transferred to D40.
Applied in-session, NOT debt: the REA checkpoint-mode trial (ENG-4 —
works-with-config: `REA_GHIDRA_CHECKPOINT_DIR` under gitignored
`tools/re/rea-checkpoints` restores analysis across commands; measured
84 s first import → ~11 s per subsequent command on this 2-core box);
the hex-guard widening + canary test (LEGAL-2/SEC-1); the fetcher's
mechanical sha256 verification (SEC-4); the NOTE scan (SEC-3, applied
early); the protocol §6/§7.4 amendments and the ADR-020 clarification
annotation; the phase-1 offset erratum (0x99000). The full condition
ledger lives in `adversarial/CONSENSUS.md`'s 2026-11-22 TT gate record.

**Stage-2 execution session 1 (2026-11-22, append-only):** D33 closed with
a premise CORRECTION (the QSS CTC threshold is $200,000 per Form 8812
line 9, not the debt's recorded $400k — the fixture found the live
over-application of the QSS→MFJ column mapping to a joint-return-keyed
threshold); D38's Phase 1–3 half discharged (the row above). Applied
in-session, NOT debt: the ADR-012 mechanics (a)–(f), the LEGAL-1
mechanics, the §7.5-clean first spec (`docs/formats/clearfile-json.md`),
the 22-test RE-tool suite, the re-tooling CI job, and the harness_check
ADR-012 family. PROD-2 DISCHARGED (2 of 2).

**Stage-2 execution session 2 (2026-11-23, append-only):** D34 closed
(the row above) — and its recorded edge drift was FIXED, not just
documented: the web file reader's dependent-count clamp aligned to the
Dart reference's 0..100 bound (a parity correction per ADR-016's
corrections-flow rule; pinned by the shared edge fixture asserting 101
placeholder rows on BOTH sides). Applied in-session, NOT debt: the two
DoD specs (`docs/formats/{tax-exchange-container,txf}.md`, both
§7.5-clean, lint-clean — 3 of the 4 named files now published;
`tax-modern.md` awaits T3), the `fixtures/migration/` shared-fixture
family, the 23rd RE-tool test (the exchange-container differential pair
inside mandatory family #2), and the count syncs everywhere (115 Dart =
98 + 17 golden; bridge 11 groups; RE tools 23). The Stage-2 execution
box is CLOSED at two sessions exactly.

**TT program T2 session 3 (2026-11-23, append-only):** D40 closed (the
row above — the InstallShield-layer record walk byte-proven + the
app-module inventory entered via the MSI's MSCF cabinet); D41 opened for
the residues (the CAN-Business ISc internal table + classic codec, the
MSI name-encoding, the UI IA study proper). Also recorded here: the T2
session-2 note's stream-header field arithmetic carried a misalignment
(the "≈0x17580000 compressed size" was record 1's [u16 0][u32 0x1758
dsize] misread) — corrected in the session-3 note's erratum with the
FUN_00452b16 exact-0x2e-read anchor.

**TT program T3 session 1 (2026-11-23, append-only):** T3 ENTERED —
the MSI-cab codec byte-proven (the InstallShield MSZIP window-carry
variant: TComp=0x0001 everywhere, per-block CK-marked complete
deflate streams whose distance codes reach into the previous block's
output; the ctypes zlib inflateSetDictionary decoder; 859/859 blocks
proven on folder 87), the ttax engine DLL carved + triaged (the
.tax-layer host: IData:: family + embedded Crypto++ + the password
surface), the REA entry map built (67 functions) — D42 opened for the
construction chase. Also recorded here: the prior session's closing
backup was interrupted at context exhaustion (a UUID-message unpushed
local commit); normalized this session (guards re-run + pushed as
`8f9db50`) — the incident class joins the 2026-11-16/2026-11-20
unpushed-commit family: the teardown backup is the fragile step at
context exhaustion, and harness_check's unpushed check caught it at
bootstrap as designed.

**Stages 4+5+6 gate (2026-11-26, append-only):** D8 (both AI halves),
D11, D12, D16, D29 closed (the rows above). Applied in-session, NOT
debt: the Stages 4/5/6 execution under the owner's blanket directive
(after-the-fact gate; sequencing deviation recorded in CONSENSUS for
owner ratification), the web-boot fix + Pages deploy (live), the v1.1
release, the D29 guard fix + CI wiring, the platform-accurate
disclosure + its privacy_test pins, the README CSP/HSTS wording
corrections, and the harness_check check-ignore trailing-slash fix.
Owner-ratification surfacings from the gate record: (a) the PAT's use
to ENABLE Pages (repo-settings mutation after the GITHUB_TOKEN
create-site 403 — a new PAT-use class adjacent to D30); (b) pages.yml's
`id-token: write` OIDC grant (the deploy-pages requirement; deviation
from the Stage-0 "nothing more" posture, recorded in-file). D30
re-affirmed untouched (Dependabot, branch protection, PAT expiry —
owner-side).

**Owner ruling (2026-11-26, append-only):** the ratification
surfacings above are RATIFIED by the owner in-conversation (the
after-the-fact sequencing, the PAT-Pages-use, the `id-token: write`
OIDC grant) — no remediation directed. The same message FUNDED the
epilogue N1–N6 program (ADR-017). D30 remains untouched and standing —
no ruling was received on Dependabot alerts, branch protection, or PAT
expiry; they stay owner-side.

**N1 entry gate (2026-11-26, append-only):** applied in-session, NOT
debt — the gate-level conditions (the TWO-session box, the third-engine
boundary sentence, the 16→17 count erratum, the zero-dependency license
assertion as the annex's cargo-deny discharge, the harness_check
release.yml variant guard, the fetch_flutter_sdk.sh SPDX residue
repair, the fourth-version-plane note). Recorded as debt: **D43** —
the ADR-017 verification annex (a) differential/property harness is
DEFERRED to N1 session 2 by design (session 1 lands only the third
golden-fixture runner); mechanism named: a Dart-side random/edge input
generator emitting JSON cases that a later `cargo test` consumes
against the Rust core, with the Dart reference computing the same cases
in-process — N1's exit checklist names the harness; exceeding the
two-session box fires the Stage-3 tripwire precedent. Also debt-adjacent,
recorded at the same gate: the D31c caveat carries to the Rust runner —
if N1 authors any fixtures, they pin only three-runner-derivable fields.

**N1 session 2 (2026-11-26, append-only):** **D43 CLOSED** — the
annex-(a) differential/property harness landed exactly per its recorded
mechanism: the tracked Dart generator (`scripts/generate_differential_cases.dart`,
relocated from `clearfile/tool/` for the PROD-5 zero-clearfile/src-delta
boundary) emitting `fixtures/differential/cases.json` (seed 771937021;
550 cases: 300 random + 246 edge + 4 edge-d31b; byte-deterministic,
sha256 regeneration-verified) with the Dart reference computing the
expected values in-process; `core/tests/differential_harness.rs`
consumes them against the Rust core — 550 × 26 fields EXACT binary64
parity, tolerance-0.0 semantics — plus `core/tests/property_harness.rs`
(the property half: fold order, bracket monotonicity/continuity,
refund/owed exclusivity, the D33 QSS↔MFJ column equivalence). The
26-key rule (D31c) is asserted per case by the consumer AND by
harness_check's new corpus-ledger family. The annex-(b) ported bridge
suites landed with it (envelope + TXF + .tax inspection + the
composition). The N1 exit gate convenes on the combined delta.

**N1 exit gate (2026-11-26, append-only):** D44 recorded (PROD-2): ADR-017's
core boundary names "MD3-from-seed palette generation"; N1's execution box
never included it (session 1 = the engine/runner slice; session 2 = the
annex harnesses + codecs), and the gap was silent until the exit gate —
now explicit: **D44 — the MD3-from-seed tonal palette generation is
deferred to the first consumer session (N2, the Linux native UI), where
the palette's contract (the seed → tonal palettes the UI stacks
consume) becomes pinning-able against a real consumer.** The ADR-017
licensing annex's MD3 notes (unprotectable functional design, no
Google/Material logos) carry to that session.

**N2 sessions 1+2 (2026-11-26, append-only): D44 CLOSED** — the
MD3-from-seed palette generation landed in the core (core/src/palette.rs:
the color math + Hct + the tonal palettes + SchemeTonalSpot + the 34
MaterialDynamicColors roles) verified by the palette differential corpus
(fixtures/palette/cases.json, 33 seeds × the six ladders × 101 tones +
2 × 34 roles, all ARGB-exact) + THIRD-PARTY-NOTICES.md's Apache-2.0
translation entry; consumed by the Linux app's theme.
