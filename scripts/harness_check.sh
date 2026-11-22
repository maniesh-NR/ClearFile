#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# ---------------------------------------------------------------------------
# harness_check.sh — harness self-enforcement (D19, ROADMAP Stage-1 item 9).
#
# Mechanical checks against memory drift, the class of failure every gate
# has re-discovered by hand so far (four different test counts in one
# session, a ROADMAP gate status that pre-dated the gate's outcome, a
# STATE.md snapshot older than the last session-log entry, 100644→100755
# mode flips from snapshot restores, an appended session log that was
# never backed up).
#
# Read-only: changes nothing. Exit 0 = all checks pass; exit 1 = failures
# listed. Runs locally (dogfooded at teardown) and in CI (hygiene.yml).
# ---------------------------------------------------------------------------
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ROADMAP="harness/memory/ROADMAP.md"
CONSENSUS="harness/adversarial/CONSENSUS.md"
STATE="harness/memory/STATE.md"
LOG="harness/memory/SESSION_LOG.md"
WORKFLOW="harness/WORKFLOW.md"

FAILURES=0
fail() { echo "harness_check: FAIL — $*" >&2; FAILURES=$((FAILURES + 1)); }
pass() { echo "harness_check: ok — $1"; }

# --- 1. Gate-status consistency: ROADMAP ↔ CONSENSUS ----------------------
# Every stage the ROADMAP declares past its gate must have a matching
# outcome recorded in CONSENSUS, and no stage may silently flip status.
if grep -q 'gate PASSED' "$ROADMAP" && grep -q '\*\*Stage 0: PASSED\*\*' "$CONSENSUS"; then
  pass "Stage 0: ROADMAP and CONSENSUS agree (PASSED)"
else
  fail "Stage 0 gate status drift between ROADMAP and CONSENSUS"
fi

# Stage-2 entry gate (2026-11-14): Stage 1 was executed and formally closed
# at that gate; Stage 3 was entered there under the re-sequencing (Stage 2,
# RE tooling, deferred until after Stage 3). Patterns updated accordingly —
# a legitimate stage advance is a checker update, not a drift.
if grep -q 'Stage 1 CLOSED' "$ROADMAP" && grep -q '\*\*Stage 1: CLOSED\*\*' "$CONSENSUS"; then
  pass "Stage 1: ROADMAP and CONSENSUS agree (CLOSED)"
else
  fail "Stage 1 gate status drift between ROADMAP and CONSENSUS"
fi

# Stage-3 closure + Stage-2 entry (2026-11-17 full-depth gate): Stage 3
# was executed and formally closed at the gate; Stage 2 (RE tooling) was
# entered there. Patterns updated accordingly — a legitimate stage
# advance is a checker update, not a drift.
if grep -q 'Stage 3 CLOSED' "$ROADMAP" && grep -q '\*\*Stage 3: CLOSED\*\*' "$CONSENSUS"; then
  pass "Stage 3: ROADMAP and CONSENSUS agree (CLOSED 2026-11-17)"
else
  fail "Stage 3 gate status drift between ROADMAP and CONSENSUS (closure not recorded?)"
fi

if grep -q 'Stage 2: ENTERED' "$ROADMAP" && grep -q '\*\*Stage 2: ENTERED\*\*' "$CONSENSUS"; then
  pass "Stage 2: ROADMAP and CONSENSUS agree (ENTERED 2026-11-17)"
else
  fail "Stage 2 gate status drift between ROADMAP and CONSENSUS (entry not recorded?)"
fi

PENDING_RM=$(grep -c 'Gate status:.*PENDING' "$ROADMAP" || true)
if [ "$PENDING_RM" -eq 9 ]; then
  pass "Stages 4, 5, 6 remain PENDING in ROADMAP plus the six unfunded epilogue stages N1–N6 ($PENDING_RM; the TT-compatibility program passed its own gate 2026-11-22, T2 ENTERED — checker updated per the legitimate-advance precedent, ADR-019/020)"
else
  fail "ROADMAP has $PENDING_RM 'Gate status: PENDING' lines; expected 9 (Stages 4, 5, 6 + epilogue N1–N6; the TT program gated 2026-11-22). Update this checker if a stage legitimately advanced"
fi

S2_ENTERED_CS=$(grep -c '\*\*Stage 2: ENTERED\*\*' "$CONSENSUS" || true)
ENTERED_CS=$(grep -cE '\*\*Stage (4|5|6): (ENTERED|PASSED|CLOSED)\*\*' "$CONSENSUS" || true)
ENTERED_N_CS=$(grep -cE '\*\*N[1-6]: (ENTERED|PASSED|CLOSED)\*\*' "$CONSENSUS" || true)
ENTERED_TT_CS=$(grep -cE '\*\*T[1-4]: (ENTERED|PASSED|CLOSED)\*\*' "$CONSENSUS" || true)
if [ "$S2_ENTERED_CS" -eq 1 ] && [ "$ENTERED_CS" -eq 0 ] && [ "$ENTERED_N_CS" -eq 0 ] && [ "$ENTERED_TT_CS" -eq 1 ]; then
  pass "CONSENSUS records Stage 2's entry and the TT program's T2 entry (the 2026-11-22 TT gate) and no outcome for un-gated stages 4, 5, 6, or the epilogue N1–N6"
else
  fail "CONSENSUS stage-outcome drift (Stage-2 entries: $S2_ENTERED_CS; un-gated outcomes: $ENTERED_CS/$ENTERED_N_CS; TT entries: $ENTERED_TT_CS — expected 1 after the 2026-11-22 TT gate) — reconcile with ROADMAP"
fi

# --- 2. Gate-scope consistency: WORKFLOW §2 tiering ↔ ROADMAP tiering -------
WF_SCOPE=$(grep -c 'Stage-2 entry' "$WORKFLOW" || true)
RM_SCOPE=$(grep -c 'Stage 2 entry' "$ROADMAP" || true)
WF_HR=$(grep -c 'history-rewrite' "$WORKFLOW" || true)
RM_HR=$(grep -c 'history-rewrite' "$ROADMAP" || true)
if [ "$WF_SCOPE" -ge 1 ] && [ "$RM_SCOPE" -ge 1 ] && [ "$WF_HR" -ge 1 ] && [ "$RM_HR" -ge 1 ]; then
  pass "gate-depth tiering lists the same full-depth stages in WORKFLOW and ROADMAP"
else
  fail "gate-depth tiering diverged between WORKFLOW and ROADMAP (fuller-scope-wins rule applies)"
fi

# --- 3. STATE freshness vs the session log ----------------------------------
LAST_LOG="$(grep -E '^## [0-9]{4}-[0-9]{2}-[0-9]{2}' "$LOG" | tail -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')"
STATE_UPD="$(grep -m1 -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "$STATE")"
if [ -n "$LAST_LOG" ] && [ -n "$STATE_UPD" ] && [[ "$STATE_UPD" > "$LAST_LOG" || "$STATE_UPD" == "$LAST_LOG" ]]; then
  pass "STATE.md ($STATE_UPD) is not older than the last session-log entry ($LAST_LOG)"
else
  fail "STATE.md ($STATE_UPD) predates the last SESSION_LOG entry ($LAST_LOG) — refresh it at teardown"
fi

# --- 4. Stated test totals vs actual declarations ---------------------------
# Static declarations, except golden_fixtures_test.dart which is data-driven:
# its single test declaration expands to one executed test per JSON fixture
# in fixtures/tax/, so its fixtures are counted instead of its declaration.
STATIC_ALL=$(grep -h -E '^[[:space:]]*(test|testWidgets)\(' clearfile/test/*.dart | wc -l | tr -d ' ')
GOLDEN_STATIC=$(grep -h -E '^[[:space:]]*(test|testWidgets)\(' clearfile/test/golden_fixtures_test.dart 2>/dev/null | wc -l | tr -d ' ')
GOLDEN_TESTS=$(ls fixtures/tax/*.json 2>/dev/null | wc -l | tr -d ' ')
DECLARED=$(( STATIC_ALL - GOLDEN_STATIC + GOLDEN_TESTS ))
RM_ROW="$(grep -oE '[0-9]+ Dart tests' README.md | head -1 | grep -oE '^[0-9]+')"
RM_RUN="$(grep -oE '[0-9]+ tests green' README.md | head -1 | grep -oE '^[0-9]+')"
ST_GREEN="$(grep -oE '\*\*[0-9]+/[0-9]+ green\*\*' "$STATE" | head -1 | grep -oE '[0-9]+/[0-9]+' | cut -d/ -f1)"
if [ -n "$RM_ROW" ] && [ "$RM_ROW" -eq "$DECLARED" ]; then
  pass "README test-table row ($RM_ROW) matches declared tests ($DECLARED)"
else
  fail "README test-table row says '${RM_ROW:-<none>}', actual test declarations: $DECLARED"
fi
if [ -n "$RM_RUN" ] && [ "$RM_RUN" -eq "$DECLARED" ]; then
  pass "README run-block count ($RM_RUN) matches declared tests ($DECLARED)"
else
  fail "README run-block says '${RM_RUN:-<none>} tests green', actual test declarations: $DECLARED"
fi
if [ -n "$ST_GREEN" ] && [ "$ST_GREEN" -eq "$DECLARED" ]; then
  pass "STATE.md test count ($ST_GREEN) matches declared tests ($DECLARED)"
else
  fail "STATE.md says '${ST_GREEN:-<none>}/… green', actual test declarations: $DECLARED"
fi

# --- 5. Mode drift: snapshot restores flip 100644 → 100755 -----------------
MODE_FLIPS=$(git diff --cached --summary 2>/dev/null | grep -c 'mode change' || true)
MODE_FLIPS_WT=$(git diff --summary 2>/dev/null | grep -c 'mode change' || true)
if [ "$MODE_FLIPS" -eq 0 ] && [ "$MODE_FLIPS_WT" -eq 0 ]; then
  pass "no 100644↔100755 mode flips staged or unstaged"
else
  fail "mode-only changes staged/working ($MODE_FLIPS/$MODE_FLIPS_WT) — normalize before committing"
fi

# --- 6. Nothing appended to memory that is not pushed -----------------------
if git fetch -q origin 2>/dev/null; then
  UNPUSHED="$(git rev-list --count origin/main..main 2>/dev/null || echo X)"
  if [ -z "$UNPUSHED" ] || [ "$UNPUSHED" = "0" ]; then
    pass "no unpushed commits (last session-log entry is archived)"
  else
    fail "$UNPUSHED unpushed commit(s) — the last session-log entry postdates the backup; run scripts/sandbox_backup.sh"
  fi
else
  # Stage-2 entry gate (ENG-2): this branch used to promise a '-c' flag the
  # script never implemented. The phantom option is gone; the check itself
  # stays fail-closed — a transient network failure needs a re-run, not a
  # silent pass.
  fail "could not reach origin to verify the unpushed check (transient network error? re-run)"
fi

# --- 7. Stage-2 RE-tooling placement mechanics (ADR-012 (a)/(e), 2026-11-22) -
# (a) the enumerated synthetic-fixture path must be gitignored (nothing may
# land there by accident), and (e) the RE tooling must never be wired into
# release.yml artifact paths (checkouts of both rules; the CI binary-blob
# assertion itself lives in hygiene.yml's re-tooling job).
if git check-ignore -q fixtures/re 2>/dev/null; then
  pass "fixtures/re/ (the enumerated synthetic-fixture path) is gitignored (ADR-012 (a))"
else
  fail "fixtures/re/ is NOT gitignored — the ADR-012 (a) fixture path must stay ignored"
fi
if git ls-files --error-unmatch fixtures/re >/dev/null 2>&1; then
  fail "files are TRACKED under fixtures/re/ — the synthetic path must stay untracked (ADR-012 (a))"
else
  pass "nothing tracked under fixtures/re/ (ADR-012 (a))"
fi
RE_TOOL_REFS="$(grep -cE 're_entropy|re_magic|re_diff|check_binary_blobs|lint_format_specs|test_re_tools|fixtures/re' .github/workflows/release.yml 2>/dev/null || true)"
if [ "$RE_TOOL_REFS" -eq 0 ]; then
  pass "release.yml references no RE tooling or fixture path (ADR-012 (e))"
else
  fail "release.yml references RE tooling ($RE_TOOL_REFS line(s)) — tooling never wires into artifact paths (ADR-012 (e))"
fi

echo "harness_check: $FAILURES failure(s)"
exit $([ "$FAILURES" -eq 0 ] && echo 0 || echo 1)
