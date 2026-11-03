import 'package:clearfile/models/dependent.dart';
import 'package:clearfile/models/filing_status.dart';
import 'package:clearfile/models/tax_return.dart';
import 'package:clearfile/models/w2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('JSON roundtrip preserves every field', () {
    final original = TaxReturnData(
      id: 'roundtrip',
      displayName: 'Test Return',
      taxYear: 2025,
      filingStatus: FilingStatus.headOfHousehold,
      taxpayer65OrOlder: true,
      spouse65OrOlder: false,
      taxpayerBlind: true,
      spouseBlind: false,
      w2s: [
        W2Entry(employer: 'Emp', wages: 1000.5, withholding: 100.25),
        W2Entry(employer: 'Emp2', wages: 2000, withholding: 200),
      ],
      interestIncome: 12.5,
      ordinaryDividends: 3,
      qualifiedDividends: 4.5,
      longTermCapitalGains: 100,
      otherIncome: 7,
      studentLoanInterest: 1200,
      deductionMethod: DeductionMethod.itemized,
      stateLocalIncomeOrSalesTax: 5000,
      realEstateTax: 3000,
      mortgageInterest: 8000,
      charitableCash: 500,
      charitableNonCash: 200,
      estimatedPayments: 1000,
      dependents: [
        Dependent(
            name: 'A', age: 5, relationship: 'child', qualifyingChild: true),
        Dependent(name: 'B', age: 70, relationship: 'parent',
            otherDependentCredit: true),
      ],
      created: DateTime.utc(2026, 1, 15),
      modified: DateTime.utc(2026, 2, 20),
    );

    final json = original.toJson();
    expect(json['format'], 'clearfile.return');
    expect(json['formatVersion'], 1);

    final restored = TaxReturnData.fromJson(Map<String, dynamic>.from(json));

    expect(restored.id, original.id);
    expect(restored.displayName, original.displayName);
    expect(restored.taxYear, original.taxYear);
    expect(restored.filingStatus, original.filingStatus);
    expect(restored.taxpayer65OrOlder, true);
    expect(restored.spouse65OrOlder, false);
    expect(restored.taxpayerBlind, true);
    expect(restored.spouseBlind, false);
    expect(restored.w2s, original.w2s);
    expect(restored.interestIncome, original.interestIncome);
    expect(restored.ordinaryDividends, original.ordinaryDividends);
    expect(restored.qualifiedDividends, original.qualifiedDividends);
    expect(restored.longTermCapitalGains, original.longTermCapitalGains);
    expect(restored.otherIncome, original.otherIncome);
    expect(restored.studentLoanInterest, original.studentLoanInterest);
    expect(restored.deductionMethod, original.deductionMethod);
    expect(restored.stateLocalIncomeOrSalesTax, original.stateLocalIncomeOrSalesTax);
    expect(restored.realEstateTax, original.realEstateTax);
    expect(restored.mortgageInterest, original.mortgageInterest);
    expect(restored.charitableCash, original.charitableCash);
    expect(restored.charitableNonCash, original.charitableNonCash);
    expect(restored.estimatedPayments, original.estimatedPayments);
    expect(restored.dependents, original.dependents);
    expect(restored.created, original.created);
    expect(restored.modified, original.modified);
  });

  test('fromJson tolerates missing optional fields', () {
    final restored = TaxReturnData.fromJson({'id': 'x'});
    expect(restored.filingStatus, FilingStatus.single);
    expect(restored.w2s, isEmpty);
    expect(restored.dependents, isEmpty);
    expect(restored.deductionMethod, DeductionMethod.auto);
    expect(restored.taxYear, 2025);
    expect(restored.totalIncome, 0);
  });

  test('derived totals aggregate W-2s', () {
    final r = TaxReturnData(
      w2s: [
        W2Entry(employer: 'A', wages: 100, withholding: 10),
        W2Entry(employer: 'B', wages: 200, withholding: 20),
      ],
      interestIncome: 5,
    );
    expect(r.totalWages, 300);
    expect(r.totalWithholding, 30);
    expect(r.totalIncome, 305);
  });
}
