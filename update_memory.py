#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""update_memory.py — refresh PROJECT_MEMORY.md's rolling git-activity window.

pstack-style persistent-memory helper (owner directive 2026-11-22,
ADR-018; adapted from the uploaded pstack template, see
harness/memory/DECISIONS.md). Run from the repo root at session
bootstrap, or wire as a pre-commit/post-commit hook:

    python3 update_memory.py

Documented deltas from the uploaded template — both forced by this
repo's mega-commit backup granularity (one backup commit per session,
whole-feature diffs) and the protocol's own zero-noise rule; measured
2026-11-22: full -p window = 245 KB vs stat window = 19 KB:

  * PATCH_MODE = "stat" by default — commit metadata + per-file stat
    summaries. Set PATCH_MODE = "patch" to restore the upstream full
    -p behaviour (owner-overrule path, recorded in ADR-018).
  * Noise excludes apply in either mode: package-lock.json / *.lock
    (machine churn — the 2026-11-17 audit refresh alone is ~15k diff
    lines), harness/adversarial/reports/ (near-verbatim reviewer
    reports, already archived in-repo), fixtures/tax/ (golden JSON
    data, already pinned by the CI suites).

The section-replacement logic and NUM_COMMITS are the upstream
behaviour verbatim.
"""
import subprocess
from pathlib import Path

MEMORY_FILE = Path("PROJECT_MEMORY.md")
NUM_COMMITS = 3  # Number of recent commits to pull diffs for
PATCH_MODE = "stat"  # "stat" (default, zero-noise) or "patch" (full -p)
NOISE_EXCLUDES = [
    ":(exclude)package-lock.json",
    ":(exclude)*.lock",
    ":(exclude)harness/adversarial/reports/",
    ":(exclude)fixtures/tax/",
]


def get_recent_git_diffs():
    """Fetches recent commit metadata and diff patches using git log."""
    try:
        # Run git log with patch output for the last N commits
        result = subprocess.run(
            [
                "git", "log",
                f"-n{NUM_COMMITS}",
                "--pretty=format:### Commit: %h - %s (%an, %ad)",
                "--date=short",
                "--stat" if PATCH_MODE == "stat" else "-p",
                "--",
                ".",
                *NOISE_EXCLUDES,
            ],
            capture_output=True,
            text=True,
            check=True,
            encoding="utf-8"
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"[!] Error running git command: {e}")
        return ""
    except FileNotFoundError:
        print("[!] Git is not installed or not found in system PATH.")
        return ""


def update_project_memory():
    diffs = get_recent_git_diffs()
    if not diffs:
        print("[!] No git history or changes found to update.")
        return

    section_header = "## Recent Progress & Git Activity"
    new_section = f"{section_header}\n\n```diff\n{diffs}\n```\n\n"

    # Read existing memory file if it exists
    if MEMORY_FILE.exists():
        content = MEMORY_FILE.read_text(encoding="utf-8")

        # If the recent activity section already exists, replace it
        if section_header in content:
            parts = content.split(section_header)
            # Find the end of this section (assume next '##' header or end of file)
            remainder = parts[1]
            next_header_idx = remainder.find("\n## ")
            if next_header_idx != -1:
                remaining_content = remainder[next_header_idx:]
            else:
                remaining_content = ""

            updated_content = parts[0].rstrip() + "\n\n" + new_section + remaining_content.lstrip()
        else:
            # Prepend right below the main title
            updated_content = content + "\n\n" + new_section
    else:
        # Initialize a new memory file if none exists
        updated_content = f"# Project Memory & State\n\n{new_section}"

    MEMORY_FILE.write_text(updated_content, encoding="utf-8")
    print(f"[✓] Successfully updated {MEMORY_FILE} with the last {NUM_COMMITS} commit diffs.")


if __name__ == "__main__":
    update_project_memory()
