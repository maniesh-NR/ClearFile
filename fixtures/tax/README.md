# Shared golden tax fixtures

`(TaxReturnData, TaxResult)` JSON pairs that pin **both** ClearFile engines
(the Flutter reference engine and the Next.js web engine) to IRS-published
truth. This is the fixtures-first deliverable of Stage 3 (ROADMAP; entered
2026-11-14 at the Stage-2 entry gate): the Flutter engine's regression suite
today, the web engine's parity tests in the boxed parity set next.

## Why they exist

The two engines share no code and can silently diverge. A disagreement is
settled neither by the Dart engine nor the TS engine but by the IRS
publication a fixture cites: each file carries `source.pin` (a verbatim
quotation or row reference), a line-by-line `derivation`, and the
`tolerance` the assertion uses. IRS publications are 17 USC §105 government
works — quoting and deriving from them is unproblematic.

## Consumers

- `clearfile/test/golden_fixtures_test.dart` — loads every `*.json`, runs
  `TaxCalculator.compute` on `input`, and asserts every `expected` key
  within `tolerance` (plus `deductionMethodUsed` as an enum name).
- `scripts/verify_golden_fixtures.py` — the independent oracle: Decimal
  arithmetic written from the form text, not from either engine. Its
  agreement with the hand-written fixtures is what proves the numbers are
  form-derived rather than engine-derived. Runs in CI (hygiene `suites`).
- The web engine's parity suite (Stage-3, upcoming) reads the same files
  from the repo root.

## File schema (`format: clearfile.golden`, version 1)

| Field | Meaning |
| --- | --- |
| `name` | Stable identifier; the Dart test group name. |
| `description` | What the fixture pins, in one paragraph. |
| `taxYear` | Engine parameter year (2025 for the whole set). |
| `source.publication` | The IRS (or cross-check) publication name. |
| `source.urls` | URLs the numbers were read from. |
| `source.pin` | Verbatim quotation / row reference that anchors the numbers. |
| `input` | A `TaxReturnData` JSON object (missing keys take the model's defaults; `id`/timestamps are irrelevant to computation). |
| `expected` | The `TaxResult` keys being asserted (a subset is fine; only what the pin actually settles). |
| `tolerance` | Max absolute error per numeric field. `0.005` for exact worksheet arithmetic; `0.505` where the pin is an IRS whole-dollar figure (Tax Table rows). |
| `derivation` | Ordered steps with form line references, so a human can re-derive every expected number against the publication. |

## Rules for adding or editing a fixture

1. **Never derive an expected value by running either engine.** Hand-derive
   it from the IRS worksheet or publication, then (a) record the derivation
   steps in the file, and (b) confirm `scripts/verify_golden_fixtures.py`
   agrees (extend the oracle if the fixture pins mechanics it does not yet
   model).
2. Cite what settles disputes: `source.pin` must be specific enough that
   someone holding the PDF can check the number (worksheet line numbers,
   table row and column, verbatim sentence).
3. Prefer unambiguous pins: exact multiples where the form's rounding rules
   could otherwise differ (the student-loan fixture sits at the 0.500
   midpoint of the phase-out band for exactly this reason).
4. A fixture that fails against an engine is a finding about the engine
   (see the four 2026-11-14 corrections it already forced: the MFS QDI
   15% cap $300,000, the MFS NIIT threshold $125,000, MFS senior-deduction
   ineligibility, and the 8812 next-$1,000 phase-out rounding with the
   combined CTC+ODC floor). Fix the engine against the form, not the
   fixture against the engine.
5. Rounding conventions, where the IRS publishes whole dollars (Tax Table
   rows), belong in `tolerance`, not in the engines.

## Scope note

The fixtures pin the mechanics the demo engine actually models. Cases the
1040 flow deliberately simplifies away (ACTC allocation between CTC and ODC
in the partial-absorption zone, MAGI add-backs, Puerto Rico exclusions)
are consciously not pinned — see `harness/memory/DEBT.md` for the register
of known simplifications.
