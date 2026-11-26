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

FUNDED_RM=$(grep -c 'Gate status:.*FUNDED' "$ROADMAP" || true)
if [ "$FUNDED_RM" -eq 4 ]; then
  pass "Epilogue funding posture in ROADMAP ($FUNDED_RM FUNDED: N3–N6; N1 ENTERED+CLOSED, N2 ENTERED — all 2026-11-26; each unfunded-stage still enters only behind its own delta-scoped gate) — checker updated per the legitimate-advance precedent"
else
  fail "ROADMAP has $FUNDED_RM 'Gate status: FUNDED' lines; expected 4 (N3–N6 still funded; N1 ENTERED+CLOSED, N2 ENTERED, all 2026-11-26). Update this checker if a stage legitimately advanced"
fi

S2_ENTERED_CS=$(grep -c '\*\*Stage 2: ENTERED\*\*' "$CONSENSUS" || true)
ENTERED_CS=$(grep -cE '\*\*Stage [456]: CLOSED\*\*' "$CONSENSUS" || true)
# N1's two outcomes (ENTERED at the full-depth entry gate + CLOSED at the
# exit gate, both 2026-11-26) — updated at the N1 exit close (the
# legitimate-advance precedent: a checker update, not drift).
ENTERED_N_CS=$(grep -cE '\*\*N[1-6]: (ENTERED|PASSED|CLOSED)' "$CONSENSUS" || true)
ENTERED_TT_CS=$(grep -cE '\*\*T[1-4]: (ENTERED|PASSED|CLOSED)\*\*' "$CONSENSUS" || true)
if [ "$S2_ENTERED_CS" -eq 1 ] && [ "$ENTERED_CS" -eq 3 ] && [ "$ENTERED_N_CS" -eq 3 ] && [ "$ENTERED_TT_CS" -eq 1 ]; then
  pass "CONSENSUS records Stage 2's entry, the TT program's T2 entry, the Stages 4/5/6 closures, and N1's ENTERED + CLOSED + N2's ENTERED outcomes"
else
  fail "CONSENSUS stage-outcome drift (Stage-2 entries: $S2_ENTERED_CS; Stages-4/5/6 closures: $ENTERED_CS; epilogue outcomes: $ENTERED_N_CS; TT entries: $ENTERED_TT_CS — expected 1/3/3/1) — reconcile with ROADMAP"
fi

# --- 1b. The N1 variant precondition: release.yml stays native-free -------
RM_NATIVE=$(grep -cE 'core/|clearfile-core|cargo' ".github/workflows/release.yml" || true)
if [ "$RM_NATIVE" -eq 0 ]; then
  pass "release.yml references no core/, clearfile-core, or cargo (the ADR-017 variant precondition — nothing shipped depends on the Rust core)"
else
  fail "release.yml references core/|clearfile-core|cargo ($RM_NATIVE hits) — a shipped-artifact coupling the recorded variant forbids without a new gate"
fi

# --- 1c. The Rust suite's mechanical ledger join (N1 gate PROD-3) ----------
# The third golden-fixture runner's manifest must cover the shared corpus
# EXACTLY: run + deferred entries == the fixtures/tax/*.json count (the
# deferred entries are the #[ignore]d tests — skipped-and-counted, never
# red on main). The anchors match the manifest const's line shape so
# prose in doc comments cannot pollute the count.
FIXTURE_DIR_COUNT=$(ls fixtures/tax/*.json 2>/dev/null | wc -l)
RM_TOTAL=$(grep -cE '^    "[0-9]{2}-[a-z0-9-]+\.json (run|deferred) ' core/tests/harness/mod.rs 2>/dev/null || true)
RM_DEFERRED=$(grep -E '^    "[0-9]{2}-[a-z0-9-]+\.json (run|deferred) ' core/tests/harness/mod.rs 2>/dev/null | grep -c ' deferred ' || true)
if [ "$FIXTURE_DIR_COUNT" -gt 0 ] && [ "$RM_TOTAL" -eq "$FIXTURE_DIR_COUNT" ]; then
  pass "the Rust fixture manifest's run+deferred count ($RM_TOTAL; $RM_DEFERRED deferred) equals the shared fixture directory count ($FIXTURE_DIR_COUNT) — green + #[ignore]d == the corpus"
else
  fail "Rust fixture manifest drift (manifest entries: $RM_TOTAL; fixtures/tax/*.json: $FIXTURE_DIR_COUNT; deferred: $RM_DEFERRED) — the runner's manifest must cover the shared corpus exactly (N1 gate PROD-3)"
fi
README_CORE_ROW=$(grep -c '17 of 17 shared fixtures green' README.md 2>/dev/null || true)
if [ "$README_CORE_ROW" -ge 1 ]; then
  pass "README carries the core/ row with the honest fixture count (PROD-3)"
else
  fail "README lacks the core/ row with the honest fixture count (N1 gate PROD-3) — add one row carrying the manifest's run count"
fi

# N1 session 2 (ADR-017 annex (a)/(b)): the differential-corpus ledger —
# PROD-3's mechanical-join mirror for the annex-(a) corpus. The corpus's
# own manifest must equal its array, stay the full generated set, and name
# the tracked generator where it actually lives (the relocation is part
# of the PROD-5 boundary: zero clearfile/ or src/ paths in the N1 delta).
DIFF_MANIFEST=$(python3 - <<'PYEOF' 2>/dev/null || echo MISSING
import json
try:
    d = json.load(open("fixtures/differential/cases.json"))
    cases = d.get("cases", [])
    if (d.get("caseCount") == len(cases)
            and d.get("kind") == "clearfile-differential"
            and d.get("generator") == "scripts/generate_differential_cases.dart"
            and len(cases) >= 500):
        print(len(cases))
    else:
        print("DRIFT")
except Exception:
    print("MISSING")
PYEOF
)
if [[ "$DIFF_MANIFEST" =~ ^[0-9]+$ ]]; then
  pass "the differential corpus ledger: caseCount == the array == $DIFF_MANIFEST cases, the tracked generator named (annex (a) / D43)"
else
  fail "differential corpus drift: $DIFF_MANIFEST — the manifest must equal the array, carry >= 500 cases, and name scripts/generate_differential_cases.dart"
fi
N1S2_FILES=$(ls core/src/json.rs core/src/envelope.rs core/src/txf.rs core/src/tax_inspect.rs \
    core/tests/differential_harness.rs core/tests/property_harness.rs core/tests/return_format_port.rs \
    core/tests/txf_port.rs core/tests/tax_inspect_port.rs core/tests/exchange_composition.rs \
    scripts/generate_differential_cases.dart 2>/dev/null | wc -l)
if [ "$N1S2_FILES" -eq 11 ]; then
  pass "the N1 session-2 surface is fully tracked (4 modules + 6 test files + the generator)"
else
  fail "N1 session-2 file drift ($N1S2_FILES of 11) — a codec module, ported suite, harness, or the generator is missing"
fi
# The corpus's recorded regeneration digest (N1 exit gate, the SEC/ENG
# advisory): the committed cases.json must match the digest its README
# records — a drifted-but-self-consistent corpus otherwise passes the
# manifest check alone (the ENG exit-gate risk register).
CORPUS_DIGEST=$(sha256sum fixtures/differential/cases.json 2>/dev/null | cut -d' ' -f1)
if [ -n "$CORPUS_DIGEST" ] && grep -q "$CORPUS_DIGEST" fixtures/differential/README.md 2>/dev/null; then
  pass "the differential corpus matches its recorded regeneration digest (${CORPUS_DIGEST:0:12}…)"
else
  fail "the differential corpus's sha256 is not the digest recorded in fixtures/differential/README.md — regenerate + re-record, or the corpus has drifted"
fi

# N2 session 1 (D44): the palette-corpus ledger — the mechanical-join
# mirror of the differential family: the corpus's own manifest must
# equal its array, name the tracked generator + the 0.13.0 reference,
# and the palette module + its verification test are tracked.
PALETTE_MANIFEST=$(python3 - <<'PYEOF' 2>/dev/null || echo MISSING
import json
try:
    d = json.load(open("fixtures/palette/cases.json"))
    cases = d.get("cases", [])
    if (d.get("kind") == "clearfile-palette"
            and d.get("seedCount") == len(cases)
            and d.get("roleCount") == 34
            and d.get("paletteCount") == 6
            and "0.13.0" in d.get("reference", "")
            and len(cases) >= 33):
        print(len(cases))
    else:
        print("DRIFT")
except Exception:
    print("MISSING")
PYEOF
)
if [[ "$PALETTE_MANIFEST" =~ ^[0-9]+$ ]]; then
  PALETTE_DIGEST=$(sha256sum fixtures/palette/cases.json 2>/dev/null | cut -d' ' -f1)
  if grep -q "$PALETTE_DIGEST" fixtures/palette/README.md 2>/dev/null; then
    pass "the palette corpus ledger: $PALETTE_MANIFEST seeds, 34 roles x 2, 6 ladders x 101, the 0.13.0 reference named, the digest recorded ($PALETTE_MANIFEST checks green) (D44)"
  else
    fail "the palette corpus's sha256 is not the digest recorded in fixtures/palette/README.md — regenerate + re-record, or the corpus has drifted"
  fi
else
  fail "palette corpus drift: $PALETTE_MANIFEST — the manifest must equal the array, carry the 0.13.0 reference, 34 roles, 6 palettes"
fi
PALETTE_FILES=$(ls core/src/palette.rs core/tests/palette_port.rs apps/linux/Cargo.toml apps/linux/deny.toml apps/linux/src/main.rs apps/linux/Cargo.lock scripts/palette_tool/test/generate_palette_fixtures.dart 2>/dev/null | wc -l)
if [ "$PALETTE_FILES" -eq 7 ]; then
  pass "the D44/N2-scaffold surface is fully tracked (the palette module + verification + the apps/linux scaffold + the generator)"
else
  fail "D44/N2-scaffold file drift ($PALETTE_FILES of 7) — a palette module/test, scaffold file, or the generator is missing"
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
# The path carries a trailing slash: a directory-only ignore pattern
# (/fixtures/re/) matches only directory-resolved paths, and on a fresh
# clone or post-recycle checkout the runtime-generated directory does not
# EXIST on disk — the bare-name form then false-fails (observed 2026-11-25;
# the trailing-slash form matches the .gitignore rule by pattern alone).
if git check-ignore -q fixtures/re/ 2>/dev/null; then
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
