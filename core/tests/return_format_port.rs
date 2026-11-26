// SPDX-License-Identifier: GPL-3.0-only
//! The ported return-format suite (N1 session 2, A1): ALL 15 tests from
//! `clearfile/test/return_format_test.dart` (each test cites its original
//! name in a comment; the two `FileReturnStore` group tests run against an
//! in-memory stand-in for the `returns/` directory because the store is
//! Dart-side filesystem I/O and the pure core owns no store — the envelope
//! contract the store relies on is what is pinned), the cfr /
//! unified-return-format groups from `scripts/txf_taxfile_test.mjs` (its
//! section 3 — the TXF-exporter and `.tax`-container groups belong to the
//! other codec workers), the full-lossless round-trip pin, and tolerance
//! unit tests for the model readers.
//!
//! The two v1 migration samples are the SHARED cross-suite fixtures in
//! `../fixtures/migration/` (DEBT D34): one identical file on disk, the
//! exact ordered warning lists asserted by the Dart suite, the web bridge
//! suite, and this port — drift in wording or ordering fails all three.

use clearfile_core::envelope::{
    decode_return_import, EPOCH_INSTANT_TEXT, ReturnFileCodec, ReturnImport, TaxReturnData,
};
use clearfile_core::json::Json;
use clearfile_core::{DeductionMethod, Dependent, FilingStatus, TaxReturnInput, W2Entry};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// The Dart suite's `sample()` (return_format_test.dart:21-42), with the
/// reference's generated `id` / `DateTime.now()` timestamps fixed to
/// literal text (the pure core owns no clock; equality is on the model,
/// and Dart's own equality is `toJson`-map string equality).
fn sample() -> TaxReturnData {
    TaxReturnData {
        id: "format-test-1".to_owned(),
        display_name: "Format test".to_owned(),
        created: "2026-11-23T10:00:00.000Z".to_owned(),
        modified: "2026-11-23T10:00:00.000Z".to_owned(),
        input: TaxReturnInput {
            tax_year: 2025,
            filing_status: FilingStatus::MarriedJoint,
            taxpayer_65_or_older: true,
            spouse_65_or_older: false,
            taxpayer_blind: false,
            spouse_blind: false,
            w2s: vec![
                W2Entry {
                    employer: "Acme".to_owned(),
                    wages: 90000.0,
                    withholding: 9000.0,
                },
                W2Entry {
                    employer: "Globex".to_owned(),
                    wages: 10000.0,
                    withholding: 500.0,
                },
            ],
            interest_income: 120.5,
            ordinary_dividends: 0.0,
            qualified_dividends: 500.0,
            long_term_capital_gains: 1000.0,
            other_income: 0.0,
            student_loan_interest: 300.0,
            deduction_method: DeductionMethod::Auto,
            state_local_income_or_sales_tax: 8000.0,
            real_estate_tax: 0.0,
            mortgage_interest: 0.0,
            charitable_cash: 0.0,
            charitable_non_cash: 0.0,
            estimated_payments: 700.0,
            dependents: vec![Dependent {
                name: "Kid".to_owned(),
                age: 8,
                relationship: "daughter".to_owned(),
                qualifying_child: true,
                other_dependent_credit: false,
            }],
        },
    }
}

/// A zeroed compute input mirroring the Dart `TaxReturnData` constructor
/// defaults (taxYear 2025, single, auto, all money 0) — the base the
/// ported tests override field by field.
fn default_input() -> TaxReturnInput {
    TaxReturnInput {
        tax_year: 2025,
        filing_status: FilingStatus::Single,
        taxpayer_65_or_older: false,
        spouse_65_or_older: false,
        taxpayer_blind: false,
        spouse_blind: false,
        w2s: Vec::new(),
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

/// `../fixtures/migration` resolved from `CARGO_MANIFEST_DIR` so the suite
/// is CWD-independent (the same pattern as `core/tests/harness/mod.rs`).
fn migration_fixture(name: &str) -> String {
    let path = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .expect("crate dir has a parent")
        .join("fixtures")
        .join("migration")
        .join(name);
    std::fs::read_to_string(&path).expect("shared migration fixture must be readable")
}

/// The exact ordered warning list `fixtures/migration/README.md` (§the
/// exact-warning contract) records for `v1-web-envelope.json`.
const SAVED_WITH_OLDER_PROTOTYPE: &str =
    "Saved with an older prototype: the return was migrated to the current engine model.";
const ADJUSTMENTS_DROPPED: &str = "\"Adjustments to income\" had no equivalent in the current model and was dropped — re-enter it as student loan interest if that is what it was.";
const MEDICAL_OTHER_DROPPED: &str =
    "Medical and \"other\" itemized expenses have no equivalent in the current model and were dropped.";
const DEPENDENT_COUNTS_MIGRATED: &str =
    "Dependent counts were migrated; re-enter their names in the Dependents step.";
const FILING_STATUS_MISSING: &str = "Filing status was missing; defaulted to single.";
const TAX_YEAR_DEFAULTED: &str =
    "Tax year was missing or unsupported; defaulted to 2025 (the engine supports TY2025).";

// ---------------------------------------------------------------------------
// The 15 Dart tests (clearfile/test/return_format_test.dart)
// ---------------------------------------------------------------------------

/// Dart test: 'envelope round-trip preserves the return'
/// (return_format_test.dart:44-53).
#[test]
fn envelope_round_trip_preserves_the_return() {
    let r = sample();
    let text = ReturnFileCodec::encode(&r, "2026-11-23T10:00:00.000Z").expect("encode");
    let decoded = ReturnFileCodec::decode(&text).expect("decode");
    assert!(decoded.warnings.is_empty());
    assert_eq!(decoded.filing, r); // toJson-map equality
    assert_eq!(decoded.filing.display_name, "Format test");
    assert_eq!(decoded.filing.input.w2s.len(), 2);
    assert_eq!(decoded.filing.input.w2s[0].wages, 90000.0);
    assert!(decoded.filing.input.dependents[0].qualifying_child);
}

/// Dart test: 'encode writes the unified envelope, not the legacy markers'
/// (return_format_test.dart:55-66).
#[test]
fn encode_writes_the_unified_envelope_not_the_legacy_markers() {
    let text = ReturnFileCodec::encode(&sample(), "2026-11-23T10:00:00.000Z").expect("encode");
    // 2-space pretty, Dart JsonEncoder.withIndent('  ') byte-shape.
    assert!(text.starts_with("{\n  \"format\": \"clearfile-return\",\n  \"version\": 2,\n"));
    let obj = Json::parse(&text).expect("encoded envelope parses");
    assert_eq!(
        obj.get("format").and_then(Json::as_str),
        Some("clearfile-return")
    );
    assert_eq!(obj.get("version").and_then(Json::as_f64), Some(2.0));
    assert!(!obj.get("app").expect("app").as_str().unwrap_or("").is_empty());
    assert!(!obj.get("savedAt").expect("savedAt").as_str().unwrap_or("").is_empty());
    let filing = obj.get("filing").expect("filing");
    // The legacy markers live ONLY at the envelope level now.
    assert!(filing.get("format").is_none());
    assert!(filing.get("formatVersion").is_none());
    assert_eq!(
        filing.get("displayName").and_then(Json::as_str),
        Some("Format test")
    );
    // Extra pin (purely additive): the envelope's and the filing's key
    // order are the Dart toJson/encode emission contracts, VERBATIM.
    let envelope_keys: Vec<&str> =
        obj.as_obj().expect("envelope").iter().map(|(k, _)| k.as_str()).collect();
    assert_eq!(envelope_keys, vec!["format", "version", "app", "savedAt", "filing"]);
    let filing_keys: Vec<&str> =
        filing.as_obj().expect("filing").iter().map(|(k, _)| k.as_str()).collect();
    assert_eq!(
        filing_keys,
        vec![
            "id",
            "displayName",
            "taxYear",
            "filingStatus",
            "taxpayer65OrOlder",
            "spouse65OrOlder",
            "taxpayerBlind",
            "spouseBlind",
            "w2s",
            "interestIncome",
            "ordinaryDividends",
            "qualifiedDividends",
            "longTermCapitalGains",
            "otherIncome",
            "studentLoanInterest",
            "deductionMethod",
            "stateLocalIncomeOrSalesTax",
            "realEstateTax",
            "mortgageInterest",
            "charitableCash",
            "charitableNonCash",
            "estimatedPayments",
            "dependents",
            "created",
            "modified",
        ]
    );
}

/// Dart test: 'version guard refuses future envelopes (D3)'
/// (return_format_test.dart:68-79).
#[test]
fn version_guard_refuses_future_envelopes_d3() {
    let future = r#"{"format":"clearfile-return","version":3,"filing":{}}"#;
    let err = ReturnFileCodec::decode(future).expect_err("future envelope must be refused");
    assert!(
        err.message.contains("Unsupported version 3"),
        "message must contain 'Unsupported version 3': {}",
        err.message
    );
    assert_eq!(err.message, "Unsupported version 3 (this build supports up to 2).");
}

/// Dart test: 'version guard refuses missing envelope versions'
/// (return_format_test.dart:81-91).
#[test]
fn version_guard_refuses_missing_envelope_versions() {
    let unversioned = r#"{"format":"clearfile-return","filing":{}}"#;
    let err = ReturnFileCodec::decode(unversioned).expect_err("missing version must be refused");
    assert!(
        err.message.contains("Unsupported"),
        "message must contain 'Unsupported': {}",
        err.message
    );
    assert_eq!(err.message, "Unsupported version (missing) (this build supports up to 2).");
}

/// Dart test: 'version guard refuses future flat files'
/// (return_format_test.dart:93-104).
#[test]
fn version_guard_refuses_future_flat_files() {
    let future_flat = r#"{"format":"clearfile.return","formatVersion":7,"displayName":"from the future"}"#;
    let err = ReturnFileCodec::decode(future_flat).expect_err("future flat file must be refused");
    assert!(
        err.message.contains("Unsupported version 7"),
        "message must contain 'Unsupported version 7': {}",
        err.message
    );
    assert_eq!(err.message, "Unsupported version 7 (this build supports up to 2).");
}

/// Dart test: 'legacy flat layout (ClearFile <= v1.0.1) lifts losslessly'
/// (return_format_test.dart:106-113).
#[test]
fn legacy_flat_layout_lifts_losslessly() {
    let r = sample();
    // The model's own flat serialization IS the legacy file shape.
    let legacy = r.to_json_map().write().expect("flat serialization writes");
    let decoded = ReturnFileCodec::decode(&legacy).expect("legacy flat decodes");
    assert_eq!(decoded.filing, r);
    assert!(decoded.warnings.is_empty()); // lossless: nothing to report
}

/// Dart test: 'web v1 envelope migrates with the conservative mapping
/// (shared fixture, D34)' (return_format_test.dart:115-149) — the exact
/// ordered warning list from fixtures/migration/v1-web-envelope.json.
#[test]
fn web_v1_envelope_migrates_with_the_conservative_mapping_shared_fixture_d34() {
    let v1 = migration_fixture("v1-web-envelope.json");
    let decoded = ReturnFileCodec::decode(&v1).expect("v1 fixture decodes");
    let f = &decoded.filing;
    assert_eq!(f.input.filing_status, FilingStatus::MarriedJoint);
    assert_eq!(f.input.tax_year, 2025);
    assert_eq!(f.input.interest_income, 500.0);
    assert_eq!(f.input.ordinary_dividends, 300.0);
    assert_eq!(f.input.student_loan_interest, 0.0); // adjustments dropped, warned
    assert_eq!(f.input.state_local_income_or_sales_tax, 8000.0);
    assert_eq!(f.input.mortgage_interest, 9000.0);
    assert_eq!(f.input.charitable_cash, 1000.0);
    assert_eq!(f.input.w2s[0].employer, "Acme");
    assert_eq!(f.input.dependents.len(), 3); // 2 children + 1 other dependent
    assert_eq!(f.input.dependents.iter().filter(|d| d.qualifying_child).count(), 2);
    assert_eq!(
        f.input.dependents.iter().filter(|d| d.other_dependent_credit).count(),
        1
    );
    // The fromJson defaults for the fields the v1 shape never carried.
    assert_eq!(f.id, "");
    assert_eq!(f.display_name, "Imported return");
    assert_eq!(f.created, EPOCH_INSTANT_TEXT);
    assert_eq!(f.modified, EPOCH_INSTANT_TEXT);
    assert_eq!(
        f.input,
        TaxReturnInput {
            tax_year: 2025,
            filing_status: FilingStatus::MarriedJoint,
            taxpayer_65_or_older: false,
            spouse_65_or_older: false,
            taxpayer_blind: false,
            spouse_blind: false,
            w2s: vec![W2Entry {
                employer: "Acme".to_owned(),
                wages: 90000.0,
                withholding: 9000.0,
            }],
            interest_income: 500.0,
            ordinary_dividends: 300.0,
            qualified_dividends: 0.0,
            long_term_capital_gains: 0.0,
            other_income: 0.0,
            student_loan_interest: 0.0,
            deduction_method: DeductionMethod::Auto,
            state_local_income_or_sales_tax: 8000.0,
            real_estate_tax: 0.0,
            mortgage_interest: 9000.0,
            charitable_cash: 1000.0,
            charitable_non_cash: 0.0,
            estimated_payments: 0.0,
            dependents: vec![
                Dependent {
                    name: String::new(),
                    age: 0,
                    relationship: String::new(),
                    qualifying_child: true,
                    other_dependent_credit: false,
                },
                Dependent {
                    name: String::new(),
                    age: 0,
                    relationship: String::new(),
                    qualifying_child: true,
                    other_dependent_credit: false,
                },
                Dependent {
                    name: String::new(),
                    age: 0,
                    relationship: String::new(),
                    qualifying_child: false,
                    other_dependent_credit: true,
                },
            ],
        }
    );
    // D34: the exact warning list, in order — the bridge suite asserts the
    // same list from the same file.
    assert_eq!(
        decoded.warnings,
        vec![
            SAVED_WITH_OLDER_PROTOTYPE,
            ADJUSTMENTS_DROPPED,
            MEDICAL_OTHER_DROPPED,
            DEPENDENT_COUNTS_MIGRATED,
        ]
    );
}

/// Dart test: 'v1 dependent counts clamp at 100 placeholder rows (shared
/// edge fixture, D34)' (return_format_test.dart:151-172) — qualifying
/// Children 250 → 100 (the historical Dart bound), only the two applicable
/// warnings.
#[test]
fn v1_dependent_counts_clamp_at_100_placeholder_rows_shared_edge_fixture_d34() {
    let v1 = migration_fixture("v1-web-envelope-edge-clamp.json");
    let decoded = ReturnFileCodec::decode(&v1).expect("edge-clamp fixture decodes");
    let f = &decoded.filing;
    assert_eq!(f.input.filing_status, FilingStatus::HeadOfHousehold);
    assert_eq!(f.input.state_local_income_or_sales_tax, 100.0);
    assert_eq!(f.input.w2s[0].employer, "Edge Corp");
    assert_eq!(f.input.dependents.len(), 101); // 250 clamped to 100 + 1 other
    assert_eq!(f.input.dependents.iter().filter(|d| d.qualifying_child).count(), 100);
    assert_eq!(
        f.input.dependents.iter().filter(|d| d.other_dependent_credit).count(),
        1
    );
    assert_eq!(f.input.interest_income, 10.0);
    assert_eq!(f.input.ordinary_dividends, 0.0);
    assert_eq!(f.input.mortgage_interest, 0.0);
    assert_eq!(f.input.charitable_cash, 0.0);
    assert_eq!(
        decoded.warnings,
        vec![SAVED_WITH_OLDER_PROTOTYPE, DEPENDENT_COUNTS_MIGRATED,]
    );
}

/// Dart test: 'missing v2 filing defaults with warnings, matching the web
/// reader' (return_format_test.dart:174-186).
#[test]
fn missing_v2_filing_defaults_with_warnings_matching_the_web_reader() {
    let empty = r#"{"format":"clearfile-return","version":2,"app":"ClearFile 1.0.1","savedAt":"2026-11-15T00:00:00.000Z"}"#;
    let decoded = ReturnFileCodec::decode(empty).expect("empty envelope decodes");
    assert_eq!(decoded.filing.input.filing_status, FilingStatus::Single);
    // The Dart test checks `any(contains('Filing status was missing'))`;
    // the port pins the exact list.
    assert_eq!(decoded.warnings, vec![FILING_STATUS_MISSING]);
    // The fromJson defaults for everything else.
    assert_eq!(decoded.filing.display_name, "Imported return");
    assert_eq!(decoded.filing.input.tax_year, 2025);
    assert_eq!(decoded.filing.created, EPOCH_INSTANT_TEXT);
}

/// Dart test: 'unsupported tax years default to 2025 with a warning'
/// (return_format_test.dart:188-201).
#[test]
fn unsupported_tax_years_default_to_2025_with_a_warning() {
    let future_year =
        r#"{"format":"clearfile-return","version":2,"filing":{"filingStatus":"single","taxYear":2026}}"#;
    let decoded = ReturnFileCodec::decode(future_year).expect("future-year envelope decodes");
    assert_eq!(decoded.filing.input.tax_year, 2025);
    assert_eq!(decoded.warnings, vec![TAX_YEAR_DEFAULTED]);
}

/// Dart test: 'non-JSON files fail with a clear reason'
/// (return_format_test.dart:203-209).
#[test]
fn non_json_files_fail_with_a_clear_reason() {
    let err = ReturnFileCodec::decode("not json at all").expect_err("garbage must fail");
    assert!(
        err.message.contains("not valid JSON"),
        "message must contain 'not valid JSON': {}",
        err.message
    );
    assert_eq!(err.message, "The file is not valid JSON.");
}

/// Dart test: 'foreign files fail with an explicit unrecognized-format
/// error' (return_format_test.dart:211-218).
#[test]
fn foreign_files_fail_with_an_explicit_unrecognized_format_error() {
    let foreign = r#"{"hello":"world"}"#;
    let err = ReturnFileCodec::decode(foreign).expect_err("foreign file must fail");
    assert!(
        err.message.contains("Unrecognized format"),
        "message must contain 'Unrecognized format': {}",
        err.message
    );
    // The full message, with Dart's '(missing)' marker rendering
    // (return_format.dart:95).
    assert_eq!(
        err.message,
        "Unrecognized format \"(missing)\" — expected \"clearfile-return\". This is not a ClearFile return."
    );
}

/// Dart test: 'decodeReturnImport maps outcomes for the picker flow (D1)'
/// (return_format_test.dart:220-232). The Dart suite's `ReturnImportCancelled`
/// arm is picker-side UI (no text is ever decoded for it — envelope.rs
/// divergence #9); the text-driven outcomes are the ones pinned here.
#[test]
fn decode_return_import_maps_outcomes_for_the_picker_flow_d1() {
    let text = ReturnFileCodec::encode(&sample(), "2026-11-23T10:00:00.000Z").expect("encode");
    match decode_return_import(&text) {
        ReturnImport::Ok { filing, warnings } => {
            assert_eq!(filing.display_name, "Format test");
            assert!(warnings.is_empty());
        }
        ReturnImport::Failed { reason } => {
            panic!("a valid envelope must import Ok, got Failed({reason})");
        }
    }

    match decode_return_import("garbage") {
        ReturnImport::Failed { reason } => {
            assert!(
                reason.contains("not valid JSON"),
                "reason must contain 'not valid JSON': {reason}"
            );
        }
        ReturnImport::Ok { .. } => panic!("garbage must import Failed"),
    }
}

/// Dart group 'FileReturnStore uses the same envelope (drop-in
/// compatibility)' > test 'save/listReturns round-trips the envelope on
/// disk' (return_format_test.dart:234-251).
///
/// `FileReturnStore` is Dart-side filesystem I/O (return_store.dart); the
/// pure core owns no store, so the store's contract is pinned against an
/// in-memory stand-in for the `returns/` directory: save writes exactly
/// `ReturnFileCodec::encode`'s output (return_store.dart:71), listReturns
/// decodes each `*.json` and skips failures (return_store.dart:43-64).
#[test]
fn store_save_list_round_trips_the_envelope_on_disk() {
    let r = sample();
    let saved_at = "2026-11-23T10:00:00.000Z";
    // What the store writes on save.
    let on_disk =
        vec![(format!("{}.json", r.id), ReturnFileCodec::encode(&r, saved_at).expect("encode"))];
    // What listReturns reads back: decode each file, skip failures.
    let listed: Vec<TaxReturnData> = on_disk
        .iter()
        .filter_map(|(_, text)| ReturnFileCodec::decode(text).ok())
        .map(|decoded| decoded.filing)
        .collect();
    assert_eq!(listed.len(), 1);
    assert_eq!(listed[0].display_name, "Format test");
    assert_eq!(listed[0].input.w2s.len(), 2);
    // The file on disk is the unified envelope (return_store.dart:54-57
    // reads it back through the same codec).
    let obj = Json::parse(&on_disk[0].1).expect("on-disk text parses");
    assert_eq!(obj.get("format").and_then(Json::as_str), Some("clearfile-return"));
    assert_eq!(obj.get("version").and_then(Json::as_f64), Some(2.0));
}

/// Dart group 'FileReturnStore uses the same envelope (drop-in
/// compatibility)' > test 'legacy flat store files are migrated on read;
/// corrupt skipped' (return_format_test.dart:253-277). Same in-memory
/// stand-in as above: a legacy flat autosave plus a corrupt file in
/// `returns/`; listReturns decodes each, skipping the unreadable one.
#[test]
fn store_legacy_flat_files_migrated_on_read_corrupt_skipped() {
    // The Dart suite's legacy sample (return_format_test.dart:260-265):
    // displayName 'Legacy autosave', interestIncome 42,
    // created DateTime(2020,1,1)/modified DateTime(2020,1,2) — local
    // DateTimes whose toIso8601String() carries no zone suffix.
    let legacy = TaxReturnData {
        id: "legacy-autosave".to_owned(),
        display_name: "Legacy autosave".to_owned(),
        created: "2020-01-01T00:00:00.000".to_owned(),
        modified: "2020-01-02T00:00:00.000".to_owned(),
        input: TaxReturnInput { interest_income: 42.0, ..default_input() },
    };
    let returns_dir = vec![
        ("legacy.json".to_owned(), legacy.to_json_map().write().expect("flat writes")),
        ("broken.json".to_owned(), "not json".to_owned()),
    ];
    let listed: Vec<TaxReturnData> = returns_dir
        .iter()
        .filter_map(|(_, text)| ReturnFileCodec::decode(text).ok())
        .map(|decoded| decoded.filing)
        .collect();
    assert_eq!(listed.len(), 1); // corrupt file skipped, not fatal
    assert_eq!(listed[0].display_name, "Legacy autosave");
    assert_eq!(listed[0].input.interest_income, 42.0);
    // Dart asserts created == DateTime(2020, 1, 1); the port keeps the
    // accepted timestamp text verbatim.
    assert_eq!(listed[0].created, "2020-01-01T00:00:00.000");
}

// ---------------------------------------------------------------------------
// The cfr groups (scripts/txf_taxfile_test.mjs, section 3 — the
// unified-return-format groups; TXF and .tax-container groups are the
// other workers'. Note: the script's .tax "ClearFile exchange container
// round-trip" group also rides a serializeCfr envelope inside its ZIP —
// that mixed group belongs to the tax_inspect worker; the envelope itself
// is pinned here.)
// ---------------------------------------------------------------------------

/// Script group: '[cfr] envelope v2 round-trip'
/// (txf_taxfile_test.mjs:246-268).
///
/// The web model has no `id`/`displayName`/`created`/`modified`; the
/// model-side view of a web-written filing is the Dart reader's defaults
/// for those (id '', 'Imported return', the epoch text), so the ported
/// group builds the model the way the Dart reader reads the web shape.
#[test]
fn cfr_envelope_v2_round_trip() {
    let web_filing = r#"{"taxYear":2025,"filingStatus":"marriedJoint","w2s":[{"employer":"Acme Corp","wages":52500.5,"withholding":6200}],"interestIncome":120.25,"qualifiedDividends":400,"studentLoanInterest":900}"#;
    let filing =
        TaxReturnData::from_json_map(&Json::parse(web_filing).expect("web filing parses"));
    let text = ReturnFileCodec::encode(&filing, "2026-11-23T00:00:00.000Z").expect("encode");
    let envelope = Json::parse(&text).expect("envelope parses");
    assert_eq!(envelope.get("format").and_then(Json::as_str), Some("clearfile-return"));
    assert_eq!(envelope.get("version").and_then(Json::as_f64), Some(2.0));
    let decoded = ReturnFileCodec::decode(&text).expect("decode");
    assert!(decoded.warnings.is_empty());
    assert_eq!(decoded.filing, filing);
    assert_eq!(decoded.filing.input.filing_status, FilingStatus::MarriedJoint);
    assert_eq!(decoded.filing.input.w2s[0].wages, 52500.5);
    assert_eq!(decoded.filing.input.interest_income, 120.25);
    assert_eq!(decoded.filing.input.qualified_dividends, 400.0);
    assert_eq!(decoded.filing.input.student_loan_interest, 900.0);
}

/// Script group: '[cfr] legacy flat layout accepted + guarded'
/// (txf_taxfile_test.mjs:270-296). The web twin additionally warns
/// 'Return metadata (name, dates) … not carried by the web prototype'
/// because the WEB model drops the metadata; the Dart reader (canonical
/// here) carries id/displayName and stays silent — envelope.rs divergence
/// #5.
#[test]
fn cfr_legacy_flat_layout_accepted_and_guarded() {
    let flat = r#"{"format":"clearfile.return","formatVersion":1,"displayName":"From the Flutter app","id":"abc123","taxYear":2025,"filingStatus":"single","interestIncome":42,"w2s":[{"employer":"Initech","wages":60000,"withholding":6000}],"dependents":[{"name":"Kid","age":8,"relationship":"daughter","qualifyingChild":true,"otherDependentCredit":false}]}"#;
    let decoded = ReturnFileCodec::decode(flat).expect("flat layout decodes");
    assert_eq!(decoded.filing.input.interest_income, 42.0);
    assert_eq!(decoded.filing.input.w2s[0].employer, "Initech");
    assert_eq!(decoded.filing.input.dependents.len(), 1);
    // The Dart reader KEEPS the metadata the web reader drops+warns.
    assert_eq!(decoded.filing.id, "abc123");
    assert_eq!(decoded.filing.display_name, "From the Flutter app");
    assert!(decoded.warnings.is_empty());
    // flat guard: a future formatVersion is refused, not guessed at (D3).
    let err = ReturnFileCodec::decode(r#"{"format":"clearfile.return","formatVersion":7}"#)
        .expect_err("future flat file must be refused");
    assert!(
        err.message.contains("Unsupported version 7"),
        "message must contain 'Unsupported version 7': {}",
        err.message
    );
}

/// Script group: '[cfr] version guard + honest failures'
/// (txf_taxfile_test.mjs:298-314).
#[test]
fn cfr_version_guard_and_honest_failures() {
    let err = ReturnFileCodec::decode(r#"{"format":"clearfile-return","version":3,"filing":{}}"#)
        .expect_err("future envelope refused");
    assert_eq!(err.message, "Unsupported version 3 (this build supports up to 2).");
    let err = ReturnFileCodec::decode("not json at all").expect_err("garbage refused");
    assert_eq!(err.message, "The file is not valid JSON.");
    let err = ReturnFileCodec::decode(r#"{"hello":"world"}"#).expect_err("foreign refused");
    assert_eq!(
        err.message,
        "Unrecognized format \"(missing)\" — expected \"clearfile-return\". This is not a ClearFile return."
    );
}

/// Script group: '[cfr] v1 envelope migrated: exact warning list (shared
/// fixture)' (txf_taxfile_test.mjs:316-343) — the identical sample the Dart
/// suite reads from the same file (DEBT D34).
#[test]
fn cfr_v1_envelope_migrated_exact_warning_list_shared_fixture() {
    let v1 = migration_fixture("v1-web-envelope.json");
    let decoded = ReturnFileCodec::decode(&v1).expect("v1 fixture decodes");
    let f = &decoded.filing;
    assert_eq!(f.input.filing_status, FilingStatus::MarriedJoint);
    assert_eq!(f.input.tax_year, 2025);
    assert_eq!(f.input.interest_income, 500.0);
    assert_eq!(f.input.ordinary_dividends, 300.0);
    assert_eq!(f.input.state_local_income_or_sales_tax, 8000.0);
    assert_eq!(f.input.mortgage_interest, 9000.0);
    assert_eq!(f.input.charitable_cash, 1000.0);
    assert_eq!(f.input.dependents.len(), 3);
    assert_eq!(f.input.dependents.iter().filter(|d| d.qualifying_child).count(), 2);
    assert_eq!(
        decoded.warnings,
        vec![
            SAVED_WITH_OLDER_PROTOTYPE,
            ADJUSTMENTS_DROPPED,
            MEDICAL_OTHER_DROPPED,
            DEPENDENT_COUNTS_MIGRATED,
        ]
    );
}

/// Script group: '[cfr] v1 dependent-count clamp (shared edge fixture)'
/// (txf_taxfile_test.mjs:345-366).
#[test]
fn cfr_v1_dependent_count_clamp_shared_edge_fixture() {
    let v1 = migration_fixture("v1-web-envelope-edge-clamp.json");
    let decoded = ReturnFileCodec::decode(&v1).expect("edge fixture decodes");
    let f = &decoded.filing;
    assert_eq!(f.input.filing_status, FilingStatus::HeadOfHousehold);
    assert_eq!(f.input.state_local_income_or_sales_tax, 100.0);
    assert_eq!(f.input.w2s[0].employer, "Edge Corp");
    assert_eq!(f.input.dependents.len(), 101); // 250 clamped to 100 + 1 other
    assert_eq!(f.input.dependents.iter().filter(|d| d.qualifying_child).count(), 100);
    assert_eq!(
        f.input.dependents.iter().filter(|d| d.other_dependent_credit).count(),
        1
    );
    assert_eq!(
        decoded.warnings,
        vec![SAVED_WITH_OLDER_PROTOTYPE, DEPENDENT_COUNTS_MIGRATED,]
    );
}

// ---------------------------------------------------------------------------
// The full-lossless round-trip pin (the task-required extra)
// ---------------------------------------------------------------------------

/// A v2 model with EVERY field populated, encoded and decoded back, must
/// come back EQUAL — and re-encoding the decoded model with the same stamp
/// must be BYTE-IDENTICAL (the emission order is the toJson contract and
/// every reader default is identity for a fully-populated model).
///
/// Intentional asymmetries (documented, by design):
/// - byte-stability holds only for a filing that IS the canonical v2
///   schema: the reader is tolerant, so unknown keys are dropped and
///   missing fields defaulted — a tolerant input does NOT round-trip;
/// - `savedAt` is the caller's purity seam (Dart stamps now()); here the
///   same stamp is passed both ways, so it round-trips too;
/// - timestamps are stored as the accepted ISO text verbatim (no UTC
///   re-normalization), so a `+02:00` timestamp survives verbatim.
#[test]
fn full_lossless_round_trip_every_field_populated() {
    let r = TaxReturnData {
        id: "lossless-001".to_owned(),
        display_name: "Every field populated".to_owned(),
        created: "2026-01-02T03:04:05.678Z".to_owned(),
        modified: "2026-02-03T04:05:06.789Z".to_owned(),
        input: TaxReturnInput {
            tax_year: 2025,
            filing_status: FilingStatus::MarriedJoint,
            taxpayer_65_or_older: true,
            spouse_65_or_older: true,
            taxpayer_blind: true,
            spouse_blind: true,
            w2s: vec![
                W2Entry {
                    employer: "Acme".to_owned(),
                    wages: 123456.78,
                    withholding: 12345.67,
                },
                W2Entry {
                    employer: "Globex".to_owned(),
                    wages: 10000.5,
                    withholding: 500.25,
                },
            ],
            interest_income: 120.25,
            ordinary_dividends: 300.5,
            qualified_dividends: 400.25,
            long_term_capital_gains: 1000.125,
            other_income: 55.55,
            student_loan_interest: 300.25,
            deduction_method: DeductionMethod::Itemized,
            state_local_income_or_sales_tax: 8000.99,
            real_estate_tax: 4000.5,
            mortgage_interest: 9000.25,
            charitable_cash: 1000.1,
            charitable_non_cash: 200.2,
            estimated_payments: 7000.75,
            dependents: vec![
                Dependent {
                    name: "Kid".to_owned(),
                    age: 8,
                    relationship: "daughter".to_owned(),
                    qualifying_child: true,
                    other_dependent_credit: false,
                },
                Dependent {
                    name: "Elder".to_owned(),
                    age: 71,
                    relationship: "parent".to_owned(),
                    qualifying_child: false,
                    other_dependent_credit: true,
                },
            ],
        },
    };
    let saved_at = "2026-11-23T12:00:00.000Z";
    let text = ReturnFileCodec::encode(&r, saved_at).expect("encode");
    let decoded = ReturnFileCodec::decode(&text).expect("decode");
    assert!(decoded.warnings.is_empty());
    assert_eq!(decoded.filing, r);
    let re_encoded = ReturnFileCodec::encode(&decoded.filing, saved_at).expect("re-encode");
    assert_eq!(re_encoded, text, "re-encoding the decoded model must be byte-identical");
}

// ---------------------------------------------------------------------------
// Tolerance unit tests for the model readers (from_json_map over the
// json_codec.dart helpers — behaviors the Dart suite does not pin
// individually but the reader contract defines)
// ---------------------------------------------------------------------------

/// The tolerant reader: unknown `filingStatus` → single (with the warning
/// from `_finish`), unknown `deductionMethod` → auto, non-map list entries
/// dropped (but a bare map entry survives defaulted), number-or-string
/// reads per readDouble/readInt/readString/readBool, and non-string/
/// unparseable dates → the epoch text.
#[test]
fn tolerant_reader_defaults_drops_and_string_reads() {
    let filing_json = r#"{
        "filingStatus": "widowed",
        "taxYear": "2025",
        "deductionMethod": "best",
        "taxpayer65OrOlder": 1,
        "spouse65OrOlder": "true",
        "taxpayerBlind": "1",
        "spouseBlind": "yes",
        "w2s": [{"employer":"Acme","wages":"90000.5","withholding":9}, {"junk":true}, "str", 42, ["nope"]],
        "interestIncome": "120.5",
        "ordinaryDividends": 300,
        "qualifiedDividends": "400.25",
        "longTermCapitalGains": 1000,
        "otherIncome": "junk",
        "studentLoanInterest": "300",
        "stateLocalIncomeOrSalesTax": 8000,
        "realEstateTax": "4000.5",
        "mortgageInterest": 9000,
        "charitableCash": "1000.25",
        "charitableNonCash": 200,
        "estimatedPayments": "700",
        "dependents": [{"name":"Kid","age":"8","relationship":"daughter","qualifyingChild":true,"otherDependentCredit":false}, {"junk":true}, "str", 5],
        "id": 12345,
        "displayName": "Kept",
        "created": 12345,
        "modified": "not a date"
    }"#;
    let text =
        format!("{{\"format\":\"clearfile-return\",\"version\":2,\"filing\":{filing_json}}}");
    let decoded = ReturnFileCodec::decode(&text).expect("tolerant envelope decodes");
    // Only the filing status was unknown — a string "2025" taxYear is a
    // valid readInt read with NO warning (the Dart way; the web twin's
    // num() would read it as 0 and warn — envelope.rs "reader
    // leniencies").
    assert_eq!(decoded.warnings, vec![FILING_STATUS_MISSING]);
    let f = &decoded.filing;
    assert_eq!(f.id, "12345"); // readString stringifies non-strings (Dart v.toString())
    assert_eq!(f.display_name, "Kept");
    assert_eq!(f.input.filing_status, FilingStatus::Single); // unknown → single
    assert_eq!(f.input.tax_year, 2025); // string "2025" read as 2025, no warning
    assert_eq!(f.input.deduction_method, DeductionMethod::Auto); // unknown → auto
    // readBool: number != 0; "true"; "1"; anything else → false.
    assert!(f.input.taxpayer_65_or_older);
    assert!(f.input.spouse_65_or_older);
    assert!(f.input.taxpayer_blind);
    assert!(!f.input.spouse_blind);
    // Non-map w2/dependent entries dropped; a bare map survives defaulted.
    assert_eq!(f.input.w2s.len(), 2);
    assert_eq!(f.input.w2s[0].employer, "Acme");
    assert_eq!(f.input.w2s[0].wages, 90000.5);
    assert_eq!(f.input.w2s[0].withholding, 9.0);
    assert_eq!(
        f.input.w2s[1],
        W2Entry { employer: String::new(), wages: 0.0, withholding: 0.0 }
    );
    // Number-or-string reads.
    assert_eq!(f.input.interest_income, 120.5);
    assert_eq!(f.input.ordinary_dividends, 300.0);
    assert_eq!(f.input.qualified_dividends, 400.25);
    assert_eq!(f.input.long_term_capital_gains, 1000.0);
    assert_eq!(f.input.other_income, 0.0); // "junk" is not a double → fallback
    assert_eq!(f.input.student_loan_interest, 300.0);
    assert_eq!(f.input.state_local_income_or_sales_tax, 8000.0);
    assert_eq!(f.input.real_estate_tax, 4000.5);
    assert_eq!(f.input.mortgage_interest, 9000.0);
    assert_eq!(f.input.charitable_cash, 1000.25);
    assert_eq!(f.input.charitable_non_cash, 200.0);
    assert_eq!(f.input.estimated_payments, 700.0);
    assert_eq!(f.input.dependents.len(), 2);
    assert_eq!(f.input.dependents[0].age, 8); // string "8" read as 8
    assert!(f.input.dependents[0].qualifying_child);
    assert_eq!(
        f.input.dependents[1],
        Dependent {
            name: String::new(),
            age: 0,
            relationship: String::new(),
            qualifying_child: false,
            other_dependent_credit: false,
        }
    );
    // readDate: non-string and unparseable → the epoch text.
    assert_eq!(f.created, EPOCH_INSTANT_TEXT);
    assert_eq!(f.modified, EPOCH_INSTANT_TEXT);
}

/// The readDate acceptance grammar (envelope.rs
/// `is_accepted_iso8601_text`): the pinned shapes plus the documented
/// Dart-accepted forms are kept VERBATIM; everything else falls back to
/// the epoch text.
#[test]
fn read_date_acceptance_and_epoch_fallback() {
    let created_of = |candidate: &str| -> String {
        let filing = Json::Obj(vec![(
            "created".to_owned(),
            Json::Str(candidate.to_owned()),
        )]);
        TaxReturnData::from_json_map(&filing).created
    };
    // Accepted, verbatim (no re-normalization).
    assert_eq!(created_of("2020-01-01T00:00:00.000Z"), "2020-01-01T00:00:00.000Z");
    assert_eq!(created_of("2020-01-01"), "2020-01-01"); // date-only
    assert_eq!(created_of("2020-01-01 13:27:00"), "2020-01-01 13:27:00"); // space separator
    assert_eq!(
        created_of("2012-02-27T13:27:00,123456789z"),
        "2012-02-27T13:27:00,123456789z" // ISO comma fraction + lowercase z
    );
    assert_eq!(created_of("2024-02-29T13:27:00+02:00"), "2024-02-29T13:27:00+02:00"); // leap year + offset
    // Rejected → the epoch text.
    assert_eq!(created_of("2020-02-30T00:00:00Z"), EPOCH_INSTANT_TEXT); // Feb 30
    assert_eq!(created_of("2023-02-29"), EPOCH_INSTANT_TEXT); // non-leap Feb 29
    assert_eq!(created_of("2020-13-01"), EPOCH_INSTANT_TEXT); // month 13
    assert_eq!(created_of("2020-1-01"), EPOCH_INSTANT_TEXT); // one-digit month
    assert_eq!(created_of("2020-01-01T24:00:00"), EPOCH_INSTANT_TEXT); // hour 24
    assert_eq!(created_of("2020-01-01T12:60"), EPOCH_INSTANT_TEXT); // minute 60
    assert_eq!(created_of("2020-01-01T12:30:60"), EPOCH_INSTANT_TEXT); // second 60
    assert_eq!(created_of(" 2020-01-01"), EPOCH_INSTANT_TEXT); // leading whitespace
    assert_eq!(created_of("2020-01-01Z"), EPOCH_INSTANT_TEXT); // zone without a time
    assert_eq!(created_of("2020-01-01T12:30+02"), EPOCH_INSTANT_TEXT); // bare ±hh offset
    assert_eq!(created_of(""), EPOCH_INSTANT_TEXT);
    assert_eq!(created_of("not a date"), EPOCH_INSTANT_TEXT);
    // Non-string values → the epoch (Dart readDate: `v is String` else epoch).
    let filing = Json::Obj(vec![("created".to_owned(), Json::Num(12345.0))]);
    assert_eq!(TaxReturnData::from_json_map(&filing).created, EPOCH_INSTANT_TEXT);
}

/// The v1 migration's status mapping (`_migrateWebV1`,
/// return_format.dart:178-188): mfj/mfs/hoh rename, other strings pass
/// through, missing/non-string → single + the missing-status warning.
/// Also pins the count reads the DART reader owns (readInt is
/// number-or-string and truncates, return_format.dart:214-215) where the
/// web twin accepts numbers only and rounds (cfr.ts:106-107).
#[test]
fn v1_status_mapping_and_count_reads() {
    let cases: &[(&str, FilingStatus, bool)] = &[
        (r#"{"status":"mfj"}"#, FilingStatus::MarriedJoint, false),
        (r#"{"status":"mfs"}"#, FilingStatus::MarriedSeparate, false),
        (r#"{"status":"hoh"}"#, FilingStatus::HeadOfHousehold, false),
        (r#"{"status":"marriedJoint"}"#, FilingStatus::MarriedJoint, false), // pass-through
        (r#"{"status":"survivingSpouse"}"#, FilingStatus::SurvivingSpouse, false), // pass-through
        (r#"{"status":"single"}"#, FilingStatus::Single, false), // pass-through, no warning
        (r#"{"status":"widowed"}"#, FilingStatus::Single, true), // unknown → single + warning
        (r#"{"status":5}"#, FilingStatus::Single, true), // non-string → single + warning
        (r#"{}"#, FilingStatus::Single, true), // missing → single + warning
    ];
    for (filing_json, expected_status, status_warning) in cases {
        let text =
            format!("{{\"format\":\"clearfile-return\",\"version\":1,\"filing\":{filing_json}}}");
        let decoded = ReturnFileCodec::decode(&text).expect("v1 envelope decodes");
        assert_eq!(decoded.filing.input.filing_status, *expected_status, "case {filing_json}");
        let mut expected_warnings = vec![SAVED_WITH_OLDER_PROTOTYPE.to_owned()];
        if *status_warning {
            expected_warnings.push(FILING_STATUS_MISSING.to_owned());
        }
        assert_eq!(decoded.warnings, expected_warnings, "warnings for {filing_json}");
    }

    // Count reads: number-or-string, truncating, clamped to 0..100
    // placeholder rows (return_format.dart:214-242).
    let counts = r#"{"status":"single","qualifyingChildren":250,"otherDependents":"1"}"#;
    let text = format!("{{\"format\":\"clearfile-return\",\"version\":1,\"filing\":{counts}}}");
    let decoded = ReturnFileCodec::decode(&text).expect("counts case decodes");
    assert_eq!(decoded.filing.input.dependents.len(), 101); // 250 → 100 + "1" read as 1
    assert_eq!(decoded.filing.input.dependents.iter().filter(|d| d.qualifying_child).count(), 100);
    assert_eq!(
        decoded.filing.input.dependents.iter().filter(|d| d.other_dependent_credit).count(),
        1
    );
    assert_eq!(
        decoded.warnings,
        vec![SAVED_WITH_OLDER_PROTOTYPE, DEPENDENT_COUNTS_MIGRATED]
    );

    // Dart's readInt truncates (num.toInt()), it does not round — the web
    // twin's Math.round would give 4 here (cfr.ts:106-107).
    let truncated = r#"{"status":"single","qualifyingChildren":3.7}"#;
    let text = format!("{{\"format\":\"clearfile-return\",\"version\":1,\"filing\":{truncated}}}");
    let decoded = ReturnFileCodec::decode(&text).expect("truncation case decodes");
    assert_eq!(decoded.filing.input.dependents.len(), 3);

    // A string count is read by Dart (readInt); the web twin's num() would
    // read 0. Pinned the Dart way.
    let string_count = r#"{"status":"single","qualifyingChildren":"250"}"#;
    let text = format!("{{\"format\":\"clearfile-return\",\"version\":1,\"filing\":{string_count}}}");
    let decoded = ReturnFileCodec::decode(&text).expect("string-count case decodes");
    assert_eq!(decoded.filing.input.dependents.len(), 100); // clamped from 250
}

/// The unrecognized-format and unsupported-version RENDERINGS (Dart
/// `v.toString()` / `${v}` interpolations, return_format.dart:95-98,
/// 106-112): numbers in ECMAScript digits, containers in Dart's
/// `[a, b]` list rendering — plus the top-level non-object branch
/// (divergence #6: the web twin would say 'Unrecognized format
/// "undefined"' for a top-level array) and the non-object filing branch.
#[test]
fn unrecognized_marker_and_version_renderings() {
    // A number marker renders in ECMAScript digits (Dart num.toString).
    let err = ReturnFileCodec::decode(r#"{"format": 5}"#).expect_err("numeric marker refused");
    assert_eq!(
        err.message,
        "Unrecognized format \"5\" — expected \"clearfile-return\". This is not a ClearFile return."
    );
    // A list marker renders in Dart's List.toString form: ["x"] → [x].
    let err = ReturnFileCodec::decode(r#"{"format": ["x"]}"#).expect_err("list marker refused");
    assert_eq!(
        err.message,
        "Unrecognized format \"[x]\" — expected \"clearfile-return\". This is not a ClearFile return."
    );
    // A string version is not an int: refused, with ${v} rendering "2".
    let err =
        ReturnFileCodec::decode(r#"{"format":"clearfile-return","version":"2","filing":{}}"#)
            .expect_err("string version refused");
    assert_eq!(err.message, "Unsupported version 2 (this build supports up to 2).");
    // Top-level non-objects (Dart's `decoded is! Map` check).
    for text in ["[1, 2]", "\"text\"", "42", "null"] {
        let err = ReturnFileCodec::decode(text).expect_err("top-level non-object refused");
        assert_eq!(err.message, "The file does not contain a ClearFile return.");
    }
    // A filing that is present but not an object.
    let err = ReturnFileCodec::decode(r#"{"format":"clearfile-return","version":2,"filing":[1]}"#)
        .expect_err("array filing refused");
    assert_eq!(err.message, "The file has no return payload.");
    // An explicit null filing behaves as an absent one (Dart: raw == null).
    let decoded = ReturnFileCodec::decode(r#"{"format":"clearfile-return","version":2,"filing":null}"#)
        .expect("null filing decodes to defaults");
    assert_eq!(decoded.filing.input.filing_status, FilingStatus::Single);
    assert_eq!(decoded.warnings, vec![FILING_STATUS_MISSING]);
}
