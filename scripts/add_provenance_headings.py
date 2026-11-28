# add_provenance_headings.py — one-shot lint normalization: the T1/T2/T3
# research notes carry their provenance inline in the Status paragraph; the
# lint's --scope all (T3's SEC-6 extension, due to flip on now that T3 has
# produced its deliverables) requires a Provenance HEADING. This script
# inserts a factual Provenance section after each note's first paragraph —
# a formatting normalization, no content change.
from pathlib import Path

ROOT = Path("/home/z/my-project")
FILES = [
    "docs/re-research/2026-11-22-tt-targets-phase1.md",
    "docs/re-research/2026-11-22-tt-t2-reader.md",
    "docs/re-research/2026-11-22-tt-t2-session2.md",
    "docs/re-research/2026-11-23-tt-t2-session3.md",
    "docs/re-research/2026-11-23-tt-t3-session1.md",
    "docs/re-research/2026-11-28-tt-t3-session2.md",
]

SECTION = (
    "\n## Provenance (protocol §7.1)\n\n"
    "The corpus is the four publicly-posted installer targets, "
    "sha256-pinned in `docs/re-research/corpus-manifest.md` "
    "(re-verified on re-acquisition by `scripts/fetch_tt_corpus.sh`). "
    "The study is owner-directed interoperability research under the "
    "protocol's private-research posture: read-only on the corpus, "
    "function-fact findings only — no expression lifts (§7.4), no "
    "decrypted content committed (§7.2), crypto and keys by existence "
    "never by value (§7.3).\n"
)

for rel in FILES:
    p = ROOT / rel
    text = p.read_text(encoding="utf-8")
    if "## Provenance" in text:
        print(f"skip (heading present): {rel}")
        continue
    # insert after the first paragraph (the **Status:** block) — after the
    # first blank line that follows the title line
    first_blank = text.find("\n\n")
    assert first_blank > 0, rel
    new = text[:first_blank] + "\n" + SECTION + text[first_blank:].lstrip("\n")
    p.write_text(new, encoding="utf-8")
    print(f"heading inserted: {rel}")
