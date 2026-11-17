# ADV-LEGAL — Stage-2 entry gate review (2026-11-17)

*Filed near-verbatim from the independent reviewer's returned report (Task ID 3-b; isolated context; ran concurrently with the other three reviewers, none of which it saw).*

## Verification log

- Repo state: `git status --porcelain` — clean; HEAD = `a18b160` = origin/main;
  `git ls-remote --tags origin`: `v1.0.1` → exactly `0bbb564`, `v1.0.0` tag object
  `a121f11` (peeled commit `13205da`). Matches the orchestrator's facts.
- Stage-3 commits read in full via `git log --oneline --stat -5`: `99d6823`
  (fixtures), `769e57b` (parity), `74a1286` (bridges + Ghidra), `935f782`
  (ADR-014), `a18b160` (ADR-015 close-out).
- Suites re-run this session (gitignored caches only): `flutter analyze` —
  "No issues found!"; `flutter test` — **"+111: All tests passed!"** (incl. the
  5 privacy-contract tests, `clearfile/test/privacy_test.dart`); `npx tsc
  --noEmit` — exit 0; `node scripts/txf_taxfile_test.mjs` — 10/10 groups;
  `node scripts/web_parity_test.mjs` — 16 fixtures, 0 field failures;
  `bash scripts/harness_check.sh` — 0 failures.
- Key-material scans (tree + history): `git grep -E "\b[0-9a-fA-F]{64}\b"`
  outside lockfiles — **zero hits**; AES/S-box/rijndael scan over
  `clearfile/lib`, `src/lib`, `scripts` — only prose *denying* decryption
  (`tax_inspect.dart:20-22,186`; `taxfile.ts:350`); history pickaxe for
  S-box/`aes_key` patterns (`git log --all -S`) — zero hits. No AES
  implementation exists in the codebase; the only `crypto` entry in
  `pubspec.lock:76` is `http`'s transitive (BSD) hash utility.
- Expression scan: all 16 golden-fixture `source.pin` values audited (python
  dump) — every one cites an **IRS publication** (1040 instructions, QDIVCG
  worksheet, Sch 1-A Part V, Sch A SALT worksheet, Sch 8812, Form 8960, SLI
  worksheet) — 17 U.S.C. §105 public-domain government works;
  `docs/engine.md` is a line-map (line numbers + short labels + parameters)
  quoting no third-party expression; `docs/return-format.md`/`tour.md` describe
  ClearFile's own formats. "TurboTax" mentions (7 files) are
  nominative-descriptive with explicit "NOT Intuit's format" disclaimers
  (`taxfile.ts:370`).
- Privacy claims vs code: `assistant.dart:37-67` (figures only when
  `sendReturnContext` on; names never), `assistant.dart:95-152` (review prompt
  de-identified by construction — `w2s` reduced to box1/box2, counts only);
  `providers.dart:66-106,145-183` (direct device→provider HTTPS only, no
  telemetry — telemetry-term grep over `src/`, `clearfile/lib/`: zero hits);
  web copy discloses the copilot-always-sees-summary and
  auto-fill-pastes-are-transmitted exceptions (`ai-ui.tsx:191`,
  `settings.tsx:260-261`); release body carries the network disclosure +
  GPL §6 corresponding-source line + unsigned-demo posture
  (`.github/workflows/release.yml` `body:`).
- SPDX/GPL audit: canonical GPL-3.0 `LICENSE` (674 lines) at root;
  `SPDX-License-Identifier: GPL-3.0-only` on all own-code files (Dart lib+test,
  `src/lib`, `src/app`, `src/components/clearfile`, `scripts`); vendored shadcn
  MIT correctly NOT relabelled and attributed in `THIRD-PARTY-NOTICES.md`.
- Tracked-binary census (python scan): 300 tracked files, 28 binaries — all
  own-authored assets (blueprint PNG/PDF, app icons). Relevant to the Stage-2
  no-binary-blob assertion design.
- Guard mechanics: `scripts/sandbox_backup.sh:91-92` — `TOKEN_PATTERNS` +
  `HEX_PATTERNS='[0-9a-fA-F]{64}'` (64-hex only, text-only, lockfiles excluded).
- **Independence incident, disclosed:** one tree-wide `git grep -i -E
  "decrypt|crypto"` (before I knew the reports directory's contents would
  match) printed ~15 matching lines from *archived 2026-11-14* reports in its
  output. I did not open any file under `harness/adversarial/reports/` with the
  Read tool, excluded that path from every subsequent scan, and read no
  2026-11-17 file. All positions below are derived from primary sources read
  directly.

## Findings

1. **LEGAL-1 [MAJOR] — §7.2/§7.3 are still policy, not mechanics, for the RE
   stage about to enter.** The publication guardrails (no decrypted content,
   no key material) are backed today only by (a) gitleaks (token-shaped
   secrets — an AES key is *not* token-shaped), (b) the backup guard's 64-hex
   heuristic (`sandbox_backup.sh:92`) — **a 16-byte key written as 32 hex
   characters passes it**, and (c) nothing that detects a decrypted XML
   payload pasted as text. Fix: the mechanical contract in Agenda answer 6
   (repo-tree binary assertion with an asset allow-list;
   provenance-manifest refusal in the differential tool; 32-hex-widened guard
   + spec lint on the RE-adjacent paths; synthetic-only fixtures). Must land
   with the first Stage-2 tooling commit.
2. **LEGAL-2 [MINOR] — the planned "no-binary-blob assertion" must be
   allow-list-based or it fails at birth.** The tracked tree legitimately
   contains 28 own-authored binaries (icons, `docs/blueprint.pdf`,
   `blueprint-assets/`). A naive "no binaries anywhere" CI assertion will
   either fail on day one or get watered down ad hoc. Fix: assertion =
   *tracked binaries only under the enumerated asset paths; any new binary
   under `fixtures/`, `tools/`, `docs/` (except the existing PDF), `src/`,
   `scripts/`, `harness/` fails CI* — plus the same allow-list wired into
   `sandbox_backup.sh` (the auto-publish denylist made mechanical).
3. **LEGAL-3 [MINOR] — the native re-platform (ADR-014) has a real licensing
   surface that is recorded nowhere.** ADR-014 names Qt, Slint,
   gtk-rs/gtk3-rs, KMP, Win32+Direct2D, Swift/AppKit and a shared Rust core
   but contains no license analysis; Qt is GPL/commercial dual-licensed (Qt 6
   Open Source is GPL-3.0 terms); Slint is GPL-3.0/royalty-free/commercial;
   GPL-2.0-only Rust crates are **incompatible** with a GPL-3.0-only core.
   Fix: the settlement table in Agenda answer 3, recorded as the settlement
   ADR's licensing annex + `cargo-deny`-style license check in CI + a
   per-platform LICENSES manifest at each platform's first tagged release.
4. **LEGAL-4 [NOTE] — Google API key sent as URL query (`providers.dart:67`).**
   Carried D11/D16, owned by Stage 5. No copy-accuracy problem (no privacy
   text claims header transport); noting it stays on the ledger so the
   "privacy claims accurate" conclusion is not read as covering key
   *handling*, only data-content claims.
5. **LEGAL-5 [NOTE] — README capability phrasing.** `README.md:19` "compiled
   to Android, iOS, macOS, Windows, Linux and Web" vs the release pipeline's
   actual assets (no iOS artifact is shipped; `release.yml` header). A
   supportable capability statement about the Flutter codebase, and the
   Releases row is the authoritative asset list — recommend one clarifying
   word ("targets") whenever the README is next touched. Not a disclaimer
   failure.

## Agenda answers

1. **Stage-3 closure: YES — lawfully executed within the clean-room line;
   formally CLOSE at this gate.** (i) TXF import implements the *published*
   spec v042 — record syntax, refnum→field mapping, sign convention are
   unprotectable function/field structure (§102(b); scènes à faire for an
   interchange spec communicated for implementation); the code cites the spec
   by section number and reproduces no spec text (`txf_import.dart:6-30`);
   hardening caps + 11 tests + CI bridge suite. (ii) `.tax` inspection is
   read-only: ZIP central-directory scan, STORE-only extraction, entropy
   flags, shape recognition with copy that says it does not decrypt and names
   the safe bridges (`tax_inspect.dart:21-23,182-190`; `taxfile.ts:337-352`)
   — no decryption act, no key material (verified: tree + history scans
   above) — §1201(a)(1) is never triggered by these tools, let alone
   trafficking. (iii) Golden fixtures: all 16 pins cite IRS publications —
   §105 public-domain; quoting instruction text is lawful *and* is exactly the
   best clean-room derivation evidence. (iv) The unified format is ClearFile's
   own invention, GPL'd, spec'd, guarded (ADR-015). All five Stage-3 commits
   land on the lawful side.
2. **Parity tripwire: recommend the owner ratify MAINTENANCE-FREEZE of the TS
   engine, with a recorded decision either way.** For freeze: ADR-014's
   one-Rust-core plan makes the TS engine a declared *transition artifact* —
   continued feature parity buys a sunset product at double per-stage engine
   cost; the unified `.clearfile.json` already guarantees file-level
   cross-compat; the fixtures keep a frozen engine honest at near-zero cost
   (16/16 today). For continued parity: parity is *done and green*, so
   today's marginal cost is only future features; the Rust core is unbuilt,
   so TS is the only web story until WASM lands — a freeze that outruns its
   replacement risks a coverage gap. Legally both are fine (GPL imposes no
   maintenance duty; the README scope statements are accurate today either
   way). Disposition: maintenance-freeze (fixtures stay 16/16 in CI;
   bug/security fixes allowed; no new TS-engine features) **unless** the
   owner records continued parity with a re-armed two-session box; silence is
   not an option the tripwire permits.
3. **Native re-platforming settlement (all sub-items):** (i) **staged per-OS
   migration**, Flutter app as transition vehicle + fallback — no big-bang
   (GPL §6 is unaffected either way: every tagged release already carries the
   corresponding-source line). (ii) Absorbed into a distinct stage block
   after Stage 2, per-OS increments each delta-gated; the *legal* cost is the
   license audit + LICENSES manifest at each platform's first tagged release.
   (iii) Rust core scope = 1040 engine + format codecs (TXF import/export,
   `.clearfile.json` codec, read-only `.tax` inspection — the lawful safe
   bridges) + persistence; **exclude the AI cascade** (keeps network/key
   handling and its privacy copy per-platform, keeps the core small and
   clean). (iv) FFI seams lawful everywhere — C ABI/Swift/JNI/direct are
   unprotectable interface glue; Win32/Direct2D and AppKit are proprietary
   **system libraries** (GPLv3 §1 carve-out) — no corresponding-source
   obligation for SDKs. (v) macOS tiering = an explicit deployment-target
   line (Swift interop above, AppKit-ObjC below) — pick the number at
   settlement. (vi) Linux line: **prefer gtk3-rs/gtk4-rs (MIT bindings +
   LGPL GTK, dynamic link — cleanest) for older and Slint under its GPLv3
   option for modern; Qt acceptable ONLY under its GPL-3.0 open-source terms
   with a recorded license note — commercial Qt without a purchased license
   is BLOCKED**; no LGPL static linking. (vii) KMP: Android-only; share
   logic via the Rust core over JNI (Kotlin/Apache-2.0 is GPL-3-compatible;
   a second KMP target adds surface without need). (viii) **v2.0.0: yes** at
   the re-platform boundary, with the `.clearfile.json` envelope version kept
   independent (stays 2). (ix) ADR-009 is superseded by *single-core parity*
   when the Rust core serves platforms incl. web: the fixtures remain the
   cross-engine contract; TS engine retires or freezes. Material You/MD3:
   implementing Google's design language is unprotectable functional design
   (*Apple v. Microsoft* filtration); nominal references fine, no
   Google/Material logos; residual patent exposure for a demo is negligible
   — NOTE only. Rust core: keep GPL-3.0-only to match the project; bar
   GPL-2.0-only and unlicensed crates (cargo-deny in CI).
4. **Placement ADR-012: IN-REPO, with binding conditions — I am updating my
   2026-11-14 separate-repo default on new facts, argued honestly.** What
   moved me: the harness (full-history gitleaks, backup secret guard,
   harness_check, the gate machinery itself) is bound to this repo and SEC's
   carried condition would require replicating it in a second repo before
   tooling anyway — a real single-maintainer cost; the safe bridges already
   shipped in-repo lawfully with tests, so read-only Phase 1–3 tools are a
   marginal narrative delta, not a new posture; Ghidra feasibility was
   measured with `tools/re/` gitignored and HOME-redirected, i.e. Phase-4
   mechanics stay out of the repo by construction; and the §7 checklist
   already exists and can be made mechanical (below). What kept me at
   separate — and what the conditions must neutralize: the auto-publish
   denylist (the event-driven backup pushes everything tracked at session
   end; a corpus file in an unignored path auto-publishes) and optics.
   Binding conditions: (a) one enumerated gitignored fixture/corpus path;
   (b) the hygiene binary assertion (LEGAL-2 allow-list design); (c) the same
   binary allow-list wired into `sandbox_backup.sh` — the denylist becomes
   mechanical; (d) every `docs/formats/*.md` passes §7.5 with a provenance
   field, spot-verified at the Stage-2 exit gate; (e) tooling never wired
   into `release.yml` artifact paths; (f) Phase-4 binaries/corpus never
   tracked. **Fallback: if any of (a)–(f) is not applied at Stage-2 entry, my
   position reverts to SEPARATE research repo** with
   pinning/least-privilege/secret-guard replicated first (SEC cond 3).
5. **DoD fix: N = 6 published `docs/formats/` specs in two working sessions,
   safest-first.** The corpus actually available: (1) `.clearfile.json` v2
   envelope, (2) legacy flat `clearfile.return`, (3) web v1 `.cfr`, (4) the
   `.tax`-extension exchange container, (5) TXF v042 round-trips (both
   exporters are in-repo), (6) the modern `.tax` ZIP+AES shape **on the
   owner's own licensed files only — count unknown to the repo, therefore
   NOT required for the DoD; any spec on them is a §7.1-compliant bonus**.
   Rationale: repo-own formats carry zero third-party legal surface and
   exercise the full Phase 1–3 chain (plain/ciphertext pairs, differential
   tool, spec writing); TXF is a published spec; the proprietary corpus is
   last and owner-authored-only. Checkable at the exit gate: ≥6 specs in
   `docs/formats/`, each passing §7.5, within ≤2 working sessions per
   SESSION_LOG.
6. **RE tooling security contract — carried SEC-1 posture rules confirmed**
   (hygiene.yml: `contents: read`, SHA-pinned actions, timeouts, no
   `pull_request_target`; verified lines 17-87), **plus what must be ADDED so
   §7.2/§7.3 are mechanical:** (a) repo-tree binary assertion per LEGAL-2;
   (b) synthetic-only unit fixtures — fixture bytes generated in code, zero
   committed binaries (the assertion is the enforcement); (c) the
   differential tool REFUSES pairs lacking a provenance-manifest entry
   declaring owner authorship (§7.1 made friction-y and checkable —
   reviewable in the tool's tests at the exit gate); (d) the backup hex guard
   widened from 64- to ≥32-hex **on the RE-adjacent paths only**
   (`docs/formats/`, `tools/re/`, the fixture path) with a UUID/known-hash
   allow-list — closes the 16-byte-key gap in `sandbox_backup.sh:92`; (e) a
   `docs/formats/*.md` lint: provenance field present, no hex runs ≥32; (f)
   gitleaks stays the token-shaped backstop and is *not* relied on for crypto
   material — hence (d)/(e).

## What is sound

The clean-room line is honored across the whole tree and all five Stage-3
commits: TXF per published spec (unprotectable field codes), `.tax` inspection
without decryption or key material (code + tests + tree/history scans),
IRS-pinned fixtures quoting only §105 public-domain government works, and an
original unified format. Key-material ban: zero AES code, zero hex blobs,
zero history hits. GPL-3.0-only posture is complete and honest (canonical
LICENSE, 70+ SPDX headers, shadcn MIT correctly vendored+attributed, GPL §6
release line in the template). Disclaimers are prominent in-app, in README,
and on the release body; privacy copy matches actual transmission behaviour
on every path in both codebases (verified by the 111-test run incl. the
privacy contract, plus code reads of both AI cascades); no telemetry exists.
The RE protocol's §2 legal framing (research-vs-distribution, §1201(f),
*Altai* filtration) and §7 guardrails remain correctly stated and were
verified against the code that shipped. Harness memory is internally
consistent (harness_check 0 failures).

## Verdict

**PROCEED-WITH-CONDITIONS** — Stage 3 is formally CLOSED; Stage 2 (RE
tooling) may enter only with these applied before or during the stage:

1. **ADR-012 recorded in-repo** with the six binding mechanics of Agenda
   answer 4 (a)–(f) — otherwise the placement reverts to a separate research
   repo (checkable: the ADR exists in DECISIONS.md; the fixture path is
   gitignored; the binary assertion + backup allow-list are live).
2. **DoD recorded before entry**: N = 6 specs / two working sessions,
   safest-first ordering per Agenda answer 5 (checkable at the exit gate by
   counting `docs/formats/*.md` and SESSION_LOG sessions).
3. **The LEGAL-1 mechanics land with the first tooling commit**: repo-tree
   binary assertion (allow-listed assets), synthetic-only fixtures,
   provenance-manifest refusal in the differential tool, ≥32-hex guard +
   spec lint on RE-adjacent paths (checkable: hygiene.yml job +
   `sandbox_backup.sh` diff + the tool's refusal tests).
4. **The native re-platforming settlement is recorded before any
   native-stack code lands**, including the licensing annex of Agenda answer
   3 — GPL-3.0-only Rust core, Qt only under GPL-3.0 terms or Slint/gtk
   preferred, KMP Android-only, cargo-deny license check, per-platform
   LICENSES manifest at each platform's first tagged release (checkable: the
   settlement ADR + annex exists in DECISIONS.md; CI carries the license
   check when the core lands).
5. **The web-freeze/parity disposition is RECORDED at this gate** — owner
   ratification of the recommended maintenance-freeze, or continued parity
   with a re-armed two-session box; not by silence (checkable: the decision
   appears in CONSENSUS.md/DECISIONS.md).
