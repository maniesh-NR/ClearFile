#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# ---------------------------------------------------------------------------
# ClearFile sandbox backup — event-driven, NEVER scheduled (no cron).
# Per harness/WORKFLOW.md §1 this runs as the LAST step of every execution
# plan: every reply to the owner ends with a backup run, not a timer.
#
# Usage: scripts/sandbox_backup.sh "short note of what this run changed"
# Exit codes: 0 ok/no-op · 1 setup/branch/push failure (tell the owner!) ·
#             2 secret guard tripped (never commit the flagged content)
#
# Stage-0 gate hardening (2026-11-14, conditions from ADV-SEC #3/#10/#11 and
# ADV-ENG #2): branch guard, unpushed-commit check on the no-op path, PAT
# sanitization of git error output, 0600 temp file with trap, widened secret
# patterns + hex-blob heuristic.
# ---------------------------------------------------------------------------
set -euo pipefail

ROOT="/home/z/my-project"
NOTE="${1:-sandbox state}"
cd "$ROOT"

# --- preflight -------------------------------------------------------------
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "backup: $ROOT is not a git work tree" >&2
  exit 1
fi
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "backup: 'origin' remote missing (sandbox recycled?)." >&2
  echo "  Recover per harness/WORKFLOW.md §4 before backing up." >&2
  exit 1
fi
if [ -z "$(git config user.email || true)" ]; then
  git config user.email "z@container"
  git config user.name "z"
fi

# Branch guard: the backup pushes 'main'. Running anywhere else would push a
# stale ref and silently skip this session's commits (ADV-SEC finding 3).
BRANCH="$(git branch --show-current)"
if [ "$BRANCH" != "main" ]; then
  echo "backup: refusing — current branch is '$BRANCH', not 'main'." >&2
  echo "  The backup rule archives main; commit or switch first." >&2
  exit 1
fi

# The no-op path must still verify nothing is unpushed (ADV-SEC Stage-0
# finding 3, scenario A) — and the fetch itself must never echo
# credential-bearing URLs (ADV-SEC Stage-1 finding 2): stderr goes through
# the same 0600 temp + sanitizer path as the push.
check_unpushed() {
  local ferr
  ferr="$(mktemp)"
  chmod 600 "$ferr"
  if ! git fetch -q origin 2>"$ferr"; then
    echo "backup: 'git fetch origin' failed (sanitized):" >&2
    sed -E 's#(x-access-token:)[^@]+@#\1***@#g; s#//[^@/]+@github.com#//***@github.com#g' \
      "$ferr" | tail -3 >&2
    rm -f "$ferr"
    echo "  Treat local state as NOT backed up until the network recovers." >&2
    exit 1
  fi
  rm -f "$ferr"
  if [ -n "$(git log origin/main..main)" ]; then
    echo "backup: local main is ahead of origin/main — unpushed commits exist." >&2
    git log --oneline origin/main..main >&2
    echo "  Push failed previously? Reconcile before treating state as backed up." >&2
    exit 1
  fi
}

# --- stage everything allowed by .gitignore --------------------------------
git add -A

if git diff --cached --quiet; then
  check_unpushed
  echo "backup: nothing to archive (tree clean)"
  exit 0
fi

# --- secret guard: refuse to commit token-shaped strings -------------------
# TOKEN patterns scan ALL files, binaries included (no -I; ADV-SEC Stage-1
# finding 3 — a pasted github_pat_/ghp_/sk-… inside a PDF/PNG must refuse
# the commit; genuine token strings are distinctive enough that binary
# data never false-positives them). The raw-hex heuristic stays TEXT-ONLY
# (-I): bitmap/icon pixel data naturally contains long runs of ASCII-hex
# bytes (verified: clearfile/windows/runner/resources/app_icon.ico trips
# [0-9a-fA-F]{64} six times on plain pixel bytes) — a false positive class,
# not a leak. Lockfiles legitimately contain 64-hex sha256 checksums and
# are excluded from the hex check regardless.
TOKEN_PATTERNS='github_pat_[A-Za-z0-9_]{10,}|gh[pousr]_[A-Za-z0-9]{30,}|sk-[A-Za-z0-9]{28,}|sk-(ant|proj)-[A-Za-z0-9-]{20,}|AIza[A-Za-z0-9_-]{30,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|npm_[A-Za-z0-9]{30,}|glpat-[A-Za-z0-9-]{20,}|BEGIN [A-Z ]*PRIVATE KEY'
HEX_PATTERNS='[0-9a-fA-F]{64}'
HITS="$(
  { git grep --cached -l -E "$TOKEN_PATTERNS" -- . || true
    git grep --cached -I -l -E "$HEX_PATTERNS" -- . ':(exclude)*.lock' \
      ':(exclude)package-lock.json' ':(exclude)bun.lock' ':(exclude)pnpm-lock.yaml' || true
  } | sort -u
)"
if [ -n "$HITS" ]; then
  echo "backup: REFUSING — token-shaped or hex-blob content staged in:" >&2
  echo "$HITS" >&2
  echo "  Remove the secret, then re-run. Never commit credentials." >&2
  exit 2
fi

# --- commit ------------------------------------------------------------------
STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
if ! git commit -q -m "backup(sandbox): ${NOTE} @ ${STAMP}"; then
  echo "backup: commit failed" >&2
  exit 1
fi

# --- push (fast-forward only; a rejection is never silent) -------------------
# Error output goes to a 0600 temp file and is sanitized before printing:
# git auth errors embed the remote URL, which contains the owner's PAT
# (ADV-ENG finding 2, ADV-SEC finding 11).
ERRFILE="$(mktemp)"
trap 'rm -f "$ERRFILE"' EXIT
chmod 600 "$ERRFILE"
if ! git push origin main 2>"$ERRFILE"; then
  echo "backup: PUSH FAILED (sanitized output):" >&2
  sed -E 's#(x-access-token:)[^@]+@#\1***@#g; s#//[^@/]+@github.com#//***@github.com#g' \
    "$ERRFILE" | tail -5 >&2
  echo "  If remote diverged (web edits?), inspect 'git log origin/main..main'" >&2
  echo "  and reconcile manually. Do not blind force-push." >&2
  exit 1
fi

echo "backup: pushed $(git rev-parse --short HEAD) @ ${STAMP}"
