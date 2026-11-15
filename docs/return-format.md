# The ClearFile return file format (`docs/return-format.md`)

**Status:** unified format, in force since 2026-11-15 (ADR-015, Stage-3
close-out) · Written by the Flutter app (export + autosave) and the web
prototype · Pinned by `clearfile/test/return_format_test.dart` (14 tests)
and the CI bridge suite (`scripts/txf_taxfile_test.mjs`, cfr section)

---

## 1. The file

A ClearFile return file is pretty-printed UTF-8 JSON with the extension
**`.clearfile.json`** and this envelope:

```json
{
  "format": "clearfile-return",
  "version": 2,
  "app": "ClearFile 1.0.1",
  "savedAt": "2026-11-15T02:00:00.000Z",
  "filing": { ...the TaxReturnData payload... }
}
```

- `format` — the fixed marker `clearfile-return`. Anything else is
  refused with "Unrecognized format …" (a clear error, never a silent
  null).
- `version` — the schema version, currently **2**. **Version guard**: a
  file claiming a version higher than the build supports is refused
  ("Unsupported version N (this build supports up to 2)") — future
  files are never guessed at (DEBT D3: no format change ships before a
  version guard).
- `app`, `savedAt` — informational writer identity; readers ignore them.
- `filing` — the payload: the shared `TaxReturnData` model both engines
  compute from (the parity shape, ADR-009). The Flutter app additionally
  writes return metadata (`id`, `displayName`, `created`, `modified`);
  the web prototype's model does not carry those fields, so a
  Flutter-written file opened on the web keeps them in the file but
  reports that they are "not carried by the web prototype".

Where the envelope lives:

| Medium | Writer | Reader |
| --- | --- | --- |
| `.clearfile.json` export (file picker) | Flutter `lib/io/files.dart` | both |
| Web "Save return" download | web `src/lib/files/cfr.ts` | both |
| Flutter autosave store (`returns/<id>.json`, app-private) | Flutter `lib/io/return_store.dart` | Flutter store on next launch |
| `clearfile.json` entry inside the ClearFile exchange container (`.tax`-extension ZIP) | web `src/lib/files/taxfile.ts` | both `.tax` inspectors |

## 2. The `filing` payload (version 2)

The fields below are the model contract (names are identical in Dart and
TypeScript). All money fields are plain JSON numbers (dollars, cent
precision where the engine computes it); readers tolerate missing fields
by defaulting, and say so (see §4).

- Identity/metadata (Flutter-written): `id`, `displayName`, `created`,
  `modified` (ISO-8601).
- `taxYear` (the engines support **TY2025**; a file claiming another year
  is migrated to 2025 with a warning), `filingStatus`
  (`single` | `marriedJoint` | `marriedSeparate` | `headOfHousehold` |
  `survivingSpouse`).
- Status flags: `taxpayer65OrOlder`, `spouse65OrOlder`, `taxpayerBlind`,
  `spouseBlind`.
- Income: `w2s` (list of `{employer, wages, withholding}`), 
  `interestIncome`, `ordinaryDividends`, `qualifiedDividends`,
  `longTermCapitalGains`, `otherIncome`.
- Adjustment: `studentLoanInterest`.
- Deductions: `deductionMethod` (`auto` | `standard` | `itemized`),
  `stateLocalIncomeOrSalesTax`, `realEstateTax`, `mortgageInterest`,
  `charitableCash`, `charitableNonCash`.
- Payments: `estimatedPayments`.
- `dependents` (list of `{name, age, relationship, qualifyingChild,
  otherDependentCredit}`).

## 3. Accepted vintages (the migration matrix)

| Vintage | Shape | On read |
| --- | --- | --- |
| **v2 envelope** (current) | above | parsed directly |
| **v1 envelope** (pre-parity web `.cfr`) | `{format, version: 1, filing: {status, interest, dividends, adjustments, itemized{taxesPaid, mortgageInterest, charity, medical, other}, qualifyingChildren, otherDependents, w2s}}` | migrated with the conservative mapping; every drop is warned (see §4) |
| **legacy flat layout** (Flutter ≤ v1.0.1 exports and store files) | `{format: "clearfile.return", formatVersion: 1, ...filing fields at the top level...}` | lossless envelope lift (the fields are the same model); a flat `formatVersion > 1` is refused |
| anything else | — | refused: "Unrecognized format" |

The v1 conservative mapping (applied identically by both readers — the
Dart `ReturnFileCodec._migrateWebV1` mirrors the web `migrateV1`
field-for-field, warning wording included):

- `status` `mfj`/`mfs`/`hoh` → `marriedJoint`/`marriedSeparate`/
  `headOfHousehold`; other values pass through; missing → `single` +
  warning.
- `interest` → `interestIncome`; `dividends` → `ordinaryDividends`;
  `adjustments` **dropped** (warned: re-enter as student loan interest if
  that is what it was).
- `itemized.taxesPaid` → `stateLocalIncomeOrSalesTax`;
  `itemized.mortgageInterest` → `mortgageInterest`; `itemized.charity` →
  `charitableCash`; `realEstateTax`/`charitableNonCash` → 0;
  `itemized.medical`/`itemized.other` **dropped** (warned).
- `qualifyingChildren`/`otherDependents` counts → placeholder dependent
  rows (warned: re-enter their names in the Dependents step).
- `taxYear` forced to 2025.

## 4. Warnings and outcomes (the reader contract)

Both readers surface the same conditions, as warnings on a successful
import:

- "Saved with an older prototype: the return was migrated to the current
  engine model." (any v1 file)
- One warning per dropped v1 field (above).
- "Filing status was missing; defaulted to single."
- "Tax year was missing or unsupported; defaulted to 2025 (the engine
  supports TY2025)."
- "Return metadata (name, dates) from the Flutter app is kept in the file
  but not carried by the web prototype." (web reader, flat/envelope files
  written by the Flutter app)

The Flutter import flow reports these through a **sealed outcome**
(`ReturnImport`: `ReturnImportCancelled` | `ReturnImportFailed(reason)` |
`ReturnImportOk(filing, warnings)`) — cancelled is silent, failures show
their reason, migrations show their notes (DEBT D1). The web import flow
reports them through the `parseCfr` warnings list and its toast/dialog
treatment.

## 5. Extension policy

- **`.clearfile.json`** is the canonical extension (self-describing JSON;
  what both codebases download/save now).
- **`.cfr`** is a read-only legacy alias: the web prototype's earlier
  saves still open in both apps (the Flutter picker accepts `cfr`; the
  web input accepts `.cfr,application/json,.json`).
- The **`.tax`-extension exchange container** is a different thing (an
  open ZIP with `clearfile.json` + `README.txt` entries — see
  `src/lib/files/taxfile.ts`); it is NOT Intuit's format, and its
  `clearfile.json` entry carries this same envelope.

## 6. Where the code lives

| Side | Encoder | Decoder | Guard |
| --- | --- | --- | --- |
| Flutter | `clearfile/lib/io/return_format.dart` (`ReturnFileCodec.encode`) | same file (`decode` + `_migrateWebV1` + legacy lift) | version refusal in `decode` |
| Web | `src/lib/files/cfr.ts` (`serializeCfr`) | same file (`parseCfr` + `migrateV1` + legacy lift) | version refusal in `parseCfr` |

Store compatibility: the Flutter autosave writes the same envelope
(`lib/io/return_store.dart`), so an exported file and a saved return are
interchangeable; pre-unification store files (flat layout) migrate on
next launch. Corrupt or future-version files in the store are skipped,
not fatal.

## 7. Versioning policy

The envelope version bumps only when the **filing schema** changes
(fields renamed/removed/semantics altered). A bump ships as: write the
new version, read the new and all prior vintages with migration + 
warnings, refuse anything newer. The guard is the enforcement of D3's
rule — no format change ships before a version guard — and both engines'
suites pin it (`return_format_test.dart` "version guard refuses…";
bridge suite "version guard + honest failures").
