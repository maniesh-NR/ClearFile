# Shared v1→v2 migration fixtures

**Provenance (RE protocol §7.1):** the v1 envelope is **ClearFile's own
pre-parity web shape** — the `.cfr` schema the web prototype wrote before the
Stage-3 parity port (ADR-009/ADR-015). Every specimen here is **synthesized
by this repository's own tests** (lifted verbatim from the identical inline
samples the two suites previously carried); zero third-party bytes, zero
proprietary samples. Committed fixtures under `fixtures/` are
text-with-provenance only (ADR-012 mechanic (a)); the CI no-binary-blob
assertion covers this path.

## Why they exist (DEBT D34)

The v1→v2 conservative migration is triple-implemented (Dart
`ReturnFileCodec._migrateWebV1`, web `parseCfr`'s `migrateV1`, and the
browser-store persist migration in `src/lib/store.ts`), and the two file
readers were each verified against their own inline copy of the sample with
fragment-level (`contains`/`includes`) warning checks — drift between the
copies and the warning lists was invisible. D34's fix lifts the identical
sample into ONE shared fixture and pins the exact, ordered warning list in
both suites, so a wording or ordering change on either side fails a test
from the other side's file.

## The fixtures

| File | Pins |
| --- | --- |
| `v1-web-envelope.json` | The full conservative mapping — every mappable field, every warned drop (`adjustments`, `itemized.medical`, `itemized.other`), dependent-count placeholders, the MFJ status rename, the tax-year force to 2025, and the v1 *file* W-2 shape (`{employer, wages, withholding}`). |
| `v1-web-envelope-edge-clamp.json` | The dependent-count bound: `qualifyingChildren: 250` clamps to 100 placeholder rows (the Dart reader's historical bound, now pinned on both file readers) with only the two warnings that actually apply. |

## The exact-warning contract (both suites assert list equality)

For `v1-web-envelope.json`, in order:

1. `Saved with an older prototype: the return was migrated to the current engine model.`
2. `"Adjustments to income" had no equivalent in the current model and was dropped — re-enter it as student loan interest if that is what it was.`
3. `Medical and "other" itemized expenses have no equivalent in the current model and were dropped.`
4. `Dependent counts were migrated; re-enter their names in the Dependents step.`

For `v1-web-envelope-edge-clamp.json`, in order:

1. `Saved with an older prototype: the return was migrated to the current engine model.`
2. `Dependent counts were migrated; re-enter their names in the Dependents step.`

## Consumers

- `clearfile/test/return_format_test.dart` — reads `../fixtures/migration/*.json`
  (plain `test()`, filesystem-safe outside `runAsync`), asserts the exact
  ordered warning lists and the clamped dependent count.
- `scripts/txf_taxfile_test.mjs` (CI bridge suite, cfr section) — reads the
  same files from the repo root, asserts the same exact lists.

The **v1 store shape** (`src/lib/store.ts` persist migration) is a different
vintage — its W-2 rows read `{employer, wages, federalWithheld}` — and is
documented (not fixture-pinned) in `docs/return-format.md` §3.
