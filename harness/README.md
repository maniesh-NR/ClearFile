# ClearFile Harness — memory, workflow, and adversarial governance

This directory is the **durable brain** of the ClearFile project. The
development sandbox is ephemeral (it gets recycled between sessions — this
happened between 2026-11-04 and 2026-11-14 and cost the local git history),
but this repository is not. Everything a future session needs to pick up
exactly where the last one stopped lives here.

## Directory map

| Path | Purpose |
| --- | --- |
| `WORKFLOW.md` | **The operating contract.** Event-driven backup rule, adversarial consensus gates, session protocol, recycle runbook. Read this first. |
| `memory/STATE.md` | Current snapshot: repository state, environment facts, quirks, what is next. Read this second. |
| `memory/SESSION_LOG.md` | Append-only log, one entry per work session: what was done, key decisions, open questions. |
| `memory/ROADMAP.md` | The staged roadmap. Every stage carries a gate status; stages advance only on recorded consensus. |
| `memory/DECISIONS.md` | Architecture/decision records (ADRs) with rationale. |
| `adversarial/ROLES.md` | The standing adversarial review panel: roles, mandates, independence rules. |
| `adversarial/reports/` | One report per reviewer per gate, saved near-verbatim. |
| `adversarial/CONSENSUS.md` | Gate ledger: verdicts, conditions, whether conditions were applied, gate outcome. |

## The two standing rules (owner directives, 2026-11-14)

1. **Every execution plan ends with a backup.** The last step of any prompt's
   work — before the assistant replies — is running
   `scripts/sandbox_backup.sh "<note>"`, which commits and pushes the
   sandbox's project state to this repository. Backups are **event-driven,
   never scheduled** (no cron, no fixed interval): they ride along with
   completed work, so the repository always reflects the end-state of the
   last finished task, and nothing else.
2. **Stages advance only on independent adversarial consensus.** Before any
   stage of the roadmap starts, an adversarial panel (see
   `adversarial/ROLES.md`) comprehensively reviews the completed work and
   the stage plan. Reviewers run in isolation from each other; the gate
   passes only when the recorded verdicts reach consensus. Full process:
   `WORKFLOW.md` §2.

## For a new session bootstrapping from this repository

1. Read `WORKFLOW.md`, then `memory/STATE.md`, `memory/SESSION_LOG.md` (last
   2–3 entries), `memory/ROADMAP.md`, and `adversarial/CONSENSUS.md`.
2. Follow the session protocol in `WORKFLOW.md` §3.
3. If the sandbox was recycled since the last session, run the recovery
   runbook in `WORKFLOW.md` §4 first.
