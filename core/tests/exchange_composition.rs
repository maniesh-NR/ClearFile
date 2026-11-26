// SPDX-License-Identifier: GPL-3.0-only
//! The exchange-container COMPOSITION tests (N1 session 2 integration):
//! `import_tax_container` — the payload-seam composition of
//! [`crate::tax_inspect::analyze_tax_file`] + [`crate::envelope`]
//! (ADR-017's recorded FFI design: "the envelope as payload boundary").
//! These pin the composed behaviors the references performed inline
//! (tax_inspect.dart:139-163): the full import with merged warnings, the
//! decode-failure fall-through with its verbatim warning and re-derived
//! summary, and the writer↔importer round-trip through the composition.

use clearfile_core::envelope::{ReturnFileCodec, TaxReturnData};
use clearfile_core::tax_inspect::{
    analyze_tax_file, export_tax_container, import_tax_container, ContainerImport,
};
use clearfile_core::{DeductionMethod, Dependent, FilingStatus, TaxReturnInput, W2Entry};
use std::path::PathBuf;

fn sample_filing(display_name: &str) -> TaxReturnData {
    TaxReturnData {
        id: "comp-001".to_owned(),
        display_name: display_name.to_owned(),
        created: "2026-11-26T10:00:00.000Z".to_owned(),
        modified: "2026-11-26T11:30:00.000Z".to_owned(),
        input: TaxReturnInput {
            tax_year: 2025,
            filing_status: FilingStatus::MarriedJoint,
            taxpayer_65_or_older: false,
            spouse_65_or_older: false,
            taxpayer_blind: false,
            spouse_blind: false,
            w2s: vec![W2Entry {
                employer: "Acme Corp".to_owned(),
                wages: 52500.5,
                withholding: 6200.0,
            }],
            interest_income: 120.25,
            ordinary_dividends: 0.0,
            qualified_dividends: 400.0,
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

const SAVED_AT: &str = "2026-11-26T12:00:00.000Z";

#[test]
fn composition_imports_a_written_container_losslessly() {
    let filing = sample_filing("Composition round-trip");
    let envelope = ReturnFileCodec::encode(&filing, SAVED_AT).unwrap();
    let bytes = export_tax_container(&envelope).unwrap();

    // The analysis alone: the payload seam carries the envelope text.
    let a = analyze_tax_file(&bytes);
    assert!(a.is_zip);
    assert!(a.clearfile_container);
    assert_eq!(a.clearfile_payload.as_deref(), Some(envelope.as_str()));

    // The composition: full import, the filing equal in every field.
    match import_tax_container(&bytes) {
        Some(ContainerImport::Imported(imp)) => {
            assert_eq!(imp.filing, filing);
            // The reference's merged-warning order: ZIP notes, then the
            // envelope's migration warnings — none here (a v2 envelope).
            assert!(imp.warnings.is_empty());
            assert_eq!(imp.entries.len(), 2);
            assert!(imp.summary.starts_with("This is a ClearFile exchange container"));
        }
        other => panic!("expected Imported, got {other:?}"),
    }
}

#[test]
fn composition_surfaces_v1_migration_warnings_after_zip_notes() {
    // The SHARED v1 migration fixture as the container payload — the same
    // sample the Dart/TS suites assert the exact warning list from.
    let v1 = std::fs::read_to_string(
        PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("..")
            .join("fixtures")
            .join("migration")
            .join("v1-web-envelope.json"),
    )
    .expect("the shared v1 fixture is tracked");
    let bytes = export_tax_container(&v1).unwrap();
    match import_tax_container(&bytes) {
        Some(ContainerImport::Imported(imp)) => {
            assert_eq!(
                imp.warnings,
                vec![
                    "Saved with an older prototype: the return was migrated to the current engine model.".to_owned(),
                    "\"Adjustments to income\" had no equivalent in the current model and was dropped — re-enter it as student loan interest if that is what it was.".to_owned(),
                    "Medical and \"other\" itemized expenses have no equivalent in the current model and were dropped.".to_owned(),
                    "Dependent counts were migrated; re-enter their names in the Dependents step.".to_owned(),
                ],
                "the exact ordered v1 warning list, merged after the ZIP notes"
            );
            assert_eq!(imp.filing.input.filing_status, FilingStatus::MarriedJoint);
            assert_eq!(imp.filing.input.interest_income, 500.0);
            assert_eq!(imp.filing.input.dependents.len(), 3);
        }
        other => panic!("expected Imported, got {other:?}"),
    }
}

#[test]
fn composition_falls_through_when_the_payload_is_not_an_envelope() {
    let bytes = export_tax_container("not json at all").unwrap();
    match import_tax_container(&bytes) {
        Some(ContainerImport::FellThrough(a)) => {
            assert!(!a.clearfile_container);
            assert!(a.clearfile_payload.is_none());
            assert!(
                a.warnings.iter().any(|w| w
                    == "clearfile.json could not be parsed: The file is not valid JSON."),
                "the reference's fall-through warning, verbatim: {:?}",
                a.warnings
            );
            // The plain-ZIP summary is re-derived on fall-through.
            assert!(a.summary.starts_with("ZIP container detected"));
        }
        other => panic!("expected FellThrough, got {other:?}"),
    }
}

#[test]
fn composition_fall_through_still_detects_the_intuit_shape() {
    // A container with BOTH an undecodable clearfile.json and the modern
    // Intuit shape: the reference's fall-through continues to the Intuit
    // detection — the composed summary must reflect it.
    use clearfile_core::tax_inspect::make_zip;
    // Valid UTF-8, but NOT a decodable envelope — so the composition's
    // decode-failure fall-through runs (invalid UTF-8 is handled inside
    // analyze and never reaches it).
    let payload: &[u8] = b"an encrypted-looking textual placeholder payload";
    let entries: [(&str, &[u8]); 3] = [
        ("clearfile.json", payload),
        ("manifest.xml", b"<manifest/>"),
        ("tax:7a1c2d3e-4f5a-6789-abcd-ef0123456789", b"encrypted-looking payload bytes"),
    ];
    let bytes = make_zip(&entries).unwrap();
    match import_tax_container(&bytes) {
        Some(ContainerImport::FellThrough(a)) => {
            assert!(a.intuit_modern_container);
            assert!(a.summary.contains("modern TurboTax .tax container shape"));
            assert!(a.warnings.iter().any(|w| w.starts_with("clearfile.json could not be parsed:")));
        }
        other => panic!("expected FellThrough, got {other:?}"),
    }
}

#[test]
fn composition_returns_none_for_non_clearfile_containers() {
    use clearfile_core::tax_inspect::make_zip;
    let entries: [(&str, &[u8]); 1] = [("notes.txt", b"hello hello hello")];
    let bytes = make_zip(&entries).unwrap();
    assert!(import_tax_container(&bytes).is_none());
    // Non-ZIP bytes: also None (the analysis is the honest surface).
    assert!(import_tax_container(b"just some text").is_none());
    assert!(import_tax_container(b"").is_none());
}

#[test]
fn composition_round_trips_through_encode_export_import_compute() {
    // The full pipeline the ADR-017 FFI surface names: model → envelope →
    // container → analyze/import → compute — the imported filing must
    // compute bitwise-identically to the source filing.
    let filing = sample_filing("Full pipeline");
    let expected = clearfile_core::compute_ty2025(&filing.input);
    let bytes = export_tax_container(&ReturnFileCodec::encode(&filing, SAVED_AT).unwrap()).unwrap();
    match import_tax_container(&bytes) {
        Some(ContainerImport::Imported(imp)) => {
            let got = clearfile_core::compute_ty2025(&imp.filing.input);
            assert_eq!(got, expected);
        }
        other => panic!("expected Imported, got {other:?}"),
    }
}
