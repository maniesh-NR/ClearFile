// SPDX-License-Identifier: GPL-3.0-only
//! The `.tax` inspector port suite (task N1-S2-B): the port of EVERY
//! `.tax`-analysis / exchange-container group of the two reference suites,
//! the malformed-ZIP crash battery included, plus the port's own
//! battery-extension cases.
//!
//! # Group → test mapping (each test cites its original group name)
//!
//! Dart suite — `clearfile/test/tax_inspect_test.dart` (10 tests, all
//! ported; names in the comments above each test):
//!
//! | Original Dart test | Ported test below |
//! | --- | --- |
//! | "ClearFile exchange container is detected and imported" (:16) | [`dart_suite_exchange_container_is_detected_and_imported`] |
//! | "web-written envelope container imports (cross-codebase shape, ADR-015)" (:37) | [`dart_suite_web_written_envelope_container_imports`] |
//! | "container with an unreadable clearfile.json falls through with a warning" (:67) | [`dart_suite_unreadable_clearfile_json_falls_through`] |
//! | "modern Intuit container shape is detected, flagged encrypted, never imported" (:80) | [`dart_suite_intuit_shape_detected_flagged_encrypted_never_imported`] |
//! | "low-entropy textual entries are not flagged encrypted" (:111) | [`dart_suite_low_entropy_textual_entries_not_flagged`] |
//! | "non-ZIP file: honest summary with entropy, no crash" (:124) | [`dart_suite_non_zip_file_honest_summary_with_entropy`] |
//! | "empty file: no crash, empty summary note" (:138) | [`dart_suite_empty_file_no_crash`] |
//! | "deflate entries are listed but not extracted" (:144) | [`dart_suite_deflate_entries_listed_but_not_extracted`] |
//! | "truncated ZIP: warning about the missing central directory" (:159) | [`dart_suite_truncated_zip_missing_central_directory_warning`] |
//! | "crafted central-directory name running past EOF never throws (ENG-1 regression, Stage-2 entry gate)" (:171) | [`dart_suite_crafted_name_past_eof_never_throws_eng1`] |
//!
//! TS bridge suite — `scripts/txf_taxfile_test.mjs`, section "2. .tax
//! analysis" (the four `[tax]` groups; the `[txf]` and `[cfr]` groups in
//! the same file belong to the TXF/envelope workers and are NOT ported
//! here — no single group mixes `[tax]` with `[txf]`/`[cfr]` labels, so
//! nothing was split):
//!
//! | Original `[tax]` group | Ported test below |
//! | --- | --- |
//! | "[tax] ClearFile exchange container round-trip" (:165) | [`bridge_tax_clearfile_exchange_container_round_trip`] |
//! | "[tax] Intuit container shape detected + flagged encrypted" (:186) | [`bridge_tax_intuit_shape_detected_flagged_encrypted`] |
//! | "[tax] low-entropy textual entry" (:216) | [`bridge_tax_low_entropy_textual_entry`] |
//! | "[tax] non-ZIP and empty honest paths" (:232) | [`bridge_tax_non_zip_and_empty_honest_paths`] |
//!
//! Plus (this port's own pins, no reference twin): the writer batteries —
//! `crc32`/`entropy_of` basics, `export_tax_container` field-by-field
//! layout + verbatim README, the export→inspect round-trip, and the
//! ZIP32 field-width refusals — and the `battery extension:` section of
//! adversarial malformed-ZIP cases (see its header).
//!
//! # Fixture-generation divergences (assertions unchanged)
//!
//! 1. The Dart suite's two "random-looking blob" fixtures use the Dart-VM
//!    `Random(1234)` / `Random(99)` streams, which have no Rust twin.
//!    Both use the TS bridge suite's deterministic **xorshift32** stream
//!    instead (txf_taxfile_test.mjs:189-197), keeping the Dart seeds'
//!    numbers (1234 / 99) and sizes (1024 / 4096) — the assertions pinned
//!    are behavioral (entropy > 7.5, no PK prefix), not stream identity.
//! 2. `serializeCfr` / the Flutter model's `toJson` produce envelope JSON
//!    via the reference codecs; the fixtures here build the same JSON
//!    shapes with [`Json`] (`crate::json`, the core's codec — the envelope
//!    codec module `crate::envelope` lands with a parallel worker and is
//!    deliberately not depended on here).
//!
//! # THE PAYLOAD SEAM in the assertions (ADR-017 FFI-boundary conformance)
//!
//! The references decode the envelope inline at the end of
//! `analyzeTaxFile` (`ReturnFileCodec.decode` / `parseCfr`) and expose the
//! decoded `filing`; this port carries the `clearfile.json` payload out as
//! a STRING (`TaxInspection::clearfile_payload`) and the CALLER composes
//! `crate::envelope::decode` over it (module docs of
//! `core/src/tax_inspect.rs`). Every ported test therefore:
//! - asserts the payload is carried out VERBATIM (byte-identical to the
//!   fixture text), and
//! - performs the reference's `filing.*` assertions at the SEAM level
//!   via [`Json::parse`] (the same refusal the composition would make) —
//!   the composed import function and its envelope-level tests land at
//!   integration, where the reference's fall-through-with-warning shape
//!   (dart:162-168 / taxfile.ts:330-335) is re-assembled.

use clearfile_core::json::Json;
use clearfile_core::tax_inspect::{
    analyze_tax_file, crc32, entropy_of, export_tax_container, make_zip, TaxInspectError,
    TAX_CONTAINER_README,
};

// ---------------------------------------------------------------------------
// Test-side helpers.
// ---------------------------------------------------------------------------

/// One fixture-ZIP entry: raw name bytes (so the battery can forge
/// invalid-UTF-8 names), data, and an explicit method — the Dart suite's
/// own fixture writer generalized (its `deflateAlso` list folded into one
/// ordered list; see [`fixture_zip`]).
struct FixtureEntry<'a> {
    name: &'a [u8],
    data: &'a [u8],
    method: u16,
}

/// A STORE-method fixture entry (Dart suite `_ZipEntry`).
fn stored<'a>(name: &'a str, data: &'a [u8]) -> FixtureEntry<'a> {
    FixtureEntry {
        name: name.as_bytes(),
        data,
        method: 0,
    }
}

/// A method-8 fixture entry whose payload is NOT actually deflated —
/// exactly the Dart suite's `deflateAlso` shape (the listing behavior is
/// what the tests pin; nothing inflates).
fn deflate<'a>(name: &'a str, data: &'a [u8]) -> FixtureEntry<'a> {
    FixtureEntry {
        name: name.as_bytes(),
        data,
        method: 8,
    }
}

/// A STORE entry with raw (possibly non-UTF-8) name bytes — battery only.
fn raw_stored<'a>(name: &'a [u8], data: &'a [u8]) -> FixtureEntry<'a> {
    FixtureEntry {
        name,
        data,
        method: 0,
    }
}

/// Independent CRC-32 (reflected 0xedb88320), bitwise — a DIFFERENT
/// implementation shape than the module's table-based one, so the fixture
/// writer does not merely trust the code under test (the Dart suite's
/// `_crc32`, tax_inspect_test.dart:224-230, is the same independent twin).
fn crc32_bitwise(data: &[u8]) -> u32 {
    let mut c = 0xFFFF_FFFFu32;
    for &b in data {
        c ^= b as u32;
        for _ in 0..8 {
            c = if c & 1 != 0 {
                0xEDB8_8320 ^ (c >> 1)
            } else {
                c >> 1
            };
        }
    }
    c ^ 0xFFFF_FFFF
}

/// The minimal STORE/deflate-marker ZIP fixture writer — the port of the
/// Dart suite's `_makeZip` (tax_inspect_test.dart:241-313), same field
/// layout field-for-field: local (30 + name + data), central (46 + name),
/// EOCD (22); flags 0, fixed DOS time 0 / date 0x21 (1980-01-01),
/// versions 20/20. Generalized over the Dart original in exactly one way:
/// one ordered entry list carries the method (the Dart `deflateAlso`
/// parameter pairs with it).
fn fixture_zip(entries: &[FixtureEntry<'_>]) -> Vec<u8> {
    let mut locals: Vec<u8> = Vec::new();
    let mut centrals: Vec<u8> = Vec::new();
    let mut offset: usize = 0;

    for e in entries {
        let name = e.name;
        let data = e.data;
        let crc = crc32_bitwise(data);
        let size = data.len();

        // local file header (tax_inspect_test.dart:258-273)
        locals.extend_from_slice(&0x0403_4b50u32.to_le_bytes());
        locals.extend_from_slice(&20u16.to_le_bytes()); // version needed
        locals.extend_from_slice(&0u16.to_le_bytes()); // flags
        locals.extend_from_slice(&e.method.to_le_bytes());
        locals.extend_from_slice(&0u16.to_le_bytes()); // time
        locals.extend_from_slice(&0x21u16.to_le_bytes()); // date 1980-01-01
        locals.extend_from_slice(&crc.to_le_bytes());
        locals.extend_from_slice(&(size as u32).to_le_bytes()); // compressed
        locals.extend_from_slice(&(size as u32).to_le_bytes()); // uncompressed
        locals.extend_from_slice(&(name.len() as u16).to_le_bytes());
        locals.extend_from_slice(&0u16.to_le_bytes()); // extra length
        locals.extend_from_slice(name);
        locals.extend_from_slice(data);

        // central directory record (tax_inspect_test.dart:275-295)
        centrals.extend_from_slice(&0x0201_4b50u32.to_le_bytes());
        centrals.extend_from_slice(&20u16.to_le_bytes()); // version made by
        centrals.extend_from_slice(&20u16.to_le_bytes()); // version needed
        centrals.extend_from_slice(&0u16.to_le_bytes()); // flags
        centrals.extend_from_slice(&e.method.to_le_bytes());
        centrals.extend_from_slice(&0u16.to_le_bytes()); // time
        centrals.extend_from_slice(&0x21u16.to_le_bytes()); // date
        centrals.extend_from_slice(&crc.to_le_bytes());
        centrals.extend_from_slice(&(size as u32).to_le_bytes());
        centrals.extend_from_slice(&(size as u32).to_le_bytes());
        centrals.extend_from_slice(&(name.len() as u16).to_le_bytes());
        centrals.extend_from_slice(&0u16.to_le_bytes()); // extra
        centrals.extend_from_slice(&0u16.to_le_bytes()); // comment
        centrals.extend_from_slice(&0u16.to_le_bytes()); // disk number
        centrals.extend_from_slice(&0u16.to_le_bytes()); // internal attrs
        centrals.extend_from_slice(&0u32.to_le_bytes()); // external attrs
        centrals.extend_from_slice(&(offset as u32).to_le_bytes());
        centrals.extend_from_slice(name);

        offset += 30 + name.len() + size;
    }

    let central_size = centrals.len();
    // end of central directory (tax_inspect_test.dart:301-310)
    let mut end: Vec<u8> = Vec::with_capacity(22);
    end.extend_from_slice(&0x0605_4b50u32.to_le_bytes());
    end.extend_from_slice(&0u16.to_le_bytes()); // disk number
    end.extend_from_slice(&0u16.to_le_bytes()); // disk with the directory
    end.extend_from_slice(&(entries.len() as u16).to_le_bytes()); // this disk
    end.extend_from_slice(&(entries.len() as u16).to_le_bytes()); // total
    end.extend_from_slice(&(central_size as u32).to_le_bytes());
    end.extend_from_slice(&(offset as u32).to_le_bytes());
    end.extend_from_slice(&0u16.to_le_bytes()); // comment length

    locals.extend_from_slice(&centrals);
    locals.extend_from_slice(&end);
    locals
}

/// The deterministic xorshift32 byte stream (the TS bridge suite's
/// high-entropy fixture generator, txf_taxfile_test.mjs:189-197 —
/// `seed ^= seed << 13; seed ^= seed >>> 17; seed ^= seed << 5`).
/// Used where the Dart suite's VM-`Random` streams have no Rust twin
/// (fixture-generation divergence 1 in the module docs).
fn xorshift32(seed: u32, n: usize) -> Vec<u8> {
    let mut s = seed;
    let mut out = Vec::with_capacity(n);
    for _ in 0..n {
        s ^= s.wrapping_shl(13);
        s ^= s >> 17;
        s ^= s.wrapping_shl(5);
        out.push((s & 0xFF) as u8);
    }
    out
}

/// Little-endian readers for the tests' field forgery/inspection
/// (panicking indexers are acceptable here: an out-of-bounds read is a
/// TEST failure, never a library contract).
fn le_u16(b: &[u8], at: usize) -> u16 {
    u16::from_le_bytes([b[at], b[at + 1]])
}

fn le_u32(b: &[u8], at: usize) -> u32 {
    u32::from_le_bytes([b[at], b[at + 1], b[at + 2], b[at + 3]])
}

fn set_u16(b: &mut [u8], at: usize, v: u16) {
    b[at..at + 2].copy_from_slice(&v.to_le_bytes());
}

fn set_u32(b: &mut [u8], at: usize, v: u32) {
    b[at..at + 4].copy_from_slice(&v.to_le_bytes());
}

fn put_u16(b: &mut Vec<u8>, v: u16) {
    b.extend_from_slice(&v.to_le_bytes());
}

fn put_u32(b: &mut Vec<u8>, v: u32) {
    b.extend_from_slice(&v.to_le_bytes());
}

/// The Dart ENG-1 test's own tail scan (tax_inspect_test.dart:184-190):
/// the LAST end-of-central-directory signature in the buffer (scanning
/// downward from `len − 22`, unbounded — the test's scan, not the
/// module's windowed one).
fn tail_scan_eocd(b: &[u8]) -> usize {
    let mut i = b.len() as i64 - 22;
    while i >= 0 {
        if le_u32(b, i as usize) == 0x0605_4b50 {
            return i as usize;
        }
        i -= 1;
    }
    panic!("fixture carries no end-of-central-directory record");
}

/// The first central-directory record's offset (EOCD field at +16).
fn central_ptr(b: &[u8]) -> usize {
    le_u32(b, tail_scan_eocd(b) + 16) as usize
}

// ---------------------------------------------------------------------------
// Ported: clearfile/test/tax_inspect_test.dart (all 10 tests).
// ---------------------------------------------------------------------------

// Dart suite: "ClearFile exchange container is detected and imported"
// (tax_inspect_test.dart:16-35).
#[test]
fn dart_suite_exchange_container_is_detected_and_imported() {
    // The Dart test serializes the model with JsonEncoder.withIndent('  ')
    // — a pretty flat-layout filing JSON. The port carries the payload as
    // a string (the seam), so the fixture builds the same shape with
    // crate::json's byte-identical pretty writer.
    let filing = Json::Obj(vec![
        ("format".into(), "clearfile.return".into()),
        ("formatVersion".into(), 1i64.into()),
        ("displayName".into(), "Exchange test".into()),
        ("w2s".into(), Json::Arr(vec![])),
        ("interestIncome".into(), 120i64.into()),
    ]);
    let json = filing.write_pretty("  ").unwrap();
    let bytes = fixture_zip(&[
        stored("clearfile.json", json.as_bytes()),
        stored("README.txt", b"ClearFile exchange container"),
    ]);

    let insp = analyze_tax_file(&bytes);
    assert!(insp.is_zip);
    assert!(insp.clearfile_container);
    assert!(!insp.intuit_modern_container);
    // filing != null → the payload seam: carried out, verbatim.
    assert_eq!(insp.clearfile_payload.as_deref(), Some(json.as_str()));
    assert!(insp.summary.contains("ClearFile exchange container"));

    // dart:33 `filing!.interestIncome == 120`, asserted at the seam: the
    // composition's Json::parse (then envelope decode) reads 120 back.
    let parsed = Json::parse(insp.clearfile_payload.as_deref().unwrap()).unwrap();
    assert_eq!(parsed.get("interestIncome").and_then(Json::as_f64), Some(120.0));
}

// Dart suite: "web-written envelope container imports (cross-codebase
// shape, ADR-015)" (tax_inspect_test.dart:37-65).
#[test]
fn dart_suite_web_written_envelope_container_imports() {
    // The Dart test jsonEncode's the VERSIONED envelope (clearfile-return
    // v2) — compact, insertion-ordered. Built here with crate::json's
    // byte-identical writer (fixture divergence 2).
    let filing = Json::Obj(vec![
        ("displayName".into(), "Web container".into()),
        (
            "w2s".into(),
            Json::Arr(vec![Json::Obj(vec![
                ("employer".into(), "Initech".into()),
                ("wages".into(), 60000i64.into()),
                ("withholding".into(), 6000i64.into()),
            ])]),
        ),
    ]);
    let envelope = Json::Obj(vec![
        ("format".into(), "clearfile-return".into()),
        ("version".into(), 2i64.into()),
        ("app".into(), "ClearFile prototype 0.2".into()),
        ("savedAt".into(), "2026-11-15T02:00:00.000Z".into()),
        ("filing".into(), filing),
    ]);
    let text = envelope.write().unwrap();
    let bytes = fixture_zip(&[
        stored("clearfile.json", text.as_bytes()),
        stored("README.txt", b"ClearFile exchange container"),
    ]);

    let insp = analyze_tax_file(&bytes);
    assert!(insp.clearfile_container);
    // dart:62-64 displayName / w2s.single.employer, at the seam:
    assert_eq!(insp.clearfile_payload.as_deref(), Some(text.as_str()));
    let parsed = Json::parse(insp.clearfile_payload.as_deref().unwrap()).unwrap();
    let filing = parsed.get("filing").unwrap();
    assert_eq!(
        filing.get("displayName").and_then(Json::as_str),
        Some("Web container")
    );
    let w2 = filing
        .get("w2s")
        .and_then(Json::as_arr)
        .and_then(|a| a.first())
        .unwrap();
    assert_eq!(w2.get("employer").and_then(Json::as_str), Some("Initech"));
}

// Dart suite: "container with an unreadable clearfile.json falls through
// with a warning" (tax_inspect_test.dart:67-78).
#[test]
fn dart_suite_unreadable_clearfile_json_falls_through() {
    let bytes = fixture_zip(&[
        stored("clearfile.json", b"this is not json"),
        stored("README.txt", b"ClearFile exchange container"),
    ]);
    let insp = analyze_tax_file(&bytes);

    // THE PAYLOAD SEAM (module docs, divergence 2): the reference's
    // inline envelope decode fails here, so it flips clearfileContainer
    // to false, adds the warning "clearfile.json could not be parsed:
    // <reason>" (dart:162-163) and falls through to the plain-ZIP
    // analysis. The port carries the payload out (container SHAPE true)
    // and that fall-through is the CALLER's composition over
    // crate::envelope::decode — re-assembled at integration. What this
    // test pins: the payload is carried verbatim, and the composition's
    // refusal is detectable at the seam (the exact "could not be parsed"
    // wording belongs to the envelope module's tests, DEBT D34).
    assert!(insp.clearfile_container);
    assert_eq!(insp.clearfile_payload.as_deref(), Some("this is not json"));
    assert!(Json::parse(insp.clearfile_payload.as_deref().unwrap()).is_err());
}

// Dart suite: "modern Intuit container shape is detected, flagged
// encrypted, never imported" (tax_inspect_test.dart:80-109). The Dart
// "encrypted" stand-in is `Random(1234)` over 1024 bytes — NOT real key
// material, purely synthetic; the port uses the bridge suite's
// deterministic xorshift32 stream with the same seed number (fixture
// divergence 1).
#[test]
fn dart_suite_intuit_shape_detected_flagged_encrypted_never_imported() {
    let encrypted_looking = xorshift32(1234, 1024);
    let bytes = fixture_zip(&[
        stored("manifest.xml", b"<manifest/>"),
        stored("tax:7a1c2d3e-4f5a-6789-abcd-ef0123456789", &encrypted_looking),
    ]);

    let insp = analyze_tax_file(&bytes);
    assert!(insp.is_zip);
    assert!(insp.intuit_modern_container);
    assert!(!insp.clearfile_container);
    assert!(insp.clearfile_payload.is_none()); // dart:98 filing is null

    let data = insp
        .entries
        .iter()
        .find(|e| e.name.starts_with("tax:"))
        .unwrap();
    assert!(data.entropy.is_some());
    assert!(data.entropy.unwrap() > 7.5);
    assert_eq!(data.likely_encrypted, Some(true));

    // The safe bridges must be named, and the copy must state it does
    // not decrypt (protocol §2.2/§7) — dart:106-108.
    assert!(insp.summary.contains("does not decrypt"));
    assert!(insp.summary.contains("TXF"));
}

// Dart suite: "low-entropy textual entries are not flagged encrypted"
// (tax_inspect_test.dart:111-122). The exact 149-byte Dart string (25
// "hello" words: 5 + 10 + 10 across its three source lines).
#[test]
fn dart_suite_low_entropy_textual_entries_not_flagged() {
    // The Dart source builds the string as three adjacent literals
    // (5 + 10 + 10 "hello" words); `concat!` keeps that shape in Rust.
    let text = concat!(
        "hello hello hello hello hello ",
        "hello hello hello hello hello hello hello hello hello hello ",
        "hello hello hello hello hello hello hello hello hello hello"
    );
    assert_eq!(text.len(), 149);
    let bytes = fixture_zip(&[stored("notes.txt", text.as_bytes())]);

    let insp = analyze_tax_file(&bytes);
    assert_eq!(insp.entries.len(), 1);
    assert_eq!(insp.entries[0].likely_encrypted, Some(false));
    assert!(insp.entries[0]
        .preview
        .as_deref()
        .is_some_and(|p| p.contains("hello")));
}

// Dart suite: "non-ZIP file: honest summary with entropy, no crash"
// (tax_inspect_test.dart:124-136). The Dart `Random(99)` 4096-byte blob →
// xorshift32 seed 99, 4096 bytes (fixture divergence 1).
#[test]
fn dart_suite_non_zip_file_honest_summary_with_entropy() {
    let blob = xorshift32(99, 4096);
    let insp = analyze_tax_file(&blob);
    assert!(!insp.is_zip);
    assert!(insp.entries.is_empty());
    assert!(insp.summary.contains("Not a ZIP container"));
    assert!(insp.summary.contains("bits/byte"));
    // Entropy 7.95 bits/byte over the uniform-looking stream → the
    // encrypted/compressed-looking branch of the honest wording.
    assert!(insp.summary.contains("encrypted/compressed-looking"));

    let textual = analyze_tax_file(b"just some text");
    assert!(textual.summary.contains("not high-entropy"));
}

// Dart suite: "empty file: no crash, empty summary note"
// (tax_inspect_test.dart:138-142).
#[test]
fn dart_suite_empty_file_no_crash() {
    let insp = analyze_tax_file(&[]);
    assert!(!insp.is_zip);
    assert!(insp.summary.contains("empty"));
}

// Dart suite: "deflate entries are listed but not extracted"
// (tax_inspect_test.dart:144-157).
#[test]
fn dart_suite_deflate_entries_listed_but_not_extracted() {
    let bytes = fixture_zip(&[
        stored("stored.txt", b"plain"),
        deflate("compressed.bin", b"not actually deflated"),
    ]);
    let insp = analyze_tax_file(&bytes);
    assert_eq!(insp.entries.len(), 2);
    let compressed = insp
        .entries
        .iter()
        .find(|e| e.name == "compressed.bin")
        .unwrap();
    assert_eq!(compressed.method, 8);
    assert_eq!(compressed.entropy, None);
    assert!(insp.warnings.iter().any(|w| w.contains("deflate")));
}

// Dart suite: "truncated ZIP: warning about the missing central
// directory" (tax_inspect_test.dart:159-169) — the crafted 64-byte buffer
// as a byte literal: PK\x03\x04 then 60 zero bytes.
#[test]
fn dart_suite_truncated_zip_missing_central_directory_warning() {
    let garbage: [u8; 64] = [
        0x50, 0x4b, 0x03, 0x04, // PK\x03\x04
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    ];
    let insp = analyze_tax_file(&garbage);
    assert!(insp.is_zip);
    assert!(insp
        .warnings
        .iter()
        .any(|w| w.contains("end-of-central-directory")));
}

// Dart suite: "crafted central-directory name running past EOF never
// throws (ENG-1 regression, Stage-2 entry gate)"
// (tax_inspect_test.dart:171-199). A valid single-entry ZIP, then the
// central entry's name-length field is forged to 0xFFFF: the 46-byte
// header still fits at EOF but the claimed name field runs far past it —
// the exact shape that crashed `_readZipDirectory` with a RangeError
// before the 2026-11-17 bounds check. The contract under test: never
// throws on malformed input (a panic here fails this test).
#[test]
fn dart_suite_crafted_name_past_eof_never_throws_eng1() {
    let valid = fixture_zip(&[stored("a.txt", b"x")]);
    let mut forged = valid;

    // Locate the EOCD from the tail, then the first central entry, using
    // the same scan the inspector uses (dart:184-190).
    let eocd = tail_scan_eocd(&forged);
    let ptr = le_u32(&forged, eocd + 16) as usize;
    assert_eq!(le_u32(&forged, ptr), 0x0201_4b50);
    set_u16(&mut forged, ptr + 28, 0xFFFF); // nameLen past EOF

    let insp = analyze_tax_file(&forged);
    assert!(insp.is_zip);
    assert!(insp
        .warnings
        .iter()
        .any(|w| w.contains("name extends past end of file")));
    assert!(insp.entries.is_empty()); // the walk stopped before the entry
}

// ---------------------------------------------------------------------------
// Ported: scripts/txf_taxfile_test.mjs, section "2. .tax analysis" — the
// four [tax] groups. Fixtures are built with the PORT'S OWN app writer
// (make_zip), exactly as the bridge suite builds them with the app's own
// makeZip (txf_taxfile_test.mjs:54-57, 172, 198, 218).
// ---------------------------------------------------------------------------

// Bridge suite: "[tax] ClearFile exchange container round-trip"
// (txf_taxfile_test.mjs:165-184). The envelope is serializeCfr's v2
// output shape — JSON.stringify(file, null, 2) — built here with
// crate::json's byte-identical pretty writer (fixture divergence 2).
#[test]
fn bridge_tax_clearfile_exchange_container_round_trip() {
    let filing = Json::Obj(vec![
        ("taxYear".into(), 2025i64.into()),
        (
            "w2s".into(),
            Json::Arr(vec![Json::Obj(vec![
                ("employer".into(), "Acme Corp".into()),
                ("wages".into(), 52500i64.into()),
                ("withholding".into(), 6200i64.into()),
            ])]),
        ),
        ("interestIncome".into(), 120i64.into()),
    ]);
    let envelope = Json::Obj(vec![
        ("format".into(), "clearfile-return".into()),
        ("version".into(), 2i64.into()),
        ("app".into(), "ClearFile prototype 0.2".into()),
        ("savedAt".into(), "2026-11-15T02:00:00.000Z".into()),
        ("filing".into(), filing),
    ]);
    let text = envelope.write_pretty("  ").unwrap();
    let bytes = make_zip(&[
        ("clearfile.json", text.as_bytes()),
        ("README.txt", b"ClearFile exchange container"),
    ])
    .unwrap();

    let a = analyze_tax_file(&bytes);
    assert!(a.is_zip);
    assert!(a.clearfile_container);
    assert!(!a.intuit_modern_container);
    // mjs:180 filing.interestIncome === 120, at the seam:
    assert_eq!(a.clearfile_payload.as_deref(), Some(text.as_str()));
    let parsed = Json::parse(a.clearfile_payload.as_deref().unwrap()).unwrap();
    assert_eq!(
        parsed
            .get("filing")
            .and_then(|f| f.get("interestIncome"))
            .and_then(Json::as_f64),
        Some(120.0)
    );
    assert_eq!(a.entries.len(), 2);
}

// Bridge suite: "[tax] Intuit container shape detected + flagged
// encrypted" (txf_taxfile_test.mjs:186-214) — the synthetic high-entropy
// payload via the deterministic xorshift32 stream (seed 123456789),
// exactly the bridge suite's generator.
#[test]
fn bridge_tax_intuit_shape_detected_flagged_encrypted() {
    let payload = xorshift32(123_456_789, 1024);
    let bytes = make_zip(&[
        ("manifest.xml", b"<manifest/>"),
        ("tax:7a1c2d3e-4f5a-6789-abcd-ef0123456789", &payload),
    ])
    .unwrap();
    let a = analyze_tax_file(&bytes);
    assert!(a.is_zip);
    assert!(a.intuit_modern_container);
    assert!(!a.clearfile_container);
    assert!(a.clearfile_payload.is_none()); // mjs:206 filing undefined
    let data = a
        .entries
        .iter()
        .find(|e| e.name.starts_with("tax:"))
        .unwrap();
    assert!(data.entropy.unwrap() > 7.5, "entropy {:?}", data.entropy);
    assert_eq!(data.likely_encrypted, Some(true));
    assert!(a.summary.contains("does not decrypt"));
    assert!(a.summary.contains("TXF"));
}

// Bridge suite: "[tax] low-entropy textual entry"
// (txf_taxfile_test.mjs:216-230) — 'hello '.repeat(64), 384 bytes.
#[test]
fn bridge_tax_low_entropy_textual_entry() {
    let data = b"hello ".repeat(64); // 384 bytes
    let bytes = make_zip(&[("notes.txt", &data)]).unwrap();
    let a = analyze_tax_file(&bytes);
    let e = &a.entries[0];
    assert_eq!(e.likely_encrypted, Some(false));
    assert!(e.preview.as_deref().is_some_and(|p| p.starts_with("hello")));
}

// Bridge suite: "[tax] non-ZIP and empty honest paths"
// (txf_taxfile_test.mjs:232-241).
#[test]
fn bridge_tax_non_zip_and_empty_honest_paths() {
    let a = analyze_tax_file(b"just some text");
    assert!(!a.is_zip);
    assert!(a.summary.contains("not high-entropy"));
    let b = analyze_tax_file(&[]);
    assert_eq!(b.summary, "The file is empty.");
}

// ---------------------------------------------------------------------------
// The writer pins (this port's own; the references' suites pin the writer
// only through their fixtures' round-trips — the port surfaces the
// app-writer surface makeZip, so the layout gets pinned directly).
// ---------------------------------------------------------------------------

/// `crc32` standard check value (CRC-32/ISO-HDLC) + `entropy_of` basics.
/// The bitwise twin (crc32_bitwise, above) double-checks the table-based
/// module implementation on every fixture this file builds.
#[test]
fn crc32_standard_check_value_and_entropy_basics() {
    assert_eq!(crc32(b"123456789"), 0xCBF4_3926);
    assert_eq!(crc32(b""), 0);
    assert_eq!(crc32(b"123456789"), crc32_bitwise(b"123456789"));
    // the fixture README, at writer length, through both implementations:
    assert_eq!(crc32(TAX_CONTAINER_README.as_bytes()), crc32_bitwise(TAX_CONTAINER_README.as_bytes()));

    assert_eq!(entropy_of(&[]), 0.0);
    assert_eq!(entropy_of(b"aaaa"), 0.0);
    let two_symbols = entropy_of(b"aabb"); // p = 1/2 twice → exactly 1 bit
    assert!((two_symbols - 1.0).abs() < 1e-12);
    assert!(entropy_of(&xorshift32(123_456_789, 1024)) > 7.5);
}

/// `export_tax_container` layout, field-by-field — the port of
/// `makeZip`/`exportTaxContainer` (taxfile.ts:99-177, 384-389): entry
/// order (clearfile.json, then README.txt), every local-header /
/// central-directory / end-record field, the fixed 1980-01-01 DOS stamp
/// (module divergence 8), and the table-based CRC-32.
#[test]
fn export_tax_container_layout_field_by_field() {
    let payload = "{\"format\":\"clearfile-return\",\"version\":2}";
    let bytes = export_tax_container(payload).unwrap();
    let readme = TAX_CONTAINER_README.as_bytes();
    let l = payload.len();
    let nl = "clearfile.json".len(); // 13
    let rl = "README.txt".len(); // 10
    let e0 = 30 + nl + l; // end of entry-0's local record
    let e1 = e0 + 30 + rl + readme.len(); // end of entry-1's local record
    let c0 = e1; // central directory start (== total local size)
    let central_size = (46 + nl) + (46 + rl);
    assert_eq!(bytes.len(), e1 + central_size + 22);

    // --- entry 0 local file header (taxfile.ts:110-125) ---
    assert_eq!(le_u32(&bytes, 0), 0x0403_4b50);
    assert_eq!(le_u16(&bytes, 4), 20); // version needed
    assert_eq!(le_u16(&bytes, 6), 0x0800); // flags: UTF-8 names
    assert_eq!(le_u16(&bytes, 8), 0); // method: store
    assert_eq!(le_u16(&bytes, 10), 0); // DOS time (fixed stamp)
    assert_eq!(le_u16(&bytes, 12), 0x21); // DOS date 1980-01-01
    assert_eq!(le_u32(&bytes, 14), crc32(payload.as_bytes()));
    assert_eq!(le_u32(&bytes, 18), l as u32); // compressed size
    assert_eq!(le_u32(&bytes, 22), l as u32); // uncompressed size
    assert_eq!(le_u16(&bytes, 26), nl as u16);
    assert_eq!(le_u16(&bytes, 28), 0); // extra length
    assert_eq!(&bytes[30..30 + nl], b"clearfile.json");
    assert_eq!(&bytes[30 + nl..e0], payload.as_bytes());

    // --- entry 1 local file header ---
    assert_eq!(le_u32(&bytes, e0), 0x0403_4b50);
    assert_eq!(le_u16(&bytes, e0 + 4), 20);
    assert_eq!(le_u16(&bytes, e0 + 6), 0x0800);
    assert_eq!(le_u16(&bytes, e0 + 8), 0);
    assert_eq!(le_u16(&bytes, e0 + 10), 0);
    assert_eq!(le_u16(&bytes, e0 + 12), 0x21);
    assert_eq!(le_u32(&bytes, e0 + 14), crc32(readme));
    assert_eq!(le_u32(&bytes, e0 + 18), readme.len() as u32);
    assert_eq!(le_u32(&bytes, e0 + 22), readme.len() as u32);
    assert_eq!(le_u16(&bytes, e0 + 26), rl as u16);
    assert_eq!(le_u16(&bytes, e0 + 28), 0);
    assert_eq!(&bytes[e0 + 30..e0 + 30 + rl], b"README.txt");
    assert_eq!(&bytes[e0 + 30 + rl..e1], readme);

    // --- central directory record 0 (taxfile.ts:127-147) ---
    assert_eq!(le_u32(&bytes, c0), 0x0201_4b50);
    assert_eq!(le_u16(&bytes, c0 + 4), 20); // version made by
    assert_eq!(le_u16(&bytes, c0 + 6), 20); // version needed
    assert_eq!(le_u16(&bytes, c0 + 8), 0x0800); // flags
    assert_eq!(le_u16(&bytes, c0 + 10), 0); // method
    assert_eq!(le_u16(&bytes, c0 + 12), 0); // time
    assert_eq!(le_u16(&bytes, c0 + 14), 0x21); // date
    assert_eq!(le_u32(&bytes, c0 + 16), crc32(payload.as_bytes()));
    assert_eq!(le_u32(&bytes, c0 + 20), l as u32);
    assert_eq!(le_u32(&bytes, c0 + 24), l as u32);
    assert_eq!(le_u16(&bytes, c0 + 28), nl as u16);
    assert_eq!(le_u16(&bytes, c0 + 30), 0); // extra
    assert_eq!(le_u16(&bytes, c0 + 32), 0); // comment
    assert_eq!(le_u16(&bytes, c0 + 34), 0); // disk number
    assert_eq!(le_u16(&bytes, c0 + 36), 0); // internal attrs
    assert_eq!(le_u32(&bytes, c0 + 38), 0); // external attrs
    assert_eq!(le_u32(&bytes, c0 + 42), 0); // local header offset
    assert_eq!(&bytes[c0 + 46..c0 + 46 + nl], b"clearfile.json");

    // --- central directory record 1 ---
    let c1 = c0 + 46 + nl;
    assert_eq!(le_u32(&bytes, c1), 0x0201_4b50);
    assert_eq!(le_u16(&bytes, c1 + 4), 20);
    assert_eq!(le_u16(&bytes, c1 + 6), 20);
    assert_eq!(le_u16(&bytes, c1 + 8), 0x0800);
    assert_eq!(le_u16(&bytes, c1 + 10), 0);
    assert_eq!(le_u16(&bytes, c1 + 12), 0);
    assert_eq!(le_u16(&bytes, c1 + 14), 0x21);
    assert_eq!(le_u32(&bytes, c1 + 16), crc32(readme));
    assert_eq!(le_u32(&bytes, c1 + 20), readme.len() as u32);
    assert_eq!(le_u32(&bytes, c1 + 24), readme.len() as u32);
    assert_eq!(le_u16(&bytes, c1 + 28), rl as u16);
    assert_eq!(le_u16(&bytes, c1 + 30), 0);
    assert_eq!(le_u16(&bytes, c1 + 32), 0);
    assert_eq!(le_u16(&bytes, c1 + 34), 0);
    assert_eq!(le_u16(&bytes, c1 + 36), 0);
    assert_eq!(le_u32(&bytes, c1 + 38), 0);
    assert_eq!(le_u32(&bytes, c1 + 42), e0 as u32); // entry-1 local offset
    assert_eq!(&bytes[c1 + 46..c1 + 46 + rl], b"README.txt");

    // --- end of central directory (taxfile.ts:153-162) ---
    let eo = e1 + central_size;
    assert_eq!(le_u32(&bytes, eo), 0x0605_4b50);
    assert_eq!(le_u16(&bytes, eo + 4), 0); // disk number
    assert_eq!(le_u16(&bytes, eo + 6), 0); // disk with the directory
    assert_eq!(le_u16(&bytes, eo + 8), 2); // entries this disk
    assert_eq!(le_u16(&bytes, eo + 10), 2); // entries total
    assert_eq!(le_u32(&bytes, eo + 12), central_size as u32);
    assert_eq!(le_u32(&bytes, eo + 16), e1 as u32); // directory offset
    assert_eq!(le_u16(&bytes, eo + 20), 0); // comment length
}

/// The exported container reads back through the port's own inspector —
/// the mirror of the bridge suite's round-trip group — and the README
/// inside is the honest labeling VERBATIM (spec
/// docs/formats/tax-exchange-container.md §2: "the honest labeling
/// (README.txt, verbatim owner text)"), pinned here by an INDEPENDENT
/// literal (not TAX_CONTAINER_README), so a wording drift fails the test.
#[test]
fn export_tax_container_round_trip_through_analyze() {
    // The wording contract — taxfile.ts:367-382, byte-for-byte.
    let expected_readme = "ClearFile exchange container
================================

This file uses the .tax extension but it is NOT Intuit's proprietary
TurboTax .tax format. It is an open ZIP container written by the ClearFile
prototype containing:

  - clearfile.json  ClearFile Return (open JSON schema, documented)

Why: Intuit's .tax internals are undocumented; writing a genuinely
compatible file requires a separately-scoped reverse-engineering effort
(see the engineering blueprint). This container keeps one \".tax\" file per
year for your own records and can be re-imported here at any time.

Generated by ClearFile prototype 0.1 — demo software, not for filing.
";
    assert_eq!(TAX_CONTAINER_README, expected_readme);

    let payload = "{\"format\":\"clearfile-return\",\"version\":2,\"filing\":{\"interestIncome\":120}}";
    let bytes = export_tax_container(payload).unwrap();
    let insp = analyze_tax_file(&bytes);
    assert!(insp.is_zip);
    assert!(insp.clearfile_container);
    assert!(!insp.intuit_modern_container);
    assert_eq!(insp.clearfile_payload.as_deref(), Some(payload));

    assert_eq!(insp.entries.len(), 2);
    assert_eq!(insp.entries[0].name, "clearfile.json");
    assert_eq!(insp.entries[0].method, 0);
    assert_eq!(insp.entries[0].data.as_deref(), Some(payload.as_bytes()));
    assert_eq!(insp.entries[1].name, "README.txt");
    assert_eq!(insp.entries[1].method, 0);
    assert_eq!(insp.entries[1].data.as_deref(), Some(expected_readme.as_bytes()));
    // the README is textual and < 200,000 bytes → preview = its first 300
    // bytes, lossily decoded (dart:123-126)
    let take = expected_readme.len().min(300);
    assert_eq!(insp.entries[1].preview.as_deref(), Some(&expected_readme[..take]));
    assert!(insp.summary.contains("ClearFile exchange container"));
}

/// The writer's ZIP32 field-width refusals (module divergence 9: the
/// references would throw (Dart) or silently wrap the field (JS); the
/// port refuses with a named error rather than emit a corrupt container).
///
/// The > 4 GiB guards (`EntryDataTooLarge`, `ContainerTooLarge`) are the
/// same guard family but cannot be exercised without a > 4 GiB
/// allocation; the READER side of that family is what the crash battery
/// actually protects (a forged ~4 GiB claimed size never allocates — see
/// `battery extension:` below).
#[test]
fn writer_zip32_field_width_refusals() {
    // 65,536 entries refuse; the boundary 65,535 fits the count fields.
    let many: Vec<(&str, &[u8])> = vec![("e", b"" as &[u8]); 65_536];
    assert_eq!(
        make_zip(&many),
        Err(TaxInspectError::TooManyEntries { count: 65_536 })
    );
    let max = vec![("e", b"" as &[u8]); 65_535];
    let bytes = make_zip(&max).unwrap();
    // 78 bytes per entry (30+1 local, 46+1 central) + 22 EOCD.
    assert_eq!(bytes.len(), 65_535 * 78 + 22);
    let eo = bytes.len() - 22;
    assert_eq!(le_u16(&bytes, eo + 8), 0xFFFF); // count exactly at the field max
    assert_eq!(le_u16(&bytes, eo + 10), 0xFFFF);

    // A 65,536-byte name refuses; the boundary 65,535 fits.
    let long_name = "a".repeat(65_536);
    assert_eq!(
        make_zip(&[(long_name.as_str(), b"")]),
        Err(TaxInspectError::EntryNameTooLong { len: 65_536 })
    );
    let boundary = "a".repeat(65_535);
    let bytes = make_zip(&[(boundary.as_str(), b"x")]).unwrap();
    assert_eq!(bytes.len(), (30 + 65_535 + 1) + (46 + 65_535) + 22);
}

// ---------------------------------------------------------------------------
// battery extension: adversarial malformed-ZIP cases the reference
// batteries do not pin. Each case inputs a crafted buffer to
// analyze_tax_file and asserts an honest named outcome — NEVER a panic
// (the ENG-1 template: if a case below panics, the PORT is wrong).
// ---------------------------------------------------------------------------

// battery extension: the EOCD scan window bound. A real EOCD pushed more
// than 66,000 bytes from the tail is honestly MISSED (dart:232-233
// bounds the tail scan; taxfile.ts:193) — while an EOCD exactly at the
// window boundary (offset len − 66,000) is still found (the scan's
// `i >= scanFrom` lower bound is inclusive).
#[test]
fn battery_eocd_scan_window_bound() {
    let base = fixture_zip(&[stored("a.txt", b"x")]); // 109 bytes, EOCD at 87
    assert_eq!(base.len(), 109);

    // 70,000 trailing bytes: the EOCD (at 87) sits outside the tail
    // 66,000-byte window → not found, honest note, no entries, no panic.
    let mut missed = base.clone();
    missed.extend(std::iter::repeat(b'A').take(70_000));
    let insp = analyze_tax_file(&missed);
    assert!(insp.is_zip);
    assert!(insp.entries.is_empty());
    assert!(insp
        .warnings
        .iter()
        .any(|w| w == "No ZIP end-of-central-directory record found."));

    // Exactly at the boundary: len = 66,087 → window starts at 87 ==
    // the EOCD's offset → still found (the inclusive lower bound).
    let mut boundary = base;
    boundary.extend(std::iter::repeat(b'A').take(65_978));
    assert_eq!(boundary.len(), 66_087);
    let insp = analyze_tax_file(&boundary);
    assert_eq!(insp.entries.len(), 1);
    assert!(insp.warnings.is_empty());
}

// battery extension: a decoy EOCD AFTER the real one wins the tail scan
// (the scanner returns the FIRST signature found scanning downward — the
// highest offset). The decoy's garbage fields produce the honest corrupt
// note; nothing is read out of the real directory.
#[test]
fn battery_decoy_eocd_after_real_one_wins_the_tail_scan() {
    let base = fixture_zip(&[stored("a.txt", b"x")]);
    let mut bytes = base.clone();
    // A second EOCD-shaped record appended after the real one: count 1,
    // central-directory offset 0 (pointing at the local-file header).
    put_u32(&mut bytes, 0x0605_4b50);
    put_u16(&mut bytes, 0);
    put_u16(&mut bytes, 0);
    put_u16(&mut bytes, 1); // count this disk
    put_u16(&mut bytes, 1); // total
    put_u32(&mut bytes, 0); // central size
    put_u32(&mut bytes, 0); // central offset 0
    put_u16(&mut bytes, 0); // comment

    let insp = analyze_tax_file(&bytes);
    assert!(insp.is_zip);
    assert!(insp.entries.is_empty());
    assert!(insp
        .warnings
        .iter()
        .any(|w| w == "Central directory truncated or corrupt; stopped early."));
}

// battery extension: the EOCD's central-directory offset pointing far
// past EOF (0xFFFFFFFF). The record read bounds-checks before ANY field
// is read — the honest corrupt note, never an out-of-bounds read.
#[test]
fn battery_eocd_central_directory_offset_past_eof() {
    let mut bytes = fixture_zip(&[stored("a.txt", b"x")]);
    let eocd = tail_scan_eocd(&bytes);
    set_u32(&mut bytes, eocd + 16, 0xFFFF_FFFF);

    let insp = analyze_tax_file(&bytes);
    assert!(insp.entries.is_empty());
    assert!(insp
        .warnings
        .iter()
        .any(|w| w == "Central directory truncated or corrupt; stopped early."));
}

// battery extension: EOCD count zero with real records present. The walk
// reads the THIS-disk count field (dart:244, `getUint16(eocd + 10)`) —
// the total-count field at +12 is never consulted — so a forged count of
// 0 honestly lists nothing, with no notes.
#[test]
fn battery_eocd_count_zero_with_records_present() {
    let mut bytes = fixture_zip(&[stored("a.txt", b"x"), stored("b.txt", b"y")]);
    let eocd = tail_scan_eocd(&bytes);
    set_u16(&mut bytes, eocd + 10, 0); // this-disk count → 0
    // (the total at eocd+12 stays 2 — proving only +10 is read)

    let insp = analyze_tax_file(&bytes);
    assert!(insp.is_zip);
    assert!(insp.entries.is_empty());
    assert!(insp.warnings.is_empty());
}

// battery extension: ZIP-looking files shorter than the 22-byte EOCD
// record. (a) five bytes: the `len > 4` gate passes (dart:221), the
// downward scan `len − 22` goes negative and never runs → the honest
// no-EOCD note; (b) exactly four bytes: the `len > 4` gate FAILS — a
// 4-byte file is not a ZIP at all and takes the non-ZIP path.
#[test]
fn battery_zip_looking_files_shorter_than_22_bytes() {
    let five: [u8; 5] = [0x50, 0x4b, 0x03, 0x04, 0x00];
    let insp = analyze_tax_file(&five);
    assert!(insp.is_zip);
    assert!(insp.entries.is_empty());
    assert!(insp
        .warnings
        .iter()
        .any(|w| w == "No ZIP end-of-central-directory record found."));

    let four: [u8; 4] = [0x50, 0x4b, 0x05, 0x06];
    let insp = analyze_tax_file(&four);
    assert!(!insp.is_zip);
    assert!(insp.summary.contains("Not a ZIP container"));
}

// battery extension: a bare end-of-central-directory record (PK\x05\x06 +
// 18 zero bytes) is a WELL-FORMED empty ZIP: zero entries, no notes, the
// plain-ZIP summary.
#[test]
fn battery_bare_eocd_is_a_valid_empty_zip() {
    let mut bare = [0u8; 22];
    bare[0] = 0x50;
    bare[1] = 0x4b;
    bare[2] = 0x05;
    bare[3] = 0x06;
    let insp = analyze_tax_file(&bare);
    assert!(insp.is_zip);
    assert!(insp.entries.is_empty());
    assert!(insp.warnings.is_empty());
    assert!(insp
        .summary
        .starts_with("ZIP container detected with the entries listed below"));
}

// battery extension: a STORE entry whose local-header offset points past
// EOF. The reference's guard (dart:274 `localOffset + 30 <=
// bytes.length`) fails → the entry is LISTED with no data and NO note
// (the silent else-fallthrough — dart:272-289 has no branch for it).
// Listed-but-silent is the faithful behavior; no panic.
#[test]
fn battery_store_local_offset_past_eof_silent_listing() {
    let mut bytes = fixture_zip(&[stored("a.txt", b"x"), stored("b.txt", b"y")]);
    let ptr = central_ptr(&bytes);
    set_u32(&mut bytes, ptr + 42, 0xFFFF_FFF0); // entry 0's local offset

    let insp = analyze_tax_file(&bytes);
    assert_eq!(insp.entries.len(), 2);
    assert_eq!(insp.entries[0].name, "a.txt");
    assert_eq!(insp.entries[0].method, 0);
    assert!(insp.entries[0].data.is_none()); // listed, silent
    assert_eq!(insp.entries[1].data.as_deref(), Some(&b"y"[..])); // intact
    assert!(insp.warnings.is_empty());
}

// battery extension: a STORE entry whose local header carries the WRONG
// signature (0xDEADBEEF, not PK\x03\x04). The Dart reader extracts only
// behind an intact local header (dart:274's signature check — module
// divergence 7; the TS twin would extract) → listed, no data, no note.
// The SECOND entry's local header is forged (not offset 0 — the file's
// leading bytes are the ZIP-family sniff, which must stay intact).
#[test]
fn battery_store_wrong_local_signature_no_extraction() {
    let bytes = fixture_zip(&[stored("a.txt", b"x"), stored("b.txt", b"y")]);
    let mut forged = bytes;
    // entry 0's local record is 30 + 5 + 1 = 36 bytes → entry 1's local
    // header sits at 36:
    assert_eq!(le_u32(&forged, 36), 0x0403_4b50);
    set_u32(&mut forged, 36, 0xDEAD_BEEF);

    let insp = analyze_tax_file(&forged);
    assert!(insp.is_zip);
    assert_eq!(insp.entries.len(), 2);
    assert_eq!(insp.entries[0].data.as_deref(), Some(&b"x"[..])); // intact
    assert_eq!(insp.entries[1].method, 0);
    assert!(insp.entries[1].data.is_none()); // wrong signature: silent
    assert!(insp.warnings.is_empty());
}

// battery extension: a STORE entry whose central-directory compressed
// size claims ~4 GiB (0xFFFFFFFF). Two pins: (1) the honest skip note;
// (2) NO allocation of the claimed size — the reader only ever slices a
// range it has proven fits inside the file (the > 4 GiB reader-side
// counterpart of the writer's EntryDataTooLarge refusal).
#[test]
fn battery_store_compressed_size_past_eof_skip_note() {
    let mut bytes = fixture_zip(&[stored("a.txt", b"x")]);
    let ptr = central_ptr(&bytes);
    set_u32(&mut bytes, ptr + 20, 0xFFFF_FFFF); // compressed size

    let insp = analyze_tax_file(&bytes);
    assert_eq!(insp.entries.len(), 1); // still listed
    assert!(insp.entries[0].data.is_none());
    assert!(insp
        .warnings
        .iter()
        .any(|w| w == "Entry \"a.txt\" extends past end of file; skipped."));
}

// battery extension: the `localOffset + 30 <= len` boundary is
// INCLUSIVE — a hand-crafted container whose only local header ends
// EXACTLY at EOF (local + 30 == len) passes the guard, then its one
// claimed data byte runs past EOF and gets the honest skip note. Layout:
// EOCD at 0, central record at 22, local header at 69 (99-byte file) —
// a directory-first arrangement the app writer never emits, so it is
// built field-by-field.
#[test]
fn battery_local_header_boundary_plus_30_inclusive() {
    let mut b: Vec<u8> = Vec::new();
    // end of central directory at 0 (22 bytes)
    put_u32(&mut b, 0x0605_4b50);
    put_u16(&mut b, 0); // disk number
    put_u16(&mut b, 0); // disk with the directory
    put_u16(&mut b, 1); // count this disk
    put_u16(&mut b, 1); // total
    put_u32(&mut b, 47); // central size (46 + 1-byte name)
    put_u32(&mut b, 22); // central offset (right after this record)
    put_u16(&mut b, 0); // comment length
    // central directory record at 22 (47 bytes: name "a")
    put_u32(&mut b, 0x0201_4b50);
    put_u16(&mut b, 20); // version made by
    put_u16(&mut b, 20); // version needed
    put_u16(&mut b, 0); // flags
    put_u16(&mut b, 0); // method: STORE
    put_u16(&mut b, 0); // time
    put_u16(&mut b, 0x21); // date
    put_u32(&mut b, 0); // crc
    put_u32(&mut b, 1); // compressed size — one byte that is not there
    put_u32(&mut b, 1); // uncompressed size
    put_u16(&mut b, 1); // name length
    put_u16(&mut b, 0); // extra
    put_u16(&mut b, 0); // comment
    put_u16(&mut b, 0); // disk
    put_u16(&mut b, 0); // internal attrs
    put_u32(&mut b, 0); // external attrs
    put_u32(&mut b, 69); // local offset — 69 + 30 == 99 == len
    b.push(b'a');
    // local file header at 69 (exactly 30 bytes: 69 + 30 == len == 99)
    put_u32(&mut b, 0x0403_4b50);
    put_u16(&mut b, 20); // version needed
    put_u16(&mut b, 0); // flags
    put_u16(&mut b, 0); // method
    put_u16(&mut b, 0); // time
    put_u16(&mut b, 0x21); // date
    put_u32(&mut b, 0); // crc
    put_u32(&mut b, 1); // compressed size
    put_u32(&mut b, 1); // uncompressed size
    put_u16(&mut b, 0); // name length
    put_u16(&mut b, 0); // extra length
    assert_eq!(b.len(), 99);

    let insp = analyze_tax_file(&b);
    assert_eq!(insp.entries.len(), 1);
    assert_eq!(insp.entries[0].name, "a");
    assert!(insp.entries[0].data.is_none());
    assert!(insp
        .warnings
        .iter()
        .any(|w| w == "Entry \"a\" extends past end of file; skipped."));
}

// battery extension: zero-length names and zero-byte STORE data. An empty
// name is listed honestly (no panic — the name slice is the empty
// range); a zero-byte extraction is `Some([])` with entropy `None`
// (dart:133: empty stored data has no entropy) and `likely_encrypted`
// `Some(false)` (dart:134 — the flag exists whenever data was
// extracted); a textual name with zero bytes previews the empty string.
#[test]
fn battery_zero_length_name_and_zero_byte_store_data() {
    let bytes = fixture_zip(&[raw_stored(b"", b""), stored("empty.txt", b"")]);
    let insp = analyze_tax_file(&bytes);
    assert_eq!(insp.entries.len(), 2);

    assert_eq!(insp.entries[0].name, "");
    assert_eq!(insp.entries[0].method, 0);
    assert_eq!(insp.entries[0].data.as_deref(), Some(&b""[..]));
    assert_eq!(insp.entries[0].size, 0);
    assert_eq!(insp.entries[0].entropy, None);
    assert_eq!(insp.entries[0].likely_encrypted, Some(false));
    assert_eq!(insp.entries[0].preview, None); // "" is not a textual name

    assert_eq!(insp.entries[1].name, "empty.txt");
    assert_eq!(insp.entries[1].data.as_deref(), Some(&b""[..]));
    assert_eq!(insp.entries[1].size, 0);
    assert_eq!(insp.entries[1].entropy, None);
    assert_eq!(insp.entries[1].likely_encrypted, Some(false));
    assert_eq!(insp.entries[1].preview, Some("".to_owned()));
    assert!(!insp.clearfile_container);
}

// battery extension: absurd extra/comment lengths (0xFFFF each) on the
// first of two records push the walk's next record pointer far past EOF.
// The pointer arithmetic is u64 (no 32-bit overflow) and the next record
// read bounds-checks → the honest corrupt note, one entry listed.
#[test]
fn battery_absurd_extra_and_comment_lens_walk_far_past_eof() {
    let mut bytes = fixture_zip(&[stored("a.txt", b"x"), stored("b.txt", b"y")]);
    let ptr = central_ptr(&bytes);
    set_u16(&mut bytes, ptr + 30, 0xFFFF); // extra length
    set_u16(&mut bytes, ptr + 32, 0xFFFF); // comment length

    let insp = analyze_tax_file(&bytes);
    assert_eq!(insp.entries.len(), 1);
    assert_eq!(insp.entries[0].name, "a.txt");
    assert_eq!(insp.entries[0].data.as_deref(), Some(&b"x"[..]));
    assert!(insp
        .warnings
        .iter()
        .any(|w| w == "Central directory truncated or corrupt; stopped early."));
}

// battery extension: an absurd uncompressed size (0xFFFFFFFF) claimed on
// a deflate entry — the claim only surfaces as the listed `size` (the
// honest "what the directory claims" field); nothing is allocated, the
// entry is listed-only as ever.
#[test]
fn battery_absurd_uncompressed_size_claimed_on_deflate_entry() {
    let mut bytes = fixture_zip(&[deflate("c.bin", b"not actually deflated")]);
    let ptr = central_ptr(&bytes);
    set_u32(&mut bytes, ptr + 24, 0xFFFF_FFFF); // uncompressed size

    let insp = analyze_tax_file(&bytes);
    assert_eq!(insp.entries.len(), 1);
    assert_eq!(insp.entries[0].method, 8);
    assert!(insp.entries[0].data.is_none());
    assert_eq!(insp.entries[0].size, 0xFFFF_FFFF);
    assert!(insp
        .warnings
        .iter()
        .any(|w| w == "Entry \"c.bin\" is deflate-compressed; listed only."));
}

// battery extension: overlapping entries — two central records pointing
// at the SAME local header. Both extract (the same bytes), no panic, no
// cross-contamination of the walk.
#[test]
fn battery_overlapping_entries_same_local_offset() {
    let mut bytes = fixture_zip(&[stored("a.txt", b"x"), stored("b.txt", b"y")]);
    let ptr = central_ptr(&bytes);
    let ptr1 = ptr + 46 + 5; // record 0: name "a.txt" (5), extra 0, comment 0
    set_u32(&mut bytes, ptr1 + 42, 0); // record 1's local offset → entry 0's

    let insp = analyze_tax_file(&bytes);
    assert_eq!(insp.entries.len(), 2);
    assert_eq!(insp.entries[0].data.as_deref(), Some(&b"x"[..]));
    assert_eq!(insp.entries[1].data.as_deref(), Some(&b"x"[..])); // entry 0's bytes
    assert!(insp.warnings.is_empty());
}

// battery extension: CRC mismatch is IGNORED on read. Both references
// never read the CRC fields in their readers (dart:254-260 / taxfile.ts:
// 214-220 read method/sizes/lengths/offset only) — CRC-32 is the
// writer's integrity stamp, verified here by the standard check value
// above, not a reader-side gate. A forged CRC changes nothing on read.
#[test]
fn battery_crc_mismatch_ignored_on_read() {
    let mut bytes = fixture_zip(&[stored("a.txt", b"payload bytes")]);
    set_u32(&mut bytes, 14, 0xDEAD_BEEF); // local-header CRC field
    let ptr = central_ptr(&bytes);
    set_u32(&mut bytes, ptr + 16, 0xDEAD_BEEF); // central-directory CRC field

    let insp = analyze_tax_file(&bytes);
    assert_eq!(insp.entries.len(), 1);
    assert_eq!(insp.entries[0].data.as_deref(), Some(&b"payload bytes"[..]));
    assert!(insp.warnings.is_empty());
}

// battery extension: duplicate clearfile.json entries — the first
// deflate-listed (no data), the second STORE-extracted. The references'
// filters pick the first clearfile.json entry WITH extracted bytes
// (dart:141 `where((e) => ... && e.stored != null)`, taxfile.ts:316
// `find((e) => e.name === 'clearfile.json' && e.data)`) — pins the
// port's where-filter against the name-only find.
#[test]
fn battery_duplicate_clearfile_json_stored_entry_wins() {
    let payload = "{\"format\":\"clearfile-return\",\"version\":2}";
    let bytes = fixture_zip(&[
        deflate("clearfile.json", b"not actually deflated"),
        stored("clearfile.json", payload.as_bytes()),
    ]);
    let insp = analyze_tax_file(&bytes);
    assert!(insp.clearfile_container);
    assert_eq!(insp.clearfile_payload.as_deref(), Some(payload));
}

// battery extension: a clearfile.json payload whose bytes are NOT UTF-8.
// The reference's outer catch (dart:165-168) warns "could not be parsed
// as JSON/UTF-8." and falls through to the plain-ZIP analysis — this
// branch lives INSIDE the module (the faithful outer catch), so it is
// pinned here in full.
#[test]
fn battery_invalid_utf8_clearfile_payload_warns_and_falls_through() {
    let bytes = fixture_zip(&[stored("clearfile.json", &[0xFF, 0xFE, 0xFD])]);
    let insp = analyze_tax_file(&bytes);
    assert!(!insp.clearfile_container);
    assert!(insp.clearfile_payload.is_none());
    assert!(insp
        .warnings
        .iter()
        .any(|w| w == "clearfile.json could not be parsed as JSON/UTF-8."));
    // fell through to the plain-ZIP analysis (dart:194-207):
    assert!(insp.summary.starts_with("ZIP container detected"));
    assert_eq!(insp.entries.len(), 1); // the entry is still listed
}

// battery extension: an entry name with invalid UTF-8 bytes (0xFF).
// Names decode lossily (module divergence 4 — the TS TextDecoder
// behavior) — a replacement character, never a panic; the lossy name
// still gets its textual preview.
#[test]
fn battery_invalid_utf8_entry_name_lossy_decode() {
    let bytes = fixture_zip(&[raw_stored(&[0xFF, b'.', b't', b'x', b't'], b"hello")]);
    let insp = analyze_tax_file(&bytes);
    assert_eq!(insp.entries.len(), 1);
    assert_eq!(insp.entries[0].name, "\u{FFFD}.txt");
    assert_eq!(insp.entries[0].data.as_deref(), Some(&b"hello"[..]));
    assert_eq!(insp.entries[0].preview.as_deref(), Some("hello"));
}

// battery extension: the 4,096-entry central-directory walk cap
// (dart:246 `maxEntries`, taxfile.ts:206). A container claiming 4,097
// records with 4,097 real ones walks exactly 4,096 and stops SILENTLY
// (the cap is the loop condition — no note is added).
#[test]
fn battery_central_directory_walk_cap_4096() {
    let entries: Vec<FixtureEntry<'_>> = (0..4097)
        .map(|_| stored("e", b"x"))
        .collect();
    let bytes = fixture_zip(&entries);
    assert_eq!(le_u16(&bytes, bytes.len() - 22 + 10), 4097); // EOCD count

    let insp = analyze_tax_file(&bytes);
    assert!(insp.is_zip);
    assert_eq!(insp.entries.len(), 4096);
    assert!(insp.warnings.is_empty()); // the cap stops silently (dart:248)
}
