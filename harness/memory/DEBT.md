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
| D8 | ADV-ENG #17 | Parity drift: AI timeouts (Flutter 90 s both vs web 45/90 s); Google key in URL query (Flutter) vs header (web); web CTC $50-per-$1,000 units vs Flutter exact 5% | 5 (engine half **DONE 2026-11-15** — the web engine now uses the reference's exact 8812 semantics; the AI-side halves remain Stage 5) |
| D9 | ADV-ENG #19 | Slash-bearing tags (`v1.0.0/rc`) break artifact paths — now mitigated by RELEASE_TAG validation regex (only `[0-9A-Za-z._-]` after `v<digit>` passes) | mitigated (verify at next release) |
| D10 | ADV-SEC #7 | All actions pinned to mutable major tags — pin commit SHAs | **DONE 2026-11-14** — every `uses:` in `release.yml` + `hygiene.yml` pinned to 40-hex SHAs (lightweight tags resolved via `git ls-remote`, version in comment) |
| D11 | ADV-SEC #8 | Gemini key sent as URL query param in Flutter — switch to `x-goog-api-key` header | 5 |
| D12 | ADV-SEC #9 | AI keys at rest in plaintext JSON, undisclosed in-app — disclose file+format in the Stage-1/5 privacy copy; `flutter_secure_storage` as stretch | 5 |
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
| D29 | ADV-ENG Stage-2 ENG-5 | Tag-PUSH trigger path of the release guard unverified (both live proofs were dispatches; an annotated-tag push may peel to the tag-object SHA and be refused fail-closed) — verify once at the NEXT tagged release, or drop the push trigger for dispatch-only | next tagged release |
| D30 | ADV-SEC Stage-2 SEC-2/SEC-4 | Owner-side hardening standing recommendations: Dependabot alerts, branch protection on `main`, PAT expiry (see WORKFLOW §5) — re-affirmed by the Stage-2 entry gate | owner-side |
| D31 | Stage-3 fixtures-first (2026-11-14) | Engine simplifications deliberately NOT pinned by the golden fixtures: (a) ACTC allocation between CTC and ODC in the partial-absorption zone (engine subtracts the whole non-refundable credit from the CTC portion; Schedule 8812's Part II-A has its own allocation) — fixtures avoid the ambiguous zone; (b) the student-loan worksheet's "rounded to at least three places" is read as exact precision (existing calculator test pins 1,333.33 at MAGI 92k where a 3-place worksheet gives 1,332.50) — the SLI fixture uses the unambiguous 0.500 midpoint; (c) marginal rate is computed on ordinary taxable only (QDI-heavy returns report the ordinary schedule's rate) — no fixture asserts marginalRate | Stage-3 parity set (**shared by both engines since the 2026-11-15 port**) |
| D32 | Stage-3 web parity (2026-11-15) | The web engine's previously projected TY2026 parameters were **dropped**: the reference engine (the parity truth per ADR-009) has no TY2026 parameter set, and inventing one would re-open the silent-divergence gap ADR-009 closed. Web store + `.cfr` v1 loader migrate old saves to TY2025 (conservative field mapping; adjustments/medical/other dropped — warnings shown; counts → placeholder dependents). Reinstate when the reference gains verified TY2026 parameters. | whenever the reference gains TY2026 |
| D33 | Stage-2 entry gate ENG-3 (2026-11-17) | No golden fixture exercises **survivingSpouse (QSS)** — the parity contract's only completely unpinned filing status (currently pinned only by an internal Dart equivalence test; the TS/oracle sides by nothing). One QSS fixture (pins the MFJ-column table lookup + sd 31,500 + CTC 400k + QDI 96,700/600,050 + NIIT 250k) consumed by ALL THREE runners (Dart, `web_parity_test.mjs`, `verify_golden_fixtures.py`), cited to the IRS publication carrying the QSS→MFJ-column rule. | **first Stage-2 execution session** (gate condition, assigned with a named verification event) |
| D34 | Stage-2 entry gate ENG-4 (2026-11-17) | The v1→v2 conservative migration is triple-implemented (`cfr.ts:73`, `store.ts:140`, `return_format.dart:172`) with fragment-level warning pinning and edge drift (Dart clamps child counts at 100; warning lists pinned only by `contains` fragments; `store.ts:155` reads the v1 *store* W-2 shape vs the file readers' v1 *file* shape — legitimate vintages, documented nowhere). Fix: lift the identical v1 sample into a shared fixture, assert exact warning lists in both suites, document the store-vs-file W-2 shape difference in `docs/return-format.md` §3. | Stage-2 execution window |
| D35 | Stage-2 entry gate ENG-8 (2026-11-17) | `listReturns` drops decode warnings silently (`return_store.dart:57` uses only `.filing`). Harmless today (store-origin legacy files produce no warnings) but a future envelope bump would make store-dir warnings invisible. Register, don't fix. | register |
| D36 | TT gate / T2 session 1 (2026-11-22) | The USA container's entry semantics are partially derived: field A (0x20) and field B (0x9e67) after the entry FILETIME are unresolved (chunk-size / compressed-size candidates); the payload stream's chunking (first bounded decode yielded 90,000 B before the 1 MiB bound) and the codec chain (FUN_0041e5e0 et al.) are un-chased; the CAN-Personal inner ZIP and CAN-Business InstallShield layers are not yet entered. Full map: `docs/re-research/2026-11-22-tt-t2-reader.md`. | **DONE 2026-11-22 (T2 session 2)** — `docs/re-research/2026-11-22-tt-t2-session2.md`: A = Win32 attributes bitmask, B = first-chunk compressed size; chunk grammar byte-proven (raw-Deflate chunks + 0x80000000-flagged stored segments + [u32 0] terminator + type-0 end-entry + ~10 KB trailing PKCS#7 SignedData); FUN_0041e5e0 corrected to the parent-dir preparer; CAN-Personal inner layer mapped (plain ZIP → same bootstrapper family + ISSetupStream v7); CAN-Business manifest table mapped (header fields + INI-block size field + entropy boundary). Residue transferred to D40 |
| D40 | T2 session 2 (2026-11-22) | The InstallShield-layer record walk is un-entered: the ISSetupStream v7/v8 payload record format, and the CAN-Business classic file-group record framing (from ≈0xefa00); the app-module inventory (the file-format/password routines) stops at the InstallShield boundary. Residue: the internal-header selector (0x80/0xc0/0x100) semantics unresolved but reader-irrelevant; the end-entry's trailing-field semantics ambiguous; the pump's vtable identity at 0x4191a9 (indirect — codec byte-proven regardless). | T2 session 3 |
| D37 | TT gate ENG-7 (2026-11-22) | The T4 bridge's codec layer must stay pure/portable (no Flutter I/O imports) so the ADR-017 N1 Rust-core port does not face a second unplanned migration — the TT codecs sit outside ADR-017's recorded core scope. | T4 design |
| D38 | TT gate ENG-5 (2026-11-22) | The security contract (write-confined to gitignored dirs, resource-bounded with refusal tests, crash battery per the ENG-1 template, never wired into release.yml, posture stated in the header) must be REGISTERED before the first TRACKED extraction tool lands — gitignored bench scripts (e.g. `tools/re/t2_walk.py`) follow it voluntarily meanwhile. | first tracked RE tool (Stage-2 session 1 or T4) |
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
