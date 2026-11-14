# ADV-ENG — Staff Engineer / Quality · Stage-0 review (2026-11-14)

Scope: whole repo at `df617e8` + uncommitted Stage-0 deliverables (`harness/`, `scripts/sandbox_backup.sh`). Static review (Flutter SDK absent; `npx tsc --noEmit` **was** runnable — node_modules exists today despite STATE.md saying otherwise). Read-only; no files touched.

## Findings

**1. [MAJOR] Deleted returns can resurrect — `deleteReturn` never cancels the autosave debounce.**
Evidence: `clearfile/lib/ui/app_state.dart:145-148` — `update()` arms `Timer(600ms, () { store.save(r); })` capturing the return object; `closeReturn` (:116) and `dispose()` (:244) cancel `_saveDebounce`, but `deleteReturn` (:126-135) does not. Type in a field → click Delete within 600 ms → timer fires after `store.delete(r.id)` and rewrites the JSON file; the "deleted" return reappears at next `listReturns` (e.g. next launch). Why it matters: silent data-integrity bug in the one feature (delete) that is supposed to be destructive; exactly the fragility class a god-object-with-Timer invites. Fix: `_saveDebounce?.cancel()` in `deleteReturn` **and** an identity guard inside the timer callback (`if (current?.id == r.id) store.save(r);` — the captured `r` is mutated in place, so the guard must be on id, not object). Add a unit regression test (temp dir: `update` → `deleteReturn` → advance 600 ms → `listReturns()` empty).

**2. [MAJOR] The new backup script can print the owner's PAT to the transcript on push failure.**
Evidence: `scripts/sandbox_backup.sh:58-63` — on `git push` failure it runs `tail -5 /tmp/sandbox_backup_push.err` to stderr. Git's auth/network failure messages embed the remote URL, and the remote URL is `https://x-access-token:<PAT>@github.com/...` (WORKFLOW.md §5). WORKFLOW.md explicitly promises the PAT is "never echoed in full in output" — the script violates the harness's own policy precisely when something has already gone wrong. Fix: sanitize before printing, e.g. `sed -E 's#(x-access-token:)[^@]+@#\1***@#g' /tmp/sandbox_backup_push.err | tail -5 >&2`. One line; must land before this script runs for real (it is scheduled to run at this session's teardown).

**3. [MAJOR] "Same engine" is not true: the web and Flutter engines materially diverge, and the README overclaims.**
Evidence: README.md:18-20 ("the same interview, engine and AI cascade") and README.md:51-69 (engine feature list presented for both `clearfile/lib/tax/calculator.dart` **and** `src/lib/tax/`). Reality: `src/lib/tax/engine.ts:8-13` — no qualified-dividend/LTCG stacking, no NIIT, no SALT cap, no OBBBA senior deduction, no student-loan interest, no aged/blind additions; itemized includes medical+other with no AGI ceilings; `config.ts:125` defaults to **TY2026**; whole-dollar rounding (`engine.ts:81`). Flutter implements the full OBBBA set with cents. Same inputs → different refunds (e.g. dividends, high SALT). The web UI is honest about its own scope (steps.tsx:93-95) but the repo-level docs are not. Why it matters: this project's entire brand is clean-room *rigor*; the trust claim is falsified by the README's own feature table. Fix: rewrite README's engine section to scope each bullet to its implementation and state the divergence explicitly; code parity remains Stage 3. Also fix README.md:23 — the `download/` row describes a directory that is now gitignored (verified: 0 tracked files).

**4. [MAJOR] `workflow_dispatch` is broken beyond the naming bug the roadmap names — the release step has no tag to attach to.**
Evidence: `.github/workflows/release.yml:13` (dispatch trigger) and :210-238 (release job; `softprops/action-gh-release@v2` with no `tag_name`). On a branch dispatch (GITHUB_REF_NAME = `main`), assets get branch-embedded names (known) **and** the release step either fails or creates a bogus tag/release after all six platform builds have burned their compute. ROADMAP.md:37-39 only plans the naming fix — it understates the failure. Fix: add `workflow_dispatch: inputs: tag` (validated against `^v`) and pass it to the release action, or drop the dispatch trigger. While in there: no `timeout-minutes` on any job (a hung gradle build burns 6 h — and this repo has a documented history of hung test processes), no `concurrency:` group, no pub/npm cache, actions pinned only by mutable major tags, and top-level `permissions: contents: write` granted to all build jobs that need none.

**5. [MAJOR] The shipped Next.js release artifact is built from unpinned dependencies.**
Evidence: `release.yml:194` (`npm install`); the repo tracks `bun.lock` but no `package-lock.json`; `npm install` resolves semver ranges fresh at build time. So the `nextjs-standalone` tarball on the release page is **not reproducible from the repo** — the lockfile that exists is ignored by the pipeline that ships. For a Stage-1 roadmap titled "Hardening & trust," this is the cheapest big win: commit `package-lock.json` and switch to `npm ci` (or run `bun install --frozen-lockfile && bun run build`).

**6. [MINOR] `typescript.ignoreBuildErrors: true` is suppressing exactly one real error today — quantified.**
Evidence: ran `npx tsc --noEmit` (exit 2): one app error — `src/lib/store.ts:130` TS2352 (`migrate` casts `Record<string, unknown>` straight to `ClearFileStore`); the other three errors are in untracked scaffolding (`examples/`, `skills/`) that won't exist on a CI checkout. Why it matters: the flag's cost is currently one bad cast in the localStorage migration path (exactly where corrupted persisted state would enter). Fix: type the persisted-state migration properly (or `as unknown as` with a comment), then flip the flag off **and** make CI's web job run a typecheck — `npm run build` with the flag on will not catch types. `reactStrictMode: false` deserves an explicit ADR rather than silence, since strict-mode double-mounting is precisely what exercises the persist path.

**7. [MINOR] Test-honesty detail: the claimed test split is off by one.**
Evidence: counted per file — `calculator_test.dart` has **19** tests (not 20 as README, STATE.md and the session log claim); 19+8+9+3+3 = 42, so the "42/42 green" total is correct, the breakdown is not. Fix the three docs. (Everything else I spot-checked in the harness was *accurate*: 229 tracked files ✓, tip `df617e8` ✓, clean-tree no-op string matches WORKFLOW.md §1.3 verbatim ✓, full-history secret re-scan clean ✓.)

**8. [MINOR] Harness cross-reference drift — the "durable brain" points at the wrong sections in ≥6 places.**
Evidence: harness README ("session protocol in WORKFLOW.md §4" — session protocol is §3, §4 is the recycle runbook); README + `scripts/sandbox_backup.sh` + WORKFLOW + SESSION_LOG (all cite §5 for the recycle runbook — runbook is §4, §5 is auth policy); `.gitignore:60` ("WORKFLOW.md section 3" for backup scope — it lives in §1). Plus a stray markdown artifact WORKFLOW.md ("verdict**"), and STATE.md says `node_modules/` gone while it exists on disk today. Why it matters: a fresh session bootstrapping from the repo will read the wrong runbook — the exact failure ADR-003 exists to prevent. Fix: one pointer-audit pass (mechanical, 15 minutes).

**9. [MINOR] `importReturn` conflates cancelled, unreadable and wrong-format into one silent null.**
Evidence: `clearfile/lib/io/files.dart:39-49` — `catch (_) { return null; }` also swallows programmer errors; the user who picks a non-ClearFile JSON gets zero feedback vs. the user who cancelled. Fix: return a sealed result (cancelled / notAClearFile / unreadable / ok) and surface a message for the middle two. The other `catch (_)` sites are each defensible demo choices — but annotate them with the intent comment return_store already models.

**10. [MINOR] Money normalization edge cases are unpinned and one is silently wrong.**
Evidence: `money_field.dart:62-71` — commas are stripped before `double.tryParse`, so decimal-comma input "6,5" becomes **65** (10× error, no warning); "1.2.3" fails parse and is silently ignored. The identical cleaner is duplicated in `csv_import.dart:164-171`, where an *empty* wages cell also parses as `0`. Web differs again (plain `type="number"`, whole-dollar rounding). Fix: one shared `parseMoney()` util with tests for `'$52,500.00'`, `'6 200'`, `'1,234.5'`, `'6,5'`, `'1.2.3'`, empty; CSV: empty wages cell → warning, not 0.

**11. [MINOR] Codec honesty: `readDate` fabricates epoch dates; `formatVersion` is read nowhere.**
Evidence: `json_codec.dart:42-49` (unparseable date → 1970-01-01, silent); `tax_return.dart:149-183` parses any `formatVersion` as today's schema. The JSON roundtrip tests pin current-shape roundtrip and missing-field defaults — good — but cover no schema evolution. Stage 3 owns versioning; register that **no format change may ship before a version guard exists**.

**12. [NOTE] The `runAsync` convention is sound; the underlying coupling is the debt.**
Evidence: pattern applied consistently (`widget_test.dart`), documented in three durable places. It papers over nothing in app code — the app itself never awaits FS inside build; it's the SDK's binding-zone behavior. The real smell is *why* the tests need it: FS I/O and a raw autosave `Timer` live inside a `ChangeNotifier`. The cascade layer shows the correct pattern — `http.Client` injected and `MockClient` in tests. Fix direction for Stage 1's widget-test expansion: extract a `ReturnStore` interface so new tests use a fake store and stop inheriting the quirk.

**13. [NOTE] AppState god-object — register, don't rebuild now.**
Evidence: one `ChangeNotifier` drives all five screens; every keystroke synchronously recomputes the full return and rebuilds the shell; `settingsStore.save()` is fire-and-forget with no error path; `testConnection()` bypasses the state's error state. Acceptable at demo scale; finding 1 is the concrete bug this shape produced.

**14. [NOTE] `ValueKey` over mutable, value-equal models is a latent trap.**
Evidence: `income_step.dart:27` (`ValueKey(w2)`) with `w2.dart` (`==` by value). Safe today *only* because mutations are in-place; the moment models become immutable, editing a W-2 changes its key mid-typing and remounts the card, losing focus. Same value-equality edge in `settings.dart`: `removeWhere` deletes *all* duplicate chain entries at once. Register both.

**15. [NOTE] Dead asset and a CI write into a tracked directory.**
Evidence: `clearfile/assets/sample_w2.csv` is tracked but undeclared in `pubspec.yaml` and unreferenced by any code; its data is duplicated as `w2CsvTemplate` (`csv_import.dart`). The android CI job writes APKs into that same tracked `clearfile/assets/` dir — a locally-replicated build step dirties a tracked path. Fix: wire the asset into a "download template" flow or delete it.

**16. [NOTE] CI guardrails (beyond #4).** No `timeout-minutes` anywhere; no `concurrency:` group (two rapid tag pushes race the release job); no pub/npm caching; actions pinned by mutable major tags only. All cheap, all Stage 1.

**17. [NOTE] Behavioral parity drift beyond the engine.** Flutter AI timeout 90 s for both providers vs web 45 s Google / 90 s OpenRouter; Flutter sends the Google key as a URL query param while web correctly uses the `x-goog-api-key` header — align Flutter to the header; web CTC phase-out uses ceil'd $50-per-$1,000 units vs Flutter's exact 5% of excess — answers differ at non-thousand-dollar boundaries.

**18. [NOTE] Secret-guard pattern coverage is thin (acceptable as belt; gitleaks is the suspenders).**
Evidence: `sandbox_backup.sh` matches only `github_pat_`, long `sk-`, `AIza` — misses `ghp_`/`gho_`, AWS `AKIA`, `sk-ant-`. Also note the guard scans the *entire index* each run (a feature — whole-tree sweep, not just the diff). The Stage-1 scheduled gitleaks job is the right complement.

**19. [NOTE] Slash-bearing tags break artifact paths.** `on: push: tags: 'v*'` matches `v1.0.0/rc`; the resulting asset names embed a slash and `tar`/Compress-Archive fail. Rare; guard or document.

**What is sound (stated plainly, with evidence):**
- **The calculator tests are genuinely rigorous.** 19 tests hand-derive arithmetic from published parameters; I cross-checked the pinned numbers against `tax_year.dart` constants — all consistent. Honest caveat they already carry: nothing is pinned to an *official IRS worked example* yet — Stage 3 correctly names that the highest-value trust artifact.
- **The cascade tests pin the real contract** (429→step-down, 401→provider-dead, disabled/keyless skip, 404 fall-through, all-fail report, settings roundtrip, legacy mistral drop) using a proper mock seam.
- **Every CI artifact path now follows the workspace-root lesson** — I audited all seven the way the macOS bug was found: currently no artifact-name collisions.
- **The backup script's skeleton is right**: `set -euo pipefail` correctly ordered, preflight (work-tree, origin, identity), clean-tree no-op semantics exactly as documented, fast-forward-only push with explicit no-blind-force-push guidance, documented exit-code contract.
- **The harness memory was more honest than not**: every checkable claim I tested held (229 files, tip SHA, 42 total tests, v1.0.0 pointing at `13205da`, clean-tree string, full-history secret scan — I re-ran it over every commit: clean).
- **Disclaimers are layered everywhere** — appropriate for demo software.

## Roadmap assessment

**Stage 1 (Hardening & trust) — right content, wrong completeness.** The listed items are correct, but the stage's *own gate criteria* should absorb findings 1–5: the delete-return bug and the PAT leak are trust bugs in shipped behavior, the README engine overclaim is a *documentation* trust bug fixable in an hour rather than waiting for Stage 3 code parity, and `npm ci` + lockfile is the reproducibility half of "release integrity" that SHA256SUMS alone doesn't give you (checksums of an unreproducible build are just fingerprints of drift). Add a web CI typecheck step and a `ReturnStore` interface seam so the new widget tests escape the `runAsync` tax.

**Stage 2 (RE tooling) — engineering-sound, with one demand:** the tools are exactly the kind of code that gets unit tests cheaply — pin them; keep the no-proprietary-binaries rule as a CI-checkable assertion (a test that fails if any binary blob appears under `scripts/formats/fixtures/`), not a promise.

**Stage 3 (Clean-room bridges) — the highest-value stage, and it owns two debts this review surfaced:** finding 11 (version-blind `fromJson` — no format change ships before a version guard) and finding 3's code half (parity). Note the two engines share *zero* code, so parity tests need a shared fixture format — golden `(TaxReturnData, TaxResult)` JSON pairs consumed by both Dart and TS suites.

**Stage 4 (Platform reach)** — fine; GitHub Pages should pin basic security headers for the Flutter web build, and the unsigned-.aab posture should be documented on the release page.

**Stage 5 (AI hardening)** — the recorded-fixture e2e aligns with the existing MockClient pattern; fold finding 17's timeout/key-transport divergences into that same parity sweep.

## Verdict

**PROCEED-WITH-CONDITIONS**

Stage 1 is the correct next stage and nothing found is reckless enough to hold the roadmap hostage — but the following must be applied before or during Stage 1 (each checkable):

1. **Fix the delete-return resurrection** (cancel + identity-guard the autosave debounce in `deleteReturn`) and add the regression test. Clears finding 1.
2. **Sanitize the PAT in `sandbox_backup.sh`'s push-failure output** (and any future git-error echo) before the script's next real run. Clears finding 2.
3. **Truth up the README** — scope the engine feature list per implementation, fix the stale `download/` row and the 20→19 test split. Clears findings 3 (doc half) and 7.
4. **Fix the dispatch semantics, not just the naming** — tag input for `workflow_dispatch` or remove the trigger; add `timeout-minutes` and a `concurrency` group to the workflow. Clears finding 4 (incl. 16's guardrails).
5. **Make the web release build reproducible** — commit `package-lock.json`, switch CI to `npm ci`, add a typecheck step, and clear the `store.ts:130` cast so `ignoreBuildErrors` can be turned off. Clears findings 5 and 6.
6. **Run the harness pointer-audit pass** (§-number references, the `verdict**` typo, the `node_modules` state line) so the durable brain stops misdirecting fresh sessions. Clears finding 8.

Findings 9-19 should enter the Stage-1 technical-debt register (a `harness/memory/` debt section or a DECISIONS annex) so they are tracked rather than rediscovered by the next reviewer.
