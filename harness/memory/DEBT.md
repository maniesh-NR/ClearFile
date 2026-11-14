# Technical-debt register

Findings accepted as debt (tracked here so future reviewers don't
"discover" them again). Source: Stage-0 adversarial review, 2026-11-14.
Each item carries its owner stage.

| ID | From | Debt | Stage |
| --- | --- | --- | --- |
| D1 | ADV-ENG #9 | `importReturn` conflates cancelled/unreadable/wrong-format into one silent null — needs a sealed result type + user feedback | 3 |
| D2 | ADV-ENG #10 | Money parsing duplicated (`money_field.dart` vs `csv_import.dart`); decimal-comma "6,5" parses as 65 silently; empty CSV wages cell parses as 0 — one shared `parseMoney()` + edge tests | 1 |
| D3 | ADV-ENG #11 | `readDate` fabricates 1970-01-01 on unparseable dates; `fromJson` accepts any `formatVersion` — **no format change ships before a version guard** | 3 |
| D4 | ADV-ENG #12 | FS I/O + raw autosave Timer inside a ChangeNotifier force the `runAsync` test convention — extract a `ReturnStore` interface seam so new widget tests use a fake store | 1 |
| D5 | ADV-ENG #13 | AppState god-object: every keystroke recomputes + rebuilds the shell; `settingsStore.save()` fire-and-forget; `testConnection()` bypasses error state. Register only; rebuild not warranted at demo scale | — (register) |
| D6 | ADV-ENG #14 | `ValueKey(w2)` over value-equal mutable models — breaks if models become immutable (`copyWith`); settings `removeWhere` deletes ALL duplicate chain entries at once | 1 |
| D7 | ADV-ENG #15 | `clearfile/assets/sample_w2.csv` tracked but undeclared in pubspec + unreferenced (duplicated as `w2CsvTemplate`); android CI writes into tracked `clearfile/assets/` | 1 |
| D8 | ADV-ENG #17 | Parity drift: AI timeouts (Flutter 90 s both vs web 45/90 s); Google key in URL query (Flutter) vs header (web); web CTC $50-per-$1,000 units vs Flutter exact 5% | 5 |
| D9 | ADV-ENG #19 | Slash-bearing tags (`v1.0.0/rc`) break artifact paths — now mitigated by RELEASE_TAG validation regex (only `[0-9A-Za-z._-]` after `v<digit>` passes) | mitigated (verify at next release) |
| D10 | ADV-SEC #7 | All actions pinned to mutable major tags — pin commit SHAs | 1 |
| D11 | ADV-SEC #8 | Gemini key sent as URL query param in Flutter — switch to `x-goog-api-key` header | 5 |
| D12 | ADV-SEC #9 | AI keys at rest in plaintext JSON, undisclosed in-app — disclose file+format in the Stage-1/5 privacy copy; `flutter_secure_storage` as stretch | 5 |
| D13 | ADV-SEC #13 | No SECURITY.md; no vulnerability-disclosure channel | 1 |
| D14 | ADV-LEGAL #5 | GPL per-file SPDX headers absent | 1 |
| D15 | ADV-LEGAL #6 | `z-ai-web-dev-sdk` — REMOVED from package.json 2026-11-14 ✓ | done |
| D16 | ADV-LEGAL #7 | Flutter Google transport key-in-URL (= D11) | 5 |
| D17 | ADV-LEGAL #8 | Web auto-fill sends pasted text verbatim (may contain SSN/name/address) while copy says "never collects" — soften copy or pre-send notice | 1 |
| D18 | ADV-LEGAL #12 | Web app title "Clean-Room Tax Filing Assistant" vs its own "do not file" copy — consider "Tax Return Study Prototype" | 1 |
| D19 | ADV-PROD #6 | Harness self-enforcement: add `scripts/harness_check.sh` (CONSENSUS ↔ ROADMAP gate-status consistency; SESSION_LOG last entry postdates nothing unpushed) | 1 |
| D20 | ADV-SEC #1 | Android release APKs lack INTERNET permission → shipped AI cascade silently dead; macOS entitlements lack network-client — **owner decision** (add permission + disclosure, or compile AI UI out of Android release) | 1 (decision first) |
| D21 | ADV-ENG #8 | Harness pointer drift — FIXED 2026-11-14 (§-refs audited, typo, STATE node_modules) ✓ | done |
