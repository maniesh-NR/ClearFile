# Sandbox scripts

Scripts in this directory fall into two groups:

1. **Project infrastructure** — part of the product:

   **Stage-2 RE tooling (2026-11-22, execution session 1 — ADR-012
   placement mechanics + the binding security contract; D38 registered):**

   - `re_entropy.py` — protocol Phase-1 per-block Shannon entropy scan
     (write-free, size/block/timeout caps with clean exit-3 refusals,
     crash-safe on empty/truncated inputs).
   - `re_magic.py` — protocol Phase-1 magic-byte scan at any offset
     (ZIP/CAB/RAR/7z/OLE2/SQLite/ELF/gzip/bzip2/xz/zstd/PDF; `MZ` at
     offset 0 only — the short magic floods otherwise) + text/JSON/XML
     sniff. Same posture.
   - `re_diff.py` — protocol Phase-3 differential comparison
     (offsets/lengths/entropy only — never bytes). Carries the §7.1
     provenance gate: both inputs must hash-match entries in a
     `--manifest` JSON (`{entries: [{sha256, path, provenance
     (owner-authored|synthetic), origin}]}`); pairs lacking an entry are
     refused. Same posture.
   - `test_re_tools.py` — the tools' unit suite (22 tests): every cap
     has a refusal-on-oversize test, the ENG-1-shaped crash battery runs
     empty/truncated/adversarial shapes, the read-only-fixture-dir test
     proves write-freedom, and the differential tool is exercised on a
     SYNTHESIZED pair inside the mandatory spec family #1
     (clearfile.json envelopes differing in one W-2 wage digit). Runs in
     CI (hygiene `re-tooling`); fixtures are runtime-generated under the
     gitignored `fixtures/re/` path (ADR-012 mechanic (a) — synthetic
     only, provenance-headed).
   - `check_binary_blobs.py` — the ADR-012 mechanic (b)/(c) no-binary-blob
     assertion: tracked binaries are legal only on the enumerated
     own-asset allow-list (28 entries; any new binary under `fixtures/`,
     `tools/`, `docs/`, `src/`, `scripts/`, or `harness/` fails CI).
     Runs in CI (hygiene `re-tooling`) and inside
     `scripts/sandbox_backup.sh` after `git add -A` (the auto-publish
     denylist is mechanical).
   - `lint_format_specs.py` — the LEGAL-1 `docs/formats/*.md` lint
     (Provenance section required, no ≥32-hex runs, no image embeds, no
     placeholders); `--scope all` extends to `docs/re-research/` with
     the corpus-manifest known-hash exemption (T3's SEC-6 extension
     point). Runs in CI (hygiene `re-tooling`).

   **Long-standing infrastructure:**

   - `../update_memory.py` (repo root, ADR-018) — refreshes
     `PROJECT_MEMORY.md`'s rolling git-activity window (last 3 commits,
     stat-mode with noise excludes; run `python3 update_memory.py` from
     the repo root at session bootstrap or as a pre/post-commit hook;
     `PATCH_MODE`/`NOISE_EXCLUDES` constants document the deltas from
     the uploaded pstack template).
   - `sandbox_backup.sh` — the event-driven backup (last step of every
     execution plan; see `harness/WORKFLOW.md` §1).
   - `generate_blueprint.py` / `merge_blueprint.py` / `verify_blueprint.py` —
     build `docs/blueprint.pdf` (regenerate after editing the generator's
     copy; `merge_blueprint.py` needs `download/` to exist on a fresh clone —
     `mkdir -p download` first).
   - `web_smoke.py` — Stage-1 web smoke test (ADR-010's gate): builds the
     standalone bundle, serves it, and drives it in headless Chromium via
     Playwright — welcome copy, sample-return load, results, and a
     mid-flow reload that must rehydrate state from localStorage.
     Needs `pip install playwright && playwright install chromium`.
   - `harness_check.sh` — harness self-enforcement (D19): mechanical
     cross-checks of ROADMAP↔CONSENSUS gate status, tiering consistency,
     STATE freshness, stated-vs-declared test totals (data-driven golden
     fixtures in `fixtures/tax/` are counted per JSON file), mode drift,
     and unpushed memory. Runs locally at teardown and in CI
     (`.github/workflows/hygiene.yml`).
   - `verify_golden_fixtures.py` — the independent oracle for
     `fixtures/tax/` (Stage-3 fixtures-first, 2026-11-14): re-derives every
     fixture's expected values as Decimal arithmetic written directly from
     the IRS TY2025 form and worksheet text (Tax Table, QDIVCG worksheet,
     Schedule 1-A Part V, Schedule A SALT worksheet, Schedule 8812,
     Form 8960) — deliberately NOT from either project engine, so a
     Dart/TS disagreement against a fixture can be adjudicated against the
     form text. Runs in CI (hygiene.yml `suites` job) alongside
     `flutter test`, whose `golden_fixtures_test.dart` consumes the same
     files. NB: Python `Decimal //` truncates toward zero — the script's
     ceiling-to-next-$1,000 uses the `+999` offset (learned the hard way;
     see the comment in `ctc_phaseout_amount`).
   - `web_parity_test.mjs` + `tsconfig.parity.json` — the Stage-3 web-parity
     suite (ADR-009, 2026-11-15): compiles the TypeScript engine
     (`src/lib/tax/`) via the dedicated tsconfig to the gitignored
     `.parity-build/`, then runs it against the SAME shared golden fixtures
     the Dart suite runs — every `expected` key within tolerance,
     `deductionMethodUsed` exact. Runs in CI (hygiene `suites`) right
     after the oracle; run locally with `node scripts/web_parity_test.mjs`
     from the repo root (needs the npm devDependencies for tsc).
   - `test_tag_guard.sh` — functional test of the release.yml tag guard
     (Stage-2 entry gate ENG-1): extracts the guard body verbatim from
     `release.yml` (never drifts from what CI runs) and exercises all four
     branches — existing-tag-elsewhere refused, existing-tag-match passes,
     absent tag treated as fresh, non-missing-ref fetch error refused
     (fail-closed). Run from the repo root; needs the `origin` remote.
   - `txf_taxfile_test.mjs` + `tsconfig.files.json` — the Stage-3 bridge
     suite (2026-11-15): compiles `src/lib/files/` (CommonJS emit to the
     gitignored `.files-build/` so Node resolves the extensionless
     intra-module imports) and verifies the TXF exporter against the
     published Tax Exchange Format spec v042 (header V/A/D, `^`-records,
     T/N/C/L/$/P fields, refnums 460/461/466/287/636, negative money-paid
     signs — a mini spec-shaped importer reads the export all the way
     back), the `.tax` analyzer on synthetic containers (ClearFile
     exchange round-trip, Intuit `manifest.xml`+`tax:<uuid>` shape flagged
     encrypted and never decrypted, honest non-ZIP/empty paths), and the
     unified ClearFile return format (ADR-015: envelope round-trip,
     legacy flat lift + guard, version guard, v1 migration with
     warnings). Runs in CI (hygiene `suites`) right after the parity
     suite; run locally with `node scripts/txf_taxfile_test.mjs` from
     the repo root.
   - `fetch_flutter_sdk.sh` — durable version of the recycle-runbook
     Flutter install (WORKFLOW §4): downloads the pinned 3.47.9
     stable Linux tarball into gitignored `tools/`, verifies its sha256
     against the official `releases_linux.json` manifest, unpacks, and
     smoke-tests `flutter --version`. Resumable — after a stalled
     download or a tool-call timeout just re-run it.
   - `fetch_tt_corpus.sh` — durable acquisition of the TT RE research
     corpus (ADR-019, 2026-11-22): the four publicly-posted TurboTax
     installer targets into gitignored `tools/re-corpus/` (never
     tracked; provenance record + sha256s in
     `docs/re-research/corpus-manifest.md`, which is also the
     known-hash allow-list instance for the backup secret guard).
     Resumable; byte-size verification inline; re-run after a sandbox
     recycle. No hashes are embedded in the script itself.
   - `add_spdx_headers.py` — one-shot GPL-3.0-only SPDX header application
     (D14); idempotent. Its first run had a line/character-offset bug that
     split shebang and `'use client'` first lines;
     `repair_spdx_insertion.py` is the one-shot remediation that restored
     them (kept for the audit trail).
2. **Sandbox research artifacts** — one-off AI-provider experiments kept for
   provenance (not shipped logic, not part of any build):
   - `ai_provider_tests.py` — validated the Google/OpenRouter free-tier keys
     and model catalogues (env-var keys, never hardcoded).
   - `openrouter_explore.py` — the free-model catalogue survey behind the
     cascade's default chain.
   - `diag_reasoning.py` — diagnosed empty-content responses from reasoning
     models (the reason the cascade disables reasoning tokens).

All scripts read credentials from environment variables only; none contain
embedded keys (verified by the full-history secret scans).
