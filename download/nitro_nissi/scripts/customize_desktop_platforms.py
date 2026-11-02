#!/usr/bin/env python3
"""Apply Nitro Nissi customizations to the flutter-created desktop runners.

Run after:  flutter create --platforms=linux,windows,macos --org com.nitronissi .
Idempotent: safe to run repeatedly.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

APP_NAME = "Nitro Nissi"
BUNDLE_ID = "com.nitronissi.app"
VERSION = "1.0.0"


def patch(path, pairs, required=True):
    full = os.path.join(ROOT, path)
    if not os.path.exists(full):
        if required:
            print(f"  !! missing {path} (run flutter create first)")
        return False
    s = open(full, encoding="utf-8").read()
    changed = False
    for old, new in pairs:
        if old in s:
            s = s.replace(old, new)
            changed = True
        elif new in s:
            pass  # already applied
        else:
            print(f"  ?? pattern not found in {path}: {old[:60]}")
    if changed:
        open(full, "w", encoding="utf-8").write(s)
        print(f"  patched {path}")
    return True


def main():
    print("Customizing desktop runners for Nitro Nissi...")

    # ---- Windows ----
    patch("windows/runner/Runner.rc", [
        ('STRINGVALUE, "nitro_nissi"', f'STRINGVALUE, "{APP_NAME}"'),
        ('"nitro_nissi"', APP_NAME),
        ("0,0,0,0", f"{VERSION},0,0,0"),  # VERSIONINFO fields
    ], required=False)

    # ---- macOS ----
    patch("macos/Runner/Configs/AppInfo.xcconfig", [
        ("com.example.nitroNissi", BUNDLE_ID),
        ("Com.example.nitroNissi", BUNDLE_ID.replace("com.", "com.")),
        ("nitro_nissi", APP_NAME),
    ], required=False)
    patch("macos/Runner/Configs/AppInfo.xcconfig", [
        ("com.example.nitroNissi", BUNDLE_ID),
    ], required=False)

    # Deployment target: Catalina 10.15
    for proj in [
        "macos/Runner.xcodeproj/project.pbxproj",
        "macos/Runner/Configs/AppInfo.xcconfig",
    ]:
        patch(proj, [
            ("MACOSX_DEPLOYMENT_TARGET = 10.14", "MACOSX_DEPLOYMENT_TARGET = 10.15"),
        ], required=False)
    patch("macos/Runner/Configs/AppInfo.xcconfig", [], required=False)

    # Force 10.15 via xcconfig override file (simplest + robust across templates)
    appinfo = os.path.join(ROOT, "macos/Runner/Configs/AppInfo.xcconfig")
    if os.path.exists(appinfo):
        s = open(appinfo, encoding="utf-8").read()
        if "MACOSX_DEPLOYMENT_TARGET" not in s:
            with open(appinfo, "a", encoding="utf-8") as f:
                f.write("\n// Nitro Nissi: macOS Catalina minimum\nMACOSX_DEPLOYMENT_TARGET = 10.15\n")
            print("  appended MACOSX_DEPLOYMENT_TARGET=10.15 to AppInfo.xcconfig")

    # ---- Linux ----
    patch("linux/CMakeLists.txt", [
        ('set(BINARY_NAME "nitro_nissi")', f'set(BINARY_NAME "nitro_nissi")'),
        ('set(APPLICATION_ID "com.example.nitroNissi")', f'set(APPLICATION_ID "{BUNDLE_ID}")'),
    ], required=False)
    patch("linux/my_application.cc", [
        ('gtk_header_bar_set_title(header_bar, "nitro_nissi");',
         f'gtk_header_bar_set_title(header_bar, "{APP_NAME}");'),
        ('gtk_window_set_default_size(window, 1280, 720);',
         'gtk_window_set_default_size(window, 1280, 800);'),
    ], required=False)
    # Desktop entry icon id
    patch("linux/CMakeLists.txt", [], required=False)

    print("Done.")


if __name__ == "__main__":
    sys.exit(main())
