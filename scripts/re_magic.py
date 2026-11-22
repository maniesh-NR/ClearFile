#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""re_magic.py — ClearFile Stage-2 RE tooling (protocol Phase 1: passive
identification, magic-byte scan).

SECURITY CONTRACT (Stage-2 entry gate 2026-11-17, binding — D38 registered):
- WRITE-FREE: opens the input read-only; no writes anywhere, no shell-outs,
  no network. Pinned by the read-only-fixture-dir unit test.
- RESOURCE-BOUNDED: up-front size refusal (--max-bytes scan window,
  default 32 MiB), a hit-count cap (--max-hits, default 500 — a container
  carved of many small members can otherwise flood), and a per-file
  wall-clock timeout (--timeout). Every cap refuses cleanly: a message plus
  exit code 3, never a crash.
- CRASH-SAFE: empty and truncated inputs are REPORTED, never thrown; a
  truncated magic at EOF simply does not match.

Output: one line per hit — decimal/hex offset, family, matched magic bytes
as short hex (a few identifier bytes each, protocol §7.4-safe). Text/JSON/
XML/UTF-16 sniffing covers the "plain data" verdicts of protocol Phase 1.

Exit codes: 0 ran · 2 usage error · 3 REFUSAL (a cap tripped or unreadable).
"""
from __future__ import annotations

import argparse
import os
import signal
import sys

DEFAULT_MAX_BYTES = 32 * 1024 * 1024
DEFAULT_MAX_HITS = 500
DEFAULT_TIMEOUT = 30.0

# (family, magic bytes, note, at_zero). Container/file magics are scanned at
# ANY offset (an archive can sit inside a wrapper — the TT corpus's SFX
# layout is the standing example); short/ambiguous magics ('MZ' is two
# bytes and floods random data) are checked at offset 0 only.
FAMILIES: list[tuple[str, bytes, str, bool]] = [
    ("zip", b"PK\x03\x04", "ZIP local file header", False),
    ("zip(eocd)", b"PK\x05\x06", "ZIP end-of-central-directory", False),
    ("cab", b"MSCF", "Microsoft cabinet", False),
    ("rar", b"Rar!\x1a\x07", "Roshal archive", False),
    ("7z", b"7z\xbc\xaf\x27\x1c", "7-Zip", False),
    ("ole2-cfb", b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1", "OLE2 compound file", False),
    ("sqlite", b"SQLite format 3\x00", "SQLite database", False),
    ("elf", b"\x7fELF", "ELF executable", False),
    ("gzip", b"\x1f\x8b", "gzip stream", False),
    ("bzip2", b"BZh", "bzip2 stream", False),
    ("xz", b"\xfd7zXZ\x00", "xz stream", False),
    ("zstd", b"\x28\xb5\x2f\xfd", "Zstandard frame", False),
    ("pdf", b"%PDF", "PDF document", False),
    ("mz", b"MZ", "DOS/PE image header", True),
]


class Refusal(Exception):
    pass


def load(path: str, max_bytes: int, timeout: float) -> tuple[bytes, int]:
    try:
        size = os.path.getsize(path)
    except OSError as e:
        raise Refusal(f"could not stat input: {e}") from e
    if size == 0:
        return b"", 0
    if size > max_bytes:
        raise Refusal(
            f"refusing: input is {size} bytes, over the scan-window cap "
            f"({max_bytes}; --max-bytes). Phase-1 scans stay bounded.")
    if hasattr(signal, "setitimer"):

        def _timeout(_sig, _frm):
            raise Refusal(
                f"refusing: scan exceeded the {timeout}s wall-clock cap "
                f"(--timeout); a bounded tool does not grind on.")

        signal.signal(signal.SIGALRM, _timeout)
        signal.setitimer(signal.ITIMER_REAL, timeout)
    try:
        with open(path, "rb") as f:
            data = f.read(min(size, max_bytes))
    except OSError as e:
        raise Refusal(f"could not read input: {e}") from e
    finally:
        if hasattr(signal, "setitimer"):
            signal.setitimer(signal.ITIMER_REAL, 0)
    return data, size


def text_verdict(head: bytes) -> str | None:
    """Sniff plain-text families on the first bytes (Phase 1)."""
    if not head:
        return None
    if head.startswith(b"\xef\xbb\xbf"):
        return "text (UTF-8 BOM)"
    if head.startswith(b"\xff\xfe") or head.startswith(b"\xfe\xff"):
        return "text (UTF-16 BOM)"
    sample = head[:4096]
    if b"\x00" in sample:
        return None  # NUL-bearing stays binary at this layer
    try:
        text = sample.decode("utf-8")
    except UnicodeDecodeError:
        try:
            text = sample.decode("latin-1")
        except UnicodeDecodeError:
            return None
    stripped = text.lstrip()
    if not stripped:
        return "text (whitespace only)"
    if stripped[:1] in "{[":
        return "text (JSON-like)"
    if stripped[:5].lower() == "<?xml" or stripped[:1] == "<":
        return "text (XML/HTML-like)"
    printable = sum(1 for ch in text if ch.isprintable() or ch in "\n\r\t")
    if printable >= 0.9 * len(text):
        return "text (plain)"
    return None


def scan(data: bytes, max_hits: int) -> list[str]:
    hits = 0
    lines: list[str] = []
    for family, magic, note, at_zero in FAMILIES:
        start = 0
        if at_zero:
            if data.startswith(magic):
                hits += 1
                lines.append(f"hit @ {0:>10} (0x0)  {family:<10} "
                             f"{magic.hex():<20} {note}")
            continue
        while True:
            at = data.find(magic, start)
            if at < 0:
                break
            hits += 1
            if hits > max_hits:
                raise Refusal(
                    f"refusing: more than {max_hits} magic hits "
                    f"(--max-hits). Narrow the scan window instead of "
                    f"flooding the report.")
            lines.append(f"hit @ {at:>10} (0x{at:x})  {family:<10} "
                         f"{magic.hex():<20} {note}")
            start = at + len(magic)
    return lines


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(
        prog="re_magic.py",
        description="Phase-1 magic-byte scan (any offset) + text sniff. "
                    "Read-only, size/hits/timeout caps with clean refusals "
                    "(exit 3).")
    p.add_argument("file", help="input file to scan (opened read-only)")
    p.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES,
                   help="up-front size cap for the scan window "
                        f"(default {DEFAULT_MAX_BYTES})")
    p.add_argument("--max-hits", type=int, default=DEFAULT_MAX_HITS,
                   help=f"hit-count cap (default {DEFAULT_MAX_HITS})")
    p.add_argument("--timeout", type=float, default=DEFAULT_TIMEOUT,
                   help="per-file wall-clock cap in seconds "
                        f"(default {DEFAULT_TIMEOUT})")
    args = p.parse_args(argv)

    if not os.path.exists(args.file):
        print(f"re_magic: no such file: {args.file}", file=sys.stderr)
        return 2
    try:
        data, size = load(args.file, args.max_bytes, args.timeout)
        lines = scan(data, args.max_hits)
    except Refusal as r:
        print(f"re_magic: {r}", file=sys.stderr)
        return 3

    if size == 0:
        print("empty file — nothing to scan (reported, not an error).")
        return 0
    print(f"size {size} bytes; scan window {len(data)} bytes")
    verdict = text_verdict(data[:4096])
    if verdict and not lines:
        print(f"sniff: {verdict}")
    if lines:
        print(f"{len(lines)} magic hit(s):")
        for line in lines:
            print(line)
    if not lines and not verdict:
        print("no known magic and no text verdict at this layer "
              "(unknown format — Phase 2 next).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
