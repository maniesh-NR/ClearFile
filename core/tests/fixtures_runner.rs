// SPDX-License-Identifier: GPL-3.0-only
//! The THIRD golden-fixture runner (N1 session 1): runs the std-only Rust
//! core engine against the SHARED 17 fixtures in `fixtures/tax/` with the
//! Python oracle's exact tolerance semantics.
//!
//! Shape (gate ENG-3/PROD-2): ONE `#[test]` per fixture, named after the
//! file — 17 fixture tests. Fixtures whose input features session 1 did
//! not port would carry `#[ignore = "N1 session-2 lane: <reason>"]`
//! (green + ignored == 17; never red on main). Session 1 ports
//! `calculator.dart` whole, so all 17 run (see the skip map in
//! `harness/mod.rs`).
//!
//! Also here: the ENG-1/ENG-2 comparator-semantics unit tests (delta ==
//! tolerance passes; tolerance + 1e-9 fails; NaN/∞ computed values fail),
//! the ENG-adv bracket-boundary test (taxable exactly $11,925 → $1,192.50
//! ordinary tax, verified against BOTH the Dart engine's binary64
//! arithmetic `(11925 − 0) × 0.10 == 1192.5` exactly and the Decimal
//! oracle's `11925 × 0.10 == 1192.5000` before pinning), and the ENG-7
//! strict-reader drift tests (missing/misspelled fields error with the
//! field named).
//!
//! The comparator's five rules and the four arithmetic-semantics traps
//! are documented VERBATIM in `harness/mod.rs`'s module doc-comment.

mod harness;

use clearfile_core::{compute_ty2025, DeductionMethod, FilingStatus, TaxReturnInput, W2Entry};
use harness::{json_parse, parse_input, parse_tolerance, run_fixture, skip_map, within_tolerance,
    FixtureStatus, Json, DEFAULT_TOLERANCE};

// ---------------------------------------------------------------------------
// The 17 golden fixtures — one #[test] per file, named after the file.
// All 17 are RUN (skip map: every entry Run; port is whole per ENG-4).
// If a fixture were deferred, its test would carry
// `#[ignore = "N1 session-2 lane: <reason>"]` — none do today.
// ---------------------------------------------------------------------------

#[test]
fn fixture_00_zero_income() {
    run_fixture("00-zero-income.json");
}

#[test]
fn fixture_01_tax_table_single_25225() {
    run_fixture("01-tax-table-single-25225.json");
}

#[test]
fn fixture_02_tax_table_example_mjf_25325() {
    run_fixture("02-tax-table-example-mjf-25325.json");
}

#[test]
fn fixture_03_qdi_stacking_single() {
    run_fixture("03-qdi-stacking-single.json");
}

#[test]
fn fixture_04_qdi_20pct_and_niit_single() {
    run_fixture("04-qdi-20pct-and-niit-single.json");
}

#[test]
fn fixture_05_qdi_mfs_fifteencap_300000() {
    run_fixture("05-qdi-mfs-fifteencap-300000.json");
}

#[test]
fn fixture_06_niit_mfs_threshold_125000() {
    run_fixture("06-niit-mfs-threshold-125000.json");
}

#[test]
fn fixture_07_senior_single_phaseout() {
    run_fixture("07-senior-single-phaseout.json");
}

#[test]
fn fixture_08_senior_mjs_both_65_phaseout() {
    run_fixture("08-senior-mjs-both-65-phaseout.json");
}

#[test]
fn fixture_09_senior_mfs_ineligible() {
    run_fixture("09-senior-mfs-ineligible.json");
}

#[test]
fn fixture_10_salt_phase_down_mjs() {
    run_fixture("10-salt-phase-down-mjs.json");
}

#[test]
fn fixture_11_salt_mfs_floor() {
    run_fixture("11-salt-mfs-floor.json");
}

#[test]
fn fixture_12_ctc_phaseout_rounding_mjs() {
    // Gate ENG-5: fixture 12 (the rounding fixture) is REQUIRED in the
    // session-1 GREEN set — it pins the CTC cents-normalize-before-ceiling
    // order (trap 2).
    run_fixture("12-ctc-phaseout-rounding-mjs.json");
}

#[test]
fn fixture_13_ctc_phaseout_combined_hoh() {
    run_fixture("13-ctc-phaseout-combined-hoh.json");
}

#[test]
fn fixture_14_actc_refundable_single() {
    run_fixture("14-actc-refundable-single.json");
}

#[test]
fn fixture_15_sli_phaseout_single() {
    run_fixture("15-sli-phaseout-single.json");
}

#[test]
fn fixture_16_surviving_spouse_qss_mapped_thresholds() {
    run_fixture("16-surviving-spouse-qss-mapped-thresholds.json");
}

// ---------------------------------------------------------------------------
// ENG-3 guard: the skip map's key set == the directory's *.json set
// exactly. A new or renamed fixture fails loudly — no silent drift.
// ---------------------------------------------------------------------------

#[test]
fn guard_skip_map_covers_fixture_directory_exactly() {
    let dir_set = harness::directory_fixture_set();
    let map: Vec<(&'static str, FixtureStatus)> = skip_map();
    let map_keys: std::collections::BTreeSet<&str> = map.iter().map(|(f, _)| *f).collect();
    let dir_keys: std::collections::BTreeSet<&str> = dir_set.iter().map(|s| s.as_str()).collect();
    assert_eq!(
        map_keys,
        dir_keys,
        "skip map must map the fixtures/tax directory's *.json set exactly; \
         a fixture was added, renamed, or removed without updating \
         core/tests/harness/mod.rs (FIXTURE_FILES / skip map / manifest)"
    );
    assert_eq!(map.len(), dir_keys.len(), "skip map has duplicate keys");
    for (file, status) in &map {
        match status {
            FixtureStatus::Run => {}
            FixtureStatus::Deferred { reason, feature } => {
                assert!(
                    !reason.is_empty() && !feature.is_empty(),
                    "deferred entry {} must name both a reason and a feature",
                    file
                );
            }
        }
    }
}

// ---------------------------------------------------------------------------
// ENG-1/ENG-2 comparator-semantics unit tests.
// ---------------------------------------------------------------------------

/// Rule 3: delta EXACTLY equal to the tolerance PASSES (not `>`).
/// `0.01 − 0.005` is exactly the f64 value of the `0.005` literal, so this
/// really is the equality edge, not merely a value under it.
#[test]
fn comparator_delta_exactly_tolerance_passes() {
    let computed = 0.01_f64;
    let pinned = 0.005_f64;
    let tolerance = 0.005_f64;
    assert_eq!(computed - pinned, tolerance, "test setup: delta must equal the tolerance exactly");
    assert!(
        within_tolerance(computed, pinned, tolerance),
        "delta == tolerance must PASS (rule 3: fail only when delta > tolerance)"
    );
}

/// Rule 3: tolerance + 1e-9 FAILS.
#[test]
fn comparator_delta_tolerance_plus_epsilon_fails() {
    let tolerance = 0.005_f64;
    let computed = tolerance + 1e-9;
    assert!(
        !within_tolerance(computed, 0.0, tolerance),
        "delta = tolerance + 1e-9 must FAIL"
    );
}

/// Rule 5: a NaN computed value FAILS (fail-closed, `!(delta <= tolerance)`
/// semantics — `delta > tolerance` alone would silently pass).
#[test]
fn comparator_nan_computed_value_fails() {
    assert!(
        !within_tolerance(f64::NAN, 100.0, 0.005),
        "NaN computed values must FAIL the harness (rule 5)"
    );
}

/// Rule 5: an infinite computed value FAILS.
#[test]
fn comparator_infinite_computed_value_fails() {
    assert!(!within_tolerance(f64::INFINITY, 100.0, 0.005), "∞ must FAIL (rule 5)");
    assert!(!within_tolerance(f64::NEG_INFINITY, 0.0, 0.005), "-∞ must FAIL (rule 5)");
}

/// Rule 3 (ENG-1): the comparator is NOT cent-rounded. It compares the RAW
/// delta; cent-quantizing both sides would mask deltas the oracle fails
/// (pinned 100.00, computed 99.9951 at tolerance 0.001: raw delta 0.0049
/// FAILS, but a cent-rounded comparator would quantize the computed value
/// to 100.00 and wrongly pass).
#[test]
fn comparator_does_not_cent_round() {
    // Raw |99.9951 − 100| = 0.0049 > 0.001 → FAIL, NOT quantized to a pass.
    assert!(
        !within_tolerance(99.9951, 100.0, 0.001),
        "cent-rounding would mask this failure; the raw delta must decide"
    );
    // And the raw-difference thresholds stay exact (0.0049 passes / 0.0051
    // fails at the 0.005 default — no quantization steps of $0.01).
    assert!(within_tolerance(0.0049, 0.0, DEFAULT_TOLERANCE));
    assert!(!within_tolerance(0.0051, 0.0, DEFAULT_TOLERANCE));
}

/// Rule 4: the tolerance default is 0.005, and a fixture's own
/// `tolerance` overrides it (fixture 01 pins 0.505 for whole-dollar Tax
/// Table rows).
#[test]
fn tolerance_rule_default_and_fixture_01_override() {
    assert_eq!(DEFAULT_TOLERANCE, 0.005);
    let fixture_01 = harness::load_fixture("01-tax-table-single-25225.json")
        .expect("fixture 01 must load");
    assert_eq!(fixture_01.tolerance, 0.505);
    let fixture_12 = harness::load_fixture("12-ctc-phaseout-rounding-mjs.json")
        .expect("fixture 12 must load");
    assert_eq!(fixture_12.tolerance, DEFAULT_TOLERANCE);
    // A JSON document without a tolerance key parses as the default.
    let root = json_parse(r#"{"name": "no-tolerance-here"}"#).expect("parses");
    assert_eq!(parse_tolerance(&root).expect("tolerance"), DEFAULT_TOLERANCE);
}

/// Rule 2: `deductionMethodUsed` is compared by exact string. The field
/// mapping exposes every numeric fixture key, and the method field is
/// never numeric.
#[test]
fn deduction_method_used_is_an_exact_string_field() {
    let fixture = harness::load_fixture("10-salt-phase-down-mjs.json").expect("fixture 10 loads");
    let result = compute_ty2025(&fixture.input);
    let failures = harness::compare(&fixture, &result);
    assert!(
        failures.is_empty(),
        "fixture 10 (which pins deductionMethodUsed) must pass via the exact-string rule: {:?}",
        failures
    );
    assert_eq!(result.deduction_method_used.name(), "itemized");
    assert_eq!(DeductionMethod::Auto.name(), "auto");
    assert_eq!(DeductionMethod::Standard.name(), "standard");
}

// ---------------------------------------------------------------------------
// ENG-adv boundary tests (the four arithmetic traps' observable edges).
// ---------------------------------------------------------------------------

/// Bracket boundary: taxable income EXACTLY $11,925 (the single 10% rung's
/// inclusive upper bound) → ordinary tax exactly $1,192.50.
///
/// Pinned after verifying the value in BOTH references: the Dart engine's
/// binary64 `(11925 − 0) × 0.10` rounds to exactly 1192.5
/// (11925.0 * 0.1 == 1192.5 holds in IEEE-754 double) and the Decimal
/// oracle computes 11925 × 0.10 = 1192.5000. Upper bounds are INCLUSIVE in
/// both engines (the next rung starts only above 11925).
#[test]
fn bracket_boundary_taxable_exactly_11925_yields_1192_50() {
    let input = TaxReturnInput {
        tax_year: 2025,
        filing_status: FilingStatus::Single,
        taxpayer_65_or_older: false,
        spouse_65_or_older: false,
        taxpayer_blind: false,
        spouse_blind: false,
        w2s: vec![W2Entry {
            employer: "boundary test".to_owned(),
            wages: 27675.0, // 27675 − 15750 standard deduction = 11925 taxable
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
    };
    let result = compute_ty2025(&input);
    assert_eq!(result.taxable_income, 11925.0, "taxable must sit exactly on the rung boundary");
    assert_eq!(result.preferential_income, 0.0);
    assert_eq!(
        result.ordinary_tax, 1192.5,
        "ordinary tax at the inclusive 10% rung boundary is exactly $1,192.50"
    );
    // The boundary is inclusive: 11925 is fully inside the 10% rung, so
    // not one dollar of it is taxed at 12%.
    assert!(result.ordinary_tax < 1192.5 + 0.0000001);
}

/// Trap 3 sanity: Dart round/ceil == Rust f64::round/ceil (half away from
/// zero / ceiling) — the exact pairs the CTC phase-out relies on.
#[test]
fn round_and_ceil_match_dart_semantics() {
    assert_eq!((0.5_f64).round(), 1.0); // half away from zero
    assert_eq!((1.5_f64).round(), 2.0);
    assert_eq!((-0.5_f64).round(), -1.0); // half away from zero, negative side
    assert_eq!((1425.0_f64 * 100.0).round(), 142500.0); // fixture 12's cents step
    assert_eq!((1.425_f64).ceil(), 2.0); // fixture 12's ceiling step
    assert_eq!((2.0_f64).ceil(), 2.0); // exact multiples do not move up
}

/// Trap 4: `dart_min`/`dart_max` propagate NaN like Dart's `min`/`max`
/// (Rust's built-ins ignore NaN). Unreachable via the JSON fixtures (the
/// strict reader rejects non-finite numbers) but pinned here anyway.
#[test]
fn dart_min_max_propagate_nan_like_dart() {
    assert!(clearfile_core::engine::dart_min(f64::NAN, 1.0).is_nan());
    assert!(clearfile_core::engine::dart_min(1.0, f64::NAN).is_nan());
    assert!(clearfile_core::engine::dart_max(f64::NAN, 1.0).is_nan());
    assert!(clearfile_core::engine::dart_max(1.0, f64::NAN).is_nan());
    // Non-NaN behavior matches f64::min/f64::max.
    assert_eq!(clearfile_core::engine::dart_min(1.0, 2.0), 1.0);
    assert_eq!(clearfile_core::engine::dart_max(1.0, 2.0), 2.0);
}

// ---------------------------------------------------------------------------
// ENG-7 strict-reader drift tests: missing/misspelled input fields error
// with the FIELD NAMED (unlike the Dart loader, which defaults silently).
// Each test feeds a deliberately corrupted copy of a real fixture.
// ---------------------------------------------------------------------------

fn corrupt_fixture(corruption: impl Fn(&str) -> String) -> String {
    let path = harness::fixtures_dir().join("00-zero-income.json");
    let text = std::fs::read_to_string(&path).expect("fixture 00 must be readable");
    corruption(&text)
}

/// A fixture with a missing required input field fails with a named-field
/// error (ENG-7 verify).
#[test]
fn strict_reader_errors_on_missing_field_with_named_error() {
    let text = corrupt_fixture(|t| t.replace("\"interestIncome\": 0,", ""));
    let parsed = json_parse(&text).expect("corrupted text is still valid JSON");
    let err = parse_input(parsed.get("input").expect("input present"))
        .expect_err("a missing required field MUST error");
    assert!(
        err.contains("interestIncome"),
        "the error must name the missing field: {}",
        err
    );
    assert!(
        err.contains("missing required field"),
        "the error must say the field is missing: {}",
        err
    );
}

/// A fixture with a misspelled input field fails with a named-field error
/// (the unknown key AND the now-missing real key are both reported — the
/// unknown-key check fires first).
#[test]
fn strict_reader_errors_on_misspelled_field_with_named_error() {
    let text = corrupt_fixture(|t| {
        t.replace("\"ordinaryDividends\"", "\"ordinaryDividendz\"")
    });
    let parsed = json_parse(&text).expect("corrupted text is still valid JSON");
    let err = parse_input(parsed.get("input").expect("input present"))
        .expect_err("a misspelled field MUST error");
    assert!(
        err.contains("ordinaryDividendz"),
        "the error must name the misspelled field: {}",
        err
    );
}

/// An unknown filing status errors (the Dart loader silently defaults to
/// `single` — that is exactly the drift this reader refuses).
#[test]
fn strict_reader_errors_on_unknown_filing_status() {
    let text = corrupt_fixture(|t| {
        t.replace("\"filingStatus\": \"single\"", "\"filingStatus\": \"unmarried\"")
    });
    let parsed = json_parse(&text).expect("corrupted text is still valid JSON");
    let err = parse_input(parsed.get("input").expect("input present"))
        .expect_err("an unknown filing status MUST error");
    assert!(
        err.contains("input.filingStatus") && err.contains("unmarried"),
        "the error must name the field and the bad value: {}",
        err
    );
}

/// An unknown deduction method errors (the Dart loader silently defaults
/// to `auto`).
#[test]
fn strict_reader_errors_on_unknown_deduction_method() {
    let text = corrupt_fixture(|t| {
        t.replace("\"deductionMethod\": \"auto\"", "\"deductionMethod\": \"whichever\"")
    });
    let parsed = json_parse(&text).expect("corrupted text is still valid JSON");
    let err = parse_input(parsed.get("input").expect("input present"))
        .expect_err("an unknown deduction method MUST error");
    assert!(
        err.contains("input.deductionMethod"),
        "the error must name the field: {}",
        err
    );
}

/// A missing/misspelled W-2 subfield errors with the indexed path named.
#[test]
fn strict_reader_errors_on_missing_w2_field() {
    let path = harness::fixtures_dir().join("01-tax-table-single-25225.json");
    let text = std::fs::read_to_string(&path).expect("fixture 01 must be readable");
    // Drop the W-2's withholding subfield (fixture 01's single W-2 line
    // reads `"w2s": [{"employer": "Example W-2", "wages": 40975, "withholding": 0}]`;
    // removing key AND its trailing comma keeps the JSON parseable so the
    // reader-level check is what fires).
    let text = text.replace("\"wages\": 40975, \"withholding\": 0", "\"wages\": 40975");
    let parsed = json_parse(&text).expect("corrupted text is still valid JSON");
    let err = parse_input(parsed.get("input").expect("input present"))
        .expect_err("a missing W-2 field MUST error");
    assert!(
        err.contains("input.w2s[0]") && err.contains("withholding"),
        "the error must name the indexed path and field: {}",
        err
    );
}

/// A wrong-typed input value errors (booleans must be booleans, numbers
/// must be numbers).
#[test]
fn strict_reader_errors_on_wrong_typed_field() {
    let text = corrupt_fixture(|t| {
        t.replace("\"taxpayerBlind\": false", "\"taxpayerBlind\": \"no\"")
    });
    let parsed = json_parse(&text).expect("corrupted text is still valid JSON");
    let err = parse_input(parsed.get("input").expect("input present"))
        .expect_err("a wrong-typed field MUST error");
    assert!(
        err.contains("input.taxpayerBlind"),
        "the error must name the field path: {}",
        err
    );
}

// ---------------------------------------------------------------------------
// Strict JSON parser unit tests (the reader's substrate).
// ---------------------------------------------------------------------------

#[test]
fn json_parser_rejects_non_finite_numbers() {
    // 1e999 overflows to +inf at parse time and must be rejected so NaN/∞
    // can never enter the comparator (rule 5's first line of defense).
    assert!(json_parse("{\"a\": 1e999}").is_err());
    // Underflow to 0.0 (1e-999) is finite and therefore accepted.
    let v = json_parse("[1e-999]").expect("underflow to 0.0 is finite");
    assert_eq!(v, Json::Arr(vec![Json::Num(0.0)]));
}

#[test]
fn json_parser_rejects_duplicate_keys() {
    let err = json_parse(r#"{"a": 1, "a": 2}"#).expect_err("duplicate keys must error");
    assert!(err.contains("duplicate"), "{}", err);
}

#[test]
fn json_parser_rejects_trailing_content() {
    assert!(json_parse("{} {}").is_err());
    assert!(json_parse("[] x").is_err());
}

#[test]
fn json_parser_enforces_number_grammar() {
    assert!(json_parse("01").is_err(), "leading zero is not valid JSON");
    assert!(json_parse("1.").is_err(), "bare fraction point is not valid JSON");
    assert!(json_parse("1e").is_err(), "bare exponent is not valid JSON");
    assert!(json_parse(".5").is_err(), "leading dot is not valid JSON");
    assert!(json_parse("+1").is_err(), "leading plus is not valid JSON");
    let v = json_parse("-12.5e-3").expect("valid exponent form");
    assert_eq!(v, Json::Num(-0.0125));
}

#[test]
fn json_parser_handles_escapes_and_unicode() {
    let v = json_parse(r#"{"s": "a\nb\tc\"d\\e\u2019"}"#).expect("valid escapes");
    match v {
        Json::Obj(entries) => match &entries[0].1 {
            Json::Str(s) => assert_eq!(s, "a\nb\tc\"d\\e\u{2019}"),
            other => panic!("expected string, got {:?}", other),
        },
        other => panic!("expected object, got {:?}", other),
    }
}

#[test]
fn json_parser_handles_surrogate_pairs() {
    let v = json_parse(r#""😀""#).expect("surrogate pair parses");
    assert_eq!(v, Json::Str("\u{1F600}".to_owned()));
}

#[test]
fn json_parser_rejects_naked_nan_infinity_literals() {
    assert!(json_parse("NaN").is_err());
    assert!(json_parse("Infinity").is_err());
    assert!(json_parse("-Infinity").is_err());
}

// ---------------------------------------------------------------------------
// Skip-map mechanism: the deferred lane compiles and carries feature +
// reason (session-2 API preview; nothing is deferred in session 1).
// ---------------------------------------------------------------------------

#[test]
fn deferred_status_carries_feature_keyed_reason() {
    let status = FixtureStatus::Deferred {
        reason: "fixture pins a dependents-based credit beyond CTC/ODC",
        feature: "dependents-based credits beyond CTC/ODC",
    };
    match status {
        FixtureStatus::Run => panic!("constructed a Deferred"),
        FixtureStatus::Deferred { reason, feature } => {
            assert!(!reason.is_empty());
            assert!(!feature.is_empty());
        }
    }
    // And the whole map is well-formed: every entry is Run or a complete
    // Deferred (the guard test checks the key set).
    for (file, status) in skip_map() {
        match status {
            FixtureStatus::Run => {}
            FixtureStatus::Deferred { reason, feature } => {
                assert!(
                    !reason.is_empty() && !feature.is_empty(),
                    "deferred entry {} lacks reason/feature",
                    file
                );
            }
        }
    }
}
