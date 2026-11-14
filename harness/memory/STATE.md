# Current state (snapshot)

**Updated:** 2026-11-14 (after the Stage-2 entry gate session — Stage 1
closed, Stage 3 entered under the re-sequencing; this gate session's
closing backup is the tip)

## Repository

- GitHub: `maniesh-NR/ClearFile` (public), branch `main`. The Stage-1
  execution session's closing backup is the tip (code work backed up as
  `0bbb564`, memory records in the closing commit).
- Tag `v1.0.1` (release 445310560): **published 2026-11-14** via the
  fresh-tag dispatch path — 11 assets including the first
  `SHA256SUMS.txt` (one asset locally re-verified), the Android INTERNET +
  macOS network-client fix, the network disclosure, and the hardened CI's
  first full green run (8/8 jobs, run 43598726491). The tag points at
  exactly `0bbb564` (target_commitish honored). The existing-tag poisoning
  guard was proven by the intentional refusal run 43598383213.
- `hygiene.yml` (gitleaks weekly + harness_check on push) — first push run
  green. All workflow actions SHA-pinned.
- Public tree: project-only; 61-test suite; GPL-3.0-only SPDX headers on
  own code (vendored shadcn excluded); SECURITY.md present.

## Gate status

- Stage 0: PASSED (2026-11-14).
- Stage 1: ENTERED, executed end-to-end, and **CLOSED 2026-11-14** at the
  Stage-2 entry gate (4 × PROCEED-WITH-CONDITIONS, no BLOCKs; unanimous
  closure on live-verified execution evidence).
- **Stage 2 (RE tooling): re-sequenced AFTER Stage 3** — PENDING; its
  entry gate (full-depth, ADV-LEGAL weighted; also Stage 3's exit gate)
  must settle: the DoD fix (define N + a two-session time-box), the
  placement ADR-012 (panel split recorded in CONSENSUS), and the RE
  tooling security contract. Stage IDs are stable — Stage 2 is still "RE
  tooling", Stage 3 still "parity & bridges", everywhere.
- **Stage 3: ENTERED 2026-11-14** (at the Stage-2 entry gate, which
  reviewed its plan under the re-sequencing). Execution starts with the
  shared golden fixtures FIRST. **Parity tripwire clock (defined at
  entry):** baseline 2026-11-14; box = two working sessions on the web
  parity set; slip = exit gate not convened within four total working
  sessions; exceed-or-slip → web-freeze returns to the next gate as a
  mandatory item.
- Owner decisions all stand: ADR-008 accept-and-document; ADR-009 feature
  parity; INTERNET add-and-disclose; PAT unchanged. ADR-010 closed. ADR-011:
  settings schemaVersion 2. The ordering swap is the gate's settled
  decision (split panel recorded honestly; owner overrule path in
  CONSENSUS).

## Environment facts (sandbox)

- **Flutter SDK 3.47.9 PRESENT** at `tools/flutter` (reinstalled
  2026-11-14, sha256 `25ed8c3c…` verified against
  `tools/releases_linux.json`; the tarball download stalls — use a
  resuming loop with `--speed-limit 1024 --speed-time 30`).
- `node_modules/` present; `.next/` absent (`npm run build` when needed).
  `npx tsc --noEmit` exit 0 (tsconfig excludes untracked `examples/`,
  `skills/`).
- Test suite: **61/61 green** (re-run by the orchestrator AND two of the
  four gate reviewers independently, 2026-11-14): 19 calculator, 8
  cascade, 10 CSV, 3 JSON, 5 privacy, 2 autosave regressions,
  5 money-parsing, 6 step/settings guards, 3 widget. `flutter analyze`
  clean. `npx tsc --noEmit` exit 0.
- Live-check quirk (2026-11-14): **unauthenticated api.github.com from this
  sandbox is shared-rate-limited (60/hr, exhausted fast when four
  reviewers run concurrently)** — use the public HTML pages
  (`github.com/…/releases/tag/…`, `…/actions/runs/…`) or, sparingly and
  never echoing it, authenticated curl per WORKFLOW §5.
- Git identity: platform default (`z@container`). Remote auth: owner's
  fine-grained PAT in `.git/config` only (owner declined rotation —
  WORKFLOW §5).

## Hard-won quirks (do not relearn these)

1. **Widget tests + filesystem = hang** — FS work inside `testWidgets` must
   run in `tester.runAsync` (plain `test()` is unaffected).
2. `AppState.dispose()` idempotent; call before test-body return
   (`_verifyInvariants` runs before teardown).
3. **Autosave contract (2026-11-14):** `deleteReturn` cancels the debounce;
   the timer callback is identity-guarded; `_open` **flushes the prior
   return's pending save on switch** — three regression tests pin all of
   it (delete, switch, and the privacy contract).
4. Dart `$` escaping; `file_picker` 13.x static API; `RadioGroup<T>`;
   static teal seed (`dynamic_color` unusable at 3.47).
5. `upload-artifact` path: workspace root, not working-directory.
6. Root `.gitignore` `/test` (not `test`).
7. **Sandbox recycles squash local history** — GitHub is source of truth;
   runbook WORKFLOW §4 works (proven twice).
8. Hex-blob heuristics must exclude lockfiles (sha256 checksums) AND stay
t   text-only (`-I`): icon/bitmap pixel data legitimately trips
   `[0-9a-fA-F]{64}` (the Windows app_icon.ico did, six times). Token
   patterns scan binaries fine — they're too distinctive to false-positive.
9. **Snapshot restores flip file modes to 755** — normalize before
   committing or every diff noisies (proven twice; now a pre-backup step
   and a future harness_check item).
10. Blueprint regen: generator + playwright cover + merge (needs
    `mkdir -p download` on fresh clones); not byte-deterministic
    (timestamps) — never cite it as a reproducibility exemplar.
11. **Bulk scripted file edits must be re-verified immediately** — the
    SPDX header script split 15 first lines (line- vs character-offset
    bug); caught by `head` spot-checks + full analyze/test/tsc/smoke
    re-run before commit. Never trust a bulk edit without the suite.
12. **The PAT is broader than its recorded profile** (Actions write/read
    observed 2026-11-14; WORKFLOW §5 carries the correction). Check
    permissions in the UI when rotating.

## Immediately next

**Stage 3 execution, fixtures first** (WORKFLOW §3.4 is satisfied — the
Stage-2 entry gate PASSED and entered Stage 3): build the shared golden
fixtures (`(TaxReturnData, TaxResult)` JSON pairs pinned to IRS-published
worked examples) as the reference engine's regression suite — the parity
tripwire's first session. Then the web parity set (boxed at two
sessions). Stage 3's exit gate = the RE-tooling stage's entry gate, which
also carries the placement ADR-012 and the RE DoD fix (see CONSENSUS
ledger). Owner-side surfacings standing: Dependabot, branch protection,
PAT expiry (D30).
