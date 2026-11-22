# TT RE research corpus — provenance manifest (ADR-019, 2026-11-22)

The four acquisition targets of the TT-compatibility program (owner
directive 2026-11-22). **Provenance framing:** publicly-posted installer
URLs on Intuit's own CDNs, acquired for the owner-directed
interoperability study under the RE protocol's private-research posture
(§2.1 / §1201(f)); the blobs live ONLY under gitignored
`tools/re-corpus/` (never tracked — ADR-012 mechanics; re-acquire via
`scripts/fetch_tt_corpus.sh` after a sandbox recycle, then re-verify
each sha256 against this manifest).

| Target | URL | Bytes | sha256 |
| --- | --- | --- | --- |
| TurboTax Personal USA, TY2026 | `https://downloads.ecom.intuit.com/ttfed/26tax/Windows_PC_TurboTax_Download.exe` | 403,981,944 | `3e6fc19922c14bbbafbfa879f8fbaa80ff24248ad6c3c210da25514069315b83` |
| TurboTax Personal Canada, 2025 | `https://intuitglobal.intuit.com/downloads/CanadaTax/2025/dls/TurboTax_2025.exe` | 369,125,144 | `724a4b69c6816875083ef5c1423184ccbabd198e5e6ec850b3a492569bcc9f59` |
| TurboTax Business USA, TY2026 | `https://downloads.ecom.intuit.com/ttfed/26tax/Windows_PC_TurboTax_Business_Download.exe` | 379,141,920 | `8a2458bacb0c0616bd75e203b129f83062b5c39e34289d40babfea6f936b192a` |
| TurboTax Business Canada, 2025 | `https://cdn.ctg.intuit.ca/downloads/2025/TTBinc_2025.exe` | 333,073,488 | `0ea4512d4605fa07aeda4a888845c1d65631c4ef1518ea1195be9b2923a6c069` |

Downloaded 2026-11-22 (this file's directory holds the Phase-1 findings:
`2026-11-22-tt-targets-phase1.md`). The hashes in this table are
sha256 checksums of publicly downloadable files — the recorded
known-hash allow-list instance for the backup secret guard (ADR-019);
nothing else under `docs/` may carry hex runs this long (the
`docs/formats/*.md` lint, when it lands, enforces that).
