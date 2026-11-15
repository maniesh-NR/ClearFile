// SPDX-License-Identifier: GPL-3.0-only
import 'package:flutter_test/flutter_test.dart';

import 'package:clearfile/io/txf_import.dart';

/// TXF import tests, pinned to the published spec v042 record structure
/// (header V/A/D + `^`-terminated records; T type, N refnum, C copy,
/// L line, $ amount, P description) and its tax line item table
/// (460/461/466 W-2 family, 287/286/683/488/257 income, 275/544/276/283/
/// 545/280/485 deductions, 268/521 payments, 636 student loan).
void main() {
  test('canonical V042 structure imports every mapped field', () {
    final txf = [
      'V042',
      'AQuicken 2011 for Windows R1',
      'D 03/16/2026',
      '^',
      // W-2 copy 1 (self): payer + salary + withholding
      'TS',
      'N466',
      'C1',
      'PAcme Corp',
      '^',
      'TS',
      'N460',
      'C1',
      r'$ 52500.00',
      '^',
      'TS',
      'N461',
      'C1',
      r'$ -6200.00', // spec sign: money paid is negative
      '^',
      // W-2 copy 2 (self)
      'TS',
      'N466',
      'C2',
      'PBeta School District',
      '^',
      'TS',
      'N460',
      'C2',
      r'$ 38200.00',
      '^',
      'TS',
      'N461',
      'C2',
      r'$ -3410.50',
      '^',
      // Interest income, two L lines (sums per spec's multi-line model)
      'TD',
      'N287',
      'C1',
      'L1',
      r'$ 90.00',
      'X 3/24/2026 Our Checking DEP Interest earned',
      '^',
      'TD',
      'N287',
      'C1',
      'L2',
      r'$ 30.00',
      'X 4/24/2026 Our Checking DEP Interest earned',
      '^',
      'TS',
      'N287',
      'C1',
      'L1',
      r'$ 120.00',
      '^',
      // Dividends: total 286, qualified 683
      'TS',
      'N286',
      'C1',
      r'$ 1000.00',
      '^',
      'TS',
      'N683',
      'C1',
      r'$ 800.00',
      '^',
      // Capital gain distribution -> long-term gains
      'TS',
      'N488',
      'C1',
      r'$ 450.00',
      '^',
      // Other income (1040:21)
      'TS',
      'N257',
      'C1',
      r'$ 300.00',
      '^',
      // Sch A: state+local taxes, real estate, mortgage, charity
      'TS',
      'N275',
      'C1',
      r'$ -2000.00',
      '^',
      'TS',
      'N544',
      'C1',
      r'$ -400.00',
      '^',
      'TS',
      'N276',
      'C1',
      r'$ -3100.00',
      '^',
      'TS',
      'N283',
      'C1',
      r'$ -8200.00',
      '^',
      'TS',
      'N280',
      'C1',
      r'$ -625.00',
      '^',
      'TS',
      'N485',
      'C1',
      r'$ -1000.00',
      '^',
      // Estimated tax + student loan interest
      'TS',
      'N268',
      'C1',
      r'$ -1000.00',
      '^',
      'TS',
      'N636',
      'C1',
      r'$ -900.00',
      '^',
    ].join('\n');

    final result = parseTxf(txf);
    final r = result.returnData;

    expect(r.w2s, hasLength(2));
    expect(r.w2s[0].employer, 'Acme Corp');
    expect(r.w2s[0].wages, 52500);
    expect(r.w2s[0].withholding, 6200);
    expect(r.w2s[1].employer, 'Beta School District');
    expect(r.w2s[1].wages, 38200);
    expect(r.w2s[1].withholding, 3410.5);

    expect(r.interestIncome, 120); // detail records ignored, summary only
    expect(r.ordinaryDividends, 200); // total 1000 - qualified 800
    expect(r.qualifiedDividends, 800);
    expect(r.longTermCapitalGains, 450);
    expect(r.otherIncome, 300);
    expect(r.stateLocalIncomeOrSalesTax, 2400); // 275 + 544 magnitudes
    expect(r.realEstateTax, 3100);
    expect(r.mortgageInterest, 8200);
    expect(r.charitableCash, 625);
    expect(r.charitableNonCash, 1000);
    expect(r.estimatedPayments, 1000);
    expect(r.studentLoanInterest, 900);

    // Honest importer notes, not errors: the 2026 export date (TXF carries
    // no tax-year field) and the two ignored detail records.
    expect(result.warnings, hasLength(2));
    expect(result.warnings.first, contains('2026'));
    expect(result.warnings.last, contains('detail (TD) records'));
    expect(result.unknownCodes, isEmpty);
  });

  test('record may legally start at N with no separate TS line', () {
    final txf = 'V042\nA ClearFile test\nD 01/15/2026\n^\n'
        'N460\nC1\n\$ 1000\n^\n';
    final result = parseTxf(txf);
    expect(result.returnData.w2s.single.wages, 1000);
  });

  test('CRLF line endings and spaced field tags ("N 460") both parse', () {
    final txf = 'V042\r\nA ClearFile test\r\nD 01/15/2026\r\n^\r\n'
        'TS\r\nN 460\r\nC 1\r\n\$ 1000\r\n^\r\n';
    final result = parseTxf(txf);
    expect(result.returnData.w2s.single.wages, 1000);
  });

  test('spouse W-2 codes land in their own copy space', () {
    final txf = 'V042\n^\n'
        'TS\nN460\nC1\n\$ 1000\n^\n'
        'TS\nN506\nC1\n\$ 2000\n^\n'
        'TS\nN507\nC1\n\$ -300\n^\n';
    final result = parseTxf(txf);
    expect(result.returnData.w2s, hasLength(2));
    expect(result.returnData.w2s[0].wages, 1000);
    expect(result.returnData.w2s[1].wages, 2000);
    expect(result.returnData.w2s[1].withholding, 300);
  });

  test('unknown refnums are reported, not guessed', () {
    final txf = 'V042\n^\nTS\nN1234\nC1\n\$ 99\n^\nTS\nN460\nC1\n\$ 500\n^\n';
    final result = parseTxf(txf);
    expect(result.unknownCodes, [1234]);
    expect(result.returnData.w2s.single.wages, 500);
    expect(
        result.warnings.any((w) => w.contains('1234')), isTrue);
  });

  test('non-V042 version and off-year export date produce notes', () {
    final txf = 'V037\n^\nTS\nN460\nC1\n\$ 500\n^\n';
    final result = parseTxf(txf);
    expect(
        result.warnings.any((w) => w.contains('V037')), isTrue);
    expect(result.returnData.taxYear, 2025);
  });

  test('unparsable amounts are skipped with a warning', () {
    final txf = 'V042\n^\nTS\nN460\nC1\n\$ bananas\n^\n';
    final result = parseTxf(txf);
    // No readable amount and no payer means no W-2 entry is created.
    expect(result.returnData.w2s, isEmpty);
    expect(result.warnings.any((w) => w.contains('bananas')), isTrue);
  });

  test('no importable summary records throws a honest error', () {
    expect(
        () => parseTxf('V042\nA test\nD 01/15/2026\n^\n'),
        throwsA(isA<TxfParseException>()));
    expect(() => parseTxf('hello world\n'), throwsA(isA<TxfParseException>()));
  });

  test('parser hardening: the 5 MB cap throws', () {
    final huge = 'V042\n^\n${'x' * (5 * 1024 * 1024)}';
    expect(() => parseTxf(huge), throwsA(isA<TxfParseException>()));
  });

  test('parser hardening: a 4097-char line throws', () {
    final longLine = 'N460\nC1\n\$ ${'9' * 5000}\n^\n';
    expect(() => parseTxf('V042\n^\n$longLine'),
        throwsA(isA<TxfParseException>()));
  });

  test('empty-file edge: no records at all throws', () {
    expect(() => parseTxf(''), throwsA(isA<TxfParseException>()));
  });
}
