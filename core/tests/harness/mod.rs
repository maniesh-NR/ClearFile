// SPDX-License-Identifier: GPL-3.0-only
//! The N1 session-1 test harness: a STRICT hand-rolled JSON reader, the
//! golden-fixture comparator ported EXACTLY from the Python oracle
//! (`scripts/verify_golden_fixtures.py`), the per-fixture skip map, and
//! the fixture manifest the harness_check ledger join reads.
//!
//! This module lives ONLY under `core/tests/` (I/O is allowed in tests;
//! the library itself must stay pure — no `std::fs`, no env).
//!
//! # The comparator: five rules, ported VERBATIM from the gate + oracle
//!
//! 1. The compared field-set is EXACTLY the fixture's `expected` keys —
//!    no more, no fewer (verify_golden_fixtures.py:319,
//!    `for key, pinned in fixture["expected"].items()`).
//! 2. `deductionMethodUsed` matches by EXACT STRING (the enum name);
//!    it is never compared numerically (verify_golden_fixtures.py:320-325).
//! 3. Every other field compares `|computed − pinned| > tolerance` → FAIL,
//!    `delta == tolerance` → PASS. The comparator is NOT cent-rounded —
//!    cent-quantizing both sides would mask deltas the oracle fails
//!    (ENG-1; the oracle does no rounding, verify_golden_fixtures.py:317-331).
//! 4. `tolerance` is the fixture's own `tolerance` field if present, else
//!    the default `0.005` (16 fixtures use the default; fixture
//!    `01-tax-table-single-25225.json` pins `0.505` for the whole-dollar
//!    Tax Table rows).
//! 5. NaN/infinite computed values FAIL: the check uses
//!    `!(delta <= tolerance)` semantics (`scripts/web_parity_test.mjs:93`),
//!    NEVER `delta > tolerance` — a NaN delta makes `delta > tolerance`
//!    evaluate false, which would silently PASS (ENG-2 fail-closed).
//!    This module implements rule 5 as `delta <= tolerance`, which is the
//!    same predicate with NaN/∞ falling through to FAIL.
//!
//! # The four arithmetic-semantics traps the ENGINE ports obey
//!
//! (mirrored here because the harness pins their observable behavior —
//! the full statement lives in `core/src/engine.rs` and the gate text)
//!
//! (a) Operation ORDER is preserved exactly as `calculator.dart` does it
//!     (f64 non-associativity: the `totalIncome` fold, bracket
//!     accumulation calculator.dart:253-263);
//! (b) the CTC cents-normalize happens BEFORE the $1,000 phase-out
//!     ceiling, exactly as calculator.dart:117-122 — the Python oracle's
//!     `+999` integer idiom (verify_golden_fixtures.py:186-189) is
//!     deliberately NOT ported (it exists only because Decimal is exact);
//! (c) Dart `round()` == Rust [`f64::round`] and Dart `ceil` ==
//!     [`f64::ceil`] (half away from zero / ceiling);
//! (d) Dart `min`/`max` propagate NaN, Rust's ignore it — unreachable via
//!     JSON fixtures (this reader rejects non-finite numbers), noted and
//!     handled by `core/src/engine.rs`'s `dart_min`/`dart_max`.
//!
//! # Skip map (ENG-3 — the honest-subset mechanism)
//!
//! [`skip_map`] maps ALL fixture filenames to
//! [`FixtureStatus::Run`] or [`FixtureStatus::Deferred`]` { reason,
//! feature }`, keyed to INPUT FEATURES (not module lists). Session 1
//! ports `calculator.dart` whole (SLI + SALT + deduction-choice +
//! payments included, ENG-4), so every fixture's input features are
//! covered and all 17 entries are `Run`. The guard test in
//! `fixtures_runner.rs` asserts the map's key set equals the directory's
//! `*.json` set exactly — a new or renamed fixture fails loudly, no
//! silent drift. A deferred fixture (session-2 lane) would carry
//! `#[ignore = "N1 session-2 lane: <reason>"]` and stay green-never-red.

// The harness is compiled separately into EACH test crate that includes it
// (fixtures_runner, fixture_manifest); not every crate uses every item, so
// dead_code would fire spuriously per crate.
#![allow(dead_code)]

use clearfile_core::{
    DeductionMethod, Dependent, FilingStatus, TaxResult, TaxReturnInput, W2Entry,
};
use std::collections::BTreeSet;
use std::fs;
use std::path::{Path, PathBuf};

// ---------------------------------------------------------------------------
// Minimal strict JSON parser (std-only; std has no JSON).
// ---------------------------------------------------------------------------

/// A parsed JSON value. Numbers are stored as `f64`; non-finite numbers
/// (e.g. `1e999` overflowing) are REJECTED at parse time so NaN/∞ can
/// never enter the pipeline through fixtures (comparator rule 5's first
/// line of defense).
#[derive(Clone, Debug, PartialEq)]
pub enum Json {
    Null,
    Bool(bool),
    Num(f64),
    Str(String),
    Arr(Vec<Json>),
    /// Insertion-ordered object; duplicate keys are a parse ERROR.
    Obj(Vec<(String, Json)>),
}

const MAX_DEPTH: u32 = 64;

/// Parse `text` as one JSON document (trailing content is an error).
pub fn json_parse(text: &str) -> Result<Json, String> {
    let mut p = JsonParser {
        bytes: text.as_bytes(),
        pos: 0,
        depth: 0,
    };
    p.skip_ws();
    let v = p.parse_value()?;
    p.skip_ws();
    if p.pos != p.bytes.len() {
        return Err(format!("trailing characters at byte {}", p.pos));
    }
    Ok(v)
}

struct JsonParser<'a> {
    bytes: &'a [u8],
    pos: usize,
    depth: u32,
}

impl JsonParser<'_> {
    fn skip_ws(&mut self) {
        while let Some(&b) = self.bytes.get(self.pos) {
            match b {
                b' ' | b'\t' | b'\n' | b'\r' => self.pos += 1,
                _ => break,
            }
        }
    }

    fn peek(&self) -> Option<u8> {
        self.bytes.get(self.pos).copied()
    }

    fn err<T>(&self, msg: &str) -> Result<T, String> {
        Err(format!("{} (at byte {})", msg, self.pos))
    }

    fn parse_value(&mut self) -> Result<Json, String> {
        if self.depth >= MAX_DEPTH {
            return self.err("nesting too deep");
        }
        match self.peek() {
            None => self.err("unexpected end of input"),
            Some(b'{') => {
                self.depth += 1;
                let v = self.parse_object();
                self.depth -= 1;
                v
            }
            Some(b'[') => {
                self.depth += 1;
                let v = self.parse_array();
                self.depth -= 1;
                v
            }
            Some(b'"') => self.parse_string().map(Json::Str),
            Some(b't') => self.parse_literal("true", Json::Bool(true)),
            Some(b'f') => self.parse_literal("false", Json::Bool(false)),
            Some(b'n') => self.parse_literal("null", Json::Null),
            Some(b'-') | Some(b'0'..=b'9') => self.parse_number().map(Json::Num),
            Some(c) => self.err(&format!("unexpected character '{}'", c as char)),
        }
    }

    fn parse_literal(&mut self, lit: &str, value: Json) -> Result<Json, String> {
        if self.bytes[self.pos..].starts_with(lit.as_bytes()) {
            self.pos += lit.len();
            Ok(value)
        } else {
            self.err(&format!("invalid literal (expected '{}')", lit))
        }
    }

    fn parse_object(&mut self) -> Result<Json, String> {
        self.pos += 1; // '{'
        let mut entries: Vec<(String, Json)> = Vec::new();
        self.skip_ws();
        if self.peek() == Some(b'}') {
            self.pos += 1;
            return Ok(Json::Obj(entries));
        }
        loop {
            self.skip_ws();
            if self.peek() != Some(b'"') {
                return self.err("expected object key string");
            }
            let key = self.parse_string()?;
            self.skip_ws();
            if self.peek() != Some(b':') {
                return self.err("expected ':' after object key");
            }
            self.pos += 1;
            self.skip_ws();
            let value = self.parse_value()?;
            if entries.iter().any(|(k, _)| *k == key) {
                return self.err(&format!("duplicate object key '{}'", key));
            }
            entries.push((key, value));
            self.skip_ws();
            match self.peek() {
                Some(b',') => {
                    self.pos += 1;
                }
                Some(b'}') => {
                    self.pos += 1;
                    return Ok(Json::Obj(entries));
                }
                _ => return self.err("expected ',' or '}' in object"),
            }
        }
    }

    fn parse_array(&mut self) -> Result<Json, String> {
        self.pos += 1; // '['
        let mut items = Vec::new();
        self.skip_ws();
        if self.peek() == Some(b']') {
            self.pos += 1;
            return Ok(Json::Arr(items));
        }
        loop {
            self.skip_ws();
            items.push(self.parse_value()?);
            self.skip_ws();
            match self.peek() {
                Some(b',') => {
                    self.pos += 1;
                }
                Some(b']') => {
                    self.pos += 1;
                    return Ok(Json::Arr(items));
                }
                _ => return self.err("expected ',' or ']' in array"),
            }
        }
    }

    fn parse_string(&mut self) -> Result<String, String> {
        self.pos += 1; // opening '"'
        let mut out = String::new();
        let mut segment_start = self.pos;
        loop {
            match self.peek() {
                None => return self.err("unterminated string"),
                Some(b'"') => {
                    out.push_str(&self.utf8_segment(segment_start, self.pos)?);
                    self.pos += 1;
                    return Ok(out);
                }
                Some(b'\\') => {
                    out.push_str(&self.utf8_segment(segment_start, self.pos)?);
                    self.pos += 1;
                    let esc = match self.peek() {
                        Some(c) => c,
                        None => return self.err("unterminated escape"),
                    };
                    self.pos += 1;
                    match esc {
                        b'"' => out.push('"'),
                        b'\\' => out.push('\\'),
                        b'/' => out.push('/'),
                        b'b' => out.push('\u{0008}'),
                        b'f' => out.push('\u{000C}'),
                        b'n' => out.push('\n'),
                        b'r' => out.push('\r'),
                        b't' => out.push('\t'),
                        b'u' => {
                            let cp = self.parse_unicode_escape()?;
                            if (0xD800..=0xDBFF).contains(&cp) {
                                // High surrogate: require an adjacent low surrogate.
                                if self.bytes.get(self.pos) == Some(&b'\\')
                                    && self.bytes.get(self.pos + 1) == Some(&b'u')
                                {
                                    self.pos += 2;
                                    let lo = self.parse_unicode_escape()?;
                                    if (0xDC00..=0xDFFF).contains(&lo) {
                                        let combined =
                                            0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00);
                                        out.push(
                                            char::from_u32(combined)
                                                .ok_or("invalid surrogate pair")?,
                                        );
                                    } else {
                                        return self.err("invalid low surrogate");
                                    }
                                } else {
                                    return self.err("lone high surrogate");
                                }
                            } else if (0xDC00..=0xDFFF).contains(&cp) {
                                return self.err("lone low surrogate");
                            } else {
                                out.push(char::from_u32(cp).ok_or("invalid \\u escape")?);
                            }
                        }
                        _ => return self.err(&format!("invalid escape '\\{}'", esc as char)),
                    }
                    segment_start = self.pos;
                }
                Some(c) if c < 0x20 => {
                    return self.err(&format!(
                        "unescaped control character 0x{:02x} in string",
                        c
                    ));
                }
                Some(_) => {
                    // Multi-byte UTF-8 continuation bytes (>= 0x80) pass through.
                    self.pos += 1;
                }
            }
        }
    }

    fn utf8_segment(&self, start: usize, end: usize) -> Result<String, String> {
        std::str::from_utf8(&self.bytes[start..end])
            .map(str::to_owned)
            .map_err(|_| "invalid UTF-8 in string".to_owned())
    }

    fn parse_unicode_escape(&mut self) -> Result<u32, String> {
        let mut cp: u32 = 0;
        for _ in 0..4 {
            let c = match self.peek() {
                Some(c) if c.is_ascii_hexdigit() => c,
                _ => return self.err("invalid \\u escape (need 4 hex digits)"),
            };
            self.pos += 1;
            let digit = (c as char).to_digit(16).expect("hexdigit checked");
            cp = cp * 16 + digit;
        }
        Ok(cp)
    }

    /// Strict JSON number grammar: `-? (0 | [1-9][0-9]*) (\.[0-9]+)?
    /// ([eE][+-]?[0-9]+)?`, then `f64` parse, then REJECT non-finite
    /// results (fail-closed at parse time).
    fn parse_number(&mut self) -> Result<f64, String> {
        let start = self.pos;
        if self.peek() == Some(b'-') {
            self.pos += 1;
        }
        match self.peek() {
            Some(b'0') => {
                self.pos += 1;
            }
            Some(c) if c.is_ascii_digit() => {
                while matches!(self.peek(), Some(c) if c.is_ascii_digit()) {
                    self.pos += 1;
                }
            }
            _ => return self.err("invalid number"),
        }
        if self.peek() == Some(b'.') {
            self.pos += 1;
            if !matches!(self.peek(), Some(c) if c.is_ascii_digit()) {
                return self.err("invalid number fraction");
            }
            while matches!(self.peek(), Some(c) if c.is_ascii_digit()) {
                self.pos += 1;
            }
        }
        if matches!(self.peek(), Some(b'e') | Some(b'E')) {
            self.pos += 1;
            if matches!(self.peek(), Some(b'+') | Some(b'-')) {
                self.pos += 1;
            }
            if !matches!(self.peek(), Some(c) if c.is_ascii_digit()) {
                return self.err("invalid number exponent");
            }
            while matches!(self.peek(), Some(c) if c.is_ascii_digit()) {
                self.pos += 1;
            }
        }
        let text = std::str::from_utf8(&self.bytes[start..self.pos]).expect("ascii slice");
        let n: f64 = text
            .parse()
            .map_err(|_| format!("invalid number '{}'", text))?;
        if !n.is_finite() {
            return Err(format!("number '{}' is not finite (JSON cannot carry NaN/∞)", text));
        }
        Ok(n)
    }
}

// ---------------------------------------------------------------------------
// JSON accessors with named-field error messages.
// ---------------------------------------------------------------------------

impl Json {
    pub fn get(&self, key: &str) -> Option<&Json> {
        match self {
            Json::Obj(entries) => entries.iter().find(|(k, _)| k == key).map(|(_, v)| v),
            _ => None,
        }
    }

    pub fn as_obj(&self, ctx: &str) -> Result<&Vec<(String, Json)>, String> {
        match self {
            Json::Obj(entries) => Ok(entries),
            other => Err(format!("{}: expected a JSON object, got {}", ctx, kind(other))),
        }
    }

    pub fn as_arr(&self, ctx: &str) -> Result<&[Json], String> {
        match self {
            Json::Arr(items) => Ok(items),
            other => Err(format!("{}: expected a JSON array, got {}", ctx, kind(other))),
        }
    }

    pub fn as_f64(&self, ctx: &str) -> Result<f64, String> {
        match self {
            Json::Num(n) => Ok(*n),
            other => Err(format!("{}: expected a number, got {}", ctx, kind(other))),
        }
    }

    pub fn as_bool(&self, ctx: &str) -> Result<bool, String> {
        match self {
            Json::Bool(b) => Ok(*b),
            other => Err(format!("{}: expected a boolean, got {}", ctx, kind(other))),
        }
    }

    pub fn as_str(&self, ctx: &str) -> Result<&str, String> {
        match self {
            Json::Str(s) => Ok(s),
            other => Err(format!("{}: expected a string, got {}", ctx, kind(other))),
        }
    }
}

fn kind(v: &Json) -> &'static str {
    match v {
        Json::Null => "null",
        Json::Bool(_) => "a boolean",
        Json::Num(_) => "a number",
        Json::Str(_) => "a string",
        Json::Arr(_) => "an array",
        Json::Obj(_) => "an object",
    }
}

// ---------------------------------------------------------------------------
// STRICT fixture-input reader (ENG-7): errors on missing or misspelled
// input fields with named-field error messages — unlike the Dart loader
// (`json_codec.dart:6-41` + `tax_return.dart:150-184`), which defaults
// every field silently (unknown status → `single`, unknown method →
// `auto`) and therefore cannot detect schema drift.
// ---------------------------------------------------------------------------

/// The exact input schema shared by all 17 golden fixtures (each fixture's
/// `input` object carries ALL of these keys). Both lists are the same set:
/// every field is required, and every key not in the set is rejected.
pub const REQUIRED_INPUT_FIELDS: &[&str] = &[
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
];

const W2_REQUIRED_FIELDS: &[&str] = &["employer", "wages", "withholding"];
const DEPENDENT_REQUIRED_FIELDS: &[&str] = &[
    "name",
    "age",
    "relationship",
    "qualifyingChild",
    "otherDependentCredit",
];

fn integral_f64(value: f64, ctx: &str) -> Result<i64, String> {
    if !value.is_finite() || value.fract() != 0.0 || value < i64::MIN as f64 || value > i64::MAX as f64 {
        return Err(format!("{}: expected an integer, got {}", ctx, value));
    }
    Ok(value as i64)
}

fn check_schema(
    obj: &Vec<(String, Json)>,
    required: &[&str],
    ctx: &str,
) -> Result<(), String> {
    // Unknown keys first: a MISSPELLED field (e.g. `ordinaryDividendz`)
    // both removes a required key and adds an unknown one, and the unknown-
    // key message names the actual typo, which is the more useful error.
    for (k, _) in obj {
        if !required.contains(&k.as_str()) {
            return Err(format!(
                "{}: unknown field '{}' (misspelled, or schema drift)",
                ctx, k
            ));
        }
    }
    for field in required {
        if obj.iter().all(|(k, _)| k != field) {
            return Err(format!(
                "{}: missing required field '{}' (the Dart loader would silently default it; this reader errors — ENG-7)",
                ctx, field
            ));
        }
    }
    Ok(())
}

fn parse_w2(entry: &Json, ctx: &str) -> Result<W2Entry, String> {
    let obj = entry.as_obj(ctx)?;
    check_schema(obj, W2_REQUIRED_FIELDS, ctx)?;
    let get = |key: &str| obj.iter().find(|(k, _)| k == key).map(|(_, v)| v);
    Ok(W2Entry {
        employer: get("employer")
            .ok_or_else(|| format!("{}: missing 'employer'", ctx))?
            .as_str(&format!("{}.employer", ctx))?
            .to_owned(),
        wages: get("wages")
            .ok_or_else(|| format!("{}: missing 'wages'", ctx))?
            .as_f64(&format!("{}.wages", ctx))?,
        withholding: get("withholding")
            .ok_or_else(|| format!("{}: missing 'withholding'", ctx))?
            .as_f64(&format!("{}.withholding", ctx))?,
    })
}

fn parse_dependent(entry: &Json, ctx: &str) -> Result<Dependent, String> {
    let obj = entry.as_obj(ctx)?;
    check_schema(obj, DEPENDENT_REQUIRED_FIELDS, ctx)?;
    let get = |key: &str| obj.iter().find(|(k, _)| k == key).map(|(_, v)| v);
    Ok(Dependent {
        name: get("name")
            .ok_or_else(|| format!("{}: missing 'name'", ctx))?
            .as_str(&format!("{}.name", ctx))?
            .to_owned(),
        age: integral_f64(
            get("age")
                .ok_or_else(|| format!("{}: missing 'age'", ctx))?
                .as_f64(&format!("{}.age", ctx))?,
            &format!("{}.age", ctx),
        )?,
        relationship: get("relationship")
            .ok_or_else(|| format!("{}: missing 'relationship'", ctx))?
            .as_str(&format!("{}.relationship", ctx))?
            .to_owned(),
        qualifying_child: get("qualifyingChild")
            .ok_or_else(|| format!("{}: missing 'qualifyingChild'", ctx))?
            .as_bool(&format!("{}.qualifyingChild", ctx))?,
        other_dependent_credit: get("otherDependentCredit")
            .ok_or_else(|| format!("{}: missing 'otherDependentCredit'", ctx))?
            .as_bool(&format!("{}.otherDependentCredit", ctx))?,
    })
}

fn num_field(obj: &Vec<(String, Json)>, key: &str) -> Result<f64, String> {
    let ctx = format!("input.{}", key);
    obj.iter()
        .find(|(k, _)| k == key)
        .ok_or_else(|| format!("input: missing required field '{}'", key))?
        .1
        .as_f64(&ctx)
}

fn bool_field(obj: &Vec<(String, Json)>, key: &str) -> Result<bool, String> {
    let ctx = format!("input.{}", key);
    obj.iter()
        .find(|(k, _)| k == key)
        .ok_or_else(|| format!("input: missing required field '{}'", key))?
        .1
        .as_bool(&ctx)
}

/// Strict parse of a fixture `input` object into the engine's input model.
/// Missing required fields, unknown (misspelled) fields, wrong-typed
/// values, unknown enum names, and non-finite numbers all error with the
/// field named.
pub fn parse_input(input: &Json) -> Result<TaxReturnInput, String> {
    let obj = input.as_obj("input")?;
    check_schema(obj, REQUIRED_INPUT_FIELDS, "input")?;
    let get = |key: &str| obj.iter().find(|(k, _)| k == key).map(|(_, v)| v);

    let status_name = get("filingStatus")
        .ok_or_else(|| "input: missing required field 'filingStatus'".to_owned())?
        .as_str("input.filingStatus")?;
    let filing_status = FilingStatus::from_json_name(status_name).ok_or_else(|| {
        format!(
            "input.filingStatus: unknown filing status '{}' (valid: single, marriedJoint, marriedSeparate, headOfHousehold, survivingSpouse; the Dart loader silently defaults unknown names to 'single' — this reader errors)",
            status_name
        )
    })?;

    let method_name = get("deductionMethod")
        .ok_or_else(|| "input: missing required field 'deductionMethod'".to_owned())?
        .as_str("input.deductionMethod")?;
    let deduction_method = DeductionMethod::from_json_name(method_name).ok_or_else(|| {
        format!(
            "input.deductionMethod: unknown deduction method '{}' (valid: auto, standard, itemized; the Dart loader silently defaults unknown names to 'auto' — this reader errors)",
            method_name
        )
    })?;

    let w2s_json = get("w2s")
        .ok_or_else(|| "input: missing required field 'w2s'".to_owned())?
        .as_arr("input.w2s")?;
    let mut w2s = Vec::with_capacity(w2s_json.len());
    for (i, entry) in w2s_json.iter().enumerate() {
        w2s.push(parse_w2(entry, &format!("input.w2s[{}]", i))?);
    }

    let deps_json = get("dependents")
        .ok_or_else(|| "input: missing required field 'dependents'".to_owned())?
        .as_arr("input.dependents")?;
    let mut dependents = Vec::with_capacity(deps_json.len());
    for (i, entry) in deps_json.iter().enumerate() {
        dependents.push(parse_dependent(entry, &format!("input.dependents[{}]", i))?);
    }

    Ok(TaxReturnInput {
        tax_year: integral_f64(
            get("taxYear")
                .ok_or_else(|| "input: missing required field 'taxYear'".to_owned())?
                .as_f64("input.taxYear")?,
            "input.taxYear",
        )?,
        filing_status,
        taxpayer_65_or_older: bool_field(obj, "taxpayer65OrOlder")?,
        spouse_65_or_older: bool_field(obj, "spouse65OrOlder")?,
        taxpayer_blind: bool_field(obj, "taxpayerBlind")?,
        spouse_blind: bool_field(obj, "spouseBlind")?,
        w2s,
        interest_income: num_field(obj, "interestIncome")?,
        ordinary_dividends: num_field(obj, "ordinaryDividends")?,
        qualified_dividends: num_field(obj, "qualifiedDividends")?,
        long_term_capital_gains: num_field(obj, "longTermCapitalGains")?,
        other_income: num_field(obj, "otherIncome")?,
        student_loan_interest: num_field(obj, "studentLoanInterest")?,
        deduction_method,
        state_local_income_or_sales_tax: num_field(obj, "stateLocalIncomeOrSalesTax")?,
        real_estate_tax: num_field(obj, "realEstateTax")?,
        mortgage_interest: num_field(obj, "mortgageInterest")?,
        charitable_cash: num_field(obj, "charitableCash")?,
        charitable_non_cash: num_field(obj, "charitableNonCash")?,
        estimated_payments: num_field(obj, "estimatedPayments")?,
        dependents,
    })
}

// ---------------------------------------------------------------------------
// Fixture loading (I/O lives ONLY here and in the test functions).
// ---------------------------------------------------------------------------

/// The comparator's default tolerance (comparator rule 4).
pub const DEFAULT_TOLERANCE: f64 = 0.005;

/// A loaded golden fixture.
pub struct Fixture {
    /// Filename inside `fixtures/tax/`.
    pub file: String,
    /// The fixture's `name` field (falls back to the filename, as the
    /// oracle does).
    pub name: String,
    pub input: TaxReturnInput,
    /// The `expected` object's entries, in file order (comparator rule 1:
    /// the compared field-set is exactly this).
    pub expected: Vec<(String, Json)>,
    /// Comparator rule 4: the fixture's own tolerance, else
    /// [`DEFAULT_TOLERANCE`].
    pub tolerance: f64,
}

/// `../fixtures/tax` relative to the crate — resolved from
/// `CARGO_MANIFEST_DIR` so the suite is CWD-independent (the STATE quirk
/// 16 analog: the Dart suite resolves `../fixtures/tax` from its package
/// dir too).
pub fn fixtures_dir() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .expect("crate dir has a parent")
        .join("fixtures")
        .join("tax")
}

/// The directory's `*.json` filenames, sorted. Hidden files and
/// non-`.json` entries are ignored (same enumeration the oracle does).
pub fn fixture_files() -> Vec<String> {
    let mut names: Vec<String> = fs::read_dir(fixtures_dir())
        .unwrap_or_else(|e| panic!("cannot read fixtures dir {:?}: {}", fixtures_dir(), e))
        .filter_map(|e| e.ok())
        .filter(|e| e.file_type().map(|t| t.is_file()).unwrap_or(false))
        .map(|e| e.file_name().to_string_lossy().into_owned())
        .filter(|n| n.ends_with(".json"))
        .collect();
    names.sort();
    names
}

/// Parse the fixture-level `tolerance` (rule 4): the fixture's own value
/// if present (must be a number), else [`DEFAULT_TOLERANCE`].
pub fn parse_tolerance(root: &Json) -> Result<f64, String> {
    match root.get("tolerance") {
        None => Ok(DEFAULT_TOLERANCE),
        Some(v) => v.as_f64("tolerance"),
    }
}

/// Read + strictly parse one fixture file.
pub fn load_fixture(file: &str) -> Result<Fixture, String> {
    let path = fixtures_dir().join(file);
    let text = fs::read_to_string(&path).map_err(|e| format!("{}: read error: {}", file, e))?;
    let root = json_parse(&text).map_err(|e| format!("{}: invalid JSON: {}", file, e))?;

    let input_json = root
        .get("input")
        .ok_or_else(|| format!("{}: missing required field 'input'", file))?;
    let expected_json = root
        .get("expected")
        .ok_or_else(|| format!("{}: missing required field 'expected'", file))?
        .as_obj(&format!("{}: expected", file))?
        .clone();

    Ok(Fixture {
        file: file.to_owned(),
        name: match root.get("name") {
            Some(Json::Str(s)) => s.clone(),
            _ => file.to_owned(),
        },
        input: parse_input(input_json).map_err(|e| format!("{}: {}", file, e))?,
        expected: expected_json,
        tolerance: parse_tolerance(&root).map_err(|e| format!("{}: {}", file, e))?,
    })
}

// ---------------------------------------------------------------------------
// Comparator (ported EXACTLY from verify_golden_fixtures.py:317-331).
// ---------------------------------------------------------------------------

/// Comparator rules 3 + 5, fail-closed. `delta <= tolerance` — so
/// `delta == tolerance` PASSES (rule 3, NOT `>`), and NaN/∞ deltas FAIL
/// (rule 5: NaN comparisons are false, so a NaN computed value can never
/// pass; equivalent to web_parity_test.mjs's `!(delta <= tolerance)`).
pub fn within_tolerance(computed: f64, pinned: f64, tolerance: f64) -> bool {
    let delta = (computed - pinned).abs();
    delta <= tolerance
}

/// The golden fixture's camelCase expected-key → result-field mapping
/// (the mirror of the Dart suite's `readField` switch,
/// golden_fixtures_test.dart:30-86). `deductionMethodUsed` is handled
/// separately by [`compare`] as an exact-string field (rule 2).
pub fn result_field(result: &TaxResult, key: &str) -> Option<f64> {
    match key {
        "totalIncome" => Some(result.total_income),
        "studentLoanDeduction" => Some(result.student_loan_deduction),
        "agi" => Some(result.agi),
        "basicStandardDeduction" => Some(result.basic_standard_deduction),
        "additionalStandardDeduction" => Some(result.additional_standard_deduction),
        "seniorDeduction" => Some(result.senior_deduction),
        "standardDeductionTotal" => Some(result.standard_deduction_total),
        "saltPaid" => Some(result.salt_paid),
        "saltCap" => Some(result.salt_cap),
        "saltAllowed" => Some(result.salt_allowed),
        "itemizedDeductionTotal" => Some(result.itemized_deduction_total),
        "deductionUsed" => Some(result.deduction_used),
        "taxableIncome" => Some(result.taxable_income),
        "ordinaryTax" => Some(result.ordinary_tax),
        "preferentialIncome" => Some(result.preferential_income),
        "preferentialTax" => Some(result.preferential_tax),
        "niit" => Some(result.niit),
        "nonRefundableCredits" => Some(result.non_refundable_credits),
        "refundableCredits" => Some(result.refundable_credits),
        "totalTax" => Some(result.total_tax),
        "totalPayments" => Some(result.total_payments),
        "refund" => Some(result.refund),
        "amountOwed" => Some(result.amount_owed),
        "effectiveRate" => Some(result.effective_rate),
        "marginalRate" => Some(result.marginal_rate),
        "qualifyingChildren" => Some(result.qualifying_children as f64),
        _ => None,
    }
}

/// Compare a computed [`TaxResult`] against one fixture's `expected`
/// object. Returns the list of field failures (empty = fixture PASSES).
/// Implements all five comparator rules (see the module doc-comment).
pub fn compare(fixture: &Fixture, result: &TaxResult) -> Vec<String> {
    let mut failures = Vec::new();
    for (key, pinned) in &fixture.expected {
        if key == "deductionMethodUsed" {
            // Rule 2: exact string on the enum name, never numeric.
            match pinned {
                Json::Str(pinned_name) => {
                    let computed_name = result.deduction_method_used.name();
                    if computed_name != pinned_name {
                        failures.push(format!(
                            "deductionMethodUsed: engine={} pinned={}",
                            computed_name, pinned_name
                        ));
                    }
                }
                other => failures.push(format!(
                    "deductionMethodUsed: pinned value must be a string, got {}",
                    kind(other)
                )),
            }
            continue;
        }
        let pinned_num = match pinned {
            Json::Num(n) => *n,
            other => {
                failures.push(format!("{}: pinned value must be a number, got {}", key, kind(other)));
                continue;
            }
        };
        let computed = match result_field(result, key) {
            Some(v) => v,
            None => {
                // Field-set drift: the fixture pins a field the engine does
                // not produce. Fail loudly — never approximate (honesty).
                failures.push(format!(
                    "{}: not a TaxResult field (fixture pins a field the engine does not produce)",
                    key
                ));
                continue;
            }
        };
        if !within_tolerance(computed, pinned_num, fixture.tolerance) {
            failures.push(format!(
                "{}: engine={} pinned={} delta={} tol={}",
                key,
                computed,
                pinned_num,
                (computed - pinned_num).abs(),
                fixture.tolerance
            ));
        }
    }
    failures
}

/// Load one fixture, run the TY2025 engine, compare, and panic on any
/// failure (the body every per-fixture `#[test]` calls).
pub fn run_fixture(file: &str) {
    let fixture = load_fixture(file)
        .unwrap_or_else(|e| panic!("{}: fixture failed to load: {}", file, e));
    let result = clearfile_core::compute_ty2025(&fixture.input);
    let failures = compare(&fixture, &result);
    assert!(
        failures.is_empty(),
        "{} ({}): {} field failure(s):\n  {}",
        fixture.file,
        fixture.name,
        failures.len(),
        failures.join("\n  ")
    );
}

// ---------------------------------------------------------------------------
// Per-fixture skip map (ENG-3) + manifest (PROD-3).
// ---------------------------------------------------------------------------

/// Status of one fixture in the session-1 honest subset.
///
/// `Deferred` entries must be keyed to INPUT FEATURES not ported (never a
/// module list), carry a human `reason`, and surface as
/// `#[ignore = "N1 session-2 lane: <reason>"]` on that fixture's test.
#[derive(Clone, Debug, PartialEq)]
pub enum FixtureStatus {
    /// The engine covers every input feature the fixture exercises; its
    /// test runs and must be green.
    Run,
    /// The fixture exercises input features session 1 did not port; its
    /// test is `#[ignore]`d with the reason and runs in the session-2 lane.
    Deferred {
        reason: &'static str,
        /// The named input feature waiting on session 2 (e.g.
        /// "dependents-based credits beyond CTC/ODC").
        feature: &'static str,
    },
}

/// All fixture filenames (the skip map's keys). The guard test asserts
/// this set equals the directory's `*.json` set exactly.
///
/// Per-fixture feature census (the input features each fixture exercises,
/// all of which session 1 ports by taking `calculator.dart` whole):
/// - 00 zero-income: degenerate zero case + the `agi > 0` effective-rate guard.
/// - 01/02 Tax Table whole-dollar rows (tolerance 0.505 on 01).
/// - 03/04/05 QDI/LTCG stacking incl. 20% band + NIIT + the MFS $300,000 15% cap.
/// - 06 NIIT MFS $125,000 threshold.
/// - 07/08/09 OBBBA senior deduction incl. phase-out, MFS ineligibility,
///   aged/blind additions.
/// - 10/11 SALT phase-down/floor + itemized-vs-standard choice +
///   `deductionMethodUsed`/`saltCap`/`saltAllowed`/`saltPaid` pins.
/// - 12/13 Schedule 8812 phase-out with next-$1,000 rounding + combined
///   CTC+ODC floor + ODC (`qualifyingChildren` pins).
/// - 14 refundable ACTC (earned-income floor) + refund pin.
/// - 15 student-loan-interest deduction + phase-out (`studentLoanDeduction` pin).
/// - 16 qualifying surviving spouse mapped thresholds (QSS CTC start,
///   QSS brackets, senior deduction for QSS).
pub const FIXTURE_FILES: &[&str] = &[
    "00-zero-income.json",
    "01-tax-table-single-25225.json",
    "02-tax-table-example-mjf-25325.json",
    "03-qdi-stacking-single.json",
    "04-qdi-20pct-and-niit-single.json",
    "05-qdi-mfs-fifteencap-300000.json",
    "06-niit-mfs-threshold-125000.json",
    "07-senior-single-phaseout.json",
    "08-senior-mjs-both-65-phaseout.json",
    "09-senior-mfs-ineligible.json",
    "10-salt-phase-down-mjs.json",
    "11-salt-mfs-floor.json",
    "12-ctc-phaseout-rounding-mjs.json",
    "13-ctc-phaseout-combined-hoh.json",
    "14-actc-refundable-single.json",
    "15-sli-phaseout-single.json",
    "16-surviving-spouse-qss-mapped-thresholds.json",
];

/// The per-fixture skip map: ALL 17 filenames, each `Run` or
/// `Deferred { reason, feature }`.
///
/// Session-1 disposition: `calculator.dart` is ported WHOLE (SLI + SALT +
/// deduction-choice + payments included, gate ENG-4), so every fixture's
/// input features are ported — all 17 entries are [`FixtureStatus::Run`].
/// There are NO honest deferrals: no fixture pins a field the ported
/// engine does not compute. If a later fixture exercises genuinely
/// unported features, its entry becomes `Deferred` here, its test gains
/// `#[ignore = "N1 session-2 lane: <reason>"]`, and the manifest line
/// below flips to `deferred <feature>: <reason>`.
pub fn skip_map() -> Vec<(&'static str, FixtureStatus)> {
    FIXTURE_FILES.iter().map(|f| (*f, FixtureStatus::Run)).collect()
}

/// The manifest the harness_check ledger join reads: plain
/// `"filename status reason"` lines, one per fixture, so a shell grep can
/// count `run` and `deferred` entries. `reason` is `-` for `run` entries;
/// for a deferred entry it is `"<feature>: <reason>"`. Invariant enforced
/// by `fixture_manifest.rs`: run + deferred == the fixture directory's
/// `*.json` count (green + ignored == 17).
pub const FIXTURE_MANIFEST: &[&str] = &[
    "00-zero-income.json run -",
    "01-tax-table-single-25225.json run -",
    "02-tax-table-example-mjf-25325.json run -",
    "03-qdi-stacking-single.json run -",
    "04-qdi-20pct-and-niit-single.json run -",
    "05-qdi-mfs-fifteencap-300000.json run -",
    "06-niit-mfs-threshold-125000.json run -",
    "07-senior-single-phaseout.json run -",
    "08-senior-mjs-both-65-phaseout.json run -",
    "09-senior-mfs-ineligible.json run -",
    "10-salt-phase-down-mjs.json run -",
    "11-salt-mfs-floor.json run -",
    "12-ctc-phaseout-rounding-mjs.json run -",
    "13-ctc-phaseout-combined-hoh.json run -",
    "14-actc-refundable-single.json run -",
    "15-sli-phaseout-single.json run -",
    "16-surviving-spouse-qss-mapped-thresholds.json run -",
];

/// One parsed manifest line.
pub struct ManifestEntry {
    pub file: &'static str,
    /// `"run"` or `"deferred"`.
    pub status: &'static str,
    /// `"-"` for run entries; `"<feature>: <reason>"` for deferred ones.
    pub reason: &'static str,
}

/// Parse [`FIXTURE_MANIFEST`] into structured entries (panics on a
/// malformed line — the manifest is a committed contract, not user input).
pub fn manifest_entries() -> Vec<ManifestEntry> {
    FIXTURE_MANIFEST
        .iter()
        .map(|line| {
            let mut parts = line.splitn(3, ' ');
            let file = parts.next().expect("manifest line has a filename");
            let status = parts.next().expect("manifest line has a status");
            let reason = parts.next().expect("manifest line has a reason column");
            assert!(
                status == "run" || status == "deferred",
                "manifest line '{}' has invalid status '{}' (must be run|deferred)",
                line,
                status
            );
            assert!(
                !file.is_empty() && file.ends_with(".json"),
                "manifest line '{}' has an invalid filename",
                line
            );
            ManifestEntry {
                file,
                status,
                reason,
            }
        })
        .collect()
}

/// The directory's `*.json` set as a `BTreeSet<String>` (the guard's
/// right-hand side).
pub fn directory_fixture_set() -> BTreeSet<String> {
    fixture_files().into_iter().collect()
}
