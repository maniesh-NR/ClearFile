# Stage-2 EXIT gate — ADV-SEC report (2026-11-28)

**Reviewer:** ADV-SEC (standing adversarial panel, isolation)
**Scope:** delta since the last convened gate (the N6 exit, 2026-11-27; tip at review start `1ccfa43`, delta = `8b5c553` + `02d7289`) plus the five named risk surfaces in the gate agenda.
**Method:** every finding below carries file/line or command-output evidence; no assumptions. All scripts/commands named were run by this reviewer in this sandbox.

---

## Findings

### 1. `docs/formats/tax-modern.md` — clean of crypto key material; lint green in both scopes; "by existence only" honored

- **Lint (the mechanical backstop):** `python3 scripts/lint_format_specs.py --scope all` → `lint_format_specs: 11 file(s) clean`, exit 0 (covers all four `docs/formats/*.md` + all six `docs/re-research/*.md`, with the recorded `corpus-manifest.md` known-hash exemption, `scripts/lint_format_specs.py:39,88-94`). Default scope: `4 file(s) clean`, exit 0. The 4 named DoD specs are present: `clearfile-json.md`, `tax-exchange-container.md`, `txf.md`, `tax-modern.md`.
- **Independent key-material scan (not just the lint):** I scanned the whole delta for `[0-9a-fA-F]{32,}` hex runs and ≥40-char base64-like runs. `tax-modern.md` and all re-research notes: **zero hits**. The only ≥32-hex hits in the delta are the pre-existing third-party action pin SHAs in `.github/workflows/release.yml` (e.g. `actions/checkout@11d5960a…`, `actions/upload-artifact@ea165f8d…`) — supply-chain pins, not crypto material, and none added by this delta (verified below, finding 4).
- **Key/IV values absent:** the spec's crypto section states the class only — "AES-CBC using 16-byte (128-bit) keys … different keys … per tax year and embedded in the TurboTax binary. The key/IV VALUES are published in the write-up and are deliberately NOT recorded here or anywhere in the repo" (`docs/formats/tax-modern.md:67-73`). The public write-up is cited by name/URL (`tax-modern.md:15-17`), not reproduced. The only "key" arithmetic anywhere in the delta is the pre-existing ISSetupStream transport obfuscation whose "key" is the record's own public filename field — recorded since T2 session 3 (`docs/re-research/2026-11-23-tt-t2-session3.md:44-52`, incl. the 4-byte mask `13 35 86 07` at line 48) and explicitly ruled a format fact, not key material; the T3 chase record re-states it with the same §7.5 posture (`docs/re-research/2026-11-28-tt-t3-session2.md:113-115`). No *new* material class enters the repo with this delta.
- **"By existence only" honored:** per-year keys described as a class fact (§2); engine-module anchors at identifier level only, with the no-ole32 cross-check and the explicit unresolved password-mechanism question (`tax-modern.md:114-134`, §5 honest limits `136-150`). The spec's own §7.5 checklist is recorded at the end (`tax-modern.md:164-175`) with the manual ≥32-hex scan claim — which my independent scan confirms.
- **No decrypted content committed anywhere in the delta:** the delta (`git diff --name-status 1ccfa43..HEAD`) contains only text files (`.md`, `.py`, `.sh`, `.yml`, README). No binary, no archive, no quoted decode output; the decode artifacts are console-printed counts/closures only (see finding 2). `python3 scripts/check_binary_blobs.py` → `clean — 465 tracked files, 28 allow-listed own binaries, no other binary blobs`, exit 0.

### 2. The falsification claim is mechanically verified — I reproduced both Z_STREAM_END closures myself

- **Script/technique correspondence to the recorded path:** the bench scripts (gitignored — `git check-ignore` → `.gitignore:105 /tools/`) implement exactly the recorded layers:
  - outer container magic `48 12 90 BF 49 FF 91 AA` scanned from `0x99000` (`tools/re/tt3_chase2.py:101`, `tt3_stream.py:33-45`) = the T2 session-2 record (`docs/re-research/2026-11-22-tt-t2-session2.md:22`);
  - installer entry located by name, chunk-stream inflated in memory (`tt3_stream.py:50-78`) = T2-s2:78;
  - ISSetupStream header validation (14-byte magic + u16 version 7|8 + u32 generation 4 + 26 zero bytes = the recorded 46-byte header, `tt3_stream.py:81-89`, `tt3_chase2.py:159-167`) = T2-s3:23-30; the USA header lands at inflated offset `0x198c00`, matching the recorded PE raw end (`2026-11-22-tt-t2-session2.md:85`); the CAN v7 header lands at `0x14ae00` (T2-s3 framing; reproduced live, below);
  - v4 record table with the session's byte-derived offsets — `dsize u32 @+0x0A`, `u16=1 @+0x16`, name @+0x30 (`tt3_stream.py:92-99`, `tt3_chase2.py:169-187`) — a *correction* of the T2-s3 prose's ambiguous field boundaries, consistent with that note's own erratum pattern (`2026-11-23-tt-t2-session3.md:66-74`);
  - the variant-A cipher in code — `out[i] = SWAP[enc] ^ mk[((phase0+i) % 1024) % keylen] ^ 0xFF` (`tt3_stream.py:22-27`) — is algebraically identical to the recorded `plain = ~(swapnib(enc) ^ maskedKey[(p mod 1024) mod keylen])` (T2-s3:50), since `x ^ 0xFF = ~x`;
  - zlib inflate of the decrypted stream.
- **Empirical reproduction (I ran both, read-only):**
  - `python3 tools/re/tt3_stream.py` → 8-record inventory printed byte-matching the recorded inventory (T2-s3:78-83: splash 5,976; ini 4,690; prq 673; VC_redist 18,479,851; prq 749; isc 1,585; **MSI 383,877,541**; Setup.ini 1,593), then **`Z_STREAM_END at input 383877541 (383.9 MB): output 390117376 = 0x1740b800, unused=0`** — input exactly dsize, output exactly the T2-s3 recorded size (`2026-11-23-tt-t2-session3.md:105-106`). The claimed numbers (`2026-11-28-tt-t3-session2.md:66-68`) are exact.
  - `python3 tools/re/tt3_can.py` → 7-record inventory matching T2-s3:88-95, v7 header at `0x14ae00`, then **`Z_STREAM_END at input 246582748: output 251319296 = 0xefad400, unused=0`** — matching the record (`2026-11-28-tt-t3-session2.md:70-78`). The decode runs clean *through* 0x24000 (input 0x24000 = 147,456 ≪ 383,877,541) — the "divergence" does not exist; the falsification stands.
- **Retention-free / read-only verified, not assumed:** all three scripts contain no file-write, delete, or rename operations (read of source reviewed in full; only `open(..., "rb")`/`read`/in-memory buffers). I sha256-pinned the scripts before each run (`sha256sum tools/re/tt3_*.py`) and re-verified after (`OK` × 4), and `find tools -newer <pin>` returned nothing — **zero bytes written to disk by the bench**. The corpus lives in gitignored `tools/re-corpus/` (4 installers present, ignored per `.gitignore:105`); scripts open it read-only.
- **Premise provenance checks out:** the falsified "0x24000" premise is genuinely recorded where the record claims (e.g. `harness/memory/SESSION_LOG.md:1612,1932,2646`, `harness/memory/STATE.md:51`), and the new record disposes it with an identifiable artifact class (field-offset misalignment shifting the decode window) rather than hand-waving.

### 3. D46 rework commit `8b5c553` — release.yml changes are sound; the fail-closed guards are genuinely fail-closed; confinement is true; the harness_check flip is correct with one (unreachable-in-practice) blind spot

- **No new third-party action pins:** the release.yml diff is a single region (50 added lines, `.github/workflows/release.yml:561-620`); the only added steps use `run:` and a `node -e` heredoc. The only `uses:` lines in the diff are *context* lines (pre-existing pinned `actions/checkout`/`setup-node`/`upload-artifact`). `rustc`/`rustup` are the GitHub-hosted runner's preinstalled toolchain, consistent with the comment at `release.yml:572-574` and the hygiene suites job's recorded pattern.
- **No secrets; permissions unchanged:** the diff touches nothing above line 560; top-level `permissions: contents: read` (`release.yml:47-48`) and the release job's `permissions:` block (`release.yml:639`) are untouched; no `secrets.*` reference added.
- **Fail-closed rustc guard — I tested it:** extracted the exact guard lines (`release.yml:578-588`) into a sandbox harness with stubbed `rustc` binaries:
  - `rustc 1.94.9` → **exit 1 (refuses, below floor)**;
  - `rustc 1.95.0` → exit 0;
  - `rustc 1.9x.0` → **exit 1 (unparsable minor refused by the `case *[!0-9]*` patterns, `release.yml:582-583`)**;
  - missing `rustc` (command-not-found, empty `LINE`) → **exit 1**.
  The guard refuses on every error path before any build runs.
- **Import-empty guard fail-closed:** `new WebAssembly.Module(...)` throws on a corrupt/invalid file (node exits non-zero), and a non-zero import count exits 1 explicitly (`release.yml:594-604`).
- **Bundle tar-listing assertion fail-closed — I tested both ways:** a tarball *containing* `standalone/public/clearfile-core.wasm` → `grep -F` matches → passes; a tarball without it → `grep -F` finds nothing → the `|| { … exit 1 }` branch fires (`release.yml:609-618`). A failed/short `tar tzf` produces no matching output and likewise refuses. The `cp`-then-`test -f` pair (`release.yml:591-592`) catches a missing build output; `public/` exists in the checkout (`public/logo.svg`, `public/robots.txt`), so the copy target is real.
- **Confinement claim true:** all `cargo|wasm|rustup|clearfile-core` references sit at `release.yml:565-618`, strictly inside the `nextjs-web` job (job at `:498`, next job `release:` at `:628`). The committed guard's own counts reproduce: OUTSIDE=0, INSIDE=6.
- **harness_check flip (`scripts/harness_check.sh:90-104`) — defeat attempts:**
  - *Named scenario — a cargo reference inside ANOTHER job's step:* caught. I injected `      - run: cargo smuggled-build` into the `release` job of a copy; OUTSIDE=1 → the guard fails it. Correct.
  - *Dotted job-name escape:* renaming a job to `release.web:` (dot in the ID) breaks the boundary regex `^  [A-Za-z0-9_-]+:$` (`harness_check.sh:96-97`): the cargo line was attributed to the previous job's state — OUTSIDE=0, guard passes. **However, GitHub Actions job IDs cannot contain dots**, so this is unreachable in a workflow Actions would accept — a theoretical, not practical, blind spot.
  - *Reachable-but-contrived blind spot:* a job line with trailing whitespace or a trailing comment after the colon (e.g. `  release: # publish` — valid YAML) would also fail to match the boundary regex and inherit the previous job's state. The guard is a heuristic over a reviewer-attended artifact (the workflow diff is read by gates), so this is an observation-level hardening item, recorded as condition 3 below.
  - The old N1 form (zero references anywhere) is genuinely *narrowed*, not silently lifted: the failure branch now names the confinement requirement (`harness_check.sh:98-104`), matching the D46 record.
- **README row updated truthfully:** `README.md` src/ row now states the release lane ships the wasm boot asset and retains the D45 LICENSES-at-first-tag rider (`git show 8b5c553 -- README.md`).

### 4. Records consistency (DECISIONS / ROADMAP / CONSENSUS / DEBT) — the four layers agree; two memory-layer sync gaps remain

- **The four records tell one consistent story:** DECISIONS.md "Owner rulings recorded 2026-11-28" (`harness/memory/DECISIONS.md:878-915`, uncommitted working tree): option (a) — T3 session 2 FUNDED (the 0x24000 chase + `tax-modern.md`, D42); D46 DISCHARGED same day; T4 FUNDED strictly behind its own entry gate. ROADMAP.md carries matching **FUNDED 2026-11-28** entries for T3 (`harness/memory/ROADMAP.md:870-875`) and T4 (`:882-886`) with the namespace rule intact. CONSENSUS.md's "2026-11-28 · The owner's terminal-gate rulings" entry (`harness/adversarial/CONSENSUS.md:2448-2465`) restates all three rulings and cross-references DECISIONS. DEBT.md's D46 row is flipped to **DONE 2026-11-28** with the verification record (`harness/memory/DEBT.md:230`, committed in `8b5c553`) and correctly preserves D45 as still owed.
- **Gap A — the rulings are not committed:** the DECISIONS/ROADMAP/CONSENSUS updates are working-tree-only (`git status` shows `M` on all three + PROJECT_MEMORY.md). Consistent with this repo's session-close commit pattern, but the exit gate's own decision record must not stay untracked.
- **Gap B — the falsified premise is still live in STATE.md and SESSION_LOG has no 2026-11-28 entry:** `harness/memory/STATE.md:49-52` still reads "the Stage-2 exit gate SLIPPED honestly — the T3 MSI-record keystream diverges at payload offset 0x24000, decompile chase required, tax-modern.md unwritten" — the exact premise finding 2 falsifies; and `grep -n "2026-11-28" harness/memory/SESSION_LOG.md` returns **nothing** — the funded T3 session's execution is not yet in the session log. Neither is a security defect (the chase note + commit message carry the truth), but a gate that advances on a falsified-premise record without correcting the record would be the records-honesty class this panel polices.

### 5. Provenance-heading normalization — formatting-only, confirmed byte-precise

- `git diff HEAD~1 --numstat -- docs/re-research/`: **3 insertions / 0 deletions** for each of the five pre-existing notes (`2026-11-22-tt-targets-phase1.md`, `2026-11-22-tt-t2-reader.md`, `2026-11-22-tt-t2-session2.md`, `2026-11-23-tt-t2-session3.md`, `2026-11-23-tt-t3-session1.md`) + the new 122-line `2026-11-28-tt-t3-session2.md`. The 3-line insert in every file is the `## Provenance (protocol §7.1)` heading + blank + the fixed factual sentence.
- I extracted the `SECTION` constant from `scripts/add_provenance_headings.py:19-29` and programmatically confirmed it is byte-identical to the text actually present in all six notes (`SECTION-PRESENT` × 6). No content changed beyond the insertion; the script itself is idempotent (`skip (heading present)` guard, `add_provenance_headings.py:34-36`) and is the lint's `--scope all` flip enabler (SEC-6 extension, `lint_format_specs.py:17-22`), which now passes (finding 1).

### 6. DoD checklist cross-check (the exit gate's own fixed list)

- **4/4 named specs present + lint-clean:** verified (finding 1).
- **§7.5-clean:** `tax-modern.md` records the full checklist pass (`tax-modern.md:164-175`); the chase note records the §7.5-style pass (`2026-11-28-tt-t3-session2.md:111-122`).
- **≤2 Stage-2 execution sessions:** SESSION_LOG records exactly two — session 1 (`harness/memory/SESSION_LOG.md:1152`, 2026-11-22) and session 2 ("the box's second and final", `:1294`, 2026-11-23). The T3 sessions are TT-program-lane work under the namespace rule (`DECISIONS.md:891-895`, `ROADMAP.md:876-880`) and do not count toward Stage-2's box.
- **Refusal/cap tests green:** `python3 scripts/test_re_tools.py` → `Ran 23 tests … OK`, exit 0 (the RE-tool refusal/cap classes: size refusals, block/timeout caps, clean exit-3 refusals).
- **No-binary-blob assertion green:** `check_binary_blobs.py` clean (finding 1).
- **Environmental note (not a finding):** `bash scripts/harness_check.sh` currently exits 1 with exactly one failure — `FAIL — 2 unpushed commit(s) — the last session-log entry postdates the backup; run scripts/sandbox_backup.sh` — i.e. the sandbox-backup/push hygiene for today's two commits, expected pre-close, resolved by the close backup. The confinement guard itself passes (OUTSIDE=0/INSIDE=6).

---

## Verdict

**PROCEED-WITH-CONDITIONS**

No BLOCK: the security-critical surfaces are clean — the new spec carries no crypto key material, no IV values, no ≥32-hex runs, and no decrypted content enters the repo; the falsification of the slip's technical premise is empirically verified by this reviewer's own bounded reproduction of both end-to-end closures; the D46 workflow rework adds no new supply-chain surface, holds least privilege, and its guards are fail-closed as claimed. The conditions are records-integrity and guard-hardening items only.

**Conditions (all concrete and checkable):**

1. **Commit the owner-rulings record layer before/at gate close.** The 2026-11-28 owner rulings exist only as working-tree edits (`git status`: `M harness/memory/DECISIONS.md`, `M harness/memory/ROADMAP.md`, `M harness/adversarial/CONSENSUS.md`, plus `M PROJECT_MEMORY.md`). Checkable: after close, `git status` shows none of these modified; `git log -1 -- harness/memory/DECISIONS.md` carries the "Owner rulings recorded 2026-11-28" section (`DECISIONS.md:878`).
2. **Correct the falsified slip premise in the memory layer at close.** Add the 2026-11-28 T3-session-2 entry to `harness/memory/SESSION_LOG.md` (currently absent — `grep -n "2026-11-28" harness/memory/SESSION_LOG.md` → no match) and amend the superseded STATE.md text (`harness/memory/STATE.md:49-52`: "keystream diverges at payload offset 0x24000, decompile chase required, tax-modern.md unwritten") to record the falsification and the spec's landing, citing the chase note. Checkable: both greps/lines reflect the post-T3 state.
3. **Harden the harness_check confinement boundary regex** (`scripts/harness_check.sh:96-97`): the job-boundary pattern `^  [A-Za-z0-9_-]+:$` mis-attributes lines when a job line carries trailing whitespace or a trailing comment (valid YAML) — verified escape in my sandbox test. Fix so any two-space-indented `key:`-shaped line (allowing optional trailing whitespace/comment) is treated as a job boundary, and re-verify: with the fix, a cargo line injected under any job other than `nextjs-web` must yield OUTSIDE ≥ 1, and the current file must still give OUTSIDE=0 / INSIDE=6 with `harness_check.sh` passing on that check.

— ADV-SEC, 2026-11-28
