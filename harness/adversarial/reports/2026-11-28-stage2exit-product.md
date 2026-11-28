# ADV-PROD — Stage-2 EXIT gate (delta-scoped) · product-honesty review
**Date:** 2026-11-28 · **Reviewer:** ADV-PROD (isolated) · **Gate:** the Stage-2 EXIT gate (slipped since 2026-11-23; surfacings 1–13 recorded; the THIRTEENTH disposed by owner ruling option (a), 2026-11-28)
**Delta scope:** `git diff 1ccfa43..02d7289` (the N6 terminal close → tip) **plus the uncommitted working tree** (4 modified files: PROJECT_MEMORY.md, CONSENSUS.md, DECISIONS.md, ROADMAP.md — the ruling records, not yet committed), per the gate's delta rule.
**Product bar under review:** "a reader can verify every number against a cited source without reading git history" — claims cite evidence; slips are recorded honestly; nothing silently grows.

---

## 1. The delta, itemized

`git diff --stat 1ccfa43..HEAD` → 12 files, +421/−7:

| File | Δ | Nature |
| --- | --- | --- |
| `docs/re-research/2026-11-28-tt-t3-session2.md` | +122 | **the falsification record** (funded T3 session 2, deliverable 1) |
| `docs/formats/tax-modern.md` | +175 | **spec 4 of 4** (funded T3 session 2, deliverable 2) |
| `docs/re-research/{5 × T2 notes}` | +3 each | Provenance-heading normalization only (verified by diff: the identical §7.1 block inserted; `add_provenance_headings.py` is a one-shot formatter, not wired into CI/harness — `git grep add_provenance_headings -- .github scripts/harness_check.sh` → no matches) |
| `scripts/add_provenance_headings.py` | +43 | the one-shot normalizer itself |
| `.github/workflows/release.yml` | +50 | the D46 rework (see §4b) |
| `scripts/harness_check.sh` | +19/−5 | the same-commit variant-guard flip (see §4b) |
| `README.md` | 2 | the src/ row truth update (see §4b) |
| `harness/memory/DEBT.md` | 2 | D46 → DONE (see §4b) |

No engine, core, codec, bridge, or Flutter files touched — the frozen surfaces (ADR-016/017) are untouched by construction; prior suite results carry for this delta.

---

## 2. RECORDS HONESTY (primary surface) — the disposition is recorded in the note and the commit, but NOT in the gate-time memory records

**The falsification itself is credible and well-anchored.** `docs/re-research/2026-11-28-tt-t3-session2.md` quotes the old premise verbatim (l.26–30), disposes it (l.80–93: "the recorded '0x24000 divergence' is FALSIFIED… an artifact of the wiped session's bench pipeline… the class is identifiable… The decompile chase the slip demanded is mooted"), honestly declines to reconstruct the exact old bug ("un-reconstructable in detail — the bench scripts went with the recycles", l.86–88), and corrects two field-layout errors in its own program's prior records (l.38–60) without overclaiming. I cross-checked its numbers against the independently recorded T2 values:

- MSI dsize **383,877,541** and VC_redist **18,479,851** → T2-s3 l.73/81/83 ✓
- decode output **390,117,376 B** → T2-s3 l.106 (recorded 2026-11-23, five days before this session) ✓ — the "byte-exact closure" is anchored to a number this session did not produce
- CAN MSI dsize **246,582,748** + ndp48 **121,227,973** → T2-s3 l.91–92 ✓; payload **369,198,176 B** → targets-phase1 l.46 ✓
- header offsets **0x198c00** / **0x14ae00** → T2-s2 l.85/95 ✓; MSCF **121 folders / 6,503 entries** → T2-s3 l.124 ✓
- The old premise's own history is consistent: T2-s3 (l.105–106) had *already* decoded the 2026 MSI whole; the 0x24000 divergence claim appears later (CONSENSUS l.988–996, SESSION_LOG l.1612) from the chase whose bench was wiped — exactly the artifact story the falsification record tells.

The funded scope's letter is honored: DECISIONS.md (2026-11-28) offered "the keystream chase (decompile-level …, **or** the structural-hypothesis sweep)" — closure by sweep-and-verify without a decompile is within the ruling's own text, and the mootness is a consequence, not a scope cut.

**But the gate-time records — the surfaces the protocol's future gates actually read — do not carry the disposition. The honest-disposition bar is currently FAILED on all three:**

- **F1 · DEBT.md D42 row (l.47) is NOT updated.** The row's body is the pre-falsification residue list and its Stage/disposition column still reads "**T3 session 2**" — the disposition of a chase that has now RUN and closed. The falsification record itself says (l.102–105) "D42's keystream item CLOSES … remaining residues … ride their lanes unchanged", yet the row a DEBT reader sees still presents the chase as owed. This is the exact silent-contradiction class the bar forbids. `git status` confirms DEBT.md has no pending edit.
- **F2 · ROADMAP.md's Stage-2 slip block (l.330–349) is NOT reconciled and now asserts three falsehoods:** "the documented variant-A cipher inflates cleanly to 0x24000 then dies … the decompile-level chase … **is required**" (l.333–336), "`tax-modern.md` **remains unwritten**" (l.337), "the exit gate **remains unconvened**" (l.337–338) — while spec 4 is published, the chase is falsified, and this gate is the convening. The unstaged ROADMAP edit added only the T3/T4 FUNDED markers in the TT-program section (l.870–874, 882–885) and left the slip block untouched.
- **F3 · CONSENSUS.md never records the falsification.** Eleven assertions of the open chase stand (l.990, 1121, 1664, 1763, 1872, 1919, 2073, 2188, 2298, 2377, 2441–2444 — the latest, at the terminal close: "the MSI-record keystream chase stands as recorded debt D42 (disposition 'T3 session 2')"). The sole 2026-11-28 entry (l.2446–2462, unstaged) records the owner's three **rulings** but none of their **outcomes** — no falsification, no spec-4 landing, no gate convening. A CONSENSUS reader finishes today's records still believing a cipher chase is open.

A reader of the re-research note or the commit message gets the truth; a reader of DEBT/ROADMAP/CONSENSUS — the gate-time contract — does not. The disposition must be reconciled into all three at the close (conditions 1–3).

---

## 3. SPEC 4 QUALITY — `docs/formats/tax-modern.md`: PASS

- **Spec count:** `ls docs/formats/` → exactly the 4 named DoD files (`clearfile-json.md`, `tax-exchange-container.md`, `tax-modern.md`, `txf.md`); no strays (checked with `ls -la`). Matches ROADMAP l.206–210's fixed N=4 list verbatim.
- **Citations:** the public write-up is named, dated, and linked (l.15–17); §2 is headed "per the public write-up — described and linked, not reproduced"; §3 names this repo's verification artifact per claim (`2026-11-28-tt-t3-session2.md`, the T2 records) and every number in it cross-checks (see §2 above); §4 cites the T3 session-1 note for the identifier-level anchors. Nothing is stated as repo-verified fact that is only the write-up's claim — the one place the risk lived (other years' keys) is explicitly fenced: "recorded as the write-up's claim, not this repo's verification" (l.148–150).
- **Honest limits are unmissable:** a bold "No owned `.tax` sample exists" paragraph in the Provenance header (l.30–37) AND a dedicated §5 "Honest limits" (l.136–150) repeating the no-owned-sample rule, the unresolved password-mechanism relationship (D42 ride-along), the remaining residues, and the ISc scope boundary.
- **Namespace collision cannot be confused:** §1's "Namespace collision, stated honestly" (l.48–54: spec 2 carries `clearfile.json`; this family carries `manifest.xml` + `tax:UUID`; a ClearFile reader correctly reports "not a ClearFile container") plus §6's DoD-boundary note (TT deliverables never count toward N=4; the password-layer spec remains a distinct future artifact). The T2-s1/T2-s3 field-offset corrections are recorded in §3 with the correction named.
- **Crypto hygiene:** keys by existence only (l.67–73: "linking is describing; reproducing is trafficking"); the §7.5 checklist is applied and recorded (l.164–175).
- **Mechanical backstops re-run live by this gate:** `python3 scripts/lint_format_specs.py` → **4 files clean**; `--scope all` → **11 files clean**; `check_binary_blobs.py` → clean (465 tracked, 28 allow-listed). The "oracle 17/17 / blob clean / exactly 2 execution sessions" DoD claims are consistent: the delta touches no engine/core code, the T3 session is a TT-program session under the namespace rule (ROADMAP l.874–880), and Stage-2's two execution sessions remain 2026-11-22 and 2026-11-23.

---

## 4. THE OWNER'S THREE RULINGS — recorded and acted on faithfully

**(a) T3 funded → BOTH deliverables present.** The chase record (`2026-11-28-tt-t3-session2.md`) + `docs/formats/tax-modern.md` (§2, §3 above). The ruling's full text exists (DECISIONS.md, "Owner rulings recorded 2026-11-28" — unstaged; CONSENSUS l.2446+ mirrors it). FAITHFUL.

**(b) D46 "do that small rework now" → landed in LEGAL's exact pre-ruled narrow form.** `git show 8b5c553`:
- The wasm steps (fail-closed rustc ≥ 1.95 guard → `rustup target add wasm32-unknown-unknown` → `cargo build --locked --release --target wasm32-unknown-unknown` → copy to `public/clearfile-core.wasm` + existence check → the import-empty guard) sit in the `nextjs-web` job ONLY: all `wasm32` references in release.yml are at l.576–591, inside the job that begins at l.498 (`git grep -n "^  nextjs-web:"` → l.498; single diff hunk; the job's tag-guard above verifies the tagged checkout before `npm ci`). The bundle step gained the fail-closed tar-listing assertion (l.604–610 region).
- The harness_check guard flipped **in the same commit** (both files in 8b5c553's stat): the N1 variant precondition is now the awk-scoped confinement assertion — "zero `core/|clearfile-core|cargo` matches OUTSIDE the job block, the confined steps present INSIDE it" — narrowed, not lifted, exactly as LEGAL rider 2(a) ruled (2026-11-27-n6exit-legal.md l.349–353: "the harness_check release.yml variant-precondition guard flips IN THAT SAME COMMIT to the references-confined-to-nextjs-web state").
- `git grep "stale-by-design"` outside the historical records (STATE/CONSENSUS/SESSION_LOG/PROJECT_MEMORY) → **none**: README's `src/` row now states the post-rework truth (the shipped boot asset + "the first tagged web release also owes D45's LICENSES manifest"); DEBT's D46 row is marked **DONE 2026-11-28** with the local end-to-end verification record (pinned-toolchain wasm build → public/ → import-empty → build-with-asset → tar listing carries `standalone/public/clearfile-core.wasm`).
- Live: `bash scripts/harness_check.sh` → the confinement guard PASSES ("release.yml's core/cargo references are confined to the nextjs-web job … 0 outside"). FAITHFUL.

**(c) T4 funded → NO T4 code exists.** The delta's 12 files contain nothing under `clearfile/`, `src/`, `core/`, `core-ffi/` (only release.yml/harness_check/README/DEBT/docs/one docs-formatter script); `git status` shows no untracked code (only this report, per the gate's untracked rule). DECISIONS/ROADMAP/CONSENSUS all record the funding-gates-the-lane-not-work rule ("the ENTRY GATE convenes at T4's session start before any T4 code exists"); tax-modern.md §2 l.74–78 independently confirms "no T4 code exists". FAITHFUL.

---

## 5. The D45/D46 coupling — intact

DEBT D45 (l.229) stands unchanged: the LICENSES manifest (palette Apache-2.0, Rust std **MIT OR Apache-2.0**, the carried MIT shadcn set; GPL §6 same-tag `--locked` discipline) owed at "**the next tagged release**". D46's DONE text preserves the coupling explicitly ("D45's LICENSES manifest remains owed at the first tag; the no-tag constraint's rationale is discharged"); README's src/ row repeats it; the release.yml rework keeps the `--locked`-from-tagged-checkout discipline D45's GPL §6 clause relies on. Correctly recorded as STANDING.

---

## 6. Consistency sweep

- STATE.md's text is the pre-teardown snapshot (still "the next session is a fresh directive's"; the parked items list) — per protocol STATE syncs at teardown; **not a finding**, treated per the gate brief.
- DEBT / ROADMAP / CONSENSUS mutual consistency: **consistent with each other and all three inconsistent with the session's own outcome** — each still presents the chase as open (F1–F3 above). They are internally consistent in their inconsistency, which is precisely why the reader-trap survives: no single record contradicts another on the chase; they all predate the falsification.
- The working tree vs the committed tree: the ruling records (DECISIONS/CONSENSUS/ROADMAP) are unstaged while the already-committed spec 4 cites "DECISIONS.md, Owner rulings recorded 2026-11-28" — until the close commit lands, the spec's own citation dangles.
- `bash scripts/harness_check.sh` → **1 failure**: "2 unpushed commit(s) — the last session-log entry postdates the backup; run scripts/sandbox_backup.sh". SESSION_LOG has no 2026-11-28 entry at all (the T3 session and the D46 discharge are unlogged). The close ritual is open; the checker itself is reporting it.

---

## 7. Verified-clean ledger (this gate's own runs)

- formats lint default: 4/4 clean · scope-all: 11/11 clean (both live)
- 32-hex canary probe of the scope-all lint: a canary note with a 32-hex run **fails** scope-all (exit 1, both violations flagged) — the rider's checkable clause works — while the default scope CI actually runs (hygiene.yml l.695) **passes it** (exit 0) → see condition 5
- check_binary_blobs: clean (465 tracked / 28 allow-listed) — live
- harness_check: every family green except the backup/unpushed-commits failure (§6)
- D46 confinement guard: green — live
- delta touches no frozen surfaces; no T4 code; D45 standing; 4/4 named specs present

---

## 8. Findings ledger

| # | Finding | Severity | Evidence |
| --- | --- | --- | --- |
| F1 | DEBT.md D42 row still disposes the keystream chase to "T3 session 2" — no falsification note; the row contradicts the session's own disposition | HIGH (records honesty) | DEBT.md l.47; falsification record l.102–105; `git status` (no DEBT edit) |
| F2 | ROADMAP.md slip block asserts "the chase is required", "tax-modern.md remains unwritten", "the exit gate remains unconvened" — all three now false; unstaged edit added FUNDED markers but skipped the block | HIGH (records honesty) | ROADMAP.md l.330–349 vs commit 02d7289; working diff (T3/T4 markers only, l.870–894) |
| F3 | CONSENSUS.md: 11 open-chase assertions, zero falsification records; the 2026-11-28 entry records rulings but not outcomes | HIGH (records honesty) | CONSENSUS.md l.990…2441–2444; new entry l.2446–2462 |
| F4 | Close ritual open: no SESSION_LOG 2026-11-28 entry; harness_check FAIL on unpushed commits; the ruling records unstaged while committed spec 4 cites DECISIONS 2026-11-28 | MEDIUM | harness_check output; SESSION_LOG tail (ends at the N6 close); `git status` |
| F5 | TT-SEC-6's lint-coverage rider ("must cover docs/re-research/") is not enforced: CI runs default scope only; the scope-all flip is unrecorded in the memory layers and unwired in CI | LOW | 2026-11-22-tt-security.md item 6; hygiene.yml l.695; canary probe (§7) |
| OBS-1 | The T2-s1/T2-s3 field-offset corrections live only in the new note + spec §3; the older notes carry no erratum pointer (T2-s3 has its own erratum convention, l.66) — a reader of the old prose alone builds the ambiguous layout | OBSERVATION | T2-s3 l.32 vs chase record l.53–60 |
| OBS-2 | The chase bench lives in gitignored `tools/re/` (tt3_chase2/tt3_stream/tt3_can present locally) — the chase is not re-runnable from a fresh clone; consistent with the recorded corpus/bench posture since the TT gate; the record's own honesty about this is adequate | OBSERVATION | `.gitignore` l.105; `ls tools/re/` |

---

## 9. VERDICT

**PROCEED-WITH-CONDITIONS.** The delta's substance is sound, faithful to all three owner rulings, and independently cross-verified by this gate; the exit may close once the records stop contradicting it. Every condition is dischargeable at the session close (the repo's own rider-at-close convention) and is checkable as written:

1. **DEBT.md D42:** amend the row so its disposition no longer reads "T3 session 2" as an open chase — record the keystream/divergence item **CLOSED 2026-11-28, FALSIFIED as a bench artifact** (cite `docs/re-research/2026-11-28-tt-t3-session2.md`), with residues (a)–(d) explicitly standing and their next disposition named. Check: a DEBT reader cannot conclude the cipher chase is still owed.
2. **ROADMAP.md slip block (l.330–349):** append a dated falsification paragraph to the block (the original text retained as history, marked FALSIFIED, citing the chase record and commit 02d7289) or rewrite it per the dated-correction convention; it must stop asserting the chase is required and that `tax-modern.md` is unwritten/the exit gate unconvened. Check: the block's text and the falsification record agree.
3. **CONSENSUS.md:** extend the 2026-11-28 record (or add the session-outcome entry at the close) with the **outcomes**: the falsification, spec 4's landing (4/4 named specs, lint-clean both scopes), the D46 discharge already cited, and this exit gate's outcome — superseding the eleven standing "chase stands as D42" lines by dated entry, never by silent edit. Check: the newest CONSENSUS entry, read alone, leaves the chase closed.
4. **Close ritual:** land the SESSION_LOG 2026-11-28 entry (the T3 session 2 record + the D46 discharge + this gate); commit the unstaged ruling records (DECISIONS/CONSENSUS/ROADMAP — spec 4's Status line cites DECISIONS 2026-11-28 and must not dangle); run `scripts/sandbox_backup.sh` so harness_check's unpushed-commits failure clears (STATE.md syncs at teardown per protocol). Check: `harness_check` → 0 failures.
5. **TT-SEC-6 enforcement:** wire the lint's re-research coverage into CI (`python3 scripts/lint_format_specs.py --scope all` at hygiene.yml l.695, or a second step) and note the flip + the canary result in the records — the rider's checkable clause ("a canary note with a 32-hex run fails the lint") passed under this gate's probe, but nothing runs it in CI today. Check: hygiene's lint step covers `docs/re-research/`.

Not BLOCK: nothing in the funded session's work is unsound, unfaithful, or uncited; the failure is confined to the memory layers' sync, which the protocol discharges at the close this gate convenes.

*Untracked gate artifact — not committed, per the gate brief. No other files modified (the §7 canary probe wrote and removed a temp file; tree verified clean).*
