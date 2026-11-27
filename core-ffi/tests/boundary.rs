// SPDX-License-Identifier: GPL-3.0-only
//! The boundary battery (the N3 gate's ledger, SEC-4/ENG): every C
//! function exercised THROUGH the `extern "C"` boundary — the shared
//! golden-fixture corpus + the 550-case differential corpus at parsed
//! parity with the core's own outputs, the malformed-input classes
//! (never a panic — the guard), both cap batteries, the input-size
//! bound, the panic-injection proof, the palette marshaling, and the
//! envelope round-trips. This file links the crate's rlib leg and calls
//! the same `#[no_mangle] pub extern "C"` functions the cdylib exports
//! (the audit surface), never a parallel test-only API.

use clearfile_core::envelope::TaxReturnData;
use clearfile_core::json::Json;
use clearfile_core::palette::{scheme_role, PaletteRole};
use clearfile_core::tax_inspect::{export_tax_container, make_zip};
use clearfile_core::{compute_ty2025, INPUT_TOO_LARGE_MESSAGE};
use clearfile_core_ffi::{
    clearfile_compute, clearfile_decode_envelope, clearfile_encode_envelope, clearfile_free,
    clearfile_import_txf, clearfile_inspect_tax, clearfile_last_error, clearfile_load_and_compute,
    clearfile_palette_scheme_role,
};
use std::ffi::CStr;
use std::ffi::CString;

// ---------------------------------------------------------------------------
// The marshaling helpers (the test side of the two return classes)
// ---------------------------------------------------------------------------

/// Call a text-payload function, take the owned buffer as a Rust string,
/// free it through the one free fn (the contract), and assert no error.
type CTextFn = extern "C" fn(*const std::ffi::c_char, usize) -> *mut std::ffi::c_char;

fn call_ok(payload: &str, f: CTextFn) -> String {
    let owned = f(payload.as_ptr() as *const _, payload.len());
    assert!(
        !owned.is_null(),
        "the call must succeed; last_error: {}",
        last_error_text()
    );
    assert_eq!(last_error_text(), "", "a success clears the last error");
    // SAFETY: the data functions' owned-return contract (CString::into_raw
    // on the other side); the take-back + drop happens inside take_owned.
    let text = unsafe { CStr::from_ptr(owned) }.to_string_lossy().into_owned();
    clearfile_free(owned);
    text
}

/// Call a bytes-payload function (the same shape, byte payloads).
fn call_bytes_ok(
    payload: &[u8],
    f: CTextFn,
) -> String {
    let owned = f(payload.as_ptr() as *const _, payload.len());
    assert!(
        !owned.is_null(),
        "the call must succeed; last_error: {}",
        last_error_text()
    );
    let text = unsafe { CStr::from_ptr(owned) }.to_string_lossy().into_owned();
    clearfile_free(owned);
    text
}

/// Call a function expecting the named failure; returns the message.
fn call_err(payload: &[u8], f: CTextFn) -> String {
    let owned = f(payload.as_ptr() as *const _, payload.len());
    assert!(owned.is_null(), "the call must fail for a malformed payload");
    let message = last_error_text();
    assert!(!message.is_empty(), "the failure must set the last error");
    message
}

/// The borrowed last-error text (the ABI's second return class, copied).
fn last_error_text() -> String {
    // SAFETY: the borrowed thread-local pointer, valid until the next
    // call on this thread (the contract); copied immediately.
    unsafe { CStr::from_ptr(clearfile_last_error()) }
        .to_string_lossy()
        .into_owned()
}

/// One fixture file's parsed input/expected/tolerance triple.
struct Fixture {
    input: Json,
    expected: Vec<(String, Json)>,
    tolerance: f64,
}

/// Load one shared golden fixture (the same corpus the Dart/TS/Rust
/// runners consume — `fixtures/tax/`).
fn load_fixture(file: &str) -> Fixture {
    let text = std::fs::read_to_string(format!("../fixtures/tax/{file}")).unwrap();
    let root = Json::parse(&text).expect("the fixture must parse");
    let pairs = root.as_obj().expect("the fixture must be an object");
    let input = pairs
        .iter()
        .find(|(k, _)| k == "input")
        .map(|(_, v)| v.clone())
        .expect("the fixture must carry an input");
    let expected = match pairs
        .iter()
        .find(|(k, _)| k == "expected")
        .map(|(_, v)| v.clone())
        .expect("the fixture must carry an expected")
    {
        Json::Obj(ref pairs) => pairs.clone(),
        _ => panic!("the fixture's expected must be an object"),
    };
    let tolerance = match pairs.iter().find(|(k, _)| k == "tolerance") {
        Some((_, Json::Num(n))) => *n,
        _ => 0.0,
    };
    Fixture { input, expected, tolerance }
}

/// The comparator's rule 3 (the golden runner's semantics, shared): raw
/// comparison, NOT cent-rounded — `delta <= tolerance` passes; NaN
/// fail-closed.
fn assert_within(case: &str, field: &str, expected: f64, computed: f64, tolerance: f64) {
    assert!(
        (computed - expected).abs() <= tolerance,
        "{case}: {field}: boundary={computed} pinned={expected} (tol {tolerance})"
    );
}

// ---------------------------------------------------------------------------
// (a) The 17 shared golden fixtures THROUGH the boundary (SEC-4)
// ---------------------------------------------------------------------------

#[test]
fn golden_fixtures_through_the_boundary() {
    let files = std::fs::read_dir("../fixtures/tax")
        .unwrap()
        .filter_map(|entry| {
            let name = entry.unwrap().file_name().into_string().ok()?;
            name.ends_with(".json").then_some(name)
        })
        .collect::<Vec<_>>();
    assert_eq!(files.len(), 17, "the shared corpus is the 17 fixtures");
    for file in files {
        let fixture = load_fixture(&file);
        let input_text = fixture.input.write().unwrap();
        let output = call_ok(&input_text, clearfile_compute);
        let parsed = Json::parse(&output).expect("the boundary output must be JSON");
        let obj = parsed.as_obj().expect("the boundary output must be an object");
        for (key, pinned) in &fixture.expected {
            let computed = obj
                .iter()
                .find(|(k, _)| k == key)
                .map(|(_, v)| v.clone())
                .unwrap_or_else(|| panic!("{}: the boundary output lacks {key}", file));
            match (computed.clone(), pinned.clone()) {
                (Json::Num(c), Json::Num(p)) => {
                    assert_within(&file, key, p, c, fixture.tolerance);
                }
                (Json::Str(c), Json::Str(p)) => {
                    assert_eq!(c, p, "{}: {key} must match verbatim", file);
                }
                other => panic!("{}: {key}: kind mismatch {other:?}", file),
            }
        }
    }
}

// ---------------------------------------------------------------------------
// (b) The 550-case differential corpus THROUGH the boundary (SEC adv-1:
// the non-ASCII marshaling catcher + exact binary64 parity)
// ---------------------------------------------------------------------------

#[test]
fn differential_corpus_through_the_boundary() {
    let text = std::fs::read_to_string("../fixtures/differential/cases.json").unwrap();
    let root = Json::parse(&text).unwrap();
    let pairs = root.as_obj().unwrap();
    let count = match pairs.iter().find(|(k, _)| k == "caseCount") {
        Some((_, Json::Num(n))) => *n as usize,
        _ => panic!("the corpus must carry caseCount"),
    };
    let cases = match pairs
        .iter()
        .find(|(k, _)| k == "cases")
        .map(|(_, v)| v.clone())
        .expect("the corpus must carry cases")
    {
        Json::Arr(items) => items,
        _ => panic!("cases must be an array"),
    };
    assert_eq!(cases.len(), count, "the corpus's count field is honest");
    let mut checked_fields = 0usize;
    for case in &cases {
        let case_pairs = case.as_obj().unwrap();
        let id = match case_pairs.iter().find(|(k, _)| k == "id") {
            Some((_, Json::Str(s))) => s.clone(),
            _ => panic!("every case carries an id"),
        };
        let input = case_pairs
            .iter()
            .find(|(k, _)| k == "input")
            .map(|(_, v)| v.clone())
            .expect("input");
        let expected = match case_pairs
            .iter()
            .find(|(k, _)| k == "expected")
            .map(|(_, v)| v.clone())
            .expect("expected")
        {
            Json::Obj(ref pairs) => pairs.clone(),
            _ => panic!("expected must be an object"),
        };
        let input_text = input.write().unwrap();
        let output = call_ok(&input_text, clearfile_compute);
        let parsed = Json::parse(&output).expect("JSON out");
        let obj = parsed.as_obj().unwrap();
        for (key, pinned) in &expected {
            let computed = obj
                .iter()
                .find(|(k, _)| k == key)
                .map(|(_, v)| v.clone())
                .unwrap_or_else(|| panic!("case {id}: the boundary output lacks {key}"));
            match (computed, pinned.clone()) {
                (Json::Num(c), Json::Num(p)) => {
                    // Tolerance 0.0, the differential harness's exact
                    // binary64 rule (`!(delta <= 0.0)` fails).
                    assert!(
                        (c - p).abs() <= 0.0,
                        "case {id}: {key}: boundary={c} pinned={p}"
                    );
                    checked_fields += 1;
                }
                (Json::Str(c), Json::Str(p)) => assert_eq!(c, p, "case {id}: {key}"),
                other => panic!("case {id}: {key}: kind mismatch {other:?}"),
            }
        }
    }
    assert!(
        checked_fields >= 550 * 20,
        "the corpus's per-case field count: {checked_fields} checked over {count} cases"
    );
}

// ---------------------------------------------------------------------------
// (c) The malformed classes THROUGH the boundary (SEC-4: named errors,
// never a panic — the guard holds on the real path)
// ---------------------------------------------------------------------------

#[test]
fn malformed_inputs_through_the_boundary() {
    // Not valid JSON → the codec's app-parity message (what the
    // Linux app's pipeline surfaces for the same bytes); the raw
    // compute path surfaces the parser's own named error.
    let message = call_err(b"{ nope", clearfile_load_and_compute);
    assert_eq!(message, "The file is not valid JSON.");
    let message = call_err(b"{ nope", clearfile_compute);
    assert!(message.contains("unexpected"), "the parser's own named error: {message}");
    // Not a ClearFile envelope → the core's own message, verbatim.
    let message = call_err(br#"{ "format": "something-else" }"#, clearfile_load_and_compute);
    assert!(
        message.contains("Unrecognized format \"something-else\""),
        "the envelope error must surface verbatim: {message}"
    );
    // Not valid UTF-8 → the wording family.
    let message = call_err(&[0xFF, 0xFE, 0x00], clearfile_load_and_compute);
    assert!(
        message.contains("not valid UTF-8"),
        "the UTF-8 error must surface: {message}"
    );
    // Empty input → the honest not-a-JSON error.
    let message = call_err(b"", clearfile_load_and_compute);
    assert!(!message.is_empty());
    // A truncated ZIP (the malformed-ZIP crash battery's class): the
    // analysis path never panics, never NULLs — the honest analysis.
    let truncated = b"PK\x03\x04garbage-garbage";
    let analysis = call_bytes_ok(truncated, clearfile_inspect_tax);
    let parsed = Json::parse(&analysis).unwrap();
    let pairs = parsed.as_obj().unwrap();
    assert!(
        pairs.iter().any(|(k, v)| k == "isZip" && *v == Json::Bool(true)),
        "the truncated ZIP is still a ZIP-family analysis"
    );
    // The envelope decoder's own path (not via the composed one).
    let message = call_err(b"not json at all", clearfile_decode_envelope);
    assert_eq!(message, "The file is not valid JSON.");
    // inspect_tax NEVER fails on bytes (the core's contract) — even on
    // hostile garbage.
    for payload in [&b""[..], &[0u8, 1, 2], b"PK\x05\x06"] {
        let analysis = call_bytes_ok(payload, clearfile_inspect_tax);
        Json::parse(&analysis).expect("the analysis output is always JSON");
    }
}

// ---------------------------------------------------------------------------
// (d) Both cap batteries THROUGH the boundary (SEC-4)
// ---------------------------------------------------------------------------

#[test]
fn member_cap_through_the_boundary() {
    // The 10,001-member object (the fail-closed member cap): the named
    // error, verbatim from the core.
    let mut wide = String::from("{");
    for i in 0..=10_000usize {
        if i > 0 {
            wide.push(',');
        }
        wide.push_str(&format!("\"k{i}\":0"));
    }
    wide.push('}');
    // The envelope path collapses parse errors to its own message
    // (the app-parity surface), so the named cap error surfaces
    // through the raw compute path.
    let _ = call_err(wide.as_bytes(), clearfile_decode_envelope);
    let message = call_err(wide.as_bytes(), clearfile_compute);
    assert!(
        message.contains("exceeds the 10,000-member parser limit"),
        "the member cap must surface: {message}"
    );
}

#[test]
fn store_cap_through_the_boundary() {
    // The 256 MiB cumulative STORE-extraction cap: 257 STORE entries of
    // 1 MiB (one SHARED buffer — the core battery's documented
    // discipline; the container is ~257 MiB in memory, the known cost
    // of this battery, ~seconds).
    let shared = vec![b'A'; 1024 * 1024];
    let names: Vec<String> = (0..257).map(|i| format!("e{i}.bin")).collect();
    let entries: Vec<(&str, &[u8])> = names.iter().map(|n| (n.as_str(), shared.as_slice())).collect();
    let container = make_zip(&entries).expect("the crafted container must build");
    let analysis = call_bytes_ok(&container, clearfile_inspect_tax);
    let parsed = Json::parse(&analysis).unwrap();
    let pairs = parsed.as_obj().unwrap();
    let warnings = match pairs.iter().find(|(k, _)| k == "warnings") {
        Some((_, Json::Arr(items))) => items.clone(),
        other => panic!("the analysis carries warnings: {other:?}"),
    };
    let stop_note = warnings.iter().any(|w| matches!(w, Json::Str(s) if s.contains("Extraction stopped after 268435456 bytes")));
    assert!(
        stop_note,
        "the STORE cap must surface its stop-note in the warnings: {warnings:?}"
    );
}

// ---------------------------------------------------------------------------
// (e) The input-size bound THROUGH the boundary (SEC-6)
// ---------------------------------------------------------------------------

#[test]
fn input_size_bound_through_the_boundary() {
    // The exact-boundary pair via the pure decision fn is pinned in the
    // core + the app; THIS battery pins the boundary's own enforcement:
    // a real 512 MiB + 1 byte payload refused by name before any parse
    // (the documented cost: one transient zeroed allocation).
    let too_large = vec![b' '; 512 * 1024 * 1024 + 1];
    let message = call_err(&too_large, clearfile_compute);
    assert_eq!(message, INPUT_TOO_LARGE_MESSAGE);
    // Just under the bound is NOT refused here (the parse's own caps
    // and named errors govern): a 512 MiB payload of spaces hits the
    // parser's own named error, never the size error.
    let under = vec![b' '; 512 * 1024 * 1024];
    let message = call_err(&under, clearfile_compute);
    assert_eq!(message, "unexpected end of JSON input");
    assert_ne!(message, INPUT_TOO_LARGE_MESSAGE);
}

// ---------------------------------------------------------------------------
// (f) The panic-injection proof (SEC-1)
// ---------------------------------------------------------------------------

#[cfg(feature = "panic-hook-test")]
#[test]
fn panic_injection_maps_to_the_sentinel_and_named_message() {
    let owned = clearfile_core_ffi::clearfile_test_guard_panic();
    assert!(owned.is_null(), "the guard maps a panic to the sentinel");
    let message = last_error_text();
    assert!(
        message.contains("failed unexpectedly"),
        "the guard's named panic message must surface: {message}"
    );
}

// ---------------------------------------------------------------------------
// (g) The palette marshaling THROUGH the boundary
// ---------------------------------------------------------------------------

#[test]
fn palette_roles_through_the_boundary() {
    // The app's seed (the corpus's recorded app seed) × all 34 roles ×
    // light + dark — parity with the direct core calls.
    const SEED: u32 = 0xFF_00_69_6E;
    for role in PaletteRole::ALL {
        let name = CString::new(role.name()).unwrap();
        for dark in [false, true] {
            let through = clearfile_palette_scheme_role(
                SEED,
                dark,
                name.as_ptr(),
                role.name().len(),
            );
            assert_eq!(through, scheme_role(SEED, dark, role), "role {}", role.name());
            assert_ne!(through, 0, "scheme colors are always opaque");
        }
    }
    // The error path: an unknown role name → the 0-sentinel + the named
    // error (and the success-clear contract holds after a good call).
    let bogus = CString::new("notARole").unwrap();
    let through = clearfile_palette_scheme_role(SEED, false, bogus.as_ptr(), bogus.to_bytes().len());
    assert_eq!(through, 0);
    assert!(
        last_error_text().contains("Unknown color role"),
        "the unknown-role error must surface: {}",
        last_error_text()
    );
}

// ---------------------------------------------------------------------------
// (h) The envelope + container round-trips THROUGH the boundary (the
// composed pipeline's parity with the Linux app's load_and_compute)
// ---------------------------------------------------------------------------

#[test]
fn envelope_and_container_round_trips_through_the_boundary() {
    // The shared v1→v2 migration fixture (the same one the app's tests
    // + the CI headless smoke consume).
    let v1 = std::fs::read_to_string("../fixtures/migration/v1-web-envelope.json").unwrap();
    let decoded = call_ok(&v1, clearfile_decode_envelope);
    let parsed = Json::parse(&decoded).unwrap();
    let pairs = parsed.as_obj().unwrap();
    let warnings = match pairs.iter().find(|(k, _)| k == "warnings").unwrap().1 {
        Json::Arr(ref items) => items.clone(),
        _ => panic!("warnings must be an array"),
    };
    assert_eq!(warnings.len(), 4, "the four exact migration warnings");
    assert!(
        warnings.iter().any(|w| matches!(w, Json::Str(s) if s.contains("Dependent counts were migrated"))),
        "the migration warning text must be verbatim-in-substance"
    );

    // The composed pipeline on the same fixture: the envelope path.
    let loaded = call_bytes_ok(v1.as_bytes(), clearfile_load_and_compute);
    let parsed = Json::parse(&loaded).unwrap();
    let pairs = parsed.as_obj().unwrap();
    assert!(
        pairs.iter().any(|(k, v)| k == "source" && matches!(v, Json::Str(s) if s.contains("envelope"))),
        "the composed pipeline names the envelope source"
    );
    // The result through the boundary equals the direct core call,
    // field by field (the one-engine parity: compute via the boundary,
    // compare against the core's own output for the same filing).
    let filing = match pairs.iter().find(|(k, _)| k == "filing").unwrap().1 {
        Json::Obj(ref pairs) => pairs.clone(),
        _ => panic!("filing must be an object"),
    };
    let direct = compute_ty2025(&TaxReturnData::from_json_map(&Json::Obj(filing)).input);
    let through = match pairs.iter().find(|(k, _)| k == "result").unwrap().1 {
        Json::Obj(ref pairs) => pairs.clone(),
        _ => panic!("result must be an object"),
    };
    for (key, value) in &through {
        if key == "deductionMethodUsed" {
            assert!(
                matches!(value, Json::Str(s) if *s == direct.deduction_method_used.name()),
                "deductionMethodUsed must match the engine's own name: {value:?}"
            );
            continue;
        }
        let pinned = direct_field(&direct, key).expect("a TaxResult field");
        match value {
            Json::Num(c) => assert!((c - pinned).abs() <= 0.0, "{key}: {c} vs {pinned}"),
            other => panic!("{key}: {other:?}"),
        }
    }

    // The container round-trip: encode the migrated filing through the
    // boundary, wrap it in the exchange container, load it back through
    // the composed pipeline — warning-free (the idempotence property:
    // a re-encoded v2 model imports warning-free).
    let decoded2 = call_ok(&v1, clearfile_decode_envelope);
    let parsed2 = Json::parse(&decoded2).unwrap();
    let pairs2 = parsed2.as_obj().unwrap();
    let filing2 = match pairs2.iter().find(|(k, _)| k == "filing").unwrap().1 {
        Json::Obj(ref pairs) => pairs.clone(),
        _ => panic!("filing must be an object"),
    };
    let filing_text = Json::Obj(filing2).write().unwrap();
    let envelope = call_two_payloads(filing_text.as_bytes(), "2026-11-27T00:00:00Z", clearfile_encode_envelope);
    let container = export_tax_container(&envelope).expect("the container must build");
    let loaded = call_bytes_ok(&container, clearfile_load_and_compute);
    let parsed = Json::parse(&loaded).unwrap();
    let pairs = parsed.as_obj().unwrap();
    assert!(
        pairs.iter().any(|(k, v)| k == "source" && matches!(v, Json::Str(s) if s.contains("container"))),
        "the composed pipeline names the container source"
    );
    assert!(
        pairs.iter().any(|(k, v)| k == "warnings" && matches!(v, Json::Arr(w) if w.is_empty())),
        "the re-encoded v2 model imports warning-free"
    );
}

/// The direct-call field accessor (the comparator's key set).
fn direct_field(result: &clearfile_core::TaxResult, key: &str) -> Option<f64> {
    Some(match key {
        "totalIncome" => result.total_income,
        "studentLoanDeduction" => result.student_loan_deduction,
        "agi" => result.agi,
        "basicStandardDeduction" => result.basic_standard_deduction,
        "additionalStandardDeduction" => result.additional_standard_deduction,
        "seniorDeduction" => result.senior_deduction,
        "standardDeductionTotal" => result.standard_deduction_total,
        "saltPaid" => result.salt_paid,
        "saltCap" => result.salt_cap,
        "saltAllowed" => result.salt_allowed,
        "itemizedDeductionTotal" => result.itemized_deduction_total,
        "deductionUsed" => result.deduction_used,
        "taxableIncome" => result.taxable_income,
        "ordinaryTax" => result.ordinary_tax,
        "preferentialIncome" => result.preferential_income,
        "preferentialTax" => result.preferential_tax,
        "niit" => result.niit,
        "nonRefundableCredits" => result.non_refundable_credits,
        "refundableCredits" => result.refundable_credits,
        "totalTax" => result.total_tax,
        "totalPayments" => result.total_payments,
        "refund" => result.refund,
        "amountOwed" => result.amount_owed,
        "effectiveRate" => result.effective_rate,
        "marginalRate" => result.marginal_rate,
        "qualifyingChildren" => result.qualifying_children as f64,
        _ => return None,
    })
}

/// A two-payload call (encode's filing + savedAt) through the boundary.
fn call_two_payloads(
    a: &[u8],
    b: &str,
    f: extern "C" fn(*const std::ffi::c_char, usize, *const std::ffi::c_char, usize) -> *mut std::ffi::c_char,
) -> String {
    let owned = f(
        a.as_ptr() as *const _,
        a.len(),
        b.as_ptr() as *const _,
        b.len(),
    );
    assert!(!owned.is_null(), "encode must succeed: {}", last_error_text());
    let text = unsafe { CStr::from_ptr(owned) }.to_string_lossy().into_owned();
    clearfile_free(owned);
    text
}

// ---------------------------------------------------------------------------
// (i) TXF through the boundary + the free/last-error contracts
// ---------------------------------------------------------------------------

#[test]
fn txf_import_through_the_boundary_and_the_contracts() {
    // A minimal honest TXF file (the Dart canonical v042 shape: the
    // header + one W-2 — payer N466, wages N460, withholding N461, the
    // spec's negative-money-paid sign).
    let txf = [
        "V042",
        "AQuicken 2011 for Windows R1",
        "D 03/16/2026",
        "^",
        "TS", "N466", "C1", "PAcme Corp", "^",
        "TS", "N460", "C1", "$ 52500.00", "^",
        "TS", "N461", "C1", "$ -6200.00", "^",
    ].join("\n");
    let imported = call_ok(&txf, clearfile_import_txf);
    let parsed = Json::parse(&imported).unwrap();
    let pairs = parsed.as_obj().unwrap();
    assert!(
        pairs.iter().any(|(k, v)| k == "displayName" && matches!(v, Json::Str(s) if s.contains("TXF"))),
        "the display name is the importer's own: {imported}"
    );
    assert!(
        pairs.iter().any(|(k, v)| k == "input" && matches!(v, Json::Obj(_))),
        "the imported input is the filing shape"
    );

    // clearfile_free(NULL) is a documented no-op (never a crash).
    clearfile_free(std::ptr::null_mut());

    // The last-error contract: "" after a success (the guard clears),
    // set after a failure, "" again after the next success.
    let _ = call_ok("{\"taxYear\":2025}", clearfile_compute);
    assert_eq!(last_error_text(), "");
    let _ = call_err(b"not json", clearfile_compute);
    assert!(!last_error_text().is_empty());
    let _ = call_ok("{\"taxYear\":2025}", clearfile_compute);
    assert_eq!(last_error_text(), "");
}
