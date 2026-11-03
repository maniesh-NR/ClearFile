import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/dependent.dart';
import '../../../models/tax_return.dart';
import '../app_state.dart';

/// Step 4 of 5: dependents list with the two plain-language credit questions
/// the demo engine asks instead of running the full IRS dependency tests.
class DependentsStep extends StatelessWidget {
  const DependentsStep({super.key, required this.state, required this.r});

  final AppState state;
  final TaxReturnData r;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Dependents', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Claiming a qualifying child under 17 can add a \$2,200 Child Tax '
          'Credit; a dependent who is not a qualifying child may still earn '
          'the \$500 Credit for Other Dependents.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        for (final d in r.dependents)
          _DependentCard(key: ValueKey(d), state: state, dependent: d),
        if (r.dependents.isEmpty)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No dependents. Skip this step if nobody depends on you.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        FilledButton.tonalIcon(
          onPressed: () =>
              state.update((x) => x.dependents.add(Dependent())),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Add dependent'),
        ),
      ],
    );
  }
}

class _DependentCard extends StatelessWidget {
  const _DependentCard({super.key, required this.state, required this.dependent});

  final AppState state;
  final Dependent dependent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dependent.name.trim().isEmpty
                        ? 'New dependent'
                        : dependent.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      state.update((x) => x.dependents.remove(dependent)),
                ),
              ],
            ),
            TextFormField(
              initialValue: dependent.name,
              decoration: const InputDecoration(
                labelText: 'First and last name',
                isDense: true,
              ),
              onChanged: (t) => state.update((x) => dependent.name = t),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue:
                  dependent.age == 0 ? '' : dependent.age.toString(),
              decoration: const InputDecoration(
                labelText: 'Age at the end of 2025',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (t) =>
                  state.update((x) => dependent.age = int.tryParse(t) ?? 0),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: dependent.relationship,
              decoration: const InputDecoration(
                labelText: 'Relationship (son, parent, niece...)',
                isDense: true,
              ),
              onChanged: (t) =>
                  state.update((x) => dependent.relationship = t),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: dependent.qualifyingChild,
              onChanged: (v) =>
                  state.update((x) => dependent.qualifyingChild = v),
              title: const Text('Qualifying child under 17'),
              subtitle: Text(
                'Child Tax Credit, \$2,200 per child.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: dependent.otherDependentCredit,
              onChanged: (v) =>
                  state.update((x) => dependent.otherDependentCredit = v),
              title: const Text('Qualifies for the other-dependent credit'),
              subtitle: Text(
                '\$500 credit - for example a parent or a child 17+.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
