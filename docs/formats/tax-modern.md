# The Intuit modern `.tax` return container — shape-level spec (spec 4 of the Stage-2 DoD set)

**Status:** in force · Spec version 1 · First published 2026-11-28 (the
funded T3 session 2 — owner ruling option (a) of the Stage-2 slip
re-agenda; DECISIONS.md, Owner rulings recorded 2026-11-28)

## Provenance (protocol §7.1)

**Third-party proprietary family, studied at SHAPE level only.** The
subject is Intuit TurboTax's 2017+ return-file container (`.tax` /
`.tax[YYYY]`) — not this repository's own `.tax`-extension exchange
container (spec 2). Two sources inform this spec, and both are cited per
claim:

1. **The public write-up** (Zameer Manji, "Understanding TurboTax tax
   files", January 2024,
   `zameermanji.com/blog/2024/1/7/understanding-turbotax-tax-files`):
   the format family's existence, container shape, entry set, and crypto
   class are DESCRIBED here and LINKED there — never reproduced. The
   write-up publishes per-year key values; per protocol §7.3 (and
   ADR-020's by-existence posture) **no key material, IV, or derived
   value appears in this file or anywhere in this repository**.
2. **This repository's own delivery-pipeline verification** (T2/T3
   research records + the 2026-11-28 end-to-end decode): the pipeline
   that installs the engine which reads and writes these files, verified
   in-memory and retention-free on the sha256-verified corpus
   (`docs/re-research/corpus-manifest.md` holds the hashes; they are not
   repeated here per the lint's by-existence rule).

**No owned `.tax` sample exists.** The corpus holds the four publicly
posted installers; no `.tax` return file is owned, and none is required
by the Stage-2 entry gate's DoD (the named spec 4 charter: the
container's *existence and shape*, linked to the public write-up — the
"specs on the owner's own licensed `.tax` files are bonus, never
required" clause). The interior is therefore documented from the
write-up's shape facts only; §5 records exactly what that means. The
§7.5 checklist is applied and recorded at the end.

## 1. Family identification

| Thing | Value |
| --- | --- |
| Family | Intuit TurboTax return files, 2017+ (the write-up documents the 2017 and 2019 tax years) |
| Extension | `.tax` (year-suffixed naming per the write-up) |
| Container class | ZIP (`PK` signatures — the same sniff class as spec 2) |
| Distinguishing fact | exactly two entries with the §2 names — any other entry set is not this family |

**Namespace collision, stated honestly:** ClearFile's own exchange
container (spec 2) deliberately shares the `.tax` extension. The two are
distinguished by their entry sets — spec 2's containers carry a
`clearfile.json` entry; this family carries `manifest.xml` + one `tax:`
entry. A ClearFile reader that sniffs a ZIP will honestly report an
Intuit return file as "not a ClearFile container" (the spec 2 reader
contract), which is the correct behavior: the two formats are unrelated.

## 2. Container shape (per the public write-up — described and linked, not reproduced)

- The container is a **ZIP holding exactly two entries**:
  1. `manifest.xml` — decrypts to XML; carries the metadata for the
     returns held in the file (the list of returns plus per-return
     metadata, including the tax year).
  2. **one tax-data entry whose name begins `tax:` followed by a UUID**
     (the write-up's example shape: `tax:` + a hyphenated UUID) —
     decrypts to the tax return XML (its `taxYear` attribute carries the
     year; the schema is not publicly documented but parses as ordinary
     XML).
- **Crypto class (existence only, §7.3):** both entries are encrypted
  with **AES-CBC using 16-byte (128-bit) keys**; the manifest and the
  tax-data entry use **different keys**; the keys are **per tax year and
  embedded in the TurboTax binary**. The key/IV VALUES are published in
  the write-up and are deliberately NOT recorded here or anywhere in the
  repo — linking is describing; reproducing is trafficking (protocol
  §7.3, verbatim posture).
- ADR-020 relevance (recorded, not acted on): the T4 bridge's sanctioned
  fixed-key module would consume the per-year key table as its
  quarantined, provenance-labeled implementation — the ONE sanctioned
  exception to by-existence, and it does not exist yet (T4 is funded,
  entry gate pending; no T4 code exists).

## 3. What this repository has verified around the family (the delivery pipeline, 2026-11-28)

The engine that reads and writes these files arrives through a delivery
pipeline this repository verified **end-to-end** in the funded T3
session 2 (the chase record:
`docs/re-research/2026-11-28-tt-t3-session2.md`; prior layers: the T2
records). Every claim below is a byte-verified function fact with the
verification artifact named:

1. **The ISSetupStream v7/v8 record grammar** (both targets re-walked
   this session): the 46-byte stream header (`ISSetupStream\0` + u16
   version label + u32 generation 4 + 26 zero bytes) followed by the
   v4-generation record table — the byte-derived field offsets
   (correcting the T2 session-3 prose's field boundaries): namelen u32
   @+0x00, flags u32 @+0x04, u16 0 @+0x08, **dsize u32 @+0x0A**, u32 0
   @+0x0E, u16 0 @+0x12, **u16 = 1 @+0x16**, three u64 FILETIMEs
   @+0x18/+0x20/+0x28, UTF-16LE name @+0x30, payload @+0x30+namelen.
2. **The record transport cipher** (the recorded variant-A: the record's
   own UTF-8 filename masked bytewise with the 4-byte constant, each
   byte `plain = ~(swapnib(enc) ^ maskedKey[(p mod 1024) mod keylen])`)
   — **verified END-TO-END on both MSI-record targets with byte-exact
   arithmetic closure**: Personal-USA 2026 (`TurboTax 2026.msi`, dsize
   383,877,541 consumed exactly → 390,117,376 bytes out, Z_STREAM_END)
   and Personal-CAN 2025 (`TurboTax 2025.msi`, dsize 246,582,748
   consumed exactly → 251,319,296 bytes out, Z_STREAM_END). **No
   keystream divergence exists** — the previously recorded "0x24000
   divergence" (the Stage-2 exit-gate slip's technical premise, D42's
   chase item) is disposed as a bench artifact of the wiped
   session's pipeline; the variant-A formula is complete as recorded.
3. **The deep stack**: the MSI record inflates to an OLE compound file →
   the embedded MSCF cabinet (121 folders, 6,503 entries) → the app
   modules, including the `ttax` engine DLL (the T2 session-3/T3
   session-1 inventory, existence-level).

## 4. The engine-module anchors (existence-level, from the T3 session 1 triage)

Identifier-level facts about the module that implements this family's
read/write layer (no expression, no key material — §7.4/§7.3):

- **Crypto++ is embedded** (the library's own exception-string cluster
  at the `.rdata` RVAs recorded in the T3 session-1 note) — the crypto
  primitive library for the layer, consistent with §2's AES-CBC class.
- **The `IData::` serialization family** (`Open`, `ReadString`,
  `ReadVector`, `WriteString`, `WriteVector`, `Close`, `Swap`, `Proxy`)
  — the return-data object I/O surface the container's payload feeds.
- **The password surfaces exist** (the save-dialog encryption-checkbox
  string class; the transfer-service password-on-read diagnostic) —
  recorded at existence level. **The relationship between the optional
  user password feature and §2's per-year embedded-key AES layer is
  UNRESOLVED** and is recorded as an open question riding D42 — this
  spec does not conflate them.
- **A cross-check that supports the write-up's shape:** the engine
  module imports **no ole32** and carries **zero structured-storage
  constants** (the T3 session-1 negative finding) — consistent with §2's
  ZIP container (the `.tax` layer is not OLE inside the engine module).

## 5. Honest limits

- **No owned sample** — every interior claim in §2 rests on the linked
  public write-up, not on a byte-level verification by this repo. The
  delivery-pipeline facts in §3–§4 are this repo's own verified work;
  the container-interior facts are not.
- The **password-mechanism relationship** (user password vs per-year
  embedded key) is unresolved (D42 ride-along).
- D42's remaining residues ride their lanes: the 26 MB module's REA
  import strategy (c) and the mixed-mode export-table glitch (d).
- The CAN-Business classic `ISc` layer is un-entered (T2 session-3
  limit) — it has no MSI record and is out of this spec's scope.
- The write-up documents 2017 and 2019 explicitly; other years' keys
  follow the same per-year embedded pattern per the write-up's framing —
  recorded as the write-up's claim, not this repo's verification.

## 6. Namespace note (the Stage-2 DoD boundary)

This file is the Stage-2 DoD's **named spec 4** (the entry gate's fixed
N=4 list). The TT program's deeper format-family deliverables — notably
the password layer's clean-room documentation — are **distinct future
artifacts under `docs/re-research/`** per the namespace rule (TT gate
PROD-3/ENG-6): TT specs never count toward Stage-2's N=4, and this
file's presence in `docs/formats/` is the DoD's own named list, not TT
scope creep. T3 session 2 funded this file's landing together with the
keystream chase; the two are recorded separately (the chase in the
re-research note, the spec here).

## §7.5 pre-commit checklist (this spec)

No key material (§7.3 — the write-up's key values are deliberately
unrecorded; crypto by existence only) — pass; no decrypted content
(§7.2 — nothing decrypted is quoted; the pipeline decode recorded counts
and closures only) — pass; no expression lifts (§7.4 — identifiers,
offsets, counts; proprietary strings paraphrased; no images) — pass;
corpus provenance stated (§7.1 — the four installer targets,
`corpus-manifest.md`; no `.tax` sample owned, stated) — pass; every
claim cites an offset, a count, a named verification artifact, or the
linked write-up (§6) — pass. Manual ≥32-hex scan of this file: clean
(LEGAL-4; the lint's hex-run rule is the mechanical backstop).
