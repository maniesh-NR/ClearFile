#!/usr/bin/env bash
# Nitro Nissi — one-time desktop platform setup.
#
# Generates the windows/, macos/ and linux/ runner projects with the PINNED
# Flutter version (3.19.x — the last release supporting Windows 7), then
# applies Nitro Nissi customizations (names, icons, deployment target).
# Run this once after cloning; CI runs it automatically.
#
# Usage: bash scripts/setup_desktop_platforms.sh
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Checking Flutter version"
FLUTTER_VERSION="$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')"
echo "    Flutter $FLUTTER_VERSION"
case "$FLUTTER_VERSION" in
  3.19.*) echo "    OK (Windows 7 compatible)" ;;
  *) echo "    WARNING: not 3.19.x. Windows 7 support requires Flutter 3.19.x!" ;;
esac

echo "==> Generating desktop platform projects (existing files are preserved)"
flutter create --platforms=linux,windows,macos --org com.nitronissi --project-name nitro_nissi .

echo "==> Applying Nitro Nissi customizations"
python3 scripts/customize_desktop_platforms.py

echo "==> Generating platform icons"
dart run flutter_launcher_icons

echo "==> Done. Build with:"
echo "     flutter build windows   (Win7 x64 compatible with 3.19.x)"
echo "     flutter build linux"
echo "     flutter build macos     (deployment target 10.15 Catalina)"
