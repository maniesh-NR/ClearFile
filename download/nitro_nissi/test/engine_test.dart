/// Engine verification tests — every expectation is hand-computed from the
/// parameter sources cited in docs/TAX_ENGINE.md.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitro_nissi/core/tax/engine.dart';
import 'package:nitro_nissi/core/tax/model.dart';
import 'package:nitro_nissi/core/tax/params_2024.dart';
import 'package:nitro_nissi/core/tax/params_2025.dart';
import 'package:nitro_nissi/core/io/tax_file.dart';
import 'package:nitro_nissi/core/io/importer_tt.dart';
import 'package:nitro_nissi/core/efile/mef_json.dart';

const engine = FederalEngine();

void main() {
  group('TY2025 — single wage earner', () {
    // 60,000 wages + 1,000 interest, standard deduction 15,750
    // → taxable 45,250 → tax 1,192.50 + 12%×33,325 = 5,191.50 → 5,192
    // withholding 5,500 → refund 308.
    test('refund of \$308', () {
      final d = TaxReturnData(taxYear: 2025)
        ..w2s.add(W2Entry(employerName: 'Acme', wages: 60000, federalWithholding: 5500,
            ssWages: 60000, ssWithholding: 3720, medicareWithholding: 870))
        ..interest.add(InterestIncome(payer: 'Bank', taxableInterest: 1000));
      final r = engine.compute(d, params2025);
      expect(r.agi, 61000);
      expect(r.deductionUsed, 15750);
      expect(r.taxableIncome, 45250);
      expect(r.totalTax, 5192);
      expect(r.refundOrOwe, 308);
      expect(r.isRefund, isTrue);
    });
  });

  group('TY2024 — MFJ with 2 kids (CTC + ACTC + EITC)', () {
    // 45,000 wages, std 29,200 → TI 15,800 → tax 1,580.
    // CTC nonrefundable 1,580 (consumes the entire tax); ACTC = min(4,000−1,580, 2×1,700, 15%×42,500) = 2,420.
    // EITC 2 kids: 6,960 − 21.06%×(45,000−29,640) = 3,725.20 → 3,725.
    // totalTax after credits = 0. Refund = 2,000 − 0 − (2,420 + 3,725) = 4,145.
    TaxReturnData data() => TaxReturnData(
          taxYear: 2024,
          filingStatus: FilingStatus.marriedJointly,
          spouse: Person(firstName: 'Sam', lastName: 'Doe', ssn: '000-00-0002'),
        )
          ..w2s.add(W2Entry(employerName: 'Job', wages: 45000, federalWithholding: 2000,
              ssWages: 45000, ssWithholding: 2790, medicareWithholding: 652))
          ..dependents.addAll([
            Dependent(firstName: 'Kid1', ssn: '000-00-0003', dateOfBirth: DateTime(2019, 3, 1)),
            Dependent(firstName: 'Kid2', ssn: '000-00-0004', dateOfBirth: DateTime(2016, 7, 1)),
          ]);

    test('combined refundable credits and refund', () {
      final r = engine.compute(data(), params2024);
      expect(r.ctcEligibleChildren, 2);
      expect(r.ctcNonrefundable, 1580);
      expect(r.ctcRefundable, 2420);
      expect(r.eitc, 3725);
      expect(r.totalTax, 0);
      expect(r.refundOrOwe, -4145);
    });
  });

  group('TY2025 — self-employment with QBI', () {
    // SE net 50,000 → SE earnings 46,175 → SE tax 7,064.775 → 7,065.
    // Half SE = 3,532. AGI = 46,468 (rounded). Std 15,750.
    // TI before QBI = 30,718; QBI = min(10,000, 20%×30,717.61)=6,143.52
    // TI = 24,574; tax = 1,192.50 + 12%×12,649.09 = 2,710.39 → 2,710.
    // Total owed = 2,710 + 7,065 = 9,775.
    test('SE tax, half-SE deduction and QBI', () {
      final d = TaxReturnData(taxYear: 2025)
        ..selfEmployment.add(SelfEmploymentIncome(businessName: 'Consulting', netProfit: 50000));
      final r = engine.compute(d, params2025);
      expect(r.seEarnings, 46175);
      expect(r.seTax, 7065);
      expect(r.halfSeTaxDeduction, 3532);
      expect(r.qbiDeduction, 6144); // 20% of 30,717.61 → 6,143.52 → engine keeps unrounded until output: 6,144
      expect(r.totalTax, 9775);
      expect(r.isRefund, isFalse);
    });
  });

  group('TY2025 — OBBBA senior + tips + overtime', () {
    // Single, 65+ (born 1958). Wages 90,000 incl. 5,000 tips + 8,000 OT.
    // AGI = 90,000 − 5,000 − 8,000 = 77,000.
    // Std = 15,750 + 2,000 (65+) = 17,750.
    // Senior = 6,000 − 6%×(77,000−75,000) = 5,880.
    // TI = 77,000 − 17,750 − 5,880 = 53,370.
    // Bracket check: 10%×11,925 + 12%×36,550 + 22%×4,895 = 1,192.50 + 4,386 + 1,076.90 = 6,655.40 → 6,655.
    test('new deductions apply with phaseouts', () {
      final d = TaxReturnData(taxYear: 2025)
        ..taxpayer = Person(firstName: 'Pat', dateOfBirth: DateTime(1958, 6, 15))
        ..w2s.add(W2Entry(employerName: 'Diner', wages: 90000,
            qualifiedTips: 5000, qualifiedOvertime: 8000));
      final r = engine.compute(d, params2025);
      expect(r.obbbaTipsDeduction, 5000);
      expect(r.obbbaOvertimeDeduction, 8000);
      expect(r.seniorDeduction, 5880);
      expect(r.standardDeductionUsed, 17750);
      expect(r.taxableIncome, 53370);
      expect(r.totalTax, 6655);
    });

    test('senior deduction phases to zero over \$175,000', () {
      final d = TaxReturnData(taxYear: 2025)
        ..taxpayer = Person(firstName: 'Pat', dateOfBirth: DateTime(1955, 1, 1))
        ..w2s.add(W2Entry(employerName: 'Corp', wages: 200000));
      final r = engine.compute(d, params2025);
      // 6,000 − 6%×(200,000−75,000) = −1,500 → 0
      expect(r.seniorDeduction, 0);
    });
  });

  group('TY2025 — preferential rates', () {
    // Single: wages 30,000, qualified dividends 5,000.
    // Std 15,750 → TI 19,250. Ordinary part 14,250 → 10% bracket top 11,925:
    // tax = 1,192.50 + 12%×2,325 = 1,471.50 → 1,472 (rounded).
    // Preferential 5,000: all below the 15% start (48,350) → 0%.
    test('qualified dividends taxed at 0% in the 10/12% range', () {
      final d = TaxReturnData(taxYear: 2025)
        ..w2s.add(W2Entry(employerName: 'Job', wages: 30000))
        ..dividends.add(DividendIncome(payer: 'Broker', ordinaryDividends: 5000, qualifiedDividends: 5000));
      final r = engine.compute(d, params2025);
      expect(r.ordinaryTax, 1472);
      expect(r.preferentialTax, 0);
      expect(r.totalTax, 1472);
    });
  });

  group('file format round-trip', () {
    test('.nnx serialize/load preserves data', () {
      final d = TaxReturnData(taxYear: 2025)
        ..w2s.add(W2Entry(employerName: 'Acme', wages: 12345, federalWithholding: 500))
        ..dependents.add(Dependent(firstName: 'Kid', dateOfBirth: DateTime(2020, 1, 1)));
      final text = TaxFile.save(d);
      final loaded = TaxFile.load(text);
      expect(loaded.taxYear, 2025);
      expect(loaded.w2s.single.wages, 12345);
      expect(loaded.w2s.single.employerName, 'Acme');
      expect(loaded.dependents.single.firstName, 'Kid');
    });

    test('recomputing a loaded return gives identical results', () {
      final d = TaxReturnData(taxYear: 2025)
        ..w2s.add(W2Entry(employerName: 'Acme', wages: 60000, federalWithholding: 5500))
        ..interest.add(InterestIncome(payer: 'Bank', taxableInterest: 1000));
      final a = engine.compute(d, params2025);
      final b = engine.compute(TaxFile.load(TaxFile.save(d)), params2025);
      expect(b.refundOrOwe, a.refundOrOwe);
      expect(b.totalTax, a.totalTax);
    });
  });

  group('best-effort importer', () {
    test('maps JSON with known keys into a review preview', () {
      const json = '{"employerName": "Acme Corp", "wages": 55000, '
          '"federalWithholding": 4000, "ssn": "123-45-6789"}';
      final bytes = Uint8List.fromList(utf8.encode(json));
      final preview = const TurboTaxImporter().analyze(bytes, 'probe.json');
      expect(preview.fields, isNotEmpty);
      final wages = preview.fields.firstWhere((f) => f.key == 'w2.wages');
      expect(wages.value, 55000);
      final applied = applyImport(TaxReturnData(), preview.fields);
      expect(applied.w2s.single.employerName, 'Acme Corp');
      expect(applied.w2s.single.wages, 55000);
      expect(applied.taxpayer.ssn, '123-45-6789');
    });

    test('inflates zlib streams embedded in binary blobs', () {
      // Build a zlib stream of a JSON payload using dart:io ZLibEncoder via
      // the archive package used by the importer itself.
      const payload = '{"wages": 42000, "employerName": "ZlibCo"}';
      final compressed = Uint8List.fromList(ZLibEncoder().encode(utf8.encode(payload)) as List<int>);
      final preview = const TurboTaxImporter().analyze(compressed, 'blob.bin');
      expect(preview.fields.map((f) => f.key), contains('w2.wages'));
    });
  });

  group('MeF-style export', () {
    test('mirrors 1040 lines without transmitting anything', () {
      final d = TaxReturnData(taxYear: 2025)
        ..w2s.add(W2Entry(employerName: 'Acme', wages: 60000, federalWithholding: 5500));
      final r = engine.compute(d, params2025);
      final mef = const MeFExporter().export(d, r);
      expect(mef['documentSystem'], 'NitroNissi-eFileReady-JSON');
      final f1040 = mef['form1040'] as Map;
      expect(f1040['line1a_wages'], 60000);
      expect(f1040['line11_adjustedGrossIncome'], 60000);
    });
  });
}
