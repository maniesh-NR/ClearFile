// SPDX-License-Identifier: GPL-3.0-only
//! The TXF bridge-suite port (N1 session 2, ADR-017 annex (b)): the
//! exporter groups from the web-side bridge suite
//! (`scripts/txf_taxfile_test.mjs` — the `[txf]` blocks) and the importer
//! + money-parser suites from the Dart reference
//! (`clearfile/test/txf_import_test.dart`, 11 tests;
//! `clearfile/test/money_parse_test.dart`, 5 groups — re-pinned here
//! because `parse_money` is ported INTO the core), plus clearly-marked
//! `// port extension:` tests for the port's own documented divergences
//! (the UTF-16 cap arithmetic, the bit-faithful `toFixed(2)`) and the
//! export→import round-trip the annex demands.

use clearfile_core::txf::{export_txf, parse_money, parse_txf, TxfParseError};
use clearfile_core::{DeductionMethod, Dependent, FilingStatus, TaxReturnInput, W2Entry};

// ---------------------------------------------------------------------------
// The mjs's tiny spec-shaped TXF reader, ported 1:1 (the verification
// mirror — an exporter whose output a spec-shaped reader cannot read is
// a bug, not a style choice).
// ---------------------------------------------------------------------------

#[derive(Default)]
struct ReadRecord {
    kind: Option<String>,
    refnum: i64,
    copy: i64,
    line: i64,
    text: Option<String>,
    amounts: Vec<f64>,
}

fn read_txf(text: &str) -> Vec<ReadRecord> {
    let mut records = Vec::new();
    let mut current: Option<ReadRecord> = None;
    let mut in_header = true;
    for raw in text.split('\n') {
        let line = raw.replace('\r', "");
        if line.trim() == "^" {
            in_header = false;
            if let Some(rec) = current.take() {
                records.push(rec);
            }
            continue;
        }
        if line.trim().is_empty() {
            continue;
        }
        if in_header {
            continue;
        }
        let rec = current.get_or_insert_with(ReadRecord::default);
        let mut chars = line.chars();
        let tag = chars.next().unwrap();
        let value = chars.as_str().trim().to_owned();
        match tag {
            'T' => rec.kind = Some(value),
            'N' => rec.refnum = value.parse().unwrap_or(0),
            'C' => rec.copy = value.parse().unwrap_or(0),
            'L' => rec.line = value.parse().unwrap_or(0),
            'P' => rec.text = Some(value),
            '$' if !value.is_empty() => {
                let cleaned: String = value
                    .chars()
                    .filter(|c| *c != '$' && *c != ',')
                    .collect();
                rec.amounts.push(cleaned.parse().unwrap());
            }
            _ => {}
        }
    }
    records
}

// ---------------------------------------------------------------------------
// [txf] exporter verified against spec v042 structure
// (scripts/txf_taxfile_test.mjs group 1)
// ---------------------------------------------------------------------------

fn export_sample() -> TaxReturnInput {
    TaxReturnInput {
        tax_year: 2025,
        filing_status: FilingStatus::Single,
        taxpayer_65_or_older: false,
        spouse_65_or_older: false,
        taxpayer_blind: false,
        spouse_blind: false,
        w2s: vec![
            W2Entry {
                employer: "Acme Corp".to_owned(),
                wages: 52500.5,
                withholding: 6200.0,
            },
            W2Entry {
                employer: "Beta School District".to_owned(),
                wages: 38200.0,
                withholding: 3410.5,
            },
            W2Entry {
                employer: "  ".to_owned(), // blank employer: no 466
                wages: 1000.0,
                withholding: 0.0,
            },
        ],
        interest_income: 120.25,
        ordinary_dividends: 0.0,
        qualified_dividends: 0.0,
        long_term_capital_gains: 0.0,
        other_income: 0.0,
        student_loan_interest: 900.0,
        deduction_method: DeductionMethod::Auto,
        state_local_income_or_sales_tax: 0.0,
        real_estate_tax: 0.0,
        mortgage_interest: 0.0,
        charitable_cash: 0.0,
        charitable_non_cash: 0.0,
        estimated_payments: 0.0,
        dependents: Vec::<Dependent>::new(),
    }
}

#[test]
fn mjs_txf_exporter_verified_against_spec_v042_structure() {
    let out = export_txf(&export_sample(), 3, 16, 2026);
    let lines: Vec<&str> = out.split('\n').collect();

    // header per spec §VIII
    assert_eq!(lines[0], "V042");
    assert!(lines[1].starts_with("A ClearFile 2025"), "A program line");
    assert!(lines[3] == "^");

    let records = read_txf(&out);
    assert!(records.iter().all(|r| r.kind.as_deref() == Some("S")));
    assert!(records.iter().all(|r| r.refnum > 0));

    // W-2 copies: 466 payer (format 2, no $), 460 salary, 461 withholding
    let payers: Vec<&ReadRecord> = records.iter().filter(|r| r.refnum == 466).collect();
    assert_eq!(payers.len(), 2); // the blank employer emits none
    assert_eq!(payers[0].text.as_deref(), Some("Acme Corp"));
    assert_eq!(payers[0].copy, 1);
    assert_eq!(payers[1].text.as_deref(), Some("Beta School District"));
    assert_eq!(payers[1].copy, 2);
    assert!(payers.iter().all(|r| r.amounts.is_empty()));

    let salaries: Vec<&ReadRecord> = records.iter().filter(|r| r.refnum == 460).collect();
    assert_eq!(
        salaries.iter().map(|r| r.copy).collect::<Vec<_>>(),
        vec![1, 2, 3]
    );
    assert_eq!(salaries[0].amounts[0], 52500.5);

    // spec sign convention: money paid is negative (zero stays plain zero)
    let withholdings: Vec<&ReadRecord> = records.iter().filter(|r| r.refnum == 461).collect();
    assert_eq!(
        withholdings.iter().map(|r| r.amounts[0]).collect::<Vec<_>>(),
        vec![-6200.0, -3410.5, 0.0]
    );

    // interest + student loan
    let interest = records.iter().find(|r| r.refnum == 287).unwrap();
    assert_eq!(interest.amounts[0], 120.25);
    let sli = records.iter().find(|r| r.refnum == 636).unwrap();
    assert_eq!(sli.amounts[0], -900.0);

    // C defaults are explicit and L lines are 1
    assert!(records.iter().all(|r| r.copy >= 1 && r.line == 1));

    assert!(out.ends_with('\n'), "trailing newline");
}

// ---------------------------------------------------------------------------
// [txf] empty-return edge: header-only file
// (scripts/txf_taxfile_test.mjs group 2)
// ---------------------------------------------------------------------------

#[test]
fn mjs_txf_empty_return_edge_header_only_file() {
    let mut filing = export_sample();
    filing.w2s.clear();
    filing.interest_income = 0.0;
    filing.student_loan_interest = 0.0;
    let out = export_txf(&filing, 1, 15, 2026);
    assert!(read_txf(&out).is_empty());
    assert_eq!(out.split('\n').next(), Some("V042"));
}

// ---------------------------------------------------------------------------
// Dart clearfile/test/txf_import_test.dart (all 11 tests, ported 1:1)
// ---------------------------------------------------------------------------

#[test]
fn dart_canonical_v042_structure_imports_every_mapped_field() {
    let txf = [
        "V042",
        "AQuicken 2011 for Windows R1",
        "D 03/16/2026",
        "^",
        // W-2 copy 1 (self): payer + salary + withholding
        "TS", "N466", "C1", "PAcme Corp", "^",
        "TS", "N460", "C1", "$ 52500.00", "^",
        "TS", "N461", "C1", "$ -6200.00", "^", // spec sign: money paid is negative
        // W-2 copy 2 (self)
        "TS", "N466", "C2", "PBeta School District", "^",
        "TS", "N460", "C2", "$ 38200.00", "^",
        "TS", "N461", "C2", "$ -3410.50", "^",
        // Interest income, two L lines (sums per spec's multi-line model)
        "TD", "N287", "C1", "L1", "$ 90.00",
        "X 3/24/2026 Our Checking DEP Interest earned", "^",
        "TD", "N287", "C1", "L2", "$ 30.00",
        "X 4/24/2026 Our Checking DEP Interest earned", "^",
        "TS", "N287", "C1", "L1", "$ 120.00", "^",
        // Dividends: total 286, qualified 683
        "TS", "N286", "C1", "$ 1000.00", "^",
        "TS", "N683", "C1", "$ 800.00", "^",
        // Capital gain distribution -> long-term gains
        "TS", "N488", "C1", "$ 450.00", "^",
        // Other income (1040:21)
        "TS", "N257", "C1", "$ 300.00", "^",
        // Sch A: state+local taxes, real estate, mortgage, charity
        "TS", "N275", "C1", "$ -2000.00", "^",
        "TS", "N544", "C1", "$ -400.00", "^",
        "TS", "N276", "C1", "$ -3100.00", "^",
        "TS", "N283", "C1", "$ -8200.00", "^",
        "TS", "N280", "C1", "$ -625.00", "^",
        "TS", "N485", "C1", "$ -1000.00", "^",
        // Estimated tax + student loan interest
        "TS", "N268", "C1", "$ -1000.00", "^",
        "TS", "N636", "C1", "$ -900.00", "^",
    ]
    .join("\n");

    let result = parse_txf(&txf).unwrap();
    let r = &result.return_data.input;

    assert_eq!(r.w2s.len(), 2);
    assert_eq!(r.w2s[0].employer, "Acme Corp");
    assert_eq!(r.w2s[0].wages, 52500.0);
    assert_eq!(r.w2s[0].withholding, 6200.0);
    assert_eq!(r.w2s[1].employer, "Beta School District");
    assert_eq!(r.w2s[1].wages, 38200.0);
    assert_eq!(r.w2s[1].withholding, 3410.5);

    assert_eq!(r.interest_income, 120.0); // detail records ignored, summary only
    assert_eq!(r.ordinary_dividends, 200.0); // total 1000 - qualified 800
    assert_eq!(r.qualified_dividends, 800.0);
    assert_eq!(r.long_term_capital_gains, 450.0);
    assert_eq!(r.other_income, 300.0);
    assert_eq!(r.state_local_income_or_sales_tax, 2400.0); // 275 + 544 magnitudes
    assert_eq!(r.real_estate_tax, 3100.0);
    assert_eq!(r.mortgage_interest, 8200.0);
    assert_eq!(r.charitable_cash, 625.0);
    assert_eq!(r.charitable_non_cash, 1000.0);
    assert_eq!(r.estimated_payments, 1000.0);
    assert_eq!(r.student_loan_interest, 900.0);

    // Honest importer notes, not errors: the 2026 export date (TXF carries
    // no tax-year field) and the two ignored detail records.
    assert_eq!(result.warnings.len(), 2);
    assert!(result.warnings[0].contains('2'));
    assert!(result.warnings[0].contains("2026"));
    assert!(result.warnings[1].contains("detail (TD) records"));
    assert!(result.unknown_codes.is_empty());
}

#[test]
fn dart_record_may_legally_start_at_n_with_no_separate_ts_line() {
    let txf = "V042\nA ClearFile test\nD 01/15/2026\n^\nN460\nC1\n$ 1000\n^\n";
    let result = parse_txf(txf).unwrap();
    assert_eq!(result.return_data.input.w2s.len(), 1);
    assert_eq!(result.return_data.input.w2s[0].wages, 1000.0);
}

#[test]
fn dart_crlf_endings_and_spaced_field_tags_parse() {
    let txf = "V042\r\nA ClearFile test\r\nD 01/15/2026\r\n^\r\nTS\r\nN 460\r\nC 1\r\n$ 1000\r\n^\r\n";
    let result = parse_txf(txf).unwrap();
    assert_eq!(result.return_data.input.w2s.len(), 1);
    assert_eq!(result.return_data.input.w2s[0].wages, 1000.0);
}

#[test]
fn dart_spouse_w2_codes_land_in_their_own_copy_space() {
    let txf = "V042\n^\nTS\nN460\nC1\n$ 1000\n^\nTS\nN506\nC1\n$ 2000\n^\nTS\nN507\nC1\n$ -300\n^\n";
    let result = parse_txf(txf).unwrap();
    let w2s = &result.return_data.input.w2s;
    assert_eq!(w2s.len(), 2);
    assert_eq!(w2s[0].wages, 1000.0);
    assert_eq!(w2s[1].wages, 2000.0);
    assert_eq!(w2s[1].withholding, 300.0);
}

#[test]
fn dart_unknown_refnums_are_reported_not_guessed() {
    let txf = "V042\n^\nTS\nN1234\nC1\n$ 99\n^\nTS\nN460\nC1\n$ 500\n^\n";
    let result = parse_txf(txf).unwrap();
    assert_eq!(result.unknown_codes, vec![1234]);
    assert_eq!(result.return_data.input.w2s.len(), 1);
    assert_eq!(result.return_data.input.w2s[0].wages, 500.0);
    assert!(result.warnings.iter().any(|w| w.contains("1234")));
}

#[test]
fn dart_non_v042_version_and_off_year_export_date_produce_notes() {
    let txf = "V037\n^\nTS\nN460\nC1\n$ 500\n^\n";
    let result = parse_txf(txf).unwrap();
    assert!(result.warnings.iter().any(|w| w.contains("V037")));
    assert_eq!(result.return_data.input.tax_year, 2025);
}

#[test]
fn dart_unparsable_amounts_are_skipped_with_a_warning() {
    let txf = "V042\n^\nTS\nN460\nC1\n$ bananas\n^\n";
    let result = parse_txf(txf).unwrap();
    // No readable amount and no payer means no W-2 entry is created.
    assert!(result.return_data.input.w2s.is_empty());
    assert!(result.warnings.iter().any(|w| w.contains("bananas")));
}

#[test]
fn dart_no_importable_summary_records_throws_an_honest_error() {
    assert_eq!(
        parse_txf("V042\nA test\nD 01/15/2026\n^\n"),
        Err(TxfParseError::NoImportableRecords)
    );
    assert_eq!(
        parse_txf("hello world\n"),
        Err(TxfParseError::NoImportableRecords)
    );
}

#[test]
fn dart_parser_hardening_the_5_mb_cap_throws() {
    let huge = format!("V042\n^\n{}", "x".repeat(5 * 1024 * 1024));
    assert_eq!(parse_txf(&huge), Err(TxfParseError::FileTooLarge));
}

#[test]
fn dart_parser_hardening_a_4097_char_line_throws() {
    let long_line = format!("N460\nC1\n$ {}\n^\n", "9".repeat(5000));
    assert_eq!(
        parse_txf(&format!("V042\n^\n{long_line}")),
        Err(TxfParseError::LineTooLong { line: 5 })
    );
}

#[test]
fn dart_parser_hardening_the_10000_record_cap_throws_eng2() {
    // 10,001 well-formed summary records (~180 KB, far under the 5 MB
    // cap): the record-count cap is the only limit this input trips.
    let record = "TS\nN460\nC1\n$ 1\n^\n";
    let txf = format!("V042\n^\n{}", record.repeat(10_001));
    assert_eq!(parse_txf(&txf), Err(TxfParseError::TooManyRecords));
}

#[test]
fn dart_empty_file_edge_no_records_at_all_throws() {
    assert_eq!(parse_txf(""), Err(TxfParseError::NoImportableRecords));
}

// ---------------------------------------------------------------------------
// Dart clearfile/test/money_parse_test.dart (the 5 groups, re-pinned —
// parse_money is ported INTO the core)
// ---------------------------------------------------------------------------

#[test]
fn dart_money_empty_and_whitespace_only_input_mean_zero() {
    assert_eq!(parse_money(""), Some(0.0));
    assert_eq!(parse_money(" "), Some(0.0));
    assert_eq!(parse_money("\t"), Some(0.0));
    assert_eq!(parse_money("$"), Some(0.0));
}

#[test]
fn dart_money_plain_and_tolerant_us_formats_parse() {
    assert_eq!(parse_money("52500"), Some(52500.0));
    assert_eq!(parse_money("$52,500.00"), Some(52500.0));
    assert_eq!(parse_money("6,200"), Some(6200.0));
    assert_eq!(parse_money(" 6 200 "), Some(6200.0));
    assert_eq!(parse_money("1,234.5"), Some(1234.5));
    assert_eq!(parse_money("-5.25"), Some(-5.25));
}

#[test]
fn dart_money_unparseable_text_returns_none() {
    assert_eq!(parse_money("abc"), None);
    assert_eq!(parse_money("12x"), None);
}

#[test]
fn dart_money_decimal_comma_shapes_are_refused() {
    assert_eq!(parse_money("6,5"), None);
    assert_eq!(parse_money("6,50"), None);
    assert_eq!(parse_money("-1,5"), None);
}

#[test]
fn dart_money_non_us_formats_stay_out_of_scope_pinned() {
    assert_eq!(parse_money("1.234,56"), Some(1.23456));
    assert_eq!(parse_money("1,2,3"), Some(123.0));
}

// ---------------------------------------------------------------------------
// port extension: the module's documented divergences, pinned
// ---------------------------------------------------------------------------

// port extension: divergence #5 — the caps count UTF-16 code units
// (Dart String.length), not Rust bytes or chars.
#[test]
fn port_extension_caps_count_utf16_units_not_bytes() {
    // 'é' is 1 UTF-16 unit but 2 UTF-8 bytes: a 4096-unit P line passes
    // the line cap (8192 bytes), 4097 units refuse — with an importable
    // record present so the no-importable-records refusal cannot mask
    // the outcome.
    let ok_long = format!("P{}", "é".repeat(4095)); // tag + 4095 = 4096 units
    assert!(
        parse_txf(&format!("V042\n^\nTS\nN466\nC1\n{ok_long}\n^\n")).is_ok(),
        "a 4096-unit line (8192 bytes) passes the UTF-16-unit cap"
    );
    let bad_line = format!("P{}", "é".repeat(4096)); // 4097 units
    assert!(matches!(
        parse_txf(&format!("V042\n^\nTS\nN466\nC1\n{bad_line}\n^\n")),
        Err(TxfParseError::LineTooLong { .. })
    ));
    // File cap: 4.5M units across 4,500 mapped records = ~9,000,000 bytes —
    // under the 5,000,000-UNIT cap (a byte-based cap would refuse), over
    // it in bytes, every line under the 4096-unit line cap, under the
    // 10,000-record cap: the file parses.
    let wide_lines: Vec<String> = (0..4_500)
        .map(|_| format!("TS\nN287\nC1\nP{}", "é".repeat(990)))
        .collect();
    let wide = format!("V042\n^\n{}\n^\n", wide_lines.join("\n^\n"));
    let parsed = parse_txf(&wide);
    assert!(
        parsed.is_ok(),
        "the caps count UTF-16 units, not bytes: a ~9,000,000-byte file with \
         4.5M units, 991-unit lines and 4,500 records must parse — got {:?}",
        parsed.err()
    );
    // The bytes-based counterpoint: 6M ASCII units = 6M bytes refuse.
    let ascii_lines: Vec<String> = (0..6_000).map(|_| "P".to_owned() + &"x".repeat(999)).collect();
    let big = format!("V042\n^\n{}\n^\n", ascii_lines.join("\n^\n"));
    assert_eq!(parse_txf(&big), Err(TxfParseError::FileTooLarge));
}

// port extension: the bit-faithful `Number.prototype.toFixed(2)` — the
// rounding cases where Rust's `{:.2}` (half-to-even) would diverge.
#[test]
fn port_extension_money_lines_match_ecmascript_to_fixed_2() {
    let mut filing = export_sample();
    filing.w2s = vec![W2Entry {
        employer: "Rounding Corp".to_owned(),
        wages: 0.125, // half-to-even would print 0.12; ECMAScript prints 0.13
        withholding: 2.675, // the exact f64 is below the tie: 2.67 either way
    }];
    let out = export_txf(&filing, 1, 1, 2026);
    assert!(out.contains("$0.13"), "toFixed(2) tie-to-larger: {out}");
    assert!(out.contains("$-2.67"), "exact-value rounding: {out}");
    // A huge integer >= 2^53: both engines print the exact dyadic
    // expansion (the f64 IS 123456789012345683968).
    let mut huge = export_sample();
    huge.w2s = vec![W2Entry {
        employer: "Big Corp".to_owned(),
        wages: 123456789012345680000.0,
        withholding: 0.0,
    }];
    let out = export_txf(&huge, 1, 1, 2026);
    assert!(out.contains("$123456789012345683968.00"), "exact dyadic expansion: {out}");
}

// port extension: the export→import round-trip the annex demands — an
// exporter whose output the importer cannot read back is a bug. The
// demo scope is lossy (the module docs pin what leaves); for a filing
// whose fields are all inside the exported scope, the round-trip is
// lossless.
#[test]
fn port_extension_export_import_round_trip_is_lossless_in_scope() {
    let original = export_sample();
    let text = export_txf(&original, 3, 16, 2026);
    let result = parse_txf(&text).unwrap();
    let back = &result.return_data.input;
    assert_eq!(back.w2s.len(), 3);
    // The blank-employer W-2 survives with an empty employer (466 is not
    // emitted for it; salary + withholding still round-trip).
    assert_eq!(back.w2s[0].employer, "Acme Corp");
    assert_eq!(back.w2s[0].wages, 52500.5);
    assert_eq!(back.w2s[0].withholding, 6200.0);
    assert_eq!(back.w2s[1].employer, "Beta School District");
    assert_eq!(back.w2s[1].wages, 38200.0);
    assert_eq!(back.w2s[1].withholding, 3410.5);
    assert_eq!(back.w2s[2].employer, "");
    assert_eq!(back.w2s[2].wages, 1000.0);
    assert_eq!(back.w2s[2].withholding, 0.0);
    assert_eq!(back.interest_income, 120.25);
    assert_eq!(back.student_loan_interest, 900.0);
    assert_eq!(result.return_data.display_name, "Imported from TXF");
    assert!(result.unknown_codes.is_empty());
    // The imported filing computes identically to the original.
    let a = clearfile_core::compute_ty2025(&original);
    let b = clearfile_core::compute_ty2025(back);
    assert_eq!(a, b);
}
