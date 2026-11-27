// SPDX-License-Identifier: GPL-3.0-only
// The root build: the exact-pinned plugin versions (verified live at
// authoring: com.android.* 9.5.3 via dl.google.com's group index,
// Kotlin 2.4.21 via repo1.maven.org — the runner's Gradle 9.9.1/JDK 21
// lane is guarded fail-closed in CI before any of these resolve).
plugins {
    id("com.android.application") version "9.5.3" apply false
    id("com.android.library") version "9.5.3" apply false
    id("org.jetbrains.kotlin.android") version "2.4.21" apply false
    id("org.jetbrains.kotlin.multiplatform") version "2.4.21" apply false
}
