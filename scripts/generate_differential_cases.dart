// SPDX-License-Identifier: GPL-3.0-only

/// Differential/property case generator for the ADR-017 verification annex
/// (a) / debt D43 mechanism: a Dart-side random + edge input generator that
/// emits JSON cases consumed later by `cargo test` against the Rust core,
/// with expected values computed IN-PROCESS by the Dart reference engine
/// (clearfile/lib/tax/calculator.dart) — the exact same call path the golden
/// fixture suite uses (`TaxReturnData.fromJson(input)` +
/// `const TaxCalculator().compute(...)`), so the differential exercises the
/// reference engine, never a reimplementation.
///
/// These are NOT golden fixtures. The annex (d) authoring discipline (never
/// derive an expected value by running any engine) applies to
/// fixtures/tax/; this file is the annex (a) Rust-vs-Dart *differential*
/// contract, where the Dart reference IS the expectation by design.
/// Numeric semantics: exact binary64 parity, tolerance 0.0.
///
/// Expected blocks carry exactly the 26 three-runner-derivable keys (D31c);
/// `marginalRate` is deliberately NEVER emitted.
///
/// Determinism
/// -----------
/// Byte-identical output on every run:
///  * no timestamps, no environment reads, no `dart:math` `Random`;
///  * all map literals are ordered (Dart map insertion order = emission
///    order), so the JSON key order is fixed;
///  * every value derives from one private PRNG (below) seeded with the
///    constant [seed], or from the TY2025 parameter tables read at runtime
///    from clearfile/lib/models/tax_year.dart (edge cases never hardcode a
///    parameter);
///  * money values are cent-rounded (`(v * 100).round() / 100`) so the
///    emitted JSON stays human-auditable.
///
/// RNG: xorshift64* (Marsaglia). 64-bit state interpreted as UNSIGNED.
/// On the Dart VM, `int` is 64-bit two's-complement, `<<` and `*` wrap
/// modulo 2^64 (bits shifted/carried out of the 64-bit word are discarded),
/// and `>>>` is the unsigned right shift, so all steps below run with exact
/// unsigned semantics. (This tool is a plain VM script and is never
/// compiled to JS/web, where int semantics differ.) Per step:
///     x ^= x >>> 12;  x ^= x << 25;  x ^= x >>> 27;
///     return x * 0x2545F4914F6CDD1D;
/// The state is advanced once per call; state 0 (a fixed point) is remapped
/// to a nonzero constant. Uniform doubles take the top 53 bits of the raw
/// output divided by 2^53 (exact in binary64).
///
/// Run (from scripts/):
///     ../tools/flutter/bin/cache/dart-sdk/bin/dart \
///         generate_differential_cases.dart
/// Output: <repo>/fixtures/differential/cases.json
library;

import 'dart:convert';
import 'dart:io';

import '../clearfile/lib/models/filing_status.dart';
import '../clearfile/lib/models/tax_return.dart';
import '../clearfile/lib/models/tax_year.dart';
import '../clearfile/lib/tax/calculator.dart';
import '../clearfile/lib/tax/results.dart';

/// Master seed. Change it and every random case changes; never change it
/// casually — the committed cases.json is pinned to this value.
const int seed = 771937021;

/// Number of 'random'-class cases (a few of which carry negative inputs).
const int randomCaseCount = 300;

/// Repository-relative output location (resolved against the script path,
/// so the tool works from any CWD).
const String outputRelativePath = 'fixtures/differential/cases.json';

const String note =
    'Differential cases per ADR-017 verification annex (a) / D43: inputs '
    'generated deterministically; expected values computed in-process by the '
    'Dart reference engine (clearfile/lib/tax/calculator.dart). NOT golden '
    'fixtures — the golden authoring discipline (annex (d)) applies to '
    'fixtures/tax/; these are the Rust-vs-Dart differential contract with '
    'exact binary64 parity (tolerance 0.0). The 26 pinned keys are the '
    'three-runner-derivable set only (D31c).';

/// The single parameter table the edge cases read at runtime — every
/// threshold, cap, and bracket boundary comes from here, never hardcoded.
final TaxYearParameters params = TaxYearParameters.ty2025;

// ---------------------------------------------------------------------------
// PRNG
// ---------------------------------------------------------------------------

class Xorshift64Star {
  static const int _nonzeroFallback = 0x9E3779B97F4A7C15;
  static const double _twoPow53 = 9007199254740992.0;

  int _x;

  Xorshift64Star(int seedValue)
      : _x = seedValue.toUnsigned(64) == 0
            ? _nonzeroFallback
            : seedValue.toUnsigned(64);

  /// Raw 64-bit step (wrapping `<<`/`*` on the VM = unsigned semantics).
  int nextUint64() {
    var x = _x;
    x ^= x >>> 12;
    x ^= x << 25;
    x ^= x >>> 27;
    _x = x;
    return x * 0x2545F4914F6CDD1D;
  }

  /// Uniform in [0, 1) with full 53-bit precision (exact division by 2^53).
  double nextUnit() => (nextUint64() >>> 11) / _twoPow53;

  /// True with probability [p].
  bool chance(double p) => nextUnit() < p;

  /// Uniform integer in [0, n) via rejection sampling (no modulo bias).
  int nextInt(int n) {
    final limit = 9007199254740992 - (9007199254740992 % n);
    while (true) {
      final v = nextUint64() >>> 11;
      if (v < limit) return v % n;
    }
  }

  /// Uniform double in [lo, hi).
  double uniform(double lo, double hi) => lo + nextUnit() * (hi - lo);

  /// Cent-rounded money value drawn from [lo, hi) — always finite.
  double centsBetween(double lo, double hi) =>
      (uniform(lo, hi) * 100).round() / 100.0;

  /// Weighted pick (weights need not be normalised).
  T pick<T>(List<T> values, List<double> weights) {
    var total = 0.0;
    for (final w in weights) {
      total += w;
    }
    var u = nextUnit() * total;
    for (var i = 0; i < values.length; i++) {
      u -= weights[i];
      if (u < 0) return values[i];
    }
    return values.last;
  }
}

// ---------------------------------------------------------------------------
// Input builders — key order mirrors the golden fixtures' input blocks
// exactly (see fixtures/tax/00-zero-income.json).
// ---------------------------------------------------------------------------

Map<String, dynamic> w2(String employer, double wages, double withholding) =>
    <String, dynamic>{
      'employer': employer,
      'wages': wages,
      'withholding': withholding,
    };

Map<String, dynamic> dependent(String name, int age, String relationship,
        bool qualifyingChild, bool otherDependentCredit) =>
    <String, dynamic>{
      'name': name,
      'age': age,
      'relationship': relationship,
      'qualifyingChild': qualifyingChild,
      'otherDependentCredit': otherDependentCredit,
    };

Map<String, dynamic> makeInput({
  String filingStatus = 'single',
  bool taxpayer65OrOlder = false,
  bool spouse65OrOlder = false,
  bool taxpayerBlind = false,
  bool spouseBlind = false,
  List<Map<String, dynamic>> w2s = const [],
  double interestIncome = 0,
  double ordinaryDividends = 0,
  double qualifiedDividends = 0,
  double longTermCapitalGains = 0,
  double otherIncome = 0,
  double studentLoanInterest = 0,
  String deductionMethod = 'auto',
  double stateLocalIncomeOrSalesTax = 0,
  double realEstateTax = 0,
  double mortgageInterest = 0,
  double charitableCash = 0,
  double charitableNonCash = 0,
  double estimatedPayments = 0,
  List<Map<String, dynamic>> dependents = const [],
}) =>
    <String, dynamic>{
      'taxYear': 2025,
      'filingStatus': filingStatus,
      'taxpayer65OrOlder': taxpayer65OrOlder,
      'spouse65OrOlder': spouse65OrOlder,
      'taxpayerBlind': taxpayerBlind,
      'spouseBlind': spouseBlind,
      'w2s': w2s,
      'interestIncome': interestIncome,
      'ordinaryDividends': ordinaryDividends,
      'qualifiedDividends': qualifiedDividends,
      'longTermCapitalGains': longTermCapitalGains,
      'otherIncome': otherIncome,
      'studentLoanInterest': studentLoanInterest,
      'deductionMethod': deductionMethod,
      'stateLocalIncomeOrSalesTax': stateLocalIncomeOrSalesTax,
      'realEstateTax': realEstateTax,
      'mortgageInterest': mortgageInterest,
      'charitableCash': charitableCash,
      'charitableNonCash': charitableNonCash,
      'estimatedPayments': estimatedPayments,
      'dependents': dependents,
    };

// ---------------------------------------------------------------------------
// Case record + expected mapping (exactly the 26 pinned keys, D31c)
// ---------------------------------------------------------------------------

const List<String> expectedKeys = <String>[
  'totalIncome',
  'studentLoanDeduction',
  'agi',
  'basicStandardDeduction',
  'additionalStandardDeduction',
  'seniorDeduction',
  'standardDeductionTotal',
  'saltPaid',
  'saltCap',
  'saltAllowed',
  'itemizedDeductionTotal',
  'deductionMethodUsed',
  'deductionUsed',
  'taxableIncome',
  'ordinaryTax',
  'preferentialIncome',
  'preferentialTax',
  'niit',
  'nonRefundableCredits',
  'refundableCredits',
  'totalTax',
  'totalPayments',
  'refund',
  'amountOwed',
  'effectiveRate',
  'qualifyingChildren',
];

/// The ONLY expected-value source: run the reference engine in-process over
/// the input map, exactly as clearfile/test/golden_fixtures_test.dart does.
Map<String, Object> expectedFor(Map<String, dynamic> input) {
  final TaxResult r = const TaxCalculator()
      .compute(TaxReturnData.fromJson(input));
  return <String, Object>{
    'totalIncome': r.totalIncome,
    'studentLoanDeduction': r.studentLoanDeduction,
    'agi': r.agi,
    'basicStandardDeduction': r.basicStandardDeduction,
    'additionalStandardDeduction': r.additionalStandardDeduction,
    'seniorDeduction': r.seniorDeduction,
    'standardDeductionTotal': r.standardDeductionTotal,
    'saltPaid': r.saltPaid,
    'saltCap': r.saltCap,
    'saltAllowed': r.saltAllowed,
    'itemizedDeductionTotal': r.itemizedDeductionTotal,
    'deductionMethodUsed': r.deductionMethodUsed.name,
    'deductionUsed': r.deductionUsed,
    'taxableIncome': r.taxableIncome,
    'ordinaryTax': r.ordinaryTax,
    'preferentialIncome': r.preferentialIncome,
    'preferentialTax': r.preferentialTax,
    'niit': r.niit,
    'nonRefundableCredits': r.nonRefundableCredits,
    'refundableCredits': r.refundableCredits,
    'totalTax': r.totalTax,
    'totalPayments': r.totalPayments,
    'refund': r.refund,
    'amountOwed': r.amountOwed,
    'effectiveRate': r.effectiveRate,
    'qualifyingChildren': r.qualifyingChildren,
  };
}

class DiffCase {
  final String id;
  final String caseClass;
  final Map<String, dynamic> input;
  late final Map<String, Object> expected = expectedFor(input);

  DiffCase(this.id, this.caseClass, this.input);
}

String _slug(FilingStatus s) => s.name.toLowerCase();

String _moneyTag(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

// ---------------------------------------------------------------------------
// Random cases
// ---------------------------------------------------------------------------

/// 300 independently-sampled returns. Every ~31st case (10 total) is a
/// NEGATIVE-input probe (negative otherIncome and/or a negative W-2 wage);
/// the engine's max/min-clamped flow keeps every emitted field finite for
/// them — the self-check verifies it before anything is written.
List<DiffCase> randomCases(Xorshift64Star rng) {
  final cases = <DiffCase>[];
  for (var i = 0; i < randomCaseCount; i++) {
    final negative = i % 31 == 7;
    final status = rng.pick(
      ['single', 'marriedJoint', 'marriedSeparate', 'headOfHousehold',
          'survivingSpouse'],
      [0.27, 0.27, 0.16, 0.175, 0.125], // QSS boosted to ~1/8 (annex exhibit A)
    );
    // ~25% true each; spouse flags are sampled on every status on purpose —
    // on non-marriedJoint statuses the engine must ignore them (hasSpouse).
    final taxpayer65 = rng.chance(0.25);
    final spouse65 = rng.chance(0.25);
    final taxpayerBlind = rng.chance(0.25);
    final spouseBlind = rng.chance(0.25);

    final w2Count = rng.nextInt(5); // 0..4 W-2s
    final w2s = <Map<String, dynamic>>[
      for (var k = 0; k < w2Count; k++)
        w2('W-${k + 1}', rng.centsBetween(0, 450000),
            rng.centsBetween(0, 60000)),
    ];
    var otherIncome = rng.centsBetween(0, 40000);
    if (negative) {
      otherIncome = rng.centsBetween(-40000, -0.01);
      if (w2s.isNotEmpty && rng.chance(0.5)) {
        // Negative wage on one W-2 (a correction scenario) — keep the same
        // employer string, replace the wage with negative cent dust.
        final last = w2s.removeLast();
        w2s.add(w2(
          last['employer'] as String,
          rng.centsBetween(-35000, -0.01),
          last['withholding'] as double,
        ));
      }
    }

    final method = rng.pick(
      ['auto', 'standard', 'itemized'],
      [0.70, 0.15, 0.15],
    );

    final depCount = rng.nextInt(6); // 0..5
    final deps = <Map<String, dynamic>>[];
    for (var j = 0; j < depCount; j++) {
      final roll = rng.nextUnit();
      bool qc;
      bool odc;
      int age;
      String rel;
      if (roll < 0.40) {
        qc = true;
        odc = false;
        age = rng.nextInt(18); // 0..17
        rel = 'child';
      } else if (roll < 0.70) {
        qc = false;
        odc = true;
        age = 18 + rng.nextInt(63); // 18..80
        rel = rng.chance(0.5) ? 'parent' : 'relative';
      } else if (roll < 0.90) {
        qc = false;
        odc = false;
        age = rng.nextInt(81); // 0..80
        rel = 'relative';
      } else {
        // Both flags: kids and ODC counts are independent in the engine.
        qc = true;
        odc = true;
        age = rng.nextInt(18);
        rel = 'child';
      }
      deps.add(dependent('Dep-${j + 1}', age, rel, qc, odc));
    }

    cases.add(DiffCase(
      'rand-${(i + 1).toString().padLeft(3, '0')}',
      'random',
      makeInput(
        filingStatus: status,
        taxpayer65OrOlder: taxpayer65,
        spouse65OrOlder: spouse65,
        taxpayerBlind: taxpayerBlind,
        spouseBlind: spouseBlind,
        w2s: w2s,
        interestIncome: rng.centsBetween(0, 40000),
        ordinaryDividends: rng.centsBetween(0, 120000),
        qualifiedDividends: rng.centsBetween(0, 120000),
        longTermCapitalGains: rng.centsBetween(0, 120000),
        otherIncome: otherIncome,
        studentLoanInterest: rng.centsBetween(0, 3000),
        deductionMethod: method,
        stateLocalIncomeOrSalesTax: rng.centsBetween(0, 15000),
        realEstateTax: rng.centsBetween(0, 15000),
        mortgageInterest: rng.centsBetween(0, 30000),
        charitableCash: rng.centsBetween(0, 10000),
        charitableNonCash: rng.centsBetween(0, 10000),
        estimatedPayments: rng.centsBetween(0, 30000),
        dependents: deps,
      ),
    ));
  }
  return cases;
}

// ---------------------------------------------------------------------------
// Edge groups — every threshold read from params at runtime
// ---------------------------------------------------------------------------

/// 1. All-zero income (fixture-00 semantics) and wages-only at exactly $0.01.
List<DiffCase> edge1ZeroAndPenny() => [
      DiffCase('edge-zero-income', 'edge', makeInput()),
      DiffCase('edge-wages-0.01', 'edge',
          makeInput(w2s: [w2('W-1', 0.01, 0)])),
    ];

/// 2. Taxable income at every ordinary bracket boundary and ±$0.01 for EACH
///    of the 5 statuses (boundary-adjusted gross income = boundary + the
///    status's basic standard deduction, delivered as wages-only income).
List<DiffCase> edge2BracketBoundaries() {
  final cases = <DiffCase>[];
  for (final s in FilingStatus.values) {
    final sd = params.standardDeduction[s]!;
    for (final b in params.ordinaryBrackets[s]!) {
      if (b.upTo == double.infinity) continue; // open top rung: no boundary
      final tag = _moneyTag(b.upTo);
      for (final probe in <(String, double)>[
        ('', 0.0),
        ('-below', -0.01),
        ('-above', 0.01),
      ]) {
        final agi = b.upTo + sd + probe.$2;
        cases.add(DiffCase(
          'edge-bracket-${_slug(s)}-$tag${probe.$1}',
          'edge',
          makeInput(
            filingStatus: s.name,
            w2s: [w2('W-1', agi, 0)],
          ),
        ));
      }
    }
  }
  return cases;
}

/// 3. Itemized total == standard total exactly (auto → standard; the
///    strictly-greater rule) and ±$0.01 around the tie, plus a tie built
///    through the SALT-allowed path.
List<DiffCase> edge3ItemizedTie() {
  final cases = <DiffCase>[];
  for (final name in ['single', 'marriedJoint']) {
    final s = FilingStatus.values.firstWhere((f) => f.name == name);
    final sd = params.standardDeduction[s]!;
    final wages = name == 'single' ? 80000.0 : 120000.0;
    cases.add(DiffCase(
      'edge-itemized-tie-$name',
      'edge',
      makeInput(
        filingStatus: s.name,
        w2s: [w2('W-1', wages, 0)],
        mortgageInterest: sd,
      ),
    ));
    cases.add(DiffCase(
      'edge-itemized-tie-plus-$name',
      'edge',
      makeInput(
        filingStatus: s.name,
        w2s: [w2('W-1', wages, 0)],
        mortgageInterest: sd + 0.01,
      ),
    ));
    cases.add(DiffCase(
      'edge-itemized-tie-minus-$name',
      'edge',
      makeInput(
        filingStatus: s.name,
        w2s: [w2('W-1', wages, 0)],
        mortgageInterest: sd - 0.01,
      ),
    ));
  }
  final singleSd = params.standardDeduction[FilingStatus.single]!;
  cases.add(DiffCase(
    'edge-itemized-tie-salt-single',
    'edge',
    makeInput(
      w2s: [w2('W-1', 80000, 0)],
      stateLocalIncomeOrSalesTax: 10000,
      mortgageInterest: singleSd - 10000,
    ),
  ));
  return cases;
}

/// 4. Forced standard vs forced itemized vs auto on the same money fields
///    (itemized clearly wins: auto must pick itemized, forced standard pins
///    the override).
List<DiffCase> edge4ForcedDeduction() {
  Map<String, dynamic> money(String method) => makeInput(
        w2s: [w2('W-1', 80000, 0)],
        deductionMethod: method,
        stateLocalIncomeOrSalesTax: 5000,
        mortgageInterest: 20000,
      );
  return [
    DiffCase('edge-forced-standard', 'edge', money('standard')),
    DiffCase('edge-forced-itemized', 'edge', money('itemized')),
    DiffCase('edge-forced-auto', 'edge', money('auto')),
  ];
}

/// 5. QSS at several income points + the marriedJoint twin with IDENTICAL
///    money fields (the D33 equivalence zone: QSS maps to the MFJ rate
///    column, standard deduction, QDI caps and NIIT threshold) and the
///    divergence zone (dependents present: QSS uses the $200,000 CTC
///    phase-out start, MFJ the $400,000 one — read from the tables).
List<DiffCase> edge5QssTwins() {
  Map<String, dynamic> money(
    String statusName, {
    required double wages,
    double qualifiedDividends = 0,
    double interestIncome = 0,
    List<Map<String, dynamic>> dependents = const [],
  }) =>
      makeInput(
        filingStatus: statusName,
        w2s: [w2('W-1', wages, 0)],
        interestIncome: interestIncome,
        qualifiedDividends: qualifiedDividends,
        dependents: dependents,
      );

  final twoKids = <Map<String, dynamic>>[
    dependent('Child 1', 4, 'child', true, false),
    dependent('Child 2', 6, 'child', true, false),
  ];
  final cases = <DiffCase>[];
  // Equivalence pairs: no dependents, no SLI (SLI thresholds legitimately
  // differ QSS vs MFJ); the expected blocks must be identical.
  for (final point in <(String, double, double, double)>[
    ('lo', 80000.0, 50000.0, 0.0),
    ('mid', 150000.0, 150000.0, 20000.0),
    ('hi', 600000.0, 0.0, 0.0),
  ]) {
    for (final statusName in ['survivingSpouse', 'marriedJoint']) {
      cases.add(DiffCase(
        'edge-qss-equiv-${point.$1}-${statusName == 'marriedJoint' ? 'mfj' : 'qss'}',
        'edge',
        money(
          statusName,
          wages: point.$2,
          qualifiedDividends: point.$3,
          interestIncome: point.$4,
        ),
      ));
    }
  }
  // Divergence pairs: same money + same two children, statuses differ.
  for (final point in <(String, double)>[
    ('ctc-divergence-partial', 260000.0),
    ('ctc-divergence-zero', 300000.0),
  ]) {
    cases.add(DiffCase(
      'edge-qss-${point.$1}-qss',
      'edge',
      money('survivingSpouse',
          wages: point.$2, qualifiedDividends: 20000, dependents: twoKids),
    ));
    cases.add(DiffCase(
      'edge-qss-${point.$1}-mfj',
      'edge',
      money('marriedJoint',
          wages: point.$2, qualifiedDividends: 20000, dependents: twoKids),
    ));
  }
  return cases;
}

/// 6. Senior (OBBBA) zones: at / inside / above the phase-out, both-65 MFJ
///    boundaries, MFS ineligibility, QSS and HoH.
List<DiffCase> edge6SeniorZones() {
  final per = params.seniorDeductionPerPerson;
  final rate = params.seniorPhaseoutRate;
  final singleStart = params.seniorPhaseoutStart[FilingStatus.single]!;
  final singleZeroCross = singleStart + per / rate;
  final mfjStart = params.seniorPhaseoutStart[FilingStatus.marriedJoint]!;
  final mfjZeroCross = mfjStart + per / rate;
  List<Map<String, dynamic>> kids2 = [
    dependent('Child 1', 4, 'child', true, false),
    dependent('Child 2', 6, 'child', true, false),
  ];
  return [
    DiffCase('edge-senior-single-65-at-start', 'edge',
        makeInput(taxpayer65OrOlder: true, w2s: [w2('W-1', singleStart, 0)])),
    DiffCase('edge-senior-single-65-inside', 'edge',
        makeInput(taxpayer65OrOlder: true, w2s: [w2('W-1', 100000, 0)])),
    DiffCase('edge-senior-single-65-at-zero', 'edge',
        makeInput(
            taxpayer65OrOlder: true,
            w2s: [w2('W-1', singleZeroCross, 0)])),
    DiffCase('edge-senior-single-65-above-zero', 'edge',
        makeInput(
            taxpayer65OrOlder: true,
            w2s: [w2('W-1', singleZeroCross + 0.01, 0)])),
    DiffCase('edge-senior-mfj-both-65-at-start', 'edge',
        makeInput(
            filingStatus: 'marriedJoint',
            taxpayer65OrOlder: true,
            spouse65OrOlder: true,
            w2s: [w2('W-1', mfjStart, 0)])),
    DiffCase('edge-senior-mfj-both-65-inside', 'edge',
        makeInput(
            filingStatus: 'marriedJoint',
            taxpayer65OrOlder: true,
            spouse65OrOlder: true,
            w2s: [w2('W-1', mfjZeroCross - 75000, 0)])),
    DiffCase('edge-senior-mfj-both-65-at-zero', 'edge',
        makeInput(
            filingStatus: 'marriedJoint',
            taxpayer65OrOlder: true,
            spouse65OrOlder: true,
            w2s: [w2('W-1', mfjZeroCross, 0)])),
    DiffCase('edge-senior-mfj-one-65-inside', 'edge',
        makeInput(
            filingStatus: 'marriedJoint',
            taxpayer65OrOlder: true,
            w2s: [w2('W-1', 200000, 0)])),
    DiffCase('edge-senior-mfs-65-ineligible', 'edge',
        makeInput(
            filingStatus: 'marriedSeparate',
            taxpayer65OrOlder: true,
            spouse65OrOlder: true, // hasSpouse false on MFS: flag ignored
            w2s: [w2('W-1', 100000, 0)])),
    DiffCase('edge-senior-qss-65-at-start', 'edge',
        makeInput(
            filingStatus: 'survivingSpouse',
            taxpayer65OrOlder: true,
            spouse65OrOlder: true, // ignored: not a joint return
            w2s: [w2('W-1', mfjStart, 0)],
            dependents: kids2)),
    DiffCase('edge-senior-hoh-65-inside', 'edge',
        makeInput(
            filingStatus: 'headOfHousehold',
            taxpayer65OrOlder: true,
            w2s: [w2('W-1', 100000, 0)])),
  ];
}

/// 7. Blind flags: MFJ both blind (both count) vs single with both flags
///    (only the taxpayer's counts — hasSpouse pins) vs person-semantics
///    (65 + blind is still one person).
List<DiffCase> edge7BlindFlags() {
  final cases = <DiffCase>[];
  void add(String id, String status, bool tp, bool sp) {
    cases.add(DiffCase(
      id,
      'edge',
      makeInput(
        filingStatus: status,
        taxpayerBlind: tp,
        spouseBlind: sp,
        w2s: [w2('W-1', 90000, 0)],
      ),
    ));
  }

  add('edge-blind-mfj-both', 'marriedJoint', true, true);
  add('edge-blind-single-both-flags', 'single', true, true);
  add('edge-blind-single-taxpayer-only', 'single', true, false);
  add('edge-blind-hoh-spouse-only', 'headOfHousehold', false, true);
  add('edge-blind-mfs-both-flags', 'marriedSeparate', true, true);
  cases.add(DiffCase(
    'edge-blind-single-65-and-blind',
    'edge',
    makeInput(
      taxpayer65OrOlder: true,
      taxpayerBlind: true,
      spouseBlind: true,
      w2s: [w2('W-1', 90000, 0)],
    ),
  ));
  return cases;
}

/// 8. CTC phase-out boundaries: agi exactly at / ±$0.01 around the
///    per-status phase-out start, mixed kids+ODC, full phase-out (credits
///    zero), and the last covered $1,000 step boundary (the
///    cents-normalize-before-ceiling trap).
List<DiffCase> edge8CtcPhaseout() {
  final cases = <DiffCase>[];
  const kidsByStatus = [2, 3, 1, 2, 3]; // single..survivingSpouse
  for (final s in FilingStatus.values) {
    final thr = params.ctcPhaseoutStart[s]!;
    final kids = kidsByStatus[s.index];
    final deps = <Map<String, dynamic>>[
      for (var j = 1; j <= kids; j++)
        dependent('Child $j', 2 + j, 'child', true, false),
    ];
    for (final probe in <(String, double)>[
      ('at', 0.0),
      ('minus', -0.01),
      ('plus', 0.01),
    ]) {
      cases.add(DiffCase(
        'edge-ctc-${_slug(s)}-${probe.$1}',
        'edge',
        makeInput(
          filingStatus: s.name,
          w2s: [w2('W-1', thr + probe.$2, 0)],
          dependents: deps,
        ),
      ));
    }
  }
  final mixedDeps = <Map<String, dynamic>>[
    dependent('Child 1', 5, 'child', true, false),
    dependent('Child 2', 8, 'child', true, false),
    dependent('Parent 1', 66, 'parent', false, true),
    dependent('Parent 2', 68, 'parent', false, true),
  ];
  final mfjThr = params.ctcPhaseoutStart[FilingStatus.marriedJoint]!;
  final kids2 = <Map<String, dynamic>>[
    dependent('Child 1', 5, 'child', true, false),
    dependent('Child 2', 8, 'child', true, false),
  ];
  cases
    ..add(DiffCase(
      'edge-ctc-mixed-step-plus',
      'edge',
      makeInput(
        filingStatus: 'marriedJoint',
        w2s: [w2('W-1', mfjThr + 1000.01, 0)],
        dependents: mixedDeps,
      ),
    ))
    ..add(DiffCase(
      'edge-ctc-odc-only-phaseout',
      'edge',
      makeInput(
        filingStatus: 'marriedJoint',
        w2s: [w2('W-1', mfjThr + 10000, 0)],
        dependents: [
          dependent('Parent 1', 66, 'parent', false, true),
          dependent('Parent 2', 68, 'parent', false, true),
          dependent('Relative 1', 40, 'relative', false, true),
        ],
      ),
    ))
    ..add(DiffCase(
      'edge-ctc-full-phaseout-zero',
      'edge',
      makeInput(
        filingStatus: 'marriedJoint',
        w2s: [w2('W-1', mfjThr + 100000, 0)],
        dependents: kids2,
      ),
    ))
    ..add(DiffCase(
      'edge-ctc-full-phaseout-mixed-zero',
      'edge',
      makeInput(
        filingStatus: 'marriedJoint',
        // (2 CTC + 2 ODC gross) / 5% above the threshold, exactly on the
        // step boundary where the combined credit hits zero.
        w2s: [w2('W-1',
            mfjThr + (2 * params.ctcPerChild + 2 * params.odcPerDependent) /
                params.ctcPhaseoutRate, 0)],
        dependents: mixedDeps,
      ),
    ))
    ..add(DiffCase(
      'edge-ctc-step-1000-exact',
      'edge',
      makeInput(
        filingStatus: 'marriedJoint',
        w2s: [w2('W-1', mfjThr + 1000, 0)],
        dependents: kids2,
      ),
    ))
    ..add(DiffCase(
      'edge-ctc-step-1000-below',
      'edge',
      makeInput(
        filingStatus: 'marriedJoint',
        w2s: [w2('W-1', mfjThr + 999.99, 0)],
        dependents: kids2,
      ),
    ))
    ..add(DiffCase(
      'edge-ctc-step-1000-above',
      'edge',
      makeInput(
        filingStatus: 'marriedJoint',
        w2s: [w2('W-1', mfjThr + 1000.01, 0)],
        dependents: kids2,
      ),
    ));
  return cases;
}

/// 9. ACTC refundable zone: earned-income floor boundary, per-child cap
///    binding, earned-income cap binding, partial absorption (D31a zone),
///    and zero earned income.
List<DiffCase> edge9Actc() {
  final kids1 = [dependent('Child 1', 6, 'child', true, false)];
  final kids2 = [
    dependent('Child 1', 6, 'child', true, false),
    dependent('Child 2', 9, 'child', true, false),
  ];
  final kids3 = [
    dependent('Child 1', 6, 'child', true, false),
    dependent('Child 2', 9, 'child', true, false),
    dependent('Child 3', 11, 'child', true, false),
  ];
  final kids4 = [
    for (var j = 1; j <= 4; j++) dependent('Child $j', 2 + j, 'child', true, false),
  ];
  return [
    DiffCase('edge-actc-at-floor', 'edge',
        makeInput(w2s: [
          w2('W-1', params.actcEarnedIncomeFloor, 0)
        ], dependents: kids2)),
    DiffCase('edge-actc-floor-plus', 'edge',
        makeInput(w2s: [
          w2('W-1', params.actcEarnedIncomeFloor + 0.01, 0)
        ], dependents: kids2)),
    DiffCase('edge-actc-above-floor', 'edge',
        makeInput(w2s: [w2('W-1', 12000, 0)], dependents: kids1)),
    DiffCase('edge-actc-perchild-cap', 'edge',
        makeInput(w2s: [w2('W-1', 15000, 0)], dependents: kids1)),
    DiffCase('edge-actc-earned-cap', 'edge',
        makeInput(w2s: [w2('W-1', 8000, 0)], dependents: kids4)),
    DiffCase('edge-actc-partial-absorption', 'edge',
        makeInput(w2s: [w2('W-1', 40000, 0)], dependents: kids2)),
    DiffCase('edge-actc-zero-earned', 'edge',
        makeInput(
            qualifiedDividends: 30000,
            dependents: kids2)),
    DiffCase('edge-actc-many-kids-low-wage', 'edge',
        makeInput(w2s: [w2('W-1', 9000, 0)], dependents: kids3)),
  ];
}

/// 10. SALT: exactly at each status cap, ±$0.01 around it, far above, and
///     the phase-down / floor zone.
List<DiffCase> edge10Salt() {
  final cases = <DiffCase>[];
  for (final s in FilingStatus.values) {
    final cap = params.saltBaseCap[s]!;
    for (final probe in <(String, double)>[
      ('at-cap', 0.0),
      ('plus', 0.01),
      ('minus', -0.01),
    ]) {
      cases.add(DiffCase(
        'edge-salt-${_slug(s)}-${probe.$1}',
        'edge',
        makeInput(
          filingStatus: s.name,
          w2s: [w2('W-1', 100000, 0)],
          stateLocalIncomeOrSalesTax: cap + probe.$2,
        ),
      ));
    }
  }
  cases
    ..add(DiffCase(
      'edge-salt-far-above-single',
      'edge',
      makeInput(
        w2s: [w2('W-1', 100000, 0)],
        stateLocalIncomeOrSalesTax: 300000,
      ),
    ))
    ..add(DiffCase(
      'edge-salt-far-above-mfs',
      'edge',
      makeInput(
        filingStatus: 'marriedSeparate',
        w2s: [w2('W-1', 100000, 0)],
        stateLocalIncomeOrSalesTax: 300000,
      ),
    ))
    ..add(DiffCase(
      'edge-salt-phasedown-mfj',
      'edge',
      makeInput(
        filingStatus: 'marriedJoint',
        w2s: [w2('W-1', params.saltPhaseoutStart[FilingStatus.marriedJoint]! +
                100000, 0)],
        stateLocalIncomeOrSalesTax: 50000,
      ),
    ))
    ..add(DiffCase(
      'edge-salt-phasedown-mfj-floor',
      'edge',
      makeInput(
        filingStatus: 'marriedJoint',
        w2s: [w2('W-1', params.saltPhaseoutStart[FilingStatus.marriedJoint]! +
                300000, 0)],
        stateLocalIncomeOrSalesTax: 25000,
      ),
    ))
    ..add(DiffCase(
      'edge-salt-phasedown-mfs',
      'edge',
      makeInput(
        filingStatus: 'marriedSeparate',
        w2s: [w2('W-1',
            params.saltPhaseoutStart[FilingStatus.marriedSeparate]! + 50000,
            0)],
        stateLocalIncomeOrSalesTax: 20000,
      ),
    ))
    ..add(DiffCase(
      'edge-salt-phaseout-start-mfj',
      'edge',
      makeInput(
        filingStatus: 'marriedJoint',
        w2s: [w2('W-1', params.saltPhaseoutStart[FilingStatus.marriedJoint]!,
            0)],
        stateLocalIncomeOrSalesTax: params.saltBaseCap[FilingStatus.marriedJoint]!,
      ),
    ))
    ..add(DiffCase(
      'edge-salt-phaseout-start-plus-mfj',
      'edge',
      makeInput(
        filingStatus: 'marriedJoint',
        w2s: [
          w2('W-1',
              params.saltPhaseoutStart[FilingStatus.marriedJoint]! + 0.01, 0)
        ],
        stateLocalIncomeOrSalesTax: params.saltBaseCap[FilingStatus.marriedJoint]!,
      ),
    ));
  return cases;
}

/// 11. Student loan interest: phase-out band ends, exact midpoint
///     (unambiguous), other points inside the band (the D31b reading — fine
///     for differential, marked 'edge-d31b'), MFS ineligibility, MFJ band,
///     and the $2,500 cap.
List<DiffCase> edge11StudentLoan() {
  final start = params.studentLoanPhaseoutStart[FilingStatus.single]!;
  final end = params.studentLoanPhaseoutEnd[FilingStatus.single]!;
  final width = end - start;
  final mfjStart = params.studentLoanPhaseoutStart[FilingStatus.marriedJoint]!;
  final mfjEnd = params.studentLoanPhaseoutEnd[FilingStatus.marriedJoint]!;
  DiffCase at(String id, String cls, double wages,
      {String status = 'single', double sli = 2500}) {
    return DiffCase(
      id,
      cls,
      makeInput(
        filingStatus: status,
        w2s: [w2('W-1', wages, 0)],
        studentLoanInterest: sli,
      ),
    );
  }

  return [
    at('edge-sli-below-start', 'edge', start - 5000),
    at('edge-sli-at-start', 'edge', start),
    at('edge-sli-midpoint', 'edge', start + width / 2),
    at('edge-sli-at-end', 'edge', end),
    at('edge-sli-above-end', 'edge', end + 20000),
    at('edge-sli-quarter', 'edge-d31b', start + width / 4),
    at('edge-sli-three-quarter', 'edge-d31b', start + 3 * width / 4),
    at('edge-sli-third', 'edge-d31b', start + width / 3),
    at('edge-sli-microscopic', 'edge-d31b', start + width / 4, sli: 0.01),
    at('edge-sli-mfs-ineligible', 'edge', 100000,
        status: 'marriedSeparate'),
    at('edge-sli-mfj-midpoint', 'edge',
        mfjStart + (mfjEnd - mfjStart) / 2,
        status: 'marriedJoint'),
    at('edge-sli-over-cap', 'edge', start - 5000, sli: 5000),
  ];
}

/// 12. NIIT: agi exactly at each status threshold ±$0.01 (with investment
///     income large), and the agi-vs-investment cross-over cases.
List<DiffCase> edge12Niit() {
  final cases = <DiffCase>[];
  for (final s in FilingStatus.values) {
    final thr = params.niitThreshold[s]!;
    for (final probe in <(String, double)>[
      ('at', 0.0),
      ('minus', -0.01),
      ('plus', 0.01),
    ]) {
      cases.add(DiffCase(
        'edge-niit-${_slug(s)}-${probe.$1}',
        'edge',
        makeInput(
          filingStatus: s.name,
          qualifiedDividends: thr + probe.$2, // investment-only income
        ),
      ));
    }
  }
  cases
    ..add(DiffCase(
      'edge-niit-crossover-investment-binds', // NII < MAGI excess
      'edge',
      makeInput(
        w2s: [w2('W-1',
            params.niitThreshold[FilingStatus.single]! + 50000, 0)],
        qualifiedDividends: 10000,
      ),
    ))
    ..add(DiffCase(
      'edge-niit-crossover-magi-binds', // MAGI excess < NII
      'edge',
      makeInput(
        w2s: [w2('W-1',
            params.niitThreshold[FilingStatus.single]! + 10000, 0)],
        qualifiedDividends: 50000,
      ),
    ))
    ..add(DiffCase(
      'edge-niit-crossover-tie', // NII == MAGI excess exactly
      'edge',
      makeInput(
        w2s: [w2('W-1', params.niitThreshold[FilingStatus.single]!, 0)],
        qualifiedDividends: 60000,
      ),
    ))
    ..add(DiffCase(
      'edge-niit-interest-only',
      'edge',
      makeInput(
        w2s: [w2('W-1',
            params.niitThreshold[FilingStatus.single]! + 100000, 0)],
        interestIncome: 20000,
      ),
    ));
  return cases;
}

/// 13. QDI stacking: preferential income exactly at the zero-cap and
///     fifteen-cap boundaries per status (+$0.01 into the next band), the
///     deep 20% zone, and the preferential > taxable clamp zone.
List<DiffCase> edge13QdiStacking() {
  final cases = <DiffCase>[];
  for (final s in FilingStatus.values) {
    final sd = params.standardDeduction[s]!;
    final zc = params.qdiZeroCap[s]!;
    final fc = params.qdiFifteenCap[s]!;
    final slug = _slug(s);
    cases
      ..add(DiffCase(
        'edge-qdi-$slug-zerocap-at',
        'edge',
        makeInput(
            filingStatus: s.name, qualifiedDividends: zc + sd),
      ))
      ..add(DiffCase(
        'edge-qdi-$slug-zerocap-plus',
        'edge',
        makeInput(
            filingStatus: s.name, qualifiedDividends: zc + sd + 0.01),
      ))
      ..add(DiffCase(
        'edge-qdi-$slug-fifteencap-at',
        'edge',
        makeInput(
            filingStatus: s.name, qualifiedDividends: fc + sd),
      ))
      ..add(DiffCase(
        'edge-qdi-$slug-fifteencap-plus',
        'edge',
        makeInput(
            filingStatus: s.name, qualifiedDividends: fc + sd + 0.01),
      ));
  }
  final singleSd = params.standardDeduction[FilingStatus.single]!;
  final singleFc = params.qdiFifteenCap[FilingStatus.single]!;
  cases
    ..add(DiffCase(
      'edge-qdi-deep-20pct-single',
      'edge',
      makeInput(qualifiedDividends: singleFc + singleSd + 100000),
    ))
    ..add(DiffCase(
      'edge-qdi-clamp',
      'edge',
      makeInput(
        w2s: [w2('W-1', 10000, 0)],
        qualifiedDividends: 100000, // > taxable: clamped to taxable
      ),
    ))
    ..add(DiffCase(
      'edge-qdi-clamp-exact-equal',
      'edge',
      makeInput(
        w2s: [w2('W-1', singleSd, 0)],
        qualifiedDividends: 40000, // == taxable exactly
      ),
    ));
  return cases;
}

/// 14. Multi-W-2 fold order: 6 W-2s with cent dust in a fixed order + the
///     SAME W-2s reordered (pins the engine's left-fold; the sums differ
///     bitwise). Pair A/B pins totalIncome; pair C/D pins totalPayments.
const List<double> foldWages = <double>[
  10000.37, 20000.13, 30000.79, 40000.42, 50000.61, 60000.24,
];
const List<double> foldWithholding = <double>[
  1500.11, 2500.29, 3500.07, 4500.33, 5500.19, 6500.05,
];
const List<double> foldWholeWages = <double>[
  10000, 20000, 30000, 40000, 50000, 60000,
];

List<DiffCase> edge14W2FoldOrder() {
  final a = <Map<String, dynamic>>[
    for (var i = 0; i < foldWages.length; i++)
      w2('W-${i + 1}', foldWages[i], 0),
  ];
  final c = <Map<String, dynamic>>[
    for (var i = 0; i < foldWholeWages.length; i++)
      w2('W-${i + 1}', foldWholeWages[i], foldWithholding[i]),
  ];
  return [
    DiffCase('edge-w2-fold-order-a', 'edge', makeInput(w2s: a)),
    DiffCase('edge-w2-fold-order-b', 'edge',
        makeInput(w2s: a.reversed.toList())),
    DiffCase('edge-w2-fold-order-c', 'edge', makeInput(w2s: c)),
    DiffCase('edge-w2-fold-order-d', 'edge',
        makeInput(w2s: c.reversed.toList())),
  ];
}

/// 15. Dependent-count extremes: 0 / 1 / 8 qualifying (ACTC per-child caps)
///     / 12 mixed.
List<DiffCase> edge15DependentCounts() {
  List<Map<String, dynamic>> kids(int n) => <Map<String, dynamic>>[
        for (var j = 1; j <= n; j++)
          dependent('Child $j', 2 + j, 'child', true, false),
      ];
  return [
    DiffCase('edge-deps-zero', 'edge', makeInput(w2s: [w2('W-1', 90000, 0)])),
    DiffCase('edge-deps-one', 'edge',
        makeInput(w2s: [w2('W-1', 90000, 0)], dependents: kids(1))),
    DiffCase('edge-deps-eight-qualifying', 'edge',
        makeInput(w2s: [w2('W-1', 30000, 0)], dependents: kids(8))),
    DiffCase('edge-deps-twelve-mixed', 'edge', makeInput(
        w2s: [w2('W-1', 60000, 0)],
        dependents: [
          ...kids(7),
          dependent('Parent 1', 70, 'parent', false, true),
          dependent('Parent 2', 72, 'parent', false, true),
          dependent('Relative 1', 45, 'relative', false, true),
          dependent('Relative 2', 50, 'relative', false, true),
          dependent('Sibling 1', 21, 'relative', false, true),
        ])),
  ];
}

/// 16. effectiveRate zones and the payments boundary: tiny tax, ~$5M AGI,
///     AGI exactly 0 (rate must be 0), payments == tax (refund == owed == 0),
///     refund > 0, refund with refundable credits, owed > 0.
List<DiffCase> edge16RateAndPayments() {
  final singleSd = params.standardDeduction[FilingStatus.single]!;
  // Engine-derived withholding: the draft's own totalTax, so the final case
  // sits exactly on the refund == owed == 0 boundary.
  final draftTax =
      expectedFor(makeInput(w2s: [w2('W-1', 100000, 0)]))['totalTax']
          as double;
  return [
    DiffCase('edge-rate-tiny-taxable', 'edge',
        makeInput(w2s: [w2('W-1', singleSd + 0.01, 0)])),
    DiffCase('edge-rate-large-agi', 'edge',
        makeInput(w2s: [w2('W-1', 5000000, 0)])),
    DiffCase('edge-rate-agi-zero-with-payments', 'edge',
        makeInput(estimatedPayments: 500)),
    DiffCase('edge-payments-refund-owed-zero', 'edge',
        makeInput(w2s: [w2('W-1', 100000, draftTax)])),
    DiffCase('edge-payments-refund-positive', 'edge',
        makeInput(w2s: [w2('W-1', 100000, 20000)])),
    DiffCase(
      'edge-payments-refund-with-actc',
      'edge',
      makeInput(
        w2s: [w2('W-1', 12000, 100)],
        dependents: [dependent('Child 1', 6, 'child', true, false)],
      ),
    ),
    DiffCase('edge-payments-owed-positive', 'edge',
        makeInput(w2s: [w2('W-1', 100000, 1000)])),
  ];
}

// ---------------------------------------------------------------------------
// Self-checks (run before anything is written; any violation aborts)
// ---------------------------------------------------------------------------

void _checkFinite(Object? v, String where) {
  if (v is num) {
    if (!v.isFinite) {
      throw StateError('$where: non-finite value $v');
    }
  } else if (v is Map) {
    v.forEach((k, child) => _checkFinite(child, '$where.$k'));
  } else if (v is List) {
    for (var i = 0; i < v.length; i++) {
      _checkFinite(v[i], '$where[$i]');
    }
  }
}

void selfCheck(List<DiffCase> cases) {
  // Unique ids and known classes.
  final seenIds = <String>{};
  const knownClasses = {'random', 'edge', 'edge-d31b'};
  for (final c in cases) {
    if (!seenIds.add(c.id)) {
      throw StateError('duplicate case id: ${c.id}');
    }
    if (!knownClasses.contains(c.caseClass)) {
      throw StateError('${c.id}: unknown class ${c.caseClass}');
    }
  }

  // Exactly the 26 pinned keys, in the pinned order; every value finite;
  // deductionMethodUsed resolved (never 'auto'); qualifyingChildren an int.
  for (final c in cases) {
    final keys = c.expected.keys.toList(growable: false);
    if (keys.length != expectedKeys.length) {
      throw StateError('${c.id}: expected has ${keys.length} keys, '
          'want ${expectedKeys.length}');
    }
    for (var i = 0; i < expectedKeys.length; i++) {
      if (keys[i] != expectedKeys[i]) {
        throw StateError('${c.id}: expected key $i is ${keys[i]}, '
            'want ${expectedKeys[i]}');
      }
    }
    _checkFinite(c.input, '${c.id}.input');
    _checkFinite(c.expected, '${c.id}.expected');
    final method = c.expected['deductionMethodUsed'] as String;
    if (method != 'standard' && method != 'itemized') {
      throw StateError('${c.id}: deductionMethodUsed is $method '
          '(must be resolved, never auto)');
    }
    final kids = c.expected['qualifyingChildren'];
    if (kids is! int || kids < 0) {
      throw StateError('${c.id}: qualifyingChildren is $kids, want int >= 0');
    }
  }

  DiffCase byId(String id) =>
      cases.firstWhere((c) => c.id == id, orElse: () => throw StateError(
          'self-check: case $id not found'));

  // QSS/MFJ equivalence twins: identical money fields, no dependents — the
  // whole expected block must be identical (D33: QSS maps to the MFJ rate
  // column, standard deduction, QDI caps and NIIT threshold).
  for (final point in ['lo', 'mid', 'hi']) {
    final qss = byId('edge-qss-equiv-$point-qss');
    final mfj = byId('edge-qss-equiv-$point-mfj');
    if (jsonEncode(qss.expected) != jsonEncode(mfj.expected)) {
      throw StateError('edge-qss-equiv-$point: QSS twin differs from the '
          'MFJ twin on identical money fields');
    }
  }

  // W-2 fold-order twins: the same W-2s in a different order must produce
  // bitwise-different folded totals (pins the engine's left fold).
  if (byId('edge-w2-fold-order-a').expected['totalIncome'] ==
      byId('edge-w2-fold-order-b').expected['totalIncome']) {
    throw StateError('w2 fold-order twins: totalIncome identical across '
        'orders — the chosen dust constants no longer pin the fold order');
  }
  if (byId('edge-w2-fold-order-c').expected['totalPayments'] ==
      byId('edge-w2-fold-order-d').expected['totalPayments']) {
    throw StateError('w2 fold-order twins: totalPayments identical across '
        'orders — the chosen dust constants no longer pin the fold order');
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  final rng = Xorshift64Star(seed);
  final cases = <DiffCase>[
    ...randomCases(rng),
    ...edge1ZeroAndPenny(),
    ...edge2BracketBoundaries(),
    ...edge3ItemizedTie(),
    ...edge4ForcedDeduction(),
    ...edge5QssTwins(),
    ...edge6SeniorZones(),
    ...edge7BlindFlags(),
    ...edge8CtcPhaseout(),
    ...edge9Actc(),
    ...edge10Salt(),
    ...edge11StudentLoan(),
    ...edge12Niit(),
    ...edge13QdiStacking(),
    ...edge14W2FoldOrder(),
    ...edge15DependentCounts(),
    ...edge16RateAndPayments(),
  ];

  try {
    selfCheck(cases);
  } on StateError catch (e) {
    stderr.writeln('SELF-CHECK FAILED — nothing written: $e');
    exitCode = 1;
    return;
  }

  final doc = <String, Object>{
    'kind': 'clearfile-differential',
    'generator': 'scripts/generate_differential_cases.dart',
    'seed': seed,
    'caseCount': cases.length,
    'note': note,
    'cases': <Map<String, Object>>[
      for (final c in cases)
        <String, Object>{
          'id': c.id,
          'class': c.caseClass,
          'input': c.input,
          'expected': c.expected,
        },
    ],
  };

  final output = const JsonEncoder.withIndent('  ').convert(doc) + '\n';
  // scripts/x.dart → parent = scripts/ → parent = the repo root.
  final repoRoot =
      Directory(Platform.script.toFilePath()).parent.parent;
  final outFile = File('${repoRoot.path}/$outputRelativePath');
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(output);

  final byClass = <String, int>{};
  for (final c in cases) {
    byClass[c.caseClass] = (byClass[c.caseClass] ?? 0) + 1;
  }
  stdout.writeln('wrote ${outFile.path}');
  stdout.writeln('  bytes: ${utf8.encode(output).length}');
  stdout.writeln('  cases: ${cases.length}');
  byClass.forEach((cls, n) => stdout.writeln('    $cls: $n'));
}
