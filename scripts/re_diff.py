#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""re_diff.py — ClearFile Stage-2 RE tooling (protocol Phase 3: differential
byte-level comparison of a same-product file pair).

SECURITY CONTRACT (Stage-2 entry gate 2026-11-17, binding — D38 registered):
- WRITE-FREE: opens both inputs read-only; no writes anywhere, no
  shell-outs, no network. Pinned by the read-only-fixture-dir unit test.
- RESOURCE-BOUNDED: up-front size refusal (--max-bytes, default 128 MiB
  per side), a differing-region cap (--max-regions, default 200), and a
  per-file wall-clock timeout (--timeout). Every cap refuses cleanly: a
  message plus exit code 3, never a crash.
- CRASH-SAFE: empty files, size mismatches, and malformed manifests are
  REPORTED, never thrown (the ENG-1 battery's truncated/adversarial
  shapes are unit-tested against this tool).

PROVENANCE GATE (protocol §7.1 — the Stage-2 entry gate's LEGAL-1
condition, binding): differential analysis runs ONLY on file pairs whose
sha256 appears in a provenance manifest with provenance "owner-authored"
or "synthetic". A pair lacking a manifest entry (or supplied without
--manifest) is refused with exit 3. The manifest is operator-supplied JSON:
    {"entries": [{"sha256": "<64-hex>", "path": "...",
                  "provenance": "owner-authored" | "synthetic",
                  "origin": "..."}]}

Output is offsets, lengths, and per-region Shannon entropy only — the
tool never echoes input bytes (protocol §7.2/§7.4 posture: no decrypted
content, no expression lifts).

Exit codes: 0 ran (incl. clean "byte-identical"/"cannot establish"
reports) · 2 usage error · 3 REFUSAL (cap tripped, unreadable input,
bad manifest, or §7.1 provenance missing).
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import signal
import sys

DEFAULT_MAX_BYTES = 128 * 1024 * 1024
DEFAULT_MAX_REGIONS = 200
DEFAULT_TIMEOUT = 60.0
GOOD_PROVENANCE = {"owner-authored", "synthetic"}


class Refusal(Exception):
    pass


def sha256_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            chunk = f.read(1024 * 1024)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def load_manifest(path: str) -> dict[str, str]:
    """Returns sha256 -> provenance. Malformed manifests refuse cleanly."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            doc = json.load(f)
    except OSError as e:
        raise Refusal(f"could not read manifest: {e}") from e
    except json.JSONDecodeError as e:
        raise Refusal(f"could not parse manifest {path}: {e}") from e
    if not isinstance(doc, dict) or not isinstance(doc.get("entries"), list):
        raise Refusal(
            f"manifest {path} is not the documented shape "
            f"({{'entries': [{{sha256, path, provenance, origin}}]}})")
    out: dict[str, str] = {}
    for i, entry in enumerate(doc["entries"]):
        if not isinstance(entry, dict):
            raise Refusal(f"manifest entry {i} is not an object")
        sha = entry.get("sha256")
        prov = entry.get("provenance")
        if not isinstance(sha, str) or not isinstance(prov, str):
            raise Refusal(
                f"manifest entry {i} lacks 'sha256' or 'provenance'")
        out[sha] = prov
    return out


def entropy(span: bytes) -> float:
    if not span:
        return 0.0
    counts = [0] * 256
    for b in span:
        counts[b] += 1
    ent = 0.0
    for c in counts:
        if c:
            p = c / len(span)
            ent -= p * math.log2(p)
    return ent


def read_capped(path: str, max_bytes: int, timeout: float) -> bytes:
    try:
        size = os.path.getsize(path)
    except OSError as e:
        raise Refusal(f"could not stat input: {e}") from e
    if size == 0:
        return b""
    if size > max_bytes:
        raise Refusal(
            f"refusing: {path} is {size} bytes, over the size cap "
            f"({max_bytes}; --max-bytes). Differential pairs stay bounded.")
    if hasattr(signal, "setitimer"):

        def _timeout(_sig, _frm):
            raise Refusal(
                f"refusing: comparison exceeded the {timeout}s wall-clock "
                f"cap (--timeout); a bounded tool does not grind on.")

        signal.signal(signal.SIGALRM, _timeout)
        signal.setitimer(signal.ITIMER_REAL, timeout)
    try:
        with open(path, "rb") as f:
            return f.read(size)
    except OSError as e:
        raise Refusal(f"could not read {path}: {e}") from e
    finally:
        if hasattr(signal, "setitimer"):
            signal.setitimer(signal.ITIMER_REAL, 0)


def diff_regions(a: bytes, b: bytes, max_regions: int) -> list[tuple[int, int, int]]:
    """Locate differing byte runs. Returns (offset_a, offset_b, length).

    The prefix/suffix common spans are excluded; for equal-size pairs the
    runs are the maximal spans of differing bytes. Raises Refusal past the
    region cap (a flooded report is a cap, not a finding).
    """
    n = min(len(a), len(b))
    prefix = 0
    while prefix < n and a[prefix] == b[prefix]:
        prefix += 1
    suffix = 0
    while suffix < n - prefix and a[len(a) - 1 - suffix] == b[len(b) - 1 - suffix]:
        suffix += 1
    regions: list[tuple[int, int, int]] = []
    i, j = prefix, prefix
    end_a, end_b = len(a) - suffix, len(b) - suffix
    while i < end_a or j < end_b:
        # advance over the differing span
        run = 0
        while i < end_a and j < end_b and a[i] != b[j]:
            run += 1
            i += 1
            j += 1
        if run == 0:
            # one side exhausted (size mismatch): the rest is one region
            if i < end_a or j < end_b:
                regions.append((i, j, max(end_a - i, end_b - j)))
            break
        regions.append((i - run, j - run, run))
        # skip the identical gap up to the next difference
        while i < end_a and j < end_b and a[i] == b[j]:
            i += 1
            j += 1
        if len(regions) > max_regions:
            raise Refusal(
                f"refusing: more than {max_regions} differing regions "
                f"(--max-regions). Narrow the pair or raise the cap "
                f"deliberately.")
    return regions


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(
        prog="re_diff.py",
        description="Phase-3 differential comparison (offsets/lengths/"
                    "entropy only — never bytes). §7.1 provenance manifest "
                    "required; read-only; size/region/timeout caps with "
                    "clean refusals (exit 3).")
    p.add_argument("file_a")
    p.add_argument("file_b")
    p.add_argument("--manifest", required=True,
                   help="provenance manifest JSON (see module docstring); "
                        "pairs lacking an entry are refused per §7.1")
    p.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES,
                   help="per-side size cap; larger inputs are refused "
                        f"(default {DEFAULT_MAX_BYTES})")
    p.add_argument("--max-regions", type=int, default=DEFAULT_MAX_REGIONS,
                   help=f"differing-region cap (default {DEFAULT_MAX_REGIONS})")
    p.add_argument("--timeout", type=float, default=DEFAULT_TIMEOUT,
                   help="wall-clock cap in seconds "
                        f"(default {DEFAULT_TIMEOUT})")
    args = p.parse_args(argv)

    for path in (args.file_a, args.file_b):
        if not os.path.exists(path):
            print(f"re_diff: no such file: {path}", file=sys.stderr)
            return 2
    try:
        manifest = load_manifest(args.manifest)
        try:
            sha_a = sha256_file(args.file_a)
            sha_b = sha256_file(args.file_b)
        except OSError as e:
            raise Refusal(f"could not hash input: {e}") from e
        for path, sha in ((args.file_a, sha_a), (args.file_b, sha_b)):
            provenance = manifest.get(sha)
            if provenance is None:
                print(
                    f"re_diff: REFUSING — no provenance-manifest entry for "
                    f"{path} (sha256 {sha[:16]}...). Differential analysis "
                    f"runs only on owner-authored or synthetic pairs "
                    f"(protocol §7.1).", file=sys.stderr)
                return 3
            if provenance not in GOOD_PROVENANCE:
                print(
                    f"re_diff: REFUSING — manifest provenance "
                    f"'{provenance}' for {path} is neither owner-authored "
                    f"nor synthetic (protocol §7.1).", file=sys.stderr)
                return 3

        a = read_capped(args.file_a, args.max_bytes, args.timeout)
        b = read_capped(args.file_b, args.max_bytes, args.timeout)
        if sha_a == sha_b:
            print("byte-identical (sha256 match) — same-version same-input "
                  "pairs differ only in timestamps/IDs; this one differs "
                  "nowhere.")
            return 0
        regions = diff_regions(a, b, args.max_regions)
    except Refusal as r:
        print(f"re_diff: {r}", file=sys.stderr)
        return 3

    print(f"A: {args.file_a} ({len(a)} bytes)")
    print(f"B: {args.file_b} ({len(b)} bytes)")
    if len(a) != len(b):
        print(f"sizes differ by {abs(len(a) - len(b))} bytes "
              f"(data-vs-header separation first, then re-run equal-size "
              f"pairs)")
    if not regions:
        print("no differing regions established "
              "(empty inputs or identical up to the scanned caps).")
        return 0
    print(f"{len(regions)} differing region(s):")
    for off_a, off_b, length in regions:
        span_a = a[off_a:off_a + min(length, 1024 * 1024)]
        span_b = b[off_b:off_b + min(length, 1024 * 1024)]
        print(f"  A@{off_a} (0x{off_a:x})  B@{off_b} (0x{off_b:x})  "
              f"len {length}  H(A)={entropy(span_a):.3f}  "
              f"H(B)={entropy(span_b):.3f}")
    print("(offsets and entropy only — no bytes echoed, protocol §7.2/§7.4)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
