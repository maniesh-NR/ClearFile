// SPDX-License-Identifier: GPL-3.0-only
//! The ClearFile demo federal tax engine — the ordinary-income path ported
//! WHOLE from the Dart reference `clearfile/lib/tax/calculator.dart`
//! (income → adjustments → (standard | itemized) deduction → brackets with
//! qualified-dividend stacking → NIIT → CTC/ACTC/ODC → payments).
//!
//! THIS IS DEMONSTRATION SOFTWARE. It omits many real-return rules and must
//! not be used to file.
//!
//! # Arithmetic-semantics traps (N1 entry gate ENG-5 — all four bind here)
//!
//! 1. **Operation order is preserved exactly** (f64 non-associativity):
//!    the `totalIncome` fold ([`TaxReturnInput::total_income`]), the
//!    bracket accumulation loop ([`bracket_tax`],
//!    calculator.dart:253-263), and every sum/difference below are written
//!    in the Dart expression's left-associated order — re-associating
//!    changes bits, and the golden fixtures are the regression contract.
//! 2. **The CTC cents-normalize happens BEFORE the $1,000 phase-out
//!    ceiling** (calculator.dart:117-122): cents are rounded to the
//!    nearest cent first (so floating-point dust cannot bump an exact
//!    multiple of $1,000 up to the next unit), THEN the excess is ceiled
//!    to the next $1,000. Do NOT port the Python oracle's
//!    `(raw + 999) // 1000` integer idiom (verify_golden_fixtures.py:186-189)
//!    — that exists only because Decimal is exact; this engine is binary64
//!    and needs the two-step form.
//! 3. **Dart `round()`/`ceil()` == Rust [`f64::round`]/[`f64::ceil`]**:
//!    both are half-away-from-zero / ceiling, so the port uses them
//!    directly for the Dart `roundToDouble()`/`ceilToDouble()` calls.
//! 4. **Dart `min`/`max` propagate NaN; Rust's ignore it.** Dart
//!    `dart:math` `min`/`max` return NaN when EITHER argument is NaN;
//!    Rust [`f64::min`]/[`f64::max`] return the non-NaN operand. This port
//!    uses [`dart_min`]/[`dart_max`], which replicate the Dart
//!    propagation, so the semantics match the reference bit-for-bit. The
//!    case is UNREACHABLE via the JSON fixtures (JSON cannot carry NaN and
//!    the strict fixture reader rejects non-finite numbers) but is noted
//!    and handled anyway.

use crate::params::TaxYearParameters;
use crate::{DeductionMethod, FilingStatus, TaxResult, TaxReturnInput};

/// Dart `dart:math` `min`: returns NaN if EITHER argument is NaN
/// (Rust `f64::min` would silently return the other operand — trap 4).
pub fn dart_min(a: f64, b: f64) -> f64 {
    if a.is_nan() || b.is_nan() {
        f64::NAN
    } else {
        a.min(b)
    }
}

/// Dart `dart:math` `max`: returns NaN if EITHER argument is NaN
/// (Rust `f64::max` would silently return the other operand — trap 4).
pub fn dart_max(a: f64, b: f64) -> f64 {
    if a.is_nan() || b.is_nan() {
        f64::NAN
    } else {
        a.max(b)
    }
}

/// Bracket accumulation, ported line-for-line from
/// `calculator.dart:253-263` (`_bracketTax`). The sequential `tax +=`
/// accumulation and the `lowerBound = b.upTo` updates keep the exact
/// operation order (trap 1). Bracket upper bounds are INCLUSIVE in both
/// reference engines: taxable income exactly at a rung boundary fills that
/// rung only.
pub fn bracket_tax(income: f64, brackets: &[crate::params::Bracket]) -> f64 {
    let mut tax = 0.0;
    let mut lower_bound = 0.0;
    for b in brackets {
        if income <= lower_bound {
            break;
        }
        let upper = dart_min(income, b.up_to);
        tax += (upper - lower_bound) * b.rate;
        lower_bound = b.up_to;
    }
    tax
}

/// Marginal-rate lookup, ported line-for-line from
/// `calculator.dart:265-273` (`_marginalRate`). Note it returns the FIRST
/// bracket's rate when `income <= lower_bound` at the first rung (i.e. for
/// zero/negative ordinary taxable income) — faithful to the Dart code;
/// no fixture pins `marginalRate` (D31c).
pub fn marginal_rate(income: f64, brackets: &[crate::params::Bracket]) -> f64 {
    let mut lower_bound = 0.0;
    for b in brackets {
        if income <= lower_bound {
            return brackets[0].rate;
        }
        if income <= b.up_to {
            return b.rate;
        }
        lower_bound = b.up_to;
    }
    brackets[brackets.len() - 1].rate
}

/// Student loan interest deduction, ported from `calculator.dart:212-226`
/// (`_studentLoanDeduction`). MAGI is total income (computed before the
/// deduction itself). The phase-out form is the Dart one:
/// `capped * (end - magi) / (end - start)` — NOT the oracle's
/// `capped * (1 - ratio)` (same value in exact arithmetic, different bits
/// in binary64; trap 1).
fn student_loan_deduction(
    paid: f64,
    status: FilingStatus,
    magi: f64,
    params: &TaxYearParameters,
) -> f64 {
    let capped = dart_min(paid, params.student_loan_max);
    if capped <= 0.0 {
        return 0.0;
    }
    let slot = status.slot();
    let start = params.student_loan_phaseout_start[slot];
    let end = params.student_loan_phaseout_end[slot];
    if end <= start {
        return 0.0; // MFS: not eligible.
    }
    if magi <= start {
        return capped;
    }
    if magi >= end {
        return 0.0;
    }
    capped * (end - magi) / (end - start)
}

/// OBBBA senior deduction, ported from `calculator.dart:228-246`
/// (`_seniorDeduction`). Married filing separately gets nothing
/// (Schedule 1-A (2025) Part V). The spouse's 65+ flag only counts with
/// `hasSpouse`, i.e. exactly `status == MarriedJoint` — a qualifying
/// surviving spouse does NOT get a second senior person.
fn senior_deduction(
    r: &TaxReturnInput,
    status: FilingStatus,
    agi: f64,
    params: &TaxYearParameters,
) -> f64 {
    if status == FilingStatus::MarriedSeparate {
        return 0.0;
    }
    let senior_persons = (r.taxpayer_65_or_older as i64)
        + ((r.spouse_65_or_older && status.has_spouse()) as i64);
    if senior_persons == 0 {
        return 0.0;
    }
    let start = params.senior_phaseout_start[status.slot()];
    let per = params.senior_deduction_per_person;
    if agi <= start {
        return per * senior_persons as f64;
    }
    let phased_per = per - params.senior_phaseout_rate * (agi - start);
    dart_max(0.0, phased_per) * senior_persons as f64
}

/// Aged-or-blind additional-standard-deduction head count, ported from
/// `calculator.dart:248-251` (`_agedOrBlindCount`). The spouse term
/// requires `hasSpouse` (exactly `status == MarriedJoint`) and counts the
/// PAIR once when either spouse flag is set.
fn aged_or_blind_count(r: &TaxReturnInput) -> i64 {
    (r.taxpayer_65_or_older as i64)
        + (r.taxpayer_blind as i64)
        + (((r.spouse_65_or_older || r.spouse_blind) && r.filing_status.has_spouse()) as i64)
}

/// The engine. Port of `TaxCalculator.compute` (calculator.dart:20-208),
/// operation order preserved end-to-end (trap 1); the CTC phase-out keeps
/// the cents-normalize → next-$1,000-ceiling order (trap 2); rounds/ceils
/// are Rust `f64::round`/`f64::ceil` == Dart's (trap 3); mins/maxes are
/// Dart-NaN-propagating ([`dart_min`]/[`dart_max`], trap 4).
pub fn compute(r: &TaxReturnInput, params: &TaxYearParameters) -> TaxResult {
    let status = r.filing_status;

    // ---- Income ----------------------------------------------------------
    let wages = r.total_wages();
    let total_income = r.total_income();

    // ---- Adjustments: student loan interest -------------------------------
    let sli = student_loan_deduction(r.student_loan_interest, status, total_income, params);
    let agi = total_income - sli;

    // ---- Itemized (Schedule A-lite) ---------------------------------------
    let salt_paid = dart_max(0.0, r.state_local_income_or_sales_tax + r.real_estate_tax);
    let salt_cap = params.salt_cap_for(status, agi);
    let salt_allowed = dart_min(salt_paid, salt_cap);
    let positive_agi = dart_max(0.0, agi);
    let charitable_allowed = dart_min(
        r.charitable_cash,
        params.charitable_cash_agi_limit * positive_agi,
    ) + dart_min(
        r.charitable_non_cash,
        params.charitable_non_cash_agi_limit * positive_agi,
    );
    let itemized_raw = dart_max(0.0, salt_allowed + r.mortgage_interest + charitable_allowed);

    // ---- Senior deduction (OBBBA) -----------------------------------------
    let senior = senior_deduction(r, status, agi, params);

    // ---- Standard deduction ------------------------------------------------
    let basic = params.standard_deduction[status.slot()];
    let aged_or_blind_persons = aged_or_blind_count(r);
    let additional = aged_or_blind_persons as f64
        * params.additional_per_aged_or_blind_person[status.slot()];
    let standard_total = basic + additional;

    let standard_deduction_total = standard_total + senior;
    let itemized_deduction_total = itemized_raw + senior;

    // ---- Choose method -----------------------------------------------------
    let used: DeductionMethod = match r.deduction_method {
        DeductionMethod::Standard => DeductionMethod::Standard,
        DeductionMethod::Itemized => DeductionMethod::Itemized,
        DeductionMethod::Auto => {
            if itemized_deduction_total > standard_deduction_total {
                DeductionMethod::Itemized
            } else {
                DeductionMethod::Standard
            }
        }
    };
    let deduction_used = if used == DeductionMethod::Itemized {
        itemized_deduction_total
    } else {
        standard_deduction_total
    };

    // ---- Taxable income -----------------------------------------------------
    let taxable = dart_max(0.0, agi - deduction_used);

    // ---- Tax with qualified dividend / LTCG stacking -------------------------
    let preferential_income = dart_min(
        dart_max(0.0, r.qualified_dividends + r.long_term_capital_gains),
        taxable,
    );
    let ordinary_taxable = taxable - preferential_income;
    let ordinary_tax = bracket_tax(ordinary_taxable, &params.ordinary_brackets[status.slot()]);

    let zero_cap = params.qdi_zero_cap[status.slot()];
    let fifteen_cap = params.qdi_fifteen_cap[status.slot()];
    let mut preferential_remaining = preferential_income;
    let zero_room = dart_max(0.0, zero_cap - ordinary_taxable);
    let at_zero_rate = dart_min(preferential_remaining, zero_room);
    preferential_remaining -= at_zero_rate;
    let fifteen_room = dart_max(0.0, fifteen_cap - dart_max(ordinary_taxable, zero_cap));
    let at_fifteen_rate = dart_min(preferential_remaining, fifteen_room);
    preferential_remaining -= at_fifteen_rate;
    let preferential_tax = 0.15 * at_fifteen_rate + 0.20 * preferential_remaining;

    // ---- Net investment income tax (simplified) -------------------------------
    let investment_income = dart_max(
        0.0,
        r.interest_income
            + r.ordinary_dividends
            + r.qualified_dividends
            + r.long_term_capital_gains,
    );
    let niit_threshold = params.niit_threshold[status.slot()];
    let niit = if agi > niit_threshold {
        params.niit_rate * dart_min(investment_income, agi - niit_threshold)
    } else {
        0.0
    };

    // ---- Credits -----------------------------------------------------------
    let kids: i64 = r
        .dependents
        .iter()
        .filter(|d| d.qualifying_child)
        .count() as i64;
    let other_dependents: i64 = r
        .dependents
        .iter()
        .filter(|d| d.other_dependent_credit)
        .count() as i64;
    let ctc_phaseout_start = params.ctc_phaseout_start[status.slot()];
    // Schedule 8812 (2025), line 10: the excess MAGI is rounded UP to the
    // next multiple of $1,000 BEFORE the 5% phase-out is applied ("if the
    // result is $425, enter $1,000; if the result is $1,025, enter $2,000").
    // Cents-normalize FIRST (trap 2) so floating-point dust cannot bump an
    // exact multiple of $1,000 up to the next unit; then ceiling to the
    // next $1,000. This two-step binary64 form replaces the Decimal
    // oracle's exact `(raw + 999) // 1000` idiom.
    let raw_excess = agi - ctc_phaseout_start;
    let excess_cents = if raw_excess <= 0.0 {
        0.0
    } else {
        (raw_excess * 100.0).round() // Dart (rawExcess * 100).roundToDouble()
    };
    let phase_out_base = if excess_cents <= 0.0 {
        0.0
    } else {
        (excess_cents / 100000.0).ceil() * 1000.0 // Dart ceilToDouble() * 1000
    };
    let phase_out_amount = params.ctc_phaseout_rate * phase_out_base;
    let gross_ctc = kids as f64 * params.ctc_per_child;
    let gross_odc = other_dependents as f64 * params.odc_per_dependent;
    // 8812 line 12: the phase-out reduces the COMBINED CTC + ODC amount,
    // floored at zero (not each credit separately).
    let phased_total = dart_max(0.0, gross_ctc + gross_odc - phase_out_amount);
    // ODC is strictly non-refundable, so only the CTC portion feeds the
    // refundable ACTC side.
    let phased_ctc = dart_max(0.0, gross_ctc - phase_out_amount);

    let tax_before_credits = ordinary_tax + preferential_tax;
    let non_refundable_credits = dart_min(phased_total, tax_before_credits);

    // Refundable ACTC (simplified): 15% of earned income above the floor,
    // capped at the per-child refundable amount.
    let earned_income = wages;
    let remaining_ctc = dart_max(0.0, phased_ctc - non_refundable_credits);
    let refundable_credits = dart_min(
        remaining_ctc,
        dart_min(
            params.actc_per_child * kids as f64,
            params.actc_rate * dart_max(0.0, earned_income - params.actc_earned_income_floor),
        ),
    );

    // Refundable credits are paid out like withholding (1040 payments side).
    let total_tax = dart_max(0.0, tax_before_credits - non_refundable_credits + niit);

    // ---- Payments ------------------------------------------------------------
    let payments = r.total_withholding() + r.estimated_payments;
    let refund = dart_max(0.0, payments + refundable_credits - total_tax);
    let owed = dart_max(0.0, total_tax - payments - refundable_credits);

    // The `agi > 0` guard (calculator.dart:155) survives the port: zero or
    // negative AGI must produce an effective rate of 0.0, never NaN
    // (fixture 00 pins effectiveRate: 0).
    let effective_rate = if agi > 0.0 { total_tax / agi } else { 0.0 };
    let marginal = marginal_rate(ordinary_taxable, &params.ordinary_brackets[status.slot()]);

    TaxResult {
        total_income,
        student_loan_deduction: sli,
        agi,
        basic_standard_deduction: basic,
        additional_standard_deduction: additional,
        senior_deduction: senior,
        standard_deduction_total,
        salt_paid,
        salt_cap,
        salt_allowed,
        itemized_deduction_total,
        deduction_method_used: used,
        deduction_used,
        taxable_income: taxable,
        ordinary_tax,
        preferential_income,
        preferential_tax,
        niit,
        non_refundable_credits,
        refundable_credits,
        total_tax,
        total_payments: payments,
        refund,
        amount_owed: owed,
        effective_rate,
        marginal_rate: marginal,
        qualifying_children: kids,
    }
}

/// Convenience wrapper mirroring the Dart default parameter
/// (`compute(r, {params = TaxYearParameters.ty2025})`).
pub fn compute_ty2025(r: &TaxReturnInput) -> TaxResult {
    compute(r, &crate::params::TY2025)
}
