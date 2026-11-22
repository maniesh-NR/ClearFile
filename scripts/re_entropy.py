#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""re_entropy.py — ClearFile Stage-2 RE tooling (protocol Phase 1: passive
identification, per-block Shannon entropy).

SECURITY CONTRACT (Stage-2 entry gate 2026-11-17, binding — D38 registered):
- WRITE-FREE: opens the input read-only; no writes anywhere, no shell-outs,
  no network. Pinned by the read-only-fixture-dir unit test.
- RESOURCE-BOUNDED: up-front size refusal (--max-bytes, default 64 MiB),
  a block-count cap (--max-blocks, default 16384), and a per-file
  wall-clock timeout (--timeout seconds, signal-based). Every cap refuses
  cleanly — a refusal message plus exit code 3, never a crash.
- CRASH-SAFE: empty, truncated, and unreadable inputs are REPORTED
  ("could not ..."), never thrown. Malformed input cannot crash this tool
  because no structured header is ever trusted; the ENG-1 battery runs
  zero-byte and one-byte files through it.

Output is a text report (offset, entropy, flag per block + a summary with
high-entropy run boundaries). Nothing but aggregate statistics is printed —
no input bytes are echoed (protocol §7.2/§7.4 posture).

Exit codes: 0 ran (including clean "nothing to scan" reports) · 2 usage
error · 3 REFUSAL (a cap tripped or the file could not be read).
"""
from __future__ import annotations

import argparse
import math
import os
import signal
import sys

DEFAULT_MAX_BYTES = 64 * 1024 * 1024
DEFAULT_BLOCK = 4096
DEFAULT_MAX_BLOCKS = 16384
DEFAULT_TIMEOUT = 30.0
HIGH = 7.5   # bits/byte — compressed or encrypted region candidate
ELEVATED = 6.0


class Refusal(Exception):
    """A cap tripped or the input could not be established."""


def shannon(counts: list[int], total: int) -> float:
    if total == 0:
        return 0.0
    ent = 0.0
    for c in counts:
        if c:
            p = c / total
            ent -= p * math.log2(p)
    return ent


def scan(path: str, block: int, max_bytes: int, max_blocks: int,
         timeout: float) -> tuple[list[tuple[int, float]], int]:
    """Read-only scan. Raises Refusal on any cap trip or I/O failure."""
    try:
        size = os.path.getsize(path)
    except OSError as e:
        raise Refusal(f"could not stat input: {e}") from e
    if size == 0:
        return [], 0
    if size > max_bytes:
        raise Refusal(
            f"refusing: input is {size} bytes, over the size cap "
            f"({max_bytes}; --max-bytes). Phase-1 scans stay bounded.")
    blocks = (min(size, max_bytes) + block - 1) // block
    if blocks > max_blocks:
        raise Refusal(
            f"refusing: scan needs {blocks} blocks, over the block cap "
            f"({max_blocks}; --max-blocks or a larger --block).")

    # Per-file wall-clock guard (POSIX signals; Linux/macOS only, same as
    # the sandbox and CI runners).
    if hasattr(signal, "setitimer"):

        def _timeout(_sig, _frm):
            raise Refusal(
                f"refusing: scan exceeded the {timeout}s wall-clock cap "
                f"(--timeout); a bounded tool does not grind on.")

        signal.signal(signal.SIGALRM, _timeout)
        signal.setitimer(signal.ITIMER_REAL, timeout)

    out: list[tuple[int, float]] = []
    try:
        with open(path, "rb") as f:
            for i in range(blocks):
                chunk = f.read(block)
                if not chunk:
                    break
                counts = [0] * 256
                for b in chunk:
                    counts[b] += 1
                out.append((i * block, shannon(counts, len(chunk))))
    except OSError as e:
        raise Refusal(f"could not read input: {e}") from e
    finally:
        if hasattr(signal, "setitimer"):
            signal.setitimer(signal.ITIMER_REAL, 0)
    return out, size


def report(rows: list[tuple[int, float]], size: int) -> str:
    lines: list[str] = []
    if not rows:
        lines.append("empty file — nothing to scan (reported, not an error).")
        return "\n".join(lines)
    lines.append(f"size {size} bytes; {len(rows)} blocks")
    for off, ent in rows:
        flag = ""
        if ent >= HIGH:
            flag = "high (compressed/encrypted region candidate)"
        elif ent >= ELEVATED:
            flag = "elevated"
        lines.append(f"  block @ {off:>12}  H = {ent:6.4f} bits/byte  {flag}")
    # recompute high runs compactly (bounded output: run list, not per-block)
    high_runs: list[tuple[int, int]] = []
    for off, ent in rows:
        if ent >= HIGH:
            if high_runs and high_runs[-1][1] == off:
                high_runs[-1] = (high_runs[-1][0], off + 1)
            else:
                high_runs.append((off, off + 1))
    mean = sum(e for _, e in rows) / len(rows)
    lines.append(f"mean entropy {mean:.4f} bits/byte")
    if high_runs:
        lines.append(
            f"{len(high_runs)} high-entropy block run(s) "
            f"(>= {HIGH} bits/byte):")
        for start, end in high_runs[:50]:
            lines.append(f"  {start} .. {end} blocks")
        if len(high_runs) > 50:
            lines.append(f"  ... {len(high_runs) - 50} more (report cap)")
    else:
        lines.append("no high-entropy blocks (nothing compressed/encrypted "
                     "at this block size)")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(
        prog="re_entropy.py",
        description="Phase-1 per-block Shannon entropy scan. Read-only, "
                    "size/block/timeout caps with clean refusals (exit 3).")
    p.add_argument("file", help="input file to scan (opened read-only)")
    p.add_argument("--block", type=int, default=DEFAULT_BLOCK,
                   help=f"block size in bytes (default {DEFAULT_BLOCK})")
    p.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES,
                   help="up-front size cap; larger inputs are refused "
                        f"(default {DEFAULT_MAX_BYTES})")
    p.add_argument("--max-blocks", type=int, default=DEFAULT_MAX_BLOCKS,
                   help=f"block-count cap (default {DEFAULT_MAX_BLOCKS})")
    p.add_argument("--timeout", type=float, default=DEFAULT_TIMEOUT,
                   help="per-file wall-clock cap in seconds "
                        f"(default {DEFAULT_TIMEOUT})")
    args = p.parse_args(argv)

    if args.block < 256 or args.block > 65536:
        print("re_entropy: --block must be within [256, 65536]", file=sys.stderr)
        return 2
    if not os.path.exists(args.file):
        print(f"re_entropy: no such file: {args.file}", file=sys.stderr)
        return 2
    try:
        rows, size = scan(args.file, args.block, args.max_bytes,
                          args.max_blocks, args.timeout)
    except Refusal as r:
        print(f"re_entropy: {r}", file=sys.stderr)
        return 3
    print(report(rows, size))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
