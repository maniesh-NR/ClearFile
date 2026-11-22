#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Independent oracle for the shared golden tax fixtures.

Re-derives every fixture's expected values from the IRS TY2025 form and
worksheet text (Instructions for Form 1040 (2025) incl. the Tax Table, the
Qualified Dividends and Capital Gain Tax Worksheet, and the Student Loan
Interest Deduction Worksheet; Schedule 1-A (2025) Part V; Instructions for
Schedule A (2025) State and Local Taxes Worksheet; Schedule 8812 (2025);
Instructions for Form 8960 (2025)) — deliberately as Decimal arithmetic
written from the publications, NOT from either project engine (Dart or
TypeScript). Its job: prove the fixture numbers are form-derived, and give
the Stage-3 web-parity work a second opinion when an engine disagrees.

Usage: python3 scripts/verify_golden_fixtures.py  (repo root)
Exit code 0 = every fixture in fixtures/tax/ checks out.
"""
from __future__ import annotations

import json
import sys
from decimal import Decimal as D
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FIXTURES = ROOT / "fixtures" / "tax"

# ---------------------------------------------------------------------------
# TY2025 parameters, each pinned to its IRS publication (see
# clearfile/lib/models/tax_year.dart for the source list; values re-typed
# here from the instructions PDFs fetched 2026-11-14).
# ---------------------------------------------------------------------------
D0 = D("0")

STATUS_LIST = ["single", "marriedJoint", "marriedSeparate",
               "headOfHousehold", "survivingSpouse"]

STANDARD_DEDUCTION = {
    "single": D("15750"), "marriedJoint": D("31500"),
    "marriedSeparate": D("15750"), "headOfHousehold": D("23625"),
    "survivingSpouse": D("31500"),
}
ADDITIONAL_65_OR_BLIND = {
    "single": D("2000"), "marriedJoint": D("1600"),
    "marriedSeparate": D("1600"), "headOfHousehold": D("2000"),
    "survivingSpouse": D("1600"),
}
SENIOR_PER_PERSON = D("6000")
SENIOR_START = {"single": D("75000"), "marriedSeparate": D("75000"),
                "headOfHousehold": D("75000"), "marriedJoint": D("150000"),
                "survivingSpouse": D("150000")}
SENIOR_RATE = D("0.06")

BRACKETS = {
    "single": [(D("0.10"), D("11925")), (D("0.12"), D("48475")),
               (D("0.22"), D("103350")), (D("0.24"), D("197300")),
               (D("0.32"), D("250525")), (D("0.35"), D("626350")),
               (D("0.37"), None)],
    "marriedJoint": [(D("0.10"), D("23850")), (D("0.12"), D("96950")),
                     (D("0.22"), D("206700")), (D("0.24"), D("394600")),
                     (D("0.32"), D("501050")), (D("0.35"), D("751600")),
                     (D("0.37"), None)],
    "marriedSeparate": [(D("0.10"), D("11925")), (D("0.12"), D("48475")),
                        (D("0.22"), D("103350")), (D("0.24"), D("197300")),
                        (D("0.32"), D("250525")), (D("0.35"), D("375800")),
                        (D("0.37"), None)],
    "headOfHousehold": [(D("0.10"), D("17000")), (D("0.12"), D("64850")),
                        (D("0.22"), D("103350")), (D("0.24"), D("197300")),
                        (D("0.32"), D("250500")), (D("0.35"), D("626350")),
                        (D("0.37"), None)],
    "survivingSpouse": [(D("0.10"), D("23850")), (D("0.12"), D("96950")),
                        (D("0.22"), D("206700")), (D("0.24"), D("394600")),
                        (D("0.32"), D("501050")), (D("0.35"), D("751600")),
                        (D("0.37"), None)],
}
QDI_ZERO_CAP = {"single": D("48350"), "marriedJoint": D("96700"),
                "marriedSeparate": D("48350"), "headOfHousehold": D("64750"),
                "survivingSpouse": D("96700")}
QDI_FIFTEEN_CAP = {"single": D("533400"), "marriedJoint": D("600050"),
                   "marriedSeparate": D("300000"),
                   "headOfHousehold": D("566700"),
                   "survivingSpouse": D("600050")}
SALT_BASE_CAP = {"single": D("40000"), "marriedJoint": D("40000"),
                 "marriedSeparate": D("20000"),
                 "headOfHousehold": D("40000"),
                 "survivingSpouse": D("40000")}
SALT_START = {"single": D("500000"), "marriedJoint": D("500000"),
              "marriedSeparate": D("250000"),
              "headOfHousehold": D("500000"),
              "survivingSpouse": D("500000")}
SALT_RATE = D("0.30")
SALT_FLOOR = {"single": D("10000"), "marriedJoint": D("10000"),
              "marriedSeparate": D("5000"), "headOfHousehold": D("10000"),
              "survivingSpouse": D("10000")}
NIIT_RATE = D("0.038")
NIIT_THRESHOLD = {"single": D("200000"), "marriedSeparate": D("125000"),
                  "headOfHousehold": D("200000"),
                  "marriedJoint": D("250000"),
                  "survivingSpouse": D("250000")}
CTC_PER_CHILD = D("2200")
ODC_PER_DEPENDENT = D("500")
ACTC_PER_CHILD = D("1700")
ACTC_RATE = D("0.15")
ACTC_EARNED_FLOOR = D("2500")
CTC_PHASEOUT_START = {"single": D("200000"), "marriedSeparate": D("200000"),
                      "headOfHousehold": D("200000"),
                      "marriedJoint": D("400000"),
                      # Schedule 8812 (2025) line 9: "All other filing
                      # statuses—$200,000" — a qualifying surviving spouse is
                      # an other filing status (Pub 501: "doesn't entitle you
                      # to file a joint return"); corrected by the QSS golden
                      # fixture 2026-11-22 (was wrongly the MFJ $400,000).
                      "survivingSpouse": D("200000")}
CTC_PHASEOUT_RATE = D("0.05")
SLI_MAX = D("2500")
SLI_START = {"single": D("85000"), "headOfHousehold": D("85000"),
             "survivingSpouse": D("85000"), "marriedJoint": D("170000"),
             "marriedSeparate": None}  # MFS not eligible
SLI_END = {"single": D("100000"), "headOfHousehold": D("100000"),
           "survivingSpouse": D("100000"), "marriedJoint": D("200000"),
           "marriedSeparate": None}
CHARITY_CASH_LIMIT = D("0.60")
CHARITY_NONCASH_LIMIT = D("0.30")


def bracket_tax(taxable: D, status: str) -> D:
    tax = D0
    lower = D0
    for rate, upto in BRACKETS[status]:
        if taxable <= lower:
            break
        upper = taxable if upto is None else min(taxable, upto)
        tax += (upper - lower) * rate
        if upto is None:
            break
        lower = upto
    return tax


def sli_deduction(paid: D, status: str, magi: D) -> D:
    capped = min(paid, SLI_MAX)
    if capped <= 0:
        return D0
    start, end = SLI_START[status], SLI_END[status]
    if start is None or end is None or end <= start:
        return D0
    if magi <= start:
        return capped
    if magi >= end:
        return D0
    ratio = (magi - start) / (end - start)  # worksheet line 7 (exact allowed)
    return capped * (D("1") - ratio)


def senior_deduction(status: str, taxpayer65: bool, spouse65: bool,
                     agi: D) -> D:
    if status == "marriedSeparate":
        return D0  # Schedule 1-A Part V: married => joint return required
    persons = (1 if taxpayer65 else 0) + (
        1 if spouse65 and status == "marriedJoint" else 0)
    if persons == 0:
        return D0
    start = SENIOR_START[status]
    if agi <= start:
        return SENIOR_PER_PERSON * persons
    per = max(D0, SENIOR_PER_PERSON - SENIOR_RATE * (agi - start))
    return per * persons


def salt_cap(status: str, magi: D) -> D:
    base = SALT_BASE_CAP[status]
    start = SALT_START[status]
    if magi <= start:
        return base
    reduced = base - SALT_RATE * (magi - start)
    return reduced if reduced > SALT_FLOOR[status] else SALT_FLOOR[status]


def ctc_phaseout_amount(status: str, agi: D) -> D:
    """Schedule 8812 (2025) lines 9-11: excess MAGI rounded UP to the next
    multiple of $1,000, then x 5%."""
    raw = agi - CTC_PHASEOUT_START[status]
    if raw <= 0:
        return D0
    # "next multiple of $1,000" = ceiling division. NB: Decimal // is
    # truncating (toward zero), so the usual -(-a//b) idiom is WRONG here;
    # the +999 offset works for the positive raw guaranteed above.
    units = (raw + D("999")) // D("1000")
    return CTC_PHASEOUT_RATE * (units * D("1000"))


def compute(inp: dict) -> dict:
    status = inp["filingStatus"]
    wages = sum((D(str(w["wages"])) for w in inp.get("w2s", [])), D0)
    withholding = sum((D(str(w["withholding"])) for w in inp.get("w2s", [])), D0)
    interest = D(str(inp.get("interestIncome", 0)))
    ord_div = D(str(inp.get("ordinaryDividends", 0)))
    qual_div = D(str(inp.get("qualifiedDividends", 0)))
    ltcg = D(str(inp.get("longTermCapitalGains", 0)))
    other = D(str(inp.get("otherIncome", 0)))
    sli_paid = D(str(inp.get("studentLoanInterest", 0)))
    method = inp.get("deductionMethod", "auto")
    salt_income = D(str(inp.get("stateLocalIncomeOrSalesTax", 0)))
    real_estate = D(str(inp.get("realEstateTax", 0)))
    mortgage = D(str(inp.get("mortgageInterest", 0)))
    charity_cash = D(str(inp.get("charitableCash", 0)))
    charity_noncash = D(str(inp.get("charitableNonCash", 0)))
    estimated = D(str(inp.get("estimatedPayments", 0)))
    deps = inp.get("dependents", [])
    taxpayer65 = inp.get("taxpayer65OrOlder", False)
    spouse65 = inp.get("spouse65OrOlder", False)
    taxpayer_blind = inp.get("taxpayerBlind", False)
    spouse_blind = inp.get("spouseBlind", False)

    total_income = wages + interest + ord_div + qual_div + ltcg + other
    sli = sli_deduction(sli_paid, status, total_income)
    agi = total_income - sli

    salt_paid = max(D0, salt_income + real_estate)
    cap = salt_cap(status, agi)
    salt_allowed = min(salt_paid, cap)
    charity = (min(charity_cash, CHARITY_CASH_LIMIT * max(agi, D0))
               + min(charity_noncash, CHARITY_NONCASH_LIMIT * max(agi, D0)))
    itemized_raw = max(D0, salt_allowed + mortgage + charity)

    senior = senior_deduction(status, taxpayer65, spouse65, agi)

    basic = STANDARD_DEDUCTION[status]
    aged_blind = ((1 if taxpayer65 else 0) + (1 if taxpayer_blind else 0)
                  + (1 if (spouse65 or spouse_blind)
                     and status == "marriedJoint" else 0))
    additional = aged_blind * ADDITIONAL_65_OR_BLIND[status]
    standard_total = basic + additional + senior
    itemized_total = itemized_raw + senior

    if method == "standard":
        used, deduction = "standard", standard_total
    elif method == "itemized":
        used, deduction = "itemized", itemized_total
    else:
        if itemized_total > standard_total:
            used, deduction = "itemized", itemized_total
        else:
            used, deduction = "standard", standard_total

    taxable = max(D0, agi - deduction)

    preferential = min(max(D0, qual_div + ltcg), taxable)
    ordinary_taxable = taxable - preferential
    ordinary_tax = bracket_tax(ordinary_taxable, status)

    zero_cap = QDI_ZERO_CAP[status]
    fifteen_cap = QDI_FIFTEEN_CAP[status]
    at_zero = min(preferential, max(D0, zero_cap - ordinary_taxable))
    rem = preferential - at_zero
    fifteen_room = max(D0, fifteen_cap - max(ordinary_taxable, zero_cap))
    at_fifteen = min(rem, fifteen_room)
    at_twenty = rem - at_fifteen
    preferential_tax = D("0.15") * at_fifteen + D("0.20") * at_twenty

    investment_income = max(D0, interest + ord_div + qual_div + ltcg)
    threshold = NIIT_THRESHOLD[status]
    niit = (NIIT_RATE * min(investment_income, agi - threshold)
            if agi > threshold else D0)

    kids = sum(1 for d in deps if d.get("qualifyingChild"))
    other_deps = sum(1 for d in deps if d.get("otherDependentCredit"))
    gross_ctc = kids * CTC_PER_CHILD
    gross_odc = other_deps * ODC_PER_DEPENDENT
    phase_out = ctc_phaseout_amount(status, agi)
    phased_total = max(D0, gross_ctc + gross_odc - phase_out)
    phased_ctc = max(D0, gross_ctc - phase_out)

    tax_before = ordinary_tax + preferential_tax
    nonrefundable = min(phased_total, tax_before)
    remaining_ctc = max(D0, phased_ctc - min(phased_ctc, nonrefundable))
    refundable = min(
        remaining_ctc,
        min(ACTC_PER_CHILD * kids,
            ACTC_RATE * max(D0, wages - ACTC_EARNED_FLOOR)))

    total_tax = max(D0, tax_before - nonrefundable + niit)
    payments = withholding + estimated
    refund = max(D0, payments + refundable - total_tax)
    owed = max(D0, total_tax - payments - refundable)
    effective = (total_tax / agi) if agi > 0 else D0

    return {
        "totalIncome": total_income, "studentLoanDeduction": sli, "agi": agi,
        "basicStandardDeduction": basic, "additionalStandardDeduction": additional,
        "seniorDeduction": senior, "standardDeductionTotal": standard_total,
        "saltPaid": salt_paid, "saltCap": cap, "saltAllowed": salt_allowed,
        "itemizedDeductionTotal": itemized_total, "deductionMethodUsed": used,
        "deductionUsed": deduction, "taxableIncome": taxable,
        "ordinaryTax": ordinary_tax, "preferentialIncome": preferential,
        "preferentialTax": preferential_tax, "niit": niit,
        "nonRefundableCredits": nonrefundable, "refundableCredits": refundable,
        "totalTax": total_tax, "totalPayments": payments, "refund": refund,
        "amountOwed": owed, "effectiveRate": effective,
        "qualifyingChildren": kids,
    }


def main() -> int:
    if not FIXTURES.is_dir():
        print(f"missing {FIXTURES}", file=sys.stderr)
        return 2
    files = sorted(FIXTURES.glob("*.json"))
    if not files:
        print("no fixtures found", file=sys.stderr)
        return 2

    failures = 0
    for path in files:
        fixture = json.loads(path.read_text())
        name = fixture.get("name", path.name)
        tolerance = D(str(fixture.get("tolerance", 0.005)))
        computed = compute(fixture["input"])
        for key, pinned in fixture["expected"].items():
            if key == "deductionMethodUsed":
                if computed[key] != pinned:
                    print(f"FAIL {name}: {key} oracle={computed[key]} "
                          f"pinned={pinned}")
                    failures += 1
                continue
            delta = abs(D(str(computed[key])) - D(str(pinned)))
            if delta > tolerance:
                print(f"FAIL {name}: {key} oracle={computed[key]} "
                      f"pinned={pinned} delta={delta} tol={tolerance}")
                failures += 1
        print(f"ok   {name} ({len(fixture['expected'])} fields checked)")

    print(f"\n{len(files)} fixtures, {failures} field failures")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
