// SPDX-License-Identifier: GPL-3.0-only
// The N3 Android app (the 2026-11-27 N3 gate's ledger, items 8–10): the
// KMP-shaped build — a :shared module (kotlin("multiplatform") with
// EXACTLY androidTarget(), no second Kotlin target — the ADR-017
// settlement) + an :app module (Android Views, no Compose). The gradle
// supply chain: NO committed wrapper jar (the blob policy bars
// third-party binaries; the CI lane drives the runner's preinstalled
// Gradle behind a fail-closed version assertion — never the unpinned
// default); repositories google()/mavenCentral() only; the plugin
// versions exact-pinned in the plugins DSL; the dependency set minimal
// (zero AndroidX — the zero-AndroidX posture is the recorded gate
// ruling; the only external artifact is the test-scope JUnit 4.13.2,
// EPL 1.0, never linked into the APK).

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "clearfile-android"
include(":shared")
include(":app")
