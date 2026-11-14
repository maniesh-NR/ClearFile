#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# ---------------------------------------------------------------------------
# test_tag_guard.sh — functional test of the release.yml tag guard (ENG-1).
#
# Stage-2 entry gate (2026-11-14): ADV-ENG finding ENG-1 — the tag-SHA guard
# was fail-open on fetch failure. The guard in release.yml was rewritten to
# fail closed on every fetch error except the "couldn't find remote ref"
# case (the only legitimate fresh-tag signal). This script extracts the
# guard body VERBATIM from release.yml (so it can never drift from what CI
# actually runs) and exercises all four branches:
#
#   1. tag exists remotely at a different commit   -> refuse (exit 1)
#   2. tag exists remotely at this commit          -> pass silently (exit 0)
#   3. tag absent remotely                         -> fresh tag (exit 0)
#   4. fetch fails with a non-missing-ref error    -> refuse (exit 1)
#
# Scenarios 1-3 run against the real `origin` (read-only fetches; existing
# tags are already local so the fetches are no-ops). Scenario 4 runs in a
# throwaway repo whose origin is a nonexistent path. Run from the repo root.
# ---------------------------------------------------------------------------
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

WF=".github/workflows/release.yml"
[ -f "$WF" ] || { echo "test_tag_guard: $WF missing" >&2; exit 2; }

# --- extract the guard body verbatim (first occurrence), dedented ----------
sed -n '/^          fetch_err="\$(mktemp)"/,/^          rm -f "\$fetch_err"$/p' "$WF" \
  | sed 's/^          //' > /tmp/tag_guard_body.sh
[ -s /tmp/tag_guard_body.sh ] || { echo "test_tag_guard: guard body not found in $WF" >&2; exit 2; }
bash -n /tmp/tag_guard_body.sh || { echo "test_tag_guard: extracted body fails bash -n" >&2; exit 2; }

run_guard() { # $1=tag $2=github_sha $3=cwd
  ( cd "$3" && RELEASE_TAG="$1" GITHUB_SHA="$2" bash /tmp/tag_guard_body.sh )
}

FAILURES=0
expect() { # $1=desc $2=want_rc $3=got_rc $4=want_grep $5=output
  local got_rc="$3" output="$5" want_rc="$2" want_grep="$4" desc="$1"
  if [ "$got_rc" -ne "$want_rc" ]; then
    echo "test_tag_guard: FAIL — $desc: rc=$got_rc, want $want_rc" >&2
    FAILURES=$((FAILURES + 1)); return
  fi
  if [ -n "$want_grep" ] && ! printf '%s' "$output" | grep -qi "$want_grep"; then
    echo "test_tag_guard: FAIL — $desc: output missing '$want_grep'" >&2
    FAILURES=$((FAILURES + 1)); return
  fi
  echo "test_tag_guard: ok — $desc"
}

# --- scenario data ----------------------------------------------------------
SHA_HERE="$(git rev-parse HEAD)"            # 7b16e12-ish: NOT a tag target
SHA_V1001="$(git rev-parse 'v1.0.1^{commit}')"

# 1. existing tag at a different commit -> refuse
out="$(run_guard v1.0.0 "$SHA_HERE" "$ROOT" 2>&1)"; rc=$?
expect "existing tag elsewhere is refused" 1 "$rc" "refusing: tag v1.0.0 exists" "$out"

# 2. existing tag at exactly this commit -> pass silently
out="$(run_guard v1.0.1 "$SHA_V1001" "$ROOT" 2>&1)"; rc=$?
expect "existing tag at this SHA passes" 0 "$rc" "" "$out"

# 3. tag absent remotely -> fresh tag
out="$(run_guard v0.0.0-guard-probe "$SHA_HERE" "$ROOT" 2>&1)"; rc=$?
expect "absent tag treated as fresh" 0 "$rc" "not present remotely" "$out"

# 4. fetch fails with a non-missing-ref error -> refuse (fail-closed)
TMP="$(mktemp -d)"
git -C "$TMP" init -q .
git -C "$TMP" remote add origin "$TMP/nonexistent.git"
out="$(run_guard v1.0.0 "$SHA_HERE" "$TMP" 2>&1)"; rc=$?
expect "non-missing-ref fetch error refuses (fail-closed)" 1 "$rc" "refusing to build" "$out"
rm -rf "$TMP" /tmp/tag_guard_body.sh

echo "test_tag_guard: $FAILURES failure(s)"
exit $([ "$FAILURES" -eq 0 ] && echo 0 || echo 1)
