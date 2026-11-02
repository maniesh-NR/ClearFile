/// E-file-ready export: a MeF-style JSON layout for future transmission work.
///
/// HONESTY NOTE (docs/SCOPE.md): real IRS e-filing requires an approved
/// Electronic Return Originator (ERO) enrollment, a Transmission Control
/// Code, and the actual MeF XML schemas. This exporter produces a JSON
/// structure that mirrors MeF concepts (return header + form field sets) so
/// the data is portable and ready for a future certified pipeline. It is NOT
/// accepted by the IRS and is never transmitted by Nitro Nissi.
library;

import '../tax/model.dart';
import '../tax/engine.dart';

class MeFExporter {
  const MeFExporter();

  Map<String, dynamic> export(TaxReturnData d, TaxResult r) {
    return {
      'documentSystem': 'NitroNissi-eFileReady-JSON',
      'note':
          'Mirrors IRS MeF (Modernized e-File) concepts for interoperability planning. Not accepted or transmitted by the IRS.',
      'schemaYear': '${d.taxYear}v',
      'returnHeader': {
        'taxYear': d.taxYear,
        'taxPeriodEndDate': '${d.taxYear}-12-31',
        'filingStatus': _fsCode(d.filingStatus),
        'taxpayer': _person(d.taxpayer),
        if (d.spouse != null) 'spouse': _person(d.spouse!),
        'dependents': d.dependents.map((dep) => _dependent(dep, d.taxYear)).toList(),
      },
      'form1040': {
        // Income
        'line1a_wages': r.wages,
        'line1z_totalIncome': r.wages + r.seNet + r.taxableInterest + r.ordinaryDividends +
            r.retirementTaxable + r.socialSecurityTaxable + r.unemployment + r.otherIncome -
            r.capitalLossDeduction + _max(0, r.netShortTermGain + r.netLongTermGain),
        'line2a_taxableInterest': r.taxableInterest,
        'line2b_taxExemptInterest': r.taxExemptInterest,
        'line3a_qualifiedDividends': r.qualifiedDividends,
        'line3b_ordinaryDividends': r.ordinaryDividends,
        'line7_capitalGain': _max(0, r.netShortTermGain + r.netLongTermGain),
        'line8_additionalIncome': r.unemployment + r.otherIncome,
        'line9_totalIncome': r.totalIncome,
        // Adjustments
        'line10_adjustments': r.halfSeTaxDeduction +
            r.iraDeduction +
            r.studentLoanInterestDeduction +
            r.hsaDeduction +
            r.educatorDeduction +
            r.seHealthDeduction +
            r.seSepDeduction +
            r.obbbaTipsDeduction +
            r.obbbaOvertimeDeduction +
            r.obbbaCarLoanDeduction,
        'line11_adjustedGrossIncome': r.agi,
        // Deduction
        'line12_standardOrItemized': r.deductionUsed,
        'line12d_qualifiedBusinessIncome': r.qbiDeduction,
        'line13_seniorDeduction': r.seniorDeduction,
        'line14_taxableIncome': r.taxableIncome,
        // Tax
        'line16_tax': r.ordinaryTax + r.preferentialTax,
        // Credits
        'line19_childTaxCredit': r.ctcNonrefundable,
        'line20_schedule3Credits': r.childCareCredit + r.aotcNonrefundable + r.llcCredit + r.saversCredit,
        'line22_totalCredits': r.totalNonrefundableCredits,
        // Other taxes
        'line23_otherTaxes': r.seTax + r.niit + r.additionalMedicareTax,
        'line24_totalTax': r.totalTax,
        // Payments
        'line25a_federalWithheld': r.totalPayments - _estimates(d),
        'line26_estimatedPayments': _estimates(d),
        'line33_totalPayments': r.totalPayments,
        // Refundable credits
        'line27_eitc': r.eitc,
        'line28_actc': r.ctcRefundable,
        'line29_aotcRefundable': r.aotcRefundable,
        'line34_refund': r.isRefund ? r.refundOrOwe : 0.0,
        'line37_amountOwed': r.isRefund ? 0.0 : -r.refundOrOwe,
      },
      'worksheets': {
        'preferentialRates': {
          'qualifiedDividends': r.qualifiedDividends,
          'netLongTermGain': r.netLongTermGain,
          'ordinaryTax': r.ordinaryTax,
          'preferentialTax': r.preferentialTax,
        },
        'selfEmployment': {
          'netProfit': r.seNet,
          'netEarnings': r.seEarnings,
          'seTax': r.seTax,
        },
      },
      'engine': {
        'name': 'Nitro Nissi FederalEngine',
        'taxYearParameters': '${d.taxYear}',
        'computedAt': DateTime.now().toUtc().toIso8601String(),
      }
    };
  }

  double _estimates(TaxReturnData d) => d.adjustments.estimatedPayments;

  double _max(double a, double b) => a > b ? a : b;

  String _fsCode(FilingStatus s) {
    switch (s) {
      case FilingStatus.single:
        return 'Single';
      case FilingStatus.marriedJointly:
        return 'MarriedFilingJointly';
      case FilingStatus.marriedSeparately:
        return 'MarriedFilingSeparately';
      case FilingStatus.headOfHousehold:
        return 'HeadOfHousehold';
      case FilingStatus.qualifyingSurvivingSpouse:
        return 'QualifyingSurvivingSpouse';
    }
  }

  Map<String, dynamic> _person(Person p) => {
        'firstName': p.firstName,
        'lastName': p.lastName,
        // Keep the SSN out of generic exports by default; the user can
        // complete it in the destination system.
        'ssnPresent': p.ssn.isNotEmpty,
      };

  Map<String, dynamic> _dependent(Dependent dep, int year) => {
        'firstName': dep.firstName,
        'lastName': dep.lastName,
        'relationship': dep.relationship,
        'birthYear': dep.dateOfBirth?.year,
        'ctcEligible': dep.isCtcEligible(year),
        'eitcQualifying': dep.isEitcQualifyingChild(year),
      };
}
