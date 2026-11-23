# TXF v042 — ClearFile's verified profile (spec 3 of the Stage-2 DoD set)

**Status:** in force (Dart importer since v1.0.0; web exporter since
prototype 0.2) · Spec version 1 · First published 2026-11-23 (Stage-2
execution session 2)

## Provenance (protocol §7.1)

**A published interchange format, profiled — zero third-party samples.**
TXF (Tax Exchange Format) is a **publicly published specification** (version
V042) for moving tax data between desktop tax packages; using it is the
documented safe bridge for TurboTax-exported data (this repo's RE protocol
§2.5: prefer the published export over any format RE — no reverse
engineering touched this format, so §7.2/§7.3 never arise). This spec
documents **ClearFile's profile**: the subset its two shipped bridges read
(the Flutter importer's refnum table) and write (the web exporter), as
verified by the suites below. Every specimen cited is **synthesized by this
repository's own tests** — no TurboTax export, no third-party file, no user
data. The §7.5 checklist at the end is applied and recorded.

## 1. Extension and identification

| Thing | Value |
| --- | --- |
| Canonical extension | `.txf` |
| Sniff (Phase-1, `scripts/re_magic.py`) | text (line-oriented ASCII; first non-whitespace bytes `V042` for files this repo's ecosystem emits) |
| Top-level shape | line-oriented text: a header block, then `^`-terminated records |
| Reader gates | a file with no importable summary record is refused ("not a TXF file at all" is one of the honest outcomes) |

Verified by: `txf_import_test.dart` ("no importable summary records
throws a honest error", "empty-file edge"), the bridge suite's
`readTxf` verification mirror.

## 2. Grammar (the published V042 structure, as ClearFile implements it)

```text
header:    V042                       version
           A <program name>           exporting program (informational)
           D MM/DD/YYYY               export date
           ^                           header terminator
record:    (field line)*  ^           records are '^'-terminated
field:     T S|D     record type: summary (imported) or detail
           N <refnum> the tax line item code (the spec's table; §3)
           C <copy>  the form-copy number (W-2 copies; defaults 1)
           L <line>  the line within the item (defaults 1)
           $ <amount> an amount; a record may carry several (summed)
           P <text>  description/payer text
           X <detail> detail lines (carried, not used)
           D <date>  a date field (carried, not used)
```

The importer additionally tolerates (pinned by tests): CRLF line endings
(`\r` stripped), blank lines, whitespace-padded field values (`N 460`
parses — value side is trimmed), and a record whose first field line is
its `N…` (a `T` line may be absent — type defaults to summary per the
spec).

Verified by: `clearfile/lib/io/txf_import.dart` (`_applyField`,
`parseTxf`); `txf_import_test.dart` "record may legally start at N with no
separate TS line", "CRLF line endings and spaced field tags … both parse".

**Sign convention (spec §VII.B):** income is positive; expenses and tax
payments are negative. ClearFile's model stores positive magnitudes — the
importer takes absolute values on the expense/payment refnums (§3) and the
exporter writes the negatives (§5).

## 3. The refnum profile (what the importer maps)

| Refnum | Tax line item (per the spec's table) | Maps to |
| --- | --- | --- |
| 460 / 506 | W-2 salary, taxpayer / spouse (box 1) | per-W-2 wages |
| 461 / 507 | federal withholding, taxpayer / spouse (box 2) | per-W-2 withholding |
| 466 / 513 | W-2 payer, taxpayer / spouse | per-W-2 employer |
| 287 | interest income (Schedule B; summed across L lines) | `interestIncome` |
| 286 | total dividend income | dividends (see the 683 rule) |
| 683 | qualified dividends | `qualifiedDividends` (ordinary = total − qualified) |
| 488 | capital gain distributions | `longTermCapitalGains` |
| 257 | other income (1040 line 21 family) | `otherIncome` |
| 275 / 544 | state + local taxes paid (Schedule A) | `stateLocalIncomeOrSalesTax` |
| 276 | real estate tax (A:6) | `realEstateTax` |
| 283 / 545 | home mortgage interest (A:10/11) | `mortgageInterest` |
| 280 | cash charity (A:16) | `charitableCash` |
| 485 | non-cash charity (A:17) | `charitableNonCash` |
| 268 / 521 | federal estimated tax payments | `estimatedPayments` |
| 636 | student loan interest | `studentLoanInterest` |

W-2 grouping: each W-2 is the copy space `C` — taxpayer codes (460/461/466)
key `self:<copy>`, spouse codes (506/507/513) key `spouse:<copy>`; a
record with an amount for a slot already filled keeps the **first** and
warns ("Duplicate … record; the first one was kept."); a payer text is
kept once; a copy whose salary, withholding and payer are all empty is
dropped at import ("No W-2 wage records found — only the non-wage fields
imported." when none survive).

Verified by: `txf_import_test.dart` "canonical V042 structure imports every
mapped field" (all refnums at once), "spouse W-2 codes land in their own
copy space", the duplicate/blank-copy cases.

## 4. The reader contract (honest import, refusals, caps)

Only **summary (`TS`)** records are imported; detail (`TD`) records are
ignored per the spec's §VII.A and reported by count. Unknown refnums are
never guessed at — skipped and reported both as a warning with the deduped
sorted code list and as the structured `unknownCodes` list. Unparsable `N`
values make the record malformed (skipped, counted); unparsable `$` shapes
are skipped with a per-record warning ("amount … could not be read").

Cross-field honesty rules: qualified dividends exceeding the total clamp
the ordinary portion to zero with a warning; qualified with no total warns
that the ordinary portion is unknown; the export date's year ≠ 2025 warns
that TXF carries no tax-year field (the return stays on the engine's
TY2025); `V` ≠ 042 warns that the suite pins V042 (a missing `V` warns and
parses anyway).

**Hard refusals (never crashes, all pinned by tests):**

| Cap | Refusal message |
| --- | --- |
| 5 MB file (`_maxBytes`) | "File exceeds the 5 MB parser limit (parser hardening, ADV-ENG #11)." |
| 10,000 records (`_maxRecords`, the Stage-2 entry gate's ENG-2 condition) | "More than 10,000 records (parser hardening)." |
| 4,096 characters per line (`_maxLineLength`) | "Line N exceeds the 4096-character parser limit." |
| zero importable TS records | "No importable summary (TS) records were found. The file may be a detail-only export or not a TXF file at all." |

Verified by: `txf_import_test.dart` ("unknown refnums are reported, not
guessed", "non-V042 version and off-year export date produce notes",
"unparsable amounts are skipped with a warning", the three hardening-cap
tests, the empty-file edge) — 12 tests total.

## 5. The writer profile (the web exporter)

`exportTxf` writes exactly this subset: the header (`V042`, `A ClearFile
<year> (web prototype)`, `D` export date, `^`), then per W-2 (copy
C1, C2, …): an optional payer record `466` (format-2: text only, no `$` —
emitted only when the employer is non-blank), the salary `460` (positive),
the withholding `461` (**negative**, per the sign convention; a zero stays
plain zero), then `287` interest (positive, described) and `636`
student-loan interest (negative) when > 0. Every record carries explicit
`C` and `L1`; the file ends with a trailing newline; an empty return
exports the header only — still a valid TXF file.

The exported demo scope is disclosed in-app: only W-2
wages/withholding/payers, interest and student-loan interest leave the web
prototype, and the UI says to verify the import in the receiving software.

Verified by: `scripts/txf_taxfile_test.mjs` section 1 — the exporter is
read back by an independent spec-shaped reader (`readTxf`) asserting the
header shape, summary-only records, payer format-2 (no amounts), copy
sequences, the sign convention values, the blank-employer no-466 rule and
the empty-return edge ("an exporter whose output a spec-shaped importer
cannot read is a bug, not a style choice").

## 6. Where the code lives (verification anchors)

| Side | Module | Role |
| --- | --- | --- |
| Flutter | `clearfile/lib/io/txf_import.dart` (`parseTxf`, `TxfImportResult` / `TxfImportOutcome`) | the importer — the full §3 table |
| Web | `src/lib/files/txf.ts` (`exportTxf`) | the exporter — the §5 subset |
| CI bridge | `scripts/txf_taxfile_test.mjs` (txf section, 2 groups) | exporter↔spec-reader round-trip |
| Dart suite | `clearfile/test/txf_import_test.dart` (12 tests) | importer grammar, mapping, honesty, caps |

## 7. Differential-analysis note (protocol Phase 3)

A one-field edit in a TXF file is byte-local by construction (plain text,
line-oriented): the differential tool family applies trivially to
user-authored pairs, and no differential is pinned inside this family —
the mandated synthesized pair inside the DoD set is exercised in families
#1 and #2 (`test_re_tools.py`; `docs/formats/clearfile-json.md` §7 and
`docs/formats/tax-exchange-container.md` §6).

## §7.5 pre-commit checklist (applied, recorded — ADR-012 mechanic (d))

- [x] No key material (§7.3) — TXF has no crypto anywhere; nothing to
      record by existence even.
- [x] No decrypted content (§7.2) — no RE occurred; every specimen is
      synthesized by this repo's own tests (Provenance above).
- [x] No expression lifts (§7.4) — the structure quotes a published
      functional interchange spec (field letters, refnum semantics —
      17 USC §102(b) subject matter, cited functionally); no third-party
      files, text or images; no markdown image embeds (lint-enforced by
      `scripts/lint_format_specs.py`).
- [x] Corpus provenance stated (§7.1) — the Provenance section above:
      a published spec, profiled by owner-authored code; zero third-party
      samples.
- [x] Claims cite bytes/function names/tests (§6) — every grammar row,
      mapping row and refusal above carries its "verified by" test or
      code anchor.
