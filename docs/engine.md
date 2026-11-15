# The ClearFile engine — line mapping and limitations register

**Status:** Stage-3 close-out deliverable (2026-11-15) · Applies to BOTH
engines: `clearfile/lib/tax/calculator.dart` (Dart, the reference) and
`src/lib/tax/engine.ts` (the line-for-line TypeScript port at parity,
ADR-009) · Verification: §5

This is the map between what the engines compute and where the same
quantity lives on the real TY2025 federal forms — plus the honest
register of everything the engines deliberately do NOT model. Read it
alongside `README.md` ("Calculation engines" / "Engine limitations")
and `fixtures/tax/README.md` (the golden fixtures' own citations).

**Conventions.** "1040 line N" refers to the line numbering of the
2024-published Form 1040 family; the 2025 final forms (post-OBBBA) may
renumber — where the engines' citations name a worksheet or schedule,
trust the worksheet name over the line number. The arithmetic itself is
pinned to IRS-published worked examples by the golden fixtures (§5), so
a numbering drift is a documentation fix, not a math bug. All parameters
below live in ONE place per codebase (`clearfile/lib/models/
tax_year.dart` `TaxYearParameters.ty2025`, mirrored in
`src/lib/tax/config.ts`) with their sources in the class doc.

---

## 1. Income → AGI

| Engine step (code) | Value | Form location |
| --- | --- | --- |
| `r.totalWages` (sum of W-2 Box 1) | wages | 1040 line 1z |
| `interestIncome` | taxable interest | 1040 line 2b |
| `ordinaryDividends` | non-qualified dividends | 1040 line 3b (3a is the qualified subset, captured separately) |
| `qualifiedDividends` + `longTermCapitalGains` | preferential-rate income | 1040 line 3a + line 7 (entered directly; Schedule D is not modelled) |
| `otherIncome` | misc income | 1040 line 8 (in reality routed via Schedule 1 line 10; the engine takes it directly) |
| `totalIncome` | total income | 1040 line 9 |
| `_studentLoanDeduction` | student loan interest deduction | Schedule 1 line 21 → 1040 line 10 |
| `totalIncome - sli` | AGI | 1040 line 11 |

Student-loan parameters (TY2025): cap $2,500; phase-out 85k–100k
(single/HoH/QSS), 170k–200k (MFJ); **MFS ineligible** (encoded as
start > end). MAGI here = total income (before the deduction itself).

## 2. Deductions

| Engine step | Value | Form location |
| --- | --- | --- |
| `params.standardDeduction[status]` | basic standard deduction | 1040 line 12 (OBBBA 2025: $15,750 / $31,500 / $15,750 / $23,625 / $31,500 by status) |
| `_agedOrBlindCount × additionalPer…` | 65+/blind additions (standard route only) | 1040 line 12 checkbox worksheet (VITA: $2,000 single/HoH, $1,600 married per person) |
| `_seniorDeduction` | OBBBA senior deduction, $6,000 per 65+ person, phased out 6% of MAGI over 75k (single/HoH/MFS-base) / 150k (MFJ/QSS); **MFS ineligible** | Schedule 1-A (2025) Part V, added on the standard OR itemized route |
| `saltPaid = stateLocal + realEstate`, `saltCapFor(status, agi)` | SALT with the OBBBA cap: $40,000 base ($20,000 MFS) minus 30% of MAGI over 500k ($250k MFS), floored at $10,000 ($5,000 MFS) | Schedule A lines 5a–5e (the 2025 SALT worksheet) |
| `mortgageInterest` | mortgage interest | Schedule A line 8a |
| `charitableCash` ≤ 60% AGI, `charitableNonCash` ≤ 30% AGI | charitable (simplified: two ceilings, no carryover) | Schedule A lines 11a/11b |
| `itemizedRaw` + senior | itemized route | 1040 line 13 area (Schedule A total) |
| method choice (`auto` picks the larger total; `standard`/`itemized` force) | deduction used | 1040 lines 12–13 |
| `max(0, agi − deductionUsed)` | taxable income | 1040 line 15 |

Not modelled on the deduction side: QBI (1040 line 13's other half),
medical/casualty/other itemized categories, charitable carryovers.

## 3. Tax

| Engine step | Value | Form location |
| --- | --- | --- |
| `ordinaryTaxable = taxable − preferentialIncome` | ordinary slice | Qualified Dividends and Capital Gain Tax Worksheet, ordinary-income side |
| `_bracketTax(ordinaryTaxable, brackets)` | tax on ordinary income | 1040 line 16 (Tax Table below the breakpoint / Tax Computation Worksheet above) |
| QDI/LTCG stacking: 0% band to `qdiZeroCap`, 15% band to `qdiFifteenCap`, 20% above | preferential tax | the QDIVCG worksheet (breakpoints = worksheet lines 6 and 13: 48,350/533,400 single; 96,700/600,050 MFJ & QSS; 48,350/**300,000-flat** MFS; 64,750/566,700 HoH) |
| `niit = 3.8% × min(investmentIncome, agi − threshold)` | net investment income tax (simplified base: interest + ordinary dividends + qualified dividends + LTCG) | Form 8960 → Schedule 2 line 12 → 1040 line 17 area |

NIIT thresholds (Form 8960 instructions): 200k single/HoH, 250k MFJ/QSS,
**125k MFS**.

## 4. Credits and payments

| Engine step | Value | Form location |
| --- | --- | --- |
| CTC $2,200 per qualifying child + ODC $500 per other dependent | gross credits | Schedule 8812 |
| phase-out: 5% of the excess MAGI over 200k (400k MFJ/QSS), **excess rounded UP to the next $1,000 first** (8812 line 10 wording; the engine cents-normalizes before the ceiling so float dust cannot bump a multiple) | phase-out | Schedule 8812 line 10 |
| the phase-out reduces the **combined CTC+ODC amount, floored at zero** (not each credit separately) | phased credits | Schedule 8812 line 12 |
| `min(phasedTotal, taxBeforeCredits)` | non-refundable credits | 1040 line 19 area (Schedule 8812 → credits) |
| ACTC (refundable): 15% of earned income above a $2,500 floor, capped $1,700 per child; only the CTC portion (ODC is strictly non-refundable) | refundable credit | 1040 payments section, additional-child-tax-credit line (line 27 on the 2024 form) |
| `totalTax = max(0, taxBeforeCredits − nonRefundable + niit)` | total tax | 1040 line 22 area |
| `withholding + estimatedPayments (+ ACTC paid out like withholding)` | payments | 1040 lines 25/26 (+ refundable credit line) |
| refund / owed | bottom line | 1040 lines 34 / 37 |

## 5. Verification pyramid (how every number is pinned)

1. **Unit tests** — `clearfile/test/calculator_test.dart` (19) and the
   parity suite hand-verify each rule at its breakpoints; every named
   parameter has a test that exercises it.
2. **Shared golden fixtures** — `fixtures/tax/` (16 IRS-pinned
   `(TaxReturnData, TaxResult)` pairs, citation + derivation + tolerance
   per file): Tax Table rows, the instructions' own MFJ Tax-Table
   example, QDIVCG worksheet breakpoints (incl. the flat $300,000 MFS
   15% cap), Schedule 1-A Part V, the Schedule A SALT worksheet (incl.
   the $575k→$17,500 phase-down point), Schedule 8812 (incl.
   next-$1,000 rounding and the combined CTC+ODC floor), Form 8960
   (incl. the $125,000 MFS threshold), the student-loan worksheet.
   Run by BOTH engines: `golden_fixtures_test.dart` (Dart) and
   `scripts/web_parity_test.mjs` (TS) — 16/16 each in CI.
3. **The independent oracle** — `scripts/verify_golden_fixtures.py`
   re-derives every expected value in Decimal arithmetic written
   directly from the form text, by a THIRD implementation, in the
   hygiene `suites` CI job.

## 6. Limitations register (the honest list)

The engines are demonstration-grade; these are the known, deliberate
non-implementations and simplifications. `D31` items are
deliberate-unpinned simplifications recorded in the debt register.

- **Not modelled at all**: AMT (Form 6251); self-employment tax
  (Schedule SE); additional Medicare tax (Form 8950); QBI (1040 line 13);
  state/territory returns; estate & trust schedules; EITC; education
  credits (8863/8917); premium tax credit (8962); energy credits;
  estimated-tax penalties; HSA/IRA interactions; foreign income
  (2555/1116); medical, casualty, theft, and "other" itemized
  categories; charitable carryovers; kiddie tax (the child's return is
  not modelled).
- **Simplified**: NIIT base = interest + dividends + LTCG only (Form
  8960's actual NII has more categories and deductions); the ACTC walk
  (15% of earned income above a $2,500 floor, capped $1,700/child —
  the real 8812 Part II has additional branches); charitable AGI
  ceilings applied as two plain caps; the senior deduction's MAGI is
  AGI (the schedule's own MAGI definition may differ in edge cases).
- **D31 (deliberate-unpinned)**: (a) the ACTC/CTC+ODC allocation inside
  the partial-absorption zone — the engine subtracts the phase-out from
  the combined amount with the CTC-only ACTC remainder; fixtures avoid
  the ambiguous zone; (b) the student-loan worksheet's "rounded to at
  least three places" is read as exact precision; (c) `marginalRate` is
  computed on the ordinary schedule only (QDI-heavy returns report the
  ordinary side's rate) — no fixture asserts it.
- **Display vs precision**: all money computes at cent precision
  (`double` in Dart, `number` in TS — both engines agree to the cent on
  every fixture); whole-dollar display rounding is UI-level only.
- **Tax-year scope**: TY2025 only (the reference has no TY2026
  parameter set; the web side migrates TY2026 saves down to 2025 rather
  than half-supporting them — D32).

A discrepancy found against this map belongs in a
`.github/ISSUE_TEMPLATE` discrepancy report — see the repo tour
(`docs/tour.md`) for the reading order.
