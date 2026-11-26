// SPDX-License-Identifier: GPL-3.0-only
//! Read-only `.tax` container inspection + the ClearFile exchange container
//! (N1 session 2, ADR-017 annex (b)) — ported whole from the Dart reference
//! `clearfile/lib/io/tax_inspect.dart` (319 lines, canonical) and, for the
//! writer half, the TS twin `src/lib/files/taxfile.ts` (389 lines; the
//! Flutter app has no `.tax` writer — spec
//! `docs/formats/tax-exchange-container.md` §5).
//!
//! THIS IS DEMONSTRATION SOFTWARE. It never decrypts anything: the modern
//! Intuit container family is *recognized at shape level only*
//! (`manifest.xml` + `tax:<uuid>`); no key material, no decryptor (RE
//! protocol §2.2/§7.2/§7.3 — the summaries say so and point at the safe
//! bridges: TurboTax's own TXF export and printed PDFs).
//!
//! # What it does — and deliberately does NOT do (tax_inspect.dart:9-23)
//!
//! - Detects the ZIP wrapper family of `.tax` files and lists entries from
//!   the **central directory** (name, method, sizes) — never a linear scan.
//! - Extracts **STORE-method entries only**; DEFLATE entries are listed but
//!   not extracted (honest, dependency-free reading; no inflate is bundled).
//!   Cumulative STORE extraction is capped (256 MiB, `analysis limit`):
//!   a crafted container that would extract past the cap stops the walk
//!   with an honest note — the analysis path never panics, never errors.
//! - Recognizes ClearFile's own open exchange container (a STORE-extracted
//!   `clearfile.json` entry) and **carries its payload text out** (below).
//! - Recognizes the *shape* of the modern Intuit container and reports
//!   per-entry Shannon entropy so encrypted payloads are flagged
//!   (≥ 128 stored bytes at ≥ 7.5 bits/byte).
//! - Non-ZIP files get the honest "unrecognized/legacy" summary with
//!   whole-file entropy; an empty file reports `The file is empty.`
//!
//! # THE PAYLOAD SEAM (ADR-017 FFI-boundary conformance note)
//!
//! The Dart/TS references decode the envelope **inline** at the end of
//! `analyzeTaxFile` (`ReturnFileCodec.decode` / `parseCfr`,
//! tax_inspect.dart:143-169 / taxfile.ts:316-335), merging the envelope's
//! migration warnings into the inspection result. ADR-017's recorded FFI
//! design is "**the envelope as payload boundary**" (one flat C ABI; the
//! surface is `inspect_tax` carrying the payload text, envelope
//! `encode`/`decode` beside it) — so this module **does not decode the
//! envelope**: [`TaxInspection::clearfile_payload`] carries the extracted
//! `clearfile.json` payload as a STRING and the CALLER composes
//! `crate::envelope::decode` over it. Where the reference's import branch
//! merges envelope warnings (and flips `clearfileContainer` to false when
//! its inline decode fails, falling through to the plain-ZIP analysis with
//! the warning `clearfile.json could not be parsed: <reason>`), this port
//! exposes the payload and leaves that fall-through to the composition;
//! the composed import function lands at integration with tests.
//!
//! # Deliberate divergences (ADR-017 annex (c) — each with its reason)
//!
//! 1. **The payload seam itself** (above): `filing: TaxReturnData?` and the
//!    envelope-warning merge are replaced by `clearfile_payload:
//!    Option<String>` — the recorded ADR-017 FFI boundary.
//! 2. [`TaxInspection::clearfile_container`] therefore means "a STORE-
//!    extracted `clearfile.json` payload was carried out" (the container
//!    SHAPE), not the references' "the inline envelope decode succeeded" —
//!    the decode-success determination is the caller's composition now.
//! 3. **The UTF-8 layer stays inside** (faithful): a `clearfile.json` whose
//!    bytes are not UTF-8 warns `clearfile.json could not be parsed as
//!    JSON/UTF-8.` and falls through, exactly as the reference's outer
//!    catch (tax_inspect.dart:165-168).
//! 4. **Entry names decode UTF-8-lossy** (the TS `TextDecoder` behavior)
//!    rather than the Dart `String.fromCharCodes` byte-per-code-unit — a
//!    Rust `String` cannot hold lone bytes; every name the recognition
//!    paths test for is ASCII.
//! 5. **The Dart entropy-field semantics are canonical**: `entropy` is
//!    `Some` for any non-empty stored data (the TS twin computes it only
//!    at ≥ 128 bytes) — `tax_inspect.dart` is the canonical reference.
//! 6. **The ENG-1 name-length guard is kept** (tax_inspect.dart:261-268):
//!    the TS twin lacks it; spec §3.5 records it as the only intentional
//!    asymmetry between the two readers — a strictly-added guard, so the
//!    port keeps the harder behavior.
//! 7. **The Dart local-header signature check is kept**
//!    (tax_inspect.dart:274: a STORE entry extracts only when
//!    `PK\x03\x04` sits at the entry's local offset) — the TS twin extracts
//!    without checking; the Dart check is stricter and canonical.
//! 8. **The writer stamps a fixed DOS timestamp** (1980-01-01 00:00:00,
//!    date word `0x21`): the TS writer stamps the wall clock
//!    (`dosDateTime()`, taxfile.ts:92-97), but the core is pure and
//!    deterministic (ADR-017 Rust-core boundary) and cannot read a clock;
//!    `0x21` is the same fixed value the Dart test-fixture writer uses.
//! 9. **The writer refuses ZIP32 field-width overflows with named errors**
//!    (name > 65,535 bytes, entry data > 4 GiB, > 65,535 entries, central-
//!    directory offset/size > 4 GiB): the references would throw (Dart) or
//!    silently wrap the field (JS) — the port refuses rather than emit a
//!    corrupt container (never corrupt, never panic).
//! 10. **Where the two references word a summary differently**, the Dart
//!     wording wins (canonical): the non-ZIP summary says
//!     `Not a ZIP container (no PK signature). This is either a legacy
//!     binary tax format …` (tax_inspect.dart:102-108) where the TS says
//!     `Unrecognized container (no ZIP signature) …` (taxfile.ts:294); the
//!     deflate note says `… is deflate-compressed; listed only.`
//!     (tax_inspect.dart:285) where the TS says `… not extracted (shown
//!     only).` (taxfile.ts:236); the saw-deflate summary follows
//!     tax_inspect.dart:200-206 (the TS variant says "could not be
//!     extracted in-browser", taxfile.ts:362).

/// Fixed honest-labeling text inside every exported exchange container —
/// `TAX_CONTAINER_README`, ported VERBATIM from `taxfile.ts:367-382`. The
/// "NOT the Intuit format" wording is a wording contract (spec §2: "the
/// honest labeling (README.txt, verbatim owner text)"), so it is pinned
/// byte-for-byte by the port suite's independent literal.
pub const TAX_CONTAINER_README: &str = "ClearFile exchange container
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

/// Fixed DOS timestamp stamped into every exported entry: 1980-01-01
/// 00:00:00 (date word `0x0021`, time word `0x0000`). See divergence 8.
const DOS_TIME: u16 = 0x0000;
const DOS_DATE: u16 = 0x0021; // 1980-01-01 (the Dart fixture writer's date)

/// Entropy threshold (bits/byte) for flagging encrypted/compressed content
/// (TS `LIKELY_ENCRYPTED_ENTROPY`, taxfile.ts:277; the Dart inlines 7.5 —
/// protocol Phase 1's AES-layer signature).
const LIKELY_ENCRYPTED_ENTROPY: f64 = 7.5;

/// A stored entry is only entropy-flagged from this many bytes (TS
/// `ENTROPY_MIN_BYTES`, taxfile.ts:278; Dart `>= 128`, tax_inspect.dart:122).
const ENTROPY_MIN_BYTES: usize = 128;

/// Textual stored entries below this size get a preview (Dart
/// `e.stored!.length < 200000`, tax_inspect.dart:123).
const PREVIEW_MAX_ENTRY_SIZE: usize = 200_000;

/// Previews carry at most this many bytes (Dart `take(300)`,
/// tax_inspect.dart:125).
const PREVIEW_MAX_BYTES: usize = 300;

/// The end-of-central-directory scan window: the tail 66,000 bytes
/// (tax_inspect.dart:232 / taxfile.ts:193 — the ZIP format's 65,535-byte
/// comment bound, plus headroom; both references use 66,000).
const MAX_EOCD_SCAN_WINDOW: u64 = 66_000;

/// Central-directory walk cap (untrusted input) — `maxEntries = 4096`
/// (tax_inspect.dart:246 / taxfile.ts:206).
const MAX_ZIP_ENTRIES: usize = 4096;

/// Cumulative STORE-extraction cap (untrusted input): 256 MiB across the
/// whole walk. Honest exchange containers are KB-scale (the ClearFile
/// exchange container is two STORE entries — a JSON envelope plus a short
/// README), so the cap is unreachable for real files; a crafted container
/// whose central records alias shared STORE bytes can otherwise drive
/// extraction far past the file's own size (a 385 KB crafted file, >1 GB
/// extracted) — the amplification the N1-exit gate registered. Exceeding
/// it STOPS the walk with an honest note (the analysis path never errors,
/// never panics); the writer-side export path is untouched.
const MAX_STORED_EXTRACTION_BYTES: u64 = 256 * 1024 * 1024;

/// The ClearFile-exchange-container summary, verbatim
/// (tax_inspect.dart:158-160 == taxfile.ts:328; the spec §2 quotes it as
/// the in-app disclosure).
const CLEARFILE_EXCHANGE_SUMMARY: &str = "This is a ClearFile exchange container (.tax extension, open ZIP format). The full return can be imported.";

/// The modern-Intuit-shape summary, verbatim (tax_inspect.dart:182-191).
const INTUIT_MODERN_SUMMARY: &str = "This matches the modern TurboTax .tax container shape (ZIP with a manifest.xml plus a tax:<uuid> data entry). The entries are AES-encrypted with per-year key/IV constants embedded in the TurboTax binary (public write-up, protocol §5). ClearFile does not decrypt Intuit files and ships no key material (protocol §2.2/§7) — import this return via TurboTax's own TXF export (Tax > Print & Save / Export) or the printed PDF, both of which are the documented safe bridges.";

/// Plain-ZIP summary when some entries were listed-only as DEFLATE
/// (tax_inspect.dart:200-203).
const PLAIN_ZIP_DEFLATE_SUMMARY: &str = "ZIP container detected. Some entries are compressed and listed only; stored entries are analyzed below. No ClearFile return payload was found, so nothing can be imported automatically.";

/// Plain-ZIP summary when every entry was stored (tax_inspect.dart:204-206).
const PLAIN_ZIP_SUMMARY: &str = "ZIP container detected with the entries listed below. No ClearFile return payload was found, so nothing can be imported automatically.";

/// Named writer errors (the export path; the analysis path never errors —
/// its honest report IS the error surface). ZIP32 field widths bound every
/// variant; see divergence 9.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum TaxInspectError {
    /// An entry name exceeds the 65,535-byte ZIP name-length field.
    EntryNameTooLong { len: usize },
    /// An entry's data exceeds the 4 GiB ZIP32 size fields.
    EntryDataTooLarge { size: u64 },
    /// More entries than the EOCD's 65,535-entry count fields can carry.
    TooManyEntries { count: usize },
    /// The accumulated local-header or central-directory offset/size
    /// exceeds the 4 GiB ZIP32 offset/size fields.
    ContainerTooLarge { offset: u64 },
}

impl std::fmt::Display for TaxInspectError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            TaxInspectError::EntryNameTooLong { len } => write!(
                f,
                "an entry name of {len} bytes exceeds the 65,535-byte ZIP name-length field; \
                 the container cannot be written"
            ),
            TaxInspectError::EntryDataTooLarge { size } => write!(
                f,
                "entry data of {size} bytes exceeds the 4 GiB ZIP32 size fields; \
                 the container cannot be written"
            ),
            TaxInspectError::TooManyEntries { count } => write!(
                f,
                "{count} entries exceed the 65,535-entry ZIP end-of-central-directory count; \
                 the container cannot be written"
            ),
            TaxInspectError::ContainerTooLarge { offset } => write!(
                f,
                "container offset {offset} exceeds the 4 GiB ZIP32 offset field; \
                 the container cannot be written"
            ),
        }
    }
}

impl std::error::Error for TaxInspectError {}

/// One ZIP-family entry as the analysis reports it — the Dart
/// `TaxEntryInfo` (tax_inspect.dart:54-83) plus the STORE-extracted bytes
/// the TS `ZipEntryMeta` carries (`data`, taxfile.ts:32-40).
#[derive(Clone, Debug, PartialEq)]
pub struct TaxEntryInfo {
    /// Entry name from the ZIP central directory (UTF-8-lossy decoded —
    /// divergence 4).
    pub name: String,
    /// ZIP compression method (0 stored / 8 deflate / other).
    pub method: u16,
    /// Uncompressed size as claimed by the central directory
    /// (`ZipEntryMeta.uncompressedSize`, taxfile.ts:37).
    pub uncompressed_size: u64,
    /// The STORE-extracted data — `Some` only for STORE entries whose bytes
    /// fit inside the file (`ZipEntryMeta.data`, taxfile.ts:39).
    pub data: Option<Vec<u8>>,
    /// Extracted stored size, else the central directory's claim (Dart
    /// `size: e.stored?.length ?? e.uncompressedSize`).
    pub size: u64,
    /// Shannon entropy in bits/byte over the extracted data — `None` when
    /// not extracted or empty (Dart semantics — divergence 5).
    pub entropy: Option<f64>,
    /// Entropy ≥ 7.5 over ≥ 128 stored bytes — the signature of an
    /// encrypted or already-compressed payload (`None` when not
    /// extracted).
    pub likely_encrypted: Option<bool>,
    /// Text preview for small textual stored entries (Dart
    /// `Utf8Decoder(allowMalformed: true)` over the first 300 bytes —
    /// decoded lossily here).
    pub preview: Option<String>,
}

/// The inspection result — the Dart `TaxInspection`
/// (tax_inspect.dart:24-52) with the payload seam (module docs): the
/// honest three-kind taxonomy is ClearFile exchange container /
/// ZIP-family container (plain or the recognized Intuit shape) /
/// unrecognized (non-ZIP).
#[derive(Clone, Debug, PartialEq)]
pub struct TaxInspection {
    /// True when the file carries a ZIP-family signature (PK\x03\x04 /
    /// PK\x05\x06 / PK\x07\x08 in the first three bytes —
    /// `_looksZip`, tax_inspect.dart:220-224).
    pub is_zip: bool,
    /// True when a STORE-extracted `clearfile.json` payload was carried
    /// out — the exchange-container SHAPE; the envelope decode that the
    /// references perform inline is the caller's composition (module docs,
    /// divergence 2).
    pub clearfile_container: bool,
    /// True when the entry names match the modern Intuit container shape
    /// (`manifest.xml` + a `tax:<uuid>` entry). Nothing is decrypted; the
    /// summary says exactly that and points at the safe bridges.
    pub intuit_modern_container: bool,
    /// **The payload seam (ADR-017):** the extracted `clearfile.json`
    /// payload text — `Some` exactly when `clearfile_container` is. The
    /// caller composes `crate::envelope::decode` over it (migrations'
    /// warnings surface there, as the reference's merged warnings did).
    pub clearfile_payload: Option<String>,
    pub entries: Vec<TaxEntryInfo>,
    /// The honest notes — ZIP-walk problems plus (faithfully) the
    /// unreadable-payload warning; never a panic, always user-readable.
    pub warnings: Vec<String>,
    pub summary: String,
}

/// Inspect an in-memory `.tax` file. **Never fails and never panics on any
/// input** — the analysis reports what it could and could not establish
/// (the doc contract of `analyzeTaxFile`, tax_inspect.dart:85-87; the
/// malformed-ZIP crash battery is this function's regression contract).
///
/// Port of `analyzeTaxFile` (tax_inspect.dart:87-208) with the writer-side
/// analysis cross-checked against `analyzeTaxFile` (taxfile.ts:280-365).
pub fn analyze_tax_file(bytes: &[u8]) -> TaxInspection {
    let mut warnings: Vec<String> = Vec::new();

    if !looks_zip(bytes) {
        // Phase-1 passive identification for non-ZIP files (dart:90-110):
        // whole-file entropy tells encrypted/legacy-binary from textual.
        let entropy = entropy_of(bytes);
        let summary = if bytes.is_empty() {
            "The file is empty.".to_owned()
        } else {
            format!(
                "Not a ZIP container (no PK signature). This is either a \
                 legacy binary tax format or an unknown container. \
                 Whole-file entropy is {:.2} bits/byte ({}). The legacy \
                 formats have no public documentation (protocol §1); \
                 ClearFile imports TurboTax data through the documented \
                 TXF export and PDFs instead.",
                entropy,
                if entropy >= LIKELY_ENCRYPTED_ENTROPY {
                    "encrypted/compressed-looking"
                } else {
                    "not high-entropy"
                }
            )
        };
        return TaxInspection {
            is_zip: false,
            clearfile_container: false,
            intuit_modern_container: false,
            clearfile_payload: None,
            entries: Vec::new(),
            warnings,
            summary,
        };
    }

    let dir = read_zip_directory(bytes, &mut warnings);
    let mut entries: Vec<TaxEntryInfo> = Vec::with_capacity(dir.len());
    let mut saw_deflate = false;

    for e in &dir {
        // dart:116-137 — per-entry entropy / flag / preview.
        let mut entropy = 0.0;
        let mut encrypted = false;
        let mut preview: Option<String> = None;
        if let Some(stored) = &e.stored {
            entropy = entropy_of(stored);
            encrypted = stored.len() >= ENTROPY_MIN_BYTES && entropy >= LIKELY_ENCRYPTED_ENTROPY;
            if looks_textual(&e.name) && stored.len() < PREVIEW_MAX_ENTRY_SIZE {
                let take = stored.len().min(PREVIEW_MAX_BYTES);
                // Dart: Utf8Decoder(allowMalformed: true) — decode with
                // replacement, never fail on crafted bytes.
                preview = Some(String::from_utf8_lossy(&stored[..take]).into_owned());
            }
        }
        if e.method == 8 {
            saw_deflate = true;
        }
        entries.push(TaxEntryInfo {
            name: e.name.clone(),
            method: e.method,
            uncompressed_size: e.uncompressed_size,
            data: e.stored.clone(),
            size: e
                .stored
                .as_ref()
                .map_or(e.uncompressed_size, |s| s.len() as u64),
            entropy: match &e.stored {
                Some(s) if !s.is_empty() => Some(entropy),
                _ => None,
            },
            likely_encrypted: if e.stored.is_some() { Some(encrypted) } else { None },
            preview,
        });
    }

    // ClearFile exchange container (dart:140-169) — the payload seam: the
    // references decode the envelope inline here; this port carries the
    // payload text out and the caller composes the decode (module docs).
    // The reference's FIRST clearfile.json entry WITH extracted bytes wins
    // (dart:141 `where((e) => ... && e.stored != null)` → `.first` ==
    // taxfile.ts:316 `find((e) => e.name === 'clearfile.json' && e.data)`)
    // — a same-named entry with no extracted data (deflate, past-EOF) is
    // SKIPPED, not chosen.
    if let Some(stored) = dir
        .iter()
        .find(|e| e.name == "clearfile.json" && e.stored.is_some())
        .and_then(|e| e.stored.as_ref())
    {
        // Faithful outer catch (dart:165-168): payload bytes that are not
        // UTF-8 warn and fall through to the plain-ZIP analysis.
        match String::from_utf8(stored.to_vec()) {
            Ok(text) => {
                return TaxInspection {
                    is_zip: true,
                    clearfile_container: true,
                    intuit_modern_container: false,
                    clearfile_payload: Some(text),
                    entries,
                    warnings,
                    summary: CLEARFILE_EXCHANGE_SUMMARY.to_owned(),
                };
            }
            Err(_) => warnings
                .push("clearfile.json could not be parsed as JSON/UTF-8.".to_owned()),
        }
    }

    // Modern Intuit container shape: manifest.xml + tax:<uuid> entry
    // (dart:171-192). Report the shape, decrypt nothing.
    let has_manifest = dir.iter().any(|e| e.name == "manifest.xml");
    let has_tax_data = dir.iter().any(|e| e.name.starts_with("tax:"));
    if has_manifest && has_tax_data {
        return TaxInspection {
            is_zip: true,
            clearfile_container: false,
            intuit_modern_container: true,
            clearfile_payload: None,
            entries,
            warnings,
            summary: INTUIT_MODERN_SUMMARY.to_owned(),
        };
    }

    TaxInspection {
        is_zip: true,
        clearfile_container: false,
        intuit_modern_container: false,
        clearfile_payload: None,
        entries,
        warnings,
        summary: if saw_deflate {
            PLAIN_ZIP_DEFLATE_SUMMARY.to_owned()
        } else {
            PLAIN_ZIP_SUMMARY.to_owned()
        },
    }
}

/* ---------------- ZIP central-directory reader (STORE extraction) ------ */

/// One central-directory entry as walked — the Dart `_ZipDirEntry`
/// (tax_inspect.dart:212-218): `stored` is non-null only for STORE entries.
struct ZipDirEntry {
    name: String,
    method: u16,
    uncompressed_size: u64,
    stored: Option<Vec<u8>>,
}

/// The ZIP-family signature gate (dart:220-224 `_looksZip` ==
/// taxfile.ts:268-270 `isZip`): more than four bytes starting `PK` with a
/// 0x03/0x05/0x07 third byte (local-header / EOCD / spanning-signature
/// markers — spec §1's sniff).
fn looks_zip(bytes: &[u8]) -> bool {
    bytes.len() > 4
        && bytes[0] == 0x50
        && bytes[1] == 0x4b
        && (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07)
}

/// Textual-looking entry name (dart:297-298 `\.(json|txt|xml|csv|md)$`
/// case-insensitive; == taxfile.ts:272-274). ASCII case-fold — the
/// extensions are ASCII.
fn looks_textual(name: &str) -> bool {
    let lower = name.to_ascii_lowercase();
    [".json", ".txt", ".xml", ".csv", ".md"]
        .iter()
        .any(|ext| lower.ends_with(ext))
}

/// Little-endian u16 at `at`, bounds-checked — `None` past EOF. Every read
/// in this module goes through these (the crafted-input battery's rule).
fn le_u16(bytes: &[u8], at: u64) -> Option<u16> {
    if at.checked_add(2)? > bytes.len() as u64 {
        return None;
    }
    let at = at as usize;
    Some(u16::from_le_bytes([bytes[at], bytes[at + 1]]))
}

/// Little-endian u32 at `at`, bounds-checked (see [`le_u16`]).
fn le_u32(bytes: &[u8], at: u64) -> Option<u32> {
    if at.checked_add(4)? > bytes.len() as u64 {
        return None;
    }
    let at = at as usize;
    Some(u32::from_le_bytes([
        bytes[at],
        bytes[at + 1],
        bytes[at + 2],
        bytes[at + 3],
    ]))
}

/// Locate the end-of-central-directory record from the tail, bounded to
/// the last [`MAX_EOCD_SCAN_WINDOW`] bytes (dart:230-238 == taxfile.ts:192-
/// 199, scanning downward from `len − 22`; a file shorter than 22 bytes
/// never enters the loop — the Dart signed index `i >= scanFrom` with
/// `scanFrom >= 0`). The FIRST signature found from the tail wins.
fn find_eocd(bytes: &[u8]) -> Option<usize> {
    let len = bytes.len() as u64;
    let scan_from = if len >= MAX_EOCD_SCAN_WINDOW {
        len - MAX_EOCD_SCAN_WINDOW
    } else {
        0
    };
    let mut i = bytes.len() as i64 - 22;
    while i >= scan_from as i64 {
        if le_u32(bytes, i as u64) == Some(0x0605_4b50) {
            return Some(i as usize);
        }
        i -= 1;
    }
    None
}

/// Fields of one central-directory record header, at `ptr` (dart:254-260 ==
/// taxfile.ts:214-220). `None` when the 46-byte header would not fit or
/// the signature is not `PK\x01\x02` — the reference's two disjuncts
/// (dart:249-252) produce the same "truncated or corrupt" note, so they
/// fold into one check here.
struct CentralRecord {
    method: u16,
    compressed_size: u32,
    uncompressed_size: u32,
    name_len: u16,
    extra_len: u16,
    comment_len: u16,
    local_offset: u32,
}

fn read_central_record(bytes: &[u8], ptr: u64) -> Option<CentralRecord> {
    if ptr.checked_add(46)? > bytes.len() as u64 {
        return None;
    }
    if le_u32(bytes, ptr) != Some(0x0201_4b50) {
        return None;
    }
    // In bounds by the 46-byte fit: every field read below sits inside
    // [ptr, ptr+46).
    let at = |o: u64| (ptr + o) as usize;
    Some(CentralRecord {
        method: u16::from_le_bytes([bytes[at(10)], bytes[at(11)]]),
        compressed_size: u32::from_le_bytes([
            bytes[at(20)],
            bytes[at(21)],
            bytes[at(22)],
            bytes[at(23)],
        ]),
        uncompressed_size: u32::from_le_bytes([
            bytes[at(24)],
            bytes[at(25)],
            bytes[at(26)],
            bytes[at(27)],
        ]),
        name_len: u16::from_le_bytes([bytes[at(28)], bytes[at(29)]]),
        extra_len: u16::from_le_bytes([bytes[at(30)], bytes[at(31)]]),
        comment_len: u16::from_le_bytes([bytes[at(32)], bytes[at(33)]]),
        local_offset: u32::from_le_bytes([
            bytes[at(42)],
            bytes[at(43)],
            bytes[at(44)],
            bytes[at(45)],
        ]),
    })
}

/// Walk the central directory (dart:226-295 `_readZipDirectory` ==
/// taxfile.ts:181-249 `readZip`): EOCD scan → up to `count` records under
/// the [`MAX_ZIP_ENTRIES`] cap → STORE extraction under the
/// [`MAX_STORED_EXTRACTION_BYTES`] cumulative cap. Every problem lands in
/// `notes` as an honest user-readable message; nothing panics. All
/// offset arithmetic runs in u64 (the fields are u32 but their SUMS can
/// exceed 32 bits — the crafted battery forges exactly that).
fn read_zip_directory(bytes: &[u8], notes: &mut Vec<String>) -> Vec<ZipDirEntry> {
    let mut out: Vec<ZipDirEntry> = Vec::new();
    let len = bytes.len() as u64;
    // Cumulative STORE-extracted bytes (u64: the SUM of many u32-size
    // entries can exceed 32 bits — same u64 posture as the offsets).
    let mut extracted: u64 = 0;

    let eocd = match find_eocd(bytes) {
        Some(e) => e as u64,
        None => {
            notes.push("No ZIP end-of-central-directory record found.".to_owned());
            return out;
        }
    };

    // In bounds by construction (eocd ≤ len − 22): a None is unreachable;
    // it is handled as the corrupt-truncation note rather than unwrapped.
    let (count, cd_offset) = match (le_u16(bytes, eocd + 10), le_u32(bytes, eocd + 16)) {
        (Some(c), Some(o)) => (c, o as u64),
        _ => {
            notes.push("Central directory truncated or corrupt; stopped early.".to_owned());
            return out;
        }
    };

    let mut ptr = cd_offset;
    for _n in 0..count {
        if out.len() >= MAX_ZIP_ENTRIES {
            break; // the parser-hardening cap (dart:248's loop condition)
        }
        let rec = match read_central_record(bytes, ptr) {
            Some(r) => r,
            None => {
                notes.push("Central directory truncated or corrupt; stopped early.".to_owned());
                break;
            }
        };
        // ENG-1 (Stage-2 entry gate, 2026-11-17): the 46-byte header may
        // fit while the claimed name length runs past EOF — bounds-check
        // before the slice, mirroring the truncated-header branch above.
        // (u64 arithmetic: ptr ≤ 2^32−1, +46+65535 cannot overflow.)
        let name_end = ptr + 46 + rec.name_len as u64;
        if name_end > len {
            notes.push(
                "Central directory entry name extends past end of file; stopped early.".to_owned(),
            );
            break;
        }
        let name = String::from_utf8_lossy(&bytes[(ptr + 46) as usize..name_end as usize])
            .into_owned();

        let mut stored: Option<Vec<u8>> = None;
        if rec.method == 0 {
            // STORE only, and only behind an intact local-file header
            // (dart:272-283; the signature check is the Dart-only
            // strictness — divergence 7). A method-0 entry whose local
            // header is unreachable or wrong is listed with no data and
            // NO note, exactly as the reference's silent else-fallthrough.
            let local = rec.local_offset as u64;
            if local + 30 <= len && le_u32(bytes, local) == Some(0x0403_4b50) {
                let l_name_len = le_u16(bytes, local + 26);
                let l_extra_len = le_u16(bytes, local + 28);
                // local + 30 ≤ len guarantees both reads are Some.
                if let (Some(l_name_len), Some(l_extra_len)) = (l_name_len, l_extra_len) {
                    // u64 arithmetic: no overflow (each term < 2^32 + 2^17).
                    let data_start = local + 30 + l_name_len as u64 + l_extra_len as u64;
                    let data_end = data_start + rec.compressed_size as u64;
                    if data_end <= len {
                        // Cumulative STORE-extraction cap (untrusted input,
                        // [`MAX_STORED_EXTRACTION_BYTES`]): stop the WALK
                        // before extracting an entry that would exceed it —
                        // honest note, no panic, no error (the analysis
                        // path's contract); the entry that tripped the cap
                        // is not extracted, so it is not listed either.
                        let size = data_end - data_start;
                        if extracted + size > MAX_STORED_EXTRACTION_BYTES {
                            notes.push(format!(
                                "Extraction stopped after {extracted} bytes of extracted entries (the analysis limit)."
                            ));
                            break;
                        }
                        extracted += size;
                        stored = Some(bytes[data_start as usize..data_end as usize].to_vec());
                    } else {
                        notes.push(format!(
                            "Entry \"{name}\" extends past end of file; skipped."
                        ));
                    }
                }
            }
        } else if rec.method == 8 {
            notes.push(format!("Entry \"{name}\" is deflate-compressed; listed only."));
        } else {
            notes.push(format!(
                "Entry \"{name}\" uses unsupported compression method {}; skipped.",
                rec.method
            ));
        }

        out.push(ZipDirEntry {
            name,
            method: rec.method,
            uncompressed_size: rec.uncompressed_size as u64,
            stored,
        });
        ptr += 46 + rec.name_len as u64 + rec.extra_len as u64 + rec.comment_len as u64;
    }
    out
}

/* ---------------- entropy (protocol Phase 1) ---------------------------- */

/// Shannon entropy in bits/byte (dart:302-319 `_entropyOf`/`_entropy` ==
/// taxfile.ts:253-264 `shannonEntropy`): −Σ p·log₂ p over the byte
/// histogram; 0.0 for empty input. Always finite (p ∈ (0, 1]).
pub fn entropy_of(data: &[u8]) -> f64 {
    if data.is_empty() {
        return 0.0;
    }
    let mut counts = [0u64; 256];
    for &b in data {
        counts[b as usize] += 1;
    }
    let n = data.len() as f64;
    let mut h = 0.0;
    for c in counts {
        if c == 0 {
            continue;
        }
        let p = c as f64 / n;
        h -= p * (p.ln() / std::f64::consts::LN_2);
    }
    h
}

/* ---------------- the exchange-container writer (taxfile.ts) ------------ */

/// CRC-32 (reflected 0xedb88320 polynomial), table-based and std-only —
/// `CRC_TABLE`/`crc32` (taxfile.ts:67-85; the Dart suite's test-side twin
/// is `_buildCrcTable`/`_crc32`, tax_inspect_test.dart:210-230). Pub so the
/// battery can pin the standard check value `crc32(b"123456789") ==
/// 0xCBF43926` (CRC-32/ISO-HDLC).
pub fn crc32(data: &[u8]) -> u32 {
    let mut c = 0xFFFF_FFFFu32;
    for &b in data {
        c = CRC_TABLE[((c ^ b as u32) & 0xFF) as usize] ^ (c >> 8);
    }
    c ^ 0xFFFF_FFFF
}

/// The table is a `const fn` build (std-only, computed at compile time).
const CRC_TABLE: [u32; 256] = build_crc_table();

const fn build_crc_table() -> [u32; 256] {
    let mut table = [0u32; 256];
    let mut i = 0usize;
    while i < 256 {
        let mut c = i as u32;
        let mut k = 0;
        while k < 8 {
            c = if c & 1 != 0 {
                0xEDB8_8320 ^ (c >> 1)
            } else {
                c >> 1
            };
            k += 1;
        }
        table[i] = c;
        i += 1;
    }
    table
}

/// Write the ClearFile exchange container (taxfile.ts:384-389
/// `exportTaxContainer`): a STORE-only ZIP with exactly two entries, in
/// order — `clearfile.json` (the payload text the caller serialized via
/// the envelope codec — the payload seam applied to the writer side) and
/// `README.txt` ([`TAX_CONTAINER_README`], verbatim). It is NOT the Intuit
/// format; the README inside says so explicitly.
///
/// Naming note (resolved ambiguity): the payload parameter is named for
/// the task's "openreturn.json payload" wording, which lifts the stale
/// doc-comment at taxfile.ts:16 ("containing openreturn.json + README.txt")
/// — the entry the writer actually emits (and both readers recognize, and
/// spec §2's table pins) is **`clearfile.json`** (taxfile.ts:386;
/// tax_inspect.dart:141; `e.name === 'clearfile.json'`, taxfile.ts:316).
/// `openreturn_json` therefore names the ENVELOPE PAYLOAD carried by the
/// `clearfile.json` entry, not a distinct entry name.
///
/// The payload arrives pre-serialized (`&str`): the TS writer calls
/// `serializeCfr(filing)` inline, and the seam hoists that to the caller
/// (module docs) — `export` and `inspect` are mirror images across the
/// envelope boundary.
pub fn export_tax_container(openreturn_json: &str) -> Result<Vec<u8>, TaxInspectError> {
    make_zip(&[
        ("clearfile.json", openreturn_json.as_bytes()),
        ("README.txt", TAX_CONTAINER_README.as_bytes()),
    ])
}

/// The STORE-only ZIP writer — `makeZip` (taxfile.ts:99-177) field-by-
/// field: local file header (30 + name + data), central directory (46 +
/// name per entry), end record (22). Fixed timestamp (divergence 8);
/// ZIP32 field-width refusals (divergence 9 — the TS `makeZip` never
/// fails, the port refuses with named errors rather than emit a corrupt
/// container).
///
/// The TS module exports `makeZip` and the Stage-3 bridge suite builds its
/// `[tax]` fixtures with the app's own writer (txf_taxfile_test.mjs:54-57,
/// 172, 198, 218); the port exposes the same surface so the ported groups
/// and the battery can do the same.
pub fn make_zip(entries: &[(&str, &[u8])]) -> Result<Vec<u8>, TaxInspectError> {
    if entries.len() > u16::MAX as usize {
        return Err(TaxInspectError::TooManyEntries { count: entries.len() });
    }
    let mut out: Vec<u8> = Vec::new();
    let mut central: Vec<u8> = Vec::new();
    let mut offset: u64 = 0;

    for &(name, data) in entries {
        let name_bytes = name.as_bytes();
        let name_len = name_bytes.len();
        if name_len > u16::MAX as usize {
            return Err(TaxInspectError::EntryNameTooLong { len: name_len });
        }
        let size = data.len() as u64;
        if size > u32::MAX as u64 {
            return Err(TaxInspectError::EntryDataTooLarge { size });
        }
        let crc = crc32(data);

        // --- local file header (taxfile.ts:110-125) ---
        out.extend_from_slice(&0x0403_4b50u32.to_le_bytes()); // signature
        out.extend_from_slice(&20u16.to_le_bytes()); // version needed
        out.extend_from_slice(&0x0800u16.to_le_bytes()); // flags: UTF-8 names
        out.extend_from_slice(&0u16.to_le_bytes()); // method: store
        out.extend_from_slice(&DOS_TIME.to_le_bytes());
        out.extend_from_slice(&DOS_DATE.to_le_bytes());
        out.extend_from_slice(&crc.to_le_bytes());
        out.extend_from_slice(&(size as u32).to_le_bytes()); // compressed
        out.extend_from_slice(&(size as u32).to_le_bytes()); // uncompressed
        out.extend_from_slice(&(name_len as u16).to_le_bytes());
        out.extend_from_slice(&0u16.to_le_bytes()); // extra length
        out.extend_from_slice(name_bytes);
        out.extend_from_slice(data);

        // --- central directory record (taxfile.ts:127-147) ---
        central.extend_from_slice(&0x0201_4b50u32.to_le_bytes()); // signature
        central.extend_from_slice(&20u16.to_le_bytes()); // version made by
        central.extend_from_slice(&20u16.to_le_bytes()); // version needed
        central.extend_from_slice(&0x0800u16.to_le_bytes()); // flags
        central.extend_from_slice(&0u16.to_le_bytes()); // method: store
        central.extend_from_slice(&DOS_TIME.to_le_bytes());
        central.extend_from_slice(&DOS_DATE.to_le_bytes());
        central.extend_from_slice(&crc.to_le_bytes());
        central.extend_from_slice(&(size as u32).to_le_bytes());
        central.extend_from_slice(&(size as u32).to_le_bytes());
        central.extend_from_slice(&(name_len as u16).to_le_bytes());
        central.extend_from_slice(&0u16.to_le_bytes()); // extra length
        central.extend_from_slice(&0u16.to_le_bytes()); // comment length
        central.extend_from_slice(&0u16.to_le_bytes()); // disk number
        central.extend_from_slice(&0u16.to_le_bytes()); // internal attrs
        central.extend_from_slice(&0u32.to_le_bytes()); // external attrs
        central.extend_from_slice(&(offset as u32).to_le_bytes()); // local offset
        central.extend_from_slice(name_bytes);

        offset += 30 + name_len as u64 + size;
        // The NEXT entry's local offset must fit the u32 field; refusing
        // here keeps every offset ever written in range (divergence 9).
        if offset > u32::MAX as u64 {
            return Err(TaxInspectError::ContainerTooLarge { offset });
        }
    }

    let central_size = central.len() as u64;
    if central_size > u32::MAX as u64 {
        return Err(TaxInspectError::ContainerTooLarge { offset: central_size });
    }

    // --- end of central directory (taxfile.ts:153-162) ---
    let mut end: Vec<u8> = Vec::with_capacity(22);
    end.extend_from_slice(&0x0605_4b50u32.to_le_bytes()); // signature
    end.extend_from_slice(&0u16.to_le_bytes()); // disk number
    end.extend_from_slice(&0u16.to_le_bytes()); // disk with the directory
    end.extend_from_slice(&(entries.len() as u16).to_le_bytes()); // this disk
    end.extend_from_slice(&(entries.len() as u16).to_le_bytes()); // total
    end.extend_from_slice(&(central_size as u32).to_le_bytes());
    end.extend_from_slice(&(offset as u32).to_le_bytes()); // directory offset
    end.extend_from_slice(&0u16.to_le_bytes()); // comment length

    out.extend_from_slice(&central);
    out.extend_from_slice(&end);
    Ok(out)
}

// ---------------------------------------------------------------------------
// The composed ClearFile-container import (N1 session 2 integration —
// tax_inspect.dart:139-163, the import branch the payload seam factored
// out; ADR-017's recorded FFI design: "the envelope as payload boundary")
// ---------------------------------------------------------------------------

/// A successfully imported ClearFile exchange container: the decoded
/// filing plus the MERGED warnings (the ZIP-walk notes first, then the
/// envelope's migration warnings — the reference's `[...warnings,
/// ...decoded.warnings]` order, dart:152) and the entry listing.
#[derive(Clone, Debug, PartialEq)]
pub struct ImportedContainer {
    pub filing: crate::envelope::TaxReturnData,
    pub warnings: Vec<String>,
    pub entries: Vec<TaxEntryInfo>,
    pub summary: String,
}

/// The composed import outcome: the container either imported fully, or
/// its `clearfile.json` payload failed envelope decode and the analysis
/// fell through exactly as the reference does (the parse warning
/// appended, the container flag and payload flipped off, the summary
/// re-derived — the Intuit shape if it matches, else the plain-ZIP
/// wording; dart:160-206).
#[derive(Clone, Debug, PartialEq)]
pub enum ContainerImport {
    Imported(ImportedContainer),
    FellThrough(TaxInspection),
}

/// Import a ClearFile exchange container (`.tax` bytes): analyze, then
/// decode the envelope payload — the composition the payload seam left
/// to the caller (module docs, divergence 1/2). `None` when the bytes
/// are not a ClearFile-shaped container at all (no STORE-extracted
/// `clearfile.json` payload — including the invalid-UTF-8 fall-through
/// [`analyze_tax_file]` handles internally): the caller uses
/// [`analyze_tax_file`] directly for the honest analysis.
pub fn import_tax_container(bytes: &[u8]) -> Option<ContainerImport> {
    let analysis = analyze_tax_file(bytes);
    let payload = analysis.clearfile_payload.as_ref()?;
    match crate::envelope::ReturnFileCodec::decode(payload) {
        Ok(decoded) => {
            let mut warnings = analysis.warnings;
            warnings.extend(decoded.warnings);
            Some(ContainerImport::Imported(ImportedContainer {
                filing: decoded.filing,
                warnings,
                entries: analysis.entries,
                summary: analysis.summary,
            }))
        }
        Err(e) => {
            // The reference's fall-through (dart:160-163): append the
            // parse warning, then reconstruct the plain-analysis shape.
            let mut fell = analysis;
            fell.warnings
                .push(format!("clearfile.json could not be parsed: {}", e.message));
            fell.clearfile_container = false;
            fell.clearfile_payload = None;
            let has_manifest = fell.entries.iter().any(|en| en.name == "manifest.xml");
            let has_tax_data = fell.entries.iter().any(|en| en.name.starts_with("tax:"));
            if has_manifest && has_tax_data {
                fell.intuit_modern_container = true;
                fell.summary = INTUIT_MODERN_SUMMARY.to_owned();
            } else if fell.entries.iter().any(|en| en.method == 8) {
                fell.summary = PLAIN_ZIP_DEFLATE_SUMMARY.to_owned();
            } else {
                fell.summary = PLAIN_ZIP_SUMMARY.to_owned();
            }
            Some(ContainerImport::FellThrough(fell))
        }
    }
}
