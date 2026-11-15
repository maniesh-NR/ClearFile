# The ClearFile guided tour (`docs/tour.md`)

**A reading order for a new reader** — fifteen minutes, top to bottom,
and you know what this repository is, what it claims, and how to check
either claim. (Stage-3 close-out deliverable, 2026-11-15.)

## Stop 1 — What this is (5 minutes)

`README.md`, top to bottom. The honest headline: demonstration software,
GPL-3.0, two codebases over ONE TY2025 calculation engine at parity.
Note especially: "Engine limitations" (what the engines deliberately do
NOT model) and "NOTICE — history contents" (the repo's own history
hygiene record).

## Stop 2 — The engine and its numbers (5 minutes)

1. `docs/engine.md` — the map from engine computations to the 1040 /
   Schedule A / 8812 / 8960 lines, every parameter's published source,
   the verification pyramid, and the limitations register (§6). If you
   want to dispute a number, this tells you whether the engines even
   claim it.
2. `fixtures/tax/` — the 16 shared golden fixtures, each an IRS-pinned
   input/expected pair with its citation, derivation and tolerance
   **inside the file**. This is where "verify every number" lives: no
   git history needed — the citation travels with the fixture.
3. `clearfile/lib/models/tax_year.dart` — every TY2025 parameter as a
   named constant with its source in the class doc; the web twin is
   `src/lib/tax/config.ts`.

## Stop 3 — The file formats (2 minutes)

`docs/return-format.md` — the unified ClearFile return file
(`.clearfile.json`, versioned envelope, migration matrix) plus pointers
to the TXF v042 bridges and the read-only `.tax` inspection. What
ClearFile promises about proprietary formats is in
`docs/reverse-engineering-protocol.md` §2 (the clean-room line) —
worth a skim even if you never touch RE.

## Stop 4 — The machine room (3 minutes)

- `clearfile/` — the Flutter app (the reference implementation):
  `lib/tax/calculator.dart` (the engine), `lib/io/` (the format
  bridges: `return_format.dart`, `txf_import.dart`, `tax_inspect.dart`),
  `test/` (111 tests).
- `src/` — the Next.js web prototype: `src/lib/tax/engine.ts` (the
  parity port), `src/lib/files/` (the web-side format code).
- `scripts/` — the CI-visible verification tooling (README at
  `scripts/README.md`): the Decimal oracle, the parity suite, the
  bridge suite, the web smoke test, the harness checker.
- `.github/workflows/` — `hygiene.yml` (gitleaks + harness checks +
  the suites job that runs EVERYTHING above on every push) and
  `release.yml` (the SHA-pinned, tag-guarded multi-platform build).

## Stop 5 — How this project runs itself (optional, 5 minutes)

`harness/` — the durable brain: `WORKFLOW.md` (the operating contract:
event-driven backups, adversarial consensus gates), `memory/ROADMAP.md`
(the gated stage plan), `memory/DECISIONS.md` (the ADRs — including
ADR-014's native-re-platforming direction, recorded but NOT yet
entered), `memory/SESSION_LOG.md` (the append-only work log),
`adversarial/` (the reviewer panel's reports and the gate ledger).
New sessions bootstrap from these files first — that is the point of
their existence.

## If you found a problem

- **A number looks wrong against an IRS source** → the engine
  discrepancy issue template (it asks for your citation and derivation).
- **A document disagrees with the code** → the format discrepancy
  template.
- **Anything else** → a plain issue.

## The definition of done (v1.1)

The project's DoD (ADV-PROD F5, adopted at Stage-3 close-out): **a
reader can verify every number against a cited IRS source without
reading git history.** With this tour's stops 2–3 (engine.md + the
fixtures' inline citations + the return-format spec), every engine
number and every format statement now carries its citation in the
checked-out tree; v1.1 is the release that ships exactly this state.
