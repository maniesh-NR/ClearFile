import 'package:flutter/material.dart';

import '../../../models/filing_status.dart';
import '../../../models/tax_return.dart';
import '../app_state.dart';

/// Step 1 of 5: filing status and the 65+/blind checkboxes that feed the
/// additional standard deduction.
class StatusStep extends StatelessWidget {
  const StatusStep({super.key, required this.state, required this.r});

  final AppState state;
  final TaxReturnData r;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('How were you filing in 2025?',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Pick the status that matched your situation on December 31, 2025.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        RadioGroup<FilingStatus>(
          groupValue: r.filingStatus,
          onChanged: (value) {
            if (value != null) {
              state.update((x) => x.filingStatus = value);
            }
          },
          child: Column(
            children: [
              for (final status in FilingStatus.values)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<FilingStatus>(
                    value: status,
                    title: Text(status.label),
                    subtitle: Text(
                      status.plainExplanation,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('About you (and your spouse)',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                value: r.taxpayer65OrOlder,
                onChanged: (v) => state.update((x) => x.taxpayer65OrOlder = v),
                title: const Text('I was 65 or older on Dec 31, 2025'),
                subtitle: Text(
                    'Adds an extra standard deduction amount for each person 65+.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        )),
              ),
              SwitchListTile(
                value: r.taxpayerBlind,
                onChanged: (v) => state.update((x) => x.taxpayerBlind = v),
                title: const Text('I am legally blind'),
              ),
              if (r.hasSpouse)
                SwitchListTile(
                  value: r.spouse65OrOlder,
                  onChanged: (v) =>
                      state.update((x) => x.spouse65OrOlder = v),
                  title: const Text('My spouse was 65 or older'),
                ),
              if (r.hasSpouse)
                SwitchListTile(
                  value: r.spouseBlind,
                  onChanged: (v) => state.update((x) => x.spouseBlind = v),
                  title: const Text('My spouse is legally blind'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
