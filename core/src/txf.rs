// SPDX-License-Identifier: GPL-3.0-only
//! TXF (Tax Exchange Format, published spec v042) bridge codecs (N1
//! session 2, ADR-017 annex (b)) — the std-only Rust port of:
//! - the IMPORTER, canonical, from the Dart reference
//!   `clearfile/lib/io/txf_import.dart` (366 lines: `parseTxf`,
//!   `TxfImportResult`, `TxfParseException`), including the shared
//!   tolerant money parser every `$` amount runs through
//!   (`clearfile/lib/util/money.dart:21-27`, `parseMoney` — a shared
//!   utility module in the Dart tree, ported here as [`parse_money`]);
//! - the EXPORTER from the TS twin `src/lib/files/txf.ts` (84 lines,
//!   `exportTxf`) — the Flutter app has no TXF writer
//!   (docs/formats/txf.md §6).
//!
//! `docs/formats/txf.md` is the commentary; the CODE is canonical. The two
//! references never overlap (each side has only its own codec), so no
//! Dart-vs-TS disagreement exists to arbitrate; the round-trip extension
//! pins that they compose.
//!
//! Grammar (spec v042, docs/formats/txf.md §2): a header (`V042`,
//! `A <program>`, `D <MM/DD/YYYY>`, `^` terminator) then `^`-terminated
//! records whose fields are single-letter-tagged lines — `T` record type
//! (`S` summary / `D` detail), `N` refnum, `C` form copy, `L` line within
//! the item, `$` amount (a record may carry several; they SUM),
//! `P` description/payer text, `X`/`D` field lines carried but unused.
//! The importer tolerates: CRLF endings (every `\r` stripped), blank
//! lines, whitespace-padded values (the value side is trimmed), a record
//! starting directly at `N…` (a missing `T` defaults to summary per the
//! spec), and a record whose terminator is EOF. Sign convention
//! (spec §VII.B): income positive, expenses and tax payments negative —
//! the importer stores magnitudes on the expense-side refnums, the
//! exporter writes the negatives.
//!
//! Refnum table (txf_import.dart:192-238 / docs/formats/txf.md §3):
//!
//! | Refnum | Tax line item | Maps to |
//! | --- | --- | --- |
//! | 460 / 506 | W-2 salary, taxpayer / spouse (box 1) | per-W-2 wages |
//! | 461 / 507 | federal withholding, taxpayer / spouse (box 2) | per-W-2 withholding (magnitude) |
//! | 466 / 513 | W-2 payer, taxpayer / spouse | per-W-2 employer |
//! | 287 | interest income (Sch B) | `interest_income` |
//! | 286 | total dividend income | dividends (ordinary = total − qualified) |
//! | 683 | qualified dividends | `qualified_dividends` |
//! | 488 | capital gain distributions | `long_term_capital_gains` |
//! | 257 | other income (1040:21) | `other_income` |
//! | 275 / 544 | state + local taxes (Sch A:5) | `state_local_income_or_sales_tax` |
//! | 276 | real estate tax (A:6) | `real_estate_tax` |
//! | 283 / 545 | home mortgage interest (A:10/11) | `mortgage_interest` |
//! | 280 | cash charity (A:16) | `charitable_cash` |
//! | 485 | non-cash charity (A:17) | `charitable_non_cash` |
//! | 268 / 521 | federal estimated tax payments | `estimated_payments` |
//! | 636 | student loan interest | `student_loan_interest` |
//!
//! W-2 grouping: each W-2 is the copy space `C` — taxpayer codes
//! (460/461/466) key `self:<copy>`, spouse codes (506/507/513) key
//! `spouse:<copy>` (spec §III); a second amount for a filled slot keeps
//! the FIRST and warns; a copy whose salary, withholding and payer are
//! all empty is dropped at import.
//!
//! Reader contract (docs/formats/txf.md §4): only summary (`TS`) records
//! import — detail (`TD`) records are ignored per spec §VII.A and
//! reported by count; unknown refnums and unknown types are reported,
//! never guessed; unparsable `N` values make the record malformed
//! (skipped, counted); unparsable `$` shapes are skipped with a
//! per-record warning. Hard refusals (never crashes): > 5 MB of text,
//! > 10,000 records, > 4,096 characters on a line, and zero importable
//! summary records — each with its verbatim message
//! ([`TxfParseError`]). Every user-readable message/warning below is
//! copied VERBATIM from the Dart (the import dialogs surface them
//! as-is; the wording is the contract, pinned by the ported suite).
//!
//! Writer profile (txf.ts:62-84 / docs/formats/txf.md §5): the V042
//! header, then per W-2 (copies C1, C2, …): an optional payer record
//! `466` (format 2 — text only, no `$`, emitted only for a non-blank
//! employer), the salary `460` (positive), the withholding `461`
//! (negative; zero stays plain zero), then `287` interest (positive,
//! described) and `636` student-loan interest (negative) when > 0.
//! Every record carries explicit `C` and `L1`; the file ends with a
//! trailing newline; an empty return exports the header only — still a
//! valid TXF file. Only that demo scope leaves the web prototype (the
//! UI says so and tells the user to verify the import in the receiving
//! software — the lossiness is pinned by the round-trip extension).
//!
//! # Purity seams (the reference I/O, kept out of the core)
//!
//! - [`export_txf`] takes the export-date PARTS (month, day, year): the
//!   TS reads `new Date()` itself and formats `MM/DD/YYYY` with
//!   `padStart(2, '0')` (txf.ts:31-36); a pure core owns no clock, so the
//!   caller supplies the parts and the padding is ported verbatim.
//! - The imported filing is [`ImportedReturn`]: the compute input plus
//!   the display name (`'Imported from TXF'`). Dart constructs a full
//!   `TaxReturnData` whose `id`/`created`/`modified` are `now`-based
//!   generated values (tax_return.dart:58-64) — a pure core owns
//!   neither clock nor RNG, so those three stay with the app layer.
//! - `TxfImportOutcome` (txf_import.dart:53-66) is picker-side UI (the
//!   cancelled state has no text to decode) — not ported, the same
//!   ruling as the envelope's `ReturnImportCancelled` (divergence #9
//!   in `crate::envelope`).
//!
//! # Deliberate divergences (ADR-017 annex (c) — one line + reason each)
//!
//! 1. **A `D` value shorter than 4 characters no longer crashes.** Dart's
//!    `exportDate.substring(exportDate.length - 4)` throws `RangeError`
//!    (txf_import.dart:147); the port reads it as no parsable year (no
//!    warning) — the Rust core never panics.
//! 2. **The exception's log prefix is dropped.** Dart
//!    `TxfParseException.toString()` prefixes `'TxfParseException: '`
//!    (txf_import.dart:50) — log formatting, not the dialog surface; the
//!    port's [`TxfParseError`] carries each message VERBATIM.
//! 3. **The W-2 slot sort coincides, not identical mechanism.** Dart
//!    sorts the `Map` keys with `String.compareTo` (UTF-16 code units,
//!    txf_import.dart:243); the port's `BTreeMap<String, _>` orders
//!    bytes — the keys are ASCII by construction (`self:<n>` /
//!    `spouse:<n>`), so the two orders agree on every reachable key.
//! 4. **Tag slicing is by character, not code unit.** Dart `line[0]` /
//!    `line.substring(1)` are UTF-16 code-unit ops (txf_import.dart:108,
//!    319-320); every tag this parser acts on is one ASCII letter, and a
//!    non-ASCII first character is ignored on both sides — no reachable
//!    difference (the value is only read for ASCII tags, where byte and
//!    code-unit slicing coincide).
//! 5. **The cap arithmetic counts UTF-16 code units** (Dart
//!    `String.length`) via [`utf16_len`] — NOT Rust bytes (an `é`-heavy
//!    file is 2× the bytes but the same unit count) and NOT chars (an
//!    emoji is 1 char but 2 units); both sides pinned by port tests.
//! 6. **`NaN`/`Infinity` amounts pass through.** Dart
//!    `double.tryParse` accepts `'NaN'`/`'Infinity'` (money.dart:26) and
//!    the sums carry them into the model; the port does the same (the
//!    grammar gate replicates Dart's exactly — Rust's lowercase
//!    `'inf'`/`'nan'` are rejected like Dart's). Not a divergence, but
//!    deliberate: pinned so the honesty of the pass-through cannot
//!    silently change.

use crate::{DeductionMethod, FilingStatus, TaxReturnInput, W2Entry};
use std::collections::{BTreeMap, BTreeSet};

/// The 5 MB whole-file parser cap (`_maxBytes`, txf_import.dart:68).
const MAX_BYTES: usize = 5 * 1024 * 1024;
/// The record-count cap (`_maxRecords`, txf_import.dart:69) — the Stage-2
/// entry gate's ENG-2 condition.
const MAX_RECORDS: usize = 10_000;
/// The per-line character cap (`_maxLineLength`, txf_import.dart:70).
const MAX_LINE_LENGTH: usize = 4096;

// ---------------------------------------------------------------------------
// The refusal tree (txf_import.dart:44-51 — a named enum, VERBATIM messages)
// ---------------------------------------------------------------------------

/// Hard parser refusals (txf_import.dart: `TxfParseException`). Every
/// message is user-readable and surfaces in the import dialog VERBATIM —
/// the wording is the contract (docs/formats/txf.md §4 pins all four).
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum TxfParseError {
    /// `'File exceeds the 5 MB parser limit (parser hardening, ADV-ENG
    /// #11).'` — the whole-file cap (txf_import.dart:79-82).
    FileTooLarge,
    /// `'Line N exceeds the 4096-character parser limit.'` — 1-based
    /// line number (txf_import.dart:97-99, 127-129).
    LineTooLong { line: usize },
    /// `'More than 10,000 records (parser hardening).'`
    /// (txf_import.dart:116-119).
    TooManyRecords,
    /// `'No importable summary (TS) records were found. The file may be a
    /// detail-only export or not a TXF file at all.'`
    /// (txf_import.dart:263-267).
    NoImportableRecords,
}

impl TxfParseError {
    /// The user-readable message, VERBATIM from the Dart reference.
    pub fn message(&self) -> String {
        match self {
            TxfParseError::FileTooLarge => {
                "File exceeds the 5 MB parser limit (parser hardening, ADV-ENG #11).".to_owned()
            }
            TxfParseError::LineTooLong { line } => {
                format!("Line {line} exceeds the 4096-character parser limit.")
            }
            TxfParseError::TooManyRecords => {
                "More than 10,000 records (parser hardening).".to_owned()
            }
            TxfParseError::NoImportableRecords => {
                "No importable summary (TS) records were found. The file may be a \
                 detail-only export or not a TXF file at all."
                    .to_owned()
            }
        }
    }
}

impl std::fmt::Display for TxfParseError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        // The message without Dart's log-only 'TxfParseException: ' prefix
        // (divergence #2).
        write!(f, "{}", self.message())
    }
}

impl std::error::Error for TxfParseError {}

// ---------------------------------------------------------------------------
// The results (txf_import.dart:32-42)
// ---------------------------------------------------------------------------

/// The imported filing — the Dart `TaxReturnData` the importer constructs
/// (txf_import.dart:269-284): the compute input with the Dart constructor
/// defaults (taxYear 2025, single, auto, no dependents — tax_return.dart:
/// 32-64) plus the display name `'Imported from TXF'`. The three
/// now-based fields Dart generates (`id`, `created`, `modified`) are the
/// app layer's under the purity seam (module docs).
#[derive(Clone, Debug, PartialEq)]
pub struct ImportedReturn {
    /// Dart `displayName: 'Imported from TXF'` (txf_import.dart:270).
    pub display_name: String,
    /// The compute input, the imported fields set per the refnum table.
    pub input: TaxReturnInput,
}

/// A successful TXF import (Dart `TxfImportResult`, txf_import.dart:32-42).
#[derive(Clone, Debug, PartialEq)]
pub struct TxfImportResult {
    /// The imported filing.
    pub return_data: ImportedReturn,
    /// Human-readable notes for the import dialog, in emission order
    /// (skips, sign oddities, duplicate-keeps, ignored detail records…).
    pub warnings: Vec<String>,
    /// Refnums present in the file that the demo scope does not map,
    /// deduped and sorted (Dart `unknownCodes`).
    pub unknown_codes: Vec<i64>,
}

// ---------------------------------------------------------------------------
// The importer (txf_import.dart:78-304, `parseTxf`)
// ---------------------------------------------------------------------------

/// One parsed record under construction (Dart `_TxfRecord`,
/// txf_import.dart:306-314). Its `malformed` flag is modeled by
/// [`Self::refnum`] being `None` — Dart only ever sets it for a missing
/// `N` refnum (txf_import.dart:135-137).
#[derive(Default)]
struct TxfRecord {
    /// The `T` record type, uppercased (`'S'` summary / `'D'` detail);
    /// absent means summary per the spec.
    type_: Option<String>,
    /// The `N` refnum; `None` = the record is malformed and skipped.
    refnum: Option<i64>,
    /// The `C` form-copy number (W-2 copies; defaults 1).
    copy: i64,
    /// The `L` line-within-item number — parsed and carried, never
    /// consumed (the sums are per-record; Dart's `_TxfRecord.line` is
    /// equally unread, txf_import.dart:329).
    #[allow(dead_code)]
    line: i64,
    /// The `P` description/payer text.
    text: Option<String>,
    /// Every `$` amount value in file order (a record may carry several).
    amounts: Vec<String>,
}

impl TxfRecord {
    /// Dart's constructor defaults for `copy`/`line` are 1
    /// (txf_import.dart:309-310) — not the derive's 0.
    fn new() -> TxfRecord {
        TxfRecord {
            copy: 1,
            line: 1,
            ..TxfRecord::default()
        }
    }
}

/// Per-copy W-2 accumulator (Dart `_W2Accumulator`, txf_import.dart:72-76).
#[derive(Default)]
struct W2Accumulator {
    payer: Option<String>,
    salary: f64,
    withholding: f64,
}

/// Parses TXF text into a filing plus honest warnings
/// (Dart `parseTxf`, txf_import.dart:78-304, ported whole).
///
/// Refuses (never crashes) on the three parser caps and on a file with no
/// importable summary record; never guesses an unknown refnum or type.
pub fn parse_txf(contents: &str) -> Result<TxfImportResult, TxfParseError> {
    // Dart String.length is UTF-16 code units — so is the cap (divergence
    // #5). Checked before any allocation.
    if utf16_len(contents) > MAX_BYTES {
        return Err(TxfParseError::FileTooLarge);
    }

    let mut warnings: Vec<String> = Vec::new();
    let mut unknown: BTreeSet<i64> = BTreeSet::new();

    // txf_import.dart:86-87: split on '\n', then strip EVERY '\r' in each
    // line (not only a trailing CRLF).
    let raw_lines: Vec<String> = contents.split('\n').map(|l| l.replace('\r', "")).collect();

    // Header fields (V version / A program / D date) before the first '^'.
    let mut version: Option<String> = None;
    let mut export_date: Option<String> = None;
    let mut saw_header_terminator = false;
    let mut records: Vec<TxfRecord> = Vec::new();
    let mut records_started: usize = 0;

    let mut i: usize = 0;
    while i < raw_lines.len() {
        let raw: &str = &raw_lines[i];
        // The length cap is checked when the line is REACHED, on the
        // \r-stripped line, counted in UTF-16 units; the message's line
        // number is 1-based (txf_import.dart:97-100).
        if utf16_len(raw) > MAX_LINE_LENGTH {
            return Err(TxfParseError::LineTooLong { line: i + 1 });
        }
        let line = dart_trim(raw);
        if line.is_empty() {
            i += 1;
            continue;
        }
        if line == "^" {
            saw_header_terminator = true;
            i += 1;
            continue;
        }
        if !saw_header_terminator {
            // Only V and D carry anything the importer needs; the A line
            // (and any other) is ignored (txf_import.dart:107-113).
            if let Some(tag) = line.chars().next() {
                let value = dart_trim(&line[tag.len_utf8()..]);
                if tag == 'V' {
                    version = Some(value.to_owned());
                }
                if tag == 'D' {
                    export_date = Some(value.to_owned());
                }
            }
            i += 1;
            continue;
        }
        // A record STARTS at this line — it may legally be its own first
        // field line (e.g. `N460`; a missing T defaults to summary per the
        // spec, txf_import.dart:120-122). The record cap is checked at
        // record START, before the record's fields apply — the 10,001st
        // record refuses before any more of its lines are read
        // (txf_import.dart:114-119).
        records_started += 1;
        if records_started > MAX_RECORDS {
            return Err(TxfParseError::TooManyRecords);
        }
        let mut rec = TxfRecord::new();
        apply_field(&mut rec, line);
        // Accumulate further fields until the record terminator or EOF
        // (txf_import.dart:124-134).
        while i + 1 < raw_lines.len() {
            i += 1;
            let next_raw: &str = &raw_lines[i]; // '\r' already stripped above
            if utf16_len(next_raw) > MAX_LINE_LENGTH {
                return Err(TxfParseError::LineTooLong { line: i + 1 });
            }
            let next = dart_trim(next_raw);
            if next.is_empty() {
                continue;
            }
            if next == "^" {
                break;
            }
            apply_field(&mut rec, next);
        }
        // A refnum-less record is malformed (counted and skipped later);
        // it still counted toward the record cap above, exactly like Dart.
        records.push(rec);
        i += 1;
    }

    // Version / export-date notes (txf_import.dart:140-152).
    match &version {
        None => warnings.push("No V version field found; parsed the records anyway.".to_owned()),
        Some(v) if v != "042" => {
            warnings.push(format!("TXF spec version V{v} parsed (the suite pins V042)."));
        }
        Some(_) => {}
    }
    if let Some(date) = &export_date {
        // Dart takes the LAST 4 CODE UNITS and int-parses them; a value
        // shorter than 4 would throw RangeError there — the port reads it
        // as no parsable year instead (divergence #1). Dates are ASCII in
        // practice, so last-4-chars is Dart's last-4-units.
        let tail: String = date.chars().rev().take(4).collect();
        let year: String = tail.chars().rev().collect();
        if let Ok(year) = year.parse::<i64>() {
            if year != 2025 {
                warnings.push(format!(
                    "TXF carries no tax-year field; the export date is {year}, \
                     so the return stays on 2025 — edit it after import."
                ));
            }
        }
    }

    // --- the accumulators (txf_import.dart:154-174) --------------------
    let mut w2s: BTreeMap<String, W2Accumulator> = BTreeMap::new();

    let mut interest = 0.0;
    let mut div_total = 0.0;
    let mut div_qualified = 0.0;
    let mut cap_gain_dist = 0.0;
    let mut other_income = 0.0;
    let mut state_local_tax = 0.0;
    let mut real_estate_tax = 0.0;
    let mut mortgage_interest = 0.0;
    let mut charity_cash = 0.0;
    let mut charity_non_cash = 0.0;
    let mut estimated_payments = 0.0;
    let mut student_loan_interest = 0.0;

    let mut detail_records_ignored: usize = 0;
    let mut malformed_records: usize = 0;
    let mut importable_records: usize = 0;

    // --- the mapping loop (txf_import.dart:176-240) ---------------------
    for rec in &records {
        // Malformed (no N refnum) first…
        let Some(code) = rec.refnum else {
            malformed_records += 1;
            continue;
        };
        // …then detail records (spec §VII.A: "may be safely ignored")…
        match rec.type_.as_deref() {
            Some("D") => {
                detail_records_ignored += 1;
                continue;
            }
            // …then an unknown type is reported, never guessed.
            Some(t) if t != "S" => {
                warnings.push(format!("Record N{code} has unknown type \"{t}\"; skipped."));
                continue;
            }
            _ => {}
        }
        // The amount is computed for EVERY surviving record — payer (466)
        // and unknown-refnum records included: an unreadable `$` warns even
        // where the amount is then unused (txf_import.dart:191).
        let amount = amount_of(rec, &mut warnings, code);
        match code {
            // --- W-2 family (copy-grouped; spouse codes in their own copy
            // space per spec §III) ------------------------------------------
            460 | 506 => {
                let what = format!("W-2 salary (copy {})", rec.copy);
                let slot = w2_slot(&mut w2s, code == 460, rec.copy);
                slot.salary = first_amount(slot.salary, amount, &mut warnings, &what);
            }
            461 | 507 => {
                let what = format!("W-2 withholding (copy {})", rec.copy);
                let slot = w2_slot(&mut w2s, code == 461, rec.copy);
                // Withholding is stored as a magnitude (spec §VII.B).
                slot.withholding =
                    first_amount(slot.withholding, amount.abs(), &mut warnings, &what);
            }
            466 | 513 => {
                let slot = w2_slot(&mut w2s, code == 466, rec.copy);
                // Dart `payer ??= rec.text`: the first P text wins, even an
                // empty one (a later payer never replaces it).
                if slot.payer.is_none() {
                    slot.payer = rec.text.clone();
                }
            }
            // --- income (summed, signs kept) ---------------------------------
            287 => interest += amount,
            286 => div_total += amount,
            683 => div_qualified += amount,
            488 => cap_gain_dist += amount,
            257 => other_income += amount,
            // --- deductions / payments (magnitudes per spec §VII.B) ---------
            275 | 544 => state_local_tax += amount.abs(),
            276 => real_estate_tax += amount.abs(),
            283 | 545 => mortgage_interest += amount.abs(),
            280 => charity_cash += amount.abs(),
            485 => charity_non_cash += amount.abs(),
            268 | 521 => estimated_payments += amount.abs(),
            636 => student_loan_interest += amount.abs(),
            _ => {
                unknown.insert(code);
            }
        }
        importable_records += 1;
    }

    // --- W-2 emission (txf_import.dart:242-251) ---------------------------
    // BTreeMap iteration is key-sorted; Dart sorts the keys explicitly —
    // the same order for these ASCII-only keys (divergence #3).
    let mut w2_entries: Vec<W2Entry> = Vec::new();
    for acc in w2s.values() {
        if acc.salary == 0.0 && acc.withholding == 0.0
            && acc.payer.as_deref().unwrap_or("").is_empty()
        {
            continue;
        }
        w2_entries.push(W2Entry {
            employer: acc.payer.clone().unwrap_or_default(),
            wages: acc.salary,
            withholding: acc.withholding,
        });
    }

    // --- dividend honesty rules (txf_import.dart:253-261) -----------------
    if div_qualified > 0.0 && div_total > 0.0 && div_qualified > div_total {
        warnings.push(
            "Qualified dividends exceed total dividends; the ordinary portion was clamped to \
             zero."
                .to_owned(),
        );
    }
    let ordinary = if div_qualified > 0.0 {
        div_total - div_qualified
    } else {
        div_total
    };
    if div_qualified > 0.0 && div_total == 0.0 {
        warnings.push(
            "Qualified dividends imported with no total-dividend record; the ordinary portion \
             is unknown and left at zero."
                .to_owned(),
        );
    }

    if importable_records == 0 {
        return Err(TxfParseError::NoImportableRecords);
    }

    let return_data = ImportedReturn {
        display_name: "Imported from TXF".to_owned(),
        input: TaxReturnInput {
            // Every unimported field keeps the Dart TaxReturnData
            // constructor defaults (tax_return.dart:32-64).
            tax_year: 2025,
            filing_status: FilingStatus::Single,
            taxpayer_65_or_older: false,
            spouse_65_or_older: false,
            taxpayer_blind: false,
            spouse_blind: false,
            w2s: w2_entries,
            interest_income: interest,
            ordinary_dividends: if ordinary > 0.0 { ordinary } else { 0.0 },
            qualified_dividends: div_qualified,
            long_term_capital_gains: cap_gain_dist,
            other_income,
            student_loan_interest,
            deduction_method: DeductionMethod::Auto,
            state_local_income_or_sales_tax: state_local_tax,
            real_estate_tax,
            mortgage_interest,
            charitable_cash: charity_cash,
            charitable_non_cash: charity_non_cash,
            estimated_payments,
            dependents: Vec::new(),
        },
    };

    // --- the tail warnings, in Dart's exact emission order
    // (txf_import.dart:286-301) ------------------------------------------
    if detail_records_ignored > 0 {
        warnings.push(format!(
            "{detail_records_ignored} detail (TD) records ignored, per the spec."
        ));
    }
    if malformed_records > 0 {
        warnings.push(format!(
            "{malformed_records} records had no N refnum and were skipped."
        ));
    }
    if !unknown.is_empty() {
        // Dart: (set toList..sort).join(", ") — sorted, ", "-joined.
        let list = unknown
            .iter()
            .map(|c| c.to_string())
            .collect::<Vec<String>>()
            .join(", ");
        warnings.push(format!("Refnums present but not mapped by the demo scope: {list}."));
    }
    if return_data.input.w2s.is_empty() {
        warnings.push("No W-2 wage records found — only the non-wage fields imported.".to_owned());
    }

    Ok(TxfImportResult {
        return_data,
        warnings,
        unknown_codes: unknown.into_iter().collect(),
    })
}

/// Applies one `T`/`N`/`C`/`L`/`$`/`P`/`X`/`D` field line to `rec`
/// (Dart `_applyField`, txf_import.dart:318-339). Detail (`X`) and date
/// (`D`) FIELD lines carry nothing the importer needs; any other tag is
/// ignored the same way (the line still belongs to its record).
fn apply_field(rec: &mut TxfRecord, line: &str) {
    let Some(tag) = line.chars().next() else {
        return; // unreachable: callers pass non-empty lines
    };
    let value = dart_trim(&line[tag.len_utf8()..]);
    match tag {
        'T' => rec.type_ = Some(value.to_uppercase()),
        'N' => rec.refnum = value.parse::<i64>().ok(),
        'C' => rec.copy = value.parse::<i64>().unwrap_or(1),
        'L' => rec.line = value.parse::<i64>().unwrap_or(1),
        '$' => rec.amounts.push(value.to_owned()),
        'P' => rec.text = Some(value.to_owned()),
        _ => {}
    }
}

/// The W-2 copy-slot key: `'self:<copy>'` for taxpayer codes, `'spouse:
/// <copy>'` for spouse codes (Dart `_w2Slot`, txf_import.dart:341-342).
fn w2_slot<'a>(
    map: &'a mut BTreeMap<String, W2Accumulator>,
    self_side: bool,
    copy: i64,
) -> &'a mut W2Accumulator {
    let key = format!("{}:{}", if self_side { "self" } else { "spouse" }, copy);
    map.entry(key).or_default()
}

/// Sums a record's `$` amounts, skipping — with a verbatim per-record
/// warning — every value that does not parse (Dart `_amountOf`,
/// txf_import.dart:344-357).
fn amount_of(rec: &TxfRecord, warnings: &mut Vec<String>, code: i64) -> f64 {
    if rec.amounts.is_empty() {
        return 0.0;
    }
    let mut total = 0.0;
    for raw in &rec.amounts {
        match parse_money(raw) {
            Some(parsed) => total += parsed,
            None => warnings.push(format!(
                "Record N{code}: amount \"{raw}\" could not be read; skipped."
            )),
        }
    }
    total
}

/// Keep-the-first semantics for the W-2 salary/withholding slots: a
/// NON-ZERO current value wins with a verbatim warning; a zero (or
/// NaN-free first unset) slot takes the new value silently — including
/// when the first amount was 0 (Dart `_first`, txf_import.dart:359-366,
/// checks `current != 0`, not "was ever set").
fn first_amount(current: f64, value: f64, warnings: &mut Vec<String>, what: &str) -> f64 {
    if current != 0.0 {
        warnings.push(format!("Duplicate {what} record; the first one was kept."));
        return current;
    }
    value
}

// ---------------------------------------------------------------------------
// The money parser (Dart clearfile/lib/util/money.dart:21-27, `parseMoney`)
// ---------------------------------------------------------------------------

/// The shared tolerant money parser every `$` amount runs through (Dart
/// `parseMoney`, money.dart:21-27 — a shared utility module in the Dart
/// tree; its own suite, `clearfile/test/money_parse_test.dart`, pins the
/// same behaviors the port-extension battery re-pins here):
/// - empty/whitespace-only input parses as 0 — "no amount", not an error;
/// - `$`, thousands commas and whitespace are stripped ANYWHERE;
/// - a comma followed by only one or two trailing digits is never valid
///   US grouping, so decimal-comma shapes (`"6,5"`, `"6,50"`) are
///   refused as `None` instead of silently mangling;
/// - Dart `double.tryParse` semantics on the cleaned text — including its
///   `NaN`/`Infinity` acceptance (divergence #6).
pub fn parse_money(raw: &str) -> Option<f64> {
    // Dart: replaceAll('\$','').replaceAll(RegExp(r'\s'), '') — the \s class
    // is Unicode White_Space plus \uFEFF.
    let stripped: String = raw
        .chars()
        .filter(|c| *c != '$' && !is_ecma_whitespace(*c))
        .collect();
    // The decimal-comma refusal: ^-?\d+,\d{1,2}$ (ASCII \d, money.dart:23).
    if is_decimal_comma_shape(&stripped) {
        return None;
    }
    let cleaned: String = stripped.chars().filter(|c| *c != ',').collect();
    if cleaned.is_empty() {
        return Some(0.0);
    }
    dart_double_try_parse(&cleaned)
}

/// `^-?\d+,\d{1,2}$` over the stripped text (ASCII digits — Dart RegExp
/// `\d` is ASCII-only without the unicode flag, money.dart:23).
fn is_decimal_comma_shape(s: &str) -> bool {
    let body = s.strip_prefix('-').unwrap_or(s);
    let mut parts = body.split(',');
    let (Some(int_part), Some(frac_part)) = (parts.next(), parts.next()) else {
        return false;
    };
    if parts.next().is_some() {
        return false; // a second comma: not the refused shape either
    }
    !int_part.is_empty()
        && int_part.bytes().all(|b| b.is_ascii_digit())
        && (1..=2).contains(&frac_part.len())
        && frac_part.bytes().all(|b| b.is_ascii_digit())
}

/// Dart `double.tryParse` on whitespace-free text (money.dart:26): an
/// optional sign, then exactly `NaN` or `Infinity`, or the Dart double
/// literal grammar — `digits ('.' digits?)? exponent?` / `'.' digits
/// exponent?`. Rust's `f64::from_str` accepts a SUPERSET (lowercase
/// `'inf'`/`'nan'`), so the grammar is validated FIRST and the text then
/// handed to Rust's correctly-rounded decimal parser — identical bits for
/// every accepted form (both accept `"5."`, `".5"`, `"+5"`, `"5.e3"`, and
/// overflow to infinity).
fn dart_double_try_parse(s: &str) -> Option<f64> {
    let (neg, body) = match s.as_bytes().first() {
        Some(b'-') => (true, &s[1..]),
        Some(b'+') => (false, &s[1..]),
        _ => (false, s),
    };
    match body {
        "NaN" => return Some(f64::NAN), // the sign of NaN is unobservable
        "Infinity" => {
            return Some(if neg { f64::NEG_INFINITY } else { f64::INFINITY });
        }
        _ => {}
    }
    if !is_dart_double_literal(body) {
        return None;
    }
    s.parse::<f64>().ok()
}

/// The Dart double literal grammar (the numeric half — the sign is
/// already stripped by the caller): `digits ('.' digits?)? exponent?` or
/// `'.' digits exponent?`, exponent = `e|E ('+'|'-')? digits`.
fn is_dart_double_literal(s: &str) -> bool {
    let b = s.as_bytes();
    let mut i = 0;
    let int_digits = count_ascii_digits(b, &mut i);
    if int_digits > 0 {
        if i < b.len() && b[i] == b'.' {
            i += 1;
            count_ascii_digits(b, &mut i); // optional fraction digits
        }
    } else {
        if i >= b.len() || b[i] != b'.' {
            return false;
        }
        i += 1;
        if count_ascii_digits(b, &mut i) == 0 {
            return false;
        }
    }
    if i < b.len() && (b[i] == b'e' || b[i] == b'E') {
        i += 1;
        if i < b.len() && (b[i] == b'+' || b[i] == b'-') {
            i += 1;
        }
        if count_ascii_digits(b, &mut i) == 0 {
            return false;
        }
    }
    i == b.len()
}

fn count_ascii_digits(b: &[u8], i: &mut usize) -> usize {
    let start = *i;
    while *i < b.len() && b[*i].is_ascii_digit() {
        *i += 1;
    }
    *i - start
}

// ---------------------------------------------------------------------------
// The exporter (src/lib/files/txf.ts:62-84, `exportTxf`)
// ---------------------------------------------------------------------------

/// Writes the demo-scope TXF export (TS `exportTxf`, txf.ts:62-84):
/// the V042 header, then per W-2 (copies C1, C2, …) an optional payer
/// record `466` (only for a non-blank employer), the salary `460`
/// (positive), the withholding `461` (negative — a zero stays plain
/// zero), then `287` interest and `636` student-loan interest (negative)
/// when > 0. Only those fields leave the prototype (the UI discloses
/// the scope and says to verify the import in the receiving software).
///
/// The export-date parts are the purity seam: the TS reads `new Date()`
/// and formats `MM/DD/YYYY` with `padStart(2, '0')` (txf.ts:31-36); the
/// core owns no clock, so the caller supplies (month, day, year) and the
/// padding is ported verbatim (`{:02}` pads to two, keeps wider).
pub fn export_txf(filing: &TaxReturnInput, month: u32, day: u32, year: i64) -> String {
    let mut lines: Vec<String> = vec![
        "V042".to_owned(),
        format!("A ClearFile {} (web prototype)", filing.tax_year),
        format!("D {:02}/{:02}/{}", month, day, year),
        "^".to_owned(),
    ];
    for (i, w2) in filing.w2s.iter().enumerate() {
        let copy = i as i64 + 1;
        let employer = dart_trim(&w2.employer);
        if !employer.is_empty() {
            lines.extend(ts_record(466, None, copy, 1, Some(employer)));
        }
        lines.extend(ts_record(460, Some(w2.wages), copy, 1, None));
        // Spec §VII.B: money paid is negative.
        lines.extend(ts_record(461, Some(-w2.withholding), copy, 1, None));
    }
    if filing.interest_income > 0.0 {
        lines.extend(ts_record(287, Some(filing.interest_income), 1, 1, Some("Interest income")));
    }
    if filing.student_loan_interest > 0.0 {
        lines.extend(ts_record(636, Some(-filing.student_loan_interest), 1, 1, None));
    }
    let mut out = lines.join("\n");
    out.push('\n');
    out
}

/// One summary record (TS `tsRecord`, txf.ts:45-60): `TS`, `N<code>`,
/// explicit `C<copy>` and `L<line>` (both default 1 at the call sites),
/// the `$<amount>` line for amount records, the `P<text>` line for
/// described ones, then the `^` terminator. `amount` is `None` for
/// text-only (format 2) records.
fn ts_record(code: i64, amount: Option<f64>, copy: i64, line: i64, text: Option<&str>) -> Vec<String> {
    let mut out = vec![
        "TS".to_owned(),
        format!("N{code}"),
        format!("C{copy}"),
        format!("L{line}"),
    ];
    if let Some(amount) = amount {
        out.push(format!("${}", money(amount)));
    }
    // JS truthiness (txf.ts:57 `if (opts.text)`): only a NON-EMPTY text
    // emits the P line — exportTxf's own call sites guarantee it; the
    // check is kept anyway.
    if let Some(text) = text {
        if !text.is_empty() {
            out.push(format!("P{text}"));
        }
    }
    out.push("^".to_owned());
    out
}

/// The signed money line body (TS `money`, txf.ts:38-42): a negative
/// value renders `'-'` + the absolute value's fixed-2 form; a zero stays
/// plain (`-0.0 < 0` is false in both JS and Rust, so `-w2.withholding`
/// for a zero withholding emits `"0.00"`, not `"-0.00"`).
fn money(value: f64) -> String {
    let negative = value < 0.0;
    format!("{}{}", if negative { "-" } else { "" }, ecma_to_fixed_2(value.abs()))
}

/// ECMAScript `Number.prototype.toFixed(2)` on the NON-NEGATIVE value
/// the TS `money()` passes (`Math.abs(value).toFixed(2)`, txf.ts:41):
/// the integer `n` minimizing `|n/100 − x|`, ties to the LARGER `n` —
/// NOT Rust's `{:.2}` half-to-even (0.125 renders `"0.13"` here,
/// `"0.12"` there; pinned by the port tests). `n` is computed in exact
/// integer arithmetic over the f64's dyadic value `m·2^e`, so the
/// rounding is bit-faithful to V8 for every finite input — including
/// huge integers ≥ 2^53 whose exact decimal expansion both engines
/// print (`123456789012345680000 → "123456789012345683968.00"`).
fn ecma_to_fixed_2(x: f64) -> String {
    // toFixed steps 1-2: NaN/∞ render as ToString (money() reaches these
    // only with a NaN/∞ amount — pinned by the port tests).
    if x.is_nan() {
        return "NaN".to_owned();
    }
    if x == f64::INFINITY {
        return "Infinity".to_owned();
    }
    // toFixed step 6: x ≥ 10^21 returns ToString(x) — no fixed form.
    if x >= 1e21 {
        return ecma_number_to_string(x);
    }
    let bits = x.to_bits() & 0x7fff_ffff_ffff_ffff; // |x| (money() passes abs; masked for totality)
    let exp_field = (bits >> 52) as i64;
    let frac = (bits & 0x000f_ffff_ffff_ffff) as u128;
    if exp_field == 0 {
        // Zero and subnormals: 100·x < 2^-1068 rounds to 0.00.
        return "0.00".to_owned();
    }
    let m = frac + (1u128 << 52); // the 53-bit significand
    let e = exp_field - 1023 - 52; // x = m·2^e exactly
    // n = round(100·x), ties up. With x < 1e21: e ≥ 0 implies x ≥ 2^52,
    // which bounds e ≤ 17, so n < 1e23 fits u128 with room to spare.
    let n: u128 = if e >= 0 {
        m * 100 * (1u128 << e)
    } else {
        let k = -e; // d = 2^k
        let num = m * 100; // < 2^60
        if k >= 64 {
            // d = 2^k ≥ 2^64 > 2·num: 100·x < 0.5 rounds to 0.
            return "0.00".to_owned();
        }
        let d = 1u128 << k;
        let q = num / d;
        let r = num % d;
        if 2 * r >= d {
            q + 1 // strictly past half, or exactly half → the larger n
        } else {
            q
        }
    };
    format!("{}.{:02}", n / 100, n % 100)
}

/// ECMAScript `Number::toString` for the |x| ≥ 10^21 corner `toFixed`
/// defers to (txf.ts:41 can reach it only with a ≥ 10^21 amount):
/// shortest-round-trip digits, `e`, SIGNED exponent. Rust's `{:e}` emits
/// the same shortest digits but omits the exponent's `+` — re-inserted
/// here.
fn ecma_number_to_string(x: f64) -> String {
    let rust_e = format!("{x:e}");
    match rust_e.split_once('e') {
        Some((mantissa, exp)) if !exp.starts_with('+') && !exp.starts_with('-') => {
            format!("{mantissa}e+{exp}")
        }
        _ => rust_e,
    }
}

// ---------------------------------------------------------------------------
// Dart/JS string primitives (the exact semantics the codecs rely on)
// ---------------------------------------------------------------------------

/// Dart `String.length` / `String[i]` arithmetic unit: UTF-16 code units.
/// The byte caps count these, not Rust bytes or chars (divergence #5).
fn utf16_len(s: &str) -> usize {
    s.chars().map(char::len_utf16).sum()
}

/// Dart `String.trim()` / TS `String.prototype.trim()`: trims Unicode
/// White_Space plus U+FEFF from both ends (Rust's `str::trim` covers
/// White_Space; the BOM is added here).
fn dart_trim(s: &str) -> &str {
    s.trim_matches(|c: char| is_ecma_whitespace(c))
}

/// The ECMAScript `\s` class (shared by Dart RegExp `\s`, money.dart:22,
/// and JS `trim()`): Unicode White_Space plus U+FEFF.
fn is_ecma_whitespace(c: char) -> bool {
    c.is_whitespace() || c == '\u{feff}'
}
