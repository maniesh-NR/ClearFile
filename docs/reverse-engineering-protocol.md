# ClearFile — Reverse-Engineering Protocol for Legacy Tax-Software Formats

**Status:** research playbook · **Last updated:** 2026-11-03
**Scope:** read-only, interoperability-oriented format study of legacy consumer
tax-preparation file formats. ClearFile itself stores returns in its open
`.clearfile.json` format and exports TXF; nothing in this protocol is required
to use ClearFile.

---

## 1. Targets and what is publicly known

| Extension | Best current understanding | Public documentation |
| --- | --- | --- |
| `.tax` / `.tax[YYYY]` (2017+) | ZIP container holding an encrypted `manifest.xml` plus one encrypted tax-data entry (XML with Intuit `Ctg/Pta/TurboTax` namespaces). AES-CBC, 16-byte key/IV per year embedded in the TurboTax binary. | Yes — Zameer Manji's write-up (Jan 2024), zameermanji.com/blog/2024/1/7/understanding-turbotax-tax-files |
| `.tax` (mid-1990s–2005) | Undocumented binary; structure changes across years. Community requests to open them go back decades with no public spec. | None found |
| `TT[YYYY]STATE` | TurboTax desktop state-module data (downloaded state programs). Assumed binary container — **unverified**. | None found |
| `.1PE`, `.3PE`, `.3ME`, `.1PH` | TurboTax desktop forms-engine files shipped inside the Windows program directory. Numeric prefix and suffix meaning (product tier, engine generation) is **unverified hypothesis**, not established fact. | None found |
| `.LIF`, `.FIL`, `.RCD`, `.DGC`, `.SCD`, `.THP`, `.TVL` | Provenance unknown on current evidence — possibly other Intuit professional products (Lacerte/ProSeries families) or legacy generations. **No public documentation located as of 2026-11-03.** | None found |

The honest starting position: only the modern `.tax` family has a public
write-up. Everything else on the list begins as an unknown binary and goes
through the discovery protocol below. Do not treat forum folklore or this
table's hypotheses as facts — verify against bytes.

## 2. Legal guardrails (read first, every session)

1. **Intuit's EULA prohibits reverse engineering** of its software and may
   restrict the data files. In the US, intermediate copying for
   interoperability has fair-use support (*Sega v. Accolade*, *Sony v.
   Connectix*), and 17 U.S.C. §1201(f) gives a narrow interoperability
   research exemption to the DMCA anti-circumvention rule — but these protect
   *research*, not *distribution* of circumvention material.
2. **The AES layer on modern `.tax` files is a technological protection
   measure.** Analyzing it privately for interoperability with your own
   returns is defensible research; **shipping keys, IVs or ready-made
   decryptors in this repository is not.** This repo therefore documents the
   container's *existence and shape* and links the public write-up, but embeds
   no key material.
3. **Copyright splits the formats.** Field layouts, offsets, and calculation
   structure are methods/ideas (17 U.S.C. §102(b) — not copyrightable).
   Form text, interview copy, help strings and worksheets ARE copyrighted
   expression. ClearFile's clean-room line stays exactly where it has been:
   reproduce *function*, never *text*.
4. **Work only on files you own** (your own returns, your own licensed
   installs) and keep any proprietary binaries you upload to a cloud
   environment private to your account.
5. Prefer the **safe bridges** whenever they exist: TurboTax's own TXF export
   and printed PDFs already give clean-room import paths; use them where the
   goal is data, not knowledge.

## 3. Discovery protocol (applies to every unknown format)

Phase 0 — **Provenance.** Record: which product+version wrote the file, OS,
year, and where it sits (install dir vs user documents). Extensions repeat
across products; provenance disambiguates.

Phase 1 — **Passive identification (no execution, works anywhere).**
- `file`, `xxd | head`, byte histogram / Shannon entropy.
- Magic-byte scan: `PK\x03\x04` (ZIP), `MSCF` (CAB), `Rar!`, `7z`, OLE2 CFB
  (`\xd0\xcf\x11\xe0`), SQLite (`SQLite format 3`), XML/JSON/text sniffing.
- Entropy per 4 KiB block flags compressed/encrypted regions and their
  boundaries.
- Strings with offset+section: version markers, form codes (US 1040 schedules
  appear as ASCII), copyright strings — these hint at the layout inside.

Phase 2 — **Container archaeology.**
- ZIP-like: list entries (`unzip -l`, Python `zipfile`), look for
  manifests/indexes, per-entry compression, sizes vs actual (flags padding).
- OLE2/CFB: enumerate streams and storages (our web prototype's
  `ole_cfb.dart` already implements a reader).
- Unknown container: search for repeating length-prefixed records
  (try u16/u32 LE/BE length + payload), TLV runs, and alignment (4/8/16).

Phase 3 — **Differential analysis.** Two files from the same product/version
that differ in exactly one user input (e.g., one W-2 wage changed) localize
that field's byte offset. Same-version same-input files should differ only in
timestamps/IDs — this separates data from headers.

Phase 4 — **Code-assisted study of the reader/writer binary.** Ghidra on the
desktop executable: find the file-open routine via import table
(`CreateFileW`/`ReadFile`/`fopen` xrefs), trace the parsing function, export
pseudocode. This is where agents (below) genuinely accelerate the work.

Phase 5 — **Write the spec, not the extractor, first.** Record findings as a
versioned document (this file's pattern: extension, provenance, container,
record layout, field table with offsets/dtypes/units, checksums, crypto
presence). Implementation follows the spec — that ordering is what keeps the
process clean-room.

## 4. Where to run it — environment comparison

### A. Cloud VM (Linux, private) — good for Phase 1–4 batch work
- Ghidra (GUI via RDP/VNC or headless `analyzeHeadless`) + JDK 21; radare2,
  `binwalk`, `7z`, Python (Kaitai Struct, `pycryptodome` *for private
  research only* — see §2).
- Best for: long batch runs, many files, big binaries.
- Caveats: keep the VM private (license §2.4); ephemeral cloud disks lose
  Ghidra projects — snapshot or export `.gzf`; nothing here needs GPU.

### B. Google Colab — good for Phase 1–3 notebooks, weak for Phase 4
- Pure-Python format poking (entropy plots, magic scans, differential diffs)
  works well as shareable notebooks; mount Google Drive for files.
- Ghidra headless *can* run in Colab (JDK + zip download per session) but
  re-installs every session and has no GUI; fine for scripted decompile
  sweeps, clumsy for exploration.
- Caveats: session limits, no persistent state, and uploading proprietary
  binaries means they sit in your Drive — keep the folder private.

### C. Windows 10 + Google Antigravity + Ghidra + GhidraMCP + REA — strongest
for interactive Phase 4
- **Antigravity** (free, agent-first IDE; agent runs in editor + terminal +
  browser and verifies with artifacts) supports external MCP servers. Add
  GhidraMCP via the Agent panel → "..." → *Manage MCP Servers* → *View raw
  config*; config lives in `~/.gemini/config/mcp_config.json` (global) or
  `.agents/mcp_config.json` (workspace), and remote servers use `serverUrl`
  (not `url`). Known quirk: an MCP server's default working directory can be
  the Antigravity program folder, not the project — keep server configs
  path-absolute.
- **GhidraMCP** (LaurieWired, MIT) runs as a Ghidra plugin + Python bridge
  (default `localhost:8080`) exposing decompile, method/class/import listing
  and renaming to any MCP client; needs Ghidra 12.1.4 and Python ≥3.10/uv;
  headless mode via PyGhidra exists.
- **REA (Reverse Engineer Anything)** — viral late-2026 CLI that fronts
  Ghidra/Hopper/IDA, emits pseudo-code, maps modules/call paths and monitors
  network activity; built to be driven by coding agents. Useful as an
  agent-invocable batch analyzer alongside GhidraMCP's interactive tools.
- This stack runs natively on Windows 10 (Ghidra 12 + JDK 21, 64-bit) and is
  the recommended setup: interactive GUI for you, MCP tools for the agent.

### D. This chat's role
This assistant cannot be live-connected into Antigravity or to your machine.
The practical bridge is this repository: open `maniesh-NR/ClearFile` inside
Antigravity so the agent works from the same protocol documents, the
`.clearfile.json` schema, the TXF exporter and the web prototype's `.tax`
container sniffer (stored/deflate/unknown three-path analysis) that already
exist here. Findings flow back as PRs to `docs/`.

## 5. Modern `.tax` (2017+) — verified public findings

- Container: ZIP. Entries: `manifest.xml` + one data entry named like
  `tax:<uuid>`.
- `manifest.xml`: return metadata — `entityType` (e.g.
  `/tax/income/individual/taxreturn/taxml`), `entityKey`, `entityVer`, plus
  `appId`, `year`, `deviceId`, `appSku`, `formSetId`, `saveType`, `docName`,
  `ceDataType`.
- Data entry: XML in Intuit namespaces
  (`…/TurboTax/TaxReturns`, `…/USIndividualTaxReturn`,
  `…/PersistentObjects`, `…/TaxDataType`).
- Crypto: AES-CBC; per-year 16-byte key and IV constants embedded in the
  TurboTax executable; manifest and data use different keys. Key values are
  published in the source write-up (§1) and are deliberately **not
  reproduced here** (§2.2).
- Practical consequence: the interesting reverse-engineering target is the
  *TurboTax binary itself* (key derivation/embedding + parser), which is
  exactly the Phase-4/GhidraMCP workload.

## 6. Deliverable conventions

- Findings go in `docs/formats/<extension>.md` using the Phase-5 spec
  template, with provenance and a "verified by" experiment per field.
- Every claim cites bytes (offsets/hashes) or a decompiled function name —
  never "someone said".
- No key material, no copyrighted form text, no bulk proprietary binary
  content in the repo. Links to primary sources instead.
