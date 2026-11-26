# Differential cases (Rust core vs. Dart reference)

`cases.json` is the ADR-017 verification annex **(a)** / debt **D43**
mechanism: a deterministic, seeded corpus of random + edge-case tax inputs,
each paired with expected values computed **in-process by the Dart reference
engine**. A later `cargo test` consumes the same file against the Rust core
(`core/`) and must reproduce every expected value **bit-exactly**.

The fixtures pin breakpoints; this corpus pins the continuum — random
sampling across the whole input space plus targeted probes at every
threshold, cap, bracket boundary, rounding trap, and equivalence zone the
TY2025 tables encode. The QSS coverage hole (annex exhibit A) is covered by
both weighting (`survivingSpouse` ≈ 1/8 of the random cases) and dedicated
twin/divergence probes.

## Provenance and regeneration

| Item | Value |
| --- | --- |
| Generator | `scripts/generate_differential_cases.dart` (pure Dart, relative imports only — runs with the plain `dart` binary, no package resolution; lives under `scripts/` so the N1 delta keeps the PROD-5 boundary: zero `clearfile/` or `src/` paths) |
| Seed | `771937021` (constant in the generator; the corpus is pinned to it) |
| Expected values | `TaxCalculator.compute(TaxReturnData.fromJson(input))` — the exact call path `clearfile/test/golden_fixtures_test.dart` uses |
| Parameters | read at runtime from `clearfile/lib/models/tax_year.dart` (`TaxYearParameters.ty2025`) — the generator never hardcodes a threshold |

Regenerate (from `clearfile/`):

```
cd scripts
../tools/flutter/bin/cache/dart-sdk/bin/dart generate_differential_cases.dart
sha256sum ../fixtures/differential/cases.json
```

Regeneration is **byte-identical** (verified: two consecutive runs produce the
same digest). The committed file's digest is
`a15ac79cc5cb80c2dabd85a51fd0c964b9cecc72a10f45de7715fb53828d9947`.
If a run disagrees, something non-deterministic has been introduced — treat
it as a generator bug, not a corpus bump.

## The contract (NOT golden fixtures)

This is **not** the `fixtures/tax/` golden set, and the annex **(d)**
authoring discipline (never derive an expected value by running any engine;
hand-derive from the IRS publication) does **not** apply here. For the
differential, the Dart reference engine **is the expectation by design**:
every `expected` block is that engine's output on the paired `input`,
computed in-process at generation time. The distinction:

- `fixtures/tax/` settles *what the right answer is* (IRS publications are
  the arbiter; engines can be wrong).
- `fixtures/differential/` settles *whether the Rust core matches the
  reference bit-for-bit* (the Dart engine is the arbiter; a disagreement is
  a port bug on one side or the other, resolved against the engine that the
  golden fixtures + Python oracle certify).

Numeric semantics: **exact binary64 parity, tolerance 0.0** — every value
must compare bitwise-equal as `f64`, including float dust (e.g.
`210002.56` vs `210002.56000000003` is a real, pinned difference). The JSON
text round-trips binary64 exactly (shortest round-trip emission), so a
consumer parsing with serde_json reads the identical `f64` the reference
produced.

## The 26-key rule (D31c)

Every `expected` block carries exactly these 26 keys, in this order, and
nothing else:

`totalIncome, studentLoanDeduction, agi, basicStandardDeduction,
additionalStandardDeduction, seniorDeduction, standardDeductionTotal,
saltPaid, saltCap, saltAllowed, itemizedDeductionTotal, deductionMethodUsed,
deductionUsed, taxableIncome, ordinaryTax, preferentialIncome,
preferentialTax, niit, nonRefundableCredits, refundableCredits, totalTax,
totalPayments, refund, amountOwed, effectiveRate, qualifyingChildren`

These are the **three-runner-derivable** fields only.
`marginalRate` is deliberately never emitted (D31c: it is computed on
ordinary taxable only — not derivable by the third runner from the pinned
set). `deductionMethodUsed` is always resolved — `'standard'` or
`'itemized'`, never `'auto'`. `qualifyingChildren` is an integer count.

## Class taxonomy

| `class` | Count | Meaning |
| --- | --- | --- |
| `random` | 300 | Uniform-ish field-by-field sampling: status weighted (QSS ≈ 1/8), ~25% true booleans, 0–4 W-2s, 0–5 dependents with mixed `qualifyingChild`/`otherDependentCredit` flags, deduction method 70/15/15 auto/standard/itemized. **10 of the 300 carry negative inputs** (negative `otherIncome`, 4 of them also a negative W-2 wage) — the engine's clamped flow keeps every emitted field finite for them; the generator refuses to emit any case with a non-finite value. |
| `edge` | 246 | Targeted probes at runtime-read thresholds: every ordinary bracket boundary ±$0.01 for all 5 statuses; itemized==standard tie (strictly-greater rule); forced standard/itemized/auto; QSS↔MFJ equivalence twins (identical money → identical output) and D33 divergence twins (CTC threshold $200k vs $400k); senior phase-out at/inside/zero-crossing; blind-flag `hasSpouse` pins; CTC phase-out at/±$0.01 per status, the next-$1,000 step trap (exact/below/above), ODC-only and full-phase-out zeros; ACTC floor, per-child vs earned caps, partial absorption; SALT at/±$0.01 per status cap, far-above, phase-down and floor; SLI band ends + midpoint; NIIT at/±$0.01 per status threshold + investment-vs-MAGI cross-overs; QDI zero-cap/fifteen-cap boundaries per status, 20% zone, preferential>taxable clamp; multi-W-2 left-fold order twins; 0/1/8/12 dependents; effective-rate zones (tiny tax, $5M AGI, AGI 0) and the refund==owed==0 payments boundary. |
| `edge-d31b` | 4 | The D31b reading zone: student-loan phase-out points *other* than the unambiguous 0.500 midpoint (quarter, three-quarter, one-third, and a microscopic $0.01-paid case). Both engines implement the exact-precision reading; these cases pin it bit-exactly rather than avoiding it. |

## File schema

```json
{
  "kind": "clearfile-differential",
  "generator": "scripts/generate_differential_cases.dart",
  "seed": 771937021,
  "caseCount": 550,
  "note": "…the D43/annex-(a) statement…",
  "cases": [
    { "id": "rand-001", "class": "random",
      "input":   { …TaxReturnData shape, same key order as fixtures/tax… },
      "expected": { …26 keys… } }
  ]
}
```

`input` mirrors the golden fixtures' input blocks exactly (same keys, same
order; money as cent-rounded values, human-auditable). No timestamps, no
environment, no randomness outside the generator's own xorshift64* PRNG
(documented in the generator header; `dart:math` `Random` is never used).

## Self-checks (the generator exits non-zero and writes nothing if any fail)

1. Every case id is unique; every class is one of the three above.
2. Every `expected` block has exactly the 26 keys, in the pinned order.
3. Every numeric value in `input` and `expected` is finite (the negative-input
   cases are held to this — a case that would emit non-finite values is never
   written).
4. `deductionMethodUsed` ∈ {`standard`, `itemized`} (resolved, never `auto`);
   `qualifyingChildren` is a non-negative int.
5. The QSS↔MFJ money-identical twins produce **identical** expected blocks
   (D33 equivalence).
6. The W-2 fold-order twins produce **bitwise-different** folded totals
   (pins the engine's left-fold order — if the chosen dust constants ever
   stop differing, the generator fails loudly instead of pinning nothing).

## Consumers

- The future Rust-core differential `cargo test` (ADR-017 annex (a); the
  consumer is the N1 exit-checklist harness) — run `core`'s engine over each
  `input`, compare all 26 `expected` values with tolerance 0.0.
- The Dart side needs no consumer: expected values are computed by the Dart
  engine itself, so re-running the generator doubles as the Dart check.
