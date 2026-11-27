// SPDX-License-Identifier: GPL-3.0-only
// The :app module — the Android Views viewer demo (no Compose; no AndroidX:
// the zero-AndroidX posture is the recorded N3 gate ruling — plain
// android.app.Activity + platform Views + the platform theme, with the
// MD3-from-seed colors computed through the palette FFI). ZERO engine
// logic: all compute flows through :shared's JNI seam into the Rust core.
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "dev.clearfile.app"
    // compileSdk 36: a stable, verified-present runner platform (the image
    // ships android-34…37.2 incl. betas — pinned to 36, never a beta).
    compileSdk = 36

    defaultConfig {
        applicationId = "dev.clearfile.app"
        // minSdk 24 matches the NDK clang wrapper the cross-build uses
        // (aarch64-linux-android24-clang ⇒ API 24; the recorded pairing).
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
    }

    // The .so packaging: the CI lane builds the cdylib for
    // aarch64-linux-android and copies it into the GENERATED jniLibs dir
    // (never committed — the blob policy; nothing under src/). assembleDebug
    // packages it into lib/arm64-v8a/ of the APK.
    sourceSets {
        getByName("main") {
            jniLibs.srcDir("build/generated/clearfile/jniLibs")
        }
    }
}

// The bundled demo fixture — PULLED from the shared fixtures/tax/ family
// (the fixture-authoring discipline: never a newly-authored fixture; the
// asset is byte-identical to the shared golden fixture, regenerated at
// every build so the two can never drift apart silently).
val bundledFixture = tasks.register<Copy>("bundledFixture") {
    from("$rootDir/../../fixtures/tax/01-tax-table-single-25225.json")
    into(layout.buildDirectory.dir("generated/clearfile/assets"))
    rename { "clearfile-fixture.json" }
}
android {
    sourceSets {
        getByName("main") {
            assets.srcDir(layout.buildDirectory.dir("generated/clearfile/assets"))
        }
    }
}

tasks.named("preBuild") {
    dependsOn(bundledFixture)
}

// The JVM host-test lane's library path: the CI step passes the
// host-built cdylib's path as a gradle system property (-D); this wires it
// through to the forked test JVM (system properties do not cross the
// fork boundary on their own).
tasks.withType<Test>().configureEach {
    System.getProperty("clearfile.host.lib")?.let {
        systemProperty("clearfile.host.lib", it)
    }
}

dependencies {
    implementation(project(":shared"))
    // The ONE external artifact of the whole build: JUnit 4.13.2 (EPL 1.0)
    // — TEST-ONLY, never linked into the APK or any distributed artifact
    // (the recorded gradle-supply-chain posture; the runtime dependency
    // set is exactly one project module and zero external artifacts).
    testImplementation("junit:junit:4.13.2")
}
