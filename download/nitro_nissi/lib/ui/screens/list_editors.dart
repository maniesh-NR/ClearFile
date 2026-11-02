/// List editors: W-2s, dependents, interest, dividends, capital gains,
/// self-employment and retirement entries — card-per-item, add/remove,
/// same field widgets as the form pages.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../core/tax/model.dart';
import '../widgets/common.dart';

class _ListScaffold extends StatelessWidget {
  final String title;
  final String addLabel;
  final VoidCallback onAdd;
  final List<Widget> cards;
  final String? emptyText;
  const _ListScaffold({
    required this.title,
    required this.addLabel,
    required this.onAdd,
    required this.cards,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (cards.isEmpty && emptyText != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: Text(emptyText!,
                    style: Theme.of(context).textTheme.bodyLarge)),
          ),
        ...cards,
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(addLabel),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  final String heading;
  final VoidCallback? onRemove;
  final List<Widget> children;
  const _ItemCard({required this.heading, this.onRemove, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(heading,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (onRemove != null)
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }
}

typedef Mutate = void Function(void Function(dynamic) fn);

class W2ListEditor extends StatelessWidget {
  final AppState state;
  const W2ListEditor({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _ListScaffold(
      title: loc.pageW2,
      emptyText: loc.emptyW2,
      addLabel: loc.addW2,
      onAdd: () => state.mutate((d) => d.w2s.add(W2Entry())),
      cards: [
        for (var i = 0; i < state.data.w2s.length; i++)
          _w2Card(context, i, loc),
      ],
    );
  }

  Widget _w2Card(BuildContext context, int i, AppLocalizations loc) {
    final w = state.data.w2s[i];
    return _ItemCard(
      heading: w.employerName.isEmpty ? loc.w2N(i + 1) : w.employerName,
      onRemove: () => state.mutate((d) => d.w2s.removeAt(i)),
      children: [
        TextFieldSpec(
          label: loc.fEmployer,
          value: w.employerName,
          onChanged: (v) => state.mutate((d) => d.w2s[i].employerName = v),
        ),
        TextFieldSpec(
          label: loc.fEin,
          hint: '12-3456789',
          value: w.employerEin,
          onChanged: (v) => state.mutate((d) => d.w2s[i].employerEin = v),
        ),
        MoneyField(
          label: loc.fWagesBox1,
          value: w.wages,
          onChanged: (v) => state.mutate((d) => d.w2s[i].wages = v),
        ),
        MoneyField(
          label: loc.fFedWithheldBox2,
          value: w.federalWithholding,
          onChanged: (v) => state.mutate((d) => d.w2s[i].federalWithholding = v),
        ),
        MoneyField(
          label: loc.fSsWagesBox3,
          value: w.ssWages,
          onChanged: (v) => state.mutate((d) => d.w2s[i].ssWages = v),
        ),
        MoneyField(
          label: loc.fSsWithheldBox4,
          value: w.ssWithholding,
          onChanged: (v) => state.mutate((d) => d.w2s[i].ssWithholding = v),
        ),
        MoneyField(
          label: loc.fMedicareBox6,
          value: w.medicareWithholding,
          onChanged: (v) => state.mutate((d) => d.w2s[i].medicareWithholding = v),
        ),
        if (state.data.taxYear >= 2025) ...[
          MoneyField(
            label: loc.fQualifiedTips,
            value: w.qualifiedTips,
            onChanged: (v) => state.mutate((d) => d.w2s[i].qualifiedTips = v),
          ),
          MoneyField(
            label: loc.fQualifiedOvertime,
            value: w.qualifiedOvertime,
            onChanged: (v) => state.mutate((d) => d.w2s[i].qualifiedOvertime = v),
          ),
        ],
      ],
    );
  }
}

class DependentsListEditor extends StatelessWidget {
  final AppState state;
  const DependentsListEditor({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _ListScaffold(
      title: loc.pageDependents,
      emptyText: loc.emptyDependents,
      addLabel: loc.addDependent,
      onAdd: () => state.mutate((d) => d.dependents.add(Dependent())),
      cards: [
        for (var i = 0; i < state.data.dependents.length; i++)
          _depCard(context, i, loc),
      ],
    );
  }

  Widget _depCard(BuildContext context, int i, AppLocalizations loc) {
    final dep = state.data.dependents[i];
    return _ItemCard(
      heading: (dep.firstName + ' ' + dep.lastName).trim().isEmpty
          ? loc.dependentN(i + 1)
          : '${dep.firstName} ${dep.lastName}',
      onRemove: () => state.mutate((d) => d.dependents.removeAt(i)),
      children: [
        TextFieldSpec(
          label: loc.fFirstName,
          value: dep.firstName,
          onChanged: (v) => state.mutate((d) => d.dependents[i].firstName = v),
        ),
        TextFieldSpec(
          label: loc.fLastName,
          value: dep.lastName,
          onChanged: (v) => state.mutate((d) => d.dependents[i].lastName = v),
        ),
        TextFieldSpec(
          label: loc.fSsn,
          hint: '123-45-6789',
          value: dep.ssn,
          onChanged: (v) => state.mutate((d) => d.dependents[i].ssn = v),
        ),
        TextFieldSpec(
          label: loc.fRelationship,
          value: dep.relationship,
          onChanged: (v) => state.mutate((d) => d.dependents[i].relationship = v),
        ),
        TextFieldSpec(
          label: loc.fDateOfBirth,
          hint: 'YYYY-MM-DD',
          value: dep.dateOfBirth?.toIso8601String().substring(0, 10) ?? '',
          onChanged: (v) => state.mutate(
              (d) => d.dependents[i].dateOfBirth = DateTime.tryParse(v)),
        ),
        ToggleRow(
          label: loc.fFullTimeStudent,
          value: dep.isFullTimeStudent,
          onChanged: (v) => state.mutate((d) => d.dependents[i].isFullTimeStudent = v),
        ),
        ToggleRow(
          label: loc.fPermanentlyDisabled,
          value: dep.permanentlyDisabled,
          onChanged: (v) => state.mutate((d) => d.dependents[i].permanentlyDisabled = v),
        ),
      ],
    );
  }
}

class InterestListEditor extends StatelessWidget {
  final AppState state;
  const InterestListEditor({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _ListScaffold(
      title: loc.pageInterest,
      emptyText: loc.emptyInterest,
      addLabel: loc.addPayer,
      onAdd: () => state.mutate((d) => d.interest.add(InterestIncome())),
      cards: [
        for (var i = 0; i < state.data.interest.length; i++)
          _ItemCard(
            heading: state.data.interest[i].payer.isEmpty
                ? loc.payerN(i + 1)
                : state.data.interest[i].payer,
            onRemove: () => state.mutate((d) => d.interest.removeAt(i)),
            children: [
              TextFieldSpec(
                label: loc.fPayer,
                value: state.data.interest[i].payer,
                onChanged: (v) => state.mutate((d) => d.interest[i].payer = v),
              ),
              MoneyField(
                label: loc.fTaxableInterest,
                value: state.data.interest[i].taxableInterest,
                onChanged: (v) => state.mutate((d) => d.interest[i].taxableInterest = v),
              ),
              MoneyField(
                label: loc.fTaxExemptInterest,
                value: state.data.interest[i].taxExemptInterest,
                onChanged: (v) => state.mutate((d) => d.interest[i].taxExemptInterest = v),
              ),
            ],
          ),
      ],
    );
  }
}

class DividendsListEditor extends StatelessWidget {
  final AppState state;
  const DividendsListEditor({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _ListScaffold(
      title: loc.pageDividends,
      emptyText: loc.emptyDividends,
      addLabel: loc.addPayer,
      onAdd: () => state.mutate((d) => d.dividends.add(DividendIncome())),
      cards: [
        for (var i = 0; i < state.data.dividends.length; i++)
          _ItemCard(
            heading: state.data.dividends[i].payer.isEmpty
                ? loc.payerN(i + 1)
                : state.data.dividends[i].payer,
            onRemove: () => state.mutate((d) => d.dividends.removeAt(i)),
            children: [
              TextFieldSpec(
                label: loc.fPayer,
                value: state.data.dividends[i].payer,
                onChanged: (v) => state.mutate((d) => d.dividends[i].payer = v),
              ),
              MoneyField(
                label: loc.fOrdinaryDividends,
                value: state.data.dividends[i].ordinaryDividends,
                onChanged: (v) => state.mutate((d) => d.dividends[i].ordinaryDividends = v),
              ),
              MoneyField(
                label: loc.fQualifiedDividends,
                value: state.data.dividends[i].qualifiedDividends,
                onChanged: (v) => state.mutate((d) => d.dividends[i].qualifiedDividends = v),
              ),
            ],
          ),
      ],
    );
  }
}

class CapGainsListEditor extends StatelessWidget {
  final AppState state;
  const CapGainsListEditor({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _ListScaffold(
      title: loc.pageCapGains,
      emptyText: loc.emptyCapGains,
      addLabel: loc.addSale,
      onAdd: () => state.mutate((d) => d.capitalGains.add(CapitalGainEntry())),
      cards: [
        for (var i = 0; i < state.data.capitalGains.length; i++)
          _ItemCard(
            heading: state.data.capitalGains[i].description.isEmpty
                ? loc.saleN(i + 1)
                : state.data.capitalGains[i].description,
            onRemove: () => state.mutate((d) => d.capitalGains.removeAt(i)),
            children: [
              TextFieldSpec(
                label: loc.fDescription,
                value: state.data.capitalGains[i].description,
                onChanged: (v) => state.mutate((d) => d.capitalGains[i].description = v),
              ),
              MoneyField(
                label: loc.fProceeds,
                value: state.data.capitalGains[i].proceeds,
                onChanged: (v) => state.mutate((d) => d.capitalGains[i].proceeds = v),
              ),
              MoneyField(
                label: loc.fCostBasis,
                value: state.data.capitalGains[i].costBasis,
                onChanged: (v) => state.mutate((d) => d.capitalGains[i].costBasis = v),
              ),
              ToggleRow(
                label: loc.fLongTerm,
                value: state.data.capitalGains[i].isLongTerm,
                onChanged: (v) => state.mutate((d) => d.capitalGains[i].isLongTerm = v),
              ),
            ],
          ),
      ],
    );
  }
}

class SeListEditor extends StatelessWidget {
  final AppState state;
  const SeListEditor({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _ListScaffold(
      title: loc.pageSelfEmployment,
      emptyText: loc.emptySe,
      addLabel: loc.addBusiness,
      onAdd: () => state.mutate((d) => d.selfEmployment.add(SelfEmploymentIncome())),
      cards: [
        for (var i = 0; i < state.data.selfEmployment.length; i++)
          _ItemCard(
            heading: state.data.selfEmployment[i].businessName.isEmpty
                ? loc.businessN(i + 1)
                : state.data.selfEmployment[i].businessName,
            onRemove: () => state.mutate((d) => d.selfEmployment.removeAt(i)),
            children: [
              TextFieldSpec(
                label: loc.fBusinessName,
                value: state.data.selfEmployment[i].businessName,
                onChanged: (v) => state.mutate((d) => d.selfEmployment[i].businessName = v),
              ),
              MoneyField(
                label: loc.fNetProfit,
                value: state.data.selfEmployment[i].netProfit,
                onChanged: (v) => state.mutate((d) => d.selfEmployment[i].netProfit = v),
              ),
              if (state.data.taxYear >= 2025)
                MoneyField(
                  label: loc.fSeTips,
                  value: state.data.selfEmployment[i].qualifiedTips,
                  onChanged: (v) => state.mutate((d) => d.selfEmployment[i].qualifiedTips = v),
                ),
              MoneyField(
                label: loc.fSeHealthPremiums,
                value: state.data.selfEmployment[i].seHealthInsurancePremiums,
                onChanged: (v) =>
                    state.mutate((d) => d.selfEmployment[i].seHealthInsurancePremiums = v),
              ),
              MoneyField(
                label: loc.fSepSimple,
                value: state.data.selfEmployment[i].sepSimpleContributions,
                onChanged: (v) =>
                    state.mutate((d) => d.selfEmployment[i].sepSimpleContributions = v),
              ),
            ],
          ),
      ],
    );
  }
}

class RetirementListEditor extends StatelessWidget {
  final AppState state;
  const RetirementListEditor({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _ListScaffold(
      title: loc.pageRetirement,
      emptyText: loc.emptyRetirement,
      addLabel: loc.addPayer,
      onAdd: () => state.mutate((d) => d.retirement.add(RetirementIncome())),
      cards: [
        for (var i = 0; i < state.data.retirement.length; i++)
          _ItemCard(
            heading: state.data.retirement[i].payer.isEmpty
                ? loc.payerN(i + 1)
                : state.data.retirement[i].payer,
            onRemove: () => state.mutate((d) => d.retirement.removeAt(i)),
            children: [
              TextFieldSpec(
                label: loc.fPayer,
                value: state.data.retirement[i].payer,
                onChanged: (v) => state.mutate((d) => d.retirement[i].payer = v),
              ),
              MoneyField(
                label: loc.fGrossDistribution,
                value: state.data.retirement[i].grossDistribution,
                onChanged: (v) => state.mutate((d) => d.retirement[i].grossDistribution = v),
              ),
              MoneyField(
                label: loc.fTaxableAmount,
                value: state.data.retirement[i].taxableAmount,
                onChanged: (v) => state.mutate((d) => d.retirement[i].taxableAmount = v),
              ),
              MoneyField(
                label: loc.fFedWithheld,
                value: state.data.retirement[i].federalWithholding,
                onChanged: (v) => state.mutate((d) => d.retirement[i].federalWithholding = v),
              ),
            ],
          ),
      ],
    );
  }
}
