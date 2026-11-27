// SPDX-License-Identifier: GPL-3.0-only
//! The thin Android/JVM JNI shim (ADR-017's FFI seam: "Android via a
//! thin JNI shim" over the ONE flat C ABI — this module IS the whole
//! shim; the flat C ABI in `lib.rs` stays the single audit surface).
//!
//! ## The marshaling contract (the N3 gate's ledger, item 5)
//!
//! - **`jbyteArray` in/out, NEVER `jstring`** (SEC-3): JNI's
//!   `GetStringUTFChars`/`NewStringUTF` speak Modified UTF-8 (CESU-8
//!   surrogate encoding, embedded NULs) — a real corruption class for
//!   envelope JSON with non-ASCII taxpayer names; byte arrays
//!   end-to-end avoid it entirely.
//! - **The real `Java_*` mangled symbols** (ENG-3/PROD-3): the JVM
//!   tests load the HOST-built cdylib (the `host-jni` feature) and call
//!   these very exports — the no-emulator verification lane.
//! - **A thin translation only** — zero logic of its own: every method
//!   marshals bytes, calls the flat C ABI function of the same name,
//!   and marshals the result back. Every cross-boundary buffer is
//!   Rust-allocated and released inside the same call (the JVM never
//!   frees Rust memory).
//! - **Panic containment**: every export wraps its whole body in the
//!   same shared [`ffi_guard`] (the exported-count == guarded-count
//!   audit covers this module's exports too).
//! - **Errors surface as Java exceptions** carrying the core's named
//!   message verbatim — the JVM caller never sees an unexplained NULL.
//!
//! ## The bound class (fixed at the N3 session-1 commit)
//!
//! Package `dev.clearfile.ffi`, class `Native` — the Kotlin side
//! declares `external fun` members on this exact class; the JVM binds
//! `Java_dev_clearfile_ffi_Native_<method>` by name. The class owns the
//! single `System.loadLibrary("clearfile_core_ffi")` call.
//!
//! cbindgen:ignore — this module's exports are NOT part of
//! `clearfile.h` (the header is the flat C ABI only; the JVM binds by
//! the mangled names below).

use crate::ffi_guard;
use jni::objects::{JByteArray, JClass};
use jni::sys::{jbyteArray, jboolean, jint, jlong};
use jni::JNIEnv;

/// Marshal a `jbyteArray` input into an owned `Vec<u8>` (copied — the
/// JVM buffer is released before any C call; no pin lifetime crosses
/// the seam).
fn read_array(env: &mut JNIEnv, array: &JByteArray) -> Result<Vec<u8>, String> {
    if array.is_null() {
        return Ok(Vec::new());
    }
    env.convert_byte_array(array)
        .map_err(|_| "The Java byte array could not be read.".to_string())
}

/// Marshal an owned byte vector into a fresh `jbyteArray` (the raw
/// FFI-safe return type).
fn write_array(env: &mut JNIEnv, bytes: &[u8]) -> Result<jbyteArray, String> {
    let array = env
        .byte_array_from_slice(bytes)
        .map_err(|_| "The Java byte array could not be created.".to_string())?;
    Ok(array.as_raw())
}

/// Copy a C-owned return buffer into a `jbyteArray` and release the
/// Rust buffer in the same call (`NULL` means the C call failed —
/// surface the last error).
fn owned_c_to_java(env: &mut JNIEnv, owned: *mut std::ffi::c_char) -> Result<jbyteArray, String> {
    if owned.is_null() {
        return Err(last_error_text());
    }
    // SAFETY: `owned` came from CString::into_raw on the lib.rs side
    // (the flat C ABI's owned-return contract); from_raw reconstructs
    // the CString for the copy, and it drops at the scope end.
    let text = unsafe { std::ffi::CString::from_raw(owned) };
    write_array(env, text.as_bytes())
}

/// The current last-error text as an owned byte vector (copied out of
/// the borrowed thread-local — safe across the boundary).
fn last_error_text() -> String {
    // SAFETY: clearfile_last_error returns the thread-local CString's
    // pointer, valid until the next call on this thread (the ABI
    // contract); copied immediately.
    let ptr = crate::clearfile_last_error();
    if ptr.is_null() {
        return String::new();
    }
    unsafe { std::ffi::CStr::from_ptr(ptr) }
        .to_string_lossy()
        .into_owned()
}

/// The shared tail of every data export: `Ok` → the array return;
/// `Err` → a Java `IllegalStateException` carrying the core's named
/// message (the same wording family the other platforms surface), plus
/// a NULL array return.
fn finish(env: &mut JNIEnv, result: Result<jbyteArray, String>) -> jbyteArray {
    match result {
        Ok(array) => array,
        Err(message) => {
            // A pending exception (an earlier marshal failure) keeps its
            // own message — never masked.
            if env.exception_check().unwrap_or(false) {
                return std::ptr::null_mut();
            }
            let _ = env.throw_new("java/lang/IllegalStateException", &message);
            std::ptr::null_mut()
        }
    }
}

// ---------------------------------------------------------------------------
// The Java_dev_clearfile_ffi_Native_* exports (one per flat-C function)
// ---------------------------------------------------------------------------

/// cbindgen:ignore
#[no_mangle]
pub extern "system" fn Java_dev_clearfile_ffi_Native_compute<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    input_json: JByteArray<'local>,
) -> jbyteArray {
    let result = ffi_guard(|| {
        let bytes = read_array(&mut env, &input_json)?;
        // The flat C ABI (same crate, same call discipline as every
        // other consumer — the JNI layer adds no logic of its own).
        let owned = crate::clearfile_compute(bytes.as_ptr() as *const std::ffi::c_char, bytes.len());
        owned_c_to_java(&mut env, owned)
    });
    finish(&mut env, result.ok_or_else(last_error_text))
}

/// cbindgen:ignore
#[no_mangle]
pub extern "system" fn Java_dev_clearfile_ffi_Native_decodeEnvelope<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    text: JByteArray<'local>,
) -> jbyteArray {
    let result = ffi_guard(|| {
        let bytes = read_array(&mut env, &text)?;
        let owned = crate::clearfile_decode_envelope(bytes.as_ptr() as *const std::ffi::c_char, bytes.len());
        owned_c_to_java(&mut env, owned)
    });
    finish(&mut env, result.ok_or_else(last_error_text))
}

/// cbindgen:ignore
#[no_mangle]
pub extern "system" fn Java_dev_clearfile_ffi_Native_encodeEnvelope<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    filing_json: JByteArray<'local>,
    saved_at_utc: JByteArray<'local>,
) -> jbyteArray {
    let result = ffi_guard(|| {
        let filing = read_array(&mut env, &filing_json)?;
        let saved = read_array(&mut env, &saved_at_utc)?;
        let owned = crate::clearfile_encode_envelope(
            filing.as_ptr() as *const std::ffi::c_char,
            filing.len(),
            saved.as_ptr() as *const std::ffi::c_char,
            saved.len(),
        );
        owned_c_to_java(&mut env, owned)
    });
    finish(&mut env, result.ok_or_else(last_error_text))
}

/// cbindgen:ignore
#[no_mangle]
pub extern "system" fn Java_dev_clearfile_ffi_Native_importTxf<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    contents: JByteArray<'local>,
) -> jbyteArray {
    let result = ffi_guard(|| {
        let bytes = read_array(&mut env, &contents)?;
        let owned = crate::clearfile_import_txf(bytes.as_ptr() as *const std::ffi::c_char, bytes.len());
        owned_c_to_java(&mut env, owned)
    });
    finish(&mut env, result.ok_or_else(last_error_text))
}

/// cbindgen:ignore
#[no_mangle]
pub extern "system" fn Java_dev_clearfile_ffi_Native_exportTxf<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    input_json: JByteArray<'local>,
    month: jint,
    day: jint,
    year: jlong,
) -> jbyteArray {
    let result = ffi_guard(|| {
        let bytes = read_array(&mut env, &input_json)?;
        let owned = crate::clearfile_export_txf(
            bytes.as_ptr() as *const std::ffi::c_char,
            bytes.len(),
            month as u32,
            day as u32,
            year as i64,
        );
        owned_c_to_java(&mut env, owned)
    });
    finish(&mut env, result.ok_or_else(last_error_text))
}

/// cbindgen:ignore
#[no_mangle]
pub extern "system" fn Java_dev_clearfile_ffi_Native_inspectTax<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    bytes: JByteArray<'local>,
) -> jbyteArray {
    let result = ffi_guard(|| {
        let payload = read_array(&mut env, &bytes)?;
        let owned = crate::clearfile_inspect_tax(payload.as_ptr() as *const std::ffi::c_char, payload.len());
        owned_c_to_java(&mut env, owned)
    });
    finish(&mut env, result.ok_or_else(last_error_text))
}

/// cbindgen:ignore
#[no_mangle]
pub extern "system" fn Java_dev_clearfile_ffi_Native_loadAndCompute<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    bytes: JByteArray<'local>,
) -> jbyteArray {
    let result = ffi_guard(|| {
        let payload = read_array(&mut env, &bytes)?;
        let owned = crate::clearfile_load_and_compute(payload.as_ptr() as *const std::ffi::c_char, payload.len());
        owned_c_to_java(&mut env, owned)
    });
    finish(&mut env, result.ok_or_else(last_error_text))
}

/// cbindgen:ignore
#[no_mangle]
pub extern "system" fn Java_dev_clearfile_ffi_Native_paletteSchemeRole<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    seed: jint,
    dark: jboolean,
    role_name: JByteArray<'local>,
) -> jint {
    let guarded = ffi_guard(|| {
        let bytes = read_array(&mut env, &role_name)?;
        let color = crate::clearfile_palette_scheme_role(
            seed as u32,
            dark != 0,
            bytes.as_ptr() as *const std::ffi::c_char,
            bytes.len(),
        );
        // The C ABI's 0-sentinel (an unknown role name): surface the
        // named error as the Java exception, never a silent 0.
        if color == 0 {
            return Err(last_error_text());
        }
        Ok(color as jint)
    });
    match guarded {
        Some(color) => color,
        None => {
            if !env.exception_check().unwrap_or(false) {
                let _ = env.throw_new(
                    "java/lang/IllegalStateException",
                    &last_error_text(),
                );
            }
            0
        }
    }
}

/// cbindgen:ignore
#[no_mangle]
pub extern "system" fn Java_dev_clearfile_ffi_Native_lastError<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
) -> jbyteArray {
    let result = ffi_guard(|| write_array(&mut env, last_error_text().as_bytes()));
    finish(&mut env, result.ok_or_else(last_error_text))
}
