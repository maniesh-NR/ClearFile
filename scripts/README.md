# Sandbox scripts

Scripts in this directory fall into two groups:

1. **Project infrastructure** — part of the product:
   - `sandbox_backup.sh` — the event-driven backup (last step of every
     execution plan; see `harness/WORKFLOW.md` §1).
   - `generate_blueprint.py` / `merge_blueprint.py` / `verify_blueprint.py` —
     build `docs/blueprint.pdf` (regenerate after editing the generator's
     copy; `merge_blueprint.py` needs `download/` to exist on a fresh clone —
     `mkdir -p download` first).
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
