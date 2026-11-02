/// Return validation — friendly issue detection before results/export.
library;

import 'model.dart';

enum IssueSeverity { info, warning, error }

class Issue {
  final IssueSeverity severity;
  final String messageKey; // l10n key
  final String detail; // raw detail for developer / AI context
  const Issue(this.severity, this.messageKey, [this.detail = '']);
}

class Validator {
  const Validator();

  List<Issue> validate(TaxReturnData d) {
    final issues = <Issue>[];
    final needsSpouse = d.filingStatus == FilingStatus.marriedJointly ||
        d.filingStatus == FilingStatus.marriedSeparately ||
        d.filingStatus == FilingStatus.qualifyingSurvivingSpouse;
    if (needsSpouse && (d.spouse == null || d.spouse!.firstName.isEmpty)) {
      issues.add(const Issue(
          IssueSeverity.error, 'issueMissingSpouse', 'filing status requires spouse'));
    }
    if (d.filingStatus == FilingStatus.marriedSeparately) {
      issues.add(const Issue(IssueSeverity.info, 'issueMfsLimits',
          'MFS is not eligible for EITC, education credits or the senior deduction'));
    }
    if (d.taxpayer.ssn.isEmpty) {
      issues.add(const Issue(IssueSeverity.error, 'issueMissingSsn', 'taxpayer SSN'));
    }
    for (final dep in d.dependents) {
      if (dep.ssn.isEmpty) {
        issues.add(Issue(IssueSeverity.warning, 'issueDependentSsn',
            'dependent ${dep.firstName} ${dep.lastName} has no SSN'));
      }
      if (dep.dateOfBirth == null) {
        issues.add(Issue(IssueSeverity.warning, 'issueDependentDob',
            'dependent ${dep.firstName} ${dep.lastName} has no date of birth'));
      }
    }
    for (final w in d.w2s) {
      if (w.employerName.isEmpty) {
        issues.add(const Issue(IssueSeverity.warning, 'issueW2Employer', 'W-2 employer name'));
      }
      if (w.wages > 0 && w.federalWithholding <= 0) {
        issues.add(Issue(
            IssueSeverity.info, 'issueW2NoWithholding', 'no federal withholding for ${w.employerName}'));
      }
    }
    if (d.selfEmployment.any((s) => s.netProfit > 400)) {
      issues.add(const Issue(IssueSeverity.info, 'issueSeTax',
          'self-employment income triggers Schedule SE (estimated taxes may apply)'));
    }
    if (d.dependents.where((x) => x.isCtcEligible(d.taxYear)).length > 0 &&
        d.socialSecurityBenefits > 0) {
      // informational only
    }
    if (d.w2s.any((w) => w.qualifiedOvertime > 0 || w.qualifiedTips > 0) && d.taxYear < 2025) {
      issues.add(const Issue(IssueSeverity.warning, 'issueObbbaOnly2025',
          'tips/overtime deductions apply to tax year 2025-2028 only'));
    }
    return issues;
  }
}
