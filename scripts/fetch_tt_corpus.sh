#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# ---------------------------------------------------------------------------
# fetch_tt_corpus.sh — durable acquisition of the TT RE research corpus
# (ADR-019, owner directive 2026-11-22: the four publicly-posted TurboTax
# installer targets for the TT-compatibility program's Phase 1–4 study).
#
# Downloads into gitignored tools/re-corpus/ (ADR-012 mechanics: corpus
# blobs are NEVER tracked; tools/ is wiped by sandbox recycles, and this
# fetcher is the documented re-acquisition path, mirroring
# fetch_flutter_sdk.sh). Byte-sizes are verified inline; the canonical
# sha256 provenance record lives in docs/re-research/corpus-manifest.md
# (compare with `sha256sum` after download — this script prints the
# hash of each file it fetches).
#
# Provenance framing (protocol §7.1 mechanics): the targets are publicly
# posted installer URLs on Intuit's own CDNs, acquired for the owner's
# interoperability research; studying them is the §2.1/§1201(f)
# private-research posture; nothing derived from them is committed to
# this repo except function-fact notes (docs/re-research/).
#
# Usage: bash scripts/fetch_tt_corpus.sh   (from anywhere; cds to root)
# Resumable: re-run after a stall/timeout; curl -C - continues.
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")/.."

DEST="tools/re-corpus"
mkdir -p "$DEST"

# name | url | expected_bytes
TARGETS=(
  "TT_Personal_USA_2026.exe|https://downloads.ecom.intuit.com/ttfed/26tax/Windows_PC_TurboTax_Download.exe|403981944"
  "TT_Personal_CAN_2025.exe|https://intuitglobal.intuit.com/downloads/CanadaTax/2025/dls/TurboTax_2025.exe|369125144"
  "TT_Business_USA_2026.exe|https://downloads.ecom.intuit.com/ttfed/26tax/Windows_PC_TurboTax_Business_Download.exe|379141920"
  "TT_Business_CAN_2025.exe|https://cdn.ctg.intuit.ca/downloads/2025/TTBinc_2025.exe|333073488"
)

for row in "${TARGETS[@]}"; do
  IFS='|' read -r name url bytes <<<"$row"
  # Mechanical sha256 verification against the tracked provenance
  # manifest (2026-11-22 TT gate, SEC-4): the manifest is the
  # known-hash allow-list; this fetcher refuses on any mismatch, so a
  # re-acquisition after a recycle can never silently substitute bytes.
  expected_sha="$(
    awk -F'|' -v u="$url" 'index($0, u) {
      cell=$5; gsub(/[`[:space:]]/, "", cell); print cell
    }' docs/re-research/corpus-manifest.md
  )"
  if [ -z "$expected_sha" ]; then
    echo "fetch_tt_corpus: no sha256 row for $name in docs/re-research/corpus-manifest.md — refusing (manifest drift?)" >&2
    exit 1
  fi
  if [ -f "$DEST/$name" ] && [ "$(stat -c%s "$DEST/$name")" = "$bytes" ]; then
    echo "fetch_tt_corpus: $name already present ($bytes bytes); verifying sha256"
  else
    echo "fetch_tt_corpus: $name <- $url ($bytes bytes)"
    for attempt in $(seq 1 12); do
      if curl -fL --speed-limit 4096 --speed-time 60 -C - -o "$DEST/$name" "$url"; then
        break
      fi
      echo "fetch_tt_corpus: retry ${attempt} (resumed)"
      sleep 3
    done
    actual="$(stat -c%s "$DEST/$name")"
    if [ "$actual" != "$bytes" ]; then
      echo "fetch_tt_corpus: SIZE MISMATCH for $name ($actual != $bytes) — delete and re-run" >&2
      exit 1
    fi
  fi
  actual_sha="$(sha256sum "$DEST/$name" | cut -d' ' -f1)"
  if [ "$actual_sha" != "$expected_sha" ]; then
    echo "fetch_tt_corpus: SHA256 MISMATCH for $name — corpus not authentic to the manifest; delete and re-run" >&2
    exit 1
  fi
  echo "fetch_tt_corpus: $name sha256 verified"
done

echo "fetch_tt_corpus: all four targets present AND sha256-verified against docs/re-research/corpus-manifest.md"
