# Sandbox scripts

Scripts in this directory fall into two groups:

1. **Project infrastructure** — part of the product:
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
     STATE freshness, stated-vs-declared test totals, mode drift, and
     unpushed memory. Runs locally at teardown and in CI
     (`.github/workflows/hygiene.yml`).
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
