# ADV-PROD — Stage-2 entry gate review (2026-11-17)

*Filed near-verbatim from the independent reviewer's returned report (Task ID 3-d; isolated context; ran concurrently with the other three reviewers, none of which it saw).*

## Verification log

- `git status --porcelain` — empty (tree clean; HEAD = a18b160). Unauthenticated
  `git ls-remote https://github.com/maniesh-NR/ClearFile.git`: `main = a18b160`,
  `v1.0.1 → 0bbb564`, `v1.0.0 → a121f11` — matches the orchestrator's facts.
- `flutter analyze` (repo root, PATH=tools/flutter/bin) — **wrong vantage**: it
  swept the gitignored vendored SDK (`tools/flutter/...`, 190k issues). The
  correct vantage, `cd clearfile && flutter analyze` — **"No issues found!"**
  (hygiene CI uses the same vantage, `hygiene.yml:59-60`).
- `cd clearfile && flutter test` — **"+111: All tests passed"**.
- `npx tsc --noEmit` — exit 0. `node scripts/txf_taxfile_test.mjs` —
  **10/10 groups**. `node scripts/web_parity_test.mjs` — **16 fixtures, 0
  field failures**. `python3 scripts/verify_golden_fixtures.py` — **16/16**.
  `python3 scripts/web_smoke.py` — **6/6 ALL CHECKS PASSED** (incl. "demo
  disclaimer is visible"). `bash scripts/harness_check.sh` — **12 checks, 0
  failures** (111 test counts consistent across README/STATE).
- Stage-3 commits inspected (`git show --shortstat`): 99d6823 (30 files,
  +1790/−95), 769e57b (23, +1635/−667), 74a1286 (22, +2233/−111), 935f782
  (4, +193/−21), a18b160 (24, +1698/−125) — scope matches every ROADMAP claim.
- Docs/product coherence spot-checks: README test itemization 19+8+10+3+5+2+5+
  6+3+11+9+14 = 95 (+16 golden = 111) ✓; parameters mirror across codebases
  and engine.md (`src/lib/tax/config.ts:142-235` vs
  `clearfile/lib/models/tax_year.dart:157-256`: 15,750/31,500/23,625; senior
  6,000; QDI MFS cap 300,000; SALT 40,000/10,000; NIIT MFS 125,000; CTC
  2,200/ACTC 1,700); fixture 05 carries `source.publication` + `urls` +
  verbatim `pin` ✓; `docs/formats/` does not exist yet (correct — Stage 2 not
  entered) ✓; `.gitignore:63-91` keeps `tools/` and sandbox paths out of the
  public tree ✓.
- Live release page (public HTML, unauthenticated): v1.0.1 title + 11 assets
  enumerated by name (3 APKs, linux/windows/macos/flutter-web/web-standalone
  archives, blueprint.pdf, reverse-engineering-protocol.md, SHA256SUMS.txt).
  Asset download counts are NOT in the unauthenticated HTML render (lazy
  fragment), and `api.github.com` returns **HTTP 403 — shared-IP rate limit
  exceeded** (recorded honestly; the PAT was not used per instructions).
  **No iOS asset has ever shipped.**
- Bootstrap reading completed in order (WORKFLOW §2, ROLES, ROADMAP, STATE,
  DECISIONS ADR-001..015, DEBT D1–D32, last 3 SESSION_LOG entries, CONSENSUS
  both gate records, protocol, ghidra-sandbox-feasibility, engine.md, tour.md,
  README, return-format.md). No other reviewer's report was opened.

## Findings

1. **PROD-1 [MAJOR] — iOS is silently dropped from the native re-platforming
   plan.** `harness/memory/DECISIONS.md:306-309` states "The four named OSes
   match the existing Flutter targets (Windows, macOS, Linux, Android)" — but
   the existing Flutter targets are six: `README.md:19` ("compiled to Android,
   iOS, macOS, Windows, Linux and Web"). ADR-014's table
   (DECISIONS.md:283-289) has no iOS row, and no iOS binary has ever shipped
   (v1.0.1 asset list above). A shipped-compile-target orphan is exactly the
   kind of silent platform decision the settlement exists to prevent.
   **Fix:** the ADR-014 settlement must decide iOS explicitly (my
   recommendation: drop-and-record — see Agenda 3-vii; the Flutter app
   remains the iOS vehicle through the transition, then iOS ends at the last
   Flutter release).
2. **PROD-2 [MAJOR] — the native program has no roadmap home; settling
   "which stages absorb the work" inside the current 1→3→2→4→5→6 order would
   reopen the terminal stage.** ROADMAP ends deliberately at Stage 6
   (ROADMAP:367-373, ADV-PROD F11: a finite roadmap). Four native UI stacks
   over a Rust core is a multi-quarter program for ONE maintainer; inserting
   it before Stage 6 would make the "freeze" a farce (the frozen v1 under
   active replacement) and delay the already-reachable v1.1 DoD. **Fix:** the
   settlement records the native program as a separate, post-Stage-6
   **epilogue roadmap** with its own finite stage list (Rust core first,
   per-OS stacks after, its own terminal freeze); the current roadmap's end
   state is unchanged. See Agenda 3.
3. **PROD-3 [MINOR] — ADR-014's platform rows conflate version tiers with
   stacks.** Linux lists four toolkits ("gtk-rs / gtk3-rs …; Slint and Qt",
   DECISIONS.md:287,299-300 — gtk-rs and gtk3-rs are the same project);
   macOS lists "Swift (for newer versions) + AppKit (for older versions)"
   (DECISIONS.md:298) — a language paired with a framework as if they were
   tiers. Two-or-more UI toolkits per OS for one maintainer is the overreach
   pattern. **Fix:** the settlement defines ONE toolkit per platform plus a
   deployment floor (Linux: gtk-rs/gtk3 only; macOS: one Swift+AppKit app
   with a named minimum; Slint as recorded fallback, Qt cut). See Agenda
   3-v/vi.
4. **PROD-4 [MINOR] — the Stage-2 DoD is still un-fixed in-repo.**
   ROADMAP:193-207 carries the agenda item ("define N … BEFORE entry") but no
   numbers exist anywhere yet; without a fix at this gate, Stage 2 enters
   with the same unfalsifiable DoD PROD-1 flagged at the 2026-11-14 gate (a
   stage that can silently never complete). **Fix:** adopt the DoD below
   (Agenda 5) into ROADMAP's Stage-2 section at this gate's close.
5. **PROD-5 [NOTE] — the misuse surface grew this stage; the demo-first
   posture held.** TXF import + `.tax` inspection + unified
   `.clearfile.json` + exchange containers make the demo genuinely useful
   with real taxpayer data — the mandate's "useful enough to be misused"
   tension is now live. Evidence the posture held: the smoke test asserts
   the visible disclaimer; README:237-244 ("Do not file a real return");
   engine.md §6 limitations register; the format template forbids
   proprietary pastes (format-discrepancy.md:17-19). **Watch-item:** Stage
   4's public Pages deploy is where the tension gets stress-tested — the
   existing "welcome disclaimer verified prominent" scope (ROADMAP:348-350)
   must survive a public URL.
6. **PROD-6 [NOTE] — real-user exposure is unverifiable from this sandbox.**
   Download counts absent from unauthenticated HTML; API 403 rate-limited;
   PAT off-limits. Migration-shape planning must therefore assume v1.0.1
   binaries MAY be in real users' hands (11 shipped assets) — conservative
   planning, honestly recorded, not papered over.

## Agenda answers

**1. Stage-3 closure — YES, close it formally at this gate.** Every promised
value landed and was re-verified by me today: parity is real and PINNED
(16/16 on both engines + the independent Decimal oracle, in CI on every push,
`hygiene.yml:68-79`); the bridges matter to real users (TXF spec-v042 import
with hardening caps, read-only `.tax` inspection, and the unified format that
FIXED a real cross-codebase bug — web-exported exchange containers were
unimportable by the Flutter app, ADR-015); the study is legible without git
history (tour.md's reading order, engine.md's line map + limitations
register, return-format.md, citation-requiring discrepancy templates). The
slip-tripwire fired and was recorded honestly in three places
(ROADMAP:327-336, STATE:48-53, SESSION_LOG:672-679). Stage 3: CLOSED.

**2. Parity tripwire (mandatory) — recommend CONTINUED PARITY, narrowed to
maintenance, with an explicit retire-on-replacement rule; the owner must
record whichever disposition it picks.** The freeze case, argued honestly:
ADR-015 deepened coupling (every format change = both parsers + both suites);
ADR-014's Rust core makes the TS engine a scheduled transition artifact, so
further TS investment risks building a bridge for demolition; the slip fired
and the tripwire's promise obliges an explicit answer, not silence. The
parity case, argued from MEASUREMENT: the box closed under budget in ONE of
its two sessions (ROADMAP:270-289) — the doubled-cost fear did not
materialize; the remaining parity-bearing work is small (Stage 5
timeout/header items, Stage 6 parameter corrections — mechanically
symmetric, fixture-guarded); and a pre-emptive freeze recreates exactly the
D32 divergence it pretends to avoid: a frozen web engine stuck at TY2025
next to a Flutter engine that gains TY2026 at Stage 6 is a NEW silent
divergence. Disposition: parity continues as MAINTENANCE ONLY (no standalone
new web features), and terminates by REPLACEMENT — the TS engine freezes to
a docs-only transition artifact the day the Rust core serves the web (WASM
included). If the owner instead rules freeze now, it must be recorded in
DECISIONS/CONSENSUS with the TY2026-divergence consequence named.

**3. Native re-platforming settlement (ADR-014) — this seat's centerpiece.**
- (i) **Migration shape: staged per-OS, never big-bang.** The Flutter app is
  the transition vehicle and remains the shipped product on every OS until
  that OS's native stack reaches GA; each native GA retires that one Flutter
  target (a per-OS freeze, recorded in its own ADR). v1.0.1 binaries shipped
  to real users (11 assets; counts unverifiable here — PROD-6), so staged
  replacement with no coverage gap is the honest shape.
- (ii) **Placement/budget: NOT in the current roadmap.** The current
  1→3→2→4→5→6 order closes at Stage 6 with the v1.1-capable state; the native
  program is a separate, post-freeze epilogue roadmap with its own finite
  stages — N1 Rust core → N2 Linux gtk-rs (direct Rust, no FFI seam, builds
  in this sandbox) → N3 Android (Views+Kotlin; the largest shipped user
  base) → N4 Windows (Win32+Direct2D, the highest UI effort) → N5 macOS
  (Swift+AppKit) → its own terminal freeze. Acceptable owner variant: the
  Rust CORE alone (no UI stacks) may start parallel to Stage 4 behind its
  own gate, provided no shipped artifact depends on it and v1's stages still
  close first. Rationale: single-maintainer sustainability — build the
  replacement AFTER the finishable product is finished; never dual-maintain
  live engines during the build.
- (iii) **Rust core scope: the 1040 engine + format bridges (TXF
  import/export, `.tax` read-only inspection, envelope codec + migrations,
  exchange container) + the parameter tables — exactly what the two engines
  duplicate today. NOT the AI cascade (stays per-platform: low duplication,
  high churn); NOT UI/interview; not per-platform stores (the envelope IS
  the persistence contract). The core's acceptance gate is the SAME 16
  golden fixtures + oracle — the fixtures outlive every engine.**
- (iv) **FFI seams: one flat C ABI (`extern "C"`) with the `.clearfile.json`
  envelope as the payload boundary (it is already the specced serialization,
  return-format.md §1-2) + thin glue per platform: direct Rust on Linux
  (gtk-rs), a hand-written Swift wrapper over the C header on macOS, a small
  JNI shim on Android. The surface is ~a dozen functions — no binding
  framework needed; toolchain risk beats convenience for one maintainer.**
- (v) **macOS tiering: ONE Swift+AppKit app, deployment floor proposed at
  macOS 12, confirmed at that stack's entry gate. "Swift for newer + AppKit
  for older" resolves to "Swift+AppKit, old-to-new" (AppKit IS the
  conservative choice; no SwiftUI dependency). Builds ride the existing
  `macos-latest` CI runner (release.yml:288) — this Linux sandbox cannot
  build or test AppKit, a standing cost to name.**
- (vi) **Linux toolkit line: ONE toolkit — gtk-rs/gtk3 (Rust-direct, runs
  on old and new distros alike, dissolving the "older/modern" split).
  Slint = recorded fallback; Qt bindings = cut (C++ toolchain, the heaviest
  option). The "gtk-rs / gtk3-rs" pair in ADR-014 is one project, not two.**
- (vii) **KMP second target: NONE — Android-only — because I recommend
  DROPPING iOS from the end-state platform set (PROD-1): no iOS asset ever
  shipped, no distribution path, macOS covers the Apple story, and one
  maintainer cannot carry Apple signing/storefront obligations for a demo.
  If the owner insists on iOS, the second KMP target is iOS by construction —
  but that is the overreach branch.**
- (viii) **v2.0.0 semver: the major is earned at the first GA release whose
  distributed artifact for any OS is the native stack (a user-visible
  platform-lineage change). The Rust core landing alone does not bump; v1.1
  does not wait for any of this. Keep the three version planes separate:
  app semver ≠ envelope schema version (return-format.md §7) ≠ the web
  prototype's package.json 0.2.1.**
- (ix) **ADR-009 disposition once one Rust core serves every platform
  (web via WASM): parity RETIRES by replacement — each platform's old
  engine freezes when its native stack GAs; the TS engine retires to a frozen
  transition artifact when WASM serves the web; the Dart engine remains the
  reference until the Rust core's fixture parity is green, then freezes to
  reference status; the parity suites survive as long as any old engine
  ships anywhere. The doubled cost ends per-platform, not all at once.**
- **DoD and Stage-6 interaction:** v1.1 is reachable on the CURRENT
  codebases and must not wait — the DoD state already exists in-tree
  (tour.md:73-80; my spot-checks: inline fixture citations, engine.md
  parameter sources, return-format.md). v1.1 is a TAG decision; my
  recommendation: tag it as the closing event of Stage 5 (the last
  app-touching stage), which also discharges D29's tag-push verification at
  the next tagged release. The settlement keeps the roadmap FINITE: the
  current one still ends at Stage 6 (freeze); the native program is a second
  finite roadmap, entered only when the owner actually funds it with
  sessions; two finite roadmaps, not one reopened infinite one.

**4. Placement ADR-012 — IN-REPO, with the constraint set (my standing
position, strengthened by the new facts).** (1) The safe bridges already
shipped in-repo (TXF import, read-only `.tax` inspection, exchange
containers) under the same guardrails the tooling needs — the activity is
not new, only more disciplined; (2) Ghidra Phase-4 was measured FEASIBLE in
this sandbox (ghidra-sandbox-feasibility.md:7-10), so the repo's own
environment is the research bench; (3) the enforcement stack (§7 checklist,
pre-commit secret guard, gitleaks full-history scan, harness_check, gate
discipline) lives HERE — a second repo duplicates it for one maintainer and
invites discipline drift; (4) the product story is the integration:
tour.md's stop 3 already makes the protocol part of the study narrative;
splitting halves both. Constraints (the carried ledger, restated):
write-free read-only tools, resource caps with refusal tests, the
no-binary-blob CI assertion with an explicit synthetic/owner-authored
provenance distinction, fixture paths gitignored, tooling never wired into
`release.yml` artifact paths, §7.5 checklist spot-verification at exit. The
one flip condition: outside PRs submitting proprietary files — already
fenced (format-discrepancy.md:17-19).

**5. DoD fix for the RE stage — N = 3 named specs + a conditional increment
+ a two-working-session box.** With the owner-authored TurboTax corpus
UNKNOWN (zero files exist in the sandbox or repo —
ghidra-sandbox-feasibility.md:71-74), no honest N can be pinned to it; N
pins to the corpus the repo FULLY controls, plus one proprietary-shape spec
writable from public sources today:
- `docs/formats/txf.md` — TXF v042 (the published spec is the primary
  source; the shipped import/export bridges and their tests are the
  "verified by" experiments; the repo fully controls round-trip inputs).
- `docs/formats/clearfile-json.md` — the unified envelope, its three
  vintages, and the exchange container (fully synthesizable; round-trips
  pinned by the 14 codec tests + the bridge suite).
- `docs/formats/tax.md` — the modern `.tax` container at SHAPE level (ZIP
  structure, manifest + `tax:<uuid>` naming, entropy phenomenology) from
  the public write-up + the shipped read-only inspector; its provenance
  section records the owner-authored file count as an integer — if >0, the
  experiments run on those files privately (§7); if 0, on synthetic
  Intuit-shape stand-ins, with that stated.
- **Conditional increment:** each additional owner-authored family
  deposited (≥2 same-version files: `.1PE`, `TT[YYYY]STATE`, …) adds one
  spec inside the box or is declared backlog at box-end — the box never
  silently grows. The differential tool must be exercised on a synthesized
  pair inside the mandatory set, so all Phase-1–3 tools get real exercise
  regardless of corpus.
- **Time-box: two working sessions from entry (the parity-box unit; counted
  per SESSION_LOG entries). Checkable at the exit gate by: `docs/formats/
  *.md` ≥ 3 with the three named files present; each §7.5-checklist-clean;
  refusal/resource-cap tests green; the no-binary-blob assertion green;
  SESSION_LOG shows ≤ 2 execution sessions.** The git-history pre-rename
  project is excluded from N (the owner's own code, not an unknown format —
  no RE value in spec'ing it; usable only as a provenance reference).

**6. RE tooling security contract (carried SEC-1) — the contract does not
change the product's story; it MECHANIZES the story the product already
tells.** The public posture is "read-only clean-room study; shipped
capability = safe bridges; no keys, no decryptors" (README:173-198, protocol
§2.2/§7). Permissions-read, timeouts, SHA-pinned actions, no
`pull_request_target`, write-free + resource-bounded tools with refusal
tests, gitignored fixture paths, and the release-artifact separation rule
are that posture made executable — and the standing exemplar already exists
for new jobs to copy (`hygiene.yml:17-18` permissions, timeouts, SHA pins
at lines 30-53). Two product-lens additions so the posture stays legible to
an outside reader: (a) each tool's own header/`--help` must STATE the
read-only + caps + refusal posture (readers meet tools before protocols);
(b) the tooling-never-in-`release.yml`-paths rule is a product-integrity
line, not just hygiene — no shipped binary may derive from RE tooling. The
tour's stop 3 + protocol §2 already carry the narrative; the contract
preserves it.

## What is sound

- **The verification pyramid is the product's strongest asset**: three
  independent implementations (Dart, TS, Decimal oracle) held to 16
  IRS-pinned fixtures whose citations travel inside the files — re-verified
  green by me today, in CI on every push (`hygiene.yml:68-79`). The adopted
  DoD (verify every number without git history) is substantively TRUE
  in-tree, not aspirational.
- **Stage 3 delivered real user value with honest edges**: the unified
  format fixed a genuine cross-codebase bug; TXF import is spec-true and
  hardened; `.tax` inspection names its own limits ("does not decrypt") in
  the shipped copy.
- **The tripwire discipline worked even in failure**: the slip was
  detected, recorded in three memory surfaces, and routed to this agenda
  as a mandatory item — the governance is functioning as designed.
- **Release posture**: 11 assets incl. SHA256SUMS + the RE protocol doc as
  a release asset; digests render on the release page; the demo disclaimer
  is visible end-to-end (smoke-asserted).
- **Docs coherence is checkable and checked**: harness_check's 111-count
  cross-checks passed; README/engine.md/return-format.md/fixtures agree
  with the code I spot-checked; the discrepancy templates demand citations
  — the study's honesty is mechanized, not vibes.

## Verdict

**PROCEED-WITH-CONDITIONS** — Stage 2 (RE tooling) may be entered; Stage 3 is
formally CLOSED. Conditions (all checkable before or during Stage 2):

1. **Parity disposition recorded** (the tripwire mandate): the owner records
   web-freeze-or-continued-parity in DECISIONS/CONSENSUS at or before
   Stage-2 entry — no silence; my recommendation is
   continued-parity-as-maintenance with the retire-on-replacement rule
   (Agenda 2).
2. **ADR-014 settlement recorded as a new ADR before any native-stack code
   lands**, resolving: iOS (PROD-1), the epilogue-roadmap placement
   (PROD-2), one-toolkit-per-platform + the macOS floor (PROD-3), the
   Rust-core boundary, the C-ABI seam, the KMP/Android-only call, and the
   v2.0.0 rule (Agenda 3).
3. **The Stage-2 DoD fix adopted into ROADMAP** (N=3 named specs + the
   conditional increment + the two-session box; Agenda 5) before the first
   tooling commit.
4. **ADR-012 placement recorded** (in-repo-with-constraints recommended;
   Agenda 4) before the first tooling commit.
5. **The RE tooling security contract applied at the first tooling
   commit** with the two legibility additions (the tool-header posture
   line; release-artifact separation; Agenda 6), verified at the Stage-2
   exit gate by reading the tool code and tests, not by assertion.
