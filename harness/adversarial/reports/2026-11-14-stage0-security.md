# ADV-SEC — Red Team / Security · Stage-0 review (2026-11-14)

Scope actually examined: full 11-commit history (`git log -p --all`, 3.8MB dump, pattern-scanned for ghp_/gho_/ghu_/ghs_/github_pat_/sk-*/AIza/AKIA/xox/npm_/glpat-/PEM blocks/password+Bearer literals/`://`-cred URLs), both tag trees (`v1.0.0^{tree}`, 341 files), the working tree including untracked `harness/` + `scripts/sandbox_backup.sh`, on-disk ignored dirs (`tool-results/`, `.zscripts/`, `download/`, `db/`, …), home dotfiles, `/tmp`, `.github/workflows/release.yml`, lockfiles (`bun.lock`, `pubspec.lock`), and the Flutter/Next key-handling code. The PAT was classified without printing it (fine-grained `github_pat_…`, ~108 chars incl. prefix).

## Findings

**1. [MAJOR] Shipped release APKs have no INTERNET permission — the advertised AI cascade is dead in release builds.**
Evidence: `clearfile/android/app/src/main/AndroidManifest.xml` contains no `<uses-permission>` at all; INTERNET is declared only in `clearfile/android/app/src/debug/AndroidManifest.xml:6` and `.../profile/AndroidManifest.xml:6` (debug/profile builds). The cascade performs direct HTTP from the app (`clearfile/lib/ai/providers.dart:66,179`) and is a headline README feature (README.md:71–91). Release Android builds therefore cannot open sockets → Gemini/OpenRouter calls fail; the 3 ABI APKs on the public v1.0.0 release carry a silently broken feature. It also inverts a privacy claim: "no telemetry" is currently true on Android release only *because* the network is missing — that must be a decision, not an accident.
Fix (Stage 1): either add `android.permission.INTERNET` to the main manifest **and** disclose the network behavior, or compile the AI UI out of Android release builds; document the choice on the release page.

**2. [MAJOR] Release integrity debt: debug-keystore signing, no checksums, no provenance, no release-page disclaimer.**
Evidence: `clearfile/android/app/build.gradle.kts:33–36` — "Signing with the debug keys for now" (fresh random debug key per CI runner → unstable, meaningless signature); `.github/workflows/release.yml` has **no** sha256/signing/provenance step anywhere; release notes are auto-generated from commits (`release.yml:236`), so the "demonstration only" wording is not guaranteed on the release page. Users side-load 8 binaries from a public release with no integrity anchor.
Fix: Stage 1's SHA256SUMS job step (generate into `flat/` before upload) + signing decision + explicit `body:` disclaimer. Sound here: `fail_on_unmatched_files: true`, and artifacts are same-run only (`download-artifact@v4` defaults to the current run) — cross-run artifact poisoning is **not** possible; `flutter-test` gates every Flutter build.

**3. [MAJOR] `sandbox_backup.sh` can report success while local ≠ remote, and backs up the wrong thing if HEAD isn't `main`.**
Evidence: `scripts/sandbox_backup.sh:35–38` — the clean-tree no-op path exits 0 **without** checking whether local `main` is ahead of `origin/main`; `:58` pushes the ref `main`, not HEAD; the preflight (`:17–30`) has no current-branch guard. Scenario A: run N's push fails transiently (exit 1, noted); run N+1 finds no file changes → prints "nothing to archive (tree clean)" → exit 0 → the operator-visible state is "backup fine" while the commit is unpushed; the recycle runbook then recovers with `git reset origin/main` (`harness/WORKFLOW.md:155`), **discarding** the unpushed commit. Scenario B: a session ends on a feature branch/detached HEAD → `git push origin main` pushes stale local `main`; that session's commits are never backed up, silently. With sandboxes provably recycling (already happened once, STATE.md:27), this is the backup rule's real failure mode, not the secret guard.
Fix: preflight asserts `git branch --show-current` = `main` (else exit 1 with message); the no-op path runs `git fetch origin` and asserts `[ -z "$(git log origin/main..main)" ]` (else exit 1 "unpushed local commits").

**4. [MAJOR] CI: workflow-wide `contents: write` + unpinned `npm install` = elevated blast radius for any dependency compromise.**
Evidence: `release.yml:15–16` grants `contents: write` to **every** job, including the npm-install job (`:194` `npm install` — not `ci`); no `package-lock.json` exists in the tree (only `bun.lock`, 328KB, which npm ignores) → each tag build resolves the dependency graph fresh from caret ranges, so the released web bundle is (a) not reproducible and (b) not the locally-audited graph. A malicious/typosquatted or newly-published version resolved at build time runs install lifecycle scripts inside a job holding a repo-writable token → can push to `main` or publish a poisoned release under this repo's name. Compounding: `next.config.ts` `typescript.ignoreBuildErrors: true` means the bundle is unvalidated at build time.
Fix: per-job permissions (only the `release` job gets `contents: write`; all others `contents: read`); commit a package-lock.json and switch to `npm ci` (or `bun install --frozen-lockfile`); keep the planned gitleaks job.

**5. [MINOR] Template injection pattern: `${{ github.ref_name }}` interpolated directly into a pwsh command.**
Evidence: `release.yml:122` (`Compress-Archive … clearfile-windows-x64-${{ github.ref_name }}.zip`) vs the safer env-var form used everywhere else (`:60–62, :94, :150, :176, :200`). Git ref names may legally contain `$`, backticks, `;`, `&`, quotes — the classic CI injection shape. Practical risk is bounded: ref names are set by actors with push/write access (today only the owner's PAT; trigger is tag-push + dispatch, **no fork-PR trigger** — verified, so untrusted-PR input cannot reach these blocks), and a PAT thief could edit the workflow anyway. Still the documented anti-pattern; free to fix.
Fix: use `$env:GITHUB_REF_NAME`; optionally guard asset naming to `^v[0-9][0-9A-Za-z._-]*$`.

**6. [MINOR] The `workflow_dispatch` naming bug is real and fails ugly.**
Evidence: on dispatch, `GITHUB_REF_NAME` = branch name; assets become `*-main.apk`; a branch containing `/` makes `cp` target a nonexistent subdir → `if-no-files-found: error` → red build; softprops without a tag tries to key a release off a branch ref. Roadmap Stage 1 already carries the fix (ROADMAP.md:37–38) — analysis confirms; keep it, plus reject dispatches from non-`v*` refs.

**7. [MINOR] All actions pinned to mutable major-version tags.**
Evidence: `release.yml` uses `actions/checkout@v4`, `subosito/flutter-action@v2`, `actions/setup-node@v4`, `actions/upload-artifact@v4`, `actions/download-artifact@v4`, `softprops/action-gh-release@v2` — tag-retarget or action-repo compromise ships into a release published under this repo's name. Fix in Stage 1: pin commit SHAs (with version comment). (Sound: `flutter-version: '3.47.9'` is pinned.)

**8. [MINOR] Gemini API key sent as a URL query parameter.**
Evidence: `clearfile/lib/ai/providers.dart:66` — `…generateContent?key=$apiKey`; the repo's own tooling already uses the header form (`scripts/ai_provider_tests.py:168` `x-goog-api-key`; `src/lib/ai/ladder.ts:163`). Query strings leak into logs, proxies, crash dumps. Fix: switch to the `x-goog-api-key` header.

**9. [MINOR] AI keys at rest in plaintext JSON — disclosed nowhere the user can see.**
Evidence: `clearfile/lib/ai/settings.dart:123–142` (`AiSettingsStore`, plain `writeAsString`); comment at `:68` says "stored only on this device" — accurate, but the *plaintext-on-disk* detail isn't user-visible. Acceptable for a demo if the Stage-5 disclosure states the exact file and format; consider `flutter_secure_storage` as a stretch goal.

**10. [NOTE] Secret guard coverage is narrow.**
Evidence: `scripts/sandbox_backup.sh:41` — only `github_pat_`, `sk-[A-Za-z0-9]{28,}`, `AIza…`. Misses classic GitHub `ghp_/gho_/ghu_/ghs_`, `sk-ant-`/`sk-proj-`, AWS `AKIA/ASIA`, Slack `xox`, `npm_`, GitLab `glpat-`, `BEGIN … PRIVATE KEY` blocks. Combined with `git add -A` staging **any** new non-ignored path (a future tool writing `dist/`, `reports/`, `*.log.1` — the ignore list is a curated blocklist of *known* scaffolding, not an allowlist), the guard is the only pre-publish tripwire. Fix: widen the alternation (one line) + the planned gitleaks CI job. Sound: the guard correctly scans the staged index (`git grep --cached`), refuses before commit, and exits with a distinct code 2.

**11. [NOTE] PAT lifecycle posture.**
Evidence: token is fine-grained (`github_pat_`), embedded only in `.git/config` remote URL — independently verified **not** present in any tracked file, any on-disk file (including ignored dirs, home dotfiles, `/tmp`), or the full git history. Residual risks: (a) WORKFLOW §5 does in-session `curl -H "Authorization: token …"` — if a session ever echoes that header into a *tracked* file (SESSION_LOG.md is tracked), the guard would catch a fine-grained token but **not** a classic one; (b) push stderr is written to `/tmp/sandbox_backup_push.err` under default umask (git usually redacts userinfo in error URLs — don't rely on it); (c) a fine-grained PAT with Contents:RW is effectively repo-admin (force-push, release mutation). Fix: set an expiry ≤90d, rotate at every sandbox recycle, record the policy in WORKFLOW §5; `mktemp` + `trap` + `chmod 600` for the err file.

**12. [NOTE] History/tag exposure is hygiene debt, not a credential leak.**
Evidence: `v1.0.0^{tree}` = 341 files incl. `.env` (one line: `DATABASE_URL=file:/home/z/my-project/db/custom.db` — local path only), `db/custom.db` (empty Prisma schema — strings show only User/Post DDL), `download/nitro_nissi` (unrelated app — license/IP issue for ADV-LEGAL), `tool-results/` (PDF-skill briefs), `tools/flutter` gitlink. My independent full-history scan found **zero** token-shaped values; every "key" string is UI instruction text or env-var-read code (`scripts/openrouter_explore.py:32`, `scripts/ai_provider_tests.py:88–89`). So the Stage-1 rewrite decision is **security-neutral**; if rewriting, never reuse the `v1.0.0` tag name (release identity must not silently change) — publish from a new tag and mark v1.0.0 legacy in the release body.

**13. [NOTE] Missing SECURITY.md; stale README reference.**
No vulnerability-disclosure channel exists; README.md:23 still advertises `download/` "pre-built release bundles" that df617e8 just untracked. Both are one-liners for Stage 1.

**14. [NOTE] Supply chain otherwise sound.**
`bun.lock`: all 947 URL references point to `registry.npmjs.com` (no exotic hosts); `pubspec.lock`: 72 hosted + 4 sdk, no git/path deps; Flutter runtime deps are four mainstream, maintained packages (`file_picker`, `path_provider`, `http`, `url_launcher`); nothing typosquat-shaped across package.json's ~60 deps.

## Roadmap assessment

- **Stage 1 (hardening & trust): right scope, needs additions.** Conditions below map here: per-job CI permissions, action SHA pinning, `npm ci` + committed lockfile, SECURITY.md, PAT policy, INTERNET-permission decision, release-body disclaimer, backup-script correctness fixes. The gitleaks-as-repo-hygiene-not-sandbox-cron distinction is correct reasoning. History rewrite: decide on hygiene/IP grounds with ADV-LEGAL; from the security seat it is not mandatory — no secrets exist in history.
- **Stage 2 (RE infrastructure): correct posture** (read-only Phases 1–3, no key material, no decryptors). Add one requirement: the format tools parse untrusted files — they should be crash-safe, write-free, and resource-bounded; keep the sample corpus out of the repo (owner-owned files only, as stated).
- **Stage 3 (bridges): TXF import and `.clearfile.json` migrations are this repo's first shipped untrusted-input parsers.** Engine parity tests won't cover malformed input — add parser-hardening tests (bounds, malformed fixtures, size caps) to the stage scope, else the stage ships an attack surface with parity tests only.
- **Stage 4 (platform reach):** the GitHub Pages workflow is a new permissions surface — keep least-privilege there too (`pages: write` + `contents: read`, nothing more); document the .aab as unsigned.
- **Stage 5 (AI hardening): the privacy disclosure must be generated from actual transmission behavior — which is currently undecided** (Finding 1). The disclosure text is different for "no network permission" vs "calls Gemini/OpenRouter with your key"; resolve Finding 1 first. Fold in the key-at-rest plaintext detail (Finding 9) and the URL→header fix (Finding 8). Prompt-injection tests: also cover provider-response snippets (blockReason/error text) that surface into UI messages.

## Verdict

**PROCEED-WITH-CONDITIONS**

Stage 1 may start only once these are applied (all are Stage-1-entry or Stage-1-scope items; each is checkable):

1. **Backup correctness patch:** `scripts/sandbox_backup.sh` preflight asserts current branch = `main` (else exit 1 with message); the clean-tree no-op path first runs `git fetch origin` and exits 1 ("local commits unpushed") unless `git log origin/main..main` is empty; push stderr goes to a 0600 `mktemp` file removed by `trap`. Check: script source + one simulated divergence/failure run showing exit 1.
2. **Secret-guard widening:** the `PATTERNS` line adds `ghp_|gho_|ghu_|ghs_|sk-ant-|sk-proj-|AKIA[0-9A-Z]{16}|xox[baprs]-|npm_[A-Za-z0-9]{30,}|glpat-|BEGIN [A-Z ]*PRIVATE KEY`. Check: grep of the pattern line + staged-fixture refusal test.
3. **CI least-privilege + injection hygiene:** `contents: write` moves to the `release` job only; `release.yml:122`'s `${{ github.ref_name }}` becomes env-var access; the workflow_dispatch naming bug is fixed (asset naming only for `v*` refs). Check: yaml diff.
4. **Release integrity:** a step generating `SHA256SUMS` into `flat/` before upload; an explicit release `body:` carrying the demo disclaimer; the Android INTERNET-vs-AI-cascade conflict resolved (permission + disclosure, or cascade compiled out of release builds). Check: workflow diff + next release asset list.
5. **Web build reproducibility:** commit `package-lock.json` and switch CI to `npm ci` (or `bun install --frozen-lockfile`). Check: lockfile tracked + workflow diff.
6. **PAT policy recorded:** WORKFLOW.md §5 documents the fine-grained PAT's granted permissions plus rotation rule (rotate at every sandbox recycle or ≤90 days; immediate rotation if ever echoed in a transcript); owner attests an expiry is set. Check: WORKFLOW.md §5 text.

Owner-side recommendation (not gating, unverifiable from this sandbox): enable branch protection on `main` (at minimum, reject force-pushes from non-owner actors) so the PAT is not the only guard on history integrity.
