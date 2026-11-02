/// Review — Direct File's "check your answers" pattern: grouped summary of
/// everything entered, with jump-to-edit and issue list before results.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../core/tax/validation.dart';
import '../widgets/common.dart';
import 'interview.dart';
import 'results.dart';

class ReviewScreen extends StatelessWidget {
  final AppState state;
  const ReviewScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final r = state.result;
    final issues = state.issues;

    final rows = <(String, double)>[
      (loc.rowWages, r.wages),
      (loc.rowSeIncome, r.seNet),
      (loc.rowInterest, r.taxableInterest),
      (loc.rowDividends, r.ordinaryDividends),
      (loc.rowCapGains, r.netShortTermGain + r.netLongTermGain),
      (loc.rowRetirement, r.retirementTaxable),
      (loc.rowSs, r.socialSecurityTaxable),
      (loc.rowUnemployment, r.unemployment),
      (loc.rowOther, r.otherIncome),
      (loc.rowTotalIncome, r.totalIncome),
      (loc.rowAgi, r.agi),
      (r.deductionUsed == r.itemizedDeductionUsed
          ? loc.rowItemized
          : loc.rowStandard, r.deductionUsed),
      if (r.qbiDeduction > 0) (loc.rowQbi, -r.qbiDeduction),
      if (r.seniorDeduction > 0) (loc.rowSenior, -r.seniorDeduction),
      (loc.rowTaxableIncome, r.taxableIncome),
      (loc.rowTax, r.ordinaryTax + r.preferentialTax),
      if (r.seTax > 0) (loc.rowSeTax, r.seTax),
      if (r.ctcTotal > 0) (loc.rowCtc, r.ctcTotal),
      if (r.childCareCredit > 0) (loc.rowCare, r.childCareCredit),
      if (r.aotcNonrefundable + r.aotcRefundable > 0)
        (loc.rowAotc, r.aotcNonrefundable + r.aotcRefundable),
      if (r.llcCredit > 0) (loc.rowLlc, r.llcCredit),
      if (r.saversCredit > 0) (loc.rowSavers, r.saversCredit),
      if (r.eitc > 0) (loc.rowEitc, r.eitc),
      if (r.totalPayments > 0) (loc.rowPayments, r.totalPayments),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(loc.reviewTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final i in issues)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SeverityBanner(
                isError: i.severity == IssueSeverity.error,
                isWarning: i.severity == IssueSeverity.warning,
                message: _issueText(loc, i),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(row.$1)),
                          Text(money(row.$2)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => InterviewScreen(state: state, topicId: 'personal'))),
                icon: const Icon(Icons.edit),
                label: Text(loc.editAnswers),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ResultsScreen(state: state))),
                icon: const Icon(Icons.arrow_forward),
                label: Text(loc.seeResults),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _issueText(AppLocalizations loc, Issue i) {
    // Map message keys to l10n strings; fall back to the raw key + detail.
    switch (i.messageKey) {
      case 'issueMissingSpouse':
        return loc.issueMissingSpouse;
      case 'issueMfsLimits':
        return loc.issueMfsLimits;
      case 'issueMissingSsn':
        return loc.issueMissingSsn;
      case 'issueDependentSsn':
        return loc.issueDependentSsn;
      case 'issueDependentDob':
        return loc.issueDependentDob;
      case 'issueW2Employer':
        return loc.issueW2Employer;
      case 'issueW2NoWithholding':
        return loc.issueW2NoWithholding;
      case 'issueSeTax':
        return loc.issueSeTax;
      case 'issueObbbaOnly2025':
        return loc.issueObbbaOnly2025;
      default:
        return i.detail.isEmpty ? i.messageKey : '${i.messageKey}: ${i.detail}';
    }
  }
}
