# ADV-LEGAL — Stage-2 EXIT gate (delta-scoped) · 2026-11-28

**Reviewer:** ADV-LEGAL (isolated run; independent re-verification, not record-trust)
**Scope:** the delta since the last convened gate (N6 exit, commit `1ccfa43`,
2026-11-27) = commits `8b5c553` (D46 rework) + `02d7289` (T3 session 2:
spec 4 + the falsification + the provenance normalization) plus the
working-tree record updates — against the five named surfaces in the gate
charter. Stage-2 DoD as fixed 2026-11-17 (ROADMAP.md:205–223).
**Method:** my own runs and reads only — `lint_format_specs.py --scope all`,
`check_binary_blobs.py`, `test_re_tools.py`, `harness_check.sh`, awk
confinement probes on `release.yml`, an independent key-material pattern
scan (hex ≥16, base64-shape, decimal byte-lists) over all `docs/formats/`
and `docs/re-research/` files, and full reads of the two new documents and
the four record files plus `git show 8b5c553` / `git diff HEAD~1`.

---

## Findings

**F1 — `docs/formats/tax-modern.md` (named spec 4): §7-CLEAN on all six
charter checks.**
(a) *No key/IV material:* my independent scan (hex ≥16 chars, base64-shape
runs ≥24, decimal byte-lists ≥12) over the file returns only the
zameermanji URL fragment — no key bytes, no IV bytes, no derived values
anywhere. The only crypto facts recorded are existence-class: "AES-CBC
using 16-byte (128-bit) keys", "per tax year and embedded in the TurboTax
binary", "the key/IV VALUES are published in the write-up and are
deliberately NOT recorded here or anywhere in the repo" (tax-modern.md
§2, lines 67–73; Provenance lines 20–22). Linking-not-reproducing is the
§7.3 form verbatim. The lint's ≥32-hex rule is clean (my scan is stricter:
≥16).
(b) *Lint:* `python3 scripts/lint_format_specs.py --scope all` → exit 0,
"11 file(s) clean" (all 4 specs + 7 re-research notes; the corpus-manifest
sha256s ride the recorded ADR-019 known-hash exemption).
(c) *No expression lifts:* identifiers only (`manifest.xml`, the `tax:` +
UUID name shape, `taxYear`, the `IData::` method names, Crypto++
existence); the proprietary UI strings are paraphrased at class level
("the save-dialog encryption-checkbox string class", §4); no images (the
lint's image-embed rule is clean and PROD-1's runtime-screenshot extension
is satisfied — the file is text-only). §102(b)/merger/scènes-à-faire line
held: offsets, counts, structure, function only.
(d) *Namespace note (§6) correct:* it matches the TT gate's namespace rule
as recorded (CONSENSUS.md:875–879; ROADMAP.md:874–880, "TT gate,
PROD-3/ENG-6"): TT specs live under `docs/re-research/`, never count
toward N=4; the deep password-layer spec is a distinct future artifact;
this file's presence in `docs/formats/` is the DoD's own named list
(ROADMAP.md:205–211 names `tax-modern.md` as spec 4). No TT scope creep;
no counting distortion — `docs/formats/` holds exactly the four named
files, nothing more.
(e) *Honest limit stated:* "No owned `.tax` sample exists" twice
(Provenance ¶3 lines 30–37; §5 first bullet lines 138–141), correctly tied
to the entry gate's "bonus, never required" clause (ROADMAP.md:215–216).
(f) *ADR-020 posture without a shipping path:* §2's ADR-020 bullet records
the T4 quarantined-module exception as "recorded, not acted on … the ONE
sanctioned exception to by-existence, and it does not exist yet (T4 is
funded, entry gate pending; no T4 code exists)" (lines 74–78). No key
values, no implementation, no import path, no module — description only.
The by-existence default stands everywhere else.

**F2 — `docs/re-research/2026-11-28-tt-t3-session2.md` (the chase record):
§7-clean; posture consistent with T2-session-3.**
The transport cipher's "key" is recorded as the record's own public
filename field masked with the 4-byte constant `13 35 86 07` (lines
62–63) — the identical constant, with the identical recorded posture, as
T2-session-3 (lines 42–52: "transport-layer obfuscation, name-keyed — a
format fact, not key material"; checklist lines 191–193: "the 'key' is the
record's own name, a public table field"). The T3-s2 §7.5 checklist
(lines 111–122) carries the same disclaimer verbatim-class; the two notes
are consistent. This transport-layer format fact is not §7.3 key material
(it neither is, nor substitutes for, the `.tax` per-year AES keys/IVs, and
no `.tax` decryptor is created by it); the AES layer stays by-existence in
both notes. No decrypted content committed (in-memory, retention-free;
counts/closures/32-byte neighborhoods only); no expression lifts (names,
offsets, counts); lint-clean; the falsification of the "0x24000
divergence" is recorded with byte-exact closure evidence on both MSI
targets (Z_STREAM_END at exactly dsize on both; lines 66–78) — the
12-gate slip premise is disposed, the decompile chase mooted, D42's
keystream item closes. I note for the record: the two field-layout
corrections in this note (the v4 record offsets; the variable-offset entry
table) correct earlier prose, are labeled as corrections in place, and are
function facts — no legal surface.

**F3 — D46 rework (`git show 8b5c553`): the licensing posture holds;
D45 remains the open first-tag obligation.**
(a) *D45 still owed at the next tag:* DEBT.md D45 row unchanged — "the
NEXT tag (even a v1.x patch) owes the web manifest — three rows … |
the next tagged release" (DEBT.md:229). The D46 DONE text ends "D45's
LICENSES manifest remains owed at the first tag" (DEBT.md:230);
DECISIONS.md's D46 ruling says "the first tag still owes D45's LICENSES
manifest (unchanged)"; the README src/ row says "the first tagged web
release also owes D45's LICENSES manifest". Nothing anywhere implies a
tag may ship without it. However: the enforcement is records-level only —
`release.yml` contains no LICENSES-manifest step and `harness_check.sh`
no manifest assertion, so after this rework a tag is physically shippable
without the manifest. That gap is exactly what my condition 1 closes.
(b) *GPL §6 same-tag `--locked` discipline honored by the workflow's
design:* the release workflow triggers on tag push (validated `^v…`,
existing-tag SHA guard), the `nextjs-web` job checks out with the
SHA-pinned `actions/checkout@11d5960…` (v4.4.0) at the job head
(release.yml:498–505) — i.e. the tagged commit — and the new wasm step
runs `cargo build --locked --release --target wasm32-unknown-unknown
--manifest-path core-ffi/Cargo.toml` from that checkout (release.yml, the
D46 block), with the committed `core-ffi/Cargo.lock` (present, tracked)
pinning the dependency graph. The `.wasm` in the shipped tarball is
therefore built from the exact tagged source tree. The fail-closed
rustc ≥ 1.95 guard, the import-empty guard, and the new tar-listing
assertion (the boot asset must be IN the tarball) are all fail-closed
forms — no silent-degrade path. Confinement mechanically verified: my
awk probes give OUTSIDE=0 / INSIDE=6, and the same-commit
`harness_check.sh` flip asserts exactly that state ("the D46 rework
state: the wasm boot asset built --locked from the tagged checkout in
that job only").
(c) *README truth:* the src/ row states the D46 rework landed (2026-11-28,
the guards enumerated) and the D45 debt — accurate against the workflow
as diffed; the stale "see D46 before any tagged web release" instruction
was correctly replaced by the post-rework truth.

**F4 — The records: the 2026-11-28 rulings are recorded accurately; T4 is
gated; two record-currency residues ride the close.**
DECISIONS.md "Owner rulings recorded 2026-11-28": option (a) chosen = T3
session 2 FUNDED (the chase + `tax-modern.md`, D42) — matches the owner's
"1:A"; D46 "DISCHARGED (owner-ordered 'do that small rework now')" —
matches "D46: do that small rework now"; "T4 — FUNDED … Funding gates the
lane, not any work: T4 still enters ONLY behind its own entry gate … No
T4 code exists yet; the entry gate convenes at T4's session start" —
matches "T4 funding: approved" and correctly re-gates execution. CONSENSUS
carries the matching 2026-11-28 entry (all three rulings, commit 8b5c553
cited, "execution strictly behind its own entry gate (no T4 code exists
yet)"). ROADMAP carries the T3 and T4 FUNDED entries with the same
entry-gate gating language (ROADMAP.md:869–894). DEBT.md's D46 row is
marked DONE with the verification record. I confirmed no T4 code exists:
the delta contains no T4 module, no key table, no bridge code (the delta
enumeration is 12 files; none is T4). Residues (non-blocking, close-time):
(i) ROADMAP's Stage-2 slip paragraph (lines 330–349) still reads as of
2026-11-26 — "3 of 4 named specs", the divergence premise standing, "the
decompile-level chase … required" — and DEBT's D42 row keeps its
2026-11-26 form; the falsification and the 4/4 completion are recorded in
the T3 note, the spec §3, and the commit message, but not yet in the
Stage-2/D42 rows; (ii) the 2026-11-28 ruling records (DECISIONS /
CONSENSUS / ROADMAP / PROJECT_MEMORY) are working-tree-only, uncommitted,
and `harness_check` currently reports 1 failure — "2 unpushed commit(s) …
run scripts/sandbox_backup.sh" (a process-hygiene check, not a DoD item).
Condition 2 makes the sync checkable.

**F5 — Provenance-heading normalization: formatting-only, confirmed.**
`git diff HEAD~1 -- docs/re-research/`: 137 insertions, **0 deletions**.
The five pre-existing notes each gain exactly three lines — blank line +
`## Provenance (protocol §7.1)` heading + one identical boilerplate
paragraph restating the corpus/posture (sha256-pinned four-installer
corpus; §7.2/§7.3/§7.4 posture) that matches each note's own Status-block
posture (verified line-by-line on T2-session-3). The sixth file in the
diff is the new T3-session2 note itself. No existing line was modified or
removed; no substantive claim changed; the normalization tool
(`scripts/add_provenance_headings.py`) is committed and is what the lint's
new scope-all Provenance-section requirement mechanically enforces.

**F6 — Stage-2 DoD checklist re-verified mechanically (not by assertion).**
4/4 named specs present (`ls docs/formats/`: clearfile-json,
tax-exchange-container, tax-modern, txf — exactly the named four); each
lint-clean in scope-all mode (the §7.5 mechanical half; each carries its
§7.5 checklist — spec 4's is in-file, the other three were gate-verified
at their landings and remain untouched by this delta); exactly 2
Stage-2-execution session entries in SESSION_LOG (lines 1152, 1294 — the
T3 sessions are TT-program sessions per the namespace rule and do not
count); blob assertion green (`check_binary_blobs.py`: clean, 465 tracked
files, 28 allow-listed own binaries); RE-tooling refusal/cap suite green
(`test_re_tools.py`: 23 tests OK, run today); the Dart-side refusal/cap
set (incl. the TXF 10,000-record refusal) is green by the terminal-close
record (`1ccfa43`: all suites green) and untouched by this delta. The
Stage-2 EXIT gate's charter premise — spec 4 landed, the divergence
falsified end-to-end — is corroborated by the record evidence; the
falsification is a factual/format finding (byte-exact closures on both
targets), which I have no ground to dispute and which moots the only
technical obstacle the slip ever recorded.

**F7 — Process hygiene note (non-DoD).** `harness_check.sh` today: 1
failure = the 2-unpushed-commits backup reminder (commits `8b5c553`,
`02d7289` postdate the last backup). Resolves with the close-time backup
run; folded into condition 2.

---

## Verdict: PROCEED-WITH-CONDITIONS (2)

No BLOCK: no §7 guardrail violation exists in any new file; no key
material, no decrypted content, no expression lifts anywhere in the delta;
the D46 rework honors the pre-ruled narrow form and the GPL §6 same-tag
discipline; the rulings are recorded accurately with T4 correctly gated
behind its own entry gate; the DoD checklist is green on my own runs.

**Condition 1 — D45's mechanical protection must exist before the first
tag ships.** The D46 rework's declared effect is that a tag is again the
owner's ordinary decision, while D45 (the first-conveyance LICENSES
manifest — the palette Apache-2.0 row, the statically-linked Rust std
MIT-OR-Apache-2.0 row, the carried MIT shadcn set) is protected only by
the debt record; `release.yml` has no manifest step and nothing
fail-closed stops a manifest-less tag. **Checkable:** before the first
v-tag push, a fail-closed assertion exists in the tree (the release job or
`harness_check.sh`) that refuses a release without the D45 manifest, and
the first tagged release's artifacts actually carry it. (The D45 record
itself already says the right thing — this condition only closes the
enforcement gap the rework re-opened.)

**Condition 2 — Exit-close records sync (the falsification and the
rulings must reach the standing rows).** At the exit close, in the close
commit: (i) ROADMAP Stage-2's slip paragraph updated from "3 of 4" to the
4/4 + exit state with the 0x24000 premise recorded FALSIFIED (artifact:
the T3-session2 note; both targets' byte-exact closures); (ii) DEBT D42's
row notes the keystream item CLOSED by falsification, residues (a)–(d)
riding unchanged; (iii) the working-tree 2026-11-28 ruling records
(DECISIONS / CONSENSUS / ROADMAP / PROJECT_MEMORY) committed; (iv)
`scripts/sandbox_backup.sh` run so `harness_check` returns 0 failures.
**Checkable:** post-close `grep` on the two rows + a clean
`harness_check`.

**Non-condition note (posture to preserve):** the transport-constant
recording (`13 35 86 07`, name-keyed, T2-s3 + T3-s2) stands as a recorded
format fact and must stay clearly distinct from §7.3 key material in all
future notes — the by-existence rule for the `.tax` per-year AES keys/IVs
is untouched by it and must not be eroded by analogy. Any future T4
artifact remains behind the ADR-020 boundary conditions and its own entry
gate, exactly as recorded.

— ADV-LEGAL, 2026-11-28 (untracked gate report; not committed per protocol)
