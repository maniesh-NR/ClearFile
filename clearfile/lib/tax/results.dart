import '../models/tax_return.dart';

/// One row of the Form-1040-style summary shown on the Results screen.
class SummaryLine {
  const SummaryLine(this.label, this.value, {this.emphasis = false});

  final String label;
  final double value;
  final bool emphasis;
}

/// Outcome of running [TaxCalculator.compute]. Pure data; formatting and
/// rounding happen in the UI layer.
class TaxResult {
  const TaxResult({
    required this.totalIncome,
    required this.studentLoanDeduction,
    required this.agi,
    required this.basicStandardDeduction,
    required this.additionalStandardDeduction,
    required this.seniorDeduction,
    required this.standardDeductionTotal,
    required this.saltPaid,
    required this.saltCap,
    required this.saltAllowed,
    required this.itemizedDeductionTotal,
    required this.deductionMethodUsed,
    required this.deductionUsed,
    required this.taxableIncome,
    required this.ordinaryTax,
    required this.preferentialIncome,
    required this.preferentialTax,
    required this.niit,
    required this.nonRefundableCredits,
    required this.refundableCredits,
    required this.totalTax,
    required this.totalPayments,
    required this.refund,
    required this.amountOwed,
    required this.effectiveRate,
    required this.marginalRate,
    required this.qualifyingChildren,
    required this.lines,
  });

  final double totalIncome;
  final double studentLoanDeduction;
  final double agi;

  final double basicStandardDeduction;
  final double additionalStandardDeduction;
  final double seniorDeduction;
  final double standardDeductionTotal;

  final double saltPaid;
  final double saltCap;
  final double saltAllowed;
  final double itemizedDeductionTotal;

  final DeductionMethod deductionMethodUsed;
  final double deductionUsed;

  final double taxableIncome;
  final double ordinaryTax;
  final double preferentialIncome;
  final double preferentialTax;
  final double niit;

  final double nonRefundableCredits;
  final double refundableCredits;
  final double totalTax;
  final double totalPayments;

  final double refund;
  final double amountOwed;
  final double effectiveRate;
  final double marginalRate;
  final int qualifyingChildren;

  final List<SummaryLine> lines;

  bool get isRefund => refund > 0;

  /// Positive when a refund, negative when owed.
  double get refundOrOwed => refund - amountOwed;
}
