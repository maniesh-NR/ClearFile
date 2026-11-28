# Bench-evidence record — the T3 session 2 falsification closure (2026-11-28)

**Status:** the Stage-2 exit gate ENG-2 condition record (ADV-ENG,
2026-11-28): the verbatim stdout of the two closure runs plus the
sha256 digests of the gitignored bench scripts, so a post-recycle
session can diff-verify the falsification evidence instead of
re-arguing it (the wiped bench is exactly how the 0x24000 premise
survived twelve gates). This file is the lint's second recorded
known-hash exemption instance (the ADR-019 allow-list class): its
digests pin PUBLICLY-POSTED corpus-derived read-only runs and the
repository's OWN analysis scripts — no key material, no decrypted
content (the outputs are counts, closures, and offsets only).
## Provenance (protocol §7.1)

The corpus per `docs/re-research/corpus-manifest.md` (all four
targets sha256-verified on re-acquisition this session); the bench
scripts live gitignored under `tools/re/` (re-derivable from the
session note's technique record; the digests above pin today's
exact bytes).

## The bench scripts (gitignored; re-derive from the note, then verify the digests)

```
bb1904cdd2005a258d590d2d42b4b6266a8429d947ba36ecc5d6e1a13347cd63  tools/re/tt3_chase2.py
d1dc160edf3eb80aab63c309d50079c1763c70811105723a4ab78734a040d6b3  tools/re/tt3_stream.py
ebcbfb618fe308a00dfb283d6987d7be2408d943543f3a875118e4bc91c28f5f  tools/re/tt3_can.py
```

## Run 1: tt3_stream.py — the Personal-USA 2026 MSI record, end-to-end

```
installer entry: payload@0xfc905 first_csize=45184
end-of-archive word at 0x18141f51; chunks=389
installer entry inflated: 404059632 bytes (404.1 MB) from 389 chunks
ISSetupStream v8 header at 0x198c00
  rec0 'SplashScreenWithLogo409.bmp' dsize=5976
  rec1 '0x0409.ini' dsize=4690
  rec2 'Microsoft Visual C++ 2022 Redistributable Package (x64).prq' dsize=673
  rec3 '{25E2F1F0-09A7-4C6A-ADC7-CA620D43574E}.VC_redist.x64.exe' dsize=18479851
  rec4 'Microsoft .NET Framework 4.8 Full.prq' dsize=749
  rec5 'TurboTax 2026.isc' dsize=1585
  rec6 'TurboTax 2026.msi' dsize=383877541
  rec7 'Setup.ini' dsize=1593
MSI payload @0x133bf90 dsize=383877541
Z_STREAM_END at input 383877541 (383.9 MB): output 390117376 = 0x1740b800, unused=0
decode ended: input 383877541 output 390117376 = 0x1740b800
last 32 output bytes: 0000000000000000000000000000000000000000000000000000000000000000
```

## Run 2: tt3_can.py — the Personal-CAN 2025 MSI record, end-to-end

```
ZIP entries: ['Autorun.inf', 'setup.exe', 'TTConfig.ini', 'TurboTax 2025/', 'TurboTax 2025/Autorun.inf', 'TurboTax 2025/TurboTax 2025 Installer.exe']
payload installer: 'TurboTax 2025/TurboTax 2025 Installer.exe' size=369198176
read 369198176 bytes in memory
clean v7 stream header at 0x14ae00 (recorded PE raw end 0x14ae00)
  rec0 'SplashScreen409.bmp' dsize=13724 u16@+0x16=1
  rec1 '0x0409.ini' dsize=4651 u16@+0x16=1
  rec2 'Microsoft Visual C++ 2015 Redistributable Package (x86).prq' dsize=699 u16@+0x16=1
  rec3 'Microsoft .NET Framework 4.8 Full.prq' dsize=749 u16@+0x16=1
  rec4 '{06D565DC-042E-4F1B-8702-2E0BD0F22805}.ndp48-x86-x64-allos-enu.exe' dsize=121227973 u16@+0x16=1
  rec5 'TurboTax 2025.msi' dsize=246582748 u16@+0x16=1
  rec6 'Setup.ini' dsize=1543 u16@+0x16=1
MSI payload @0x74ec922 dsize=246582748
Z_STREAM_END at input 246582748: output 251319296 = 0xefad400, unused=0
decode ended: input 246582748 output 251319296 = 0xefad400
```
