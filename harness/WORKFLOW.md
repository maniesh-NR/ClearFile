# Harness workflow — the operating contract

**Status:** binding from 2026-11-14 (owner directive) · Applies to every
session that works on this repository.

---

## 1. Prime directive A — event-driven backups, never scheduled

> Owner, 2026-11-14: "Backups should always be the last step in every
> execution plan, every output to a prompt should end with a backup, rather
> than backups at a fixed time interval."

1. **The last step of every execution plan is a backup.** After a prompt's
   deliverables are complete — and *before* the assistant writes its final
   reply — run:
   ```bash
   scripts/sandbox_backup.sh "<short note about what this run changed>"
   ```
   The script commits the sandbox's project state and pushes it to
   `origin/main` on GitHub.
2. **No cron. No fixed interval. No scheduling.** Backups happen only as
   the closing action of completed work. This is deliberate: the repository
   should always equal "the end state of the last finished task", never a
   mid-work snapshot, and never a zombie schedule that pushes noise while
   nobody is working.
3. **A clean tree is a successful no-op.** If nothing tracked changed, the
   script prints `backup: nothing to archive (tree clean)` and exits 0.
   The reply still "ended with a backup" — the rule is about always
   running the step, not about always creating a commit.
4. **A failed push is never silent.** If the push fails (auth, network,
   non-fast-forward), the script exits non-zero with an explanation; the
   assistant must tell the owner in its reply rather than pretending the
   backup happened. Do not force-push a backup over diverged history
   without understanding why the history diverged.
5. **Secret guard.** The script refuses to commit if the staged content
   matches known token patterns (fine-grained and classic GitHub tokens,
   provider keys, AWS/Slack/npm/GitLab patterns, PEM blocks, and raw
   64-hex blobs outside lockfiles). Never commit credentials. The owner's
   GitHub PAT lives only in the sandbox's `.git/config` remote URL (never
   tracked, never printed in full) — see §4 for what to do after a recycle.

### Backup scope (what is backed up, what is never backed up)

The backup is a **project-state backup, not a sandbox mirror**. Tracked by
the backup: source code (`clearfile/`, `src/`, `prisma/`, `public/`),
docs (`docs/`, `harness/`, `README.md`, `LICENSE`, `blueprint-assets/`),
CI (`.github/`), tooling (`scripts/`), and repo configs.

Never backed up (enforced by `.gitignore`, "sandbox backup scope" block):

| Excluded | Why |
| --- | --- |
| `.env`, `db/` | local config + dev database (user-local data) |
| `.zscripts/`, `Caddyfile`, `tests/`, `examples/`, `mini-services/`, `tool-results/` | platform runtime scaffolding and agent artifacts |
| `download/` | local deliverables; release binaries live on GitHub Releases; contains the unrelated `nitro_nissi` app |
| `tools/` | SDKs (Flutter toolchain — multi-GB, reinstallable) |
| `node_modules/`, `.next/`, build outputs | rebuildable artifacts |

---

## 2. Prime directive B — adversarial gates with independent consensus

> Owner, 2026-11-14: "assign adversarial roles to agents to examine work
> done so far and the future roadmap, only proceed to the next stage when a
> consensus has been reached. Every stage in future must have a
> comprehensive assessment by adversarial agents, and require independent
> consensus in order to proceed further."

### The gate

Before **any** roadmap stage begins, the standing panel
(`adversarial/ROLES.md`, ≥ 4 roles) runs a **Stage Gate review**:

1. **Independence.** Reviewers run concurrently in isolated agent contexts.
   They cannot see each other's reports. Consensus is computed only after
   all reports are in, by the orchestrator, and recorded in
   `adversarial/CONSENSUS.md`.
2. **Comprehensiveness.** Each reviewer examines (a) all work completed
   since the last gate, (b) the current repository state, and (c) the plan
   for the stage about to start. Evidence is required: file paths, line
   numbers, command output — never "someone said".
   **Gate-depth tiering (Stage-0 amendment, ratified by the Stage-1
   gate):** the *scope* of (b) is tiered per `memory/ROADMAP.md`'s
   "Gate depth tiering" section — full-repository review for Stage-1
   entry, Stage-2 entry, and any history-rewrite execution;
   delta-since-last-gate plus named risk surfaces for all other gates
   and spot reviews. Independence, evidence requirements, and the verdict
   vocabulary below are never relaxed — only the review scope is. If
   WORKFLOW and ROADMAP ever disagree on a gate's scope, the fuller
   (full-depth) scope applies until the discrepancy is fixed and
   `scripts/harness_check.sh` flags it.
3. **Verdicts.** Each reviewer's verdict must be exactly one of:
   - `PROCEED` — sound; no conditions.
   - `PROCEED-WITH-CONDITIONS` — sound *only if* the numbered conditions
     are applied before or during the next stage; conditions must be
     concrete and checkable.
   - `BLOCK` — a finding so serious that advancing would be reckless; must
     name the finding and the fix that would clear it.

### The consensus rule

A gate **passes** only when:

- every reviewer's verdict is `PROCEED` or `PROCEED-WITH-CONDITIONS`, **and**
- every condition from every `PROCEED-WITH-CONDITIONS` verdict is either
  *applied* (with commit references) or *rebutted in writing* (with
  rationale the reviewer would accept), recorded in `CONSENSUS.md`.

Any `BLOCK` verdict stops the stage. The blocking finding is fixed (or
formally rebutted with the owner's agreement), and the gate is **re-run**
— a fresh review, not an amendment. Unanimity of the *panel* is required;
the owner may overrule a `BLOCK` only by recording an explicit, reasoned
acceptance-of-risk note in `CONSENSUS.md` (this is an owner prerogative,
used sparingly, and never silently).

### Cadence

- Stage transitions: mandatory gate (above).
- Within a stage, at the orchestrator's judgment or an owner request, a
  **spot review** may be convened with the same mechanics.
- The backup rule (§1) is unaffected: gates end with backups too.

---

## 3. Session protocol

**Bootstrap (start of session):**

1. Read `harness/WORKFLOW.md` (this file).
2. Read `harness/memory/STATE.md`, the last 2–3 entries of
   `harness/memory/SESSION_LOG.md`, `harness/memory/ROADMAP.md`, and
   `harness/adversarial/CONSENSUS.md`.
3. If the sandbox was recycled (missing `origin` remote, missing SDK, or a
   lone "Initial commit" in `git log`), run §4 first.
4. Confirm the next planned stage has a **passed** gate in `CONSENSUS.md`
   before starting stage work. If not, the session's first task is to run
   the gate.

**Teardown (end of every execution plan):**

1. Append a dated entry to `harness/memory/SESSION_LOG.md` (what was done,
   decisions, open questions, next step).
2. Update `harness/memory/STATE.md` if environment or repo facts changed.
3. Run `scripts/sandbox_backup.sh "<note>"` — **this is the last action**
   before replying to the owner.

---

## 4. Recycle runbook (sandbox was reset between sessions)

Observed on 2026-11-14: the sandbox re-materialized with working files
intact but git history squashed into one "Initial commit" that also swept
in platform scaffolding; the `origin` remote, the Flutter SDK (`tools/`),
`node_modules/`, and `.next/` were gone. GitHub is the source of truth.

1. Verify work files survived (`README.md`, `docs/`, `clearfile/`, `.github/`).
2. Re-add the remote (PAT is supplied by the owner in conversation; embed
   it only in `.git/config`, never in tracked files):
   ```bash
   git remote add origin https://x-access-token:<PAT>@github.com/maniesh-NR/ClearFile.git
   git fetch origin
   ```
3. Re-point the branch without touching the working tree:
   ```bash
   git reset origin/main        # mixed reset; scaffolding becomes untracked
   git restore .                # normalizes file modes the snapshot broke
   ```
   Files that are tracked in the squashed "Initial commit" but not in
   `origin/main` (`.env`, `.zscripts/`, `db/`, `download/`, `tests/`,
   `examples/`, `mini-services/`, `tool-results/`, `Caddyfile`, `tools/`)
   stay on disk as untracked — the `.gitignore` backup-scope block keeps
   them out of future backups.
4. Reinstall heavy tooling only if the session needs it:
   - Flutter SDK 3.47.9 → `tools/flutter` (stable Linux tarball, verify
     sha256; then `export PATH="$PWD/tools/flutter/bin:$PATH"`).
   - Web prototype → `npm install` (and `npm run build` when needed).
5. Verify: `git status --porcelain` shows nothing but ignored/untracked
   scaffolding; `git log --oneline -5` shows the full project history; and
   `bash scripts/harness_check.sh` exits 0 — its unpushed-commit check
   catches a stale local amend before it can diverge from origin
   (Stage-2 entry gate, 2026-11-17, ENG-7: an unlogged 2026-11-16 session
   left exactly such an amend, found two days later).

---

## 5. Auth and secret policy

- The GitHub PAT is supplied by the owner in conversation. It is used in
  `git remote add` (stored in `.git/config`, which is never committed) and
  in `curl -H "Authorization: token …"` calls to the GitHub API. It is
  never written to a tracked file, never echoed in full in output, and
  never committed. The backup script enforces this with a pre-commit
  pattern scan (fine-grained and classic GitHub tokens, provider keys,
  AWS/Slack/npm/GitLab patterns, PEM blocks, raw hex blobs).
- **Token profile (recorded 2026-11-14):** fine-grained PAT
  (`github_pat_…`), scope Contents: Read & Write on `maniesh-NR/ClearFile`
  only. A fine-grained PAT with Contents:RW is effectively repo-admin
  (force-push, release mutation) — treat its theft as a full-repo
  compromise.
- **Profile correction 2026-11-14 (Stage-1 session, observed in use):** the
  token successfully dispatched workflow runs (Actions API `POST …
  /dispatches` → HTTP 204) and read Actions job logs (HTTP 200) — it carries
  Actions write/read beyond the Contents-only profile recorded above. Treat
  the token as broader than first recorded: full-repo AND CI compromise on
  theft. When next rotating, the owner should check the PAT's actual
  permission set in the GitHub UI.
- **Rotation policy:** rotate at every sandbox recycle, or at most every
  90 days; rotate immediately if the token value is ever echoed into any
  transcript, log, or file. The owner should set an explicit expiry when
  minting tokens and attest to it; sessions should ask for the current
  PAT rather than trusting one recovered from stale context.
- **Owner decision 2026-11-14: the PAT is left as-is** (no expiry change,
  no rotation at this time) — an explicit, acknowledged risk acceptance.
  The rotation policy above remains the standing guidance for when the
  owner chooses to act; the token continues to live only in `.git/config`
  and must be re-supplied by the owner after any recycle where it stops
  authenticating.
- Owner-side recommendation: enable branch protection on `main` (at
  minimum, reject force-pushes from non-owner actors) so the PAT is not
  the only guard on history integrity.
- If the PAT is rejected after a recycle, ask the owner for a fresh token;
  do not attempt workarounds.
