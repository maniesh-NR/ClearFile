#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# fetch_rust_toolchain.sh — N1 (ADR-017, the 2026-11-26 entry gate):
# fetch the PINNED standalone Rust toolchain into the gitignored tools/
# directory, verifying sha256 against the tracked manifest row
# (scripts/rust_toolchain_manifest — SEC-2: pinned, not TOFU; the pin
# survives sandbox recycles because the manifest is tracked and the
# fetcher re-verifies on every re-fetch). Unauthenticated public fetch
# only (SEC-6). Quirk-20 hardening: tar's benign trailing-status failure
# is tolerated with a note, the sha256 check stays strict, and the
# `cargo --version` smoke test is the authority.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/scripts/rust_toolchain_manifest"
DEST="$ROOT/tools/rust"
TARBALL="/tmp/rust-toolchain-pinned.tar.xz"

read_row() {
  set -- $(awk 'NR==1{print $1, $2, $3}' "$MANIFEST")
  [ $# -eq 3 ] || { echo "fetch_rust: malformed manifest row (need version url sha256)" >&2; exit 1; }
  PINNED_VERSION="$1"; URL="$2"; PINNED_SHA="$3"
}
read_row

if [ -x "$DEST/bin/cargo" ] && "$DEST/bin/cargo" --version 2>/dev/null | grep -q "$PINNED_VERSION"; then
  echo "fetch_rust: pinned toolchain $PINNED_VERSION already present at $DEST"
  "$DEST/bin/cargo" --version
  exit 0
fi

echo "fetch_rust: downloading $URL (pinned $PINNED_VERSION)"
# Resumable, foreground, unauthenticated (no Authorization header ever).
# Skip the download when a previously verified tarball is already present.
NEED_DL=1
if [ -f "$TARBALL" ]; then
  if echo "$PINNED_SHA  $TARBALL" | sha256sum --check --strict >/dev/null 2>&1; then
    NEED_DL=0
    echo "fetch_rust: existing tarball already matches the pinned sha256 — skipping download"
  fi
fi
if [ "$NEED_DL" -eq 1 ]; then
  curl -L --fail --retry 3 -C - --output "$TARBALL" "$URL"
fi

echo "fetch_rust: verifying sha256 against the tracked manifest"
echo "$PINNED_SHA  $TARBALL" | sha256sum --check --strict

rm -rf "$DEST"
mkdir -p "$DEST"
# Quirk 20: this snapshot FS makes tar's trailing directory-status-restore
# pass fail benignly; tolerate tar's nonzero exit with a note — the sha256
# above stays strict and the version smoke below is the authority.
#
# Layout: the dist tarball is a component tree
# (rust-<ver>-<triple>/{cargo,rustc,rust-std-*}/{bin,lib}/...).
# Stripping TWO components merges every component into one prefix
# (cargo/bin/cargo -> bin/cargo, rustc/bin/rustc -> bin/rustc,
# */lib/rustlib -> lib/rustlib) — the layout rustc's relative-sysroot
# discovery expects (../lib from bin/rustc). Top-level files (COPYRIGHT
# etc.) are skipped by the strip; the heavy non-build components (docs,
# rustc-dev, llvm-tools, src, mingw, clippy, rustfmt) are excluded —
# cargo test needs exactly cargo + rustc + rust-std.
tar -xJf "$TARBALL" -C "$DEST" --strip-components=2 \
  --exclude='*/rust-docs*' --exclude='*/rustc-dev*' \
  --exclude='*/llvm-tools*' --exclude='*/rust-src*' \
  --exclude='*/rust-mingw*' --exclude='*/clippy-preview*' \
  --exclude='*/rustfmt-preview*' || \
  echo "fetch_rust: note — tar exited nonzero (the recorded benign trailing-status class); the smoke test decides" >&2

ACTUAL=$("$DEST/bin/cargo" --version 2>/dev/null || true)
case "$ACTUAL" in
  *"$PINNED_VERSION"*) echo "fetch_rust: smoke pass — $ACTUAL" ;;
  "") echo "fetch_rust: FAIL — cargo smoke produced no version" >&2; exit 1 ;;
  *) echo "fetch_rust: FAIL — cargo version '$ACTUAL' does not match pinned $PINNED_VERSION" >&2; exit 1 ;;
esac
"$DEST/bin/rustc" --version
echo "fetch_rust: OK — pinned toolchain $PINNED_VERSION installed at $DEST"
