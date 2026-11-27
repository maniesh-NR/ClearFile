// SPDX-License-Identifier: GPL-3.0-only
// The JVM host test (the N3 gate's no-emulator verification lane,
// ENG-3/SEC-3/PROD-3): System.load's the HOST-built cdylib (built with
// the host-jni feature — the Java_* symbols ride in it) and calls the
// REAL mangled symbols through Kotlin's `external fun` declarations —
// the same JNI seam the device uses, proven without an emulator.
//
// The parity target: the SAME shared golden fixture family every other
// runner consumes (fixtures/tax/ — named by path below); the pinned
// values are fixture 01's own expected object (the same numbers the
// Dart/TS/Rust runners assert). This is the JVM lane of the seam — the
// deep corpus parity is the Rust-side boundary battery's job (core-ffi's
// tests/boundary.rs, 10/10); this lane proves the JVM binding + the
// byte marshaling + the error surfacing.

package dev.clearfile.app

import dev.clearfile.ffi.Native
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.assertThrows
import org.junit.Before
import org.junit.Test

class NativeJniHostTest {

    @Before
    fun loadHostLibrary() {
        // The CI step passes the host-built .so's path; loaded BEFORE the
        // first Native touch (the object never loads on its own — by
        // design; the app calls System.loadLibrary on the device).
        val path = System.getProperty("clearfile.host.lib")
        require(!path.isNullOrBlank()) {
            "pass -Dclearfile.host.lib=<path to the host-built libclearfile_core_ffi.so>"
        }
        System.load(path)
    }

    /** Extract one nested JSON object's text (a test-only scanner: the
     *  brace-depth walk with string awareness — the fixture corpus is
     *  controlled data; the app itself parses with the platform org.json). */
    private fun extractObject(text: String, key: String): String {
        val keyAt = text.indexOf("\"$key\":")
        val start = text.indexOf('{', keyAt)
        var depth = 0
        var inString = false
        var escape = false
        for (i in start until text.length) {
            val c = text[i]
            if (inString) {
                when {
                    escape -> escape = false
                    c == '\\' -> escape = true
                    c == '"' -> inString = false
                }
                continue
            }
            when (c) {
                '"' -> inString = true
                '{' -> depth++
                '}' -> {
                    depth--
                    if (depth == 0) return text.substring(start, i + 1)
                }
            }
        }
        error("unbalanced object for \"$key\"")
    }

    @Test
    fun goldenFixtureParityThroughTheRealJniSeam() {
        // The shared fixture family, by path (the same corpus the Dart/TS/
        // Rust runners consume).
        val fixture = java.io.File("../../fixtures/tax/01-tax-table-single-25225.json")
            .readText()
        val input = extractObject(fixture, "input")
        val output = String(Native.compute(input.toByteArray(Charsets.UTF_8)))

        // Fixture 01's own expected values (the same numbers the shared
        // corpus pins): the boundary's result JSON carries them exactly.
        assertTrue(output.contains("\"totalIncome\":40975"))
        assertTrue(output.contains("\"agi\":40975"))
        assertTrue(output.contains("\"standardDeductionTotal\":15750"))
        assertTrue(output.contains("\"taxableIncome\":25225"))
        assertTrue(output.contains("\"ordinaryTax\":2789"))
        assertTrue(output.contains("\"preferentialTax\":0"))
        assertTrue(output.contains("\"niit\":0"))
        assertTrue(output.contains("\"totalTax\":2789"))
        assertTrue(output.contains("\"amountOwed\":2789"))
        assertTrue(output.contains("\"deductionMethodUsed\":\"standard\""))
    }

    @Test
    fun theComposedPipelineSurfacesTheEnvelopeErrorsAsExceptions() {
        // Not valid JSON → the core's named message, verbatim, as the
        // Java exception (never an unexplained null).
        val error = assertThrows(IllegalStateException::class.java) {
            Native.loadAndCompute("not json at all".toByteArray(Charsets.UTF_8))
        }
        assertEquals("The file is not valid JSON.", error.message)
    }

    @Test
    fun thePaletteSeamMatchesTheCorpusSeedAndSurfacesErrors() {
        // The corpus's recorded app seed (0xFF00696E = -16750226 signed).
        val seed = -0x00FF9692
        val light = Native.paletteSchemeRole(seed, false, "primary".toByteArray(Charsets.UTF_8))
        val dark = Native.paletteSchemeRole(seed, true, "primary".toByteArray(Charsets.UTF_8))
        assertTrue("scheme colors are always opaque (0xFF alpha)", (light ushr 24) == 0xFF)
        assertTrue("light and dark primaries differ", light != dark)
        // The unknown role: the named error as the exception.
        assertThrows(IllegalStateException::class.java) {
            Native.paletteSchemeRole(seed, false, "notARole".toByteArray(Charsets.UTF_8))
        }
    }
}
