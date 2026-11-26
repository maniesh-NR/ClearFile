// SPDX-License-Identifier: GPL-3.0-only
//! The ClearFile Linux native window (N2 session 2, the ADR-017 epilogue:
//! Slint over `clearfile-core`, Linux linking the crate DIRECTLY, no FFI).
//!
//! The app's shape per the N2 gate record (ENG-6, the no-drift rule): ONE
//! shared pipeline fn — [`load_and_compute`] — is the ONLY path from a file
//! to a computed return; the window, the `--headless <path>` mode, and the
//! tests all call it, never a re-implementation. The mode decision is
//! content-first (a ZIP-family signature is a `.tax` ClearFile exchange
//! container; anything else is decoded as the `.clearfile.json` envelope
//! via the core's `ReturnFileCodec` — the extension is reported, never
//! trusted). The text summary the `--headless` mode prints and the rows
//! the window renders come from the SAME row builders ([`result_groups`]).
//! The theme is MD3-from-seed (D44): the Theme global's role colors are
//! computed here from `palette::scheme_role` (seed 0xFF00696E, light
//! default, the dark toggle re-applies the same seed with `dark: true`).
//!
//! argv: `--headless <path>` prints the grouped summary + warnings to
//! stdout and exits; `--smoke` constructs the real window, renders it
//! under the event loop for ~300 ms, prints `window-smoke-ok`, exits 0;
//! a bare path opens the window with that file loaded (or the honest
//! error pane); no argument opens the honest no-file state.

slint::include_modules!();

use clearfile_core::envelope::{ReturnFileCodec, TaxReturnData};
use clearfile_core::palette::{scheme_role, PaletteRole};
use clearfile_core::tax_inspect::{analyze_tax_file, import_tax_container, ContainerImport};
use clearfile_core::{compute_ty2025, DeductionMethod, FilingStatus, TaxResult};
use slint::{ComponentHandle, ModelRc, SharedString, VecModel};

/// The app's MD3 seed (the corpus's recorded app seed, fixtures/palette).
const THEME_SEED: u32 = 0xFF_00_69_6E;

/// One loaded-and-computed return: everything both the window and the
/// headless mode render (the ONE pipeline fn's output).
#[derive(Debug)]
pub struct LoadedReturn {
    pub path: String,
    /// Honest provenance line, e.g. "the .clearfile.json envelope" or
    /// "the ClearFile exchange container (.tax)".
    pub source: String,
    pub filing: TaxReturnData,
    pub result: TaxResult,
    pub warnings: Vec<String>,
}

/// The ONE shared pipeline: read the file, route it (container vs
/// envelope, content-first), decode it via the core's codecs, compute
/// TY2025 via the core's engine (the same engine the 17 shared golden
/// fixtures pin). Every failure is a named, user-readable message in the
/// core's wording family ("The file ... .") — surfaced verbatim in the
/// window's error pane and on stderr in headless mode.
pub fn load_and_compute(path: &str) -> Result<LoadedReturn, String> {
    let bytes = std::fs::read(path)
        .map_err(|e| format!("The file could not be read: {e}."))?;
    if looks_like_zip(&bytes) {
        import_container(path, &bytes)
    } else {
        import_envelope(path, &bytes)
    }
}

/// ZIP-family signatures (mirroring the core's `_looksZip`,
/// tax_inspect.dart:220-224): local header, end-of-central-directory,
/// spanning marker. A `.clearfile.json` envelope can never begin with
/// these; a container always does — the extension never overrides this.
fn looks_like_zip(bytes: &[u8]) -> bool {
    for sig in [&b"PK\x03\x04"[..], &b"PK\x05\x06"[..], &b"PK\x07\x08"[..]] {
        if bytes.starts_with(sig) {
            return true;
        }
    }
    false
}

fn import_container(path: &str, bytes: &[u8]) -> Result<LoadedReturn, String> {
    match import_tax_container(bytes) {
        Some(ContainerImport::Imported(imported)) => finish_loaded(
            path,
            imported.filing,
            imported.warnings,
            "the ClearFile exchange container (.tax)",
        ),
        // The container was ZIP-family but not a ClearFile container: the
        // core's analysis (its summary + warnings) IS the honest error.
        Some(ContainerImport::FellThrough(analysis)) => Err(container_error(&analysis.summary, &analysis.warnings)),
        None => {
            let analysis = analyze_tax_file(bytes);
            Err(container_error(&analysis.summary, &analysis.warnings))
        }
    }
}

fn container_error(summary: &str, warnings: &[String]) -> String {
    let mut message = format!(
        "The .tax file could not be imported as a ClearFile container. {summary}"
    );
    for warning in warnings {
        message.push_str("\n  - ");
        message.push_str(warning);
    }
    message
}

fn import_envelope(path: &str, bytes: &[u8]) -> Result<LoadedReturn, String> {
    let text = std::str::from_utf8(bytes).map_err(|_| {
        "The file is not valid UTF-8 text; a ClearFile return file must be UTF-8.".to_string()
    })?;
    let decoded = ReturnFileCodec::decode(text).map_err(|e| e.message)?;
    finish_loaded(path, decoded.filing, decoded.warnings, "the .clearfile.json envelope")
}

fn finish_loaded(
    path: &str,
    filing: TaxReturnData,
    warnings: Vec<String>,
    source: &str,
) -> Result<LoadedReturn, String> {
    let result = compute_ty2025(&filing.input);
    Ok(LoadedReturn {
        path: path.to_string(),
        source: source.to_string(),
        filing,
        result,
        warnings,
    })
}

// --- formatting (display-only; the engine's semantics are f64-exact) ---

fn fmt_money(value: f64) -> String {
    let value = if value == 0.0 { 0.0 } else { value }; // normalize -0.0
    let negative = value < 0.0;
    let cents = format!("{:.2}", value.abs());
    let (int_part, frac) = match cents.split_once('.') {
        Some(parts) => parts,
        None => (cents.as_str(), "00"),
    };
    let mut grouped = String::new();
    let digits = int_part.len();
    for (index, ch) in int_part.chars().enumerate() {
        if index > 0 && (digits - index) % 3 == 0 {
            grouped.push(',');
        }
        grouped.push(ch);
    }
    if negative {
        format!("-${grouped}.{frac}")
    } else {
        format!("${grouped}.{frac}")
    }
}

fn fmt_rate(value: f64) -> String {
    format!("{value:.1}%")
}

fn status_label(status: FilingStatus) -> &'static str {
    match status {
        FilingStatus::Single => "Single",
        FilingStatus::MarriedJoint => "Married filing jointly",
        FilingStatus::MarriedSeparate => "Married filing separately",
        FilingStatus::HeadOfHousehold => "Head of household",
        FilingStatus::SurvivingSpouse => "Qualifying surviving spouse",
    }
}

fn method_label(method: DeductionMethod) -> &'static str {
    match method {
        DeductionMethod::Standard => "Standard deduction",
        DeductionMethod::Itemized => "Itemized deductions",
        // compute() resolves Auto before it returns; kept for completeness.
        DeductionMethod::Auto => "Automatic (standard vs itemized)",
    }
}

fn row(label: &str, value: String) -> ResultRow {
    ResultRow {
        label: SharedString::from(label),
        value: SharedString::from(value),
    }
}

/// The results groups — the ONE row source both the window (its five
/// model properties) and [`text_summary`] (the headless print) consume,
/// in the gate's order: income → deduction → tax → credits → refund/owed.
pub fn result_groups(result: &TaxResult) -> [Vec<ResultRow>; 5] {
    [
        vec![
            row("Total income", fmt_money(result.total_income)),
            row(
                "Student loan interest deduction",
                fmt_money(result.student_loan_deduction),
            ),
            row("Adjusted gross income", fmt_money(result.agi)),
        ],
        vec![
            row(
                "Basic standard deduction",
                fmt_money(result.basic_standard_deduction),
            ),
            row(
                "Additional standard deduction",
                fmt_money(result.additional_standard_deduction),
            ),
            row("Senior deduction", fmt_money(result.senior_deduction)),
            row(
                "Standard deduction total",
                fmt_money(result.standard_deduction_total),
            ),
            row("SALT paid", fmt_money(result.salt_paid)),
            row("SALT cap", fmt_money(result.salt_cap)),
            row("SALT allowed", fmt_money(result.salt_allowed)),
            row(
                "Itemized deductions total",
                fmt_money(result.itemized_deduction_total),
            ),
            row(
                "Method used",
                method_label(result.deduction_method_used).to_string(),
            ),
            row("Deduction used", fmt_money(result.deduction_used)),
            row("Taxable income", fmt_money(result.taxable_income)),
        ],
        vec![
            row("Ordinary tax", fmt_money(result.ordinary_tax)),
            row("Preferential income", fmt_money(result.preferential_income)),
            row("Preferential tax", fmt_money(result.preferential_tax)),
            row("NIIT", fmt_money(result.niit)),
        ],
        vec![
            row(
                "Qualifying children",
                result.qualifying_children.to_string(),
            ),
            row(
                "Non-refundable credits",
                fmt_money(result.non_refundable_credits),
            ),
            row(
                "Refundable credits",
                fmt_money(result.refundable_credits),
            ),
            row(
                "Total tax (after non-refundable credits)",
                fmt_money(result.total_tax),
            ),
        ],
        vec![
            row("Total payments", fmt_money(result.total_payments)),
            row("Refund", fmt_money(result.refund)),
            row("Amount owed", fmt_money(result.amount_owed)),
            row("Effective tax rate", fmt_rate(result.effective_rate)),
            row("Marginal tax rate", fmt_rate(result.marginal_rate)),
        ],
    ]
}

/// The text summary — the byte-exact stdout of `--headless <path>` (the
/// committed `tests/expected-headless.txt` pins it in CI) and the same
/// groups + warnings the window shows.
pub fn text_summary(loaded: &LoadedReturn) -> String {
    let mut out = String::new();
    out.push_str("ClearFile — TY2025 federal summary (demonstration prototype)\n");
    out.push_str(&format!("File: {}\n", loaded.path));
    out.push_str(&format!(
        "Return: {} ({}, TY{})\n",
        loaded.filing.display_name,
        status_label(loaded.filing.input.filing_status),
        loaded.filing.input.tax_year
    ));
    out.push_str(&format!("Imported from {}.\n", loaded.source));
    let groups = [
        ("Income", 0),
        ("Deduction", 1),
        ("Tax", 2),
        ("Credits", 3),
        ("Refund / amount owed", 4),
    ];
    for (title, index) in groups {
        out.push_str(&format!("{title}\n"));
        for r in &result_groups(&loaded.result)[index] {
            out.push_str(&format!("  {}: {}\n", r.label, r.value));
        }
    }
    if loaded.warnings.is_empty() {
        out.push_str("Import warnings: none.\n");
    } else {
        out.push_str(&format!("Import warnings ({})\n", loaded.warnings.len()));
        for warning in &loaded.warnings {
            out.push_str(&format!("  - {warning}\n"));
        }
    }
    out.push_str(
        "Demonstration prototype — not tax advice; check with a qualified tax professional.\n",
    );
    out
}

// --- the theme (MD3-from-seed via the core's palette module, D44) ---

fn color_of(dark: bool, role: PaletteRole) -> slint::Color {
    slint::Color::from_argb_encoded(scheme_role(THEME_SEED, dark, role))
}

fn apply_theme(ui: &MainWindow, dark: bool) {
    let theme = ui.global::<Theme>();
    theme.set_primary(color_of(dark, PaletteRole::Primary));
    theme.set_on_primary(color_of(dark, PaletteRole::OnPrimary));
    theme.set_primary_container(color_of(dark, PaletteRole::PrimaryContainer));
    theme.set_on_primary_container(color_of(dark, PaletteRole::OnPrimaryContainer));
    theme.set_secondary_container(color_of(dark, PaletteRole::SecondaryContainer));
    theme.set_on_secondary_container(color_of(dark, PaletteRole::OnSecondaryContainer));
    theme.set_surface(color_of(dark, PaletteRole::Surface));
    theme.set_on_surface(color_of(dark, PaletteRole::OnSurface));
    theme.set_on_surface_variant(color_of(dark, PaletteRole::OnSurfaceVariant));
    theme.set_surface_container_low(color_of(dark, PaletteRole::SurfaceContainerLow));
    theme.set_surface_container_highest(color_of(dark, PaletteRole::SurfaceContainerHighest));
    theme.set_outline_variant(color_of(dark, PaletteRole::OutlineVariant));
    theme.set_error(color_of(dark, PaletteRole::Error));
    theme.set_on_error(color_of(dark, PaletteRole::OnError));
    theme.set_error_container(color_of(dark, PaletteRole::ErrorContainer));
    theme.set_on_error_container(color_of(dark, PaletteRole::OnErrorContainer));
}

fn string_model(strings: &[String]) -> ModelRc<SharedString> {
    ModelRc::new(VecModel::from(
        strings
            .iter()
            .map(|s| SharedString::from(s.as_str()))
            .collect::<Vec<_>>(),
    ))
}

fn row_model(rows: Vec<ResultRow>) -> ModelRc<ResultRow> {
    ModelRc::new(VecModel::from(rows))
}

/// Show a computed return: the import status area + the five groups.
fn show_loaded(ui: &MainWindow, loaded: &LoadedReturn) {
    ui.set_has_file(true);
    ui.set_has_error(false);
    ui.set_file_path(SharedString::from(loaded.path.as_str()));
    ui.set_return_name(SharedString::from(loaded.filing.display_name.as_str()));
    ui.set_import_note(SharedString::from(format!(
        "Imported from {} — {}.",
        loaded.source,
        status_label(loaded.filing.input.filing_status)
    )));
    ui.set_warnings(string_model(&loaded.warnings));
    let [income, deduction, tax, credits, refund] = result_groups(&loaded.result);
    ui.set_income_rows(row_model(income));
    ui.set_deduction_rows(row_model(deduction));
    ui.set_tax_rows(row_model(tax));
    ui.set_credit_rows(row_model(credits));
    ui.set_refund_rows(row_model(refund));
    ui.set_refund_positive(loaded.result.refund > 0.0);
    ui.set_owed_positive(loaded.result.amount_owed > 0.0);
}

fn show_error(ui: &MainWindow, path: &str, message: &str) {
    ui.set_has_file(true);
    ui.set_has_error(true);
    ui.set_file_path(SharedString::from(path));
    ui.set_error_text(SharedString::from(message));
}

fn show_no_file(ui: &MainWindow) {
    ui.set_has_file(false);
    ui.set_has_error(false);
}

fn run_window(path: Option<&str>) {
    let ui = MainWindow::new().expect("the ClearFile window could not be created");
    let dark = std::cell::Cell::new(false);
    apply_theme(&ui, dark.get());
    {
        let weak = ui.as_weak();
        ui.on_toggle_theme(move || {
            let Some(ui) = weak.upgrade() else { return };
            dark.set(!dark.get());
            apply_theme(&ui, dark.get());
        });
    }
    match path {
        Some(path) => match load_and_compute(path) {
            Ok(loaded) => show_loaded(&ui, &loaded),
            Err(message) => show_error(&ui, path, &message),
        },
        None => show_no_file(&ui),
    }
    if let Err(error) = ui.run() {
        eprintln!("clearfile-linux: the window event loop failed: {error}");
        std::process::exit(1);
    }
}

/// The bounded window smoke: construct the real component, render it
/// under the event loop for ~300 ms, quit, print the marker.
fn run_smoke() {
    let ui = MainWindow::new().expect("the ClearFile window could not be created");
    apply_theme(&ui, false);
    show_no_file(&ui);
    ui.show().expect("the smoke window could not be shown");
    // Bound the loop: quit after one frame's worth of settle time. The
    // Timer must stay alive across run_event_loop (dropping stops it).
    let quit_timer = slint::Timer::default();
    quit_timer.start(
        slint::TimerMode::SingleShot,
        std::time::Duration::from_millis(300),
        || {
            // The result is () here in effect: quitting an unstarted loop
            // is fine inside the callback it fired from.
            let _ = slint::quit_event_loop();
        },
    );
    slint::run_event_loop().expect("the smoke event loop failed");
    drop(quit_timer);
    println!("window-smoke-ok");
}

fn run_headless(path: &str) {
    match load_and_compute(path) {
        Ok(loaded) => {
            print!("{}", text_summary(&loaded));
        }
        Err(message) => {
            eprintln!("clearfile-linux: {message}");
            std::process::exit(1);
        }
    }
}

fn usage_error(message: &str) -> ! {
    eprintln!("clearfile-linux: {message}");
    eprintln!("Usage: clearfile-linux [--headless <path> | --smoke | <return-file>]");
    std::process::exit(2);
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    match args.as_slice() {
        [] => run_window(None),
        [flag] if flag == "--smoke" => run_smoke(),
        [flag] if flag == "--headless" => {
            usage_error("--headless needs a return file path after it.")
        }
        [flag, path] if flag == "--headless" => run_headless(path),
        [path] => run_window(Some(path)),
        _ => usage_error("unexpected arguments."),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use clearfile_core::tax_inspect::export_tax_container;

    /// The shared v1→v2 migration fixture (also the CI headless smoke's
    /// input); the path below is relative to apps/linux — in CI the same
    /// fixture is passed repo-root-relative, which is why the byte-test
    /// normalizes exactly that line (see `headless_text_bytes`).
    const FIXTURE: &str = "../../fixtures/migration/v1-web-envelope.json";

    fn loaded_fixture() -> LoadedReturn {
        load_and_compute(FIXTURE).expect("the shared migration fixture must load")
    }

    #[test]
    fn money_formatting() {
        assert_eq!(fmt_money(0.0), "$0.00");
        assert_eq!(fmt_money(-0.0), "$0.00");
        assert_eq!(fmt_money(90800.0), "$90,800.00");
        assert_eq!(fmt_money(1739.0), "$1,739.00");
        assert_eq!(fmt_money(1234567.89), "$1,234,567.89");
        assert_eq!(fmt_money(-1234.5), "-$1,234.50");
    }

    #[test]
    fn envelope_pipeline_on_the_migration_fixture() {
        let loaded = loaded_fixture();
        assert_eq!(loaded.source, "the .clearfile.json envelope");
        // The migrated shape (the v1 lift the core's codec owns): the
        // field mapping is the core's contract; this pins the wiring.
        assert_eq!(loaded.filing.input.filing_status, FilingStatus::MarriedJoint);
        assert_eq!(loaded.filing.input.tax_year, 2025);
        assert_eq!(loaded.filing.display_name, "Imported return");
        assert_eq!(
            loaded.filing.input.w2s,
            vec![clearfile_core::W2Entry {
                employer: "Acme".to_string(),
                wages: 90000.0,
                withholding: 9000.0,
            }]
        );
        // The computed outcome over that migrated shape (the engine's own
        // TY2025 numbers, pinned here so pipeline regressions show):
        assert_eq!(loaded.result.total_income, 90800.0);
        assert_eq!(loaded.result.agi, 90800.0);
        assert_eq!(loaded.result.deduction_method_used, DeductionMethod::Standard);
        assert_eq!(loaded.result.deduction_used, 31500.0);
        assert_eq!(loaded.result.taxable_income, 59300.0);
        assert_eq!(loaded.result.qualifying_children, 2);
        assert_eq!(loaded.result.refund, 7261.0);
        assert_eq!(loaded.result.amount_owed, 0.0);
        // The codec's migration warnings surface intact (count + the
        // verbatim first warning; the full wording is the core's own
        // pinned contract).
        assert_eq!(loaded.warnings.len(), 4);
        assert_eq!(
            loaded.warnings[0],
            "Saved with an older prototype: the return was migrated to the current engine model."
        );
    }

    #[test]
    fn headless_text_bytes_and_shape() {
        let text = text_summary(&loaded_fixture());
        // Shape: the groups in the gate's order + the warning block.
        let mut cursor = 0;
        for section in [
            "Income\n",
            "Deduction\n",
            "Tax\n",
            "Credits\n",
            "Refund / amount owed\n",
        ] {
            let at = text[cursor..].find(section).unwrap_or_else(|| {
                panic!("section {section:?} missing after byte {cursor} in:\n{text}")
            });
            cursor += at + section.len();
        }
        assert!(text.contains("Import warnings (4)\n"));
        assert!(text.contains("  - Dependent counts were migrated; re-enter their names in the Dependents step.\n"));
        assert!(text.ends_with(
            "Demonstration prototype — not tax advice; check with a qualified tax professional.\n"
        ));
        // Bytes: the committed expected text (the CI smoke's full-stdout
        // diff) matches, with only the invocation-dependent file path
        // normalized (CI passes the repo-root-relative path).
        let expected = include_str!("../tests/expected-headless.txt")
            .replace("fixtures/migration/v1-web-envelope.json", FIXTURE);
        assert_eq!(text, expected);
    }

    #[test]
    fn container_pipeline_roundtrip() {
        // The .tax route: the same filing through the exchange container
        // (envelope encoded by the core's codec, zipped by the core's
        // writer) computes identically through the SAME pipeline fn.
        let envelope = loaded_fixture();
        let encoded = ReturnFileCodec::encode(&envelope.filing, "1970-01-01T00:00:00.000Z")
            .expect("the envelope must encode");
        let container = export_tax_container(&encoded).expect("the container must zip");
        let temp = std::env::temp_dir().join(format!(
            "clearfile-linux-test-{}-{:p}.tax",
            std::process::id(),
            &encoded
        ));
        std::fs::write(&temp, &container).expect("the temp container must write");
        let loaded = load_and_compute(temp.to_str().unwrap());
        std::fs::remove_file(&temp).ok();
        let loaded = loaded.expect("the container path must import");
        assert_eq!(loaded.source, "the ClearFile exchange container (.tax)");
        assert_eq!(loaded.result, envelope.result);
        // Migration idempotence: the v1 envelope's migration warnings
        // applied when loaded_fixture() FIRST imported it; this
        // round-trip re-ENCODES the already-migrated v2 model, so the
        // container import is warning-free (a second migration pass
        // changes nothing — the warnings never duplicate).
        assert!(loaded.warnings.is_empty(),
            "the re-encoded v2 model imports warning-free: {:?}",
            loaded.warnings
        );
        // Provenance: the summary is honest about the import source.
        assert!(text_summary(&loaded).contains("Imported from the ClearFile exchange container (.tax).\n"));
    }

    #[test]
    fn honest_errors_match_the_core_wording_family() {
        let missing = load_and_compute("no/such/file.clearfile.json");
        assert_eq!(
            missing.unwrap_err(),
            "The file could not be read: No such file or directory (os error 2)."
        );
        // Not a ClearFile envelope: the core's own message, verbatim.
        let temp = std::env::temp_dir().join(format!("clearfile-linux-test-{}.json", std::process::id()));
        std::fs::write(&temp, b"{ \"format\": \"something-else\" }").unwrap();
        let message = load_and_compute(temp.to_str().unwrap()).unwrap_err();
        std::fs::remove_file(&temp).ok();
        assert_eq!(
            message,
            "Unrecognized format \"something-else\" — expected \"clearfile-return\". This is not a ClearFile return."
        );
    }
}
