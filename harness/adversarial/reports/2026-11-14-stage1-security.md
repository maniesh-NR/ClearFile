# ADV-SEC — Red Team / Security · Stage-1 gate review (2026-11-14)

Scope actually examined: the full delta since the Stage-0 gate — commit `5121d6a` (Stage-0 condition fixes) + `767269f` (backup drill) + the entire staged working tree (144 files, the Stage-1 entry work) — with independent execution of the verification commands: `flutter analyze` (clean), `flutter test` (**47/47 passed** — my own run), `npx tsc --noEmit` (exit 0), replication of both backup-guard greps against the fully staged index, a sed-sanitizer simulation against a fabricated PAT-bearing git error, an independent token-pattern scan of the `v1.0.0` tag tree, and a fetch of the live v1.0.0 release page (HTML; the REST API was rate-limited). The owner's PAT is confirmed present only in `.git/config` remote URL (never printed).

## Stage-0 condition verification

**SEC-1 (backup correctness patch) — VERIFIED.**
`scripts/sandbox_backup.sh:39-44` branch guard (`git branch --show-current` ≠ `main` → exit 1; detached HEAD yields empty string → refused); `:48-56` `check_unpushed()` runs `git fetch` + rejects non-empty `origin/main..main` **before** the clean-tree exit 0 (`:61-65` — ordering correct, scenario A closed); `:97-99` `mktemp` (0600 by default, explicit `chmod 600`) + `trap … EXIT`; `:100-103` push stderr sanitized. My simulation of the sed against realistic git failure output produced a fully-redacted URL. Drill evidence: commit `767269f` + SESSION_LOG append records the forced-refusal drill. Residual gap filed as New Finding 2 (the *fetch* stderr is not sanitized).

**SEC-2 (secret-guard widening) — VERIFIED.**
Wide pattern set verified in the script; exclusion calibration proven: without exclusions the only 64-hex carrier is `clearfile/pubspec.lock` (npm lockfiles store base64 sha512, not hex — the explicit npm-lock excludes are harmless redundancy). Residual gap filed as New Finding 3 (`-I` skips binaries).

**SEC-3 (CI least privilege + injection hygiene) — VERIFIED.**
Workflow-wide `contents: read`; `contents: write` on the `release` job only; pwsh uses `$($env:RELEASE_TAG)` — no raw `${{ }}` into any shell anywhere (remaining interpolations are env assignments, the concurrency-group string, and `tag_name:` into an action input — all non-executing contexts); dispatch takes a **required** `tag` input; the `^v[0-9][0-9A-Za-z._-]*$` validation runs in all 7 jobs that consume `RELEASE_TAG` before any shell use (the charset it enforces excludes every shell metacharacter, so even the unquoted `${RELEASE_TAG}` expansions are inert); `timeout-minutes` on all 8 jobs; workflow-level `concurrency` with `cancel-in-progress: false`. The 8th job (`flutter-test`) uses no tag, hence no validation step — accurate in substance.

**SEC-4 (release integrity) — VERIFIED.**
`SHA256SUMS.txt` generated in the `release` job (the only `contents:write` job), in correct order: collision-guarded flatten → copy docs → `sha256sum *` → upload (`fail_on_unmatched_files: true`); `sha256sum *` cannot hash itself (word expansion precedes the redirection creating it). Explicit `body:` with demo disclaimer, unsigned posture, and network disclosure. INTERNET-vs-cascade resolved per owner decision: main-manifest `INTERNET` with disclosure comments, macOS `network.client` (no server entitlement), in-app copy, README network disclosure. Live v1.0.0 release description verified via the public release page HTML. The workflow has never executed end-to-end since hardening (no tag since) — carried in Roadmap items 5/6/7 and my conditions.

**SEC-5 (web reproducibility) — VERIFIED.**
`package-lock.json` committed (335 KB, tracked, clean of `z-ai-web-dev-sdk`); `npm ci`; typecheck step (my local run: exit 0); `ignoreBuildErrors: false` with a do-not-re-enable comment. See New Finding 4 (stale `bun.lock`).

**SEC-6 (PAT policy recorded) — VERIFIED.**
`harness/WORKFLOW.md §5` records the fine-grained profile, rotation guidance, expiry attestation ask, branch-protection recommendation, and the owner's explicit leave-as-is decision (an ADR I audit, not reverse — the record is complete).

**Stage-1 entry conditions (CONSENSUS): VERIFIED.** LEGAL-2: `buildReviewPrompt` de-identified by construction; `sendReturnContext` defaults false including the fromJson default for pre-existing settings files; privacy copy updated; `privacy_test.dart` all green in my 47/47 run. ENG-1: SDK present; sha256 prefix matches the manifest; analyze clean; tests 47/47. SEC-4 remainder: unsigned-demo posture stated on the release body.

## New findings

**1. [MAJOR] README privacy-default claim is false for the web prototype.**
Evidence: README "AI assistant" section: "Return figures go to your chosen provider **only when you opt in** (off by default)…". The Flutter app has the `sendReturnContext` switch; the web prototype has none — `src/components/clearfile/ai-ui.tsx:143` calls `chatTurn(q, filing, computed, messages)` and `src/lib/ai/tasks.ts:15-33/136-146` attaches the full `filingSummary` to **every** copilot chat and every review request, no opt-out exists. The web UI itself is honest ("The copilot sees your summarized return") — the repo-level README sentence overgeneralizes.
Why it matters: this is exactly the copy-vs-code mismatch class Stage-0 conditioned on (LEGAL-2); under ratified ADR-009 the web prototype is a *live* target, so the README claim governs shipped behavior. Figures are de-identified, so no identifier leak — but the *default-off* claim is wrong for one shipped implementation.
Fix: one sentence — scope it or add the equivalent web toggle (Stage-3 parity scope).

**2. [MINOR] `check_unpushed()`'s `git fetch` stderr bypasses the PAT sanitizer.**
Evidence: `sandbox_backup.sh:49` (`git fetch -q origin`, stderr straight to terminal) vs the push path (0600 temp + sed + tail). Curl-level git errors can echo the full credential-bearing remote URL — the exact leak shape the push sanitizer exists for. This path runs on every clean-tree backup.
Fix: route fetch stderr through the same `mktemp`+`sed` and print the script's own failure line.

**3. [MINOR] Secret guard skips binary files — token in a PDF/PNG passes.**
Evidence: both guard greps used `-I`, which ignores binary files. `docs/blueprint.pdf` and `blueprint-assets/*.png` are tracked binaries; a token pasted into a doc before regeneration would commit unflagged.
Fix: drop `-I` (output is `-l` filenames only — binary matches are safe to list) and/or land the gitleaks job.

**4. [MINOR] `bun.lock` is stale: still pins `z-ai-web-dev-sdk@0.0.18`.**
Evidence: `bun.lock:71/1829` while `package.json` dropped the dependency and `package-lock.json` is clean of it.
Why: a future `bun install --frozen-lockfile` resurrects a removed dependency's graph; drift erodes the "lockfile = audited graph" property.
Fix: regenerate `bun.lock` once, or delete it and standardize on npm lockfiles (CI is `npm ci` already).

**5. [NOTE] 138 files staged with mode change 100644→100755.** The next backup commit flips sources to executable (platform-snapshot artifact). Harmless but permanent diff noise. Fix: mode normalization or explicit acceptance.

**6. [NOTE] Concurrency group differs by trigger: `release-${{ github.ref_name }}-${{ inputs.tag }}`.** Tag push vs dispatch for the same tag get different groups, so two full runs can race the release job. Fix: single form `release-${{ inputs.tag || github.ref_name }}`.

**7. [NOTE] `buildFieldQuestion` is dead code that would transmit field values verbatim if wired.** No callers anywhere. If ever connected, de-identify or strip first.

**8. [NOTE] Deferred, unchanged, ledgered (verified — not regressions):** Gemini key in URL query (`providers.dart:66`, D11/D16 → Stage 5); plaintext key-at-rest (D12 → Stage 5); actions pinned to mutable major tags (D10 → Stage 1 item 6); `store.ts` migration validates only top-level shape — web-is-a-live-target now (ADR-009): make deep-shape validation part of the Stage-3 web parity work.

**What is sound (verified, not assumed):** least-privilege CI with the write-token confined to the publish job; every `RELEASE_TAG` consumer validated before shell use and the regex charset forecloses shell metacharacters; the pwsh injection fixed; `flutter-test` gates every Flutter build; artifacts are same-run only — cross-run artifact poisoning remains closed; SHA256SUMS ordering and collision guard correct; the sed sanitizer proven against a fabricated PAT-bearing error; guard zero-false-positive state proven by replication; Android INTERNET adds no cleartext (no `usesCleartextTraffic`, targetSdk ≥ 28 default, HTTPS-only endpoints, no webview) and macOS adds client-only entitlement under default ATS; no address/SSN/ZIP fields exist in the return model at all, and no name-bearing field appears in any transmitted prompt; the v1.0.0 tag tree independently re-scanned — no token-shaped values; SDK hash claim consistent with the manifest.

## Roadmap assessment (security seat)

Stage-1 items 5-9 are the right hardening set and correctly ordered; they are largely *drafted-not-yet-verified* (workflow steps exist, no tag has run them). The gitleaks scan, action SHA pinning, caching verification, and dispatch dry-run (item 6) are the remaining trust anchors and must actually land — they double as coverage for Findings 3-4 class issues. Stage 2 correctly requires crash-safe/write-free/resource-bounded RE tools plus a no-binary-blob assertion. Stage 3 retains the parser-hardening requirement for the first shipped untrusted-input parsers — keep it non-negotiable, and add the web-store deep-shape validation there (Finding 8). Stage 4 keeps least-privilege Pages + security headers; Stage 5 keeps the key-header fix and disclosure-generated-from-behavior. The only roadmap gap from this seat: Stage 1 has no line item for the README web-figures sentence (Finding 1) — fold it into the "copy fixes" work.

## Verdict

**PROCEED-WITH-CONDITIONS**

Stage 1 may start. Conditions (all concrete and checkable):

1. **README privacy-default sentence fixed** for the web prototype (scope it to Flutter, or state the web copilot's always-attached summary; or ship the web figures toggle).
2. **Sanitize `check_unpushed`'s fetch stderr** through the same 0600 mktemp + sed path, with a script-owned failure message on fetch failure.
3. **Drop `-I` from both guard greps** (or equivalent binary coverage) so token-shaped strings inside tracked binaries refuse the commit.
4. **Reconcile `bun.lock`** with `package.json` (regenerate or delete; CI stays `npm ci` + `package-lock.json`).
5. **Land Roadmap Stage-1 items 5-7 with verification evidence**: gitleaks scheduled scan + action SHA pinning + dispatch dry-run of the hardened workflow merged; at the next tag, the release shows `SHA256SUMS.txt` among assets and the `npm ci`/typecheck/build path has run green at least once.

Non-gating, owner-side, re-affirmed: branch protection on `main` and a PAT expiry remain the standing recommendations already recorded in WORKFLOW §5 (risk knowingly accepted).
