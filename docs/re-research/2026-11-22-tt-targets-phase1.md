# TT targets — Phase-1 passive survey + first-pass Phase-4 (2026-11-22)

## Provenance (protocol §7.1)

The corpus is the four publicly-posted installer targets, sha256-pinned in `docs/re-research/corpus-manifest.md` (re-verified on re-acquisition by `scripts/fetch_tt_corpus.sh`). The study is owner-directed interoperability research under the protocol's private-research posture: read-only on the corpus, function-fact findings only — no expression lifts (§7.4), no decrypted content committed (§7.2), crypto and keys by existence never by value (§7.3).
**Status:** pre-gate research record for the TT-compatibility program
(ADR-019). Read-only, function-fact findings only (protocol §6/§7.4 —
no expression lifts; proprietary strings paraphrased, identifiers kept).
Provenance: `corpus-manifest.md`. Toolchain: REA 6.10.1 (the owner's
directed front-end) over Ghidra 12.2 + Temurin 25 under gitignored
`tools/` (REA hard-requires Ghidra ≥ 12.2, which requires JDK 25;
the protocol-pinned 12.1.4/JDK-21 line stays installed as fallback —
see ADR-019).

## Per-target structure (Phase 1)

All four are 32-bit x86 PE executables (installers, not the app
modules). Sections + entropies from `tools/re/phase1_survey.json`.

### TurboTax Personal USA TY2026 (403,981,944 B)
- **Stub + overlay:** a ~626 KiB code stub (4 sections; `.text` 454,656 B
  at H=6.52; link timestamp 2008 — a long-lived wrapper) followed by a
  **403,355,256-byte overlay (99.85% of the file)** — the proprietary
  payload container, uniformly H=8.0 (compressed records).
- **Container head (file offset 0x99280 = overlay start):** magic
  `48 12 90 BF 49 FF 91 AA`, then structured tag-length records. The
  first record is named `xmlConfig` (name + u16 length + payload): an
  XML document whose root is a **SfxConfig** element (installer
  semantics fields: auto-temp, delete-after-setup, show-progress /
  show-main / show-fin flags, wait-for…). `7z` and `Deflate` marker
  strings exist in the stub's data — the decompression candidates.
- **Stub imports (reader-relevant):** KERNEL32 (CreateFileW/A, ReadFile,
  WriteFile), ADVAPI32 (CryptAcquireContextA), WS2_32 + WININET (network),
  SHELL32 (ShellExecuteExW), CRYPT32, OLEAUT32 — an
  extract-validate-launch downloader/extractor.
- **Business USA TY2026 (379,141,920 B): same stub layout** — identical
  section sizes, entropy profile, and link timestamp (not byte-identical;
  same wrapper code family, differing overlay payload of 378,515,232 B
  starting with the SAME magic + xmlConfig record).

### TurboTax Personal Canada 2025 (369,125,144 B)
- **WinZip SFX:** a `_winzip_` section (368,967,680 B, H=8.0); the
  appended archive is a **plain ZIP** (python `zipfile` opens it
  directly). Six entries: two tiny `Autorun.inf` files, `TTConfig.ini`
  (149 B), `setup.exe` (1,570,072 B, deflate), and
  `TurboTax 2025 Installer.exe` (369,198,176 B, deflate — the real
  payload layer).
- **`TTConfig.ini` facts** (extracted to `tools/re-corpus/inner/`):
  product name TurboTax, client id `ttdcan`, required product
  `TurboTaxCanadaWindowsInstaller`, log path under an MSI directory —
  the chain is WinZip SFX → `setup.exe` **MSI bootstrapper** → the
  payload installer.

### TurboTax Business Canada 2025 (333,073,488 B)
- **InstallShield-style layout:** 5-section GUI stub (`.rsrc` 303,616 B;
  `.reloc` present; gdiplus/COMCTL32 imports — a 2021-era link
  timestamp), followed by a 332,116,560 B overlay beginning with a
  **UTF-16 filename/manifest table** (first entries: a language-tagged
  INI name, `Disk1\0x1009.ini`, version and size fields, then a BOM'd
  UTF-16 INI setup script) — the classic InstallShield file-group
  structure; payload records compressed (H≈8.0).

## First-pass Phase-4 (the stub IS the container reader) — measured

The 2008-era USA stub is the proprietary container's own reader/extractor
— and at 626 KiB it fits this sandbox's measured Phase-4 envelope, so the
directed REA pipeline ran against the carved stub
(`tools/re/stub_usa.exe`; carve = first 626,688 B — `head -c`, trivially
re-carvable from the corpus):

- `rea analyze` (Ghidra 12.2 import + auto-analysis, ephemeral mode):
  **~83 s wall** on this 2-core box. The REA→Ghidra bridge is fully
  functional here (`rea doctor --provider ghidra` healthy with
  `GHIDRA_INSTALL_DIR` + JDK 25 `JAVA_HOME`).
- `rea inspect-pe-imports`: full import table (facts above).
- `rea inspect-native-instruction ram:0x47f090` (the `xmlConfig` string
  in `.data`): one incoming data reference from **`0x40143c`**.
- `rea decompile 0x40143c` → function **`FUN_004012c4`** (pseudocode
  archived at `tools/re/fun_004012c4.c`): the stub's bootstrap reader.
  Its sequence, paraphrased from the decompile (error diagnostics
  confirm each stage): open own EXE file → get size → **find marker**
  (`FUN_00418670`) → **read internal header** (`FUN_00418710`) →
  **read internal args** (`FUN_00418a50`) → **read record by name
  `xmlConfig`** (`FUN_004189c0`) → parse the XML → proceed. Failure at
  any stage shows a MessageBox and aborts.
- `rea decompile 0x418670` → the marker-finder is a **thin C++
  vtable-dispatch wrapper** (a reader-object class behind
  `DAT_004976c8`; archived at `tools/re/fun_markerfinder.c`) — the
  magic-constant construction and the record-table parser live behind
  that vtable = the T2 deep-dive entry point.

### Envelope conclusions (honest)
- **The stub-carving technique makes the installers tractable in this
  sandbox:** the small PE analyzes in ~83 s; the overlay container
  (99.8% of each file) parses independently in Python without Ghidra.
  Whole-file 333–404 MB imports remain §4.A/C-class work (the standing
  scale caveat) — and are unnecessary for the format study.
- REA limitations encountered, recorded: `inspect-binary-layout` routes
  to a pwntools provider (not installed — `REA_PWNTOOLS_PYTHON`
  absent); REA's Ghidra sessions are ephemeral (each command re-imports,
  ~80 s each) — checkpoint mode exists (`REA_GHIDRA_CHECKPOINT_DIR`) but
  was not configured this session.

## T2 entry points (next sessions, gated program)
1. Chase the reader-object vtable behind `DAT_004976c8`: the marker
   construction (the `48 12 90 BF 49 FF 91 AA` magic is built from
   immediates — not stored as a literal), the internal-header layout,
   and the record-table format (name-length records after `xmlConfig`).
2. The decompression path (`7z` / `Deflate` markers) and record
   extraction; then extract the real app modules from each target's
   payload layer and inventory them (the file-format + password
   routines live there — the program's actual targets).
3. Canada Personal: extract the inner payload installer; Canada
   Business: parse the InstallShield manifest table.
4. The UI-layout study (functional structure: wizard steps, fields,
   information architecture) begins once the app modules are extracted;
   the expression boundary (ADR-019: functional parity, own Material
   You expression) applies throughout.

## Erratum (2026-11-22, filed at the TT program gate — ADV-ENG finding 1)

The Personal-USA entry above says "Container head (file offset
0x99280 = overlay start)". The overlay start is **0x99000**
(= 626,688 B — the carve boundary itself; byte-verified in both USA
targets at the gate, and consistent with this note's own overlay
arithmetic and `phase1_survey.json`). 0x99280 lies 640 B inside the
compressed overlay. All other offsets and sizes in this note are
unaffected (independently re-derived at the gate).
