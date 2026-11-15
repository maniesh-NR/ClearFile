#!/usr/bin/env bash
# Fetch and install the Flutter SDK pinned for this project (3.47.9 stable,
# Linux x64) into the gitignored tools/ directory, verifying the tarball's
# sha256 against the official releases_linux.json manifest (WORKFLOW §4
# recycle runbook). Durable version of the ad-hoc fetch used by the
# 2026-11-14/15 sessions.
#
# Resumable: a partial download continues on re-run (curl -C -), so after a
# tool-call timeout or a stall (quirks 15/17 — foreground only, background
# fetchers die between calls) just run this script again.
#
# Usage: bash scripts/fetch_flutter_sdk.sh   (from anywhere; cds to repo root)
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=3.47.9
ARCHIVE="stable/linux/flutter_linux_${VERSION}-stable.tar.xz"
BASE="https://storage.googleapis.com/flutter_infra_release/releases"
MANIFEST="tools/.releases_linux.json"
TARBALL="tools/$(basename "$ARCHIVE")"

mkdir -p tools

# Already installed? Honour it.
if [ -x "tools/flutter/bin/flutter" ]; then
  echo "fetch_flutter: tools/flutter already present"
  exit 0
fi

# 1. Official manifest (sha256 source of truth).
if [ ! -s "$MANIFEST" ]; then
  curl -fsSL --retry 3 -o "$MANIFEST" "$BASE/releases_linux.json"
fi
EXPECTED_SHA=$(python3 - "$MANIFEST" "$VERSION" <<'PYEOF'
import json, sys
manifest = json.load(open(sys.argv[1]))
for rel in manifest["releases"]:
    if (rel.get("version") == sys.argv[2]
            and rel.get("channel") == "stable"
            and rel.get("dart_sdk_arch", "x64") == "x64"):
        print(rel["sha256"])
        sys.exit(0)
sys.exit(f"no stable x64 release found for version {sys.argv[2]}")
PYEOF
)
echo "fetch_flutter: manifest sha256 for ${VERSION} = ${EXPECTED_SHA:0:12}…"

# 2. Resuming download (quirk 15: --speed-limit aborts a stalled mirror so
#    the loop can resume; quirk 17: keep it in the foreground).
if [ ! -f "$TARBALL" ] || ! echo "$EXPECTED_SHA  $TARBALL" | sha256sum -c --status 2>/dev/null; then
  for attempt in $(seq 1 30); do
    if curl -fL --speed-limit 1024 --speed-time 60 -C - -o "$TARBALL" "$BASE/$ARCHIVE"; then
      break
    fi
    echo "fetch_flutter: download retry ${attempt} (resumed)"
    sleep 2
  done
fi

# 3. Verify against the manifest before unpacking.
echo "$EXPECTED_SHA  $TARBALL" | sha256sum -c -

# 4. Unpack and smoke-test.
tar -xJf "$TARBALL" -C tools
tools/flutter/bin/flutter --version --suppress-analytics

echo "fetch_flutter: OK (tools/flutter ${VERSION} stable, sha256 verified)"
