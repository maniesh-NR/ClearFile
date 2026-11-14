# Current state (snapshot)

**Updated:** 2026-11-14 (after the Stage-1 entry gate — Stage 1 ENTERED)

## Repository

- GitHub: `maniesh-NR/ClearFile` (public), branch `main`. The Stage-1
  session's closing backup commit is the tip (this session's work: owner
  decisions applied, entry conditions cleared, Stage-1 gate held and
  conditions applied — see `adversarial/CONSENSUS.md`).
- Tag `v1.0.0`: release carries the patched description — demo disclaimer,
  unsigned statement, **AI-broken note** (Android/macOS binaries cannot
  reach AI providers), and the GPL §6 corresponding-source line (API-200
  verified twice).
- Public tree: project-only. `bun.lock` deleted (npm lockfiles
  standardized); `package-lock.json` tracked; blueprint PDF regenerated
  with corrected privacy copy + "Tax Return Study Prototype" title
  (verified via pdftotext).

## Gate status

- Stage 0: PASSED (2026-11-14).
- **Stage 1: ENTERED (2026-11-14)** — unanimous 4 × PROCEED-WITH-CONDITIONS,
  all conditions applied in-session or assigned to Stage-1 execution
  (gitleaks, action pinning, dispatch dry-run, v1.0.1 closing tag). The
  Stage-2 entry gate reviews Stage 1's execution evidence.
- Owner decisions all ratified: ADR-008 accept-and-document (README NOTICE);
  ADR-009 **feature parity** (two-session tripwire + freeze fallback +
  fixtures-first ordering); INTERNET add-and-disclose (manifest +
  entitlement + disclosures); PAT unchanged (risk accepted).
- ADR-011: settings `schemaVersion: 2` + legacy `sendReturnContext` reset.

## Environment facts (sandbox)

- **Flutter SDK 3.47.9 PRESENT** at `tools/flutter` (reinstalled
  2026-11-14, sha256 `25ed8c3c…` verified against
  `tools/releases_linux.json`; the tarball download stalls — use a
  resuming loop with `--speed-limit 1024 --speed-time 30`).
- `node_modules/` present; `.next/` absent (`npm run build` when needed).
  `npx tsc --noEmit` exit 0 (tsconfig excludes untracked `examples/`,
  `skills/`).
- Test suite: **61/61 green** (2026-11-14, Stage-1 execution additions):
  19 calculator, 8 cascade, 10 CSV, 3 JSON, 5 privacy, 2 autosave
  regressions, 5 money-parsing, 6 step/settings guards, 3 widget.
  `flutter analyze` clean.
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

## Immediately next

Stage-1 execution (ROADMAP items 5-9): gitleaks CI scan, action SHA
pinning, caching verification, dispatch dry-run (fresh-tag AND
existing-tag), widget/web test expansion, GPL headers, SECURITY.md,
`harness_check.sh` (D19 — checklist in ROADMAP item 9), then the
**v1.0.1 closing tag** (Android/macOS network fix + first SHA256SUMS +
hardened CI's first full run). Stage-2 entry gate reviews that evidence
(and decides Stage-2-vs-3 ordering rationale, PROD note 7).
