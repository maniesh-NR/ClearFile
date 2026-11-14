# ADV-PROD — Product Strategist / Roadmap · Stage-1 gate review (2026-11-14)

**Scope reviewed (read-only):** `harness/adversarial/CONSENSUS.md`, the Stage-0 product report, `harness/memory/{ROADMAP,DECISIONS,SESSION_LOG,STATE,DEBT}.md`, `harness/WORKFLOW.md`, `README.md`, `clearfile/README.md`, the privacy/permission/entitlement diffs, the privacy test, `.github/workflows/release.yml`, the web copy diffs, the blueprint generator, git state, and actual test-declaration counts. No builds/tests executed (read-only mandate); the live v1.0.0 release page could not be fetched (API rate limit) — in-repo evidence used where it matters and flagged where unverifiable.

## Stage-0 condition verification

**1. README engine-truth sweep — VERIFIED.** Two-engine split with per-implementation scope; a real "Engine limitations" section; the NOTICE paragraph; the GitHub Releases row; the corrected 47-test breakdown (matching my own count of 47 declarations). One residue regenerating inside the swept file: the run block still said "42/42" (filed as finding 4).

**2. ADR-009 recorded + roadmap amended — VERIFIED.** The ratification is recorded verbatim against the panel recommendation ("explicit owner prerogative") including the cost statement; the ROADMAP implements it faithfully (parity feature list matching ADR-009's own clause plus rounding; web prototype as live target; Flutter as reference model; both-engines-on-shared-golden-fixtures). Stage 3's title and body were actually rewritten, not cosmetically relabeled.

**3. CONSENSUS exists + session-log reconciliation — VERIFIED.** Real ledger with verdict table, condition dispositions, owner decisions verbatim, and an appendix. The SESSION_LOG reconciliation note is appended (not rewritten), states its own mistake plainly, and closes with the backup drill (commit `767269f` confirms). Append-only honored.

**4. ROADMAP amendments — VERIFIED.** Stage-1 item 4 marks the privacy work done with real code evidence behind it (verified in the files); Stage 4 is cut to the Pages deploy with a backlog carrying a revisit trigger; the matrix is present and per-stage.

**5. ADR-008 recorded before SHA work — VERIFIED.** Ratified; NOTICE added; no new tag exists since v1.0.0, so no SHA256SUMS artifact was published ahead of the decision — the sequencing holds.

**6. Gate depth tiering added — PARTIAL.** The tiering is implemented in ROADMAP exactly; but WORKFLOW §2.2 (the self-declared *binding* contract, read first at bootstrap) still mandated "the whole current repository state" at every gate — two load-bearing documents disagreeing about the same gate's scope, and the planned self-check does not include the cross-document check. Filed as finding 2.

## New findings

**1. [MAJOR] The v1.0.0 release binaries are known-broken for the AI assistant, nothing user-facing says so, and the decision record claims a disclosure that does not exist.**
Evidence: D20/DECISIONS say the binaries' dead AI "is noted in the NOTICE/limitations" — the only places the fact appears are DEBT.md and that DECISIONS line; README's NOTICE is about history; the workflow body discloses for the *next* release only; no stage owns a release; nothing names *when* the fix ships.
Why it matters: the README markets the AI cascade; a user who side-loads v1.0.0 Android and enables the assistant gets a silently failing feature. For a project whose product is trustworthiness, a known-broken shipped artifact with zero user-facing disclosure is the exact failure class this repo exists to study — and the DECISIONS record asserting a disclosure that isn't there is an honesty defect in the durable memory itself.
Fix: re-patch the live release description with the AI-broken line; the same line in README; give the fix a vehicle — declare Stage 1's closing event to be a v1.0.1 tag (the dispatch dry-run is precisely its rehearsal, and it discharges the "verify SHA256SUMS at next tag" item).

**2. [MAJOR] The operating contract and the roadmap contradict each other on what a gate reviews.**
Evidence: WORKFLOW §2.2 mandates full-repository review at every gate with no tiering qualifier; ROADMAP's tiering section defines delta-scoped gates for Stages 3-6. WORKFLOW is read first at bootstrap; a session obeying it would run full-depth gates forever — the exact cost curve the Stage-0 condition existed to bend — while a session obeying ROADMAP violates the contract.
Fix: one paragraph in WORKFLOW §2 pointing to ROADMAP's tiering; add the cross-document check to the harness self-check.

**3. [MAJOR] Parity is now policy with a doubled cost curve, acknowledged — and with no survivability mechanism anywhere in the plan.**
Evidence: the doubled-maintenance consequence appears in exactly one place (the ADR ratification note); the ROADMAP matrix states the policy with no cost note; Stage 3 carries the parity work with no time-box, no slip trigger, no fallback. Stage 3 is now simultaneously the parity port, TXF import + verification, schema versioning, the save-format decision, parser hardening, docs/engine.md, the guided tour, issue templates, and the definition of done — the roadmap's largest stage, doubled by policy, for one maintainer, open-ended.
Why it matters: the owner decided with eyes open; I do not relitigate. But "risk accepted" is not "risk managed": without a tripwire, Stage 3 can absorb unlimited slippage before anyone is obliged to revisit the freeze option, and the highest-value trust artifacts are bundled into the same unbounded stage.
Fix: a recorded time/effort box for the parity set; the rule that exceeding it (or slipping a gate) returns the web-freeze option to the next gate agenda as a mandatory item; a doubled-cost line next to the matrix. Land the shared golden fixtures FIRST inside Stage 3 — they double as the reference engine's regression suite and keep producing value even if parity is deferred by the tripwire.

**4. [MINOR] The README contradicts itself on the test count** — 47 in the table, "42/42" in the run block; my count confirms 47.

**5. [MINOR] The durable record lags the gate input this gate depends on, and the ledger's own arithmetic drifted.** STATE.md stale on all four post-gate facts; CONSENSUS says "44 planned" while its own itemization sums to 47; the 47/47 run the gate leaned on was recorded nowhere. If the sandbox recycles before teardown, the next session bootstraps from a STATE that misstates the owner's decisions and could re-prompt for them — the exact failure ADR-003 exists to prevent.
Fix: STATE refresh; the run record appended to CONSENSUS; D19's checker to compare STATE-vs-ledger freshness and stated totals vs actual declarations.

**6. [MINOR] ~130 files staged as 100644→100755 mode flips; the closing backup would commit executable bits across the repository.** Cosmetic on GitHub but re-seeds the recycle confusion and noisies every future diff. Fix: normalize modes before the closing backup; add a mode-drift check to the harness self-check.

**7. [NOTE] With parity now policy, Stage 2 before Stage 3 is the wrong default order — decide it explicitly at the Stage-2 gate.** Stage 3 is the self-described highest-value stage and now carries a doubled, policy-mandated debt; doing RE tooling first delays the trust artifacts by a full stage at exactly the moment their cost doubled. Counterweight: Stage 2 is small, time-boxed, already ADV-LEGAL-weighted. Fix (recommendation, not a condition): swap them, or record a one-line rationale at the Stage-2 gate.

**8. [NOTE] `scripts/` carries sandbox-exploration scripts in the public repo** (openrouter_explore, diag_reasoning, ai_provider_tests) against ADR-004's "not a sandbox mirror" policy. Fix at Stage-1 hygiene: a one-line purpose README or untrack.

**9. [NOTE] What is sound and should stay.** The Stage-0 process worked as conditioned, not merely on paper: the pre-recorded log was corrected by genuine append-only reconciliation that names its own mistake; CONSENSUS is a real ledger with dispositions and honest orchestrator notes; the backup guard was actually drilled; the owner's four decisions were implemented faithfully and with unusual quality (privacy pinned by tests including the legacy-default case; INTERNET/entitlement changes carry comments citing the decision; the release body discloses unsigned posture and network use; the web copy fixes landed in both the app and the regenerated blueprint). The remaining Stage-1 scope is real, small, correctly sequenced; what is missing is the one obligation the owner's decisions created — the shipped-artifact disclosure in finding 1.

## Roadmap assessment (product seat — including the parity decision's implementation fidelity)

**Parity fidelity: high.** The six named features plus rounding; the reference-model direction; the both-engine fixture tests with a checkable fixture format; no residue of the superseded freeze plan. The implementation is faithful; what it lacks is the survivability wrapper (finding 3) — demanded as a condition, not a relitigation.

**Stage 1 as the next thing to build: right.** Hardening before features remains correct; the decisions-first re-sequencing worked. The highest-value work inside items 5-9 is the release-integrity follow-through and harness_check.sh (the harness becoming self-enforcing is what makes every later gate cheap and credible). One shape improvement: fold finding 1's fix into Stage 1's closing event so the stage ends with one coherent release (v1.0.1: INTERNET fix + SHA256SUMS verification + dispatch rehearsal) instead of leaving "verify at next tag" items dangling.

**Definition of done: coherent end-to-end, with one timing wrinkle.** The v1.1 criterion + Stage 6 freeze + version policy close the infinite-roadmap risk structurally; the wrinkle is that version policy arrives at Stage 6 while the INTERNET decision needs a patch-release rule (v1.0.x) now — folded into condition 1. Stage 4 (Pages) is coherent; Stage 5 is correctly reduced.

**Gate cadence after one full cycle: credible, half-built.** The tiering exists and this very gate honored it; the WORKFLOW contradiction (finding 2) means the cadence's rules live in a document that disagrees with the roadmap, and the self-check that would enforce consistency is still pending.

## Verdict

**PROCEED-WITH-CONDITIONS**

Stage 1 may proceed with its items 5-9 once these are applied (all concrete and checkable; none relitigates the owner's ratified decisions):

1. **v1.0.0 disclosure + fix vehicle.** Re-patch the live release description with the AI-broken line (re-verify once the API is reachable); the same line in README naming the next tagged release as the fix; record that Stage 1 closes with a v1.0.1 tag whose rehearsal is the dispatch dry-run. Clears the false "noted in the NOTICE/limitations" claim in DECISIONS D20.
2. **Parity tripwire.** ADR-009 ratification note + ROADMAP Stage 3 amended with a recorded time/effort box for the web-engine parity set and the rule that exceeding it (or slipping a gate) returns the web-freeze option to the next gate agenda as a mandatory item; a doubled-cost line next to the impl-target matrix. Golden fixtures land before the web-engine features inside Stage 3.
3. **Gate-doc reconciliation.** WORKFLOW.md §2 gains the tiering cross-reference so the binding contract matches ROADMAP; the harness self-check checklist is amended to include WORKFLOW↔ROADMAP gate-scope consistency.
4. **Record what this gate leaned on.** STATE.md updated (decisions ratified, SDK present, test state); the 47/47 + analyze run recorded in CONSENSUS; README's run-block count corrected; the CONSENSUS "44 planned" total corrected by an appended note.
5. **No mode-flip commit.** The closing backup publishes no `mode change 100644 => 100755` lines: normalize the staged modes first and verify with `git show --summary`.
