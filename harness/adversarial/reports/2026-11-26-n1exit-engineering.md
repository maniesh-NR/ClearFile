# ADV-ENG — N1 exit gate (2026-11-26, Task N1-EXIT-gate-ENG)

VERDICT: PROCEED-WITH-CONDITIONS

Scope: the N1 session-2 delta `4a55caf..138e93b` (the annex-(a) differential/property
harness, the annex-(b) ported bridge suites, the `core/src/{json,envelope,txf,tax_inspect}.rs`
codecs). Independently re-verified: `cargo test --locked` = **159/159 green**
(15 lib + 3 differential + 6 composition + 2 manifest + 42 fixtures + 7 property +
25 return_format + 37 tax_inspect + 22 txf; re-run in a fresh
`CARGO_TARGET_DIR=/tmp/gate-eng`), and the differential corpus **independently
regenerated twice in a sandbox copy** (the tracked generator + a copied `clearfile/`
tree) — byte-identical to the committed file both times
(`sha256 a15ac79cc5cb80c2dabd85a51fd0c964b9cecc72a10f45de7715fb53828d9947`,
== the digest recorded in `fixtures/differential/README.md:35`).

## Conditions

1. **The "byte-identical to BOTH reference emitters" number-emission claim is
   false for the Dart side and must be rescoped.** `core/src/json.rs:16-19`
   ("Dart's `double.toString` is documented to match ECMAScript
   `Number#toString`" — implying byte-identical output) and
   `core/src/envelope.rs:833-836` ("byte-identical to Dart's
   `JsonEncoder.withIndent('  ')` and V8's `JSON.stringify(x, null, 2)`") are
   wrong on integral doubles: Dart's JSON encoder emits `80000.0` (verified
   live with the repo's own SDK: `jsonEncode(<dynamic>[80000.0])` →
   `[80000.0]`; the committed corpus itself carries `"wages": 80000.0,` at
   `fixtures/differential/cases.json:30679`), while the core's
   `write_number(80000.0)` emits `80000` (V8-style, `core/src/json.rs:336-340`).
   The two *references* diverge from each other there; the core matches V8, not
   Dart. No functional harm (both readers parse both forms), but in this repo
   byte-shape claims are contract wording. *Fix:* rescope both doc comments to
   "byte-identical to the V8/TS writer; the Dart writer appends `.0` on integral
   doubles — a parse-compatible divergence between the references themselves"
   (an ADR-017 annex-(c) one-liner if a divergence entry is preferred).
   *Verification:* run `dart -e 'import "dart:convert"; void main(){ print(jsonEncode(<dynamic>[80000.0])); }'`
   → `80000.0` ≠ the core's `write_number(80000.0)` == `"80000"`; after the fix,
   neither file claims Dart byte-identity for number emission.
2. **The ported exporter test drops the mjs's D-date header assertion — the
   `MM/DD` zero-padding on the export path is unpinned.** The mjs reference
   asserts the D-line shape (`assert.match(lines[2], /^D \d{2}\/\d{2}\/\d{4}$/)`,
   `scripts/txf_taxfile_test.mjs:110`); the port
   (`core/tests/txf_port.rs:122-129`,
   `mjs_txf_exporter_verified_against_spec_v042_structure`) asserts `lines[0]`,
   `lines[1]`, `lines[3]` but never `lines[2]`, and no other test pins it —
   `export_txf`'s `format!("D {:02}/{:02}/{}", …)` (`core/src/txf.rs:790`) could
   regress to `{}` and stay green. *Fix:* add
   `assert_eq!(lines[2], "D 03/16/2026");` (the port passes explicit date parts,
   so the line is fully deterministic). *Verification:* change `{:02}` to `{}`
   in `core/src/txf.rs:790` and `cargo test --locked txf_port` goes red.
3. **The txf port's module docs understate the ported coverage: "11 tests" vs
   the actual 12.** `core/tests/txf_port.rs:6` and `:187` say
   "`clearfile/test/txf_import_test.dart`, 11 tests … ported 1:1", but the
   reference file has **12** `test(` blocks
   (`grep -c "test('" clearfile/test/txf_import_test.dart` → 12; enumerated at
   `txf_import_test.dart:12,170,177,184,196,205,213,221,228,233,239,249`) and
   the port ports **all 12** (`dart_canonical_v042…` …
   `dart_empty_file_edge_no_records_at_all_throws`). Coverage is a superset of
   the claim, but the repo's ledger discipline is "the honest count"
   (harness_check enforces it for README rows). *Fix:* `11` → `12` in both
   doc-comment spots. *Verification:* `grep -c "test('"
   clearfile/test/txf_import_test.dart` == 12 == the count of `dart_`-prefixed
   importer tests in `core/tests/txf_port.rs`, and both doc lines say 12.

## Risks register

- **Generator-vs-golden call path (probed, sound).** The generator's expected
  values really come from the reference call path: `expectedFor` runs
  `const TaxCalculator().compute(TaxReturnData.fromJson(input))`
  (`scripts/generate_differential_cases.dart:250-252`) — exactly
  `clearfile/test/golden_fixtures_test.dart:120-122`'s path, and the module
  docs/README pin that provenance (`fixtures/differential/README.md:22`).
  Parameters are read at runtime from `TaxYearParameters.ty2025` (generator
  line 83), never hardcoded; self-checks refuse non-finite values, duplicate
  ids, key-set drift, non-`standard`/`itemized` methods, and dead fold-order
  dust constants (generator `selfCheck`, lines 1221-1289).
- **Tolerance-0.0 honesty (probed, sound).** Both engines are binary64 with the
  operation order preserved (`core/src/engine.rs:10-36`, traps 1-4; the
  corpus's `"totalPayments": 93131.03000000001` is live evidence float dust is
  pinned, not smoothed). Dart emits shortest-round-trip decimal strings
  (`JsonEncoder` → `double.toString()`), and the consumer parses with Rust's
  correctly-rounded `str::parse::<f64>()` (`core/tests/harness/mod.rs:371-374`),
  whose inversion of a shortest-round-trip string is exact — so 0.0 is the
  honest tolerance, not an over-tight one. Fail-closed shape `!(delta <= 0.0)`
  (`core/tests/differential_harness.rs:96-104`) matches the golden runner's
  rule-5 semantics with the tolerance pinned to zero; `deductionMethodUsed`
  exact-string, `qualifyingChildren` integral-checked, the 26-key D31c set
  asserted as exact set-equality per case (lines 161-192). What would break it:
  a Dart-side engine/op-order change or a Rust-side op-order change — both of
  which the committed corpus then fails loudly.
- **Dart-SDK supply-chain on the corpus (accepted, bounded).** A future Dart
  changing `double.toString()`/`JsonEncoder` number formatting would make
  regeneration byte-differ from the committed corpus — caught by the README's
  digest comparison at *regeneration* time only; neither `harness_check.sh` nor
  CI re-derives the digest (see advisories). The committed corpus keeps the
  Rust-side contract independent of any SDK change, so the runtime dependency
  is nil; only the regeneration check can drift. The corpus is also
  strictly-schema-consumed (`parse_input` → `check_schema`,
  `core/tests/harness/mod.rs:587-589`), so generator schema drift fails loudly
  in `cargo test`.
- **Property-grid self-reference (mitigated).** The monotonicity/continuity
  grid derives bracket boundaries from the Rust table
  (`core/tests/property_harness.rs:171-182`) — a mistranscribed table would
  probe its own wrong boundaries; mitigated because the corpus's edge-2 group
  derives boundaries from the *Dart* parameter tables at generation time and
  pins expected values, so a transcription error fails the differential run.
  The continuity check is genuinely tight where it matters (±$0.01 probes at
  every rung → allowed jump $0.0037) and the 2,500-step grid enforces the
  0.37-Lipschitz bound elsewhere; a slab-overlap/missing-slab bug of any
  realistic size cannot slip through both.
- **Payload-seam semantics shift (recorded, tested).** `clearfile_container`
  means "shape present" in the core vs "inline decode succeeded" in the
  references (`core/src/tax_inspect.rs:29-45`, divergences 1-2). The fall-through
  (decode failure → warning `clearfile.json could not be parsed: <reason>` →
  Intuit-shape/plain-ZIP summary re-derivation) is faithfully composed in
  `import_tax_container` (`core/src/tax_inspect.rs:869-904`) and pinned by
  `composition_falls_through…` and
  `composition_fall_through_still_detects_the_intuit_shape`
  (`core/tests/exchange_composition.rs:121-165`). The risk is only for a
  hypothetical third-party FFI consumer of `analyze_tax_file` alone — the
  recorded ADR-017 surface is the composition, and the merged-warning order
  (`[...warnings, ...decoded.warnings]`, dart:157) is pinned verbatim by the
  v1-fixture composition test (`exchange_composition.rs:88-119`).
- **Reference-vs-reference divergences the port must arbitrate (all resolved
  toward Dart-canonical and documented).** v1 dependent counts: Dart
  `readInt`→`toInt()` truncates, TS `Math.round` rounds
  (`clearfile/lib/models/json_codec.dart:20` vs `src/lib/files/cfr.ts:106-107`;
  the port truncates, `core/src/envelope.rs:408-410`); entropy-field `Some`
  semantics (Dart canonical, divergence 5); ENG-1 name guard and local-header
  signature check kept as the stricter Dart behavior (divergences 6-7); the
  TS-only legacy-flat metadata warning and the `filingStatus ?? status`
  fallback are web-only and absent from the port, per the Dart-canonical rule.
  The v1 migration warning strings themselves are verbatim on all six
  (checked against `return_format.dart:156,161-163,175-177,192-194,209-211,238-241`
  and `cfr.ts:78,84,98,113,163,168`).
- **The in-session year-tail bug class (verified fixed, no sibling found).**
  `core/src/txf.rs:386-388` takes the last-4 characters and re-reverses them
  into order — correct (the `6202`-for-`2026` reversal is gone), and pinned by
  the ported canonical test (`core/tests/txf_port.rs:259`,
  `warnings[0].contains("2026")`). Sibling sweep: the only other tail-extraction
  in the new code is the ZIP EOCD tail scan
  (`core/src/tax_inspect.rs:480-495`), whose direction is correct
  (downward-from-the-tail) and whose decoy case is pinned
  (`battery_decoy_eocd_after_real_one_wins_the_tail_scan`,
  `core/tests/tax_inspect_port.rs:911-932`); `json.rs` has no tail slicing; the
  envelope's date handling is whole-text. No sibling of the reversed-tail class.

## Non-binding advisories

1. **Property 1 is structurally self-referential.** Its fold check compares
   `r.total_income` (bitwise) against `TaxReturnInput::total_income()` — the
   very method the engine calls (`core/src/engine.rs:179`), so it cannot fail
   unless the engine stops calling the method. The real cross-engine pin is the
   corpus (300 random cases + the edge-14 fold-order twins, Dart-derived).
   Consider an independent inline fold in the test, or a doc-comment note that
   the property is a structural pin with the corpus as the spec.
2. **The third differential test is redundant.**
   `differential_strict_reader_accepts_every_generated_input`
   (`core/tests/differential_harness.rs:206-211`) asserts non-emptiness of a
   corpus that `load_corpus` has already strictly parsed (both other tests call
   the same loader). Harmless; its name promises more than its body.
3. **`harness_check.sh`'s corpus ledger could close the content-integrity loop.**
   The new family (scripts/harness_check.sh, session-2 diff) checks manifest
   self-consistency (caseCount == array, kind, generator name, ≥ 500 cases) —
   a corpus regenerated with drifted parameters or hand-edited consistently
   would still pass. Adding `sha256sum` == the README's recorded digest
   (`a15ac79c…d9947`) makes the family a mechanical tripwire for both the Dart
   SDK's emission behavior and manual edits. Likewise `N1S2_FILES` counts
   file *presence* only (`ls | wc -l`) — an emptied file would pass (the cargo
   suite is the real backstop there).
4. **Wire the corpus regeneration check into CI someday.** The Dart SDK is
   already vendored (`tools/flutter/bin/cache/dart-sdk/bin/dart`); a CI step
   regenerating to a temp dir and comparing digests converts the README's
   manual check into a standing supply-chain tripwire.
5. **The `dart_non_v042_version_and_off_year_export_date_produce_notes` port is
   faithfully weak.** The Dart reference's own test
   (`clearfile/test/txf_import_test.dart:205-211`) never asserts the off-year
   date note (its fixture has no `D` line), and the port copies that weakness —
   the behavior is pinned elsewhere (canonical test, line 259), but a one-line
   strengthening in the port would have been free.
6. **The "verify, don't discard" disposition is sound, with two cheap
   hardenings.** Integrating complete-but-unverified subagent work after
   orchestrator review was the right call — the evidence it worked is that the
   review *caught* a real bug (the reversed year tail) and the post-integration
   full-suite re-run was green (159/159, re-verified here). The residual risk is
   that a timed-out lane's product is only statically reviewed before the
   whole-suite run; next time: (a) record a per-lane integration checklist
   (reviewer, compile, suite-green) the way harness_check records file
   presence, and (b) instruct long lanes to checkpoint work products to disk
   early so a context deadline loses less — three of five lanes hit the
   deadline, which says the lane budget estimate, not the disposition, was the
   weak link.
7. **v1-migration non-integer dependent counts are unpinned across the
   reference divergence.** `qualifyingChildren: 3.7` truncates to 3 in
   Dart/`readInt` and the port, rounds to 4 in TS; the shared D34 edge fixture
   pins the clamp only at integer values. If a v1 file ever carries a
   fractional count, the two engines will legitimately disagree — worth a line
   in the envelope module's divergence list.

## Files read (citations)

- Delta/verification: git log `4a55caf..138e93b` + diffstat; `cargo test --locked`
  (fresh target dir, 159/159); live Dart emission probe (`jsonEncode(80000.0)`);
  sandbox regeneration of `fixtures/differential/cases.json` (×2, digest equal).
- Corpus + generator: `scripts/generate_differential_cases.dart` (all 1359
  lines), `fixtures/differential/README.md`,
  `fixtures/differential/cases.json` (sampled: lines 30679, 1073).
- Differential consumer + shared harness: `core/tests/differential_harness.rs`
  (all), `core/tests/harness/mod.rs` (parser 76-380, `parse_input`/schema
  560-656, comparator docs 1-66).
- Property harness: `core/tests/property_harness.rs` (all 408 lines).
- Core: `core/src/lib.rs` (all), `core/src/engine.rs` (all), `core/src/txf.rs`
  (all 941), `core/src/tax_inspect.rs` (all 905), `core/src/envelope.rs`
  (1-120, 394-455, 740-1171), `core/src/json.rs` (1-60, 115-120, 225-260,
  300-429, 713-889) + purity grep over `core/src` (zero fs/env/io hits).
- References: `clearfile/test/golden_fixtures_test.dart` (all),
  `clearfile/lib/io/return_format.dart` (all 307), `src/lib/files/cfr.ts`
  (40-170), `clearfile/lib/io/txf_import.dart` (all 366),
  `clearfile/lib/util/money.dart` (all), `src/lib/files/txf.ts` (all 84),
  `clearfile/lib/io/tax_inspect.dart` (all 319),
  `clearfile/lib/models/json_codec.dart` (all).
- Suites/mapping: `clearfile/test/return_format_test.dart` (test list),
  `clearfile/test/txf_import_test.dart` (all 253), `clearfile/test/money_parse_test.dart`
  (test list), `clearfile/test/tax_inspect_test.dart` (test list),
  `scripts/txf_taxfile_test.mjs` (1-165 + group log lines 145-365),
  `core/tests/return_format_port.rs` (1-260 + test list 141-997),
  `core/tests/txf_port.rs` (1-501), `core/tests/tax_inspect_port.rs`
  (286-505, 878-937 + test list), `core/tests/exchange_composition.rs` (all 194).
- Ledger: `scripts/harness_check.sh` (session-2 diff hunk).

## Ported-suite mapping (mandate item 4 — enumerated)

- `return_format_test.dart` 15/15 → `return_format_port.rs`
  (`envelope_round_trip…` … `store_legacy_flat_files_migrated…`) + 5 `cfr_` mjs
  groups + 5 port extensions = 25. **No reference test unported.**
- `txf_import_test.dart` 12/12 → `txf_port.rs` `dart_canonical…` …
  `dart_empty_file_edge…`; `money_parse_test.dart` 5/5 → `dart_money_*`;
  mjs `[txf]` 2/2 → `mjs_txf_*`; 3 `port_extension_*` = 22. **No reference
  test unported.** (The "11" in the docs is the count slip — condition 3.)
- `tax_inspect_test.dart` 10/10 → `dart_suite_*`; mjs `[tax]` 4/4 →
  `bridge_tax_*`; + writer/battery/CRC extensions = 37. **No reference test
  unported.**
- mjs `[cfr]` 5/5 → `cfr_*` in return_format_port; composition 6 tests cover
  the seam. All 11 mjs groups have named ported counterparts.
