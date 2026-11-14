// SPDX-License-Identifier: GPL-3.0-only
import 'dart:convert';
import 'dart:io';

import 'package:clearfile/models/tax_return.dart';
import 'package:clearfile/tax/calculator.dart';
import 'package:clearfile/tax/results.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden-fixture regression suite for the reference (Flutter) tax engine.
///
/// The fixtures are JSON `(TaxReturnData, TaxResult)` pairs living in the
/// repo-level `fixtures/tax/` directory, pinned to IRS-published TY2025
/// worked examples and worksheet arithmetic (each file carries its own
/// `source.pin`, line-by-line `derivation`, and a `tolerance`). They are the
/// single source of truth that settles disagreements between the two
/// engines: the same files are consumed by the web (TypeScript) engine's
/// parity tests in Stage 3, and `scripts/verify_golden_fixtures.py`
/// re-derives every expectation from the IRS form text independently of
/// this engine.
///
/// Adding a fixture: copy an existing file, set input + expected values
/// ONLY from an IRS publication (cite it in `source`), and derive each
/// expected number by hand from the worksheet lines (never by running this
/// engine). Whole-dollar IRS figures (Tax Table rows) use tolerance 0.505;
/// exact worksheet arithmetic uses 0.005.
void main() {
  final dir = Directory('../fixtures/tax');

  double? readField(TaxResult r, String key) {
    switch (key) {
      case 'totalIncome':
        return r.totalIncome;
      case 'studentLoanDeduction':
        return r.studentLoanDeduction;
      case 'agi':
        return r.agi;
      case 'basicStandardDeduction':
        return r.basicStandardDeduction;
      case 'additionalStandardDeduction':
        return r.additionalStandardDeduction;
      case 'seniorDeduction':
        return r.seniorDeduction;
      case 'standardDeductionTotal':
        return r.standardDeductionTotal;
      case 'saltPaid':
        return r.saltPaid;
      case 'saltCap':
        return r.saltCap;
      case 'saltAllowed':
        return r.saltAllowed;
      case 'itemizedDeductionTotal':
        return r.itemizedDeductionTotal;
      case 'deductionUsed':
        return r.deductionUsed;
      case 'taxableIncome':
        return r.taxableIncome;
      case 'ordinaryTax':
        return r.ordinaryTax;
      case 'preferentialIncome':
        return r.preferentialIncome;
      case 'preferentialTax':
        return r.preferentialTax;
      case 'niit':
        return r.niit;
      case 'nonRefundableCredits':
        return r.nonRefundableCredits;
      case 'refundableCredits':
        return r.refundableCredits;
      case 'totalTax':
        return r.totalTax;
      case 'totalPayments':
        return r.totalPayments;
      case 'refund':
        return r.refund;
      case 'amountOwed':
        return r.amountOwed;
      case 'effectiveRate':
        return r.effectiveRate;
      case 'marginalRate':
        return r.marginalRate;
      case 'qualifyingChildren':
        return r.qualifyingChildren.toDouble();
    }
    return null;
  }

  setUpAll(() {
    if (!dir.existsSync()) {
      throw StateError('fixtures/tax must exist relative to the '
          'clearfile package');
    }
  });

  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) {
    throw StateError('no golden fixtures found in ${dir.path}');
  }

  for (final file in files) {
    final Map<String, dynamic> fixture;
    try {
      fixture =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    } catch (e) {
      fail('${file.path}: invalid JSON fixture: $e');
    }

    group(fixture['name'] as String? ?? file.uri.pathSegments.last, () {
      test('matches the IRS-pinned expected values', () {
        final expected = fixture['expected'] as Map<String, dynamic>;
        final tolerance =
            (fixture['tolerance'] as num? ?? 0.005).toDouble();

        final input = TaxReturnData.fromJson(
            (fixture['input'] as Map<String, dynamic>).cast<String, dynamic>());
        final result = const TaxCalculator().compute(input);

        if (expected.containsKey('deductionMethodUsed')) {
          expect(
            result.deductionMethodUsed.name,
            expected['deductionMethodUsed'],
            reason: '${file.path}: deduction method used',
          );
        }

        final failures = <String>[];
        for (final entry in expected.entries) {
          if (entry.key == 'deductionMethodUsed') continue; // enum, asserted above
          final value = readField(result, entry.key);
          if (value == null) {
            failures.add('${entry.key}: not a TaxResult field');
            continue;
          }
          final delta = (value - (entry.value as num).toDouble()).abs();
          if (delta > tolerance) {
            failures.add('${entry.key}: engine $value vs '
                'pinned ${entry.value} (delta $delta > $tolerance)');
          }
        }
        expect(
          failures,
          isEmpty,
          reason: '${file.path}: ${fixture['description']}\n'
              '${failures.join('\n')}',
        );
      });
    });
  }
}
