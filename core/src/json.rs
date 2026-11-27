// SPDX-License-Identifier: GPL-3.0-only
//! Zero-dependency JSON model + strict parser + round-trip-exact writer
//! (N1 session 2, ADR-017 annex (b): the bridge codecs run in the
//! std-only core, so JSON is hand-rolled here — no serde, no `fs`, no
//! `io`; strings in, strings out, pure).
//!
//! ## Number semantics (annex (c): no semantic changes during a port)
//!
//! - The PARSER accepts the RFC 8259 number grammar strictly (no leading
//!   zeros, no `+`, no bare `.5`/`5.`, no `NaN`/`Infinity` tokens) and
//!   parses every number to binary64 — the same "all numbers are double"
//!   posture as the Dart (`json_codec.dart`) and TS (`JSON.parse`) readers.
//!   A number whose magnitude overflows binary64 to a non-finite value is
//!   rejected (fail-closed; the references cannot produce one from a valid
//!   envelope either).
//! - The WRITER emits numbers ECMAScript-style — byte-identical to V8's
//!   `JSON.stringify` on the whole f64 range, and to Dart's
//!   `double.toString` / `Number#toString` (documented to match). ONE
//!   deliberate divergence from Dart's `jsonEncode`: Dart's JSON encoder
//!   appends `.0` to whole doubles (`jsonEncode(80000.0)` → `80000.0`) to
//!   mark their type; this writer follows the ECMAScript emitters
//!   (`80000`), which is byte-compatible with the TS writers the
//!   envelope/round-trip byte contracts rest on, and value-identical
//!   everywhere (both forms parse to the same f64). Plain decimal form
//!   for `1e-6 <= |x| < 1e21` (plus zero, which prints `0` — including
//!   `-0.0`), exponent form `Me+E`/`Me-E` outside that band. Rust's
//!   `{}`/`{:e}` produce exactly the shortest round-tripping digits
//!   (Grisu/Ryu family), so `parse(write(x)) == x` holds for every finite
//!   `f64` — pinned by the unit tests below, including a deterministic
//!   pseudo-random battery. Non-finite values are refused by the writer
//!   (fail-closed): the TS writer's silent `NaN → null` is a latent-bug
//!   posture, not a contract to port; the Dart writer throws on them,
//!   which is the posture kept.
//!
//! ## Strictness posture (deliberate, documented hardenings)
//!
//! - Nesting deeper than [`MAX_NESTING_DEPTH`] is rejected
//!   ([`JsonError::DepthLimitExceeded`]). Neither `jsonDecode` nor
//!   `JSON.parse` has such a limit; a crafted deep-nested payload could
//!   otherwise exhaust the stack. The envelope schema nests ~4 levels.
//! - An unpaired `\uD800`–`\uDFFF` escape is rejected (a Rust `String`
//!   cannot hold a lone surrogate; the strictness is the honest encoding
//!   of what the target type can represent).
//! - Duplicate object keys: the LAST value wins, at the FIRST position —
//!   the observable semantics of both `jsonDecode` (Dart LinkedHashMap)
//!   and `JSON.parse` (V8).
//! - An object with MORE THAN [`MAX_OBJECT_MEMBERS`] members is rejected
//!   ([`JsonError::TooManyMembers`]). Neither reference bounds this; the
//!   duplicate-key resolution below [`MAX_LINEAR_KEY_SCAN`] distinct
//!   members switches from the linear scan to an indexed lookup, so the
//!   crafted wide-object parse is O(n) (the quadratic-insertion risk the
//!   N1-exit gate registered, closed indexed — the N3 session-1
//!   hardening), and the member cap bounds the walk, not the scan.

use std::fmt::Write as _;

/// Maximum parser nesting depth (arrays + objects combined). Generous
/// against the envelope schema's ~4; bounded against crafted payloads.
pub const MAX_NESTING_DEPTH: usize = 128;

/// Maximum number of members in one JSON object. Generous against the
/// envelope/store schemas (each has fewer than 40 members); bounded
/// against crafted payloads — the memory + walk bound (the scan itself
/// is O(1) amortized past [`MAX_LINEAR_KEY_SCAN`] via the duplicate-key
/// index, so the cap's original role, bounding the O(n²) linear scan, is
/// retired; it now bounds the walk and the allocation alone), so a wider
/// object is still refused outright, never parsed slowly.
pub const MAX_OBJECT_MEMBERS: usize = 10_000;

/// Past this many DISTINCT members in one object, the duplicate-key
/// lookup switches from the linear scan to a lazily built key→slot
/// index (the N3 session-1 hardening, ENG-1/SEC-5: the R-ENG-1
/// amplification bound — a crafted wide object with many duplicate-key
/// occurrences previously cost O(distinct members) comparisons per
/// occurrence, i.e. up to ~10⁸ byte-compares over a max-width object;
/// the index is used ONLY for find-or-insert, never iterated, so
/// insertion order, the last-value-wins-at-first-position contract, and
/// every output byte are unchanged). Generous against the envelope/
/// store schemas (both far under the threshold: the linear scan serves
/// every legitimate envelope); bounded where the amplification begins.
pub const MAX_LINEAR_KEY_SCAN: usize = 64;

/// Named parser/writer errors. Every error carries the byte offset of the
/// offending construct, so callers surface named, locatable failures
/// (the ENG-7 strict-reader posture: no silent defaults).
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum JsonError {
    /// The input ended while a value was still expected.
    UnexpectedEnd,
    /// A byte that cannot start (or continue) a value/structure at `offset`.
    UnexpectedByte { offset: usize, byte: u8 },
    /// A structural token out of place (`,]` etc.) at `offset`.
    UnexpectedToken { offset: usize, what: &'static str },
    /// A string literal left unterminated, or a bad escape, at `offset`.
    BadStringEscape { offset: usize, what: &'static str },
    /// A `\u` escape was unpaired (lone surrogate) or malformed at `offset`.
    BadUnicodeEscape { offset: usize },
    /// A number violated the RFC 8259 grammar at `offset` (`what` names it).
    BadNumber { offset: usize, what: &'static str },
    /// A finite-looking number overflowed binary64 at `offset`.
    NumberOutOfRange { offset: usize },
    /// Nesting exceeded [`MAX_NESTING_DEPTH`].
    DepthLimitExceeded { offset: usize, depth: usize },
    /// An object carried more than [`MAX_OBJECT_MEMBERS`] members —
    /// `count` is the member that tripped the cap, whose key opens at
    /// `offset` (fail-closed: the duplicate-key scan is O(n²) in the
    /// member count — see module docs).
    TooManyMembers { offset: usize, count: usize },
    /// The writer was handed a non-finite number (fail-closed; see module
    /// docs — the Dart writer throws on this, the TS writer's `null` is
    /// not ported).
    NonFiniteNumber,
}

impl std::fmt::Display for JsonError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            JsonError::UnexpectedEnd => write!(f, "unexpected end of JSON input"),
            JsonError::UnexpectedByte { offset, byte } => {
                write!(f, "unexpected byte {byte:#04x} at offset {offset}")
            }
            JsonError::UnexpectedToken { offset, what } => {
                write!(f, "unexpected {what} at offset {offset}")
            }
            JsonError::BadStringEscape { offset, what } => {
                write!(f, "bad string escape ({what}) at offset {offset}")
            }
            JsonError::BadUnicodeEscape { offset } => {
                write!(f, "malformed or unpaired \\u escape at offset {offset}")
            }
            JsonError::BadNumber { offset, what } => {
                write!(f, "bad number ({what}) at offset {offset}")
            }
            JsonError::NumberOutOfRange { offset } => {
                write!(f, "number overflows binary64 at offset {offset}")
            }
            JsonError::DepthLimitExceeded { offset, depth } => {
                write!(f, "nesting depth {depth} exceeds the {MAX_NESTING_DEPTH}-deep limit at offset {offset}")
            }
            JsonError::TooManyMembers { offset, .. } => {
                // The limit is spelled out (10,000 == MAX_OBJECT_MEMBERS),
                // like the writer-side errors' "65,535-byte" wording.
                write!(
                    f,
                    "a JSON object exceeds the 10,000-member parser limit at offset {offset}"
                )
            }
            JsonError::NonFiniteNumber => write!(
                f,
                "non-finite number cannot be written as JSON (fail-closed)"
            ),
        }
    }
}

impl std::error::Error for JsonError {}

/// A parsed JSON value. Objects keep insertion order (the emission-order
/// contract the envelope codec's byte-compatibility rests on) with
/// last-value-wins duplicate keys at the first position (see module docs).
#[derive(Clone, Debug, PartialEq)]
pub enum Json {
    Null,
    Bool(bool),
    Num(f64),
    Str(String),
    Arr(Vec<Json>),
    Obj(Vec<(String, Json)>),
}

impl From<bool> for Json {
    fn from(v: bool) -> Self {
        Json::Bool(v)
    }
}
impl From<f64> for Json {
    fn from(v: f64) -> Self {
        Json::Num(v)
    }
}
impl From<i64> for Json {
    fn from(v: i64) -> Self {
        Json::Num(v as f64)
    }
}
impl From<&str> for Json {
    fn from(v: &str) -> Self {
        Json::Str(v.to_owned())
    }
}
impl From<String> for Json {
    fn from(v: String) -> Self {
        Json::Str(v)
    }
}

impl Json {
    /// Strict-parse one complete JSON document. Trailing non-whitespace
    /// content is an error.
    pub fn parse(text: &str) -> Result<Json, JsonError> {
        let mut p = Parser {
            bytes: text.as_bytes(),
            pos: 0,
        };
        p.skip_ws();
        let value = p.parse_value(0)?;
        p.skip_ws();
        if p.pos != p.bytes.len() {
            return Err(JsonError::UnexpectedByte {
                offset: p.pos,
                byte: p.bytes[p.pos],
            });
        }
        Ok(value)
    }

    /// Typed accessors (`None` when the kind mismatches — callers that
    /// require a kind convert the `None` into their own named error).
    pub fn as_bool(&self) -> Option<bool> {
        match self {
            Json::Bool(b) => Some(*b),
            _ => None,
        }
    }
    pub fn as_f64(&self) -> Option<f64> {
        match self {
            Json::Num(n) => Some(*n),
            _ => None,
        }
    }
    /// A number that is a whole value within `i64` range (counts, years).
    pub fn as_i64(&self) -> Option<i64> {
        match self {
            Json::Num(n) if n.fract() == 0.0 && n.abs() < 9.0e18 => Some(*n as i64),
            _ => None,
        }
    }
    pub fn as_str(&self) -> Option<&str> {
        match self {
            Json::Str(s) => Some(s.as_str()),
            _ => None,
        }
    }
    pub fn as_arr(&self) -> Option<&[Json]> {
        match self {
            Json::Arr(a) => Some(a.as_slice()),
            _ => None,
        }
    }
    pub fn as_obj(&self) -> Option<&[(String, Json)]> {
        match self {
            Json::Obj(o) => Some(o.as_slice()),
            _ => None,
        }
    }

    /// Object member lookup (first match; duplicate keys keep the first
    /// position but the last value, and this returns that surviving pair).
    pub fn get(&self, key: &str) -> Option<&Json> {
        match self {
            Json::Obj(pairs) => pairs
                .iter()
                .rev()
                .find(|(k, _)| k == key)
                .map(|(_, v)| v),
            _ => None,
        }
    }

    /// Serialize. Numbers follow the ECMAScript emission rules described
    /// in the module docs (byte-identical to V8 `JSON.stringify`; the one
    /// deliberate Dart `jsonEncode` divergence — whole doubles keep the
    /// ECMAScript integer form — is documented there).
    pub fn write(&self) -> Result<String, JsonError> {
        let mut out = String::new();
        self.write_into(&mut out)?;
        Ok(out)
    }

    /// Pretty-printed serialization with a fixed indent unit — byte-shape
    /// identical to BOTH reference pretty-printers (Dart
    /// `JsonEncoder.withIndent('  ')` and V8 `JSON.stringify(x, null, 2)`
    /// emit the same `": "` separators, `,\n` item breaks, and `{}`/`[]`
    /// for empty containers), which is what the envelope encoder's
    /// byte-compatibility rests on.
    pub fn write_pretty(&self, indent: &str) -> Result<String, JsonError> {
        let mut out = String::new();
        self.write_pretty_into(&mut out, indent, 0)?;
        Ok(out)
    }

    fn write_pretty_into(
        &self,
        out: &mut String,
        indent: &str,
        depth: usize,
    ) -> Result<(), JsonError> {
        match self {
            Json::Obj(pairs) if !pairs.is_empty() => {
                out.push_str("{\n");
                for (i, (k, v)) in pairs.iter().enumerate() {
                    if i > 0 {
                        out.push_str(",\n");
                    }
                    for _ in 0..=depth {
                        out.push_str(indent);
                    }
                    write_string(k, out);
                    out.push_str(": ");
                    v.write_pretty_into(out, indent, depth + 1)?;
                }
                out.push('\n');
                for _ in 0..depth {
                    out.push_str(indent);
                }
                out.push('}');
            }
            Json::Obj(_) => out.push_str("{}"),
            Json::Arr(items) if !items.is_empty() => {
                out.push_str("[\n");
                for (i, item) in items.iter().enumerate() {
                    if i > 0 {
                        out.push_str(",\n");
                    }
                    for _ in 0..=depth {
                        out.push_str(indent);
                    }
                    item.write_pretty_into(out, indent, depth + 1)?;
                }
                out.push('\n');
                for _ in 0..depth {
                    out.push_str(indent);
                }
                out.push(']');
            }
            Json::Arr(_) => out.push_str("[]"),
            other => other.write_into(out)?,
        }
        Ok(())
    }

    fn write_into(&self, out: &mut String) -> Result<(), JsonError> {
        match self {
            Json::Null => out.push_str("null"),
            Json::Bool(true) => out.push_str("true"),
            Json::Bool(false) => out.push_str("false"),
            Json::Num(n) => out.push_str(&write_number(*n)?),
            Json::Str(s) => write_string(s, out),
            Json::Arr(items) => {
                out.push('[');
                for (i, item) in items.iter().enumerate() {
                    if i > 0 {
                        out.push(',');
                    }
                    item.write_into(out)?;
                }
                out.push(']');
            }
            Json::Obj(pairs) => {
                out.push('{');
                for (i, (k, v)) in pairs.iter().enumerate() {
                    if i > 0 {
                        out.push(',');
                    }
                    write_string(k, out);
                    out.push(':');
                    v.write_into(out)?;
                }
                out.push('}');
            }
        }
        Ok(())
    }
}

/// ECMAScript `Number#toString` / `JSON.stringify` number emission.
fn write_number(n: f64) -> Result<String, JsonError> {
    if !n.is_finite() {
        return Err(JsonError::NonFiniteNumber);
    }
    if n == 0.0 {
        // Covers +0.0 and -0.0: ECMAScript prints `0` (no sign, no `.0`).
        return Ok("0".to_owned());
    }
    let mag = n.abs();
    if (1e-6..1e21).contains(&mag) {
        // Plain decimal zone: Rust's `{}` is the shortest round-trip
        // decimal expansion — identical digits to ECMAScript here.
        Ok(format!("{n}"))
    } else {
        // Exponent zone: Rust's `{:e}` gives the shortest round-trip
        // mantissa+exponent ("1.5e-7"); ECMAScript renders an explicit
        // sign on non-negative exponents ("1e+21"), so patch it in.
        let sci = format!("{n:e}");
        match sci.split_once('e') {
            Some((mantissa, exp)) => {
                if let Some(stripped) = exp.strip_prefix('-') {
                    Ok(format!("{mantissa}e-{stripped}"))
                } else {
                    Ok(format!("{mantissa}e+{exp}"))
                }
            }
            None => Ok(sci), // unreachable for finite non-zero f64
        }
    }
}

/// Minimal-escaping string emission, matching `JSON.stringify` /
/// `jsonEncode`: the two mandatory escapes, the five named control
/// escapes, `\u00xx` for the remaining control range, and raw UTF-8 for
/// everything else (including DEL and all non-ASCII).
fn write_string(s: &str, out: &mut String) {
    out.push('"');
    for ch in s.chars() {
        match ch {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\u{08}' => out.push_str("\\b"),
            '\u{0c}' => out.push_str("\\f"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if (c as u32) < 0x20 => {
                let _ = write!(out, "\\u{:04x}", c as u32);
            }
            c => out.push(c),
        }
    }
    out.push('"');
}

struct Parser<'a> {
    bytes: &'a [u8],
    pos: usize,
}

impl<'a> Parser<'a> {
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

    fn parse_value(&mut self, depth: usize) -> Result<Json, JsonError> {
        if depth >= MAX_NESTING_DEPTH {
            return Err(JsonError::DepthLimitExceeded {
                offset: self.pos,
                depth,
            });
        }
        match self.peek() {
            None => Err(JsonError::UnexpectedEnd),
            Some(b'{') => self.parse_object(depth),
            Some(b'[') => self.parse_array(depth),
            Some(b'"') => self.parse_string().map(Json::Str),
            Some(b't') => self.parse_keyword("true", Json::Bool(true)),
            Some(b'f') => self.parse_keyword("false", Json::Bool(false)),
            Some(b'n') => self.parse_keyword("null", Json::Null),
            Some(b'-') | Some(b'0'..=b'9') => self.parse_number(),
            Some(byte) => Err(JsonError::UnexpectedByte {
                offset: self.pos,
                byte,
            }),
        }
    }

    fn parse_keyword(&mut self, word: &str, value: Json) -> Result<Json, JsonError> {
        let end = self.pos + word.len();
        if self.bytes.len() >= end && &self.bytes[self.pos..end] == word.as_bytes() {
            self.pos = end;
            Ok(value)
        } else {
            Err(JsonError::UnexpectedByte {
                offset: self.pos,
                byte: self.peek().unwrap_or(b' '),
            })
        }
    }

    fn parse_object(&mut self, depth: usize) -> Result<Json, JsonError> {
        self.pos += 1; // '{'
        let mut pairs: Vec<(String, Json)> = Vec::new();
        // Duplicate-key index (N3 session-1 hardening, ENG-1/SEC-5):
        // lazily built when the DISTINCT-member count first crosses
        // MAX_LINEAR_KEY_SCAN (i.e. when the (MAX_LINEAR_KEY_SCAN + 1)-th
        // new member arrives), then used ONLY for find-or-insert — never
        // iterated — so insertion order, the last-value-wins-at-first-
        // position contract, and every output byte are unchanged. Below
        // the threshold the linear scan serves (every legitimate
        // envelope/store object is far under it).
        let mut key_index: std::collections::HashMap<String, usize> =
            std::collections::HashMap::new();
        let mut indexed = false;
        self.skip_ws();
        if self.peek() == Some(b'}') {
            self.pos += 1;
            return Ok(Json::Obj(pairs));
        }
        loop {
            self.skip_ws();
            if self.peek() != Some(b'"') {
                return Err(JsonError::UnexpectedToken {
                    offset: self.pos,
                    what: "non-string object key",
                });
            }
            let key_offset = self.pos;
            let key = self.parse_string()?;
            self.skip_ws();
            if self.peek() != Some(b':') {
                return Err(JsonError::UnexpectedToken {
                    offset: self.pos,
                    what: "expected ':' in object",
                });
            }
            self.pos += 1;
            self.skip_ws();
            let value = self.parse_value(depth + 1)?;
            // Duplicate key: last value wins at the first position
            // (Dart LinkedHashMap / V8 semantics). The lookup is the
            // indexed one once the object crossed the threshold.
            let found = if indexed {
                key_index.get(&key).copied()
            } else {
                let hit = pairs.iter().position(|(k, _)| *k == key);
                if hit.is_none() && pairs.len() >= MAX_LINEAR_KEY_SCAN {
                    // The first NEW member past the threshold: build the
                    // index over the existing members (this member joins
                    // on push below). Duplicates never arrive here — they
                    // hit the scan above and never grow the member count.
                    for (i, (k, _)) in pairs.iter().enumerate() {
                        key_index.insert(k.clone(), i);
                    }
                    indexed = true;
                }
                hit
            };
            match found {
                Some(slot) => pairs[slot].1 = value,
                None => {
                    // Member-count cap (fail-closed, module docs): the
                    // (MAX_OBJECT_MEMBERS + 1)-th NEW member is refused
                    // outright rather than parsed slowly (duplicate keys
                    // never grow the member count, so they never trip it;
                    // the cap now bounds the walk + allocation — the scan
                    // is indexed past MAX_LINEAR_KEY_SCAN).
                    if pairs.len() >= MAX_OBJECT_MEMBERS {
                        return Err(JsonError::TooManyMembers {
                            offset: key_offset,
                            count: pairs.len() + 1,
                        });
                    }
                    if indexed {
                        key_index.insert(key.clone(), pairs.len());
                    }
                    pairs.push((key, value));
                }
            }
            self.skip_ws();
            match self.peek() {
                Some(b',') => {
                    self.pos += 1;
                }
                Some(b'}') => {
                    self.pos += 1;
                    return Ok(Json::Obj(pairs));
                }
                _ => {
                    return Err(JsonError::UnexpectedToken {
                        offset: self.pos,
                        what: "expected ',' or '}' in object",
                    })
                }
            }
        }
    }

    fn parse_array(&mut self, depth: usize) -> Result<Json, JsonError> {
        self.pos += 1; // '['
        let mut items = Vec::new();
        self.skip_ws();
        if self.peek() == Some(b']') {
            self.pos += 1;
            return Ok(Json::Arr(items));
        }
        loop {
            self.skip_ws();
            items.push(self.parse_value(depth + 1)?);
            self.skip_ws();
            match self.peek() {
                Some(b',') => {
                    self.pos += 1;
                }
                Some(b']') => {
                    self.pos += 1;
                    return Ok(Json::Arr(items));
                }
                _ => {
                    return Err(JsonError::UnexpectedToken {
                        offset: self.pos,
                        what: "expected ',' or ']' in array",
                    })
                }
            }
        }
    }

    fn parse_string(&mut self) -> Result<String, JsonError> {
        self.pos += 1; // opening '"'
        let mut out = String::new();
        loop {
            let start = self.pos;
            // Fast path: a run of plain bytes up to the next '"' or '\\'
            // or a control byte.
            while let Some(&b) = self.bytes.get(self.pos) {
                if b == b'"' || b == b'\\' || b < 0x20 {
                    break;
                }
                self.pos += 1;
            }
            if self.pos > start {
                // The plain run is UTF-8 by construction (input is a
                // &str; multi-byte sequences never contain ASCII bytes).
                out.push_str(
                    std::str::from_utf8(&self.bytes[start..self.pos])
                        .expect("plain run of a &str is valid UTF-8"),
                );
            }
            match self.peek() {
                None => return Err(JsonError::UnexpectedEnd),
                Some(b'"') => {
                    self.pos += 1;
                    return Ok(out);
                }
                Some(b'\\') => {
                    self.pos += 1;
                    self.parse_escape(&mut out)?;
                }
                Some(byte) => {
                    // A raw control byte inside a string literal.
                    return Err(JsonError::UnexpectedByte {
                        offset: self.pos,
                        byte,
                    });
                }
            }
        }
    }

    fn parse_escape(&mut self, out: &mut String) -> Result<(), JsonError> {
        let offset = self.pos - 1;
        let esc = self.peek().ok_or(JsonError::UnexpectedEnd)?;
        self.pos += 1;
        match esc {
            b'"' => out.push('"'),
            b'\\' => out.push('\\'),
            b'/' => out.push('/'),
            b'b' => out.push('\u{08}'),
            b'f' => out.push('\u{0c}'),
            b'n' => out.push('\n'),
            b'r' => out.push('\r'),
            b't' => out.push('\t'),
            b'u' => {
                let cp = self.parse_hex4()?;
                if (0xD800..=0xDBFF).contains(&cp) {
                    // High surrogate: require a low surrogate next.
                    if self.bytes.get(self.pos) != Some(&b'\\')
                        || self.bytes.get(self.pos + 1) != Some(&b'u')
                    {
                        return Err(JsonError::BadUnicodeEscape { offset });
                    }
                    self.pos += 2;
                    let low = self.parse_hex4()?;
                    if !(0xDC00..=0xDFFF).contains(&low) {
                        return Err(JsonError::BadUnicodeEscape { offset });
                    }
                    let c = 0x1_0000 + ((cp - 0xD800) << 10) + (low - 0xDC00);
                    out.push(
                        char::from_u32(c)
                            .ok_or(JsonError::BadUnicodeEscape { offset })?,
                    );
                } else if (0xDC00..=0xDFFF).contains(&cp) {
                    // Lone low surrogate.
                    return Err(JsonError::BadUnicodeEscape { offset });
                } else {
                    out.push(
                        char::from_u32(cp).ok_or(JsonError::BadUnicodeEscape { offset })?,
                    );
                }
            }
            _ => {
                return Err(JsonError::BadStringEscape {
                    offset,
                    what: "unknown escape letter",
                })
            }
        }
        Ok(())
    }

    fn parse_hex4(&mut self) -> Result<u32, JsonError> {
        let offset = self.pos;
        let mut value: u32 = 0;
        for _ in 0..4 {
            let b = self.peek().ok_or(JsonError::UnexpectedEnd)?;
            let digit = match b {
                b'0'..=b'9' => (b - b'0') as u32,
                b'a'..=b'f' => (b - b'a') as u32 + 10,
                b'A'..=b'F' => (b - b'A') as u32 + 10,
                _ => return Err(JsonError::BadUnicodeEscape { offset }),
            };
            value = value * 16 + digit;
            self.pos += 1;
        }
        Ok(value)
    }

    /// RFC 8259 number grammar, then binary64 conversion (rejecting
    /// overflow to non-finite).
    fn parse_number(&mut self) -> Result<Json, JsonError> {
        let start = self.pos;
        let offset = self.pos;
        // '-' int [frac] [exp] — strict: int is 0 | digit1-9 digit*
        if self.peek() == Some(b'-') {
            self.pos += 1;
        }
        match self.peek() {
            Some(b'0') => {
                self.pos += 1;
                if let Some(b'0'..=b'9') = self.peek() {
                    return Err(JsonError::BadNumber {
                        offset,
                        what: "leading zero",
                    });
                }
            }
            Some(b'1'..=b'9') => {
                while let Some(b'0'..=b'9') = self.peek() {
                    self.pos += 1;
                }
            }
            _ => {
                return Err(JsonError::BadNumber {
                    offset,
                    what: "missing integer part",
                })
            }
        }
        if self.peek() == Some(b'.') {
            self.pos += 1;
            match self.peek() {
                Some(b'0'..=b'9') => {
                    while let Some(b'0'..=b'9') = self.peek() {
                        self.pos += 1;
                    }
                }
                _ => {
                    return Err(JsonError::BadNumber {
                        offset,
                        what: "missing fraction digits",
                    })
                }
            }
        }
        match self.peek() {
            Some(b'e') | Some(b'E') => {
                self.pos += 1;
                if matches!(self.peek(), Some(b'+') | Some(b'-')) {
                    self.pos += 1;
                }
                match self.peek() {
                    Some(b'0'..=b'9') => {
                        while let Some(b'0'..=b'9') = self.peek() {
                            self.pos += 1;
                        }
                    }
                    _ => {
                        return Err(JsonError::BadNumber {
                            offset,
                            what: "missing exponent digits",
                        })
                    }
                }
            }
            _ => {}
        }
        let text = std::str::from_utf8(&self.bytes[start..self.pos])
            .expect("number token is ASCII by grammar");
        let value: f64 = text
            .parse()
            .map_err(|_| JsonError::BadNumber {
                offset,
                what: "unparseable",
            })?;
        if !value.is_finite() {
            return Err(JsonError::NumberOutOfRange { offset });
        }
        Ok(Json::Num(value))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Deterministic xorshift64* battery: every finite f64 bit pattern in
    /// a pseudo-random sample must survive write → parse unchanged.
    #[test]
    fn number_round_trip_battery() {
        let mut state: u64 = 0x9E37_79B9_7F4A_7C15;
        let mut next = move || {
            state ^= state >> 12;
            state ^= state << 25;
            state ^= state >> 27;
            state.wrapping_mul(0x2545_F491_4F6C_DD1D)
        };
        let mut checked = 0usize;
        for _ in 0..20_000 {
            let bits = next();
            let n = f64::from_bits(bits);
            if !n.is_finite() {
                continue;
            }
            let text = write_number(n).unwrap();
            let back: f64 = text.parse().unwrap();
            assert_eq!(back.to_bits(), n.to_bits(), "round trip lost: {n} -> {text}");
            // And the strict parser accepts our own emission.
            let parsed = Json::parse(&text).unwrap();
            assert_eq!(parsed.as_f64().unwrap().to_bits(), n.to_bits());
            checked += 1;
        }
        assert!(checked > 19_000);
    }

    #[test]
    fn number_ecmascript_shape() {
        // Plain-decimal zone + the exact exponent thresholds.
        assert_eq!(write_number(0.0).unwrap(), "0");
        assert_eq!(write_number(-0.0).unwrap(), "0");
        assert_eq!(write_number(1.0).unwrap(), "1");
        assert_eq!(write_number(-4.0).unwrap(), "-4");
        assert_eq!(write_number(1234.56).unwrap(), "1234.56");
        assert_eq!(write_number(1e-6).unwrap(), "0.000001");
        assert_eq!(write_number(1e21).unwrap(), "1e+21");
        assert_eq!(write_number(-1.5e22).unwrap(), "-1.5e+22");
        assert_eq!(write_number(1e-7).unwrap(), "1e-7");
        assert_eq!(write_number(-1.5e-9).unwrap(), "-1.5e-9");
        assert_eq!(write_number(1e14).unwrap(), "100000000000000");
        assert_eq!(write_number(1e20).unwrap(), "100000000000000000000");
    }

    #[test]
    fn writer_refuses_non_finite() {
        assert_eq!(Json::Num(f64::NAN).write(), Err(JsonError::NonFiniteNumber));
        assert_eq!(
            Json::Num(f64::INFINITY).write(),
            Err(JsonError::NonFiniteNumber)
        );
    }

    #[test]
    fn string_escape_minimality_and_raw_unicode() {
        let j = Json::Str("a\"b\\c\nd\te\u{1} café → 🄯".into());
        assert_eq!(
            j.write().unwrap(),
            "\"a\\\"b\\\\c\\nd\\te\\u0001 café → 🄯\""
        );
    }

    #[test]
    fn parse_escapes_and_surrogate_pairs() {
        let v = Json::parse(r#""A😀 z""#).unwrap();
        assert_eq!(v.as_str().unwrap(), "A😀 z");
        let v = Json::parse("\"\\u00e9\\n\"").unwrap();
        assert_eq!(v.as_str().unwrap(), "é\n");
    }

    #[test]
    fn parse_strict_grammar_rejections() {
        for bad in [
            "", "  ", "01", "1.", ".5", "+1", "NaN", "Infinity", "-Infinity",
            "1e", "1e+", "1e999", "-1e999", "tru", "[1,]", "{\"a\":}", "{\"a\" 1}",
            "{\"a\":1,}", "[1 2]", "\"unterminated", "\"bad \\x esc\"",
            "\"\\uD800\"", "\"\\uDC00 alone\"", "\"\\uD800\\uD800\"", "\"a\nb\"",
            "{\"a\":1} trailing", "nul",
        ] {
            assert!(Json::parse(bad).is_err(), "should reject: {bad:?}");
        }
    }

    #[test]
    fn parse_depth_limit_fail_closed() {
        let mut text = String::new();
        for _ in 0..(MAX_NESTING_DEPTH + 1) {
            text.push('[');
        }
        for _ in 0..(MAX_NESTING_DEPTH + 1) {
            text.push(']');
        }
        // Level 129 (depth 128) is the first rejected nesting level.
        assert_eq!(
            Json::parse(&text),
            Err(JsonError::DepthLimitExceeded {
                offset: MAX_NESTING_DEPTH,
                depth: MAX_NESTING_DEPTH
            })
        );
        // One level shallower is fine.
        let mut ok = String::new();
        for _ in 0..MAX_NESTING_DEPTH {
            ok.push('[');
        }
        for _ in 0..MAX_NESTING_DEPTH {
            ok.push(']');
        }
        assert!(Json::parse(&ok).is_ok());
    }

    /// The object member-count cap (fail-closed, module docs): 10,001 NEW
    /// members → the named error; exactly 10,000 parses. Built
    /// programmatically — the strings are ~130 KB, no literals.
    #[test]
    fn parse_object_member_cap_fail_closed() {
        let mut wide = String::from("{");
        for i in 0..=MAX_OBJECT_MEMBERS {
            if i > 0 {
                wide.push(',');
            }
            let _ = write!(wide, "\"k{i}\":0");
        }
        wide.push('}');
        // The (MAX_OBJECT_MEMBERS + 1)-th member — "k10000" — trips the
        // cap; the offset is its key's opening quote.
        let key_offset = wide.rfind("\"k10000\"").unwrap();
        assert_eq!(
            Json::parse(&wide),
            Err(JsonError::TooManyMembers {
                offset: key_offset,
                count: MAX_OBJECT_MEMBERS + 1
            })
        );
        // The Display names the limit and the offset, file style.
        assert_eq!(
            JsonError::TooManyMembers {
                offset: 7,
                count: MAX_OBJECT_MEMBERS + 1
            }
            .to_string(),
            "a JSON object exceeds the 10,000-member parser limit at offset 7"
        );
    }

    #[test]
    fn parse_object_member_cap_exactly_10_000_parses() {
        let mut wide = String::from("{");
        for i in 0..MAX_OBJECT_MEMBERS {
            if i > 0 {
                wide.push(',');
            }
            let _ = write!(wide, "\"k{i}\":0");
        }
        wide.push('}');
        let v = Json::parse(&wide).unwrap();
        assert_eq!(v.as_obj().unwrap().len(), MAX_OBJECT_MEMBERS);
    }

    #[test]
    fn duplicate_keys_last_value_first_position() {
        let v = Json::parse(r#"{"a":1,"b":2,"a":3}"#).unwrap();
        let obj = v.as_obj().unwrap();
        assert_eq!(obj.len(), 2);
        assert_eq!(obj[0].0, "a");
        assert_eq!(v.get("a").unwrap().as_i64().unwrap(), 3);
        // Emission keeps the first position with the surviving value.
        assert_eq!(v.write().unwrap(), r#"{"a":3,"b":2}"#);
    }

    /// The N3 session-1 hardening battery (ENG-1/SEC-5, the R-ENG-1
    /// amplification bound): a max-width (10,000 distinct member) object
    /// followed by ~100,000 duplicate-key occurrences — the exact hostile
    /// surface, minutes of single-core scan pre-index — now parses green
    /// under a generous wall-clock bound. The bound is deliberately loose
    /// (10 s): it is two-plus orders of magnitude under the pre-index
    /// hostile case (the linear scan over 10,000 distinct keys × 100k
    /// occurrences ≈ 10⁹ key comparisons), so CI runner variance cannot
    /// false-trip it while the amplification still cannot slip through.
    #[test]
    fn duplicate_scan_indexed_past_threshold_hostile_amplification() {
        const DUPLICATES: usize = 100_000;
        let start = std::time::Instant::now();
        let mut hostile = String::from("{");
        for i in 0..MAX_OBJECT_MEMBERS {
            if i > 0 {
                hostile.push(',');
            }
            let _ = write!(hostile, "\"k{i}\":0");
        }
        // Every duplicate re-scans the full 10,000-member width pre-index.
        for _ in 0..DUPLICATES {
            let _ = write!(hostile, ",\"k0\":7");
        }
        hostile.push('}');
        let v = Json::parse(&hostile).unwrap();
        let elapsed = start.elapsed();
        // The observable contract: duplicates never grow the member
        // count; the last value wins at the first position.
        let obj = v.as_obj().unwrap();
        assert_eq!(obj.len(), MAX_OBJECT_MEMBERS);
        assert_eq!(obj[0].0, "k0");
        assert_eq!(v.get("k0").unwrap().as_i64().unwrap(), 7);
        assert!(
            elapsed.as_secs() < 10,
            "the hostile duplicate-scan case took {elapsed:?} — the indexed bound regressed"
        );
    }

    /// The threshold-straddling boundary pair (ENG-3): exactly at
    /// MAX_LINEAR_KEY_SCAN distinct members the index is NOT yet built
    /// (all linear); at threshold + 1 it IS — and in both regimes the
    /// duplicate semantics (last value wins, first position) are
    /// identical, including duplicates of a key inserted BEFORE the
    /// boundary arriving AFTER it (the cross-boundary slot identity).
    #[test]
    fn duplicate_scan_threshold_straddling_boundaries() {
        // Exactly at the threshold: 64 distinct members, all linear.
        let mut at = String::from("{");
        for i in 0..MAX_LINEAR_KEY_SCAN {
            if i > 0 {
                at.push(',');
            }
            let _ = write!(at, "\"k{i}\":{i}");
        }
        at.push('}');
        let v = Json::parse(&at).unwrap();
        assert_eq!(v.as_obj().unwrap().len(), MAX_LINEAR_KEY_SCAN);
        assert_eq!(
            v.get(&format!("k{}", MAX_LINEAR_KEY_SCAN - 1))
                .unwrap()
                .as_i64()
                .unwrap() as usize,
            MAX_LINEAR_KEY_SCAN - 1
        );

        // Threshold + 1 distinct members: the (MAX_LINEAR_KEY_SCAN +
        // 1)-th new member builds the index; then a duplicate of a
        // PRE-boundary key ("k0", slot 0) and a duplicate of the
        // BOUNDARY key itself both resolve to their first positions
        // with the last value.
        let mut over = String::from("{");
        for i in 0..=MAX_LINEAR_KEY_SCAN {
            if i > 0 {
                over.push(',');
            }
            let _ = write!(over, "\"k{i}\":{i}");
        }
        let _ = write!(over, ",\"k0\":100,\"k{}\":200", MAX_LINEAR_KEY_SCAN);
        over.push('}');
        let v = Json::parse(&over).unwrap();
        let obj = v.as_obj().unwrap();
        assert_eq!(obj.len(), MAX_LINEAR_KEY_SCAN + 1);
        // The pre-boundary duplicate: slot 0, last value 100.
        assert_eq!(obj[0].0, "k0");
        assert_eq!(v.get("k0").unwrap().as_i64().unwrap(), 100);
        // The boundary key's duplicate: its first position, last value.
        let boundary = v
            .as_obj()
            .unwrap()
            .iter()
            .position(|(k, _)| k == &format!("k{}", MAX_LINEAR_KEY_SCAN))
            .unwrap();
        assert_eq!(boundary, MAX_LINEAR_KEY_SCAN);
        assert_eq!(
            v.get(&format!("k{}", MAX_LINEAR_KEY_SCAN))
                .unwrap()
                .as_i64()
                .unwrap(),
            200
        );
        // Emission keeps every first position with the surviving
        // values — byte-identical semantics to the linear regime.
        let written = v.write().unwrap();
        assert!(written.starts_with("{\"k0\":100,"));
        assert!(written.contains(&format!(
            "\"k{}\":{},\"k{}\":200",
            MAX_LINEAR_KEY_SCAN - 1,
            MAX_LINEAR_KEY_SCAN - 1,
            MAX_LINEAR_KEY_SCAN
        )));
    }

    #[test]
    fn object_order_preserved_in_emission() {
        let v = Json::parse(r#"{"z":1,"a":2,"m":{"x":[1,2.5,null,true,"s"]}}"#).unwrap();
        assert_eq!(
            v.write().unwrap(),
            r#"{"z":1,"a":2,"m":{"x":[1,2.5,null,true,"s"]}}"#
        );
    }

    #[test]
    fn pretty_matches_dart_and_v8_shape() {
        let v = Json::parse(r#"{"a":1,"b":[1,2],"c":{"d":true,"e":[]},"f":{},"g":[]}"#)
            .unwrap();
        assert_eq!(
            v.write_pretty("  ").unwrap(),
            "{\n  \"a\": 1,\n  \"b\": [\n    1,\n    2\n  ],\n  \"c\": {\n    \"d\": true,\n    \"e\": []\n  },\n  \"f\": {},\n  \"g\": []\n}"
        );
        // Pretty output parses back to the same tree.
        assert_eq!(
            Json::parse(&v.write_pretty("  ").unwrap()).unwrap(),
            v
        );
        // Empty containers stay inline even at depth.
        let v = Json::parse(r#"{"outer":{"inner":{}}}"#).unwrap();
        assert_eq!(
            v.write_pretty("  ").unwrap(),
            "{\n  \"outer\": {\n    \"inner\": {}\n  }\n}"
        );
    }

    #[test]
    fn as_i64_whole_numbers_only() {
        assert_eq!(Json::Num(2025.0).as_i64(), Some(2025));
        assert_eq!(Json::Num(0.5).as_i64(), None);
        assert_eq!(Json::Num(9.5e18).as_i64(), None);
        assert_eq!(Json::Str("5".into()).as_i64(), None);
    }

    #[test]
    fn error_display_names_the_offset() {
        // `]` where a value is expected: the offending byte + offset.
        let err = Json::parse("[1,]").unwrap_err();
        assert_eq!(
            err.to_string(),
            "unexpected byte 0x5d at offset 3"
        );
    }
}
