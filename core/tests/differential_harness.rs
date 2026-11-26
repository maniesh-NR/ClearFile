// SPDX-License-Identifier: GPL-3.0-only
//! The annex-(a) differential harness consumer (N1 session 2, D43's
//! recorded mechanism: "a Dart-side random/edge input generator emitting
//! JSON cases that a later `cargo test` consumes against the Rust core,
//! with the Dart reference computing the same cases in-process").
//!
//! The corpus is `fixtures/differential/cases.json` — 550 cases (seed
//! 771937021), whose expected values the tracked generator
//! (`scripts/generate_differential_cases.dart`) computed by
//! running the Dart reference engine in-process. These are NOT golden
//! fixtures: the golden authoring discipline (ADR-017 annex (d) — never
//! derive expected values by running any engine) applies to
//! `fixtures/tax/`; this corpus is the DIFFERENTIAL contract — the Rust
//! port must reproduce the Dart reference's binary64 outputs EXACTLY
//! (tolerance 0.0, the comparator's `delta == tolerance passes` rule
//! therefore demanding exact equality, NaN fail-closed via
//! `!(delta <= tolerance)`).
//!
//! The 26 pinned keys are the three-runner-derivable set (D31c —
//! `marginalRate` is two-runner-derivable only and is deliberately
//! absent).

mod harness;

use clearfile_core::{compute_ty2025, TaxReturnInput};
use harness::{json_parse, parse_input, Json};
use std::path::PathBuf;

/// The differential corpus: `fixtures/differential/cases.json`, located
/// relative to the crate root exactly like the golden runner's
/// `fixtures/tax/` (STATE quirk 16's explicit-resolution pattern).
fn corpus_path() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("..")
        .join("fixtures")
        .join("differential")
        .join("cases.json")
}

fn load_corpus() -> (Vec<(String, TaxReturnInput, Json)>, i64) {
    let text = std::fs::read_to_string(corpus_path())
        .expect("fixtures/differential/cases.json is a tracked file");
    let root = json_parse(&text).expect("the corpus is valid JSON");
    let kind = root.get("kind").and_then(|j| j.as_str("kind").ok());
    let generator = root.get("generator").and_then(|j| j.as_str("generator").ok());
    let seed = root
        .get("seed")
        .and_then(|j| j.as_f64("seed").ok())
        .filter(|n| n.fract() == 0.0)
        .expect("the corpus carries its seed") as i64;
    let case_count = root
        .get("caseCount")
        .and_then(|j| j.as_f64("caseCount").ok())
        .filter(|n| n.fract() == 0.0)
        .expect("the corpus carries caseCount") as i64;
    assert_eq!(kind, Some("clearfile-differential"));
    assert_eq!(
        generator,
        Some("scripts/generate_differential_cases.dart")
    );
    let cases = root
        .get("cases")
        .and_then(|j| j.as_arr("cases").ok())
        .expect("cases is an array")
        .to_vec();
    assert_eq!(
        cases.len() as i64,
        case_count,
        "the manifest's caseCount must equal the array length"
    );
    let mut out = Vec::with_capacity(cases.len());
    for (i, case) in cases.iter().enumerate() {
        let id = case
            .get("id")
            .and_then(|j| j.as_str("id").ok())
            .unwrap_or("?")
            .to_owned();
        let input_json = case
            .get("input")
            .unwrap_or_else(|| panic!("case {id} (#{i}): missing input"));
        let input = parse_input(input_json)
            .unwrap_or_else(|e| panic!("case {id} (#{i}): strict input reader: {e}"));
        let expected = case
            .get("expected")
            .cloned()
            .unwrap_or_else(|| panic!("case {id} (#{i}): missing expected"));
        out.push((id, input, expected));
    }
    (out, seed)
}

/// Tolerance-0.0 comparator: `!(delta <= 0.0)` fails — exact binary64
/// equality demanded, NaN fail-closed (the same shape the golden
/// runner pins as the oracle's semantics, with the tolerance pinned to
/// zero for the differential contract).
fn assert_exact(case_id: &str, field: &str, expected: f64, computed: f64) {
    let delta = (computed - expected).abs();
    if !(delta <= 0.0) {
        panic!(
            "differential {case_id}: {field} — Dart expected {expected}, \
             Rust computed {computed} (delta {delta})"
        );
    }
}

fn assert_case(case_id: &str, input: &TaxReturnInput, expected: &Json) {
    let r = compute_ty2025(input);
    let expect = |field: &str| -> f64 {
        expected
            .get(field)
            .and_then(|j| j.as_f64(field).ok())
            .unwrap_or_else(|| panic!("differential {case_id}: {field} missing/not a number"))
    };
    assert_exact(case_id, "totalIncome", expect("totalIncome"), r.total_income);
    assert_exact(case_id, "studentLoanDeduction", expect("studentLoanDeduction"), r.student_loan_deduction);
    assert_exact(case_id, "agi", expect("agi"), r.agi);
    assert_exact(case_id, "basicStandardDeduction", expect("basicStandardDeduction"), r.basic_standard_deduction);
    assert_exact(case_id, "additionalStandardDeduction", expect("additionalStandardDeduction"), r.additional_standard_deduction);
    assert_exact(case_id, "seniorDeduction", expect("seniorDeduction"), r.senior_deduction);
    assert_exact(case_id, "standardDeductionTotal", expect("standardDeductionTotal"), r.standard_deduction_total);
    assert_exact(case_id, "saltPaid", expect("saltPaid"), r.salt_paid);
    assert_exact(case_id, "saltCap", expect("saltCap"), r.salt_cap);
    assert_exact(case_id, "saltAllowed", expect("saltAllowed"), r.salt_allowed);
    assert_exact(case_id, "itemizedDeductionTotal", expect("itemizedDeductionTotal"), r.itemized_deduction_total);
    let method = expected
        .get("deductionMethodUsed")
        .and_then(|j| j.as_str("deductionMethodUsed").ok())
        .unwrap_or_else(|| panic!("differential {case_id}: deductionMethodUsed missing"));
    assert_eq!(
        r.deduction_method_used.name(),
        method,
        "differential {case_id}: deductionMethodUsed"
    );
    assert_exact(case_id, "deductionUsed", expect("deductionUsed"), r.deduction_used);
    assert_exact(case_id, "taxableIncome", expect("taxableIncome"), r.taxable_income);
    assert_exact(case_id, "ordinaryTax", expect("ordinaryTax"), r.ordinary_tax);
    assert_exact(case_id, "preferentialIncome", expect("preferentialIncome"), r.preferential_income);
    assert_exact(case_id, "preferentialTax", expect("preferentialTax"), r.preferential_tax);
    assert_exact(case_id, "niit", expect("niit"), r.niit);
    assert_exact(case_id, "nonRefundableCredits", expect("nonRefundableCredits"), r.non_refundable_credits);
    assert_exact(case_id, "refundableCredits", expect("refundableCredits"), r.refundable_credits);
    assert_exact(case_id, "totalTax", expect("totalTax"), r.total_tax);
    assert_exact(case_id, "totalPayments", expect("totalPayments"), r.total_payments);
    assert_exact(case_id, "refund", expect("refund"), r.refund);
    assert_exact(case_id, "amountOwed", expect("amountOwed"), r.amount_owed);
    assert_exact(case_id, "effectiveRate", expect("effectiveRate"), r.effective_rate);
    let kids = expected
        .get("qualifyingChildren")
        .and_then(|j| j.as_f64("qualifyingChildren").ok())
        .filter(|n| n.fract() == 0.0)
        .unwrap_or_else(|| panic!("differential {case_id}: qualifyingChildren missing"))
        as i64;
    assert_eq!(
        r.qualifying_children, kids,
        "differential {case_id}: qualifyingChildren"
    );
}

/// The 26 three-runner-derivable keys (D31c) — exactly this set, no more,
/// no less, on every case.
const KEYS_26: [&str; 26] = [
    "totalIncome", "studentLoanDeduction", "agi", "basicStandardDeduction",
    "additionalStandardDeduction", "seniorDeduction", "standardDeductionTotal",
    "saltPaid", "saltCap", "saltAllowed", "itemizedDeductionTotal",
    "deductionMethodUsed", "deductionUsed", "taxableIncome", "ordinaryTax",
    "preferentialIncome", "preferentialTax", "niit", "nonRefundableCredits",
    "refundableCredits", "totalTax", "totalPayments", "refund", "amountOwed",
    "effectiveRate", "qualifyingChildren",
];

#[test]
fn differential_corpus_shape_and_key_contract() {
    let (corpus, _seed) = load_corpus();
    assert!(
        corpus.len() >= 500,
        "the corpus should carry the full generated set; got {}",
        corpus.len()
    );
    for (id, _, expected) in &corpus {
        let obj = expected
            .as_obj("expected")
            .unwrap_or_else(|e| panic!("differential {id}: expected is not an object: {e}"));
        let mut names: Vec<&str> = obj.iter().map(|(k, _)| k.as_str()).collect();
        names.sort_unstable();
        let mut want: Vec<&str> = KEYS_26.to_vec();
        want.sort_unstable();
        assert_eq!(
            names, want,
            "differential {id}: the expected block carries exactly the 26 keys"
        );
    }
}

#[test]
fn differential_random_and_edge_cases_exact_parity() {
    let (corpus, _seed) = load_corpus();
    let len = corpus.len();
    for (id, input, expected) in &corpus {
        assert_case(id, input, &expected.clone());
    }
    // The whole-corpus run is recorded as the honest headline count.
    println!("differential: {len}/26-field cases exact-parity green");
}

#[test]
fn differential_strict_reader_accepts_every_generated_input() {
    // A corpus case the strict fixture reader rejects would mean the
    // generator drifted from the shared input schema — fail loudly.
    let (corpus, _) = load_corpus();
    assert!(!corpus.is_empty());
}
