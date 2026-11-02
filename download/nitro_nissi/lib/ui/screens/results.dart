/// Results — refund/owe overview, bracket breakdown, exports
/// (print package PDF + e-file-ready JSON), TurboTax-style presentation.
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../core/export/print_package.dart';
import '../../core/efile/mef_json.dart';
import '../../services/platform_io.dart';
import '../widgets/common.dart';

class ResultsScreen extends StatelessWidget {
  final AppState state;
  const ResultsScreen({super.key, required this.state});

  Future<void> _exportPdf(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    try {
      final bytes = await const PrintPackage().build(state.data, state.result);
      final suggested = 'NitroNissi-TY${state.data.taxYear}-return.pdf';
      final path = await const PlatformIo().pickSavePath(suggested);
      await const PlatformIo().saveBytes(path, suggested, bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.savedPackage)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${loc.exportFailed}: $e')));
      }
    }
  }

  Future<void> _exportMef(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    try {
      final mef = const MeFExporter().export(state.data, state.result);
      final bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(mef));
      final suggested = 'NitroNissi-TY${state.data.taxYear}-efileready.json';
      final path = await const PlatformIo().pickSavePath(suggested);
      await const PlatformIo().saveBytes(path, suggested, bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.savedMef)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${loc.exportFailed}: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final r = state.result;
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.of(context).size.width >= 900;

    final bracketsCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.bracketBreakdown,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final s in r.bracketSlices.where((s) => s.amount > 0))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text('${(s.rate * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Expanded(child: Text(money(s.amount))),
                    Text(money(s.tax),
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            if (r.preferentialTax > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    loc.preferentialNote(money(r.qualifiedDividends + r.netLongTermGain),
                        money(r.preferentialTax)),
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );

    final factsCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fact(loc.factAgi, money(r.agi)),
            _fact(loc.factDeduction, money(r.deductionUsed)),
            _fact(loc.factTaxable, money(r.taxableIncome)),
            _fact(loc.factEffective, '${r.effectiveRate.toStringAsFixed(1)}%'),
            _fact(loc.factMarginal, '${(r.marginalRate * 100).toStringAsFixed(0)}%'),
            _fact(loc.factCredits,
                money(r.totalNonrefundableCredits + r.totalRefundableCredits)),
            _fact(loc.factOtherTaxes, money(r.seTax + r.niit + r.additionalMedicareTax)),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(loc.resultsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: r.isRefund
                    ? [scheme.primaryContainer, scheme.surface]
                    : [scheme.errorContainer, scheme.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(r.isRefund ? Icons.savings : Icons.account_balance_wallet,
                    size: 40, color: r.isRefund ? scheme.primary : scheme.error),
                const SizedBox(height: 8),
                Text(
                  r.isRefund ? loc.refundHeadline : loc.oweHeadline,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  money(r.refundOrOwe.abs()),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: r.isRefund ? scheme.primary : scheme.error),
                ),
                const SizedBox(height: 6),
                Text(loc.estimateDisclaimer,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 16),
          wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: bracketsCard),
                  const SizedBox(width: 12),
                  Expanded(child: factsCard),
                ])
              : Column(children: [bracketsCard, const SizedBox(height: 12), factsCard]),
          const SizedBox(height: 16),
          Text(loc.exportHeader, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _exportPdf(context),
                icon: const Icon(Icons.print_outlined),
                label: Text(loc.exportPdf),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _exportMef(context),
                icon: const Icon(Icons.data_object),
                label: Text(loc.exportMef),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(loc.mefDisclaimer, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _fact(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
