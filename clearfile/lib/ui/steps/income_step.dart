import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../io/csv_import.dart';
import '../../../models/tax_return.dart';
import '../../../models/w2.dart';
import '../../../util/money.dart';
import '../app_state.dart';
import '../widgets/money_field.dart';

/// Step 2 of 5: W-2 list editor (with CSV paste-import) plus the other
/// income lines the demo engine supports.
class IncomeStep extends StatelessWidget {
  const IncomeStep({super.key, required this.state, required this.r});

  final AppState state;
  final TaxReturnData r;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('W-2 wages', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final w2 in r.w2s)
          _W2Card(key: ValueKey(w2), state: state, w2: w2),
        if (r.w2s.isEmpty)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No W-2s yet. Add one for each employer, or paste a CSV.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: () => state.update((x) => x.w2s.add(W2Entry())),
              icon: const Icon(Icons.add),
              label: const Text('Add W-2'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _showCsvDialog(context, state),
              icon: const Icon(Icons.paste),
              label: const Text('Paste CSV'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Other income',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                MoneyField(
                  label: 'Interest (1099-INT, Box 1)',
                  value: r.interestIncome,
                  onChanged: (v) => state.update((x) => x.interestIncome = v),
                ),
                const SizedBox(height: 12),
                MoneyField(
                  label: 'Ordinary dividends (1099-DIV, Box 1a)',
                  helper:
                      'The part NOT taxed at lower rates. ClearFile adds qualified dividends separately below.',
                  value: r.ordinaryDividends,
                  onChanged: (v) =>
                      state.update((x) => x.ordinaryDividends = v),
                ),
                const SizedBox(height: 12),
                MoneyField(
                  label: 'Qualified dividends (1099-DIV, Box 1b)',
                  helper: 'Taxed at the lower capital-gains rates.',
                  value: r.qualifiedDividends,
                  onChanged: (v) =>
                      state.update((x) => x.qualifiedDividends = v),
                ),
                const SizedBox(height: 12),
                MoneyField(
                  label: 'Long-term capital gains',
                  value: r.longTermCapitalGains,
                  onChanged: (v) =>
                      state.update((x) => x.longTermCapitalGains = v),
                ),
                const SizedBox(height: 12),
                MoneyField(
                  label: 'Other income',
                  helper: 'Self-employment, gig platforms, prizes, etc.',
                  value: r.otherIncome,
                  onChanged: (v) => state.update((x) => x.otherIncome = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _TotalsFooter(r: r),
      ],
    );
  }
}

class _W2Card extends StatelessWidget {
  const _W2Card({super.key, required this.state, required this.w2});

  final AppState state;
  final W2Entry w2;

  @override
  Widget build(BuildContext context) {
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
                    'W-2${w2.employer.trim().isEmpty ? '' : ' - ${w2.employer.trim()}'}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove this W-2',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => state.update((x) => x.w2s.remove(w2)),
                ),
              ],
            ),
            TextFormField(
              initialValue: w2.employer,
              decoration: const InputDecoration(
                labelText: 'Employer name',
                isDense: true,
              ),
              onChanged: (text) => state.update((x) => w2.employer = text),
            ),
            const SizedBox(height: 12),
            MoneyField(
              label: 'Box 1 - wages, tips, other compensation',
              value: w2.wages,
              onChanged: (v) => state.update((x) => w2.wages = v),
            ),
            const SizedBox(height: 12),
            MoneyField(
              label: 'Box 2 - federal income tax withheld',
              value: w2.withholding,
              onChanged: (v) => state.update((x) => w2.withholding = v),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsFooter extends StatelessWidget {
  const _TotalsFooter({required this.r});

  final TaxReturnData r;

  @override
  Widget build(BuildContext context) {
    if (r.totalIncome == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Total income so far: ${formatMoney(r.totalIncome)} '
        '(withholding ${formatMoney(r.totalWithholding)})',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

Future<void> _showCsvDialog(BuildContext context, AppState state) async {
  final controller = TextEditingController();
  final imported = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Paste W-2 CSV'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste rows with an employer, wages (Box 1) and optional '
              'withholding (Box 2) column. Example:\n',
            ),
            Text(w2CsvTemplate, style: const TextStyle(fontFamily: 'monospace')),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'employer,box1_wages,box2_federal_tax_withheld\nAcme Corp,52500.00,6200.00',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: w2CsvTemplate));
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Template copied to clipboard')),
            );
          },
          child: const Text('Copy template'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Import'),
        ),
      ],
    ),
  );
  if (imported != true || !context.mounted) return;
  try {
    final result = parseW2Csv(controller.text);
    if (result.entries.isEmpty && result.warnings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to import - the text was empty.')),
      );
      return;
    }
    state.update((x) => x.w2s.addAll(result.entries));
    final message = result.warnings.isEmpty
        ? '${result.entries.length} W-2${result.entries.length == 1 ? '' : 's'} imported.'
        : '${result.entries.length} imported, ${result.warnings.length} row(s) skipped.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  } on FormatException catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.message)));
  }
}
