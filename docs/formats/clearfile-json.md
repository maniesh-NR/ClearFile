# The `clearfile.json` family — ClearFile's own return-file format (spec 1 of the Stage-2 DoD set)

**Status:** in force (envelope v2 since 2026-11-15, ADR-015) · Spec version
1 · First published 2026-11-22 (Stage-2 execution session 1)

## Provenance (protocol §7.1)

**Owner-authored format — zero third-party samples.** The format is this
repository's own design (ADR-015: the unified return file); every specimen
cited below was written by this project's own code (the Flutter reference
app and the web prototype) and every byte of the family is re-derivable
from the checked-in sources and tests. No proprietary or third-party file
informed this spec, so nothing here is a protocol §7.2/§7.3/§7.4 concern;
the §7.5 checklist at the end is still applied and recorded.

## 1. Extension and identification

| Thing | Value |
| --- | --- |
| Canonical extension | `.clearfile.json` |
| Read-only legacy alias | `.cfr` (same bytes; the web prototype's pre-unification saves) |
| Sniff (Phase-1, `scripts/re_magic.py`) | `text (JSON-like)` — first non-whitespace byte `{`; no binary magic |
| Top-level shape | pretty-printed UTF-8 JSON object |

## 2. Container (the envelope)

```json
{
  "format": "clearfile-return",
  "version": 2,
  "app": "ClearFile 1.0.1",
  "savedAt": "2026-11-15T02:00:00.000Z",
  "filing": { ... }
}
```

| Field | Type | Meaning | Verified by |
| --- | --- | --- | --- |
| `format` | string | fixed marker `clearfile-return`; anything else is refused "Unrecognized format …" | `return_format_test.dart` ("refuses unrecognized"), bridge suite cfr "honest failures" |
| `version` | number | schema version, **2**; higher refuses "Unsupported version N (this build supports up to 2)" — the D3 version guard | same suites' "version guard refuses" tests |
| `app`, `savedAt` | string | writer identity; informational, readers ignore | bridge suite round-trip |
| `filing` | object | the payload (§3) | all consumers below |

No checksum, no compression, no crypto at this layer (the family is plain
UTF-8 JSON; integrity is delegated to the transport — the ZIP-container
variant carries ZIP CRCs and is specified separately as
`tax-exchange-container.md`).

## 3. Record layout — the `filing` payload (v2)

The field table is the model contract; names are identical in Dart
(`clearfile/lib/models/tax_return.dart`) and TypeScript
(`src/lib/tax/engine.ts`). All money fields are plain JSON numbers (US
dollars). Readers tolerate missing fields by defaulting and SAY so (§5).

| Group | Fields |
| --- | --- |
| Identity/metadata (Flutter-written) | `id`, `displayName`, `created`, `modified` (ISO-8601) |
| Filing status | `taxYear` (2025), `filingStatus`: `single` \| `marriedJoint` \| `marriedSeparate` \| `headOfHousehold` \| `survivingSpouse` |
| Status flags | `taxpayer65OrOlder`, `spouse65OrOlder`, `taxpayerBlind`, `spouseBlind` (booleans) |
| Income | `w2s` (list of `{employer, wages, withholding}`), `interestIncome`, `ordinaryDividends`, `qualifiedDividends`, `longTermCapitalGains`, `otherIncome` |
| Adjustment | `studentLoanInterest` |
| Deductions | `deductionMethod`: `auto` \| `standard` \| `itemized`; `stateLocalIncomeOrSalesTax`, `realEstateTax`, `mortgageInterest`, `charitableCash`, `charitableNonCash` |
| Payments | `estimatedPayments` |
| Dependents | list of `{name, age, relationship, qualifyingChild, otherDependentCredit}` |

Verified by: `return_format_test.dart` (14 codec tests),
`json_roundtrip_test.dart`, the 17 golden fixtures' `input` blocks, and the
bridge suite (`scripts/txf_taxfile_test.mjs`, cfr section: envelope
round-trip + field-for-field asserts).

## 4. Accepted vintages (migration matrix)

| Vintage | Shape | On read |
| --- | --- | --- |
| v2 envelope (current) | §2 | parsed directly |
| v1 envelope (pre-parity web `.cfr`) | `{format, version: 1, filing: {status, interest, dividends, adjustments, itemized{…}, qualifyingChildren, otherDependents, w2s}}` | conservative migration; every drop warned (§5) |
| legacy flat layout (Flutter ≤ 1.0.1 exports/store) | `{format: "clearfile.return", formatVersion: 1, …filing fields at top level…}` | lossless envelope lift; a flat `formatVersion > 1` refuses |
| anything else | — | refused: "Unrecognized format" |

The v1→v2 conservative mapping (identical in both readers, warning
wording included): `status` `mfj`/`mfs`/`hoh` → the full names; `interest` →
`interestIncome`; `dividends` → `ordinaryDividends`; `adjustments`,
`itemized.medical`, `itemized.other` **dropped with warnings**;
`itemized.taxesPaid` → `stateLocalIncomeOrSalesTax`; `itemized.charity` →
`charitableCash`; child counts → placeholder dependent rows (warned);
`taxYear` forced to 2025. Verified by: the bridge suite's "v1 migration
with warnings" section + `return_format_test.dart` migration tests (the
known triple-implementation drift is registered as DEBT D34).

## 5. Reader contract (warnings and outcomes)

Successful imports carry warnings as data: one per dropped v1 field, plus
"Filing status was missing; defaulted to single.", "Tax year was missing or
unsupported; defaulted to 2025 (the engine supports TY2025).", and the
web-side "Return metadata (name, dates) … not carried by the web
prototype." The Flutter import returns a **sealed outcome**
(`ReturnImport`: cancelled | failed-with-reason | ok-with-warnings); the web
returns the `parseCfr` warnings list. Verified by:
`return_format_test.dart` outcome tests + the bridge suite's warning-shape
asserts.

## 6. Where the code lives (verification anchors)

| Side | Encoder | Decoder | Guard |
| --- | --- | --- | --- |
| Flutter | `clearfile/lib/io/return_format.dart` (`ReturnFileCodec.encode`) | same file (`decode` + `_migrateWebV1` + legacy lift) | version refusal in `decode` |
| Web | `src/lib/files/cfr.ts` (`serializeCfr`) | same file (`parseCfr` + `migrateV1` + legacy lift) | version refusal in `parseCfr` |

The Flutter autosave store writes the same envelope
(`lib/io/return_store.dart`); the exchange-container entry
(`clearfile.json` inside the `.tax`-extension ZIP) carries this same
envelope (`src/lib/files/taxfile.ts`).

## 7. Differential-analysis note (protocol Phase 3)

The differential tool (`scripts/re_diff.py`) is exercised on a synthesized
pair of this family (the Stage-2 gate's "synthesized pair inside the
mandatory set" rule): `scripts/test_re_tools.py`'s
`test_diff_synthetic_clearfile_pair_mandatory_set` writes two v2 envelopes
differing in exactly one W-2 wage digit and asserts the tool localizes a
single 1-byte region — the family's pretty-printed layout keeps a
single-field change byte-local, which is what makes user-input
differentials on this format meaningful.

## §7.5 pre-commit checklist (applied, recorded — ADR-012 mechanic (d))

- [x] No key material (§7.3) — the family has no crypto at all.
- [x] No decrypted content (§7.2) — all content is this project's own.
- [x] No expression lifts (§7.4) — no third-party text or images; no
      markdown image embeds (lint-enforced by
      `scripts/lint_format_specs.py`).
- [x] Corpus provenance stated (§7.1) — the Provenance section above:
      owner-authored, zero third-party samples.
- [x] Claims cite bytes/function names/tests (§6) — every field row and
      rule above carries its "verified by" experiment.
