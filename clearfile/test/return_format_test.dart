// SPDX-License-Identifier: GPL-3.0-only
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:clearfile/io/return_format.dart';
import 'package:clearfile/io/return_store.dart';
import 'package:clearfile/models/dependent.dart';
import 'package:clearfile/models/filing_status.dart';
import 'package:clearfile/models/tax_return.dart';
import 'package:clearfile/models/w2.dart';

/// Unified ClearFile return format (ADR-015): envelope round-trip, the
/// version guard (D3), legacy-layout migration, and the sealed import
/// outcome (D1). Fixtures are all program-synthesized.
void main() {
  TaxReturnData sample() => TaxReturnData(
        displayName: 'Format test',
        filingStatus: FilingStatus.marriedJoint,
        taxpayer65OrOlder: true,
        w2s: [
          W2Entry(employer: 'Acme', wages: 90000, withholding: 9000),
          W2Entry(employer: 'Globex', wages: 10000, withholding: 500),
        ],
        interestIncome: 120.5,
        qualifiedDividends: 500,
        longTermCapitalGains: 1000,
        studentLoanInterest: 300,
        stateLocalIncomeOrSalesTax: 8000,
        dependents: [
          Dependent(
              name: 'Kid',
              age: 8,
              relationship: 'daughter',
              qualifyingChild: true),
        ],
        estimatedPayments: 700,
      );

  test('envelope round-trip preserves the return', () {
    final r = sample();
    final decoded = ReturnFileCodec.decode(ReturnFileCodec.encode(r));
    expect(decoded.warnings, isEmpty);
    expect(decoded.filing, equals(r)); // toJson-map equality
    expect(decoded.filing.displayName, 'Format test');
    expect(decoded.filing.w2s, hasLength(2));
    expect(decoded.filing.w2s.first.wages, 90000);
    expect(decoded.filing.dependents.single.qualifyingChild, isTrue);
  });

  test('encode writes the unified envelope, not the legacy markers', () {
    final obj = jsonDecode(ReturnFileCodec.encode(sample()))
        as Map<String, dynamic>;
    expect(obj['format'], 'clearfile-return');
    expect(obj['version'], 2);
    expect(obj['app'], isNotEmpty);
    expect(obj['savedAt'], isNotEmpty);
    final filing = obj['filing'] as Map<String, dynamic>;
    expect(filing.containsKey('format'), isFalse);
    expect(filing.containsKey('formatVersion'), isFalse);
    expect(filing['displayName'], 'Format test');
  });

  test('version guard refuses future envelopes (D3)', () {
    final future = jsonEncode({
      'format': 'clearfile-return',
      'version': 3,
      'filing': <String, dynamic>{},
    });
    expect(
      () => ReturnFileCodec.decode(future),
      throwsA(isA<ReturnFormatException>().having(
          (e) => e.message, 'message', contains('Unsupported version 3'))),
    );
  });

  test('version guard refuses missing envelope versions', () {
    final unversioned = jsonEncode({
      'format': 'clearfile-return',
      'filing': <String, dynamic>{},
    });
    expect(
      () => ReturnFileCodec.decode(unversioned),
      throwsA(isA<ReturnFormatException>()
          .having((e) => e.message, 'message', contains('Unsupported'))),
    );
  });

  test('version guard refuses future flat files', () {
    final futureFlat = jsonEncode({
      'format': 'clearfile.return',
      'formatVersion': 7,
      'displayName': 'from the future',
    });
    expect(
      () => ReturnFileCodec.decode(futureFlat),
      throwsA(isA<ReturnFormatException>().having(
          (e) => e.message, 'message', contains('Unsupported version 7'))),
    );
  });

  test('legacy flat layout (ClearFile <= v1.0.1) lifts losslessly', () {
    final r = sample();
    // The model's own flat serialization IS the legacy file shape.
    final legacy = jsonEncode(r.toJson());
    final decoded = ReturnFileCodec.decode(legacy);
    expect(decoded.filing, equals(r));
    expect(decoded.warnings, isEmpty); // lossless: nothing to report
  });

  test('web v1 envelope migrates with the conservative mapping', () {
    final v1 = jsonEncode({
      'format': 'clearfile-return',
      'version': 1,
      'app': 'ClearFile prototype 0.1',
      'savedAt': '2026-11-03T00:00:00.000Z',
      'filing': {
        'status': 'mfj',
        'taxYear': 2026,
        'interest': 500,
        'dividends': 300,
        'adjustments': 120,
        'itemized': {
          'taxesPaid': 8000,
          'mortgageInterest': 9000,
          'charity': 1000,
          'medical': 200,
          'other': 50,
        },
        'qualifyingChildren': 2,
        'otherDependents': 1,
        'w2s': [
          {'employer': 'Acme', 'wages': 90000, 'withholding': 9000},
        ],
      },
    });
    final decoded = ReturnFileCodec.decode(v1);
    final f = decoded.filing;
    expect(f.filingStatus, FilingStatus.marriedJoint);
    expect(f.taxYear, 2025);
    expect(f.interestIncome, 500);
    expect(f.ordinaryDividends, 300);
    expect(f.studentLoanInterest, 0); // adjustments dropped, warned
    expect(f.stateLocalIncomeOrSalesTax, 8000);
    expect(f.mortgageInterest, 9000);
    expect(f.charitableCash, 1000);
    expect(f.w2s.single.employer, 'Acme');
    expect(f.dependents, hasLength(3)); // 2 children + 1 other dependent
    expect(f.dependents.where((d) => d.qualifyingChild), hasLength(2));
    expect(f.dependents.where((d) => d.otherDependentCredit), hasLength(1));
    // The web parser's four v1 warnings, mirrored verbatim.
    expect(
        decoded.warnings.any((w) => w.contains('older prototype')), isTrue);
    expect(decoded.warnings
        .any((w) => w.contains('Adjustments to income')), isTrue);
    expect(decoded.warnings.any((w) => w.contains('Medical and "other"')),
        isTrue);
    expect(decoded.warnings.any((w) => w.contains('Dependent counts')),
        isTrue);
  });

  test('missing v2 filing defaults with warnings, matching the web reader',
      () {
    final empty = jsonEncode({
      'format': 'clearfile-return',
      'version': 2,
      'app': 'ClearFile 1.0.1',
      'savedAt': '2026-11-15T00:00:00.000Z',
    });
    final decoded = ReturnFileCodec.decode(empty);
    expect(decoded.filing.filingStatus, FilingStatus.single);
    expect(decoded.warnings
        .any((w) => w.contains('Filing status was missing')), isTrue);
  });

  test('unsupported tax years default to 2025 with a warning', () {
    final futureYear = jsonEncode({
      'format': 'clearfile-return',
      'version': 2,
      'filing': {
        'filingStatus': 'single',
        'taxYear': 2026,
      },
    });
    final decoded = ReturnFileCodec.decode(futureYear);
    expect(decoded.filing.taxYear, 2025);
    expect(
        decoded.warnings.any((w) => w.contains('defaulted to 2025')), isTrue);
  });

  test('non-JSON files fail with a clear reason', () {
    expect(
      () => ReturnFileCodec.decode('not json at all'),
      throwsA(isA<ReturnFormatException>()
          .having((e) => e.message, 'message', contains('not valid JSON'))),
    );
  });

  test('foreign files fail with an explicit unrecognized-format error', () {
    final foreign = jsonEncode({'hello': 'world'});
    expect(
      () => ReturnFileCodec.decode(foreign),
      throwsA(isA<ReturnFormatException>().having(
          (e) => e.message, 'message', contains('Unrecognized format'))),
    );
  });

  test('decodeReturnImport maps outcomes for the picker flow (D1)', () {
    final ok = decodeReturnImport(
        ReturnFileCodec.encode(sample()));
    expect(ok, isA<ReturnImportOk>());
    expect((ok as ReturnImportOk).filing.displayName, 'Format test');

    final failed = decodeReturnImport('garbage');
    expect(failed, isA<ReturnImportFailed>());
    expect((failed as ReturnImportFailed).reason, contains('not valid JSON'));

    const cancelled = ReturnImportCancelled();
    expect(cancelled, isA<ReturnImport>());
  });

  group('FileReturnStore uses the same envelope (drop-in compatibility)', () {
    test('save/listReturns round-trips the envelope on disk', () async {
      final dir =
          await Directory.systemTemp.createTemp('clearfile_store_env');
      addTearDown(() => dir.delete(recursive: true));
      final store = FileReturnStore(dir);
      final r = sample();
      await store.save(r);
      final listed = await store.listReturns();
      expect(listed, hasLength(1));
      expect(listed.first.displayName, 'Format test');
      expect(listed.first.w2s, hasLength(2));
      final onDisk =
          await File('${dir.path}/returns/${r.id}.json').readAsString();
      final obj = jsonDecode(onDisk) as Map<String, dynamic>;
      expect(obj['format'], 'clearfile-return');
      expect(obj['version'], 2);
    });

    test('legacy flat store files are migrated on read; corrupt skipped',
        () async {
      final dir =
          await Directory.systemTemp.createTemp('clearfile_store_legacy');
      addTearDown(() => dir.delete(recursive: true));
      final returnsDir = Directory('${dir.path}/returns')
        ..createSync(recursive: true);
      final legacy = TaxReturnData(
        displayName: 'Legacy autosave',
        interestIncome: 42,
        created: DateTime(2020, 1, 1),
        modified: DateTime(2020, 1, 2),
      );
      File('${returnsDir.path}/legacy.json')
          .writeAsStringSync(jsonEncode(legacy.toJson()));
      File('${returnsDir.path}/broken.json')
          .writeAsStringSync('not json');
      final store = FileReturnStore(dir);
      final listed = await store.listReturns();
      expect(listed, hasLength(1)); // corrupt file skipped, not fatal
      expect(listed.first.displayName, 'Legacy autosave');
      expect(listed.first.interestIncome, 42);
      expect(listed.first.created, DateTime(2020, 1, 1));
    });
  });
}
