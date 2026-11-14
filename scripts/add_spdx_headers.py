#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""One-shot SPDX header application (Stage-1 item 9, debt D14).

Adds `SPDX-License-Identifier: GPL-3.0-only` as the first line of the
project's OWN source files.

Identifier choice: LICENSE is the plain GPL-3.0 full text and README says
"GPL-3.0"; no or-later grant exists anywhere in the repository, so
`GPL-3.0-only` is the accurate SPDX form.

Deliberately EXCLUDED (vendored upstream MIT-derived code, never
relabel): `src/components/ui/**` (shadcn/ui) and `src/hooks/**`
(shadcn add-ons). Exclusion is a licensing decision, not an oversight.

Idempotent: a file already carrying an SPDX-License-Identifier line is
skipped, so re-running is safe. Insertion respects shebangs and the
`'use client'` directive (which must remain a file's first statement).
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
INCLUDE_GLOBS = [
    "clearfile/lib/**/*.dart",
    "clearfile/test/**/*.dart",
    "src/lib/**/*.ts",
    "src/app/**/*.ts",
    "src/app/**/*.tsx",
    "src/components/clearfile/**/*.tsx",
    "scripts/*.py",
    "scripts/*.sh",
]
SPDX = "SPDX-License-Identifier: GPL-3.0-only"


def comment_prefix(suffix: str) -> str:
    if suffix in (".dart", ".ts", ".tsx"):
        return "// "
    if suffix in (".py", ".sh"):
        return "# "
    raise AssertionError(f"unhandled suffix {suffix}")


def insertion_offset_lines(text: str) -> int:
    """Line count to skip before inserting: shebang and 'use client'."""
    lines = text.splitlines(keepends=True)
    i = 0
    if lines and lines[0].startswith("#!"):
        i = 1
    if i < len(lines) and lines[i].startswith(("'use client'", '"use client"')):
        i += 1
    return i


def main() -> int:
    changed, skipped = [], []
    for pattern in INCLUDE_GLOBS:
        for path in sorted(ROOT.glob(pattern)):
            if path.is_dir():
                continue
            text = path.read_text()
            # Only an actual header line counts (a docstring can MENTION
            # the identifier; that must not cause a self-skip).
            if any(re.match(r"^(//|#) SPDX-License-Identifier", line)
                   for line in text.splitlines()[:4]):
                skipped.append(path)
                continue
            i = insertion_offset_lines(text)
            lines = text.splitlines(keepends=True)
            header = comment_prefix(path.suffix) + SPDX + "\n"
            text = "".join(lines[:i]) + header + "".join(lines[i:])
            path.write_text(text)
            changed.append(path)
    for p in changed:
        print(f"spdx: + {p.relative_to(ROOT)}")
    print(f"spdx: {len(changed)} file(s) headered, {len(skipped)} already had one")
    return 0


if __name__ == "__main__":
    sys.exit(main())
