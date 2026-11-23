# The ClearFile exchange container — the `.tax`-extension ZIP (spec 2 of the Stage-2 DoD set)

**Status:** in force (web writer since prototype 0.2; both readers since
2026-11-15) · Spec version 1 · First published 2026-11-23 (Stage-2
execution session 2)

## Provenance (protocol §7.1)

**Owner-authored format — zero third-party samples.** The container is this
repository's own design (the web prototype's `.tax`-extension exchange
wrapper): an ordinary STORE-method ZIP the prototype writes so a user can
keep one `.tax` file per year and re-import it. Every specimen cited below
was written by this project's own code (`makeZip` / `exportTaxContainer`)
or synthesized by its own tests (the STORE-writer port inside
`test_re_tools.py`, the synthetic containers in `tax_inspect_test.dart` and
the bridge suite). No proprietary or third-party file informed this spec —
the Intuit `.tax` family is a different thing and is only *recognized* at
shape level (§5); nothing here is a §7.2/§7.3/§7.4 concern. The §7.5
checklist at the end is applied and recorded.

## 1. Extension and identification

| Thing | Value |
| --- | --- |
| Canonical extension | `.tax` (shared by design with Intuit's — §5 says why that is safe and honest) |
| Sniff (Phase-1, `scripts/re_magic.py`) | ZIP local signature `PK\x03\x04` at offset 0 (also `PK\x05\x06` empty / `PK\x07\x08` spanned) |
| Reader gate (both sides) | `P` `K` then 0x03/0x05/0x07 in bytes 2–4 of a >4-byte file (`_looksZip` in `tax_inspect.dart` / `isZip` in `taxfile.ts`) |
| Distinguishing fact | the `clearfile.json` entry (§3) — any other ZIP is honestly reported as "not a ClearFile container" |

Verified by: `tax_inspect_test.dart` "non-ZIP file" + "empty file" honest
paths; bridge suite `[tax] non-ZIP and empty honest paths`.

## 2. Container structure (what the writer emits)

A minimal, dependency-free ZIP: **STORE method only** — entries are never
compressed, so payload bytes sit verbatim in the file (this is what makes
the format diff-friendly, §7). Per entry, in file order:

```text
local file header   30 bytes + name
  0x04034b50  signature (little-endian u32)
  20          version needed to extract
  0x0800      general-purpose flags (bit 11: UTF-8 names)
  0           compression method (STORE)
  DOS time, DOS date (writer clock; epoch 1980)
  CRC-32      of the entry data (reflected 0xedb88320 polynomial)
  size        compressed size = uncompressed size (STORE)
  name length, extra length 0
  entry name bytes, then the raw entry data
central directory   46 bytes + name, per entry (same CRC/sizes)
  0x02014b50  signature · 20/20 versions · same flags/method/time/date
  name/extra/comment lengths, disk, internal 0, external 0
  local-header offset
end of central directory   22 bytes
  0x06054b50  · disk 0 · this-disk/total entry counts
  central-directory size, central-directory offset, comment length 0
```

Entries, always exactly two, in order:

| Entry | Content |
| --- | --- |
| `clearfile.json` | the **v2 unified envelope** (`serializeCfr` output — `docs/formats/clearfile-json.md` §2) |
| `README.txt` | the fixed honest-labeling text (`TAX_CONTAINER_README`, quoted below) |

Verified by: `makeZip`/`exportTaxContainer` in `src/lib/files/taxfile.ts`
(writer), the bridge suite `[tax] ClearFile exchange container round-trip`
(reads what `makeZip` wrote — header fields, counts, both entries),
`tax_inspect_test.dart`'s `_makeZip` port (the same field layout, mirrored
field-for-field) and the 648-byte synthesized pair in
`test_re_tools.py::test_diff_synthetic_exchange_container_pair`.

**The honest labeling (README.txt, verbatim owner text).** The writer fixes
the user-facing disclosure inside every container: "This file uses the .tax
extension but it is NOT Intuit's proprietary TurboTax .tax format. It is an
open ZIP container written by the ClearFile prototype containing:
clearfile.json … This container keeps one ".tax" file per year for your own
records and can be re-imported here at any time." — `TAX_CONTAINER_README`
(`src/lib/files/taxfile.ts`). The same disclaimer is carried in-app by both
inspectors' summaries ("This is a ClearFile exchange container (.tax
extension, open ZIP format)").

## 3. Reading the container (the reader contract, both sides)

Both readers (`readZip` in `taxfile.ts`, `_readZipDirectory` in
`tax_inspect.dart`) walk the **central directory**, never a linear scan:

1. Locate the EOCD from the tail, bounded to the last 66,000 bytes (the
   ZIP format's 65,535-byte comment bound); no EOCD found → the honest
   note "No ZIP end-of-central-directory record found." and no entries.
2. Walk central-directory records up to `count`, under the **4,096-entry
   hardening cap** (untrusted input; both readers). A record whose header
   would run past EOF → "Central directory truncated or corrupt; stopped
   early." and the walk stops.
3. Per record: name, method, sizes from the directory; the entry data is
   extracted **only for STORE (method 0)** — Deflate (method 8) entries are
   listed with the note "… is deflate-compressed; listed only / not
   extracted (shown only)", other methods "… uses unsupported compression
   method N; skipped." No third-party inflate implementation is bundled:
   the ClearFile writer itself never compresses, so its own containers
   always read fully.
4. STORE extraction bounds: the local header must be intact
   (`0x04034b50`) and `dataStart + compressedSize` must not run past EOF —
   an entry claiming more bytes than the file holds is skipped with the
   note `Entry "<name>" extends past end of file; skipped.`
5. The Dart reader additionally bounds-checks the central-directory **name
   length** before slicing (the Stage-2 entry-gate ENG-1 crash fix:
   a crafted 46-byte-fitting header with a name length past EOF used to
   `RangeError`; now "Central directory entry name extends past end of
   file; stopped early." — the only intentional asymmetry between the two
   readers, a strictly-added guard).

Verified by: `tax_inspect_test.dart` (10 tests — the truncated-ZIP and
crafted-past-EOF never-throws guards, deflate-listed-only, the exchange
container import incl. the cross-codebase web-envelope shape, the
Intuit-shape detection, the honest non-ZIP/empty paths) and the bridge
suite `[tax]` groups (4).

## 4. The analysis behavior (what an unknown `.tax` file gets)

`analyzeTaxFile` (both sides, mirrored outcome-for-outcome) classifies:

- **ClearFile container** — a `clearfile.json` entry whose bytes parse as
  the unified envelope (any accepted vintage, §3 of
  `docs/formats/clearfile-json.md`; migrations surface as the same
  warnings): imported fully, `clearfileContainer` true. An unparseable
  `clearfile.json` (not JSON, not a ClearFile return, future version) is
  **not** fatal: the file falls through to the plain-ZIP analysis with the
  warning `clearfile.json could not be parsed: <reason>`.
- **Modern Intuit container shape** — a `manifest.xml` entry plus a
  `tax:<uuid>` entry: recognized (`intuitModernContainer` true), entries
  listed with per-entry Shannon entropy over stored data (≥128 bytes;
  entropy ≥ 7.5 bits/byte flags `likelyEncrypted` — the AES-layer signature,
  protocol Phase 1), and **nothing decrypted, ever** (protocol §2.2/§7:
  the summaries say so and point at the safe bridges — TurboTax's own TXF
  export and the printed PDF). The shape-level detail of that family is
  the DoD spec `tax-modern.md` (awaiting the T3 format-family findings).
- **Any other ZIP** — entries listed; "No ClearFile return payload was
  found, so nothing can be imported automatically."
- **Non-ZIP** — whole-file entropy reported (Phase-1 passive
  identification: encrypted/legacy-binary vs textual) with the honest
  "unrecognized container" summary; an empty file reports "The file is
  empty."

Verified by: the same tests as §3 plus the bridge suite's
`[tax] Intuit container shape detected + flagged encrypted` (synthetic
high-entropy payload via a deterministic xorshift32 stream — flagged, never
decrypted) and `[tax] low-entropy textual entry`.

## 5. Where the code lives (verification anchors)

| Side | Writer | Reader / analyzer |
| --- | --- | --- |
| Web | `src/lib/files/taxfile.ts` — `makeZip` (STORE-only ZIP), `exportTaxContainer` (the two entries), `TAX_CONTAINER_README` | same file — `readZip`, `analyzeTaxFile`, `shannonEntropy` |
| Flutter | (no writer — the app exports `.clearfile.json` directly) | `clearfile/lib/io/tax_inspect.dart` — `analyzeTaxFile`, `_readZipDirectory`, `_looksZip`, `_entropy` |

Both analyzers consume the same envelope via their unified codecs
(`parseCfr` / `ReturnFileCodec.decode`), so one container reads on both
sides — pinned by the cross-codebase test in `tax_inspect_test.dart`
("web-written envelope container imports", ADR-015).

## 6. Differential-analysis note (protocol Phase 3)

`scripts/re_diff.py` is exercised on a synthesized pair inside this
mandatory family (`test_re_tools.py::test_diff_synthetic_exchange_container_pair`):
two 648-byte containers differing in **one wage digit** inside the STORE'd
`clearfile.json` entry. The tool localizes **exactly 3 regions** —

```text
A@14 (0xe)    len 4    the local-file-header CRC-32
A@282 (0x11a) len 1    the wage digit inside the entry data
A@528 (0x210) len 4    the central-directory CRC-32
```

— which is the container's differential signature: a single-user-field
edit stays **byte-local in the payload** (STORE, no compression — the same
change in a Deflate-compressed container would smear across the whole
compressed stream) plus the two mechanical CRC-32 couplings the format
itself maintains. User-input differentials on this container are therefore
meaningful and cheap to attribute (offsets and entropy only — no bytes
echoed, §7.2/§7.4).

## §7.5 pre-commit checklist (applied, recorded — ADR-012 mechanic (d))

- [x] No key material (§7.3) — the container has no crypto at all; the
      recognized Intuit family's AES layer is described by existence
      only (§4/§5), never by value.
- [x] No decrypted content (§7.2) — all content is this project's own;
      nothing of the Intuit family is ever decrypted, by this spec or by
      the code it describes.
- [x] No expression lifts (§7.4) — no third-party text or images; the only
      quoted text (§2) is this project's own README disclosure; no
      markdown image embeds (lint-enforced by
      `scripts/lint_format_specs.py`).
- [x] Corpus provenance stated (§7.1) — the Provenance section above:
      owner-authored, zero third-party samples.
- [x] Claims cite bytes/function names/tests (§6) — every structure row,
      reader rule and differential claim above carries its "verified by"
      experiment or code anchor.
