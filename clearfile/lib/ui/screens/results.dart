import 'package:flutter/material.dart';

import '../../models/tax_return.dart';
import '../../tax/results.dart';
import '../../tax/review_rules.dart';
import '../../util/money.dart';
import '../app_state.dart';

/// Results screen: refund/balance hero, quick stats, the Form-1040-style
/// summary, the deterministic review findings and the optional AI review.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final r = state.current;
        final res = state.result;
        if (r == null || res == null) return _EmptyState(state: state);
        return Scaffold(
          appBar: AppBar(
            title: Text('Results - ${r.displayName}'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeroCard(res: res),
              const SizedBox(height: 12),
              _QuickStats(res: res),
              const SizedBox(height: 16),
              _SummaryCard(res: res),
              const SizedBox(height: 16),
              _ReviewSection(state: state, r: r, res: res),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.exportCurrent,
                      icon: const Icon(Icons.file_upload_outlined),
                      label: const Text('Export .clearfile.json'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _confirmClose(context, state),
                child: const Text('Close this return'),
              ),
              const SizedBox(height: 8),
              Text(
                'Demonstration output from a simplified 2025 engine. Verify '
                'every number against your own documents before drawing any '
                'conclusions.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _confirmClose(
      BuildContext context, AppState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close this return?'),
        content: const Text(
            'Your return stays saved on this device and can be reopened from '
            'the Home tab.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    if (confirmed == true) state.closeReturn();
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.res});

  final TaxResult res;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRefund = res.isRefund;
    final amount = isRefund ? res.refund : res.amountOwed;
    final container =
        isRefund ? scheme.primaryContainer : scheme.errorContainer;
    final onContainer =
        isRefund ? scheme.onPrimaryContainer : scheme.onErrorContainer;
    return Card(
      color: container,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(isRefund ? Icons.savings_outlined : Icons.account_balance,
                color: onContainer,
                size: 32),
            const SizedBox(height: 8),
            Text(
              formatMoney(amount),
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(color: onContainer, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              isRefund
                  ? 'Federal refund expected'
                  : amount == 0
                      ? 'Even - nothing owed, nothing refunded'
                      : 'Federal balance due',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: onContainer),
            ),
            const SizedBox(height: 4),
            Text(
              'based on the numbers entered so far',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: onContainer.withValues(alpha: 0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.res});

  final TaxResult res;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatChip(
            icon: Icons.percent,
            label: 'Effective rate ${formatPercent(res.effectiveRate)}'),
        _StatChip(
            icon: Icons.trending_up,
            label: 'Marginal rate ${formatPercent(res.marginalRate)}'),
        _StatChip(
            icon: Icons.receipt_long,
            label:
                'Deduction ${formatMoney(res.deductionUsed)} (${res.deductionMethodUsed.name})'),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSecondaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.res});

  final TaxResult res;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Form 1040-style summary',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final line in res.lines)
              ListTile(
                dense: true,
                title: Text(
                  line.label,
                  style: line.emphasis
                      ? Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          )
                      : Theme.of(context).textTheme.bodyLarge,
                ),
                trailing: Text(
                  formatMoney(line.value),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: line.emphasis ? FontWeight.w700 : null,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection(
      {required this.state, required this.r, required this.res});

  final AppState state;
  final TaxReturnData r;
  final TaxResult res;

  @override
  Widget build(BuildContext context) {
    final findings = runReview(r, res);
    final scheme = Theme.of(context).colorScheme;
    final aiReady =
        state.settings.assistantEnabled && state.settings.isConfigured;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final f in findings) _FindingCard(finding: f),
        if (findings.isEmpty)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.check_circle_outline,
                  color: scheme.primary),
              title: const Text('No review findings'),
              subtitle: Text(
                  'Nothing looks missing or inconsistent based on the '
                  'deterministic checks.',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
        if (aiReady)
          FilledButton.tonalIcon(
            onPressed: state.assistantBusy ? null : state.runAssistantReview,
            icon: state.assistantBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: const Text('Ask the AI assistant to review'),
          )
        else
          Card(
            color: scheme.tertiaryContainer,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome,
                      color: scheme.onTertiaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enable the AI assistant in Settings to get a '
                      'plain-language second opinion on this return.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onTertiaryContainer,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => state.selectTab(4),
                    child: const Text('Settings'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FindingCard extends StatelessWidget {
  const _FindingCard({required this.finding});

  final ReviewFinding finding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (color, icon) = switch (finding.severity) {
      ReviewSeverity.warning => (scheme.errorContainer, Icons.warning_amber),
      ReviewSeverity.suggestion =>
        (scheme.tertiaryContainer, Icons.lightbulb_outline),
      ReviewSeverity.info => (scheme.secondaryContainer, Icons.info_outline),
    };
    return Card(
      color: color,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    finding.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(finding.detail,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calculate_outlined,
              size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text('Nothing to calculate yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Open a return and enter your numbers to see results here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: state.startNewReturn,
            icon: const Icon(Icons.add),
            label: const Text('Start a 2025 return'),
          ),
        ],
      ),
    );
  }
}
