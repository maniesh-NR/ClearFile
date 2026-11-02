/// The guided interview specification — TurboTax-style topic → page →
/// question flow, with Direct File-style plain-language helper text.
///
/// Specs are rebuilt per locale (cheap) and bind directly to [TaxReturnData]
/// through closures, so the renderer stays generic and type-safe.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../core/tax/model.dart';

enum FieldKind { text, ssn, money, number, date, choice, toggle }

enum PageKind { form, listW2, listDependents, listInterest, listDividends, listCapitalGains, listSe, listRetirement, listOther, review }

class ChoiceOption<T> {
  final T value;
  final String label;
  const ChoiceOption(this.value, this.label);
}

class FieldSpec {
  final String label;
  final String? hint;
  final FieldKind kind;
  final Object? Function(TaxReturnData d) get;
  final void Function(TaxReturnData d, Object? v) set;
  final List<ChoiceOption<String>>? choices;
  final String? info; // right-panel help text
  const FieldSpec({
    required this.label,
    required this.kind,
    required this.get,
    required this.set,
    this.hint,
    this.choices,
    this.info,
  });
}

class SectionSpec {
  final String title;
  final List<FieldSpec> fields;
  const SectionSpec(this.title, this.fields);
}

class PageSpec {
  final String id;
  final PageKind kind;
  final String title;
  final String? info;
  final List<SectionSpec> sections;
  const PageSpec.form(this.id, this.title, this.sections, {this.info})
      : kind = PageKind.form;
  const PageSpec.special(this.id, this.kind, this.title, {this.info, this.sections = const []});
}

class TopicSpec {
  final String id;
  final IconData icon;
  final String title;
  final List<PageSpec> pages;
  const TopicSpec(this.id, this.icon, this.title, this.pages);
}

String _s(Object? v) => v == null ? '' : v.toString();
double _d(Object? v) => (v is num) ? v.toDouble() : 0;
bool _b(Object? v) => v == true;

const _statusInfo = 'Your filing status sets your tax rates, standard '
    'deduction and which credits you can claim. Pick the status that matched '
    'your situation on December 31.';

List<TopicSpec> buildTopics(AppLocalizations loc) {
  return [
    TopicSpec('personal', Icons.person_outline, loc.topicPersonal, [
      PageSpec.form('status', loc.pagePersonalInfo, [
        SectionSpec(loc.secYourInfo, [
          FieldSpec(
            label: loc.fFirstName,
            kind: FieldKind.text,
            get: (d) => d.taxpayer.firstName,
            set: (d, v) => d.taxpayer.firstName = _s(v),
            info: loc.infoYourName,
          ),
          FieldSpec(
            label: loc.fLastName,
            kind: FieldKind.text,
            get: (d) => d.taxpayer.lastName,
            set: (d, v) => d.taxpayer.lastName = _s(v),
          ),
          FieldSpec(
            label: loc.fSsn,
            kind: FieldKind.ssn,
            get: (d) => d.taxpayer.ssn,
            set: (d, v) => d.taxpayer.ssn = _s(v),
            hint: '123-45-6789',
            info: loc.infoSsn,
          ),
          FieldSpec(
            label: loc.fDateOfBirth,
            kind: FieldKind.date,
            get: (d) => d.taxpayer.dateOfBirth?.toIso8601String() ?? '',
            set: (d, v) => d.taxpayer.dateOfBirth =
                (v is String && v.isNotEmpty) ? DateTime.tryParse(v) : null,
            info: loc.infoDob,
          ),
          FieldSpec(
            label: loc.fBlind,
            kind: FieldKind.toggle,
            get: (d) => d.taxpayer.isBlind,
            set: (d, v) => d.taxpayer.isBlind = _b(v),
          ),
        ]),
        SectionSpec(loc.secFilingStatus, [
          FieldSpec(
            label: loc.fFilingStatus,
            kind: FieldKind.choice,
            get: (d) => d.filingStatus.name,
            set: (d, v) {
              final name = _s(v);
              d.filingStatus = FilingStatus.values
                  .firstWhere((f) => f.name == name, orElse: () => FilingStatus.single);
              if (d.filingStatus != FilingStatus.marriedJointly &&
                  d.filingStatus != FilingStatus.marriedSeparately &&
                  d.filingStatus != FilingStatus.qualifyingSurvivingSpouse) {
                // keep spouse data but it won't be used
              }
            },
            choices: [
              const ChoiceOption('single', 'Single'),
              const ChoiceOption('marriedJointly', 'Married filing jointly'),
              const ChoiceOption('marriedSeparately', 'Married filing separately'),
              const ChoiceOption('headOfHousehold', 'Head of household'),
              const ChoiceOption('qualifyingSurvivingSpouse', 'Qualifying surviving spouse'),
            ],
            info: _statusInfo,
          ),
        ]),
      ], info: loc.infoPersonal),
      PageSpec.form('spouse', loc.pageSpouse, [
        SectionSpec(loc.secSpouseInfo, [
          FieldSpec(
            label: loc.fFirstName,
            kind: FieldKind.text,
            get: (d) => d.spouse?.firstName ?? '',
            set: (d, v) {
              d.spouse ??= Person();
              d.spouse!.firstName = _s(v);
            },
          ),
          FieldSpec(
            label: loc.fLastName,
            kind: FieldKind.text,
            get: (d) => d.spouse?.lastName ?? '',
            set: (d, v) {
              d.spouse ??= Person();
              d.spouse!.lastName = _s(v);
            },
          ),
          FieldSpec(
            label: loc.fSsn,
            kind: FieldKind.ssn,
            get: (d) => d.spouse?.ssn ?? '',
            set: (d, v) {
              d.spouse ??= Person();
              d.spouse!.ssn = _s(v);
            },
            hint: '123-45-6789',
          ),
          FieldSpec(
            label: loc.fDateOfBirth,
            kind: FieldKind.date,
            get: (d) => d.spouse?.dateOfBirth?.toIso8601String() ?? '',
            set: (d, v) {
              d.spouse ??= Person();
              d.spouse!.dateOfBirth =
                  (v is String && v.isNotEmpty) ? DateTime.tryParse(v) : null;
            },
          ),
          FieldSpec(
            label: loc.fBlind,
            kind: FieldKind.toggle,
            get: (d) => d.spouse?.isBlind ?? false,
            set: (d, v) {
              d.spouse ??= Person();
              d.spouse!.isBlind = _b(v);
            },
          ),
        ]),
      ], info: loc.infoSpouse),
      PageSpec.special('dependents', PageKind.listDependents, loc.pageDependents,
          info: loc.infoDependents),
    ]),

    TopicSpec('income', Icons.payments_outlined, loc.topicIncome, [
      PageSpec.special('w2', PageKind.listW2, loc.pageW2,
          info: loc.infoW2),
      PageSpec.special('interest', PageKind.listInterest, loc.pageInterest,
          info: loc.infoInterest),
      PageSpec.special('dividends', PageKind.listDividends, loc.pageDividends,
          info: loc.infoDividends),
      PageSpec.special('capgains', PageKind.listCapitalGains, loc.pageCapGains,
          info: loc.infoCapGains),
      PageSpec.special('se', PageKind.listSe, loc.pageSelfEmployment,
          info: loc.infoSe),
      PageSpec.special('retirement', PageKind.listRetirement, loc.pageRetirement,
          info: loc.infoRetirement),
      PageSpec.form('otherIncome', loc.pageOtherIncome, [
        SectionSpec(loc.secSocialSecurity, [
          FieldSpec(
            label: loc.fSsBenefits,
            kind: FieldKind.money,
            get: (d) => d.socialSecurityBenefits,
            set: (d, v) => d.socialSecurityBenefits = _d(v),
            info: loc.infoSs,
          ),
        ]),
        SectionSpec(loc.secUnemployment, [
          FieldSpec(
            label: loc.fUnemployment,
            kind: FieldKind.money,
            get: (d) => d.adjustments.unemploymentAmount,
            set: (d, v) => d.adjustments.unemploymentAmount = _d(v),
          ),
          FieldSpec(
            label: loc.fUnemploymentWithheld,
            kind: FieldKind.money,
            get: (d) => d.adjustments.unemploymentWithholding,
            set: (d, v) => d.adjustments.unemploymentWithholding = _d(v),
          ),
        ]),
        SectionSpec(loc.secOtherIncome, [
          FieldSpec(
            label: loc.fOtherIncomeDesc,
            kind: FieldKind.text,
            get: (d) => d.otherIncome.isEmpty ? '' : d.otherIncome.first.description,
            set: (d, v) {
              if (v == null || _s(v).isEmpty) {
                if (d.otherIncome.isNotEmpty) d.otherIncome.removeAt(0);
                return;
              }
              if (d.otherIncome.isEmpty) d.otherIncome.add(OtherIncomeItem());
              d.otherIncome[0].description = _s(v);
            },
            hint: loc.hOtherIncome,
          ),
          FieldSpec(
            label: loc.fOtherIncomeAmount,
            kind: FieldKind.money,
            get: (d) => d.otherIncome.isEmpty ? 0 : d.otherIncome.first.amount,
            set: (d, v) {
              if (v == null || _d(v) == 0) return;
              if (d.otherIncome.isEmpty) d.otherIncome.add(OtherIncomeItem());
              d.otherIncome[0].amount = _d(v);
            },
          ),
        ]),
        if (true) SectionSpec(loc.secObbba, [
          FieldSpec(
            label: loc.fCarLoanInterest,
            kind: FieldKind.money,
            get: (d) => d.qualifiedCarLoanInterest,
            set: (d, v) => d.qualifiedCarLoanInterest = _d(v),
            info: loc.infoCarLoan,
          ),
        ]),
      ], info: loc.infoOtherIncome),
    ]),

    TopicSpec('deductions', Icons.receipt_long_outlined, loc.topicDeductions, [
      PageSpec.form('itemized', loc.pageDeductions, [
        SectionSpec(loc.secItemized, [
          FieldSpec(
            label: loc.fMedical,
            kind: FieldKind.money,
            get: (d) => d.itemized.medicalExpenses,
            set: (d, v) => d.itemized.medicalExpenses = _d(v),
            info: loc.infoMedical,
          ),
          FieldSpec(
            label: loc.fSalt,
            kind: FieldKind.money,
            get: (d) => d.itemized.saltTaxes,
            set: (d, v) => d.itemized.saltTaxes = _d(v),
            info: loc.infoSalt,
          ),
          FieldSpec(
            label: loc.fMortgage,
            kind: FieldKind.money,
            get: (d) => d.itemized.mortgageInterest,
            set: (d, v) => d.itemized.mortgageInterest = _d(v),
          ),
          FieldSpec(
            label: loc.fCharityCash,
            kind: FieldKind.money,
            get: (d) => d.itemized.charitableCash,
            set: (d, v) => d.itemized.charitableCash = _d(v),
          ),
          FieldSpec(
            label: loc.fCharityNonCash,
            kind: FieldKind.money,
            get: (d) => d.itemized.charitableNonCash,
            set: (d, v) => d.itemized.charitableNonCash = _d(v),
          ),
        ]),
        SectionSpec(loc.secAdjustments, [
          FieldSpec(
            label: loc.fIra,
            kind: FieldKind.money,
            get: (d) => d.adjustments.iraContributions,
            set: (d, v) => d.adjustments.iraContributions = _d(v),
            info: loc.infoIra,
          ),
          FieldSpec(
            label: loc.fStudentLoanInterest,
            kind: FieldKind.money,
            get: (d) => d.adjustments.studentLoanInterest,
            set: (d, v) => d.adjustments.studentLoanInterest = _d(v),
            info: loc.infoSli,
          ),
          FieldSpec(
            label: loc.fHsa,
            kind: FieldKind.money,
            get: (d) => d.adjustments.hsaContributions,
            set: (d, v) => d.adjustments.hsaContributions = _d(v),
          ),
          FieldSpec(
            label: loc.fEducator,
            kind: FieldKind.money,
            get: (d) => d.adjustments.educatorExpenses,
            set: (d, v) => d.adjustments.educatorExpenses = _d(v),
          ),
        ]),
      ], info: loc.infoDeductions),
    ]),

    TopicSpec('credits', Icons.volunteer_activism_outlined, loc.topicCredits, [
      PageSpec.form('credits', loc.pageCredits, [
        SectionSpec(loc.secChildCare, [
          FieldSpec(
            label: loc.fChildCare,
            kind: FieldKind.money,
            get: (d) => d.credits.childCareExpenses,
            set: (d, v) => d.credits.childCareExpenses = _d(v),
            info: loc.infoChildCare,
          ),
        ]),
        SectionSpec(loc.secEducation, [
          FieldSpec(
            label: loc.fAotc,
            kind: FieldKind.money,
            get: (d) => d.credits.aotcQualifiedExpenses,
            set: (d, v) => d.credits.aotcQualifiedExpenses = _d(v),
            info: loc.infoAotc,
          ),
          FieldSpec(
            label: loc.fLlc,
            kind: FieldKind.money,
            get: (d) => d.credits.llcQualifiedExpenses,
            set: (d, v) => d.credits.llcQualifiedExpenses = _d(v),
            info: loc.infoLlc,
          ),
        ]),
        SectionSpec(loc.secSavers, [
          FieldSpec(
            label: loc.fSavers,
            kind: FieldKind.money,
            get: (d) => d.credits.saversCreditContributions,
            set: (d, v) => d.credits.saversCreditContributions = _d(v),
            info: loc.infoSavers,
          ),
        ]),
        SectionSpec(loc.secPayments, [
          FieldSpec(
            label: loc.fEstimatedPayments,
            kind: FieldKind.money,
            get: (d) => d.adjustments.estimatedPayments,
            set: (d, v) => d.adjustments.estimatedPayments = _d(v),
          ),
        ]),
      ], info: loc.infoCredits),
    ]),
  ];
}
