import 'package:clearfile/models/dependent.dart';
import 'package:clearfile/models/filing_status.dart';
import 'package:clearfile/models/tax_return.dart';
import 'package:clearfile/models/w2.dart';
import 'package:clearfile/tax/calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-computed expected values for the TY2025 demo engine.
///
/// Every expectation below was derived manually from the published TY2025
/// parameters (OBBBA standard deduction, Rev. Proc. 2024-40 brackets, QDI
/// worksheet breakpoints) before being encoded here, so a regression in the
/// engine shows up as a mismatch against an independent calculation.
void main() {
  const calc = TaxCalculator();

  TaxReturnData ret({
    FilingStatus status = FilingStatus.single,
    double wages = 0,
    double withholding = 0,
    double interest = 0,
    double ordinaryDividends = 0,
    double qualifiedDividends = 0,
    double ltcg = 0,
    double sli = 0,
    double saltIncome = 0,
    double realEstate = 0,
    double mortgage = 0,
    double charityCash = 0,
    bool taxpayer65 = false,
    bool spouse65 = false,
    List<Dependent> dependents = const [],
  }) =>
      TaxReturnData(
        filingStatus: status,
        taxpayer65OrOlder: taxpayer65,
        spouse65OrOlder: spouse65,
        w2s: [
          W2Entry(employer: 'Test Employer', wages: wages, withholding: withholding)
        ],
        interestIncome: interest,
        ordinaryDividends: ordinaryDividends,
        qualifiedDividends: qualifiedDividends,
        longTermCapitalGains: ltcg,
        studentLoanInterest: sli,
        stateLocalIncomeOrSalesTax: saltIncome,
        realEstateTax: realEstate,
        mortgageInterest: mortgage,
        charitableCash: charityCash,
        dependents: dependents,
      );

  test('Single filer, wages only, standard deduction', () {
    final r = calc.compute(ret(wages: 50000, withholding: 6200));
    expect(r.agi, 50000);
    expect(r.deductionUsed, 15750);
    expect(r.taxableIncome, 34250);
    // 1192.50 + 12% of (34250 - 11925)
    expect(r.ordinaryTax, closeTo(3871.50, 0.01));
    expect(r.totalTax, closeTo(3871.50, 0.01));
    expect(r.refund, closeTo(2328.50, 0.01));
    expect(r.amountOwed, 0);
    expect(r.marginalRate, closeTo(0.12, 1e-9));
    expect(r.effectiveRate, closeTo(0.07743, 0.0001));
  });

  test('MFJ, both spouses 65+: aged + OBBBA senior deduction', () {
    final r = calc.compute(
        ret(status: FilingStatus.marriedJoint, wages: 80000, taxpayer65: true, spouse65: true));
    expect(r.additionalStandardDeduction, 3200); // 2 x 1600
    expect(r.seniorDeduction, 12000); // 2 x 6000, AGI below 150k start
    expect(r.standardDeductionTotal, 46700);
    expect(r.taxableIncome, 33300);
    // 2385 + 12% of (33300 - 23850)
    expect(r.totalTax, closeTo(3519.00, 0.01));
  });

  test('Single senior hits the 6% senior-deduction phase-out', () {
    final r = calc.compute(ret(wages: 90000, taxpayer65: true));
    // 6000 - 6% of (90000 - 75000)
    expect(r.seniorDeduction, closeTo(5100, 0.01));
    expect(r.additionalStandardDeduction, 2000);
    expect(r.deductionUsed, closeTo(22850, 0.01));
    expect(r.taxableIncome, closeTo(67150, 0.01));
    // 1192.50 + 4386 + 22% of (67150 - 48475)
    expect(r.totalTax, closeTo(9687.00, 0.01));
  });

  test('Auto mode picks standard when itemized is smaller', () {
    final r = calc.compute(ret(
      status: FilingStatus.marriedJoint,
      wages: 120000,
      saltIncome: 12000,
      realEstate: 6000,
      mortgage: 9000,
      charityCash: 2000,
    ));
    expect(r.saltCap, 40000); // AGI 120k below 500k phase-down start
    expect(r.saltAllowed, 18000);
    expect(r.itemizedDeductionTotal, 29000);
    expect(r.deductionMethodUsed, DeductionMethod.standard);
    expect(r.deductionUsed, 31500);
  });

  test('Auto mode picks itemized when larger', () {
    final r = calc.compute(ret(
      status: FilingStatus.marriedJoint,
      wages: 120000,
      saltIncome: 20000,
      realEstate: 5000,
      mortgage: 9000,
      charityCash: 2000,
    ));
    expect(r.itemizedDeductionTotal, 36000);
    expect(r.deductionMethodUsed, DeductionMethod.itemized);
    expect(r.deductionUsed, 36000);
  });

  test('SALT 30% phase-down matches the published MFJ 550k example', () {
    final r = calc.compute(ret(status: FilingStatus.marriedJoint, wages: 550000));
    // 40000 - 30% of (550000 - 500000) = 25000
    expect(r.saltCap, 25000);
  });

  test('SALT floor for MFS', () {
    final r = calc.compute(
        ret(status: FilingStatus.marriedSeparate, wages: 300000, saltIncome: 10000));
    // 20000 - 30% of (300000 - 250000) = 5000 (floor)
    expect(r.saltCap, 5000);
    expect(r.saltAllowed, 5000);
  });

  test('Qualified dividends fill the 0% band first', () {
    final r = calc.compute(ret(
      wages: 30000,
      ordinaryDividends: 10000,
      qualifiedDividends: 10000,
    ));
    expect(r.taxableIncome, 34250);
    expect(r.preferentialIncome, 10000);
    expect(r.preferentialTax, 0); // all inside the 0% band
    // Ordinary taxable 24250: 1192.50 + 12% of (24250 - 11925)
    expect(r.ordinaryTax, closeTo(2671.50, 0.01));
    expect(r.niit, 0); // AGI 50k below the 200k threshold
    expect(r.totalTax, closeTo(2671.50, 0.01));
  });

  test('Qualified dividends at 15% plus NIIT', () {
    final r = calc.compute(ret(wages: 220000, qualifiedDividends: 50000));
    expect(r.agi, 270000);
    expect(r.taxableIncome, 254250);
    expect(r.preferentialTax, closeTo(7500, 0.01)); // 15% of 50000
    // Brackets: 1192.50 + 4386 + 12072.50 + 22548 + 32% of 6950
    expect(r.ordinaryTax, closeTo(42423.00, 0.01));
    // NIIT: 3.8% of min(50000 NII, 70000 excess MAGI)
    expect(r.niit, closeTo(1900, 0.01));
    expect(r.totalTax, closeTo(51823.00, 0.01));
    expect(r.marginalRate, closeTo(0.32, 1e-9));
  });

  test('CTC fully non-refundable for typical MFJ family', () {
    final kids = List.generate(
        2, (i) => Dependent(name: 'Kid $i', age: 8, relationship: 'child', qualifyingChild: true));
    final r = calc.compute(
        ret(status: FilingStatus.marriedJoint, wages: 90000, dependents: kids));
    expect(r.qualifyingChildren, 2);
    // 2385 + 12% of (58500 - 23850)
    final taxBefore = 6543.00;
    expect(r.ordinaryTax, closeTo(taxBefore, 0.01));
    expect(r.nonRefundableCredits, closeTo(4400, 0.01));
    expect(r.refundableCredits, 0);
    expect(r.totalTax, closeTo(2143.00, 0.01));
  });

  test('CTC phases out above 400k MFJ', () {
    final kids = List.generate(
        2, (i) => Dependent(name: 'Kid $i', age: 8, relationship: 'child', qualifyingChild: true));
    final r = calc.compute(
        ret(status: FilingStatus.marriedJoint, wages: 410000, dependents: kids));
    // 4400 - 5% of 10000
    expect(r.nonRefundableCredits, closeTo(3900, 0.01));
  });

  test('ACTC pays out with zero tax liability', () {
    final kid = Dependent(name: 'Kid', age: 6, relationship: 'child', qualifyingChild: true);
    final r = calc.compute(ret(wages: 12000, dependents: [kid]));
    expect(r.totalTax, 0);
    // min(2200, 1700, 15% of (12000 - 2500))
    expect(r.refundableCredits, closeTo(1425, 0.01));
    expect(r.refund, closeTo(1425, 0.01));
  });

  test('Student loan interest phase-out (single)', () {
    final r = calc.compute(ret(wages: 92000, sli: 2500));
    // 2500 * (100000 - 92000) / 15000
    expect(r.studentLoanDeduction, closeTo(1333.3333, 0.01));
    expect(r.agi, closeTo(90666.6667, 0.01));
  });

  test('Student loan interest unavailable to MFS', () {
    final r = calc.compute(
        ret(status: FilingStatus.marriedSeparate, wages: 50000, sli: 2000));
    expect(r.studentLoanDeduction, 0);
  });

  test('Charitable deduction capped at 60% of AGI', () {
    final r = calc.compute(ret(wages: 10000, charityCash: 20000));
    expect(r.itemizedDeductionTotal, closeTo(6000, 0.01));
    // Standard deduction still wins.
    expect(r.deductionMethodUsed, DeductionMethod.standard);
  });

  test('Zero-income return produces zeroes', () {
    final r = calc.compute(TaxReturnData());
    expect(r.agi, 0);
    expect(r.taxableIncome, 0);
    expect(r.totalTax, 0);
    expect(r.refund, 0);
    expect(r.amountOwed, 0);
    expect(r.effectiveRate, 0);
  });

  test('Qualifying surviving spouse uses the MFJ schedule', () {
    final kid = Dependent(name: 'Kid', age: 7, relationship: 'child', qualifyingChild: true);
    final a = calc.compute(ret(status: FilingStatus.survivingSpouse, wages: 90000, dependents: [kid]));
    final b = calc.compute(ret(status: FilingStatus.marriedJoint, wages: 90000, dependents: [kid]));
    expect(a.totalTax, b.totalTax);
    expect(a.standardDeductionTotal, b.standardDeductionTotal);
  });

  test('MFS 35% breakpoint at 375,800', () {
    // Taxable 380,000 for MFS: the slice between 250,525 and 375,800 is at 35%.
    final r = calc.compute(ret(status: FilingStatus.marriedSeparate, wages: 395750));
    expect(r.taxableIncome, 380000);
    final tax = r.ordinaryTax;
    // 1192.50 + 4386 + 12072.50 + 22548 + 32% of (250525-197300)
    //   + 35% of (375800-250525) + 37% of (380000-375800)
    final expected = 1192.50 +
        4386.00 +
        12072.50 +
        22548.00 +
        0.32 * 53225 +
        0.35 * 125275 +
        0.37 * 4200;
    expect(tax, closeTo(expected, 0.01));
  });

  test('Summary lines include the refundable credit on the payments side', () {
    final kid = Dependent(name: 'Kid', age: 6, relationship: 'child', qualifyingChild: true);
    final r = calc.compute(ret(wages: 12000, dependents: [kid]));
    final labels = r.lines.map((l) => l.label).toList();
    final totalTaxIndex = labels.indexOf('Total tax');
    final actcIndex =
        labels.indexOf('Additional child tax credit (refundable)');
    expect(totalTaxIndex, greaterThanOrEqualTo(0));
    expect(actcIndex, greaterThan(totalTaxIndex));
  });
}
