import '../models/tax_return.dart';
import '../util/money.dart';
import 'results.dart';

/// How serious a review finding is.
enum ReviewSeverity { info, suggestion, warning }

/// What the UI should do when the user acts on a finding. Deterministic
/// actions only - the AI assistant never triggers these directly.
enum ReviewActionKind {
  none,
  switchToItemized,
  switchToStandard,
  reviewIncome,
  reviewDeductions,
  reviewDependents,
}

class ReviewFinding {
  const ReviewFinding(
    this.severity,
    this.title,
    this.detail, [
    this.action = ReviewActionKind.none,
  ]);

  final ReviewSeverity severity;
  final String title;
  final String detail;
  final ReviewActionKind action;
}

/// Deterministic, offline, free review pass. Runs on every Review screen and
/// feeds both the UI cards and the AI review prompt.
List<ReviewFinding> runReview(TaxReturnData r, TaxResult res) {
  final f = <ReviewFinding>[];

  if (r.totalIncome == 0) {
    f.add(const ReviewFinding(
      ReviewSeverity.info,
      'No income entered yet',
      'Add your W-2 wages or other income and your results will update '
      'immediately.',
      ReviewActionKind.reviewIncome,
    ));
  }

  if (r.deductionMethod == DeductionMethod.standard &&
      res.itemizedDeductionTotal > res.standardDeductionTotal + 0.5) {
    f.add(ReviewFinding(
      ReviewSeverity.suggestion,
      'Itemizing could save you money',
      'Your itemized deductions (${_money(res.itemizedDeductionTotal)}) are '
      'larger than your standard deduction (${_money(res.standardDeductionTotal)}). '
      'Switching would reduce your taxable income by '
      '${_money(res.itemizedDeductionTotal - res.standardDeductionTotal)}.',
      ReviewActionKind.switchToItemized,
    ));
  }

  if (r.deductionMethod == DeductionMethod.itemized &&
      res.standardDeductionTotal > res.itemizedDeductionTotal + 0.5) {
    f.add(ReviewFinding(
      ReviewSeverity.suggestion,
      'The standard deduction is larger',
      'Your standard deduction (${_money(res.standardDeductionTotal)}) beats '
      'itemizing (${_money(res.itemizedDeductionTotal)}) this year.',
      ReviewActionKind.switchToStandard,
    ));
  }

  for (final w2 in r.w2s) {
    if (w2.withholding > w2.wages && w2.wages > 0) {
      f.add(ReviewFinding(
        ReviewSeverity.warning,
        'Withholding is larger than wages',
        '${w2.employer.isEmpty ? "A W-2" : w2.employer}: Box 2 '
        '(${_money(w2.withholding)}) is larger than Box 1 (${_money(w2.wages)}). '
        'Double-check which box each number came from.',
        ReviewActionKind.reviewIncome,
      ));
    }
  }

  if (r.totalWages > 0 && r.totalWithholding == 0) {
    f.add(const ReviewFinding(
      ReviewSeverity.info,
      'No federal withholding on file',
      'Your W-2s show wages but nothing in Box 2. If any tax was withheld, add '
      'it - otherwise expect to owe when you finish.',
      ReviewActionKind.reviewIncome,
    ));
  }

  for (final d in r.dependents) {
    if (d.name.trim().isEmpty) {
      f.add(const ReviewFinding(
        ReviewSeverity.warning,
        'A dependent is missing a name',
        'Every dependent needs a name so the return summary is complete.',
        ReviewActionKind.reviewDependents,
      ));
    }
    if (d.qualifyingChild && d.age >= 17) {
      f.add(ReviewFinding(
        ReviewSeverity.warning,
        'Child Tax Credit age check',
        '${d.name.isEmpty ? "A dependent" : d.name} is marked as a qualifying '
        'child but is 17 or older. Only children under 17 at the end of 2025 '
        'qualify for the $2,200 credit; they may still qualify for the $500 '
        'credit for other dependents.',
        ReviewActionKind.reviewDependents,
      ));
    }
    if (!d.qualifyingChild && !d.otherDependentCredit && d.name.isNotEmpty) {
      f.add(const ReviewFinding(
        ReviewSeverity.info,
        'Dependent without a credit type',
        'Mark whether each dependent is a qualifying child under 17 or '
        'qualifies for the $500 credit for other dependents.',
        ReviewActionKind.reviewDependents,
      ));
    }
  }

  if ((r.charitableCash > 0 || r.charitableNonCash > 0) &&
      r.deductionMethod == DeductionMethod.standard) {
    f.add(const ReviewFinding(
      ReviewSeverity.info,
      'Charitable gifts only count when you itemize',
      'You entered charitable contributions but chose the standard deduction. '
      'Consider comparing both methods - ClearFile can do that automatically.',
      ReviewActionKind.reviewDeductions,
    ));
  }

  if (r.studentLoanInterest > 2500) {
    f.add(const ReviewFinding(
      ReviewSeverity.info,
      'Student loan interest is capped',
      'Only up to $2,500 of student loan interest is deductible; the engine '
      'already applied the cap.',
      ReviewActionKind.reviewDeductions,
    ));
  }

  if (res.saltPaid > res.saltCap + 0.5) {
    f.add(ReviewFinding(
      ReviewSeverity.info,
      'State and local taxes exceeded the cap',
      'You paid ${_money(res.saltPaid)} of state and local taxes but the '
      '2025 cap for your income is ${_money(res.saltCap)}; only the capped '
      'amount can be deducted.',
      ReviewActionKind.reviewDeductions,
    ));
  }

  final seniorPersons =
      (r.taxpayer65OrOlder ? 1 : 0) + (r.spouse65OrOlder && r.hasSpouse ? 1 : 0);
  if (seniorPersons > 0 && res.seniorDeduction < 6000 * seniorPersons - 0.5) {
    f.add(ReviewFinding(
      ReviewSeverity.info,
      'Senior deduction is partially phased out',
      'The $6,000 senior deduction starts shrinking once income exceeds '
      '$75,000 ($150,000 married filing jointly). Yours is currently '
      '${_money(res.seniorDeduction)}.',
    ));
  }

  if (res.refund > 4000) {
    f.add(ReviewFinding(
      ReviewSeverity.info,
      'Large refund expected',
      'A refund over ${_money(4000)} usually means too much tax was withheld '
      'during the year. You could file a fresh W-4 to keep more of each '
      'paycheck.',
    ));
  }

  if (res.amountOwed > 4000) {
    f.add(ReviewFinding(
      ReviewSeverity.info,
      'Large balance due',
      'You appear to owe ${_money(res.amountOwed)}. Consider estimated '
      'payments or a W-4 adjustment to avoid penalties next year.',
    ));
  }

  return f;
}

String _money(double v) => formatMoney(v);
