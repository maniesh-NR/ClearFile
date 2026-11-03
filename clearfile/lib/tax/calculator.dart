import 'dart:math';

import '../models/filing_status.dart';
import '../models/tax_return.dart';
import '../models/tax_year.dart';
import 'results.dart';

/// The ClearFile demo federal tax engine.
///
/// Implements a simplified, clearly-labelled TY2025 Form 1040 flow:
/// income -> adjustments -> (standard | itemized) deduction -> brackets with
/// qualified-dividend stacking -> NIIT -> CTC/ACTC/ODC -> payments.
///
/// THIS IS DEMONSTRATION SOFTWARE. It omits many real-return rules (see the
/// README "Engine limitations" section) and must not be used to file.
class TaxCalculator {
  const TaxCalculator();

  TaxResult compute(
    TaxReturnData r, {
    TaxYearParameters params = TaxYearParameters.ty2025,
  }) {
    final status = r.filingStatus;

    // ---- Income ----------------------------------------------------------
    final wages = r.totalWages;
    final totalIncome = r.totalIncome;

    // ---- Adjustments: student loan interest -------------------------------
    final sli = _studentLoanDeduction(
        r.studentLoanInterest, status, totalIncome, params);
    final agi = totalIncome - sli;

    // ---- Itemized (Schedule A-lite) ---------------------------------------
    final saltPaid = max(0.0, r.stateLocalIncomeOrSalesTax + r.realEstateTax);
    final saltCap = params.saltCapFor(status, agi);
    final saltAllowed = min(saltPaid, saltCap);
    final positiveAgi = max(0.0, agi);
    final charitableAllowed =
        min(r.charitableCash, params.charitableCashAgiLimit * positiveAgi) +
            min(r.charitableNonCash, params.charitableNonCashAgiLimit * positiveAgi);
    final itemizedRaw =
        max(0.0, saltAllowed + r.mortgageInterest + charitableAllowed);

    // ---- Senior deduction (OBBBA) -----------------------------------------
    final senior = _seniorDeduction(r, status, agi, params);

    // ---- Standard deduction ------------------------------------------------
    final basic = params.standardDeduction[status]!;
    final agedOrBlindPersons = _agedOrBlindCount(r);
    final additional =
        agedOrBlindPersons * params.additionalPerAgedOrBlindPerson[status]!;
    final standardTotal = basic + additional;

    final standardDeductionTotal = standardTotal + senior;
    final itemizedDeductionTotal = itemizedRaw + senior;

    // ---- Choose method -----------------------------------------------------
    final DeductionMethod used;
    switch (r.deductionMethod) {
      case DeductionMethod.standard:
        used = DeductionMethod.standard;
      case DeductionMethod.itemized:
        used = DeductionMethod.itemized;
      case DeductionMethod.auto:
        used = itemizedDeductionTotal > standardDeductionTotal
            ? DeductionMethod.itemized
            : DeductionMethod.standard;
    }
    final deductionUsed = used == DeductionMethod.itemized
        ? itemizedDeductionTotal
        : standardDeductionTotal;

    // ---- Taxable income -----------------------------------------------------
    final taxable = max(0.0, agi - deductionUsed);

    // ---- Tax with qualified dividend / LTCG stacking -------------------------
    final preferentialIncome =
        min(max(0.0, r.qualifiedDividends + r.longTermCapitalGains), taxable);
    final ordinaryTaxable = taxable - preferentialIncome;
    final ordinaryTax = _bracketTax(ordinaryTaxable, params.ordinaryBrackets[status]!);

    final zeroCap = params.qdiZeroCap[status]!;
    final fifteenCap = params.qdiFifteenCap[status]!;
    var preferentialRemaining = preferentialIncome;
    final zeroRoom = max(0.0, zeroCap - ordinaryTaxable);
    final atZeroRate = min(preferentialRemaining, zeroRoom);
    preferentialRemaining -= atZeroRate;
    final fifteenRoom = max(0.0, fifteenCap - max(ordinaryTaxable, zeroCap));
    final atFifteenRate = min(preferentialRemaining, fifteenRoom);
    preferentialRemaining -= atFifteenRate;
    final preferentialTax = 0.15 * atFifteenRate + 0.20 * preferentialRemaining;

    // ---- Net investment income tax (simplified) -------------------------------
    final investmentIncome = max(
        0.0,
        r.interestIncome +
            r.ordinaryDividends +
            r.qualifiedDividends +
            r.longTermCapitalGains);
    final niitThreshold = params.niitThreshold[status]!;
    final niit = agi > niitThreshold
        ? params.niitRate * min(investmentIncome, agi - niitThreshold)
        : 0.0;

    // ---- Credits -----------------------------------------------------------
    final kids = r.dependents.where((d) => d.qualifyingChild).length;
    final otherDependents =
        r.dependents.where((d) => d.otherDependentCredit).length;
    final ctcPhaseoutStart = params.ctcPhaseoutStart[status]!;
    final excessAgi = max(0.0, agi - ctcPhaseoutStart);
    final grossCtc = kids * params.ctcPerChild;
    final grossOdc = otherDependents * params.odcPerDependent;
    final phasedCtc = max(0.0, grossCtc - params.ctcPhaseoutRate * excessAgi);
    final phasedOdc = max(0.0, grossOdc - params.ctcPhaseoutRate * excessAgi);

    final taxBeforeCredits = ordinaryTax + preferentialTax;
    final nonRefundableCredits = min(phasedCtc + phasedOdc, taxBeforeCredits);

    // Refundable ACTC (simplified): 15% of earned income above the floor,
    // capped at the per-child refundable amount.
    final earnedIncome = wages;
    final remainingCtc = max(0.0, phasedCtc - nonRefundableCredits);
    final refundableCredits = min(
      remainingCtc,
      min(
        params.actcPerChild * kids,
        params.actcRate * max(0.0, earnedIncome - params.actcEarnedIncomeFloor),
      ),
    );

    // Refundable credits are paid out like withholding (1040 payments side).
    final totalTax = max(0.0, taxBeforeCredits - nonRefundableCredits + niit);

    // ---- Payments ------------------------------------------------------------
    final payments = r.totalWithholding + r.estimatedPayments;
    final refund = max(0.0, payments + refundableCredits - totalTax);
    final owed = max(0.0, totalTax - payments - refundableCredits);

    final effectiveRate = agi > 0 ? totalTax / agi : 0.0;
    final marginalRate =
        _marginalRate(ordinaryTaxable, params.ordinaryBrackets[status]!);

    return TaxResult(
      totalIncome: totalIncome,
      studentLoanDeduction: sli,
      agi: agi,
      basicStandardDeduction: basic,
      additionalStandardDeduction: additional,
      seniorDeduction: senior,
      standardDeductionTotal: standardDeductionTotal,
      saltPaid: saltPaid,
      saltCap: saltCap,
      saltAllowed: saltAllowed,
      itemizedDeductionTotal: itemizedDeductionTotal,
      deductionMethodUsed: used,
      deductionUsed: deductionUsed,
      taxableIncome: taxable,
      ordinaryTax: ordinaryTax,
      preferentialIncome: preferentialIncome,
      preferentialTax: preferentialTax,
      niit: niit,
      nonRefundableCredits: nonRefundableCredits,
      refundableCredits: refundableCredits,
      totalTax: totalTax,
      totalPayments: payments,
      refund: refund,
      amountOwed: owed,
      effectiveRate: effectiveRate,
      marginalRate: marginalRate,
      qualifyingChildren: kids,
      lines: _buildLines(
        r: r,
        sli: sli,
        totalIncome: totalIncome,
        agi: agi,
        used: used,
        deductionUsed: deductionUsed,
        standardDeductionTotal: standardDeductionTotal,
        itemizedDeductionTotal: itemizedDeductionTotal,
        taxable: taxable,
        ordinaryTax: ordinaryTax,
        preferentialTax: preferentialTax,
        niit: niit,
        nonRefundableCredits: nonRefundableCredits,
        refundableCredits: refundableCredits,
        totalTax: totalTax,
        payments: payments,
        refund: refund,
        owed: owed,
      ),
    );
  }

  /// MAGI for the student loan interest deduction is computed before the
  /// deduction itself, so we pass total income.
  double _studentLoanDeduction(
    double paid,
    FilingStatus status,
    double magi,
    TaxYearParameters params,
  ) {
    final capped = min(paid, params.studentLoanMax);
    if (capped <= 0) return 0;
    final start = params.studentLoanPhaseoutStart[status]!;
    final end = params.studentLoanPhaseoutEnd[status]!;
    if (end <= start) return 0; // MFS: not eligible.
    if (magi <= start) return capped;
    if (magi >= end) return 0;
    return capped * (end - magi) / (end - start);
  }

  double _seniorDeduction(
    TaxReturnData r,
    FilingStatus status,
    double agi,
    TaxYearParameters params,
  ) {
    final seniorPersons = (r.taxpayer65OrOlder ? 1 : 0) +
        (r.spouse65OrOlder && r.hasSpouse ? 1 : 0);
    if (seniorPersons == 0) return 0;
    final start = params.seniorPhaseoutStart[status]!;
    final per = params.seniorDeductionPerPerson;
    if (agi <= start) return per * seniorPersons;
    final phasedPer = per - params.seniorPhaseoutRate * (agi - start);
    return max(0.0, phasedPer) * seniorPersons;
  }

  int _agedOrBlindCount(TaxReturnData r) =>
      (r.taxpayer65OrOlder ? 1 : 0) +
      (r.taxpayerBlind ? 1 : 0) +
      ((r.spouse65OrOlder || r.spouseBlind) && r.hasSpouse ? 1 : 0);

  double _bracketTax(double income, List<Bracket> brackets) {
    var tax = 0.0;
    var lowerBound = 0.0;
    for (final b in brackets) {
      if (income <= lowerBound) break;
      final upper = min(income, b.upTo);
      tax += (upper - lowerBound) * b.rate;
      lowerBound = b.upTo;
    }
    return tax;
  }

  double _marginalRate(double income, List<Bracket> brackets) {
    var lowerBound = 0.0;
    for (final b in brackets) {
      if (income <= lowerBound) return brackets.first.rate;
      if (income <= b.upTo) return b.rate;
      lowerBound = b.upTo;
    }
    return brackets.last.rate;
  }

  List<SummaryLine> _buildLines({
    required TaxReturnData r,
    required double sli,
    required double totalIncome,
    required double agi,
    required DeductionMethod used,
    required double deductionUsed,
    required double standardDeductionTotal,
    required double itemizedDeductionTotal,
    required double taxable,
    required double ordinaryTax,
    required double preferentialTax,
    required double niit,
    required double nonRefundableCredits,
    required double refundableCredits,
    required double totalTax,
    required double payments,
    required double refund,
    required double owed,
  }) {
    return [
      SummaryLine('Total income', totalIncome),
      if (sli > 0) SummaryLine('Student loan interest deduction', -sli),
      SummaryLine('Adjusted gross income', agi, emphasis: true),
      SummaryLine('Standard deduction (incl. additions + senior)', standardDeductionTotal),
      SummaryLine('Itemized deductions (after SALT cap)', itemizedDeductionTotal),
      SummaryLine(
        used == DeductionMethod.itemized
            ? 'Deduction used - itemized'
            : 'Deduction used - standard',
        -deductionUsed,
      ),
      SummaryLine('Taxable income', taxable, emphasis: true),
      SummaryLine('Tax on ordinary income', ordinaryTax),
      if (preferentialTax > 0)
        SummaryLine('Tax on qualified dividends & long-term gains', preferentialTax),
      if (niit > 0) SummaryLine('Net investment income tax', niit),
      if (nonRefundableCredits > 0)
        SummaryLine('Non-refundable credits', -nonRefundableCredits),
      SummaryLine('Total tax', totalTax, emphasis: true),
      SummaryLine('Federal income tax withheld', r.totalWithholding),
      if (r.estimatedPayments > 0)
        SummaryLine('Estimated payments', r.estimatedPayments),
      if (refundableCredits > 0)
        SummaryLine('Additional child tax credit (refundable)', refundableCredits),
      SummaryLine('Total payments', payments),
      if (refund > 0) SummaryLine('Refund', refund, emphasis: true),
      if (owed > 0) SummaryLine('Amount you owe', owed, emphasis: true),
    ];
  }
}
