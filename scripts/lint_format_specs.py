#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""lint_format_specs.py — ClearFile Stage-2 RE tooling guard (LEGAL-1
mechanic, Stage-2 entry gate 2026-11-17).

Lints the format-specification docs:
- every docs/formats/*.md carries a PROVENANCE section (ADR-012 mechanic
  (d): "every docs/formats/*.md passes the §7.5 per-spec checklist with a
  provenance field" — this is the mechanical half of that checklist);
- no contiguous hex run of 32+ characters anywhere (the 16-byte-key-as-hex
  shape; crypto constants by existence, never by value — protocol §7.3);
- no markdown image embeds (no ![...](...) — expression lifts are
  prohibited, protocol §7.4, and the TT gate's PROD-1 extension covers
  runtime screenshots too);
- no leftover placeholders (TODO / XXX / 【…】).

Scope: docs/formats/ by default; `--scope all` extends to docs/re-research/
(the extension flipped ON at the Stage-2 exit close, 2026-11-28 — T3's
deliverables exist; CI's hygiene RE-tools job runs the wide scope) with
the recorded known-hash exemption set: the TT corpus provenance manifest
(sha256 checksums of publicly-posted installers, ADR-019) and the
bench-evidence record (the digests pinning the gitignored analysis
scripts, the ENG-2 Stage-2-exit condition). Everything else stays hex-free.

Posture: read-only. Exit 0 clean · 1 violations listed · 2 usage error.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HEX_RUN = re.compile(r"[0-9a-fA-F]{32,}")
IMAGE_EMBED = re.compile(r"!\[[^\]]*\]\(")
PLACEHOLDERS = re.compile(r"TODO|XXX|【[^】]*】")
PROVENANCE_SECTION = re.compile(r"^#+ .*provenance", re.IGNORECASE | re.MULTILINE)

# The known-hash exemption class (ADR-019's allow-list instance): files
# that legitimately carry sha256 provenance digests of PUBLICLY-POSTED,
# sha256-verified material — the TT corpus manifest, and (the Stage-2
# exit close, 2026-11-28, ENG-2's condition) the bench-evidence record
# whose digests pin the gitignored analysis scripts so a post-recycle
# session can diff-verify the falsification evidence instead of
# re-arguing it. Everything else stays hex-free (§7.3).
KNOWN_HASH_EXEMPT = {
    "docs/re-research/corpus-manifest.md",
    "docs/re-research/bench-evidence-2026-11-28.md",
}


def lint(path: Path) -> list[str]:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        return [f"unreadable: {e}"]
    problems: list[str] = []
    if not PROVENANCE_SECTION.search(text):
        problems.append("missing a Provenance section (ADR-012 (d) / §7.1)")
    for match in HEX_RUN.finditer(text):
        span = match.group(0)
        problems.append(
            f"hex run >= 32 chars ({len(span)} at byte {match.start()}) — "
            f"crypto constants by existence, never by value (§7.3)")
    if IMAGE_EMBED.search(text):
        problems.append("markdown image embed present — expression lifts "
                        "prohibited (§7.4)")
    for match in PLACEHOLDERS.finditer(text):
        problems.append(f"placeholder text {match.group(0)!r}")
    return problems


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(
        prog="lint_format_specs.py",
        description="Provenance + guardrail lint for docs/formats specs "
                    "(and, with --scope all, re-research notes).")
    p.add_argument("--scope", choices=["formats", "all"], default="formats",
                   help="'formats' = docs/formats/*.md (default); 'all' "
                        "extends to docs/re-research/*.md with the "
                        "corpus-manifest known-hash exemption (SEC-6, T3)")
    args = p.parse_args(argv)

    targets = sorted((ROOT / "docs" / "formats").glob("*.md"))
    if args.scope == "all":
        targets += [t for t in sorted((ROOT / "docs" / "re-research")
                                       .glob("*.md"))]
    if not targets:
        print("lint_format_specs: no docs/formats/*.md found yet — the first "
              "spec (docs/formats/clearfile-json.md) is the Stage-2 "
              "session-1 deliverable.")
        return 1

    failures = 0
    for path in targets:
        rel = path.relative_to(ROOT).as_posix()
        problems = lint(path)
        if rel in KNOWN_HASH_EXEMPT and args.scope == "all":
            # The recorded known-hash instance (ADR-019): its sha256
            # checksums are the one legitimate ≥32-hex content; every other
            # rule still applies.
            problems = [x for x in problems if "hex run" not in x]
            if not problems:
                continue
        if problems:
            failures += 1
            print(f"lint_format_specs: {rel}", file=sys.stderr)
            for problem in problems:
                print(f"    - {problem}", file=sys.stderr)
        else:
            print(f"ok   {rel}")
    if failures:
        print(f"lint_format_specs: {failures} file(s) with violations",
              file=sys.stderr)
        return 1
    print(f"lint_format_specs: {len(targets)} file(s) clean")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
