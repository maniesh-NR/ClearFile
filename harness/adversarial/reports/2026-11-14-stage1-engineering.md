# ADV-ENG — Staff Engineer / Quality · Stage-1 gate review (2026-11-14)

Scope: full repo at staged state (HEAD `767269f`; session work staged awaiting teardown backup). Static review + read-only commands re-run independently: `npx tsc --noEmit` (exit 0), `flutter analyze` (clean, 7.2 s, fresh SDK), both secret-guard greps against the live index (clean), YAML parse of `release.yml`, test-declaration recount, lockfile↔package.json sync check. `flutter test` not re-run per rules; the 47/47 claim audited by declaration count.

## Stage-0 condition verification

**ENG-1 (delete-return resurrection + regression test): VERIFIED.** `deleteReturn` cancels the debounce; the timer callback is identity-guarded; `dispose()` idempotent. The regression test genuinely catches the bug if reintroduced: it arms the real 600 ms timer, deletes, waits 900 ms, then asserts `listReturns` empty — with both fix halves reverted, the timer re-saves and the assertion fails; it passes if only one half exists (tests the contract, not the implementation detail). Residual (NOTE, not a failure): the timer's save is fire-and-forget, so a reintroduced bug on a pathologically slow FS could theoretically land its write after the 900 ms check — practically ample slack on a local temp dir.

**ENG-2 (PAT sanitization): VERIFIED.** 0600 mktemp + trap + chmod; push stderr through sed before tail; both sed patterns cover the actual `x-access-token:…@github.com/` credential form (the second also covers `oauth2:`/bare-token forms). The drill evidence is real (commit `767269f` + SESSION_LOG entry).

**ENG-3 (README truth sweep): VERIFIED, one residual.** Two-engine split, honest "Engine limitations" section, GitHub-Releases row, NOTICE paragraph, 19-count fix all present. Residual: the run-commands block still said "42/42 green" — stale against the same file's 47-test table.

**ENG-4 (dispatch semantics + guardrails): VERIFIED.** Required `tag` input; `RELEASE_TAG` validated in every build job (windows correctly forces `shell: bash` for the validation); `timeout-minutes` on all 8 jobs; workflow-level concurrency with `cancel-in-progress: false`; the pwsh zip step uses correct subexpression env-var syntax; `tag_name` propagates the validated tag to softprops. Slash-bearing tags fail validation instead of breaking paths. YAML parses cleanly.

**ENG-5 (reproducible web build): VERIFIED.** `package-lock.json` committed and exactly in sync with `package.json` (`z-ai-web-dev-sdk` absent from both); CI uses `npm ci` + typecheck + build; `ignoreBuildErrors: false` with the do-not-re-enable comment; tsc re-run: exit 0; `reactStrictMode: false` carries the ADR-010 pointer.

**ENG-6 (harness pointer audit): VERIFIED — and already drifting again.** The §-references were corrected, the typo is gone, WORKFLOW §5 carries the full PAT policy. However STATE.md still said "SDK ABSENT" / "43 pending" — false at review time — and the CONSENSUS appendix said "44 planned" while its own itemization sums to 47.

**Stage-1 entry conditions (engineering seat):**
- *SDK + analyze + tests*: PARTIAL at review time — everything present and verified by my own runs, but no durable document yet recorded the executed result.
- *SEC-4 remainder*: VERIFIED.
- *LEGAL-2 privacy*: VERIFIED — de-identification, default-off (both defaults), copy aligned, web auto-fill exception disclosed; web copilot context is counts+figures only.

**Claimed-change spot-audit:** blueprint regenerated (17 pages, exact byte size; the corrected sentence is real); DEBT register statuses check out; DECISIONS/ROADMAP/WORKFLOW §5 match the owner decisions.

## New findings

**1. [MINOR] The identity-guard fix silently drops the previous return's pending autosave on every switch path (regression introduced by the Stage-0 fix).**
Evidence: the guarded timer skips the save whenever `current?.id != r.id`, but `_open()` neither cancels nor flushes, and it is reached with a dirty `current` from three paths (`openReturn`, `startNewReturn`, `importFromFile`); the user can reach home mid-edit via `selectTab`. Edit return A, switch to return B within 600 ms → the guard correctly refuses to save A into B's identity window, but nothing else ever saves A — A's last edits silently vanish. The fix traded a resurrection bug for a narrow vanishing bug in the same mechanism.
Fix: flush-on-switch in `_open` (`_saveDebounce?.cancel(); if (current != null) await store.save(current!);`) + a switch-path regression test.

**2. [MINOR] The privacy test never exercises the findings path — the one place names still live.**
Evidence: `review_rules.dart` interpolates `w2.employer` and `d.name` into finding **details**; `buildReviewPrompt` embeds only finding **titles** (static strings) — so no leak today, but nothing pins it: a future "improvement" that includes `f.detail` in the prompt would leak employer and dependent names with every test still green.
Fix: a test whose fixture triggers both name-bearing findings (withholding > wages; qualifying child age 17+) and asserts the prompt excludes the names. (Adjacent nit: the prompt labels the Dart `Map.toString()` output "JSON" — it isn't.)

**3. [MINOR] Four different test counts lived in the durable docs; only one is right — Stage-0 finding 7's class, reintroduced within one session.**
Evidence: actual count = 47 (recounted); README table 47 ✓, README run block 42, CONSENSUS "44 planned" (its own itemization sums to 47), STATE "43 pending". The gate's own entry condition is "verify the test run" — the run happened but the harness recorded three stale numbers.
Fix: one mechanical pass + build `harness_check.sh` (D19) so this stops being a per-gate rediscovery.

**4. [MINOR] `store.ts` migrate comment claims shape validation the code doesn't perform.**
Evidence: the loop only pruned null/undefined values; a persisted `w2s: "x"` would survive and crash the first consumer — precisely the corrupted-localStorage path the rewrite meant to harden.
Fix: real checks (`Array.isArray` etc.) or a narrowed comment; don't leave the comment promising more than the code delivers in the untrusted-input path.

**5. [NOTE] Backup-script exit-code contract drift on fetch failure.** `git fetch -q origin` under `set -e`: a network failure exits with git's 128, not the documented 1. Wrap or document. Everything else adversarially probed holds: `:(exclude)` pathspecs valid on the installed git; empty-index exits absorbed; the "commit lands, push fails" question has no silent hole.

**6. [NOTE] Release concurrency group doesn't deduplicate the same tag across triggers.** Fix: group on the tag alone.

**7. [NOTE] Dispatch against a pre-existing tag publishes HEAD artifacts under an older tag.** Guard (compare the tag's SHA to `github.sha`) or document; the planned dispatch dry-run should test fresh-tag AND existing-tag dispatch.

**8. [NOTE] Blueprint pipeline portability/determinism.** The merge script writes to the gitignored `download/` path — a fresh clone fails until `mkdir`; ReportLab embeds timestamps (not byte-deterministic — never cite the blueprint as a reproducibility exemplar); one "never collects" sentence still lived in the generator at review time.

**9. [NOTE] tsconfig exclude is redundant but harmless.** Belt-and-suspenders for local runs; acceptable.

**What is sound, stated plainly:** every Stage-0 engineering condition is genuinely applied, not cosmetically — each traced to lines with the cheap verifications re-run (tsc 0, analyze clean, guard greps clean, lock sync, YAML parse, count). The delete regression test is designed with real power. The backup drill actually happened and is committed. The README engine section is now the most honest document in the repo. The DEBT register is complete and its status entries are truthful. The Google-key-in-URL and the duplicated money cleaner remain open exactly as ledgered — no silent scope shrinkage.

## Roadmap assessment (engineering seat)

**Stage 1 remaining: correctly scoped and sequenced.** Two additions: the dispatch dry-run must cover the existing-tag case and verify the `npm ci`→tsc→build chain on a real runner; `harness_check.sh` should move up the list (this gate again caught memory drift a 30-line checker would flag mechanically). The `ReturnStore` seam (D4) is the natural vehicle for finding 1's fix.

**Stage 3 parity (ADR-009): engineering-sound, with fixture-design demands.** The port is tractable — constants-plus-formulas with cited sources and hand-verified tests to crib from. The shared golden fixtures need: (1) a canonical superset input schema mapped into each engine's native model; (2) a canonical result schema both engines map into; (3) an explicit `taxYear` pin per fixture (web defaults TY2026, Flutter is TY2025-only); (4) a declared rounding mode with expected values in cents; (5) generation from the Flutter engine (the ratified reference) plus the IRS worked-example corpus. Budget note: exact CTC phase-out and cents rounding change existing web outputs — expected and disclosed, but the parity PR must not quietly rebaseline golden numbers.

**Stage 5:** keep timeout parity and the `x-goog-api-key` header fix — the key-in-URL is still live at `providers.dart:66`.

## Verdict

**PROCEED-WITH-CONDITIONS**

All Stage-0 engineering conditions and Stage-1 entry items verified as genuinely applied; the roadmap is sound. Conditions (each checkable):

1. **Fix the switch-path autosave drop** (finding 1): flush-on-switch in `_open` + a regression test covering update-A → open-B → A persisted.
2. **Pin the findings path in the privacy contract** (finding 2): a privacy test with a fixture that triggers the name-bearing findings, asserting employer/dependent strings absent from the prompt.
3. **Record the verified entry facts and kill the count drift** (finding 3): README run-block count; CONSENSUS correction note (append-only); STATE.md refresh — before the teardown backup.
4. **Align `store.ts` migrate with its comment** (finding 4): real shape checks for container fields or a narrowed comment.

Findings 5-9 are notes for the debt register / Stage-1 items, not gate blockers.
