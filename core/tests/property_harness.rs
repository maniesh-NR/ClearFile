// SPDX-License-Identifier: GPL-3.0-only
//! The annex-(a) property harness (N1 session 2): engine-level invariants
//! that hold on the WHOLE input continuum, not just pinned points — the
//! annex's "fixtures pin breakpoints, not the continuum" is exactly the
//! gap these close on the Rust side (the differential corpus covers the
//! sampled continuum; these hold by construction on generated grids).
//!
//! Properties proved (each on generated grids, every grid point):
//! 1. `totalIncome` is exactly the reference's left-associated fold.
//! 2. Ordinary tax is monotone non-decreasing in taxable income and
//!    continuous at bracket boundaries (step ≤ ε × top marginal rate).
//! 3. `refund`/`amountOwed` are exclusive (at most one > 0) and ≥ 0.
//! 4. Domain bounds: taxable ≥ 0, niit ≥ 0, totalTax ≥ 0; the effective
//!    rate ∈ [0, 1] when agi > 0 and exactly 0 when agi ≤ 0 (the Dart
//!    `agi > 0` guard).
//! 5. Deduction-method consistency: the label matches the used total;
//!    `auto` picks itemized only when STRICTLY greater.
//! 6. `qualifyingChildren` is exactly the count of qualifying dependents.
//! 7. The D33 QSS↔MFJ column equivalence: identical money fields with
//!    NO dependents ⇒ every derived field identical (the CTC threshold
//!    divergence needs dependents to bite).

mod harness;

use clearfile_core::params::{TaxYearParameters, TY2025};
use clearfile_core::{
    compute_ty2025, DeductionMethod, Dependent, FilingStatus, TaxReturnInput, W2Entry,
};
use harness::{json_parse, parse_input};
use std::path::PathBuf;

/// A wages-only input at `wages` for `status` (the minimal driver of the
/// taxable-income grid).
fn wages_only(wages: f64, status: FilingStatus) -> TaxReturnInput {
    TaxReturnInput {
        tax_year: 2025,
        filing_status: status,
        taxpayer_65_or_older: false,
        spouse_65_or_older: false,
        taxpayer_blind: false,
        spouse_blind: false,
        w2s: vec![W2Entry {
            employer: "Grid".to_owned(),
            wages,
            withholding: 0.0,
        }],
        interest_income: 0.0,
        ordinary_dividends: 0.0,
        qualified_dividends: 0.0,
        long_term_capital_gains: 0.0,
        other_income: 0.0,
        student_loan_interest: 0.0,
        deduction_method: DeductionMethod::Auto,
        state_local_income_or_sales_tax: 0.0,
        real_estate_tax: 0.0,
        mortgage_interest: 0.0,
        charitable_cash: 0.0,
        charitable_non_cash: 0.0,
        estimated_payments: 0.0,
        dependents: Vec::new(),
    }
}

const STATUSES: [FilingStatus; 5] = [
    FilingStatus::Single,
    FilingStatus::MarriedJoint,
    FilingStatus::MarriedSeparate,
    FilingStatus::HeadOfHousehold,
    FilingStatus::SurvivingSpouse,
];

/// Deterministic xorshift64* (the same constants the json battery uses)
/// for pseudo-random property inputs.
struct Rng(u64);
impl Rng {
    fn next_f64(&mut self, lo: f64, hi: f64) -> f64 {
        self.0 ^= self.0 >> 12;
        self.0 ^= self.0 << 25;
        self.0 ^= self.0 >> 27;
        let r = (self.0.wrapping_mul(0x2545_F491_4F6C_DD1D) >> 11) as f64 / (1u64 << 53) as f64;
        lo + r * (hi - lo)
    }
}

// ---------------------------------------------------------------------------
// 1. totalIncome is the reference's left-associated fold
// ---------------------------------------------------------------------------

#[test]
fn property_total_income_is_the_left_associated_fold() {
    let mut rng = Rng(0x9E37_79B9_7F4A_7C15);
    for _ in 0..500 {
        let n = (rng.next_f64(0.0, 5.0) as usize).max(1);
        let w2s: Vec<W2Entry> = (0..n)
            .map(|i| W2Entry {
                employer: format!("W-{i}"),
                wages: rng.next_f64(0.0, 250_000.0),
                withholding: rng.next_f64(0.0, 30_000.0),
            })
            .collect();
        let input = TaxReturnInput {
            w2s,
            interest_income: rng.next_f64(0.0, 20_000.0),
            ordinary_dividends: rng.next_f64(0.0, 5_000.0),
            qualified_dividends: rng.next_f64(0.0, 40_000.0),
            long_term_capital_gains: rng.next_f64(0.0, 60_000.0),
            other_income: rng.next_f64(0.0, 10_000.0),
            filing_status: STATUSES[(rng.next_f64(0.0, 5.0) as usize) % 5],
            ..wages_only(0.0, FilingStatus::Single)
        };
        let r = compute_ty2025(&input);
        // The reference's exact association order (calculator.dart):
        // wages + interest + ordDiv + qualDiv + ltcg + other.
        let expected = input.total_wages()
            + input.interest_income
            + input.ordinary_dividends
            + input.qualified_dividends
            + input.long_term_capital_gains
            + input.other_income;
        assert_eq!(
            r.total_income.to_bits(),
            expected.to_bits(),
            "totalIncome must be the left-associated fold, bitwise"
        );
        // And the same folds on the differential corpus.
    }
    // The differential corpus inputs fold-check too.
    let text = std::fs::read_to_string(
        PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("..")
            .join("fixtures")
            .join("differential")
            .join("cases.json"),
    )
    .expect("the differential corpus is tracked");
    let root = json_parse(&text).unwrap();
    let cases = root.get("cases").and_then(|j| j.as_arr("cases").ok()).unwrap();
    for case in cases {
        let id = case.get("id").and_then(|j| j.as_str("id").ok()).unwrap_or("?");
        let input = parse_input(case.get("input").unwrap()).unwrap();
        let r = compute_ty2025(&input);
        let expected = input.total_income();
        assert_eq!(
            r.total_income.to_bits(),
            expected.to_bits(),
            "differential {id}: totalIncome fold"
        );
        let kids = input
            .dependents
            .iter()
            .filter(|d| d.qualifying_child)
            .count();
        assert_eq!(
            r.qualifying_children,
            kids as i64,
            "differential {id}: qualifyingChildren"
        );
    }
}

// ---------------------------------------------------------------------------
// 2. Ordinary tax monotone + continuous at bracket boundaries
// ---------------------------------------------------------------------------

#[test]
fn property_ordinary_tax_monotone_and_boundary_continuous() {
    let top_rate = 0.37;
    for &status in &STATUSES {
        let sd = TY2025.standard_deduction[status.slot()];
        let mut grid: Vec<f64> = Vec::new();
        for b in &TY2025.ordinary_brackets[status.slot()] {
            // The top bracket is unbounded (up_to = ∞): probe a large
            // finite income deep inside it instead of the bound itself.
            let income = if b.up_to.is_finite() {
                b.up_to + sd
            } else {
                10_000_000.0 + sd
            };
            grid.push(income - 0.01);
            grid.push(income);
            grid.push(income + 0.01);
        }
        grid.push(1.0);
        grid.push(sd * 0.5); // below the deduction: taxable 0
        grid.push(sd);
        grid.push(sd + 0.01);
        for i in 0..600 {
            grid.push(sd + i as f64 * 2_500.0);
        }
        grid.sort_by(|a, b| a.partial_cmp(b).unwrap());
        let mut prev: Option<(f64, f64)> = None; // (income, ordinary_tax)
        for &income in &grid {
            let r = compute_ty2025(&wages_only(income, status));
            if let Some((p_income, p_tax)) = prev {
                assert!(
                    r.ordinary_tax >= p_tax - 1e-9,
                    "{:?} @ {income}: ordinary tax {r_} < previous {p_tax}",
                    status,
                    r_ = r.ordinary_tax
                );
                let step = income - p_income;
                assert!(
                    r.ordinary_tax - p_tax <= step * top_rate + 1e-9,
                    "{:?} @ {income}: bracket step {} exceeds ε×top-rate",
                    status,
                    r.ordinary_tax - p_tax
                );
            }
            prev = Some((income, r.ordinary_tax));
        }
    }
}

// ---------------------------------------------------------------------------
// 3. Refund/owed exclusivity + 4. domain bounds + effective rate
// ---------------------------------------------------------------------------

#[test]
fn property_refund_owed_exclusive_and_bounds_hold() {
    let mut rng = Rng(0x0123_4567_89AB_CDEF);
    for _ in 0..800 {
        let status = STATUSES[(rng.next_f64(0.0, 5.0) as usize) % 5];
        let income = rng.next_f64(0.0, 900_000.0);
        let mut input = wages_only(income, status);
        input.w2s[0].withholding = rng.next_f64(0.0, 120_000.0);
        input.estimated_payments = rng.next_f64(0.0, 40_000.0);
        input.qualified_dividends = rng.next_f64(0.0, 300_000.0);
        input.interest_income = rng.next_f64(0.0, 90_000.0);
        input.dependents = (0..(rng.next_f64(0.0, 4.0) as usize))
            .map(|i| Dependent {
                name: format!("D{i}"),
                age: 7,
                relationship: "child".to_owned(),
                qualifying_child: i % 2 == 0,
                other_dependent_credit: i % 2 == 1,
            })
            .collect();
        let r = compute_ty2025(&input);
        assert!(r.taxable_income >= 0.0, "taxable ≥ 0");
        assert!(r.niit >= 0.0, "niit ≥ 0");
        assert!(r.total_tax >= 0.0, "totalTax ≥ 0");
        assert!(r.refund >= 0.0 && r.amount_owed >= 0.0, "refund/owed ≥ 0");
        assert!(
            !(r.refund > 0.0 && r.amount_owed > 0.0),
            "refund and owed are exclusive"
        );
        if r.agi > 0.0 {
            assert!(
                (0.0..=1.0).contains(&r.effective_rate),
                "effective rate in [0,1] at agi {}",
                r.agi
            );
        } else {
            assert_eq!(
                r.effective_rate, 0.0,
                "the Dart agi>0 guard: no AGI, no rate"
            );
        }
    }
}

// ---------------------------------------------------------------------------
// 5. Deduction-method consistency + 6. qualifyingChildren count
// ---------------------------------------------------------------------------

#[test]
fn property_deduction_choice_and_children_count_consistent() {
    let mut rng = Rng(0x77AA_11BB_22CC_33DD);
    for _ in 0..600 {
        let status = STATUSES[(rng.next_f64(0.0, 5.0) as usize) % 5];
        let mut input = wages_only(rng.next_f64(0.0, 500_000.0), status);
        input.state_local_income_or_sales_tax = rng.next_f64(0.0, 60_000.0);
        input.mortgage_interest = rng.next_f64(0.0, 40_000.0);
        input.charitable_cash = rng.next_f64(0.0, 20_000.0);
        let kids = (rng.next_f64(0.0, 4.0) as usize).max(1);
        input.dependents = (0..kids)
            .map(|i| Dependent {
                name: format!("D{i}"),
                age: 6,
                relationship: "child".to_owned(),
                qualifying_child: true,
                other_dependent_credit: false,
            })
            .collect();
        let r = compute_ty2025(&input);
        match r.deduction_method_used {
            DeductionMethod::Standard => assert_eq!(
                r.deduction_used.to_bits(),
                r.standard_deduction_total.to_bits(),
                "standard label ⇒ the standard total"
            ),
            DeductionMethod::Itemized => assert_eq!(
                r.deduction_used.to_bits(),
                r.itemized_deduction_total.to_bits(),
                "itemized label ⇒ the itemized total"
            ),
            DeductionMethod::Auto => unreachable!("auto never survives the choice"),
        }
        // The auto rule on the same input: itemized only when strictly greater.
        let std_better = r.standard_deduction_total >= r.itemized_deduction_total;
        assert_eq!(
            r.deduction_method_used == DeductionMethod::Standard,
            std_better,
            "auto picks itemized only when STRICTLY greater"
        );
        assert_eq!(
            r.qualifying_children,
            kids as i64,
            "qualifyingChildren == the qualifying count"
        );
    }
}

// ---------------------------------------------------------------------------
// 7. The D33 QSS↔MFJ column equivalence (rates/sd/QDI/NIIT columns — the
//    CTC threshold divergence needs dependents to bite; none here)
// ---------------------------------------------------------------------------

#[test]
fn property_qss_uses_the_mfj_columns_except_ctc() {
    let mut points: Vec<f64> = Vec::new();
    for i in 0..80 {
        points.push(5_000.0 + i as f64 * 15_000.0);
    }
    // The NIIT/QDI/salt threshold zone for the joint columns.
    points.push(130_000.0);
    points.push(250_000.0);
    points.push(260_000.0);
    for &income in &points {
        let qss = compute_ty2025(&wages_only(income, FilingStatus::SurvivingSpouse));
        let mfj = compute_ty2025(&wages_only(income, FilingStatus::MarriedJoint));
        assert_eq!(qss.basic_standard_deduction, mfj.basic_standard_deduction);
        assert_eq!(qss.standard_deduction_total, mfj.standard_deduction_total);
        assert_eq!(qss.taxable_income, mfj.taxable_income);
        assert_eq!(qss.ordinary_tax, mfj.ordinary_tax);
        assert_eq!(qss.preferential_tax, mfj.preferential_tax);
        assert_eq!(qss.niit, mfj.niit);
        assert_eq!(qss.salt_cap, mfj.salt_cap);
        assert_eq!(qss.total_tax, mfj.total_tax);
        assert_eq!(qss.effective_rate, mfj.effective_rate);
    }
    // And the CTC column divergence is real WITH dependents (the D33
    // correction: the CTC threshold is $200,000 for QSS, not the joint
    // $400,000) — pinned on the two thresholds themselves.
    let kid = Dependent {
        name: "Kid".to_owned(),
        age: 7,
        relationship: "child".to_owned(),
        qualifying_child: true,
        other_dependent_credit: false,
    };
    let with_kid = |status: FilingStatus, income: f64| {
        let mut input = wages_only(income, status);
        input.dependents = vec![kid.clone()];
        input
    };
    // QSS at its own $200k threshold: the phase-out bites hard by 260k.
    let qss_at_200k = compute_ty2025(&with_kid(FilingStatus::SurvivingSpouse, 199_999.99));
    let qss_at_260k = compute_ty2025(&with_kid(FilingStatus::SurvivingSpouse, 260_000.0));
    let mfj_at_260k = compute_ty2025(&with_kid(FilingStatus::MarriedJoint, 260_000.0));
    assert_eq!(qss_at_200k.non_refundable_credits, 2200.0, "QSS CTC whole at 199,999.99");
    assert!(
        qss_at_260k.non_refundable_credits < mfj_at_260k.non_refundable_credits,
        "QSS phases out on the 200k column (D33), not the joint 400k"
    );
}

// ---------------------------------------------------------------------------
// 8. Determinism: the same input, bitwise the same result
// ---------------------------------------------------------------------------

#[test]
fn property_compute_is_deterministic() {
    let mut rng = Rng(0x0BAD_CAFE_0123_4567);
    for _ in 0..200 {
        let mut input = wages_only(rng.next_f64(0.0, 400_000.0), STATUSES[(rng.next_f64(0.0, 5.0) as usize) % 5]);
        input.qualified_dividends = rng.next_f64(0.0, 200_000.0);
        input.student_loan_interest = rng.next_f64(0.0, 3_000.0);
        let a = compute_ty2025(&input);
        let b = compute_ty2025(&input);
        assert_eq!(a, b, "the engine is pure and deterministic");
    }
}

// ---------------------------------------------------------------------------
// The parameters themselves: the table invariants the properties lean on
// ---------------------------------------------------------------------------

#[test]
fn property_bracket_tables_are_sorted_and_terse() {
    let p: &TaxYearParameters = &TY2025;
    for status in 0..5 {
        let brackets = &p.ordinary_brackets[status];
        assert_eq!(brackets.len(), 7, "seven TY2025 brackets");
        for w in brackets.windows(2) {
            assert!(
                w[0].rate < w[1].rate,
                "rates strictly increase within a status"
            );
            assert!(w[0].up_to < w[1].up_to, "bounds strictly increase");
        }
        assert!(
            p.standard_deduction[status] > 0.0,
            "a positive standard deduction per status"
        );
    }
}
