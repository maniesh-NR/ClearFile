import 'package:flutter/material.dart';

import '../../../models/tax_return.dart';
import '../../../util/money.dart';
import '../app_state.dart';
import '../widgets/money_field.dart';

/// Step 5 of 5: estimated payments and a summary of the withholding already
/// captured from W-2s.
class PaymentsStep extends StatelessWidget {
  const PaymentsStep({super.key, required this.state, required this.r});

  final AppState state;
  final TaxReturnData r;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Tax you already paid',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Federal tax withheld on your W-2s is counted automatically. Add any '
          'estimated payments you made during the year.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                MoneyField(
                  label: 'Estimated federal tax payments',
                  value: r.estimatedPayments,
                  onChanged: (v) =>
                      state.update((x) => x.estimatedPayments = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: scheme.secondaryContainer,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.payments_outlined,
                        color: scheme.onSecondaryContainer),
                    const SizedBox(width: 8),
                    Text('Payments on file',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: scheme.onSecondaryContainer,
                            )),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Withholding from ${r.w2s.length} '
                  'W-2${r.w2s.length == 1 ? '' : 's'}: '
                  '${formatMoney(r.totalWithholding)}\n'
                  'Estimated payments: ${formatMoney(r.estimatedPayments)}\n'
                  'Total payments: '
                  '${formatMoney(r.totalWithholding + r.estimatedPayments)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
