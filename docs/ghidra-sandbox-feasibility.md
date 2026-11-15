# Ghidra `analyzeHeadless` in the ClearFile sandbox — feasibility verdict

**Status:** research finding (owner directive, 2026-11-15) · feeds the
pending Stage-2 entry gate (ADR-012 placement + RE DoD)
**Question:** can Ghidra's CLI analyzer run in this sandbox, to support
Phase-4 study of TurboTax proprietary file formats?
**Verdict:** **Yes, with measured limits.** Ghidra 12.1.4 + JDK 21 runs
`analyzeHeadless` end-to-end (import → auto-analysis → Java postScript →
saved project) inside a ~1 GB heap on this 3.9 GB / 2-core box. Scale
caveats below.

---

## 1. Environment (as measured, 2026-11-15)

| Resource | Value |
| --- | --- |
| CPU | 2 cores |
| RAM | 3.9 GB total, ~1.78 GB free at analysis time, **no swap** |
| Disk | 9.9 GB root filesystem (~3.9 GB free after all installs) |
| JDK | Temurin 21.0.13 (full JDK, `javac` included) at `tools/jdk21` |
| Ghidra | **12.1.4** at `tools/ghidra` (882 MB unpacked) |
| Heap cap | `GHIDRA_HEADLESS_MAXMEM=1G` (default is 2G — too big here) |
| Home redirect | `HOME=tools/re/ghidra_home` (user settings stay out of the real HOME) |

Install notes: Ghidra **12.2 (current latest) refuses JDK 21 —
`application.java.min=25`** and fails headless with "unsupported java
version". 12.1.4 is the newest JDK-21 line and is exactly the version
`docs/reverse-engineering-protocol.md` §4.C pins for GhidraMCP, so the
sandbox now runs the repo's documented version. Both artifacts live under
gitignored `tools/` and reinstall from the documented fetchers.

## 2. Benchmark (the evidence)

Target: a synthetic stand-in "proprietary container writer" (`tools/re/
crypto_demo.c`, 16,224-byte ELF built with gcc -O2) embedding an
**authentic AES S-box computed from the published Rijndael definition**,
a fake 16-byte "per-year key", and a ZIP local-header magic — zero
proprietary material anywhere.

PostScript: `tools/re/FindCryptoConstants.java` (GhidraScript) — counts
identified functions, scans memory for the AES S-box prefix and the
`PK\x03\x04` magic (the exact constant-hunting workflow Phase 4 would
point at a proprietary reader/writer binary).

```
$ tools/ghidra/support/analyzeHeadless tools/re/ghidra_proj BenchProj \
    -import tools/re/crypto_demo -scriptPath tools/re \
    -postScript FindCryptoConstants.java tools/re/bench_report.txt
```

| Measurement | Result |
| --- | --- |
| Exit code | 0 (import + auto-analysis + postScript + save all succeeded) |
| Wall time | **11 s** (2 cores) |
| Peak RSS (java) | **416.9 MiB** (1 GB heap cap; ~1.78 GB free before/after) |
| Functions identified | 26 |
| AES S-box prefix (16 B) | found @ `00102060` |
| ZIP local-header magic | found @ `00102040` |

Bench harness: `tools/re/run_bench.sh` (builds the target, runs headless
under a `/proc` peak-RSS poller, prints the report). Rerunning the
benchmark after any sandbox recycle is one command.

## 3. What this settles

- **Phase-4 mechanics work here.** Auto-analysis, function ID, and
  byte-pattern crypto-constant hunting all run headless in this sandbox
  — the same operations the protocol's Phase 4 prescribes for finding
  the per-year key/IV constants in a proprietary binary.
- **The loop-closer.** The one thing Phase 4 needs beyond these mechanics
  is the owner's licensed binaries and owner-authored file corpus
  (§2.4/§7.1) — neither exists in this sandbox, and none was synthesized
  beyond the stand-in above.
- **Scale ceiling (honest).** 2 cores, ~1.8 GB free RAM, no swap, 1 GB
  heap: comfortable for small/medium binaries and scripted sweeps;
  a real TurboTax desktop executable (hundreds of MB) would want a
  raised heap, long patience, or one of the protocol §4.A/C
  environments (private cloud VM / Windows + GhidraMCP). The §4.A cloud
  caveat applies here too: **ephemeral disks lose Ghidra projects —
  export findings or snapshot `.gzf` before the sandbox recycles.**
- **Not done, deliberately.** No TurboTax binary was analyzed (none
  owned here), no `.tax` file was decrypted, and no key material exists
  anywhere in this repository or the bench harness (protocol §2.2/§7).
  The public write-up's constants stay cited-by-existence only.

## 4. The capability that DID ship to ClearFile (Stage-3 bridges)

The feasibility answer is only half the owner directive; the app-side
"work with these file formats" capability landed as the documented safe
bridges (protocol §2.5), all pinned by tests (Dart suite now 95/95; new
web bridge suite green in CI):

- **TXF import (Flutter, `clearfile/lib/io/txf_import.dart`)** — the
  published Tax Exchange Format spec v042: `^`-terminated records,
  single-letter field lines, W-2 copies grouped by the `C` copy field
  (460/461/466 + spouse 506/507/513), income codes 287/286/683/488/257,
  deduction codes 275/544/276/283/545/280/485, payment codes 268/521,
  adjustment 636; spec sign convention (expenses negative → magnitudes
  stored); unknown refnums reported, never guessed; parser hardening
  (5 MB / 10k records / 4096-char line caps).
- **`.tax` inspection (Flutter `tax_inspect.dart` + web `taxfile.ts`)**
  — read-only ZIP central-directory scan, STORE-entry extraction,
  per-entry Shannon entropy with a likely-encrypted flag (≥7.5
  bits/byte), recognition of the modern Intuit container *shape*
  (`manifest.xml` + `tax:<uuid>`) with copy that names the safe bridges
  and states it does not decrypt (§2.2/§7.2/§7.3), and ClearFile
  exchange-container import.
- **TXF exporter verification (web, `scripts/txf_taxfile_test.mjs`)** —
  the Stage-3 planned verification suite; it forced a real fix: the
  exporter's previous codes (425 "wages", 426 "federal withholding") are
  the 4952 investment-interest family per the spec table — now exports
  spec-true 460/461/466 per W-2 copy, 287 interest, 636 student loan,
  with the spec's negative-sign convention for money paid.

## 5. Standing limits (unchanged by this finding)

The AES layer on modern `.tax` files remains a technological protection
measure: private, owner-authored-corpus research is defensible
(§2.1/§1201(f)); shipping keys/IVs/ready-made decryptors is not, and
this repository does neither. "Full capability" with real Intuit data
therefore continues to mean the TXF/PDF bridges above — and the RE
tooling decision (in-repo vs separate research repo) stays exactly
where the roadmap put it: the Stage-2 entry gate's ADR-012, now with
this sandbox-feasibility data on the table.
