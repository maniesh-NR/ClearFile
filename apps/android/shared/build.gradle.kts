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
    id("com.android.library")
}

android {
    namespace = "dev.clearfile.ffi"
    compileSdk = 36
    defaultConfig {
        minSdk = 24
    }
}

kotlin {
    // EXACTLY one Kotlin target — android. No iOS (explicitly dropped
    // by ADR-017), no JVM/desktop/JS targets (a second target adds
    // surface with no consumer).
    androidTarget()

    sourceSets {
        commonMain.dependencies {
            // Intentionally empty: zero external dependencies (the glue
            // is pure Kotlin + the platform's own APIs).
        }
    }
}
