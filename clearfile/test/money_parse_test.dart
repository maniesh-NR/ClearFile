// SPDX-License-Identifier: GPL-3.0-only
import 'package:clearfile/util/money.dart';
import 'package:flutter_test/flutter_test.dart';

/// Edge tests for the shared tolerant money parser (Stage-1 debt D2).
///
/// parseMoney() is the single parser behind both the W-2 CSV importer and
/// the money text field; these tests pin its behaviour so any change to it
/// is deliberate. In particular, the decimal-comma guard ("6,5" used to
/// silently parse as 65) must not regress.
void main() {
  group('parseMoney', () {
    test('empty and whitespace-only input mean zero, not an error', () {
      expect(parseMoney(''), 0);
      expect(parseMoney(' '), 0);
      expect(parseMoney('\t'), 0);
      expect(parseMoney('\$'), 0);
    });

    test('plain and tolerant US formats parse', () {
      expect(parseMoney('52500'), 52500);
      expect(parseMoney('\$52,500.00'), 52500.0);
      expect(parseMoney('6,200'), 6200);
      expect(parseMoney(' 6 200 '), 6200);
      expect(parseMoney('1,234.5'), 1234.5);
      expect(parseMoney('-5.25'), -5.25);
    });

    test('unparseable text returns null', () {
      expect(parseMoney('abc'), isNull);
      expect(parseMoney('12x'), isNull);
    });

    test('decimal-comma shapes are refused instead of silently mangling',
        () {
      // A comma with only one or two trailing digits is never valid US
      // thousands grouping: it is a decimal-comma locale leaking through.
      expect(parseMoney('6,5'), isNull);
      expect(parseMoney('6,50'), isNull);
      expect(parseMoney('-1,5'), isNull);
    });

    test('non-US formats stay out of scope (pinned, not rehabilitated)', () {
      // A US-format prototype: dot-decimal only. Stripping the comma from a
      // European-format string yields a mangled-but-parseable number — that
      // is the documented limitation, pinned here so it cannot drift
      // silently either.
      expect(parseMoney('1.234,56'), 1.23456);
      expect(parseMoney('1,2,3'), 123);
    });
  });
}
