// swift-tools-version: 5.9
// SPDX-License-Identifier: GPL-3.0-only
// The ClearFile macOS SPM package (N5, the ADR-017 epilogue): ONE
// Swift+AppKit app consuming the SAME committed flat C ABI header
// (core-ffi/clearfile.h) through the ClearFileFFI wrapper target
// (the wrapper umbrella header — the symlink shape was rejected at
// the N5 gate: both sandbox probe findings recorded). ZERO external
// dependencies — the platform frameworks only (AppKit + Foundation,
// both under the GPLv3 §1 system-library carve-out; the zero-dep
// posture is asserted fail-closed in CI).
//
// The deployment floor is macOS 13 Ventura (ADR-017's macOS tiering)
// — BUILD-TIME-ONLY confirmable: the macos-13 CI image is retired
// (the 2026-11-27 live probe); the floor is enforced by the SDK's
// deployment-target emission and mechanically asserted from the built
// binary's minimum-OS load command.
//
// (The tools-version directive sits at line 1 by SwiftPM's own rule:
// a tools-version appearing after other content makes the manifest
// backward-incompatible for Swift < 6 — the CI round-1 finding,
// 2026-11-27.)

import PackageDescription

let package = Package(
    name: "ClearFileMacOS",
    platforms: [
        // The ADR-017 deployment floor (macOS 13 Ventura, build-time-only
        // confirmable — the macos-13 CI image is retired).
        .macOS(.v13)
    ],
    targets: [
        // The C wrapper target: the umbrella header includes the
        // committed core-ffi/clearfile.h verbatim (nothing re-declared,
        // nothing copied — the CI asserts the include line); the
        // comment-only shim.c anchors the target (SPM C targets need
        // at least one source file).
        .target(
            name: "ClearFileFFI",
            path: "Sources/ClearFileFFI"
        ),
        // The Swift+AppKit app (the executable).
        .executableTarget(
            name: "ClearFileMacOS",
            dependencies: ["ClearFileFFI"],
            path: "Sources/ClearFileMacOS"
        ),
    ]
)
