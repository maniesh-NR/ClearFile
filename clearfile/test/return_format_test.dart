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
/// outcome (D1). Fixtures are program-synthesized; the v1 migration
/// samples are the shared cross-suite fixtures in `fixtures/migration/`
/// (DEBT D34 — one identical file, exact warning lists asserted by both
/// this suite and the web bridge suite).
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

  test('web v1 envelope migrates with the conservative mapping (shared '
      'fixture, D34)', () {
    // The identical v1 sample both suites verify (fixtures/migration/,
    // DEBT D34): one file on disk, the exact warning list asserted on
    // both sides — drift in wording or ordering now fails a test.
    final v1 = File('../fixtures/migration/v1-web-envelope.json')
        .readAsStringSync();
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
    // D34: the exact warning list, in order — the bridge suite asserts
    // the same list from the same file.
    expect(decoded.warnings, equals(<String>[
      'Saved with an older prototype: the return was migrated to the '
          'current engine model.',
      '"Adjustments to income" had no equivalent in the current model and '
          'was dropped — re-enter it as student loan interest if that is '
          'what it was.',
      'Medical and "other" itemized expenses have no equivalent in the '
          'current model and were dropped.',
      'Dependent counts were migrated; re-enter their names in the '
          'Dependents step.',
    ]));
  });

  test('v1 dependent counts clamp at 100 placeholder rows (shared edge '
      'fixture, D34)', () {
    // qualifyingChildren: 250 → 100 (the historical Dart bound, now pinned
    // on both file readers); only the two applicable warnings surface.
    final v1 =
        File('../fixtures/migration/v1-web-envelope-edge-clamp.json')
            .readAsStringSync();
    final decoded = ReturnFileCodec.decode(v1);
    final f = decoded.filing;
    expect(f.filingStatus, FilingStatus.headOfHousehold);
    expect(f.stateLocalIncomeOrSalesTax, 100);
    expect(f.w2s.single.employer, 'Edge Corp');
    expect(f.dependents, hasLength(101)); // 250 clamped to 100 + 1 other
    expect(f.dependents.where((d) => d.qualifyingChild), hasLength(100));
    expect(f.dependents.where((d) => d.otherDependentCredit), hasLength(1));
    expect(decoded.warnings, equals(<String>[
      'Saved with an older prototype: the return was migrated to the '
          'current engine model.',
      'Dependent counts were migrated; re-enter their names in the '
          'Dependents step.',
    ]));
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
