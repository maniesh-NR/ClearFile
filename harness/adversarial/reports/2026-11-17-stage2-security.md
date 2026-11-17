# ADV-SEC — Stage-2 entry gate review (2026-11-17)

*Filed near-verbatim from the independent reviewer's returned report (Task ID 3-a; isolated context; ran concurrently with the other three reviewers, none of which it saw).*

## Verification log

**Full-history secret scan (mandate-required, my own run).**
`git cat-file --batch-all-objects --batch-check` → **662 unique blobs** in the
local object DB (includes the dangling mode-amend trees and pre-recycle
unreachable objects). Every blob regex-scanned for `ghp_/gho_/ghu_/ghs_/ghr_/
github_pat_`, `AKIA…`, `AIza…`, `sk-or-v1-…/sk-proj-…`, `npm_…`, `glpat-…`,
`xox[baprs]-…`, PEM/OPENSSH private-key headers, credentialed
`postgres|mysql|mongodb://user:pass@`, `DATABASE_URL=…://`,
`x-access-token:<alnum>`, `Authorization: token <alnum>`,
`Authorization: Bearer <alnum>`. **Zero real-token hits**; the only matches are
documentation placeholders (`WORKFLOW.md` §4/§5's literal `x-access-token:<PAT>@`
and `Authorization: token …` ellipsis forms). Pre-hygiene history re-inspected
at `df617e8^`: `.env` = `DATABASE_URL=file:/home/z/my-project/db/custom.db`
(no credentials), `db/custom.db` (24 KB Prisma), `download/nitro_nissi/` (the
owner's earlier app), 3 tracked `tool-results/*.txt` blobs (flutter manifest
JSON + two skill-brief texts — benign, untracked at `df617e8`), plus 2
unreachable local-only gzip blobs (old flutter-web / nextjs-standalone build
tarballs). Untracked disk scan (excl. `.git/`, `node_modules/`) for PAT-shaped
strings: **none**. `.git/` audit: no credential helper, no `.git/credentials`;
token-shaped content in exactly one file — `.git/config`'s `remote.origin.url`
(the documented PAT home; not printed, not used).

**CI posture read (mandate-required, my own run).** `.github/workflows/hygiene.yml`
+ `release.yml` read in full: no `pull_request`/`pull_request_target` trigger
anywhere (grep: 0 hits — zero fork/PR CI surface); `permissions: contents: read`
workflow-wide in both, `contents: write` only on the release job
(release.yml:487-488); `timeout-minutes` on every job (3 in hygiene, 9 in
release); SHA-pinned actions — **all 7 `uses:` lines are 40-hex SHAs** and I
resolved every one live against upstream tags via `git ls-remote`:

- `actions/checkout@11d5960a…` = v4.4.0 ✓ · `gitleaks/gitleaks-action@ff98106e…` = v2.3.9 ✓
- `subosito/flutter-action@1a449444…` = v2.23.0 ✓ · `actions/setup-node@49933ea5…` = v4.4.0 ✓
- `actions/upload-artifact@ea165f8d…` = v4.6.2 ✓ · `actions/download-artifact@d3f86a10…` = v4.3.0 ✓
- `softprops/action-gh-release@3bb12739…` = v2.6.2 ✓

gitleaks `fetch-depth: 0` (full history, hygiene.yml:32); `RELEASE_TAG` guarded
by `^v[0-9][0-9A-Za-z._-]*$` (no shell metacharacters possible) in all 7 guard
copies, used via env-var only (the one pwsh step interpolates `$env:RELEASE_TAG`
inside a quoted string, release.yml:275); tag guard fail-closed on
non-missing-ref fetch errors; artifact flatten has a name-collision guard;
`SHA256SUMS` over the whole flat dir; `fail_on_unmatched_files: true`.

**Live release/CI checks (public HTML + `git ls-remote` only — I never touched
api.github.com, so no rate-limit issue to report).** `git ls-remote origin`
→ `main` = `a18b160…` (= local HEAD), `v1.0.1` → exactly `0bbb564…`,
`v1.0.0` → `a121f11…`. Release page HTTP 200; v1.0.1 assets = 11 incl.
`SHA256SUMS.txt`. Downloaded `SHA256SUMS.txt` live and two assets:

- `reverse-engineering-protocol.md` sha256 `fbb79326…` == SHA256SUMS entry == blob at tag `0bbb564`;
- `blueprint.pdf` sha256 `4e200c1618…` == entry == tagged-tree blob —
  the checksum chain verified end-to-end for the second gate in a row.

Hygiene runs on `a18b160` verified via run pages 43713252346 (push) and
43872210841 (weekly), both "completed successfully".

**Mode-only amend resolution.** Reflog shows `HEAD@{0}: reset: moving to a18b160`, `HEAD@{1}: commit (amend) 4d4e1d6`. `git diff --stat a18b160 4d4e1d6` → **191 files changed, 0 insertions(+), 0 deletions(-)**; `git diff --raw` → all `100644→100755` with identical blob SHAs. Content-identical, mode-only — confirmed.

**Local suite re-runs (all mine).** `flutter analyze` — No issues found; `flutter test` — **+111: All tests passed**; `npx tsc --noEmit` — exit 0; `python3 scripts/verify_golden_fixtures.py` — 16 fixtures, 0 field failures; `node scripts/web_parity_test.mjs` — 16/16; `node scripts/txf_taxfile_test.mjs` — 10/10 groups; `bash scripts/harness_check.sh` — 12 ok lines, 0 failures.

**Supply chain.** `package-lock.json` (335 KB) committed + `npm ci` in CI; `clearfile/pubspec.lock` committed; SDK fetcher (`scripts/fetch_flutter_sdk.sh`) verifies the tarball sha256 against the official manifest *before* unpacking. `npm audit` run live today: **32 advisories — 2 critical, 19 high, 9 moderate, 2 low** (see SEC-1).

**New Stage-3 untrusted-input parsers read.** `clearfile/lib/io/txf_import.dart` (5 MB / 10k records / 4096-char caps at :68-70), `clearfile/lib/io/tax_inspect.dart` (read-only; EOCD tail-scan; 4096-entry cap at :246; every offset bounds-checked — :249, :265, :271; STORE-only extraction, DEFLATE listed only → no zip-bomb path; no writes), `return_format.dart` (version guard + sealed outcomes), `src/lib/files/taxfile.ts` (same 4096-entry cap at :206). AI key at rest: web localStorage (disclosed, settings.tsx:259) and Flutter settings file (disclosed) — D11/D12/D16 Stage-5 debt stands; Google key still in URL query (providers.dart:67, D11).

## Findings

**SEC-1 [MAJOR] — Live dependency advisories in the shipped web bundle's dependency tree, including two criticals.** `npm audit` today: `next 9.3.4-canary–16.4.0` (critical: request-smuggling in rewrites GHSA-ggv3-7p47-pfv8; RSC deserialization DoS GHSA-h25m-26qc-wcjf; image-cache growth GHSA-3x4c-7xq6-9pq8) and `next-auth ≤4.24.14` (critical, but no auth routes are actually used — scaffold dep); high: `zod <4.6.6` (memory exhaustion), `brace-expansion` DoS chain, `browserslist` OOM, `deepmerge-ts`, `@babel/core` arbitrary-file-read, etc. Exploitability against *this* app is low (no rewrites/auth/RSC image optimizer in use), but `clearfile-web-standalone-*.tar.gz` is a self-hostable Node-server release asset users download, and CI has no dependency-vulnerability gate (Dependabot remains owner-side, D30, still not enabled). Fix: `npm audit fix` (non-breaking per npm) + lockfile refresh before the NEXT tagged release; add `npm audit --omit=dev --audit-level=critical` to `hygiene.yml` (failing) or record Dependabot enablement. Not a Stage-2-entry blocker — it gates the next *release*, and the scaffold-heavy dep list (dnd-kit/mdxeditor/prisma/recharts…) is trimmable later.

**SEC-2 [MINOR] — An unlogged 2026-11-16 session left an unpushed mode-only amend (4d4e1d6); the reset resolution is sound but the session is absent from the record.** The resolution itself: correct — HEAD == origin/main == a18b160, zero content delta (log above), tags untouched, and leaving the amend would have tripped the backup script's unpushed check. But `SESSION_LOG.md`'s last entry is 2026-11-15 and `harness_check.sh` cannot see a session that left nothing unpushed. A governance blind spot of exactly the class the harness exists to close. Fix: an append-only dated note in SESSION_LOG (this gate's record or next teardown) recording the anomaly and its resolution. Checkable: `grep '2026-11-16' harness/memory/SESSION_LOG.md`.

**SEC-3 [MINOR] — `scripts/fetch_flutter_sdk.sh:64` aborts on the sandbox's benign tar failure.** Under `set -euo pipefail`, tar's trailing directory-status-restore error (this snapshot FS) now kills the script *after* extraction but *before* the smoke test/OK line — the SDK is installed and verified-integrity yet the fetcher reports failure (availability noise, and a fail that trains operators to ignore failures). Integrity is NOT weakened (sha256 verified at :61 before unpack). Fix: tolerate tar's exit status after a verified checksum (e.g. `tar -xJf … || echo "fetch_flutter: tar warned (benign on this FS)"`), keeping the checksum strict.

**SEC-4 [NOTE] — PAT posture carried (D30), now with one more observed fact.** Token: fine-grained, broader than recorded (Actions write observed 2026-11-14, WORKFLOW §5), unrotated by owner decision, lives only in `.git/config` — re-verified today across 662 blobs, tracked tree, and untracked disk (zero leakage anywhere). The 2026-11-16 amend proves sessions still happen outside the log; the PAT remains the sole guard on history integrity (branch protection still owner-side). Re-affirm D30; at the next owner touchpoint: enable Dependabot alerts, branch protection on `main`, and set PAT expiry on rotation.

**SEC-5 [NOTE] — Release integrity posture re-verified end-to-end (see log).** Unsigned binaries remain the disclosed posture (release body + SECURITY.md:33-38); SHA256SUMS + tag-SHA guard + target_commitish + collision guard + fail_on_unmatched_files hold. D29 (tag-PUSH trigger verification) still owed at the next tagged release. Optional future hardening: keyless cosign provenance — not warranted for a demo.

**SEC-6 [NOTE] — History-integrity of the pre-hygiene era re-confirmed benign.** No secrets; `.env` local-only; `tool-results/*.txt` blobs benign. But the fact that `tool-results/` files were *accidentally tracked* in 2026-11-03 commits is direct, in-repo evidence that the "agent artifact lands in a tracked path" accident class is real — the Stage-2 RE-corpus conditions (enumerated + gitignored fixture paths BEFORE tooling) are therefore empirically justified, not theoretical.

**SEC-7 [NOTE] — Stage-3's new attack surface is well-hardened.** TXF import, `.tax` inspection, and the return-format codec are caps-bounded, bounds-checked, write-free where feasible, refuse-and-report on unknowns, and pinned by 11+7+14+2 tests + the CI bridge suite. The `tax_inspect.dart` ZIP reader cannot be zip-bombed (STORE-only, sizes clamped to actual file length) or path-traversed (names are only stringified, never used as paths).

**SEC-8 [NOTE] — `bun.lock` still reappears on disk (recycle scaffolding) but is gitignored (/bun.lock, .gitignore:91) — D26 holds.**

## Agenda answers

**1. Stage-3 closure: YES — close it.** Every ROADMAP Stage-3 scope item has execution evidence I verified myself, not just by record: 16 IRS-pinned golden fixtures (fixtures/tax/, oracle 16/16), web parity (16/16 first-run, under budget), TXF import + `.tax` inspection + exporter fix (bridge suite 10/10, hardened parsers per SEC-7), unified return format with version guard and sealed outcomes (ADR-015; 14+2 Dart tests, my run 111/111), engine.md/tour.md/discrepancy templates/DoD (present; harness_check green). The security-relevant residuals are all ledgered (D11/D12 AI-side → Stage 5; D27/D28; D29 next release; D31 documented simplifications). Nothing blocks closure.

**2. Parity tripwire (mandatory): recommend WEB-FREEZE-AT-PARITY-COMPLETE.** The slip fired; the box didn't. Argued explicitly: the parity work's value is now *banked* (both engines run the same 16 IRS-pinned fixtures in CI — the silent-divergence risk ADR-009 closed stays closed), so continued *feature* parity buys little: every future parameter change (TY2026…) costs two engine edits for zero added correctness, and ADR-014's shared Rust core makes the TS engine a transition artifact — more sessions on it are sunk cost. Security adds its own weight: two parallel untrusted-input parser sets (`clearfile/lib/io/` + `src/lib/files/`) is a doubled hardening surface (today covered by the bridge suite, but every new format feature re-doubles it). Disposition: freeze the web *engine's* feature scope at parity-complete (bug/security fixes only; the prototype stays as the CI-visible golden-fixture consumer and study artifact); the Flutter app remains the reference implementation until the Rust core lands. The owner may keep parity via ADR-009 prerogative — but as a recorded decision at this gate; my condition 4 makes silence impossible.

**3. Native re-platforming settlement (ADR-014 open questions):** (i) **Staged per-OS, never big-bang**: extract the Rust core first and validate it against the existing golden fixtures (they are engine-agnostic JSON — the corpus already exists); the Flutter app stays the transition vehicle and umbrella UI until the last native stack is feature-complete, then retires with a final tagged release. (ii) **New stages appended after the current pipeline (Stage 7 "Rust core", Stage 8 "per-OS native UIs"), NOT absorbed into existing stages**: Stage 2 is boxed at two sessions and already re-sequenced once — loading a re-platform into it would wreck the time-box discipline this repo just proved. Budget: the same box+tripwire discipline (2 sessions core; ~2 sessions per OS stack, slip → next gate). Stage 4 (Pages deploy of the *Flutter* web build) stays before it — it is cheap and the Flutter build is the deployable artifact until native exists. (iii) **Core scope boundary: 1040 engine + format codecs (TXF both ways, `.clearfile.json` codec, `.tax` inspection, MD3-from-seed tonal palette generation) — explicitly EXCLUDE persistence (filesystem stays per-platform; core is codec-only, pure functions) and EXCLUDE the AI cascade (HTTP + key custody in the core would concentrate secrets and network into the most-consumed component; Stage-5 hardening stays per-platform)**. This keeps the core small, pure, and fuzzable with the fixture corpus. (iv) **One FFI seam: a flat C ABI (cbindgen-generated header) consumed by Win32/Direct2D C++, Android JNI, and Swift (via the same C header in an SPM target); Linux links the Rust crate directly** — one audit surface, three consumers by contract. The C ABI boundary is the new unsafe seam: fuzz it with the fixtures + malformed inputs. (v) **macOS tiers: deployment target macOS 13 (Ventura) with AppKit-primary; SwiftUI allowed opt-in on ≥14 (Sonoma)** — "older" = 11–12 unsupported, "newer" = 14+. (vi) **Linux line: Slint for modern (Wayland/X11, no system-toolkit dependency — smallest supply chain), gtk3-rs for the legacy tier (RHEL 8/9-era GTK3); Qt only if a hard requirement appears (drags a large C++ runtime)**. (vii) **Kotlin Multiplatform: Android-only** — a second KMP target adds a third runtime for zero core value; no iOS target exists in the owner's matrix. (viii) **v2.0.0: yes** — new stacks, new core, new packaging is a user-visible architecture change; the `.clearfile.json` envelope (unchanged format, version guard) is the compatibility anchor that makes the major bump safe. (ix) **ADR-009 disposition: retire into "one core, many shells"** once the Rust core serves every platform (web via WASM included) — engine divergence becomes impossible by construction and the TS engine is a compilation target, not a second engine. Until that day, if parity is kept, the both-engine golden-fixture CI (already in place) is the enforcement.

**4. Placement ADR-012: IN-REPO — upgraded from "mild" to firm, with mechanical conditions.** New facts move me, not away: Ghidra feasibility is *measured* in this sandbox (12.1.4+JDK21, 11 s/417 MiB — docs/ghidra-sandbox-feasibility.md), so Phase-4 tooling runs where this repo's backups already run; the safe bridges are already shipped app features here; and a separate repo must first replicate pinning/gitleaks/harness posture (the split's honest cost) before hosting anything. The counter-risk — the auto-publish-everything-tracked backup posture — is real and *proven* (SEC-6: `tool-results/` was accidentally tracked once), but it is exactly what the conditions make mechanical: (a) corpus fixture paths ENUMERATED + gitignored *before* tooling lands (a dedicated `fixtures/re/` synthetic dir is the only committable one; `tools/re-corpus/`-style paths for owner-authored licensed files, never tracked); (b) the no-binary-blob assertion runs in `hygiene.yml` and distinguishes **synthetic** (program-generated, committed, provenance header in each generator) from **owner-authored** (never committed; specs cite hash+provenance only); (c) resource caps + refusal tests; (d) tools are write-free and never wired into release.yml; (e) §7's per-spec checklist stays the policy layer, the backup hex-guard the backstop.

**5. DoD fix: N = 4 published `docs/formats/*.md` specs, two-working-session hard time-box.** Matched to the *guaranteed* corpus, not the aspirational one: (1) `clearfile-json.md` — this repo's own envelope, full spec authority, zero provenance risk; (2) `tax-exchange-container.md` — the `.tax`-extension exchange container this repo itself writes; (3) `txf.md` — the published v042 spec assembled with this repo's round-trip experience (the implemented bridge becomes the verified-by evidence); (4) `tax-modern.md` — the 2017+ Intuit container *shape* per the public write-up, verified against owner-authored files by hash, crypto by existence only (§7.3). The mid-1990s legacy `.tax` is a declared stretch goal explicitly NOT counted in N (owner-authored corpus unverified). Checkable at the Stage-2 exit gate: `ls docs/formats/*.md | wc -l` ≥ 4 + ≤ 2 session-log entries labeled Stage-2. If the owner attests a larger licensed corpus, N stays 4 — the DoD must be satisfiable by the repo's own data.

**6. RE tooling security contract (SEC-1 carried) — recorded here as the binding spec Stage-2 execution implements:** (a) any new workflow/job follows the repo posture — `permissions: contents: read`, `timeout-minutes` ≤ 30, SHA-pinned actions resolved against upstream tags, no `pull_request_target`/fork surface, no secrets; (b) tooling is **write-free** (reports to stdout/harness only; no writes outside gitignored build dirs, `.parity-build` precedent) and **resource-bounded** (size cap ≤ 5 MB default, 4096-entry cap, CI timeout as wall-clock backstop; the Ghidra envelope stays 1 GB heap — bench-only); **crash-safe** with refusal tests (oversize, too-many-entries, malformed input each produce a report line, never a hang or partial write); (c) tooling is **never wired into `release.yml` artifact paths** — the release pipeline stays sealed; (d) fixture paths stay **gitignored and enumerated**, with the synthetic/owner-authored provenance distinction executable in CI; (e) verification at the Stage-2 *exit* gate is by reading the tool code and tests, not assertion (per the carried condition).

## What is sound

The entire security spine, re-verified with my own hands: full-history (and dangling-object) secret cleanliness; a genuinely hardened CI posture (verified pins, least privilege, timeouts, no fork surface, fail-closed tag guard in all seven copies); a live-verified release integrity chain (tag→commit exact, checksums byte-matched to the tagged tree); confined PAT placement; the Stage-3 parsers as a model of bounded, write-free, refuse-and-report untrusted-input handling; the version-guarded unified format that closes D1/D3; an honest SECURITY.md; and a harness self-check that passes 12/12 with nothing unpushed. The tripwire honesty (box not exceeded, slip admitted and agenda-escalated) is also sound — the process did exactly what it was designed to do.

## Verdict

**PROCEED-WITH-CONDITIONS** — nothing blocks Stage-2 entry; the conditions below are concrete and checkable:

1. **Dependency fix before the next tagged release** (SEC-1): `npm audit fix` applied and refreshed `package-lock.json` committed, AND either a failing `npm audit --omit=dev --audit-level=critical` step in `hygiene.yml` or a recorded owner-side Dependabot enablement. Checkable: lockfile commit + the CI step's presence (grep) / audit output showing 0 criticals.
2. **Record the 2026-11-16 anomaly** (SEC-2): append-only SESSION_LOG note covering the unlogged session and the `4d4e1d6`→`a18b160` reset resolution. Checkable: `grep '2026-11-16' harness/memory/SESSION_LOG.md`.
3. **Stage-2 tooling implements the security contract verbatim as recorded in Agenda answer 6** (fixture paths enumerated + gitignored *before* tooling lands; CI-checkable no-binary-blob assertion with the synthetic/owner-authored distinction; write-free + caps + refusal tests; no release.yml wiring; read-permissions + timeout + SHA pins in any new job). Checkable: `.gitignore` diff, `hygiene.yml` assertion job, tool tests present, `grep -r 're_' .github/workflows/release.yml` empty.
4. **The web-freeze question is decided in writing at this gate — no silence** (Agenda 2): CONSENSUS/DECISIONS must record either freeze-at-parity-complete (my recommendation) or continued parity under ADR-009, with the both-engine CI enforcement named. Checkable: grep the gate record for the disposition.
5. **ADR-012 (placement) + the ADR-014 settlement + DoD N=4/two-session box are recorded before any tooling or native-stack code lands.** Checkable: `grep ADR-012 harness/memory/DECISIONS.md`; ROADMAP Stage-2 agenda resolved; no `docs/formats/` or native-stack commits predate them.
6. **`scripts/fetch_flutter_sdk.sh` tar-tolerance fix** (SEC-3): checksum stays strict, tar's benign trailing failure no longer aborts the script. Checkable: grep the `|| ` tolerance line at scripts/fetch_flutter_sdk.sh:64.
