// SPDX-License-Identifier: GPL-3.0-only
// The shared glue model (commonMain — the KMP shape's shared source set;
// the ONLY target is android per the ADR-017 settlement: "KMP second
// target: None — Android-only. Sharing is the Rust core's job over JNI").
//
// ZERO engine logic lives in Kotlin (the ADR-017 core boundary): every
// value displayed flows from the clearfile-core Rust core through the
// thin JNI shim (the cdylib) — this file only models what the viewer
// displays.

/** The loaded-and-computed payload the viewer displays (the glue model). */
data class LoadedReturn(
    /** Honest provenance line ("the .clearfile.json envelope" / "the ClearFile exchange container (.tax)"). */
    val source: String,
    /** The headline result rows the demo scope shows first. */
    val totalIncome: String,
    val taxableIncome: String,
    val totalTax: String,
    val refundOrOwed: String,
    /** The import/migration warnings, verbatim from the core. */
    val warnings: List<String>,
)

/** The app's MD3 seed (the corpus's recorded app seed, fixtures/palette —
 *  the same seed the Linux app uses; 0xFF00696E). */
const val THEME_SEED: Int = -0x00FF9692 // 0xFF00696E as a signed Int

/** The MD3 role names the viewer styles with (the corpus's camelCase keys). */
object Roles {
    const val PRIMARY = "primary"
    const val ON_PRIMARY = "onPrimary"
    const val SURFACE = "surface"
    const val ON_SURFACE = "onSurface"
    const val SURFACE_CONTAINER = "surfaceContainer"
    const val ON_SURFACE_VARIANT = "onSurfaceVariant"
    const val ERROR = "error"
    const val ON_ERROR = "onError"
}
