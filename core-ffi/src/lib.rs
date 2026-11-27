// SPDX-License-Identifier: GPL-3.0-only
//! The ClearFile flat C ABI (N3, the ADR-017 epilogue's FFI seam): ONE
//! flat `extern "C"` surface over the `clearfile-core` Rust core — the
//! cbindgen-generated `clearfile.h` (committed at the crate root) is the
//! audit-surface contract the N4 (Win32 C++) and N5 (macOS SPM) consumers
//! import; Android reaches the same functions through the thin JNI shim
//! (`src/jni.rs`); Linux links the core directly (no FFI — the recorded
//! N2 seam).
//!
//! ## The ABI contract (the N3 gate's ledger, items 2–4)
//!
//! - **Strings/bytes only — no struct mirrors.** The envelope IS the
//!   payload boundary: inputs are `(const pointer, explicit length)`
//!   pairs (NUL-safe; the length is authoritative), text inputs are
//!   UTF-8-validated with named errors, and NO function takes a path —
//!   the platform owns file acquisition (SAF on Android, dialogs
//!   elsewhere); this library performs NO filesystem access.
//! - **Exactly two return classes.** (1) Every data function returns an
//!   OWNED heap buffer (`char*`) on success — freed ONLY by
//!   [`clearfile_free`] (freeing it via libc directly is undefined
//!   behavior: the allocation is Rust's). (2) [`clearfile_last_error`]
//!   returns a BORROWED thread-local pointer that is NEVER freed — valid
//!   until the next call on that thread.
//! - **No panic ever crosses the boundary.** Every export wraps its
//!   whole body in the ONE shared [`ffi_guard`] (`catch_unwind`); a
//!   panic maps to the sentinel return (`NULL` / `0`) plus the
//!   last-error string in the core's wording family. The crate keeps
//!   the default unwind profile (no `panic = "abort"` — the guard
//!   requires it).
//! - **The pre-read size bound.** Every payload is refused beyond
//!   [`clearfile_core::MAX_INPUT_FILE_BYTES`] (512 MiB — 2× the 256 MiB
//!   STORE-extraction cap) before any parse, with the shared named
//!   message (the SEC-R2 hardening, enforced at every entry surface:
//!   the app pipelines AND this boundary).
//! - **The recorded addition:** [`clearfile_load_and_compute`] composes
//!   the analyze/import/decode/compute pipeline (what the Linux app's
//!   `load_and_compute` does in Rust) so the platform side carries ZERO
//!   engine logic (the ADR-017 core boundary); the ZIP-signature
//!   dispatch and the container composition are engine logic and stay
//!   on the Rust side of the seam.

use clearfile_core::envelope::{ReturnFileCodec, TaxReturnData};
use clearfile_core::json::Json;
use clearfile_core::palette::{scheme_role, PaletteRole};
use clearfile_core::tax_inspect::{
    analyze_tax_file, export_tax_container, import_tax_container, ContainerImport, TaxInspection,
};
use clearfile_core::txf::{export_txf, parse_txf};
use clearfile_core::{compute_ty2025, input_file_too_large, TaxResult, INPUT_TOO_LARGE_MESSAGE};
use std::cell::RefCell;
use std::ffi::c_char;
use std::panic::{catch_unwind, AssertUnwindSafe};

/// The JNI shim module (compiled for Android or the `host-jni` feature):
/// the thin `jbyteArray`-marshaling layer over these same functions. Its
/// `Java_*` exports ride in the same cdylib but are NEVER part of
/// `clearfile.h` (each declaration carries `/// cbindgen:ignore`).
#[cfg(any(target_os = "android", feature = "host-jni"))]
pub mod jni;

// ---------------------------------------------------------------------------
// The last-error thread-local + the ONE shared guard (SEC-1/ENG-4)
// ---------------------------------------------------------------------------

thread_local! {
    /// The borrowed return of [`clearfile_last_error`]: valid until the
    /// next call on this thread (the documented contract), never freed.
    static LAST_ERROR: RefCell<std::ffi::CString> =
        RefCell::new(std::ffi::CString::new("").unwrap());
}

/// Record the failure message for [`clearfile_last_error`].
fn set_last_error(message: &str) {
    // A message with an interior NUL byte cannot happen through the
    // guarded paths below (every message is a Rust string literal or a
    // core message; both are NUL-free). Replacing interior NULs with a
    // space keeps the function total anyway (never panics itself).
    LAST_ERROR.with(|slot| {
        *slot.borrow_mut() = std::ffi::CString::new(message.replace('\0', " ")).unwrap();
    });
}

/// The ONE shared boundary guard (SEC-1/ENG-4: every export wraps its
/// whole body here). A panic maps to the sentinel return plus a named
/// message in the core's wording family — never an unwind across
/// `extern "C"` (undefined behavior). A success CLEARS the thread-local
/// error, so [`clearfile_last_error`]'s `""` means exactly "the last
/// call on this thread succeeded" (the header's documented contract).
fn ffi_guard<T>(body: impl FnOnce() -> Result<T, String>) -> Option<T> {
    match catch_unwind(AssertUnwindSafe(body)) {
        Ok(Ok(value)) => {
            set_last_error("");
            Some(value)
        }
        Ok(Err(message)) => {
            set_last_error(&message);
            None
        }
        Err(_) => {
            set_last_error("The operation failed unexpectedly — an internal error occurred.");
            None
        }
    }
}

// ---------------------------------------------------------------------------
// The input marshaling helpers (SEC-2: (ptr, len) pairs, NUL-safe)
// ---------------------------------------------------------------------------

/// Decode `(ptr, len)` into a byte slice; `None` for an empty/NULL slice
/// (the empty payload is handled by the callers as the empty input).
fn as_bytes<'a>(ptr: *const c_char, len: usize) -> Result<&'a [u8], String> {
    if ptr.is_null() || len == 0 {
        return Ok(&[]);
    }
    // SAFETY: the caller guarantees `len` readable bytes at `ptr` for
    // the duration of the call (the ABI contract: the platform-side
    // caller owns the buffer; the length is authoritative — NUL-safe).
    Ok(unsafe { std::slice::from_raw_parts(ptr as *const u8, len) })
}

/// The 512 MiB pre-read bound, enforced at the boundary before any parse
/// (SEC-6: the C boundary is the permanent surface N4/N5/N6 consume).
fn check_size(len: usize) -> Result<(), String> {
    if input_file_too_large(len as u64) {
        return Err(INPUT_TOO_LARGE_MESSAGE.to_string());
    }
    Ok(())
}

/// UTF-8 validation with the named error in the core's wording family.
fn as_utf8<'a>(bytes: &'a [u8]) -> Result<&'a str, String> {
    std::str::from_utf8(bytes).map_err(|_| {
        "The input text is not valid UTF-8 — a ClearFile payload must be UTF-8.".to_string()
    })
}

/// Parse a JSON input, surfacing the parser's own named errors
/// (the member cap's `TooManyMembers` etc. — the core's detailed wording
/// family) — this is the raw-JSON-input path; the envelope path keeps the
/// codec's own user-facing message ("The file is not valid JSON." — the
/// app-parity surface).
fn parse_json(text: &str) -> Result<Json, String> {
    Json::parse(text).map_err(|e| e.to_string())
}

/// Serialize a `Json` value to the owned return buffer (never fails in
/// practice: the values below are finite-only by construction).
fn to_owned_buffer(value: &Json) -> Result<*mut c_char, String> {
    let text = value
        .write()
        .map_err(|_| "The result could not be serialized.".to_string())?;
    Ok(std::ffi::CString::new(text)
        .map_err(|_| "The result could not be serialized.".to_string())?
        .into_raw())
}

// ---------------------------------------------------------------------------
// The JSON serializers (the payload shapes mirror the shared fixtures)
// ---------------------------------------------------------------------------

/// The filing payload: the model's own flat serialization minus the two
/// legacy markers — exactly the envelope's `filing` subtree (byte-parity
/// with `ReturnFileCodec::encode` by construction).
fn filing_json(filing: &TaxReturnData) -> Json {
    match filing.to_json_map() {
        Json::Obj(pairs) => {
            let pairs: Vec<(String, Json)> = pairs
                .into_iter()
                .filter(|(k, _)| k != "format" && k != "formatVersion")
                .collect();
            Json::Obj(pairs)
        }
        other => other, // Defensive: to_json_map always builds an object.
    }
}

/// The result payload: the TaxResult field set in the shared golden
/// fixtures' `expected` shape (camelCase keys, the comparator's order) —
/// so the boundary battery can compare the C ABI's outputs against the
/// fixture corpus directly.
fn result_json(result: &TaxResult) -> Json {
    use Json::{Num, Obj, Str};
    Obj(vec![
        ("totalIncome".to_owned(), Num(result.total_income)),
        ("studentLoanDeduction".to_owned(), Num(result.student_loan_deduction)),
        ("agi".to_owned(), Num(result.agi)),
        ("basicStandardDeduction".to_owned(), Num(result.basic_standard_deduction)),
        ("additionalStandardDeduction".to_owned(), Num(result.additional_standard_deduction)),
        ("seniorDeduction".to_owned(), Num(result.senior_deduction)),
        ("standardDeductionTotal".to_owned(), Num(result.standard_deduction_total)),
        ("saltPaid".to_owned(), Num(result.salt_paid)),
        ("saltCap".to_owned(), Num(result.salt_cap)),
        ("saltAllowed".to_owned(), Num(result.salt_allowed)),
        ("itemizedDeductionTotal".to_owned(), Num(result.itemized_deduction_total)),
        (
            "deductionMethodUsed".to_owned(),
            Str(result.deduction_method_used.name().to_owned()),
        ),
        ("deductionUsed".to_owned(), Num(result.deduction_used)),
        ("taxableIncome".to_owned(), Num(result.taxable_income)),
        ("ordinaryTax".to_owned(), Num(result.ordinary_tax)),
        ("preferentialIncome".to_owned(), Num(result.preferential_income)),
        ("preferentialTax".to_owned(), Num(result.preferential_tax)),
        ("niit".to_owned(), Num(result.niit)),
        ("nonRefundableCredits".to_owned(), Num(result.non_refundable_credits)),
        ("refundableCredits".to_owned(), Num(result.refundable_credits)),
        ("totalTax".to_owned(), Num(result.total_tax)),
        ("totalPayments".to_owned(), Num(result.total_payments)),
        ("refund".to_owned(), Num(result.refund)),
        ("amountOwed".to_owned(), Num(result.amount_owed)),
        ("effectiveRate".to_owned(), Num(result.effective_rate)),
        ("marginalRate".to_owned(), Num(result.marginal_rate)),
        ("qualifyingChildren".to_owned(), Num(result.qualifying_children as f64)),
    ])
}

/// The inspection payload: the analysis surface the platforms render
/// (the Dart `TaxInspection` shape; the raw STORE payloads stay on the
/// Rust side — only names, methods, sizes, entropy flags, previews).
fn inspection_json(analysis: &TaxInspection) -> Json {
    use Json::{Arr, Num, Obj, Str};
    Obj(vec![
        ("isZip".to_owned(), Json::Bool(analysis.is_zip)),
        (
            "clearfileContainer".to_owned(),
            Json::Bool(analysis.clearfile_container),
        ),
        (
            "intuitModernContainer".to_owned(),
            Json::Bool(analysis.intuit_modern_container),
        ),
        (
            "entries".to_owned(),
            Arr(analysis
                .entries
                .iter()
                .map(|entry| {
                    Obj(vec![
                        ("name".to_owned(), Str(entry.name.clone())),
                        ("method".to_owned(), Num(entry.method as f64)),
                        ("uncompressedSize".to_owned(), Num(entry.uncompressed_size as f64)),
                        ("size".to_owned(), Num(entry.size as f64)),
                        ("entropy".to_owned(), entry.entropy.map(Num).unwrap_or(Json::Null)),
                        (
                            "likelyEncrypted".to_owned(),
                            entry.likely_encrypted.map(Json::Bool).unwrap_or(Json::Null),
                        ),
                        ("preview".to_owned(), entry.preview.clone().map(Str).unwrap_or(Json::Null)),
                    ])
                })
                .collect()),
        ),
        ("warnings".to_owned(), Arr(analysis
            .warnings
            .iter()
            .map(|w| Str(w.clone()))
            .collect())),
        ("summary".to_owned(), Str(analysis.summary.clone())),
    ])
}

// ---------------------------------------------------------------------------
// The flat C ABI (the exported surface — see clearfile.h for the C99 view)
// ---------------------------------------------------------------------------

/// Compute TY2025 from a return input (the flat fixture-input JSON
/// shape) — returns the owned TaxResult JSON (the fixtures' `expected`
/// shape), or `NULL` with [`clearfile_last_error`] set.
#[no_mangle]
pub extern "C" fn clearfile_compute(input_json: *const c_char, len: usize) -> *mut c_char {
    ffi_guard(|| {
        let bytes = as_bytes(input_json, len)?;
        check_size(bytes.len())?;
        let text = as_utf8(bytes)?;
        let parsed = parse_json(text)?;
        let filing = TaxReturnData::from_json_map(&parsed);
        let result = compute_ty2025(&filing.input);
        let payload = result_json(&result);
        to_owned_buffer(&payload)
    })
    .unwrap_or(std::ptr::null_mut())
}

/// Decode a `.clearfile.json` envelope file's text — returns the owned
/// `{"filing": {...}, "warnings": [...]}` JSON, or `NULL` with the
/// envelope's own user-readable message in [`clearfile_last_error`]
/// (migrations surface as the warnings array, verbatim from the core).
#[no_mangle]
pub extern "C" fn clearfile_decode_envelope(text: *const c_char, len: usize) -> *mut c_char {
    ffi_guard(|| {
        let bytes = as_bytes(text, len)?;
        check_size(bytes.len())?;
        let text = as_utf8(bytes)?;
        let decoded = ReturnFileCodec::decode(text).map_err(|e| e.message)?;
        let payload = Json::Obj(vec![
            ("filing".to_owned(), filing_json(&decoded.filing)),
            (
                "warnings".to_owned(),
                Json::Arr(decoded.warnings.iter().map(|w| Json::Str(w.clone())).collect()),
            ),
        ]);
        to_owned_buffer(&payload)
    })
    .unwrap_or(std::ptr::null_mut())
}

/// Encode a `.clearfile.json` envelope file from a filing (the flat
/// input shape) and a `savedAt` UTC timestamp — returns the owned
/// envelope file text, or `NULL` with the named error.
#[no_mangle]
pub extern "C" fn clearfile_encode_envelope(
    filing_json_text: *const c_char,
    filing_len: usize,
    saved_at_utc: *const c_char,
    saved_len: usize,
) -> *mut c_char {
    ffi_guard(|| {
        let bytes = as_bytes(filing_json_text, filing_len)?;
        check_size(bytes.len())?;
        let text = as_utf8(bytes)?;
        let parsed = parse_json(text)?;
        let filing = TaxReturnData::from_json_map(&parsed);
        let saved_bytes = as_bytes(saved_at_utc, saved_len)?;
        let saved_at = as_utf8(saved_bytes)?;
        let envelope = ReturnFileCodec::encode(&filing, saved_at).map_err(|e| e.message)?;
        Ok(std::ffi::CString::new(envelope)
            .map_err(|_| "The return could not be saved.".to_string())?
            .into_raw())
    })
    .unwrap_or(std::ptr::null_mut())
}

/// Import TXF text — returns the owned
/// `{"displayName": ..., "input": {...}, "warnings": [...],
/// "unknownCodes": [...]}` JSON, or `NULL` with the named error.
#[no_mangle]
pub extern "C" fn clearfile_import_txf(contents: *const c_char, len: usize) -> *mut c_char {
    ffi_guard(|| {
        let bytes = as_bytes(contents, len)?;
        check_size(bytes.len())?;
        let text = as_utf8(bytes)?;
        let imported = parse_txf(text).map_err(|e| e.to_string())?;
        // The shell carries the imported input in the filing shape (the
        // metadata fields default as the envelope reader would read
        // them back — the round-trip through from_json_map is the
        // payload's own contract).
        let shell = TaxReturnData {
            id: String::new(),
            display_name: imported.return_data.display_name.clone(),
            created: String::new(),
            modified: String::new(),
            input: imported.return_data.input,
        };
        let payload = Json::Obj(vec![
            ("displayName".to_owned(), Json::Str(imported.return_data.display_name)),
            ("input".to_owned(), filing_json(&shell)),
            (
                "warnings".to_owned(),
                Json::Arr(imported.warnings.iter().map(|w| Json::Str(w.clone())).collect()),
            ),
            (
                "unknownCodes".to_owned(),
                Json::Arr(
                    imported
                        .unknown_codes
                        .iter()
                        .map(|code| Json::Num(*code as f64))
                        .collect(),
                ),
            ),
        ]);
        to_owned_buffer(&payload)
    })
    .unwrap_or(std::ptr::null_mut())
}

/// Export TXF text from a return input (the flat input shape) and the
/// export date — returns the owned TXF text, or `NULL` with the named
/// error.
#[no_mangle]
pub extern "C" fn clearfile_export_txf(
    input_json: *const c_char,
    input_len: usize,
    month: u32,
    day: u32,
    year: i64,
) -> *mut c_char {
    ffi_guard(|| {
        let bytes = as_bytes(input_json, input_len)?;
        check_size(bytes.len())?;
        let text = as_utf8(bytes)?;
        let parsed = parse_json(text)?;
        let filing = TaxReturnData::from_json_map(&parsed);
        let exported = export_txf(&filing.input, month, day, year);
        Ok(std::ffi::CString::new(exported)
            .map_err(|_| "The TXF export could not be written.".to_string())?
            .into_raw())
    })
    .unwrap_or(std::ptr::null_mut())
}

/// Inspect `.tax` container bytes (read-only analysis) — returns the
/// owned analysis JSON (never fails on any input: the analysis reports
/// what it could establish; the core's own contract), or `NULL` only on
/// the size bound / an internal panic (the guard).
#[no_mangle]
pub extern "C" fn clearfile_inspect_tax(bytes: *const c_char, len: usize) -> *mut c_char {
    ffi_guard(|| {
        let payload = as_bytes(bytes, len)?;
        check_size(payload.len())?;
        let analysis = analyze_tax_file(payload);
        to_owned_buffer(&inspection_json(&analysis))
    })
    .unwrap_or(std::ptr::null_mut())
}

/// The composed pipeline (the RECORDED N3 addition — ADR-017's core
/// boundary: zero engine logic platform-side): ZIP-signature dispatch →
/// container import (the merged warnings) or envelope decode → TY2025
/// compute — everything the platform viewer needs:
/// `{"source": ..., "filing": {...}, "result": {...}, "warnings": [...]}`.
/// `NULL` with the named message in the core's wording family (the same
/// messages the Linux app's `load_and_compute` surfaces — the parity is
/// deliberate: one pipeline, two hosts).
#[no_mangle]
pub extern "C" fn clearfile_load_and_compute(bytes: *const c_char, len: usize) -> *mut c_char {
    ffi_guard(|| {
        let payload = as_bytes(bytes, len)?;
        check_size(payload.len())?;
        // The ZIP-signature dispatch (mirroring the Linux app's
        // looks_like_zip: a .clearfile.json envelope can never begin
        // with a ZIP signature; a container always does).
        let is_zip = payload.starts_with(b"PK\x03\x04")
            || payload.starts_with(b"PK\x05\x06")
            || payload.starts_with(b"PK\x07\x08");
        let loaded = if is_zip {
            load_container(payload)?
        } else {
            load_envelope(payload)?
        };
        let result = compute_ty2025(&loaded.filing.input);
        let payload = Json::Obj(vec![
            ("source".to_owned(), Json::Str(loaded.source)),
            ("filing".to_owned(), filing_json(&loaded.filing)),
            ("result".to_owned(), result_json(&result)),
            (
                "warnings".to_owned(),
                Json::Arr(loaded.warnings.iter().map(|w| Json::Str(w.clone())).collect()),
            ),
        ]);
        to_owned_buffer(&payload)
    })
    .unwrap_or(std::ptr::null_mut())
}

/// The loaded shape the composed pipeline returns.
struct Loaded {
    source: String,
    filing: TaxReturnData,
    warnings: Vec<String>,
}

/// The container path (the Linux app's import_container parity): the
/// composed import, or the honest analysis-as-error.
fn load_container(payload: &[u8]) -> Result<Loaded, String> {
    match import_tax_container(payload) {
        Some(ContainerImport::Imported(imported)) => Ok(Loaded {
            source: "the ClearFile exchange container (.tax)".to_owned(),
            filing: imported.filing,
            warnings: imported.warnings,
        }),
        Some(ContainerImport::FellThrough(analysis)) => Err(container_error(&analysis)),
        None => Err(container_error(&analyze_tax_file(payload))),
    }
}

/// The container error shape (the Linux app's container_error parity:
/// the analysis summary + its warnings ARE the honest error).
fn container_error(analysis: &TaxInspection) -> String {
    let mut message = format!(
        "The .tax file could not be imported as a ClearFile container. {}",
        analysis.summary
    );
    for warning in &analysis.warnings {
        message.push_str("\n  - ");
        message.push_str(warning);
    }
    message
}

/// The envelope path (the Linux app's import_envelope parity).
fn load_envelope(payload: &[u8]) -> Result<Loaded, String> {
    let text = as_utf8(payload).map_err(|_| {
        "The file is not valid UTF-8 text; a ClearFile return file must be UTF-8.".to_string()
    })?;
    let decoded = ReturnFileCodec::decode(text).map_err(|e| e.message)?;
    Ok(Loaded {
        source: "the .clearfile.json envelope".to_owned(),
        filing: decoded.filing,
        warnings: decoded.warnings,
    })
}

/// The MD3-from-seed scheme role color (ARGB, opaque) for a seed, a
/// brightness, and a role name (the corpus's camelCase key — e.g.
/// "primary", "surfaceContainerHigh"); returns `0` with
/// [`clearfile_last_error`] set for an unknown role name (the scheme's
/// roles are always opaque, so `0` is never a valid scheme color).
#[no_mangle]
pub extern "C" fn clearfile_palette_scheme_role(
    seed: u32,
    dark: bool,
    role_name: *const c_char,
    role_len: usize,
) -> u32 {
    ffi_guard(|| {
        let bytes = as_bytes(role_name, role_len)?;
        let name = as_utf8(bytes)?;
        let role = PaletteRole::ALL
            .iter()
            .copied()
            .find(|role| role.name() == name)
            .ok_or_else(|| {
                format!("Unknown color role \"{name}\" — the 34 scheme roles are the corpus's camelCase keys.")
            })?;
        Ok(scheme_role(seed, dark, role))
    })
    .unwrap_or(0)
}

/// The borrowed, thread-local last-error message ("" when the last call
/// succeeded) — NEVER freed; valid until the next call on this thread.
#[no_mangle]
pub extern "C" fn clearfile_last_error() -> *const c_char {
    LAST_ERROR.with(|slot| slot.borrow().as_ptr())
}

/// Free an owned return buffer (NULL-safe). The ONLY correct way to
/// release a data function's return (freeing it via libc directly is
/// undefined behavior — the allocation is Rust's).
#[no_mangle]
pub extern "C" fn clearfile_free(owned: *mut c_char) {
    if !owned.is_null() {
        // SAFETY: the pointer came from CString::into_raw on this side
        // of the ABI (the data functions); taking it back reconstructs
        // and drops the allocation.
        drop(unsafe { std::ffi::CString::from_raw(owned) });
    }
}

// ---------------------------------------------------------------------------
// The N6 wasm-lane additions (the 2026-11-27 N6 gate's rulings, ENG-1/SEC-1
// + ENG-2/SEC-3): the alloc/free pair is LENGTH-PAIRED (a leaked Vec freed
// by [`clearfile_free`] would be unsound — CString::from_raw derives the
// dealloc length from strlen, and interior-NUL payloads — every `.tax`
// container — would trap the allocator; probe-verified at the gate), and
// the container export is the ONE binary channel — binary bytes NEVER
// ride the NUL-terminated CString returns, so the export is
// caller-allocated-output with the length out. These are plain exports on
// every target (un-gated): the wasm32 JS loader is their consumer of
// record, and the boundary battery proves them on EVERY lane the same as
// every other export (the gate reconciliation recorded in CONSENSUS).
// ---------------------------------------------------------------------------

/// Allocate an input buffer of `len` usable bytes (zero-initialized, one
/// extra zero byte appended for the text-input case's convenience) for
/// writing an input payload into before a call — the wasm32 lane's one
/// allocation channel (JS has no other way to place bytes in the module's
/// memory; the native consumers own their buffers). The shared 512 MiB
/// bound is refused BEFORE the allocation, with the shared named message
/// family. Returns NULL with the named message. Freed ONLY by
/// [`clearfile_dealloc`] with the SAME `len` — NEVER [`clearfile_free`]
/// (its strlen-derived dealloc is unsound for interior-NUL payloads).
#[no_mangle]
pub extern "C" fn clearfile_alloc(len: usize) -> *mut c_char {
    ffi_guard(|| {
        if input_file_too_large(len as u64) {
            return Err(clearfile_core::INPUT_TOO_LARGE_MESSAGE.to_string());
        }
        let mut buffer = vec![0u8; len + 1];
        let ptr = buffer.as_mut_ptr();
        std::mem::forget(buffer);
        Ok(ptr as *mut c_char)
    })
    .unwrap_or(std::ptr::null_mut())
}

/// Free a [`clearfile_alloc`]ated buffer — length-paired with the SAME
/// `len` that produced it (the wasm32 JS loader's release path; the
/// native consumers never hold [`clearfile_alloc`] buffers). NULL-safe.
#[no_mangle]
pub extern "C" fn clearfile_dealloc(ptr: *mut c_char, len: usize) {
    if !ptr.is_null() {
        // SAFETY: the pointer came from clearfile_alloc(len) on this side
        // of the ABI — the same allocation length (+1 for the zero tail);
        // reconstructing and dropping is the release. Interior NUL bytes
        // are irrelevant: the recorded length governs.
        unsafe { drop(Vec::from_raw_parts(ptr as *mut u8, len + 1, len + 1)) };
    }
}

/// Export a ClearFile exchange container (the `.tax`-extension STORE-only
/// ZIP carrying the serialized envelope as its `clearfile.json` entry)
/// from a PRE-SERIALIZED envelope payload — the ONE binary-data export:
/// the caller allocates `out_bytes` (`out_capacity` bytes), the function
/// writes at most `out_capacity` bytes, stores the total needed length in
/// `*out_len`, and returns 0 on success / 1 when the buffer was too small
/// (the needed size is in `*out_len`; grow and call again) / -1 on a
/// named error (the message in [`clearfile_last_error`]). Binary bytes
/// never ride the CString channel (the N6 gate's ruling); the envelope
/// serialization is the caller's ([`clearfile_encode_envelope`] — the
/// core's own hoisted seam, `export` and `inspect` mirror images across
/// the envelope boundary).
#[no_mangle]
pub extern "C" fn clearfile_export_tax_container(
    envelope_text: *const c_char,
    envelope_len: usize,
    out_bytes: *mut c_char,
    out_capacity: usize,
    out_len: *mut usize,
) -> i32 {
    if out_len.is_null() {
        set_last_error("The container export needs a length output pointer.");
        return -1;
    }
    let guarded = ffi_guard(|| -> Result<i32, String> {
        let bytes = as_bytes(envelope_text, envelope_len)?;
        check_size(bytes.len())?;
        let text = as_utf8(bytes)?;
        let container = export_tax_container(text).map_err(|e| e.to_string())?;
        let needed = container.len();
        // SAFETY: out_len was checked non-NULL above.
        unsafe { *out_len = needed };
        if out_bytes.is_null() || out_capacity < needed {
            return Ok(1);
        }
        // SAFETY: the caller-allocated buffer, out_capacity >= needed,
        // non-overlapping with the container's own allocation.
        unsafe {
            std::ptr::copy_nonoverlapping(
                container.as_ptr(),
                out_bytes as *mut u8,
                needed,
            );
        }
        Ok(0)
    });
    match guarded {
        Some(code) => code,
        None => -1, // the guard set the named message
    }
}

/// The TY2025 parameter table, serialized (the N6 wasm lane's one true
/// source of the parameter DATA — the TS config table's retirement
/// channel; the field names + per-status keys mirror the TS
/// `TaxYearParameters` interface exactly, the last bracket rung's
/// infinite `up_to` as `null`). The adapter parses this once at init;
/// its display walk reads the core-served table (the parameter LOGIC
/// lives nowhere platform-side).
#[no_mangle]
pub extern "C" fn clearfile_params_json() -> *mut c_char {
    ffi_guard(|| {
        let json = clearfile_core::params::TY2025.to_json();
        let text = json
            .write()
            .map_err(|_| "The parameter table could not be serialized.".to_string())?;
        Ok(std::ffi::CString::new(text)
            .map_err(|_| "The parameter table could not be serialized.".to_string())?
            .into_raw())
    })
    .unwrap_or(std::ptr::null_mut())
}

/// The panic-injection test hook (SEC-1's guard proof, feature-gated —
/// NEVER part of the C ABI: `/// cbindgen:ignore`, compiled only behind
/// the `panic-hook-test` feature, exercised by the boundary battery).
/// Returns the sentinel (`NULL`) with the guard's named panic message
/// in [`clearfile_last_error`] — the mapping every export relies on,
/// proven once, here.
///
/// cbindgen:ignore
#[cfg(feature = "panic-hook-test")]
#[no_mangle]
pub extern "C" fn clearfile_test_guard_panic() -> *mut c_char {
    ffi_guard(|| -> Result<*mut c_char, String> {
        panic!("the injected panic — the guard must map this to the sentinel + the named message")
    })
    .unwrap_or(std::ptr::null_mut())
}
