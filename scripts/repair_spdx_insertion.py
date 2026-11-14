#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""One-shot repair for the add_spdx_headers.py insertion bug.

The first run inserted the header at CHARACTER offset 1 instead of after
LINE 1 whenever a file began with a shebang or a 'use client' directive,
splitting the original first line:  `#!/usr/bin/env bash` became
`## SPDX-License-Identifier: GPL-3.0-only` + `!/usr/bin/env bash`, and
`'use client'` became `'// SPDX-...` + `use client'`.

This script detects that exact signature in every file it may have
touched and restores the original first line, keeping the SPDX header on
the following line (the intended placement all along).
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CANDIDATE_GLOBS = [
    "clearfile/**/*.dart",
    "src/**/*.ts",
    "src/**/*.tsx",
    "scripts/*.py",
    "scripts/*.sh",
]
SPDX = "SPDX-License-Identifier: GPL-3.0-only"
# line1 = original-first-char + (// or #) + SPDX
SIG = re.compile(r"^([#'\"])(//|#) SPDX-License-Identifier: GPL-3.0-only\r?$")


def main() -> int:
    repaired = []
    for pattern in CANDIDATE_GLOBS:
        for path in sorted(ROOT.glob(pattern)):
            if not path.is_file():
                continue
            lines = path.read_text().splitlines(keepends=True)
            if len(lines) < 3:
                continue
            m = SIG.match(lines[0].rstrip("\r\n"))
            if not m:
                continue
            first_char, comment = m.group(1), m.group(2)
            rest_of_first = lines[1].rstrip("\r\n")
            original_first = first_char + rest_of_first
            header = f"{comment} {SPDX}\n"
            out = original_first + "\n" + header + "".join(lines[2:])
            path.write_text(out)
            repaired.append(path)
    for p in repaired:
        print(f"repaired: {p.relative_to(ROOT)}")
    print(f"{len(repaired)} file(s) repaired")
    return 0


if __name__ == "__main__":
    sys.exit(main())
