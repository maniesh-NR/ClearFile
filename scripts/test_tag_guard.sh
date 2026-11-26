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
# actually runs) and exercises its branches:
#
#   1. tag exists (locally — the tag-push case, or fetched) at a different
#      commit                                    -> refuse (exit 1)
#   2. tag exists at this commit (commit SHA)    -> pass silently (exit 0)
#   3. tag absent remotely                       -> fresh tag (exit 0)
#   4. fetch fails with a non-missing-ref error  -> refuse (exit 1)
#   5. LOCAL annotated tag, GITHUB_SHA = tag OBJECT SHA, peeled match
#                                               -> pass silently (exit 0)
#      (the D29 fix, live-verified on the v1.1 push: on a tag-push event
#      the runner already holds the tag, and an annotated tag's GITHUB_SHA
#      is the tag object, not the commit)
#   6. LOCAL tag vs a different run commit       -> refuse (exit 1)
#
# Scenarios 1-3, 5-6 run against the real repo/`origin` (read-only fetches;
# existing tags are already local so the fetches are no-ops). Scenario 4
# runs in a throwaway repo whose origin is a nonexistent path. Run from the
# repo root.
# ---------------------------------------------------------------------------
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

WF=".github/workflows/release.yml"
[ -f "$WF" ] || { echo "test_tag_guard: $WF missing" >&2; exit 2; }

# --- extract the guard body verbatim (first occurrence), dedented ----------
# The body runs from `fetch_err=` to the OUTER closing `fi` (10-space indent;
# the guard's inner branches close at 12). awk handles the multi-branch body
# the D29 fix introduced (the old single-line sed range truncated at the
# first inner `rm -f`).
awk '/^          fetch_err=/{f=1} f{print substr($0, 11)} f&&/^          fi$/{exit}' "$WF" \
  > /tmp/tag_guard_body.sh
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
# CI checkouts are shallow + tagless (fetch-depth 1, fetch-tags false), so
# the scenario SHAs would resolve EMPTY there (the 2026-11-26 CI run caught
# exactly that). Fetch the three probe tags first — then CI and a full local
# clone run the identical scenarios.
# Leading '+' so a full local clone (tags already present) is a no-op
# update instead of a clobber refusal.
git fetch --no-tags -q origin \
    '+refs/tags/v1.0.0:refs/tags/v1.0.0' \
    '+refs/tags/v1.0.1:refs/tags/v1.0.1' \
    '+refs/tags/v1.1:refs/tags/v1.1' \
  || { echo "test_tag_guard: could not fetch the probe tags from origin" >&2; exit 2; }
SHA_HERE="$(git rev-parse HEAD)"            # not every tag's target
SHA_V1001="$(git rev-parse 'v1.0.1^{commit}')"
# A commit PROVABLY different from the v1.1 target, at any future tip
# (the gate found the earlier HEAD~1 choice was history-fragile: at the
# tip that landed this fix, HEAD~1 WAS the v1.1 target and the scenario
# degenerated into a passing guard).
SHA_OTHER="$(git rev-parse 'v1.0.1^{commit}')"
TAGOBJ_V11="$(git rev-parse 'v1.1')"        # the ANNOTATED tag OBJECT sha

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
rm -rf "$TMP"

# 5. D29 tag-push shape: LOCAL annotated tag whose GITHUB_SHA is the tag
#    OBJECT; peeling both sides must match the target commit -> pass.
out="$(run_guard v1.1 "$TAGOBJ_V11" "$ROOT" 2>&1)"; rc=$?
expect "annotated tag push (tag-object GITHUB_SHA) passes" 0 "$rc" "" "$out"

# 6. LOCAL tag vs a provably different run commit -> refuse (v1.1's
#    target e099bc0 is fixed history; v1.0.1's target 0bbb564 differs).
out="$(run_guard v1.1 "$SHA_OTHER" "$ROOT" 2>&1)"; rc=$?
expect "local tag vs different run commit refuses" 1 "$rc" "refusing: tag v1.1 exists" "$out"

rm -f /tmp/tag_guard_body.sh

echo "test_tag_guard: $FAILURES failure(s)"
exit $([ "$FAILURES" -eq 0 ] && echo 0 || echo 1)
