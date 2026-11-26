# ADV-SEC — N1 exit gate (2026-11-26, Task N1-EXIT-gate-SEC)

Reviewer: ADV-SEC (secrets/CI-CD/release integrity/token lifecycle/supply chain + adversarial probe of the session-2 untrusted-input parsers). Delta under review: `4a55caf..138e93b` (tip `138e93b`, tree clean). Scope note: the three sibling exit-gate reports (LEGAL/ENG/PROD) were neither read nor written.

**VERDICT: PROCEED**

## Conditions

None. Every mandate item verified clean; the findings below are latent-or-inherited resource-complexity postures registered as risks + advisories, none a regression introduced by this delta against a shipped artifact.

## Risks register

1. **JSON object-key insertion is O(n²) on crafted wide objects** (`core/src/json.rs`, `parse_object`'s linear duplicate-key scan). Measured live: 10,000 keys → 0.37 s, 40,000 → 6.0 s, 80,000 → 26.8 s (clean 4×-keys ≈ 16×-time scaling). A few-MB crafted `.clearfile.json` with ~10⁵–10⁶ keys would pin a core for minutes — a CPU-exhaustion posture the references do NOT share (V8/Dart decode into hash maps, O(n)). Today this is latent: nothing shipped parses JSON through this core (no FFI surface, no shipped-artifact coupling — verified). It becomes a real divergence-from-reference exposure at the first FFI-wiring session. Registered for that session's gate.
2. **ZIP STORE-extraction memory/CPU amplification** (`core/src/tax_inspect.rs`, `read_zip_directory`). Crafted and measured live: a 385 KB file whose 2,048 central records all point at one shared 256 KB payload → >1 GB of allocations (per-entry copy in `dir` + clone into `entries`) + 5.69 s CPU; extrapolates to ~40 GB/OOM-abort from a ~10 MB crafted file at the 4,096-entry cap (amplification ≈ entry-cap × payload). This posture is **inherited by parity**: the shipped Dart (`tax_inspect.dart`) and TS (`taxfile.ts`) readers have the identical cap-and-extract design, so N1 introduces no new exposure — but the port is the natural place to harden before the core ever touches a user-opened file.
3. **Third allow-list instance widens the hex guard by one exact path** (`scripts/sandbox_backup.sh`): `fixtures/differential/README.md` is now excluded from both the 64-hex scan and the ≥32-hex RE scan. Verified narrowly scoped (exact path, no glob) and justified: the README carries exactly one ≥32-hex run — the corpus regeneration digest — and it matches the tracked `cases.json`'s actual sha256 (`a15ac79c…d9947`, recomputed live). Residual risk, same class as the two prior instances: any *future* 64-hex blob pasted into that README (e.g. a hex-dumped 32-byte key) passes the backup guard, and gitleaks generally does not flag bare hex either. The guard does not re-verify that the README's digest still matches `cases.json` at commit time.
4. **Full-history hex heuristic note (pre-existing, not this delta):** two sandbox-scaffolding files carrying benign 64-hex runs (`tools/releases_linux.json` — Flutter release-manifest digests; one `tool-results/*.txt`) exist in five mid-history commits and were untracked at `df617e8` ("hygiene: untrack sandbox scaffolding"). No token-shaped content (TOKEN_PATTERNS over all 44 commits: zero hits); retained in history only as digests/prose. No action required short of a history rewrite, which is out of scope.

## Non-binding advisories

1. Before the first session that wires the core to user-opened files (the FFI/integration session), add a cumulative extracted-bytes cap (e.g. total stored ≤ max(file size, N MB)) in `read_zip_directory` — a strictly-added guard in the ENG-1/divergence-9 spirit (the references lack it; document it as a deliberate hardening divergence with a battery extension pinning it).
2. Same timing, same spirit: bound the wide-object cost in `Json::parse` (e.g. cap object member count like `MAX_ZIP_ENTRIES`, or switch the duplicate-key scan to an index map after a size threshold). The 128-depth limit already covers the stack-exhaustion class; this closes the CPU class.
3. Consider extending `harness_check.sh`'s corpus-ledger check to also assert `sha256sum fixtures/differential/cases.json` equals the digest recorded in `fixtures/differential/README.md` — it would mechanically re-derive the justification for allow-list instance #3 on every CI run.
4. `MAX_ZIP_ENTRIES` (4,096) and `MAX_EOCD_SCAN_WINDOW` (66,000) are reference parity; keep the caps when hardening (item 1) so the divergence budget stays minimal and documented.

## Verified live (evidence — commands run and their outputs)

1. `git diff 4a55caf..138e93b --stat -- .github/` → **EMPTY** (CI untouched; no new `uses:` lines; all 38 `uses:` lines across the 3 workflows are full-SHA-pinned — spot-checked the list). `hygiene.yml`'s core step is `cargo test --locked` with `working-directory: core`, runner rustup only, no secrets beyond the pre-existing default `GITHUB_TOKEN` for gitleaks.
2. `cd core && cargo test --locked --test tax_inspect_port` → **37 passed; 0 failed** (0.08 s) — the malformed-ZIP crash battery green.
3. `cd core && cargo test --locked` (full suite) → **159/159 green** (15+3+6+2+42+7+25+37+22 across unit + 8 integration binaries).
4. **Adversarial probe crate** (external, `/tmp/gate-sec-adv`, path dependency on `core` — repo tree untouched), inputs crafted **beyond** the 19 battery extensions: EOCD `cd_offset == len` (records at exact EOF), `cd_offset` pointing into the local header and at the EOCD itself, `count=0xFFFF` over 200 zero-filled `PK\x01\x02` frames, 2,048-entry amplification ZIP, JSON 128/129-depth boundary, pathological numbers (`9`×400 digits, 303-char denormal, `1e-999999`, `-0`, `1e999999`), truncated/lone-surrogate `\u` escapes. Output: **no panic, no hang, no slice error** — all named errors or honest warnings; the two complexity findings above are the only adverse results (both reproduced deterministically).
5. `sha256sum fixtures/differential/cases.json` → `a15ac79cc5cb80c2dabd85a51fd0c964b9cecc72a10f45de7715fb53828d9947` — **byte-equal to the digest recorded in `fixtures/differential/README.md`** (the allow-list justification holds on the actual file).
6. **Corpus regeneration provenance**: copied ONLY `scripts/` + `clearfile/lib/` into a clean `/tmp/gencheck`, ran the tracked generator with the repo's Dart SDK → wrote 550 cases (300/246/4), sha256 **identical** (`a15ac79c…d9947`). Proves byte-determinism, no environment/timestamp dependence, no network, and that every expected value derives solely from the Dart reference engine + `tax_year.dart` parameters via `const TaxCalculator().compute(TaxReturnData.fromJson(input))` (the generator's only compute path — read in source).
7. Generator audit (read): imports are `dart:convert`, `dart:io`, and five `../clearfile/lib/…` relative paths — **no `package:` imports, no HttpClient/Socket, no Process**; file access is exactly `File('<repoRoot>/fixtures/differential/cases.json')` with `repoRoot` derived from `Platform.script` (no operator input, no traversal); the only hex constants are the 16-char xorshift64* multipliers (`0x2545F4914F6CDD1D`, `0x9E3779B97F4A7C15`) — not 64-hex, no allow-list interaction.
8. `git grep -E <TOKEN_PATTERNS> $(git rev-list --all) -- .` over all **44 commits → zero hits** (full-history secrets scan, all token shapes incl. `github_pat_`, `ghp_`, `sk-`, `AIza`, `AKIA`, `xox`, `npm_`, `glpat-`, private-key headers). Separately, 64-hex over history (excl. lockfiles + the 3 allow-listed paths) hits only the two untracked-at-`df617e8` scaffolding files (risk 4) — benign digests, absent from HEAD.
9. Corpus content scan: zero token-shaped strings, zero URLs, zero base64-blob candidates, zero hex runs ≥32 (`grep -cE '[0-9a-fA-F]{32,}' cases.json` → 0), longest string value is the 450-char `note`, names are synthetic (`Child 1`, `Dep-1`, …); structure: 550 cases, unique ids, classes 300 random / 246 edge / 4 edge-d31b, one distinct 26-key expected schema, zero non-finite values.
10. Supply chain: `core/Cargo.toml` → **zero dependency sections, `publish = false`**; `core/Cargo.lock` → **exactly one package** (`clearfile-core`); `hygiene.yml`'s license-check step enforces both fail-closed in CI.
11. Release integrity / ADR-017 variant: `grep -cE 'core/|clearfile-core|cargo' .github/workflows/release.yml` → **0**; `grep -rln clearfile-core clearfile/lib src` → **no matches** (no shipped artifact references the core); the core has **no FFI surface** (no `crate-type`, `extern "C"`, or `#[no_mangle]` anywhere in `core/`); `bash scripts/harness_check.sh` → **0 failures** (incl. its own release.yml-native-free and corpus-ledger checks).
12. `git diff 4a55caf..138e93b -- scripts/sandbox_backup.sh` → only the two exclude lines + the third-instance comment (risk 3); TOKEN_PATTERNS, the note-scan, and every other guard path unchanged.

## Files read

- `core/src/json.rs` (all 889 lines — parser, writer, number grammar, fast-path UTF-8 argument, tests)
- `core/src/tax_inspect.rs` (all 904 lines — analysis walk, EOCD scan, offsets, entropy, writer, composition)
- `core/src/lib.rs` (all 263 lines — module surface, input model)
- `core/src/txf.rs` (lines 680–810 + panic-site greps over the whole file), `core/src/envelope.rs` (panic-site/slice-site greps + decode path)
- `core/tests/tax_inspect_port.rs` (structure + battery-extension inventory, all 19 extensions listed)
- `scripts/generate_differential_cases.dart` (header, imports, PRNG, compute path, self-checks, output write)
- `scripts/sandbox_backup.sh` (all 187 lines, diffed against `4a55caf`)
- `scripts/harness_check.sh` (all, incl. the new N1 session-2 checks)
- `fixtures/differential/README.md` (all 131 lines), `fixtures/differential/cases.json` (programmatic scans + structural validation, not line-by-line)
- `.github/workflows/hygiene.yml` (all), `.github/workflows/release.yml` (trigger/uses sections + targeted greps), `.github/workflows/pages.yml` (uses: pin spot-check)
- `core/Cargo.toml`, `core/Cargo.lock`, `harness/memory/DEBT.md` (delta portion), `harness/adversarial/reports/` (directory listing only — sibling reports not opened)
