# ADV-LEGAL — N1 exit gate (2026-11-26, Task N1-EXIT-gate-LEGAL)

VERDICT: PROCEED-WITH-CONDITIONS (1 condition)

**Verification log (files/lines actually read).** The authoritative delta
(`git diff --name-status 4a55caf..138e93b`): 13 added / 9 modified, 22 files
— `core/src/{json,envelope,txf,tax_inspect}.rs`, `core/src/lib.rs` (M,
plumbing only), 6 `core/tests/*.rs`, `fixtures/differential/{README.md,cases.json}`,
`scripts/generate_differential_cases.dart`, `scripts/harness_check.sh` (M),
`scripts/sandbox_backup.sh` (M), `README.md` (M), `PROJECT_MEMORY.md` (M),
4 `harness/memory/*.md` (M) — **PROD-5 verified: zero `clearfile/` or `src/`
paths**. Read: `core/src/json.rs:1–100,328–351`; `core/src/envelope.rs:1–96`
+ verbatim-warning hits (1014/1038/1057); `core/src/txf.rs:1–120,830–941`
(the `ecma_to_fixed_2`/`ecma_number_to_string` implementations);
`core/src/tax_inspect.rs:1–209,674–678,714` (`TAX_CONTAINER_README`,
`INTUIT_MODERN_SUMMARY`, `crc32`); `core/src/lib.rs` diff; the six test-file
headers (`core/tests/{differential_harness,property_harness,exchange_composition,return_format_port,tax_inspect_port,txf_port}.rs:1–30`);
`scripts/generate_differential_cases.dart:1–120` + full import scan;
`fixtures/differential/README.md` (whole, 132 lines); `fixtures/differential/cases.json`
(schema/note/class fields); convention baselines `fixtures/tax/*.json`,
`fixtures/ai/README.md`, `fixtures/migration/README.md`, all 59 tracked `.md`
and all 37 tracked `.json` headers (SPDX survey: **0/59 md, 0/37 json** carry
headers — the data/doc no-header convention is uniform); `THIRD-PARTY-NOTICES.md`
(whole); `hygiene.yml:107–123` + `core/Cargo.toml` + `core/Cargo.lock`;
`sandbox_backup.sh:104–150`; `harness_check.sh` delta; `README.md` delta;
`DEBT.md`/`ROADMAP.md`/`STATE.md`/`SESSION_LOG.md` deltas; cited-source
spot-checks `src/lib/files/{txf,taxfile,cfr}.ts` + `clearfile/lib/io/{return_format,txf_import,tax_inspect}.dart`
+ `clearfile/lib/util/money.dart` (SPDX on every cited source; cited line
counts exact: 306/366/319/389/84, `money.dart:21–27`); `docs/formats/txf.md:1–40`
(provenance §7.1: a published public spec, zero third-party samples);
`.gitignore` (`/tools/`, `/core/target/`). **Live verifications run:** sha256
of `cases.json` == the README digest `a15ac79c…828d9947` ✓; python
byte-comparison `TAX_CONTAINER_README` TS↔Rust **byte-identical** ✓; corpus
audit: 550 = 300 random + 246 edge + 4 edge-d31b, one uniform input key-order
(== golden-fixture input order), one uniform 26-key expected order, 10
negative-input cases, all values finite ✓; migration warnings byte-identical
to Dart `_migrateWebV1` ✓; hex-constant scan of `core/src` (only public
CRC-32/ISO-HDLC constants + the 66,000/4096/128 caps — **no key material,
no decryptor**) ✓; `cargo test --locked` → **159 passed / 0 failed / 0
ignored** (15+3+6+2+42+7+25+37+22) ✓; `harness_check.sh` → **21 oks, 0
failures** ✓; `git ls-tree 138e93b` → no `clearfile/tool/` at the tip (the
recorded relocation was in-session, pre-commit) ✓.

**Findings on the mandate's seven probes.** (1) SPDX: all 11 new code files
carry `GPL-3.0-only` headers; `cases.json` + the corpus README follow the
repo's uniform lockfile/data-doc convention (Cargo.lock and every fixture
JSON/README carry none; licensing lives in `LICENSE` +
`THIRD-PARTY-NOTICES.md`) — no deviation. (2) Provenance: every citation
audited points at first-party GPL-3.0-only sources with exact line counts;
`toFixed(2)` is an **original Rust implementation of the ECMA-262 spec
algorithm** (steps 1–2/6 named, own u128 dyadic arithmetic — no V8 source);
`json.rs` implements the RFC 8259 grammar and delegates number emission to
Rust std (no serde/ryu/Grisu source copied); CRC32 is the project's own TS
code + the public ISO-HDLC test vector `0xCBF43926`; the only external
prose quoted anywhere in the delta is a 4-word TXF-spec phrase ("may be
safely ignored") — de minimis. Nothing third-party is copied. (3) Corpus:
inputs are purely synthetic (own xorshift64*, TY2025 thresholds read at
runtime from the project's `tax_year.dart`); expected values from the
project's own engine; **zero TurboTax-derived material in the corpus or
core/** — the Intuit container is recognized at shape level only (functional
facts; *Altai* filtration), no key material, no decryptor, per the ADR-017
boundary. (4) The corpus README states the differential contract honestly
and prominently (a dedicated "The contract (NOT golden fixtures)" section;
the annex-(d) distinction restated in `cases.json`'s own `note` field and in
the consumer's header — triple disclosure), and its verifiable claims
(digest, counts, key orders, finiteness) all check out live. (5) The
"NOT the Intuit format" owner text is byte-identical to `taxfile.ts:367–382`;
the root README's disclaimer surface is untouched by construction (PROD-5).
(6) `THIRD-PARTY-NOTICES.md` stays accurate: zero-dependency posture
fail-closed in CI (Cargo.lock = exactly the root package; no
`[dependencies]` section; the cargo-deny upgrade trigger recorded in
hygiene.yml + Cargo.toml + the session records); toolchains (Dart SDK,
pinned Rust) unconveyed under gitignored `/tools/` — no notice obligation;
the delta introduces no third-party material, so no new obligation arises.
(7) The backup allow-list third instance follows the recorded-instance
pattern: excludes in both scan branches + the recorded comment naming it
"the third recorded known-hash instance" + the digest verified against the
live file.

## Conditions (checkable)

1. **Root-README corpus-row precision (claim accuracy).** The new
   `fixtures/differential/` row in `README.md` says "550 deterministic
   seeded cases (300 random + 250 edge)" — an aggregation that erases the
   deliberately-marked `edge-d31b` class; the authoritative taxonomy (the
   corpus README's class table, `DEBT.md`'s D43 close-out, `SESSION_LOG.md`,
   and the commit message) is **300 random + 246 edge + 4 edge-d31b**. The
   claim is arithmetically true as an edge-family sum and the precise split
   is one hop away, but the README is the public claim surface and the
   D31b-zone pin is a governance-relevant distinction; align the row with
   the taxonomy. *Check:* the `README.md` `fixtures/differential/` row reads
   "300 random + 246 edge + 4 edge-d31b" (or equivalent naming the
   `edge-d31b` class explicitly) and still totals 550.

## Risks register

(a) **Taxonomy drift** (the condition): the aggregated "250 edge" could be
cited later as authority for a class count the corpus's own taxonomy
contradicts — small, cheap to close now. (b) **Implicit corpus license
status**: `cases.json` and the corpus README carry no per-file license line
(convention-consistent); an out-of-tree reuser who extracts the corpus alone
sees only the `note` field's provenance statement — mitigated by the tree
`LICENSE`/`THIRD-PARTY-NOTICES.md`, and the ADR-017 annex already mandates a
per-platform LICENSES manifest at each platform's first tagged release
(which is also where the Rust-std Apache-2.0/MIT attribution should be
carried). (c) **cargo-deny deferral risk**: the upgrade trigger ("in the
same commit as the first external dependency") is recorded in three places
and enforced by the fail-closed lockfile assertion — a dependency cannot
land silently; low risk. (d) **Spec-algorithm creep**: the ECMA-262/RFC
8259/TXF-spec baselines are public standards and the implementations are
original; keep future ports quoting spec prose at de-minimis length only.

## Non-binding advisories

1. Add the "allow-list active" echo line for the third recorded instance in
   `sandbox_backup.sh` (parity with the corpus-manifest and toolchain-pin
   instances) — observability only; both excludes and the recorded comment
   are already in place.
2. Consider a one-line license-status sentence in
   `fixtures/differential/README.md` (e.g., "first-party data, GPL-3.0-only
   via the repository LICENSE; no per-file header per the repo data-file
   convention") — would make the corpus self-contained without breaking the
   uniform fixture-README convention (do the sibling READMEs at the same
   time if at all).
3. Immaterial record nit: `SESSION_LOG.md` says the generator is "1,357
   lines"; the file is 1,358 — fix at the next memory sync if touched anyway.
4. The verified-digest allow-list entry protects an honest, independently
   checkable value — keep the digest-in-README pattern for any future
   generated corpus; it is exactly what made this review's provenance audit
   cheap.

**Summary:** The N1 session-2 delta is license-clean end-to-end: every new
code file SPDX'd, every port traced to first-party GPL-3.0-only sources with
exact citations, all external algorithm baselines are public specs
implemented (not copied), the corpus is purely synthetic with zero
TurboTax-derived material entering `core/`, the honesty texts are
byte-identical and the disclaimers untouched, and the licensing annex's
zero-dependency discharge is fail-closed and live-verified (159/159 tests,
21/0 harness checks, digest match). One low-severity condition: align the
root README's corpus row with the precise 300+246+4 taxonomy.
