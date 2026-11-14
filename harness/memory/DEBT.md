# Technical-debt register

Findings accepted as debt (tracked here so future reviewers don't
"discover" them again). Source: Stage-0 adversarial review, 2026-11-14.
Each item carries its owner stage.

| ID | From | Debt | Stage |
| --- | --- | --- | --- |
| D1 | ADV-ENG #9 | `importReturn` conflates cancelled/unreadable/wrong-format into one silent null — needs a sealed result type + user feedback | 3 |
| D2 | ADV-ENG #10 | Money parsing duplicated (`money_field.dart` vs `csv_import.dart`); decimal-comma "6,5" parses as 65 silently; empty CSV wages cell parses as 0 — one shared `parseMoney()` + edge tests | **DONE 2026-11-14** — `util/money.dart parseMoney()` shared by both callers; comma-plus-1/2-digit shapes refused; 5 edge tests + CSV-path warning test |
| D3 | ADV-ENG #11 | `readDate` fabricates 1970-01-01 on unparseable dates; `fromJson` accepts any `formatVersion` — **no format change ships before a version guard** | 3 |
| D4 | ADV-ENG #12 | FS I/O + raw autosave Timer inside a ChangeNotifier force the `runAsync` test convention — extract a `ReturnStore` interface seam so new widget tests use a fake store | **DONE 2026-11-14** — abstract `ReturnStore` + `FileReturnStore` + `test/fakes.dart` FakeReturnStore; step tests run outside runAsync |
| D5 | ADV-ENG #13 | AppState god-object: every keystroke recomputes + rebuilds the shell; `settingsStore.save()` fire-and-forget; `testConnection()` bypasses error state. Register only; rebuild not warranted at demo scale | — (register) |
| D6 | ADV-ENG #14 | `ValueKey(w2)` over value-equal mutable models — breaks if models become immutable (`copyWith`); settings `removeWhere` deletes ALL duplicate chain entries at once | **DONE 2026-11-14** — it was a LIVE crash (two blank W-2s = duplicate keys): ObjectKey identity keys + identity removal in both list steps; settings removeAt drops exactly one row; 3 guard tests pin it |
| D7 | ADV-ENG #15 | `clearfile/assets/sample_w2.csv` tracked but undeclared in pubspec + unreferenced (duplicated as `w2CsvTemplate`); android CI writes into tracked `clearfile/assets/` | **DONE 2026-11-14** — file removed (duplicate of the template const); android CI collects APKs under gitignored `clearfile/build/release-apks/` |
| D8 | ADV-ENG #17 | Parity drift: AI timeouts (Flutter 90 s both vs web 45/90 s); Google key in URL query (Flutter) vs header (web); web CTC $50-per-$1,000 units vs Flutter exact 5% | 5 |
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
