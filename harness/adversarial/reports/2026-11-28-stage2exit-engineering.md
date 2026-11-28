# ADV-ENG — Stage-2 EXIT gate review (delta-scoped), 2026-11-28

Reviewer: ADV-ENG (engineering), standing adversarial panel, running in isolation.
Delta under review: `1ccfa43..HEAD` (the N6-exit backup → `8b5c553` D46 rework →
`02d7289` T3 session 2), plus the working-tree mid-session state observed as found.
Method: independent re-derivation — every load-bearing claim re-run or re-computed
here, not accepted from the records. The gitignored bench scripts (`tools/re/`) and
corpus (`tools/re-corpus/`) were executed read-only as expected; no other file was
modified by this review.

**VERDICT: PROCEED-WITH-CONDITIONS (2 conditions, both teardown-scoped, checkable).**

The Stage-2 DoD is met and its longest-standing blocker is genuinely dead: the
"0x24000 MSI-record keystream divergence" premise behind 12+ gates of slip is
**falsified by this reviewer's own runs**, not merely asserted. The D46 rework is
correct, fail-closed, and confined as ruled.

---

## F1 — The falsification claim (primary target): CONFIRMED empirically

### F1.1 The bench implements exactly the recorded techniques (task item a)

Cross-read of `tools/re/tt3_chase2.py`, `tt3_stream.py`, `tt3_can.py` against
`docs/re-research/2026-11-22-tt-t2-session2.md` and
`docs/re-research/2026-11-23-tt-t2-session3.md`:

| Recorded technique (source) | Script implementation | Match |
| --- | --- | --- |
| Outer magic `48 12 90 BF 49 FF 91 AA` @0x99000 (T2-s2 §1) | `tt3_chase2.py:101` asserts the 8 bytes | ✓ |
| Entry header `[u32 magic 0x6d27e59b][u8 type][u16 namelen][name][u64 FILETIME][u32 A][u32 B]`, fields variable-offset after the name (T2-s2 §2 + the T3-s2 correction; T2-s1's +0x10/+0x18/+0x1c = the namelen-9 case) | `tt3_chase2.py:35-59`, `tt3_stream.py:33-47`: type@+4, namelen@+5, name@+7, FILETIME/A/B in the 16 bytes after the name, payload@+16 | ✓ |
| Chunk grammar `[deflate B bytes] ([u32 csize][csize B raw-Deflate] \| [u32 0x80000000\|n][n stored])* [u32 0]`, each deflate chunk a SEPARATE self-terminating stream, wbits=-15 (T2-s2 §3) | `tt3_stream.py:50-77`, `tt3_can.py` (n/a — ZIP layer), `tt3_chase2.py:74-95`: fresh `decompressobj(wbits=-15)` per deflate chunk, stored segments copied raw, 0-word terminates | ✓ |
| End-of-archive: type-0 end-entry observed at 0x18141f55 (T2-s2 §4) | This run: 0-word at `0x18141f51` (4 bytes before the end-entry magic) — independently corroborates the recorded offset | ✓ |
| ISSetupStream header = 46 B: 14 B magic + u16 version + u32 gen 4 + 26 zeros (T2-s3 §1) | `tt3_stream.py:81-88`, `tt3_can.py:42-54`, `tt3_chase2.py:148-167`: ver∈{7,8}, gen==4, 26 zero bytes at +20..+46 | ✓ |
| v4 record header 0x30 B: dsize@+0x0A, u16=1@+0x16, name@+0x30, next record at +0x30+namelen+dsize (T2-s3 §2, sequential read; the T3-s2 byte-derived offsets) | dsize read at `+0x0a` (`tt3_stream.py:94`, `tt3_can.py:62`, `tt3_chase2.py:180`), u16@`+0x16` (`tt3_can.py:63`, asserted==1 in `tt3_chase2.py:183`), walk step `0x30+namelen+dsize` | ✓ |
| Cipher: key = record's own UTF-8 filename masked bytewise with `13 35 86 07`; `plain = ~(swapnib(enc) ^ maskedKey[(p mod 1024) mod keylen])` (T2-s3 §3) | `decrypt()` in all three scripts: `SWAP[enc] ^ mk[((phase0+i)%1024)%keylen] ^ 0xFF` — identical (¬x = x^0xFF; XOR associative) | ✓ |
| Compression: zlib-wrapped deflate, stream begins `78 9c` (T2-s3 §3) | default-wbits `decompressobj()`; head bytes observed `789c` in this run (`tt3_chase2.py` output) | ✓ |

Corpus integrity: `sha256sum` of both targets re-computed this review —
`3e6fc199…15b83` (USA) and `724a4b69…9f59` (CAN) — match
`docs/re-research/corpus-manifest.md:14-15` exactly. The bench ran on the pinned,
provenance-tracked corpus.

### F1.2 The runs (task items b, c) — this reviewer's own execution

`python3 tools/re/tt3_stream.py` (66 s, read-only, in-memory):

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
```

`python3 tools/re/tt3_can.py` (38 s):

```
clean v7 stream header at 0x14ae00 (recorded PE raw end 0x14ae00)
  rec0..rec6 (7 records, u16@+0x16=1 on all 7)
MSI payload @0x74ec922 dsize=246582748
Z_STREAM_END at input 246582748: output 251319296 = 0xefad400, unused=0
```

Both match the claimed closures **byte-for-byte**: input == dsize exactly,
output 390,117,376 = 0x1740b800 (USA; = the independently recorded T2-s3 size,
`2026-11-23-tt-t2-session3.md:105-107`) and 251,319,296 (CAN), `unused_data == 0`
on both. All 8 USA records and 7 CAN records byte-match the T2-s3 recorded
inventory (`2026-11-23-tt-t2-session3.md:78-95`).

### F1.3 Fake-closure scrutiny (task item d) — no artifact found

- **All ciphertext fed?** Yes: both loops run `while total_in < mdsize` with
  `take = min(WIN, mdsize - total_in)` (`tt3_stream.py:114-119`, `tt3_can.py:81-86`);
  the only exits are eof / `zlib.error` / exhaustion. Observed exit = eof at
  input == mdsize. Had eof fired early, the printed input would be < dsize — it is not.
- **Unused data?** `unused=0` on both runs — the stream consumed the final byte of
  the final window (USA last window = 383,877,541 − 366·2^20 = 98,725 B; CAN =
  167,388 B; eof fired exactly at window end with zero residue).
- **Truncated-buffer phantom feeding?** `inner[p:p+take]` could in principle slice
  short while `total_in` still advances — but a short feed cannot produce
  `Z_STREAM_END` at input == dsize with `unused == 0` (a truncated deflate stream
  ends with eof=False → the script would print "decode ended", not Z_STREAM_END).
  Independently disproven by F1.4's arithmetic: the buffer length accounts for the
  full record table to the byte.
- **Phase continuity across 1 MiB windows?** Correct: `decrypt(ct, mk, phase0=total_in)`
  with `total_in` = the pre-window absolute payload offset (`tt3_stream.py:117`,
  `tt3_can.py:84`) — exactly the recorded "(p mod 1024)" keystream index. (1 MiB is
  a multiple of 1024, so windowing cannot alias the period.)
- **Output plausibility:** head plaintext `78 9c` (observed in `tt3_chase2.py`),
  zlib-wrapped deflate as recorded; USA output size independently recorded in T2-s3
  before this session — the strongest possible cross-check. No content is asserted
  or retained (§7.2 posture honored; only counts/closures/32-byte neighborhoods printed).

### F1.4 Independent DSIZE arithmetic (task item e) — closes to the byte, both targets

Hand-walked from the printed record tables (namelen = 2·len(name), header 0x30,
h0 = header offset + 46), independently re-computed in Python this review:

**USA** (h0 = 0x198c00 = 1,674,240; inflated installer = 404,059,632):
- Predicted MSI payload offset = 1,674,286 + Σ_{rec0..rec5}(48+namelen+dsize) + 48+34
  = 1,674,286 + 18,494,224 + 82 = **20,168,592 = 0x133bf90** — exactly the script's
  printed value.
- MSI end = 20,168,592 + 383,877,541 = 404,046,133. Residual to buffer end:
  404,059,632 − 404,046,133 = **13,499** = the Setup.ini record (48+18+1,593 = 1,659)
  + **11,840 B trailing PKCS#7 signature** (T2-s2 §5 / T2-s3 honest limits record a
  "~10 KB PKCS#7 SignedData blob, one per ISSetupStream").
- Walk end after all 8 records = 404,047,792; residual 11,840 = the signature alone.
  **Zero unexplained bytes.**

**CAN** (h0 = 0x14ae00 = 1,355,264; ZIP entry size = 369,198,176):
- Predicted MSI payload offset = 1,355,310 + 121,248,418 + 82 = **122,603,810 =
  0x74ec922** — exactly the script's printed value.
- MSI end = 122,603,810 + 246,582,748 = 369,186,558. Residual: **11,618** =
  Setup.ini record (1,609) + **10,009 B signature**. Walk end after 7 records =
  369,188,167. **Zero unexplained bytes.**

The record-table walk therefore accounts for 100% of both inflated payloads
(minus the 46-byte stream header and the recorded trailing signature) — the
dsize@+0x0A layout is arithmetically self-certifying here, not just asserted.

**Disposition of the 0x24000 premise:** both MSI records decode clean THROUGH
0x24000 to byte-exact end-to-end closure with the recorded formula alone. The
"divergence" is falsified as claimed; the decompile chase is moot. The recorded
artifact-class explanation (field-offset misalignment in the wiped session's bench
— the same trap family `tt3_chase2.py`'s first walk documents) is consistent with
the evidence: a misaligned window shifts/truncates the decode rather than revealing
a cipher variant. (Not independently re-provable — the wiped bench is gone — but
the positive closure stands on its own.)

---

## F2 — docs/formats/tax-modern.md §3 vs what the scripts prove (task item 2)

- §3 item 1 (lines 89-96): the 46-byte header and the byte-derived field offsets
  (namelen@+0x00, flags@+0x04, u16 0@+0x08, **dsize@+0x0A**, u32 0@+0x0E, u16 0@+0x12,
  **u16=1@+0x16**, FILETIMEs@+0x18/0x20/0x28, name@+0x30) — **exactly** what the
  scripts read and what the u16==1 assertions (14 records across both targets) and
  the to-the-byte walk arithmetic (F1.4) validate.
- §3 item 2 (lines 97-108): the cipher formula matches the scripts' `decrypt()`
  verbatim; the closure numbers (383,877,541 → 390,117,376; 246,582,748 →
  251,319,296; Z_STREAM_END; "no keystream divergence") match this review's runs.
- §3 item 3 (lines 109-112): the deep-stack facts (OLE compound file, MSCF
  cFolders=121 / cEntries=6,503) trace to the T2-s3 record (lines 106-124) — consistent.
- **On "correcting the T2 session-3 prose's field boundaries":** read strictly
  sequentially, the T2-s3 prose (`[u32 namelen][u32 flags][u16 0][u32 dsize][u32 0]
  [u32 0][u16 1]`, line 32-33) already yields dsize@+0x0A / u16=1@+0x16 — the same
  offsets — and T2-s3's own engine anchor says "the u32@0x0a". The T3-s2/spec
  wording overstates: this is a **disambiguation** (a natural-alignment reader gets
  +0x0C/+0x18 — exactly the trap class the wiped bench hit), not a correction of a
  wrong recorded value. The ENTRY-table correction (T2-s1's +0x10/+0x18/+0x1c being
  the namelen-9 case) IS a genuine correction and is accurately described. Wording
  nit only; no numeric error in either document.
- Spec hygiene: no key values (AES-CBC/16-byte keys by existence only), no ≥32-hex
  runs (lint-enforced), the no-owned-sample honest limit and the namespace note are
  present and correct (§5, §6). §2's interior claims are properly attributed to the
  linked public write-up, not passed off as this repo's verification.

## F3 — The D46 rework (`git show 8b5c553`, task item 3)

- **YAML validity:** `python3 -c "import yaml; yaml.safe_load(...)"` → `YAML OK`.
- **Job topology:** 8 jobs (flutter-test:60, android:81, linux:170, windows:256,
  macos:336, flutter-web:418, nextjs-web:498, release:628). All wasm/rustup/cargo/
  core references live at lines 572-618 — inside nextjs-web only; `release:` (628+)
  and every other job carry none. `grep -cE 'core/|clearfile-core|cargo'` = **6**;
  the awk counts: **OUTSIDE=0, INSIDE=6** (sums exactly). The wasm32 build in
  `hygiene.yml` is the pre-existing push/schedule CI pattern (N6 record), not a
  release job; `release.yml` is the only release workflow.
- **rustc guard (release.yml:578-588):** parse logic live-tested here on the exact
  script semantics: `rustc 1.100.0 (…)` → MAJOR=1, MINOR=100 → PASS; `1.9.0` →
  REFUSED (9 < 95 — correct numeric minor comparison); `1.95.0` → PASS (boundary);
  `2.0.0` → PASS; `garbage` and empty fields → fail-closed via the
  `''|*[!0-9]*` case guards. Fail-closed before any build.
- **`--locked` build + copy + import guard:** `cargo build --locked --release
  --target wasm32-unknown-unknown --manifest-path core-ffi/Cargo.toml` (line 590);
  artifact name verified against `core-ffi/Cargo.toml` `[lib] name =
  "clearfile_core_ffi"` → `clearfile_core_ffi.wasm` — the `cp` source (line 591) is
  right; `test -f` backstop (592); the node import-empty guard (594-605) exits 1 on
  any nonzero import count — fail-closed. Step order is sound: build asset →
  import guard → `npm run build` → bundle (`cp -r public` rides the asset in) →
  tar → **fail-closed tar-listing assertion** (614-617: `grep -F
  'standalone/public/clearfile-core.wasm'` over `tar tzf`; entry prefixes verified
  against `tar czf … -C .next standalone`). `RELEASE_TAG` is defined in the job env
  (nextjs-web env block, line ~502) — the assertion cannot run unbound.
- **harness_check.sh confinement guard (lines 87-102):** the awk state machine
  `/^  [A-Za-z0-9_-]+:$/{innext=($0=="  nextjs-web:")}` matches the actual
  job-header format (verified: every job header is exactly 2-space indent + name +
  colon; job bodies indent deeper). It also matches the `on:` trigger keys
  `push:`/`workflow_dispatch:` (lines 37/40) — harmless: they classify as "outside"
  and contain no matches. Fail direction is safe: any future core/cargo line in
  another job (even a comment) increments OUTSIDE and fails the guard.
- **`bash scripts/harness_check.sh`:** 1 failure — `FAIL — 2 unpushed commit(s) —
  the last session-log entry postdates the backup; run scripts/sandbox_backup.sh`
  (line 272). This is the expected mid-session state per the gate's terms (the
  backup runs at teardown); every other check is green, including the flipped
  confinement guard ("6 line(s) inside, 0 outside").

## F4 — The DoD checklist closure (task item 4)

| DoD item | Evidence | Status |
| --- | --- | --- |
| 4 named specs present | `ls docs/formats/`: clearfile-json.md, tax-exchange-container.md, tax-modern.md, txf.md | ✓ 4/4 |
| Each §7.5-clean + lint-clean | `lint_format_specs.py` default: 4/4; `--scope all`: exit 0, "11 file(s) clean" (10 printed ok + corpus-manifest.md checked clean under the recorded known-hash exemption — lint_format_specs.py:39,113-118; cosmetic print asymmetry, counted correctly) | ✓ |
| ≤2 Stage-2 execution sessions | SESSION_LOG headers: exactly two — line 1152 ("2026-11-22 (final) · Stage-2 execution session 1") and line 1294 ("2026-11-23 · Stage-2 execution session 2"); no third. The 2026-11-28 work is TT-program/D46 namespace (ROADMAP TT section, namespace rule TT gate PROD-3/ENG-6), pre-ruled as the slip's own trigger ("the exit gate convenes when T3 delivers") | ✓ |
| Refusal/cap tests green | This review's runs: `test_re_tools.py` 23/23 OK (the RE tools' refusal/oversize/cap suite); `ai_injection_test.mjs` 4/4 groups (refusals, whitelist coercion, hostile-body classification); the TXF 10,000-record cap refusal test **run live** on the pinned toolchain: `dart_parser_hardening_the_10000_record_cap_throws_eng2 ... ok` (core/tests/txf_port.rs:363, cargo 1.100.0). `ai_provider_tests.py` key-gated skip (no keys in this sandbox — consistent with the offline posture, not a failure) | ✓ |
| No-binary-blob assertion | `check_binary_blobs.py`: "clean — 465 tracked files, 28 allow-listed own binaries, no other binary blobs" | ✓ |
| Oracle | `verify_golden_fixtures.py`: "17 fixtures, 0 field failures" | ✓ |

D46's DEBT row (DEBT.md:229-230) and the README `src/` row (8b5c553) accurately
record the rework state and the remaining D45 obligation (LICENSES manifest at the
first tag) — no overclaim found.

## F5 — Provenance-heading normalization (task item 5)

`git diff HEAD~1 -- docs/re-research/`: five existing notes each gain exactly +3
lines (blank + `## Provenance (protocol §7.1)` + the one-paragraph provenance
statement); zero deletions or modifications of existing lines; the new T3-s2 note
was authored with the heading in place. The inserted text matches
`scripts/add_provenance_headings.py`'s SECTION constant verbatim (idempotent —
skips when the heading exists; hardcoded 6-file list). Strictly additive: the
paragraph restates facts already in each note's Status block ("Provenance:
corpus-manifest.md", read-only, §7.2/7.3/7.4 posture) — "formatting only" is fair
in that no existing content changed and no new claim is introduced. The lint's
SEC-6 scope-all extension flipping on (with the corpus-manifest known-hash
exemption recorded in the lint's own docstring, lines 17-22, 39) is the
pre-announced trigger and is satisfied.

## F6 — Findings and notes (non-blocking)

1. **SESSION_LOG gap (elevated to Condition C1):** SESSION_LOG.md's last entry is
   still the 2026-11-27 N6 session — no entry yet for the 2026-11-28 session(s)
   (the D46 discharge + T3 session 2). The memory layers are mid-flight uncommitted
   (working tree: PROJECT_MEMORY.md, CONSENSUS.md, DECISIONS.md, ROADMAP.md — the
   2026-11-28 owner-ruling records are drafted there). Expected mid-session state,
   but the exit-gate record-keeping discipline requires the session entry to land.
2. **Bench evidence retention (elevated to Condition C2):** the closure evidence
   lives only in gitignored `tools/re/` scripts + console output; the recycles
   wiped the previous bench, which is precisely how the 0x24000 confusion became
   unreconstructable for 12+ gates. The T3-s2 note records the numbers but not the
   raw transcripts or script digests.
3. **CAN closure asymmetry (note):** the USA output size 390,117,376 is
   independently corroborated by the T2-s3 record; the CAN output size 251,319,296
   is a first-publication datum of the same bench. The CAN closure nonetheless
   stands on input == dsize byte-exact + `unused == 0` + the to-the-byte
   record-table arithmetic + the identical formula's independent USA corroboration.
   No action required.
4. **"Correcting" vs "disambiguating" (note):** as in F2 — a wording nit in
   tax-modern.md §3 and the T3-s2 note/commit message; the offsets themselves are
   byte-validated and no recorded value is contradicted.
5. **Lint print asymmetry (note):** scope-all prints 10 `ok` lines but counts 11
   (the exempt corpus-manifest hits `continue` without printing). Correct behavior,
   confusing output; optional one-line polish, not a condition.

---

## CONDITIONS (numbered, checkable)

- **C1 — Land the 2026-11-28 session record at teardown.** SESSION_LOG.md must
  gain the session entry (the D46 discharge + T3 session 2, TT-program namespace)
  and the four modified memory files (PROJECT_MEMORY / CONSENSUS / DECISIONS /
  ROADMAP) be committed and pushed via `scripts/sandbox_backup.sh`, discharging
  harness_check's sole failure ("2 unpushed commit(s)"). Check: `bash
  scripts/harness_check.sh` reports 0 failures after the backup.
- **C2 — Preserve the closure evidence beyond the recycle.** Append to
  `docs/re-research/2026-11-28-tt-t3-session2.md` (or a companion note) the
  verbatim stdout of the two closure runs (`tt3_stream.py`, `tt3_can.py`) and the
  script names + sha256 digests of the three `tools/re/tt3_*.py` files — counts
  and closures only, no corpus-derived content (§7.2/§7.5-safe). Check: the
  digests + transcripts exist in the tracked note; a post-recycle re-derivation
  can be diff-verified against them instead of re-argued.

## Next actions

1. Discharge C1 + C2 at the session close (owner-funded teardown path).
2. Convene the full 4-reviewer exit gate on this delta; the DoD's engineering
   surface is green on the evidence above.
3. Optional polish (no gate dependency): the lint's exempt-file print, the
   "correcting"→"disambiguating" wording in tax-modern.md §3 / T3-s2 note.

— ADV-ENG, 2026-11-28. All commands and outputs cited above were executed by this
reviewer in this session; no claim is accepted on assertion alone.
