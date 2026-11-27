// SPDX-License-Identifier: GPL-3.0-only
// The android glue (androidMain): the JNI binding (the real
// Java_dev_clearfile_ffi_Native_* symbols from the cdylib's shim —
// package dev.clearfile.ffi, class Native), the loader, and the display
// glue. ZERO engine logic: every value comes from the Rust core through
// the boundary; the parsing here is display glue over the boundary's own
// JSON payloads (the org.json platform library — zero external
// dependencies).

package dev.clearfile.ffi

import org.json.JSONObject

/** The JNI binding surface (one function per flat-C function). */
object Native {
    // No loader here by design: the single System.loadLibrary call is the
    // app's job (MainActivity.onCreate owns it); the JVM host test instead
    // System.load's the host-built .so before first use (either path makes
    // the externals resolvable — the JNI layer never loads on its own).

    /** Compute TY2025 from a return input (the flat fixture-input JSON shape). */
    external fun compute(inputJson: ByteArray): ByteArray

    /** Decode a .clearfile.json envelope file's text → {"filing":…, "warnings":[…]}. */
    external fun decodeEnvelope(text: ByteArray): ByteArray

    /** Encode a .clearfile.json envelope file from a filing + a savedAt timestamp. */
    external fun encodeEnvelope(filingJson: ByteArray, savedAtUtc: ByteArray): ByteArray

    /** Import TXF text → {displayName, input, warnings, unknownCodes}. */
    external fun importTxf(contents: ByteArray): ByteArray

    /** Export TXF text from a return input + the export date. */
    external fun exportTxf(inputJson: ByteArray, month: Int, day: Int, year: Long): ByteArray

    /** Inspect .tax container bytes (read-only analysis, never fails). */
    external fun inspectTax(bytes: ByteArray): ByteArray

    /** The composed pipeline (the recorded N3 addition: zero engine logic platform-side). */
    external fun loadAndCompute(bytes: ByteArray): ByteArray

    /** The MD3-from-seed scheme role color (ARGB, opaque); throws for an unknown role. */
    external fun paletteSchemeRole(seed: Int, dark: Boolean, roleName: ByteArray): Int

    /** The last error message ("" when the last call succeeded). */
    external fun lastError(): ByteArray
}

/** The single library load (the app's startup owns it — see Native's
 *  header comment for the JVM-host test's alternative path). */
fun ensureLoaded() {
    System.loadLibrary("clearfile_core_ffi")
}

/** The display glue: one loaded-and-computed payload for the viewer. */
fun loadAndDisplay(bytes: ByteArray): LoadedReturn {
    // The boundary's own guard refuses any payload beyond 512 MiB (the
    // shared core constant MAX_INPUT_FILE_BYTES — 2× the 256 MiB STORE
    // cap) with the named message; MainActivity pre-checks the SAF
    // document size, this is the defense-in-depth re-check.
    val payload = String(Native.loadAndCompute(bytes))
    val root = JSONObject(payload)
    val result = root.getJSONObject("result")
    val refund = result.optDouble("refund", 0.0)
    val owed = result.optDouble("amountOwed", 0.0)
    val refundOrOwed = when {
        refund > 0.0 -> "Refund: $%,.0f".format(refund)
        owed > 0.0 -> "Amount owed: $%,.0f".format(owed)
        else -> "Balanced (no refund, nothing owed)"
    }
    val warnings = mutableListOf<String>()
    val arr = root.optJSONArray("warnings")
    if (arr != null) {
        for (i in 0 until arr.length()) {
            warnings.add(arr.getString(i))
        }
    }
    return LoadedReturn(
        source = root.getString("source"),
        totalIncome = "$%,.0f".format(result.optDouble("totalIncome", 0.0)),
        taxableIncome = "$%,.0f".format(result.optDouble("taxableIncome", 0.0)),
        totalTax = "$%,.0f".format(result.optDouble("totalTax", 0.0)),
        refundOrOwed = refundOrOwed,
        warnings = warnings,
    )
}

/** A scheme role color (ARGB int) via the palette FFI. */
fun roleColor(dark: Boolean, role: String): Int =
    Native.paletteSchemeRole(THEME_SEED, dark, role.toByteArray(Charsets.UTF_8))
