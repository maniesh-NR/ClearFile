// SPDX-License-Identifier: GPL-3.0-only
// The :shared module — the KMP shape with EXACTLY ONE Kotlin target
// (androidTarget; the ADR-017 settlement: "KMP second target: None —
// Android-only. Sharing is the Rust core's job over JNI"). ZERO engine
// logic lives here (the ADR-017 core boundary): the module carries the
// JNI binding glue (commonMain's external declarations + androidMain's
// loader/display glue) ONLY — every compute flows through the
// clearfile-core Rust core via the thin JNI shim (the cdylib).
plugins {
    id("org.jetbrains.kotlin.multiplatform")
    // AGP 9's KMP-module plugin (the KMP-library replacement for
    // com.android.library — incompatible with kotlin("multiplatform")
    // since AGP 9.0; the KMP library plugin creates the android target
    // and carries its Android identity in androidLibrary below).
    id("com.android.kotlin.multiplatform.library")
}

kotlin {
    // EXACTLY one Kotlin target — android (the plugin creates it; no
    // iOS — explicitly dropped by ADR-017 — no JVM/desktop/JS targets:
    // a second target adds surface with no consumer).
    androidLibrary {
        namespace = "dev.clearfile.ffi"
        compileSdk = 36
        minSdk = 24
    }

    sourceSets {
        commonMain.dependencies {
            // Intentionally empty: zero external dependencies (the glue
            // is pure Kotlin + the platform's own APIs).
        }
    }
}
