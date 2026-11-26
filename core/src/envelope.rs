// SPDX-License-Identifier: GPL-3.0-only
//! The unified ClearFile return file format (ADR-015) — the std-only Rust
//! port of the `.clearfile.json` envelope codec, ported whole from the
//! CANONICAL Dart reference `clearfile/lib/io/return_format.dart`
//! (306 lines: `ReturnFileCodec`, `DecodedReturnFile`,
//! `ReturnFormatException`, `ReturnImport`/`decodeReturnImport`), together
//! with the flat filing (de)serialization from
//! `clearfile/lib/models/tax_return.dart` (`TaxReturnData.toJson`/
//! `fromJson`) and the tolerant field readers from
//! `clearfile/lib/models/json_codec.dart`.
//!
//! Every user-visible message/warning string is copied VERBATIM — they
//! surface in the import dialogs verbatim — and each one is
//! cross-checked against the TS twin `src/lib/files/cfr.ts`: the two
//! references agree on every string. Where their BRANCHES differ, the
//! Dart wording is canonical (listed under "Reader leniencies" below).
//!
//! # Layout
//!
//! - [`TaxReturnData`] — the filing model: [`crate::TaxReturnInput`] plus
//!   the serialization-only metadata (`id`, `displayName`, `created`,
//!   `modified`) the Flutter app carries; `to_json_map`/`from_json_map`
//!   keep the exact field order of `tax_return.dart`'s `toJson`.
//! - [`ReturnFileCodec`] — the envelope: `encode` (the v2 writer) and
//!   `decode` (the v2 reader, the v1 web migration `_migrateWebV1`, the
//!   legacy flat lift, and the shared tolerant tail `_finish` with every
//!   warning the reader owes the user).
//! - [`decode_return_import`] / [`ReturnImport`] — the picker-independent
//!   half of the import flow (DEBT D1).
//!
//! # The purity seams (the reference's I/O, kept out of the core)
//!
//! - `encode` takes the `savedAt` stamp as a parameter: Dart calls
//!   `DateTime.now().toUtc().toIso8601String()` itself
//!   (return_format.dart:67); a pure core has no clock, so the caller
//!   owns the instant and passes the exact text (Dart's own emission
//!   shape, e.g. `"2026-11-15T02:00:00.000Z"` — written verbatim as
//!   `savedAt`, never validated).
//! - `created`/`modified` are stored as the ISO-8601 TEXT, not as a
//!   `DateTime`: a pure core has no timezone and no clock.
//!
//! # Deliberate divergences from the Dart reference (ADR-017 annex (c))
//!
//! 1. **Epoch fallback text.** Dart's `readDate` fallback is
//!    `DateTime.fromMillisecondsSinceEpoch(0)` (json_codec.dart:49) — a
//!    LOCAL `DateTime` whose `toIso8601String()` rendering is
//!    machine-dependent (`1970-01-01T00:00:00.000` on a UTC-timezone
//!    machine, `1969-12-31T19:00:00.000` in New York). The port stores
//!    [`EPOCH_INSTANT_TEXT`], the UTC rendering of the same instant with
//!    the `Z` marker — deterministic across machines, identical to what
//!    Dart produces on a UTC machine and to the `savedAt` shape Dart's
//!    own encoder stamps.
//! 2. **No date re-normalization.** Dart stores a real `DateTime` and
//!    re-emits a normalized ISO string on the next save (an offset like
//!    `+02:00` is converted to UTC). The port keeps an accepted
//!    timestamp's text verbatim; the accepted grammar is documented on
//!    [`is_accepted_iso8601_text`].
//! 3. **Dart's crash paths made tolerant.** A non-string
//!    `filingStatus`/`deductionMethod` throws `TypeError` in Dart
//!    (tax_return.dart:154,170 `as String?`); the port defaults to
//!    `single`/`auto` — consistent with the "was missing; defaulted"
//!    warning `_finish` has already emitted. A non-list
//!    `w2s`/`dependents` throws `TypeError` in Dart
//!    (tax_return.dart:159,178 `as List?`); the port reads it as the
//!    empty list, matching the web twin's tolerance (cfr.ts:174,185).
//!    Non-map entries INSIDE those lists are dropped exactly like Dart's
//!    `.whereType<Map>()`.
//! 4. **The int/double literal typing is erased.** The core JSON model
//!    parses every number to binary64, so Dart's distinction between
//!    `1` (jsonDecode → `int`) and `1.0`/`1e0` (→ `double`) cannot be
//!    recovered: a whole-value `version`/`formatVersion` is always
//!    "int". Consequences: a `version` of `1.0` is accepted as v1
//!    (Dart refuses it — its decoder types it double and the
//!    `v is! int` guard fires, return_format.dart:105 — while the web
//!    twin's number-typed guard accepts it too, cfr.ts:149), and a flat
//!    `formatVersion` of `2.0` is refused (Dart's `is int` guard skips
//!    the double-typed value and lifts the file; the web twin refuses it
//!    too, cfr.ts:134). No fixture or real writer emits fractional-form
//!    version literals.
//! 5. **Web-reader-only warning strings are NOT ported.**
//!    `'Return metadata (name, dates) from the Flutter app is kept in the
//!    file but not carried by the web prototype.'` (cfr.ts:141),
//!    `'W-2 list was invalid; it was dropped.'` (cfr.ts:175) and
//!    `'Dependent list was invalid; it was dropped.'` (cfr.ts:186)
//!    describe the WEB model (which drops `id`/`displayName`/`created`/
//!    `modified` and reports its own dropped lists). The Rust model
//!    carries the metadata fields like Dart's, and the Dart reader —
//!    the canonical source of this port — emits none of them.
//! 6. **Top-level non-objects.** A JSON array/scalar at the top level is
//!    `'The file does not contain a ClearFile return.'` (Dart's
//!    `decoded is! Map` check, return_format.dart:84-87); the web twin
//!    falls through to `Unrecognized format "undefined"` (cfr.ts:125,146
//!    — `typeof [] === 'object'` there). The Dart wording is canonical.
//! 7. **encode's fail-closed non-finite message.** Dart's `JsonEncoder`
//!    throws an internal `JsonUnsupportedObjectError` on NaN/∞; the port
//!    surfaces `'The return could not be saved: it contains a
//!    non-finite number.'` (a new, user-readable string; a NaN can only
//!    enter the model through a string field read like `"NaN"`).
//! 8. **Store scope.** Dart's `FileReturnStore` (return_store.dart) is
//!    filesystem I/O and is not ported into the pure core; the envelope
//!    contract the store relies on (the same codec on disk, legacy files
//!    migrated on read, corrupt files skipped) is pinned by the ported
//!    tests in `core/tests/return_format_port.rs`.
//! 9. **`ReturnImportCancelled` is picker-side UI** — the user closed the
//!    file picker without choosing a file; there is no text to decode,
//!    so the core's [`ReturnImport`] models only the two text-driven
//!    outcomes (`Ok`, `Failed`). The Dart sealed class remains the app's
//!    full flow (return_format.dart:271-294).
//!
//! # Reader leniencies where the two references disagree (Dart kept)
//!
//! For the record — the places the web twin is LOOSER than Dart (this
//! port keeps the DART behavior, the canonical source):
//! - `version` 0 / 0.5: Dart refuses (`'Unsupported version 0 …'`);
//!   the web guard only checks `> CFR_VERSION`, so 0 would be migrated as
//!   v1 (cfr.ts:149-153).
//! - a v2 filing carrying only the legacy `status` key: the web reader
//!   probes `f.filingStatus ?? f.status` (cfr.ts:159); Dart's v2 path
//!   never looks at `status`, so the filing defaults to single with the
//!   missing-status warning.
//! - dependent counts: Dart reads them number-or-string and TRUNCATES
//!   (`readInt`, return_format.dart:214-215); the web reader accepts
//!   numbers only (`num()`, cfr.ts:106-107 — a string count reads as 0)
//!   and rounds. Pinned the Dart way by the ported tests.
//! - a string `taxYear` `"2025"`: Dart's `readInt` accepts it with NO
//!   warning; the web `num()` reads it as 0 and warns (cfr.ts:165-169).
//!   Pinned the Dart way.
//!
//! (The writer identity also differs between the references — Dart
//! records `'ClearFile 1.0.1'` (return_format.dart:54), the web prototype
//! `'ClearFile prototype 0.2'` (cfr.ts:35); this port records the Dart
//! app's.)

use crate::json::Json;
use crate::{DeductionMethod, Dependent, FilingStatus, TaxReturnInput, W2Entry};

/// A filing map under decode: an insertion-ordered key/value list (the
/// same shape as [`Json::Obj`]'s pairs, kept as a working copy the
/// migration mutates exactly like Dart's `Map<String, dynamic>`.
type JsonMap = Vec<(String, Json)>;

// ---------------------------------------------------------------------------
// The filing model (Dart clearfile/lib/models/tax_return.dart)
// ---------------------------------------------------------------------------

/// Everything one taxpayer's return contains, file-side: the compute
/// input ([`crate::TaxReturnInput`]) plus the serialization-only
/// metadata the Flutter app carries (Dart `TaxReturnData`,
/// tax_return.dart:31-105).
///
/// `created`/`modified` hold the ISO-8601 TEXT (the purity seam — Dart
/// stores a `DateTime`; see the module docs), and `id` is whatever the
/// file carries (Dart's `fromJson` reads it with `readString`, whose
/// fallback is `''` — the constructor's generated-id default is never
/// applied on read: tax_return.dart:58-60 vs 151).
#[derive(Clone, Debug, PartialEq)]
pub struct TaxReturnData {
    /// Return identity (Dart generates `now`-based ids on construction;
    /// a decoded filing just carries what the file had, `''` if none).
    pub id: String,
    /// Human-visible name; `fromJson` defaults to `'Imported return'`
    /// (tax_return.dart:152).
    pub display_name: String,
    /// ISO-8601 creation timestamp text (see [`read_date`]).
    pub created: String,
    /// ISO-8601 last-modified timestamp text (see [`read_date`]).
    pub modified: String,
    /// The compute input — the parity filing shape (ADR-009).
    pub input: TaxReturnInput,
}

impl TaxReturnData {
    /// The flat serialization, field order VERBATIM from
    /// `tax_return.dart:120-148` (`toJson`) — including the legacy
    /// markers `format`/`formatVersion` the model still emits
    /// (return_format.dart:58-62 strips them when building the envelope).
    /// The emission order is the byte-compatibility contract: the
    /// pretty writer preserves it exactly.
    pub fn to_json_map(&self) -> Json {
        Json::Obj(vec![
            ("format".to_owned(), Json::Str("clearfile.return".to_owned())),
            ("formatVersion".to_owned(), Json::Num(1.0)),
            ("id".to_owned(), Json::Str(self.id.clone())),
            ("displayName".to_owned(), Json::Str(self.display_name.clone())),
            ("taxYear".to_owned(), Json::Num(self.input.tax_year as f64)),
            (
                "filingStatus".to_owned(),
                Json::Str(self.input.filing_status.name().to_owned()),
            ),
            (
                "taxpayer65OrOlder".to_owned(),
                Json::Bool(self.input.taxpayer_65_or_older),
            ),
            (
                "spouse65OrOlder".to_owned(),
                Json::Bool(self.input.spouse_65_or_older),
            ),
            ("taxpayerBlind".to_owned(), Json::Bool(self.input.taxpayer_blind)),
            ("spouseBlind".to_owned(), Json::Bool(self.input.spouse_blind)),
            (
                "w2s".to_owned(),
                Json::Arr(self.input.w2s.iter().map(w2_to_json).collect()),
            ),
            ("interestIncome".to_owned(), Json::Num(self.input.interest_income)),
            (
                "ordinaryDividends".to_owned(),
                Json::Num(self.input.ordinary_dividends),
            ),
            (
                "qualifiedDividends".to_owned(),
                Json::Num(self.input.qualified_dividends),
            ),
            (
                "longTermCapitalGains".to_owned(),
                Json::Num(self.input.long_term_capital_gains),
            ),
            ("otherIncome".to_owned(), Json::Num(self.input.other_income)),
            (
                "studentLoanInterest".to_owned(),
                Json::Num(self.input.student_loan_interest),
            ),
            (
                "deductionMethod".to_owned(),
                Json::Str(self.input.deduction_method.name().to_owned()),
            ),
            (
                "stateLocalIncomeOrSalesTax".to_owned(),
                Json::Num(self.input.state_local_income_or_sales_tax),
            ),
            ("realEstateTax".to_owned(), Json::Num(self.input.real_estate_tax)),
            (
                "mortgageInterest".to_owned(),
                Json::Num(self.input.mortgage_interest),
            ),
            ("charitableCash".to_owned(), Json::Num(self.input.charitable_cash)),
            (
                "charitableNonCash".to_owned(),
                Json::Num(self.input.charitable_non_cash),
            ),
            (
                "estimatedPayments".to_owned(),
                Json::Num(self.input.estimated_payments),
            ),
            (
                "dependents".to_owned(),
                Json::Arr(self.input.dependents.iter().map(dependent_to_json).collect()),
            ),
            ("created".to_owned(), Json::Str(self.created.clone())),
            ("modified".to_owned(), Json::Str(self.modified.clone())),
        ])
    }

    /// The tolerant reader, EXACTLY like `tax_return.dart:150-184`
    /// (`fromJson`) over the `json_codec.dart` helpers: unknown
    /// `filingStatus` → `single`, unknown `deductionMethod` → `auto`,
    /// non-map `w2s`/`dependents` entries dropped, every scalar read
    /// number-or-string per [`read_double`]/[`read_int`]/
    /// [`read_string`]/[`read_bool`]/[`read_date`], and unknown keys
    /// ignored. A non-object input behaves as an empty map (Dart's
    /// parameter is typed `Map`, so it cannot construct the case, and
    /// `decode` only calls this with objects).
    pub fn from_json_map(json: &Json) -> TaxReturnData {
        let pairs: &[(String, Json)] = match json {
            Json::Obj(pairs) => pairs,
            _ => &[],
        };
        TaxReturnData {
            id: read_string(pairs, "id", ""),
            display_name: read_string(pairs, "displayName", "Imported return"),
            input: TaxReturnInput {
                tax_year: read_int(pairs, "taxYear", 2025),
                // Dart casts `json['filingStatus'] as String?` — a
                // non-string value is a TypeError there; defaulted here
                // (divergence #3).
                filing_status: match obj_get(pairs, "filingStatus").and_then(Json::as_str) {
                    Some(name) => {
                        FilingStatus::from_json_name(name).unwrap_or(FilingStatus::Single)
                    }
                    None => FilingStatus::Single,
                },
                taxpayer_65_or_older: read_bool(pairs, "taxpayer65OrOlder", false),
                spouse_65_or_older: read_bool(pairs, "spouse65OrOlder", false),
                taxpayer_blind: read_bool(pairs, "taxpayerBlind", false),
                spouse_blind: read_bool(pairs, "spouseBlind", false),
                // Dart: `(json['w2s'] as List? ?? []).whereType<Map>()`
                // (tax_return.dart:159-162) — null/missing is the empty
                // list and non-map entries are dropped; a non-list value
                // is a TypeError there, read as empty here (divergence
                // #3).
                w2s: read_w2_list(pairs),
                interest_income: read_double(pairs, "interestIncome", 0.0),
                ordinary_dividends: read_double(pairs, "ordinaryDividends", 0.0),
                qualified_dividends: read_double(pairs, "qualifiedDividends", 0.0),
                long_term_capital_gains: read_double(pairs, "longTermCapitalGains", 0.0),
                other_income: read_double(pairs, "otherIncome", 0.0),
                student_loan_interest: read_double(pairs, "studentLoanInterest", 0.0),
                deduction_method: match obj_get(pairs, "deductionMethod").and_then(Json::as_str) {
                    Some(name) => {
                        DeductionMethod::from_json_name(name).unwrap_or(DeductionMethod::Auto)
                    }
                    None => DeductionMethod::Auto,
                },
                state_local_income_or_sales_tax: read_double(
                    pairs,
                    "stateLocalIncomeOrSalesTax",
                    0.0,
                ),
                real_estate_tax: read_double(pairs, "realEstateTax", 0.0),
                mortgage_interest: read_double(pairs, "mortgageInterest", 0.0),
                charitable_cash: read_double(pairs, "charitableCash", 0.0),
                charitable_non_cash: read_double(pairs, "charitableNonCash", 0.0),
                estimated_payments: read_double(pairs, "estimatedPayments", 0.0),
                dependents: read_dependent_list(pairs),
            },
            created: read_date(pairs, "created"),
            modified: read_date(pairs, "modified"),
        }
    }
}

/// `W2Entry.toJson` (w2.dart:27-31): employer, wages, withholding.
fn w2_to_json(w: &W2Entry) -> Json {
    Json::Obj(vec![
        ("employer".to_owned(), Json::Str(w.employer.clone())),
        ("wages".to_owned(), Json::Num(w.wages)),
        ("withholding".to_owned(), Json::Num(w.withholding)),
    ])
}

/// `Dependent.toJson` (dependent.dart:48-54).
fn dependent_to_json(d: &Dependent) -> Json {
    Json::Obj(vec![
        ("name".to_owned(), Json::Str(d.name.clone())),
        ("age".to_owned(), Json::Num(d.age as f64)),
        ("relationship".to_owned(), Json::Str(d.relationship.clone())),
        ("qualifyingChild".to_owned(), Json::Bool(d.qualifying_child)),
        (
            "otherDependentCredit".to_owned(),
            Json::Bool(d.other_dependent_credit),
        ),
    ])
}

/// The `w2s` list read: `(json['w2s'] as List? ?? []).whereType<Map>()`
/// mapped through `W2Entry.fromJson` (tax_return.dart:159-162,
/// w2.dart:33-37). See `from_json_map` for the non-list tolerance.
fn read_w2_list(pairs: &[(String, Json)]) -> Vec<W2Entry> {
    match obj_get(pairs, "w2s") {
        Some(Json::Arr(items)) => items
            .iter()
            .filter_map(|w| match w {
                Json::Obj(entry) => Some(entry.as_slice()),
                _ => None, // `.whereType<Map>()` drops non-map entries
            })
            .map(|w| W2Entry {
                employer: read_string(w, "employer", ""),
                wages: read_double(w, "wages", 0.0),
                withholding: read_double(w, "withholding", 0.0),
            })
            .collect(),
        _ => Vec::new(),
    }
}

/// The `dependents` list read: same shape as [`read_w2_list`]
/// (tax_return.dart:178-181, dependent.dart:56-62).
fn read_dependent_list(pairs: &[(String, Json)]) -> Vec<Dependent> {
    match obj_get(pairs, "dependents") {
        Some(Json::Arr(items)) => items
            .iter()
            .filter_map(|d| match d {
                Json::Obj(entry) => Some(entry.as_slice()),
                _ => None,
            })
            .map(|d| Dependent {
                name: read_string(d, "name", ""),
                age: read_int(d, "age", 0),
                relationship: read_string(d, "relationship", ""),
                qualifying_child: read_bool(d, "qualifyingChild", false),
                other_dependent_credit: read_bool(d, "otherDependentCredit", false),
            })
            .collect(),
        _ => Vec::new(),
    }
}

// ---------------------------------------------------------------------------
// The tolerant field readers (Dart clearfile/lib/models/json_codec.dart)
// ---------------------------------------------------------------------------

/// `readDouble` (json_codec.dart:6-15): null/missing → fallback; number →
/// the value; string → Dart's `double.tryParse` semantics (see
/// [`dart_double_try_parse`]) else fallback; anything else → fallback.
fn read_double(pairs: &[(String, Json)], key: &str, fallback: f64) -> f64 {
    match obj_get(pairs, key) {
        Some(Json::Num(n)) => *n,
        Some(Json::Str(s)) => dart_double_try_parse(s).unwrap_or(fallback),
        _ => fallback,
    }
}

/// `readInt` (json_codec.dart:17-26): null/missing → fallback; number →
/// Dart's `num.toInt()` (truncation toward zero; the port saturates
/// outside i64 where Dart's is implementation-defined — unreachable via
/// the fixtures); string → Dart's `int.tryParse` (optional sign + decimal
/// digits ONLY — no whitespace, no `5.0`, out-of-i64-range is rejected)
/// else fallback; anything else → fallback.
fn read_int(pairs: &[(String, Json)], key: &str, fallback: i64) -> i64 {
    match obj_get(pairs, key) {
        Some(Json::Num(n)) if n.is_finite() => n.trunc() as i64,
        // A non-finite number cannot come from parsed JSON; reached only
        // through mutated migration maps, where Dart's toInt() would
        // throw UnsupportedError — defaulted here instead (defensive).
        Some(Json::Num(_)) => fallback,
        Some(Json::Str(s)) => s.parse::<i64>().unwrap_or(fallback),
        _ => fallback,
    }
}

/// `readString` (json_codec.dart:28-32): null/missing → fallback; any
/// other value → Dart's `v.toString()` rendering (see [`dart_to_string`]).
fn read_string(pairs: &[(String, Json)], key: &str, fallback: &str) -> String {
    match obj_get(pairs, key) {
        Some(value) => dart_to_string(value),
        None => fallback.to_owned(),
    }
}

/// `readBool` (json_codec.dart:34-41): null/missing → fallback; bool →
/// it; number → `v != 0` (so `0`/`-0.0` are false, anything else —
/// including NaN — true); string → `v == 'true' || v == '1'`; anything
/// else → fallback.
fn read_bool(pairs: &[(String, Json)], key: &str, fallback: bool) -> bool {
    match obj_get(pairs, key) {
        Some(Json::Bool(b)) => *b,
        Some(Json::Num(n)) => *n != 0.0,
        Some(Json::Str(s)) => s == "true" || s == "1",
        _ => fallback,
    }
}

/// `readDate` (json_codec.dart:43-50), text form: a string Dart's
/// `DateTime.tryParse` accepts is KEPT VERBATIM (the port stores the
/// text; divergence #2 — no re-normalization); everything else (missing,
/// non-string, unparseable) falls back to [`EPOCH_INSTANT_TEXT`]
/// (divergence #1 — Dart's fallback is the local-rendered epoch
/// `DateTime`).
fn read_date(pairs: &[(String, Json)], key: &str) -> String {
    match obj_get(pairs, key) {
        Some(Json::Str(s)) if is_accepted_iso8601_text(s) => s.clone(),
        _ => EPOCH_INSTANT_TEXT.to_owned(),
    }
}

/// The ISO text of the epoch instant — Dart's `readDate` fallback
/// rendered deterministically (divergence #1: Dart stores
/// `DateTime.fromMillisecondsSinceEpoch(0)`, a LOCAL instant whose ISO
/// rendering depends on the machine's timezone; `1970-01-01T00:00:00.000Z`
/// is what it serializes to on a UTC machine, and the shape Dart's own
/// `encode` stamps into `savedAt`).
pub const EPOCH_INSTANT_TEXT: &str = "1970-01-01T00:00:00.000Z";

/// Dart's `v.toString()` rendering — what `readString`, the version
/// guard's `${v}`, and the unrecognized-format marker text all produce:
/// numbers in ECMAScript digits (Dart's `num.toString` matches
/// `Number#toString`; `NaN`/`Infinity` included), booleans as
/// `true`/`false`, strings as-is, and Dart's non-JSON container
/// renderings (`[a, b]`, `{k: v}`).
fn dart_to_string(v: &Json) -> String {
    match v {
        Json::Null => "null".to_owned(),
        Json::Bool(true) => "true".to_owned(),
        Json::Bool(false) => "false".to_owned(),
        Json::Num(n) => {
            if n.is_nan() {
                "NaN".to_owned()
            } else if n.is_infinite() {
                if *n > 0.0 { "Infinity".to_owned() } else { "-Infinity".to_owned() }
            } else {
                // ECMAScript number emission (core/src/json.rs).
                match Json::Num(*n).write() {
                    Ok(text) => text,
                    Err(_) => "NaN".to_owned(), // unreachable for finite values
                }
            }
        }
        Json::Str(s) => s.clone(),
        Json::Arr(items) => {
            let mut out = String::from("[");
            for (i, item) in items.iter().enumerate() {
                if i > 0 {
                    out.push_str(", ");
                }
                out.push_str(&dart_to_string(item));
            }
            out.push(']');
            out
        }
        Json::Obj(pairs) => {
            let mut out = String::from("{");
            for (i, (k, value)) in pairs.iter().enumerate() {
                if i > 0 {
                    out.push_str(", ");
                }
                out.push_str(k);
                out.push_str(": ");
                out.push_str(&dart_to_string(value));
            }
            out.push('}');
            out
        }
    }
}

/// Dart `double.tryParse` acceptance (dart:core `double.parse`):
/// leading/trailing Unicode whitespace is trimmed; then exactly `NaN`,
/// optionally-signed `Infinity`, or a decimal literal — optional `+`/`-`,
/// digits with an optional `.` fraction (`5.` and `.5` are both valid,
/// `.` alone is not), and an optional `e`/`E` exponent with an optional
/// sign and 1+ digits. Everything else (hex, whitespace inside,
/// `1,000`, `0x1p3`, …) is rejected → the caller's fallback.
fn dart_double_try_parse(s: &str) -> Option<f64> {
    let t = s.trim_matches(char::is_whitespace);
    if t == "NaN" {
        return Some(f64::NAN);
    }
    if t == "Infinity" || t == "+Infinity" {
        return Some(f64::INFINITY);
    }
    if t == "-Infinity" {
        return Some(f64::NEG_INFINITY);
    }
    if !is_dart_decimal_literal(t) {
        return None;
    }
    t.parse::<f64>().ok()
}

/// The decimal-literal grammar Dart's `double.parse` accepts after the
/// whitespace trim (everything except the `NaN`/`Infinity` forms).
fn is_dart_decimal_literal(t: &str) -> bool {
    let b = t.as_bytes();
    let mut i = 0;
    if i < b.len() && (b[i] == b'+' || b[i] == b'-') {
        i += 1;
    }
    let mut int_digits = 0;
    while i < b.len() && b[i].is_ascii_digit() {
        i += 1;
        int_digits += 1;
    }
    let mut frac_digits = 0;
    if i < b.len() && b[i] == b'.' {
        i += 1;
        while i < b.len() && b[i].is_ascii_digit() {
            i += 1;
            frac_digits += 1;
        }
    }
    if int_digits + frac_digits == 0 {
        return false; // ".", "+", "-", "e3", …
    }
    if i < b.len() && (b[i] == b'e' || b[i] == b'E') {
        i += 1;
        if i < b.len() && (b[i] == b'+' || b[i] == b'-') {
            i += 1;
        }
        let mut exp_digits = 0;
        while i < b.len() && b[i].is_ascii_digit() {
            i += 1;
            exp_digits += 1;
        }
        if exp_digits == 0 {
            return false; // "1e", "1e+", …
        }
    }
    i == b.len()
}

/// Dart's `int` typing as seen through the f64-only core JSON: a whole
/// finite value inside i64 range is "int" (divergence #4 — the literal
/// `1.0` vs `1` distinction Dart's decoder keeps is unrecoverable here).
fn as_dart_int(v: Option<&Json>) -> Option<i64> {
    match v {
        Some(Json::Num(n)) if n.is_finite() && n.fract() == 0.0 && *n >= -(2.0_f64.powi(63)) && *n < 2.0_f64.powi(63) => {
            Some(*n as i64)
        }
        _ => None,
    }
}

// ---------------------------------------------------------------------------
// Map plumbing (Dart's Map<String, dynamic> over the insertion-ordered
// object pairs: assignment replaces in place, LinkedHashMap-style)
// ---------------------------------------------------------------------------

/// `map[key]` — last value wins at the first position (the same
/// duplicate-key semantics as [`Json::get`]).
fn obj_get<'a>(pairs: &'a [(String, Json)], key: &str) -> Option<&'a Json> {
    pairs.iter().rev().find(|(k, _)| k == key).map(|(_, v)| v)
}

/// `map[key] = value` — an existing key keeps its position (Dart
/// LinkedHashMap assignment), a new key appends.
fn obj_set(pairs: &mut JsonMap, key: &str, value: Json) {
    match pairs.iter_mut().find(|(k, _)| k == key) {
        Some(slot) => slot.1 = value,
        None => pairs.push((key.to_owned(), value)),
    }
}

/// `map.remove(key)` — a no-op when absent.
fn obj_remove(pairs: &mut JsonMap, key: &str) {
    pairs.retain(|(k, _)| k != key);
}

// ---------------------------------------------------------------------------
// The ISO-8601 acceptance (readDate's DateTime.tryParse subset)
// ---------------------------------------------------------------------------

/// The ISO-8601 acceptance used by [`read_date`]: a minimal, documented
/// subset consistent with what Dart's `DateTime.tryParse` accepts for the
/// shapes the ported tests pin (`2020-01-01T00:00:00.000`,
/// `2026-11-15T02:00:00.000Z`) plus the documented Dart forms. Accepted
/// EXACTLY:
///
/// ```text
/// timestamp := date [ 'T' | 't' | ' ' time ] [ zone ]   (zone needs the time)
/// date      := dddd '-' dd '-' dd     (year 0000-9999; month 01-12; day
///                                      valid for the month, leap years incl.)
/// time      := dd ':' dd [ ':' dd [ ('.' | ',') d+ ] ] (hour 00-23,
///                                      minute/second 00-59; the seconds part
///                                      and its fraction are optional)
/// zone      := 'Z' | 'z' | ('+' | '-') dd (':' dd | dd)
///                                      (offset hours 00-23, minutes 00-59)
/// ```
///
/// Rejected (→ the epoch fallback): leading/trailing whitespace, week
/// or ordinal dates, 5-digit years, a bare `±hh` offset (minutes are
/// required), a zone without a time part, out-of-range components
/// (Feb 30, hour 24, minute 60 …), and every non-string value.
/// Accepted text is stored VERBATIM — no UTC conversion (divergence #2).
fn is_accepted_iso8601_text(s: &str) -> bool {
    let b = s.as_bytes();
    let mut i = 0usize;
    // Date: yyyy '-' MM '-' dd (proleptic Gregorian day validation,
    // matching Dart's calendar).
    let year = match take_exact_digits(b, &mut i, 4) {
        Some(v) => v,
        None => return false,
    };
    if !take_byte(b, &mut i, b'-') {
        return false;
    }
    let month = match take_exact_digits(b, &mut i, 2) {
        Some(v) => v,
        None => return false,
    };
    if !take_byte(b, &mut i, b'-') {
        return false;
    }
    let day = match take_exact_digits(b, &mut i, 2) {
        Some(v) => v,
        None => return false,
    };
    if !(1..=12).contains(&month) || day < 1 || day > days_in_month(year, month) {
        return false;
    }
    // Optional time: ('T' | 't' | ' ') HH ':' mm [ ':' ss [ ('.'|',') d+ ] ].
    match b.get(i) {
        Some(&c) if c == b'T' || c == b't' || c == b' ' => i += 1,
        // Date-only: nothing more may follow.
        _ => return i == b.len(),
    }
    let hour = match take_exact_digits(b, &mut i, 2) {
        Some(v) => v,
        None => return false,
    };
    if !take_byte(b, &mut i, b':') {
        return false;
    }
    let minute = match take_exact_digits(b, &mut i, 2) {
        Some(v) => v,
        None => return false,
    };
    if hour > 23 || minute > 59 {
        return false;
    }
    if take_byte(b, &mut i, b':') {
        let second = match take_exact_digits(b, &mut i, 2) {
            Some(v) => v,
            None => return false,
        };
        if second > 59 {
            return false;
        }
        // Fractional seconds: '.' or ',' then 1+ digits (Dart accepts
        // the ISO comma form).
        if matches!(b.get(i), Some(&c) if c == b'.' || c == b',') {
            i += 1;
            if !take_digits_at_least(b, &mut i, 1) {
                return false;
            }
        }
    }
    // Optional zone (only with a time part): Z/z or ±HH:mm / ±HHmm.
    match b.get(i) {
        Some(&c) if c == b'Z' || c == b'z' => i += 1,
        Some(&c) if c == b'+' || c == b'-' => {
            i += 1;
            let zone_hour = match take_exact_digits(b, &mut i, 2) {
                Some(v) => v,
                None => return false,
            };
            if b.get(i) == Some(&b':') {
                i += 1;
            }
            let zone_minute = match take_exact_digits(b, &mut i, 2) {
                Some(v) => v,
                None => return false,
            };
            if zone_hour > 23 || zone_minute > 59 {
                return false;
            }
        }
        _ => {}
    }
    i == b.len()
}

/// Consume exactly `n` ASCII digits, returning their value.
fn take_exact_digits(b: &[u8], i: &mut usize, n: usize) -> Option<u32> {
    let mut value = 0u32;
    for _ in 0..n {
        match b.get(*i) {
            Some(&c) if c.is_ascii_digit() => {
                value = value * 10 + u32::from(c - b'0');
                *i += 1;
            }
            _ => return None,
        }
    }
    Some(value)
}

/// Consume at least `n` ASCII digits (any count above `n` included).
fn take_digits_at_least(b: &[u8], i: &mut usize, n: usize) -> bool {
    let mut count = 0usize;
    while matches!(b.get(*i), Some(&c) if c.is_ascii_digit()) {
        *i += 1;
        count += 1;
    }
    count >= n
}

/// Consume the byte `expected` if it is next.
fn take_byte(b: &[u8], i: &mut usize, expected: u8) -> bool {
    if b.get(*i) == Some(&expected) {
        *i += 1;
        true
    } else {
        false
    }
}

/// Days in `month` of `year` (proleptic Gregorian, like Dart's calendar).
fn days_in_month(year: u32, month: u32) -> u32 {
    match month {
        1 | 3 | 5 | 7 | 8 | 10 | 12 => 31,
        4 | 6 | 9 | 11 => 30,
        2 => {
            if is_gregorian_leap_year(year) {
                29
            } else {
                28
            }
        }
        _ => 0,
    }
}

/// The Gregorian leap rule (divisible by 4, except centuries not
/// divisible by 400).
fn is_gregorian_leap_year(year: u32) -> bool {
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
}

// ---------------------------------------------------------------------------
// The codec (Dart clearfile/lib/io/return_format.dart)
// ---------------------------------------------------------------------------

/// The `.clearfile.json` envelope codec (Dart `ReturnFileCodec`,
/// return_format.dart:40-244).
///
/// ONE envelope on both codebases and both media (the exported/imported
/// file and the autosaved store file):
///
/// ```json
/// {
///   "format": "clearfile-return",
///   "version": 2,
///   "app": "ClearFile 1.0.1",
///   "savedAt": "2026-11-15T...Z",
///   "filing": { "...TaxReturnData fields..." }
/// }
/// ```
///
/// Readers also accept, with migration and warnings: version 1 envelopes
/// (the pre-parity web prototype's `.cfr` shape, migrated with the
/// same conservative mapping the web parser applies) and the legacy
/// flat layout (`format: "clearfile.return"` with the filing fields at
/// the top level, written by the Flutter app through v1.0.1 and by the
/// autosave store until the unification — the same filing model, so
/// the lift is lossless).
pub struct ReturnFileCodec;

impl ReturnFileCodec {
    /// Envelope marker of the unified format (return_format.dart:44).
    pub const FORMAT: &str = "clearfile-return";

    /// Current schema version: 2 is the parity filing shape (ADR-009)
    /// (return_format.dart:48).
    pub const VERSION: i64 = 2;

    /// Marker of the pre-unification flat layout, accepted on read only
    /// (return_format.dart:51).
    pub const LEGACY_FLAT_FORMAT: &str = "clearfile.return";

    /// Writer identity recorded in the envelope (informational)
    /// (return_format.dart:54).
    pub const APP: &str = "ClearFile 1.0.1";

    /// Serializes `filing` as the unified envelope (return_format.dart:
    /// 56-70), pretty-printed with 2-space indent (byte-identical to
    /// Dart's `JsonEncoder.withIndent('  ')` and V8's
    /// `JSON.stringify(x, null, 2)` via [`Json::write_pretty`]).
    ///
    /// Top-level field order VERBATIM: `format`, `version`, `app`,
    /// `savedAt`, `filing`; `filing` is [`TaxReturnData::to_json_map`]
    /// minus the legacy `format`/`formatVersion` markers.
    ///
    /// Purity seam: Dart stamps `DateTime.now().toUtc().toIso8601String()`
    /// itself (return_format.dart:67); the caller owns the instant here
    /// and passes the exact `savedAt` text (written verbatim, never
    /// validated) — see the module docs.
    pub fn encode(filing: &TaxReturnData, saved_at_utc: &str) -> Result<String, ReturnFormatException> {
        // The model's own flat serialization carries its legacy markers;
        // the envelope is the single place the format identity lives now.
        let mut filing_map: JsonMap = match filing.to_json_map() {
            Json::Obj(pairs) => pairs,
            // Defensive: to_json_map always builds an object.
            _ => Vec::new(),
        };
        obj_remove(&mut filing_map, "format");
        obj_remove(&mut filing_map, "formatVersion");
        let envelope = Json::Obj(vec![
            ("format".to_owned(), Json::Str(Self::FORMAT.to_owned())),
            ("version".to_owned(), Json::Num(Self::VERSION as f64)),
            ("app".to_owned(), Json::Str(Self::APP.to_owned())),
            ("savedAt".to_owned(), Json::Str(saved_at_utc.to_owned())),
            ("filing".to_owned(), Json::Obj(filing_map)),
        ]);
        // Fail-closed on non-finite numbers (divergence #7).
        envelope.write_pretty("  ").map_err(|_| {
            ReturnFormatException::new(
                "The return could not be saved: it contains a non-finite number.",
            )
        })
    }

    /// Decodes a ClearFile return file of any accepted vintage
    /// (return_format.dart:77-99). Throws [`ReturnFormatException`] with
    /// a user-readable message on files that are not valid JSON, not
    /// ClearFile returns, or claim an unsupported future version.
    pub fn decode(text: &str) -> Result<DecodedReturnFile, ReturnFormatException> {
        let decoded = match Json::parse(text) {
            Ok(v) => v,
            // Dart catches the decoder's FormatException
            // (return_format.dart:81-83); every parser failure here is
            // the same "not valid JSON" case.
            Err(_) => {
                return Err(ReturnFormatException::new("The file is not valid JSON."));
            }
        };
        let file: &[(String, Json)] = match &decoded {
            Json::Obj(pairs) => pairs,
            _ => {
                return Err(ReturnFormatException::new(
                    "The file does not contain a ClearFile return.",
                ));
            }
        };
        match obj_get(file, "format") {
            Some(Json::Str(marker)) if marker == Self::FORMAT => Self::decode_envelope(file),
            Some(Json::Str(marker)) if marker == Self::LEGACY_FLAT_FORMAT => {
                Self::decode_legacy_flat(file)
            }
            // return_format.dart:95-98: `marker == null ? '(missing)' :
            // marker.toString()`.
            marker => {
                let marker_text = match marker {
                    None | Some(Json::Null) => "(missing)".to_owned(),
                    Some(v) => dart_to_string(v),
                };
                Err(ReturnFormatException::new(format!(
                    "Unrecognized format \"{}\" — expected \"{}\". This is not a ClearFile return.",
                    marker_text,
                    Self::FORMAT
                )))
            }
        }
    }

    /// The `clearfile-return` envelope reader (return_format.dart:103-127,
    /// `_decodeEnvelope`): the version guard (D3 — future files are
    /// refused, never guessed at), the filing payload, and the v1
    /// migration feeding the shared tolerant tail.
    fn decode_envelope(file: &[(String, Json)]) -> Result<DecodedReturnFile, ReturnFormatException> {
        let version_json = obj_get(file, "version");
        // `v is! int || v < 1` (return_format.dart:105) — see
        // `as_dart_int` for the int-typing caveat (divergence #4).
        let version = match as_dart_int(version_json) {
            Some(v) if v >= 1 => v,
            _ => {
                return Err(ReturnFormatException::new(unsupported_version_message(
                    &match version_json {
                        None | Some(Json::Null) => "(missing)".to_owned(),
                        Some(v) => dart_to_string(v),
                    },
                )));
            }
        };
        if version > Self::VERSION {
            // Version guard (D3): future files are refused, never
            // guessed at (return_format.dart:109-112).
            return Err(ReturnFormatException::new(unsupported_version_message(&version.to_string())));
        }
        let mut filing: JsonMap = match obj_get(file, "filing") {
            None | Some(Json::Null) => Vec::new(),
            Some(Json::Obj(pairs)) => pairs.clone(),
            Some(_) => {
                return Err(ReturnFormatException::new("The file has no return payload."));
            }
        };
        let mut warnings: Vec<String> = Vec::new();
        if version == 1 {
            migrate_web_v1(&mut filing, &mut warnings);
        }
        finish(filing, warnings)
    }

    /// The legacy flat layout reader (return_format.dart:131-143,
    /// `_decodeLegacyFlat`): a flat `formatVersion > 1` is refused; the
    /// flat layout wrote the SAME filing model at the top level, so the
    /// migration is a lossless envelope lift with no warnings.
    fn decode_legacy_flat(file: &[(String, Json)]) -> Result<DecodedReturnFile, ReturnFormatException> {
        if let Some(legacy_version) = as_dart_int(obj_get(file, "formatVersion")) {
            if legacy_version > 1 {
                return Err(ReturnFormatException::new(unsupported_version_message(
                    &legacy_version.to_string(),
                )));
            }
        }
        let mut filing: JsonMap = file.to_vec();
        obj_remove(&mut filing, "format");
        obj_remove(&mut filing, "formatVersion");
        finish(filing, Vec::new())
    }
}

/// `'Unsupported version {v} (this build supports up to {VERSION}).'`
/// (return_format.dart:106-107, 111-112, 134-135).
fn unsupported_version_message(rendered: &str) -> String {
    format!(
        "Unsupported version {} (this build supports up to {}).",
        rendered,
        ReturnFileCodec::VERSION
    )
}

/// The shared tolerant tail (return_format.dart:150-165, `_finish`):
/// applies the same defaulting rules (and warnings) the web parser
/// (`src/lib/files/cfr.ts`) applies, so both readers report the same
/// conditions on the same file.
fn finish(mut filing: JsonMap, mut warnings: Vec<String>) -> Result<DecodedReturnFile, ReturnFormatException> {
    let status_known = match obj_get(&filing, "filingStatus") {
        Some(Json::Str(name)) => FilingStatus::from_json_name(name).is_some(),
        _ => false,
    };
    if !status_known {
        warnings.push("Filing status was missing; defaulted to single.".to_owned());
    }
    let year = read_int(&filing, "taxYear", 2025);
    if year != 2025 {
        obj_set(&mut filing, "taxYear", Json::Num(2025.0));
        warnings.push(
            "Tax year was missing or unsupported; defaulted to 2025 (the engine supports TY2025)."
                .to_owned(),
        );
    }
    Ok(DecodedReturnFile {
        filing: TaxReturnData::from_json_map(&Json::Obj(filing)),
        warnings,
    })
}

/// The v1 (pre-parity web shape) migration, mirroring the web parser's
/// `migrateV1` field-for-field (return_format.dart:172-244,
/// `_migrateWebV1`) — including the warning wording, so both engines
/// give the same account of what a migration dropped.
fn migrate_web_v1(o: &mut JsonMap, warnings: &mut Vec<String>) {
    obj_set(o, "taxYear", Json::Num(2025.0));
    warnings.push(
        "Saved with an older prototype: the return was migrated to the current engine model."
            .to_owned(),
    );
    let status = obj_get(o, "status").cloned();
    match &status {
        Some(Json::Str(s)) if s == "mfj" => {
            obj_set(o, "filingStatus", Json::Str("marriedJoint".to_owned()));
        }
        Some(Json::Str(s)) if s == "mfs" => {
            obj_set(o, "filingStatus", Json::Str("marriedSeparate".to_owned()));
        }
        Some(Json::Str(s)) if s == "hoh" => {
            obj_set(o, "filingStatus", Json::Str("headOfHousehold".to_owned()));
        }
        Some(Json::Str(s)) => {
            obj_set(o, "filingStatus", Json::Str(s.clone()));
        }
        _ => {}
    }
    obj_remove(o, "status");
    obj_set(o, "interestIncome", Json::Num(read_double(o, "interest", 0.0)));
    obj_set(o, "ordinaryDividends", Json::Num(read_double(o, "dividends", 0.0)));
    if read_double(o, "adjustments", 0.0) > 0.0 {
        warnings.push(
            "\"Adjustments to income\" had no equivalent in the current model and was dropped — re-enter it as student loan interest if that is what it was."
                .to_owned(),
        );
    }
    obj_remove(o, "interest");
    obj_remove(o, "dividends");
    obj_remove(o, "adjustments");

    let item: JsonMap = match obj_get(o, "itemized") {
        Some(Json::Obj(pairs)) => pairs.clone(),
        _ => Vec::new(),
    };
    obj_set(o, "stateLocalIncomeOrSalesTax", Json::Num(read_double(&item, "taxesPaid", 0.0)));
    obj_set(o, "realEstateTax", Json::Num(0.0));
    obj_set(o, "mortgageInterest", Json::Num(read_double(&item, "mortgageInterest", 0.0)));
    obj_set(o, "charitableCash", Json::Num(read_double(&item, "charity", 0.0)));
    obj_set(o, "charitableNonCash", Json::Num(0.0));
    if read_double(&item, "medical", 0.0) > 0.0 || read_double(&item, "other", 0.0) > 0.0 {
        warnings.push(
            "Medical and \"other\" itemized expenses have no equivalent in the current model and were dropped."
                .to_owned(),
        );
    }
    obj_remove(o, "itemized");

    // The dependent-count bound is 0..100 placeholder rows (the Dart
    // reference's historical clamp, pinned by the shared edge fixture
    // fixtures/migration/v1-web-envelope-edge-clamp.json, D34).
    let kids = read_int(o, "qualifyingChildren", 0).clamp(0, 100);
    let others = read_int(o, "otherDependents", 0).clamp(0, 100);
    obj_remove(o, "qualifyingChildren");
    obj_remove(o, "otherDependents");
    let mut dependents: Vec<Json> = Vec::new();
    for _ in 0..kids {
        dependents.push(Json::Obj(vec![
            ("name".to_owned(), Json::Str(String::new())),
            ("age".to_owned(), Json::Num(0.0)),
            ("relationship".to_owned(), Json::Str(String::new())),
            ("qualifyingChild".to_owned(), Json::Bool(true)),
            ("otherDependentCredit".to_owned(), Json::Bool(false)),
        ]));
    }
    for _ in 0..others {
        dependents.push(Json::Obj(vec![
            ("name".to_owned(), Json::Str(String::new())),
            ("age".to_owned(), Json::Num(0.0)),
            ("relationship".to_owned(), Json::Str(String::new())),
            ("qualifyingChild".to_owned(), Json::Bool(false)),
            ("otherDependentCredit".to_owned(), Json::Bool(true)),
        ]));
    }
    if !dependents.is_empty() {
        warnings.push(
            "Dependent counts were migrated; re-enter their names in the Dependents step."
                .to_owned(),
        );
    }
    obj_set(o, "dependents", Json::Arr(dependents));
}

// ---------------------------------------------------------------------------
// The outcomes (return_format.dart:247-306)
// ---------------------------------------------------------------------------

/// A successfully decoded return file: the filing plus every migration
/// warning the reader owes the user (Dart `DecodedReturnFile`,
/// return_format.dart:249-254).
#[derive(Clone, Debug, PartialEq)]
pub struct DecodedReturnFile {
    pub filing: TaxReturnData,
    pub warnings: Vec<String>,
}

/// Raised by [`ReturnFileCodec::decode`] on files that cannot be read as
/// a ClearFile return. `message` is user-readable and is surfaced in the
/// import dialogs verbatim (Dart `ReturnFormatException`,
/// return_format.dart:259-266).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ReturnFormatException {
    pub message: String,
}

impl ReturnFormatException {
    pub fn new(message: impl Into<String>) -> Self {
        ReturnFormatException {
            message: message.into(),
        }
    }
}

impl std::fmt::Display for ReturnFormatException {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.message)
    }
}

impl std::error::Error for ReturnFormatException {}

/// Outcome of the picker-driven return import (DEBT D1: cancelled,
/// unreadable and wrong-format are distinct outcomes with feedback,
/// never one silent null). Dart's `ReturnImportCancelled` — the user
/// closed the picker without choosing a file — is picker-side UI with
/// no text to decode, so the core's enum models only the two
/// text-driven outcomes (divergence #9).
#[derive(Clone, Debug, PartialEq)]
pub enum ReturnImport {
    /// A return was read; `warnings` carries the migration notes (if any)
    /// (Dart `ReturnImportOk`, return_format.dart:289-294).
    Ok {
        filing: TaxReturnData,
        warnings: Vec<String>,
    },
    /// A file was chosen but could not be read as a ClearFile return;
    /// `reason` is user-readable (Dart `ReturnImportFailed`,
    /// return_format.dart:282-286).
    Failed {
        reason: String,
    },
}

/// Decodes `text` and maps hard failures to the [`ReturnImport`] outcome
/// tree (the picker-independent half of the import flow, unit-testable
/// without a dialog) — Dart `decodeReturnImport`
/// (return_format.dart:299-306).
pub fn decode_return_import(text: &str) -> ReturnImport {
    match ReturnFileCodec::decode(text) {
        Ok(decoded) => ReturnImport::Ok {
            filing: decoded.filing,
            warnings: decoded.warnings,
        },
        Err(e) => ReturnImport::Failed { reason: e.message },
    }
}
