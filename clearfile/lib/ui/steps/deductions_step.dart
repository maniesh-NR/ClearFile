import 'package:flutter/material.dart';

import '../../../models/tax_return.dart';
import '../../../tax/results.dart';
import '../../../util/money.dart';
import '../app_state.dart';
import '../widgets/money_field.dart';

/// Step 3 of 5: deduction method, itemized components, and the student-loan
/// interest adjustment. Live comparison chips show which method is winning.
class DeductionsStep extends StatelessWidget {
  const DeductionsStep({super.key, required this.state, required this.r});

  final AppState state;
  final TaxReturnData r;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final res = state.result;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Deduction method',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        RadioGroup<DeductionMethod>(
          groupValue: r.deductionMethod,
          onChanged: (value) {
            if (value != null) {
              state.update((x) => x.deductionMethod = value);
            }
          },
          child: Column(
            children: [
              for (final method in DeductionMethod.values)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<DeductionMethod>(
                    value: method,
                    title: Text(method.label),
                  ),
                ),
            ],
          ),
        ),
        if (res != null) _ComparisonChips(res: res),
        const SizedBox(height: 16),
        Text('If you itemize',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Only needed when you itemize or let ClearFile compare. The SALT '
          'combination of state/local taxes is capped.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                MoneyField(
                  label: 'State & local income or sales tax (SALT)',
                  value: r.stateLocalIncomeOrSalesTax,
                  onChanged: (v) =>
                      state.update((x) => x.stateLocalIncomeOrSalesTax = v),
                ),
                const SizedBox(height: 12),
                MoneyField(
                  label: 'Real estate taxes',
                  value: r.realEstateTax,
                  onChanged: (v) => state.update((x) => x.realEstateTax = v),
                ),
                const SizedBox(height: 12),
                MoneyField(
                  label: 'Home mortgage interest (1098, Box 1)',
                  value: r.mortgageInterest,
                  onChanged: (v) =>
                      state.update((x) => x.mortgageInterest = v),
                ),
                const SizedBox(height: 12),
                MoneyField(
                  label: 'Charitable gifts - cash',
                  value: r.charitableCash,
                  onChanged: (v) => state.update((x) => x.charitableCash = v),
                ),
                const SizedBox(height: 12),
                MoneyField(
                  label: 'Charitable gifts - non-cash (thrift-store value)',
                  value: r.charitableNonCash,
                  onChanged: (v) =>
                      state.update((x) => x.charitableNonCash = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Adjustments to income',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MoneyField(
              label: 'Student loan interest (1098-E, Box 1)',
              helper:
                  'Deductible up to \$2,500, phasing out at higher income.',
              value: r.studentLoanInterest,
              onChanged: (v) =>
                  state.update((x) => x.studentLoanInterest = v),
            ),
          ),
        ),
      ],
    );
  }
}

class _ComparisonChips extends StatelessWidget {
  const _ComparisonChips({required this.res});

  final TaxResult res;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final better = res.deductionUsed == res.standardDeductionTotal
        ? 'Standard deduction is larger'
        : 'Itemizing is larger';
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Wrap(
        spacing: 8,
        children: [
          Chip(
            avatar: Icon(Icons.compare_arrows,
                color: scheme.onSecondaryContainer),
            label: Text(
                'Standard ${formatMoney(res.standardDeductionTotal)}'),
            backgroundColor: scheme.secondaryContainer,
          ),
          Chip(
            avatar: Icon(Icons.receipt_long, color: scheme.onSecondaryContainer),
            label: Text('Itemized ${formatMoney(res.itemizedDeductionTotal)}'),
            backgroundColor: scheme.secondaryContainer,
          ),
          Chip(
            avatar: Icon(Icons.check_circle_outline,
                color: scheme.onPrimaryContainer),
            label: Text(better),
            backgroundColor: scheme.primaryContainer,
          ),
        ],
      ),
    );
  }
}
