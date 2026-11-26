// SPDX-License-Identifier: GPL-3.0-only
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../ai/disclosure.dart';
import '../../io/return_format.dart';
import '../app_state.dart';

/// Welcome / home screen: what ClearFile is, the demo disclaimer, actions to
/// start or open a return, and the list of returns saved on this device.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ClearFile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'DEMO',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.receipt_long,
                    color: scheme.onPrimary, size: 30),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ClearFile',
                      style: Theme.of(context).textTheme.headlineMedium),
                  Text('clean-room tax assistant',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                      Icon(Icons.info_outline, color: scheme.onSecondaryContainer),
                      const SizedBox(width: 8),
                      Text('Demonstration software',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                  color: scheme.onSecondaryContainer)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ClearFile prepares a simplified 2025 US federal return for '
                    'study and demonstration. It is not IRS-authorized, cannot '
                    'e-file, and must not be used to file a real tax return.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: state.startNewReturn,
            icon: const Icon(Icons.add),
            label: const Text('Start a 2025 federal return'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _importReturnFile(context),
            icon: const Icon(Icons.file_open_outlined),
            label: const Text('Import a .clearfile.json file'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _importTxf(context),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Import a TurboTax TXF export'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _inspectTax(context),
            icon: const Icon(Icons.plagiarism_outlined),
            label: const Text('Inspect a .tax file (read-only)'),
          ),
          const SizedBox(height: 24),
          if (state.savedReturns.isNotEmpty) ...[
            Text('Saved on this device',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final r in state.savedReturns)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(r.displayName),
                  subtitle: Text(
                      'Modified ${_shortDate(r.modified)} - ${r.filingStatus.label} - ${r.w2s.length} W-2${r.w2s.length == 1 ? '' : 's'}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'open') state.openReturn(r);
                      if (value == 'delete') {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete this return?'),
                            content: Text(
                                '"${r.displayName}" will be removed from this '
                                'device. Exported copies are not affected.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  state.deleteReturn(r);
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'open', child: Text('Open')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () => state.openReturn(r),
                ),
              ),
          ],
          const SizedBox(height: 16),
          // Stage 5 (D12): the behavior-generated disclosure — native names
          // the plaintext JSON ai_settings.json storage; the web variant
          // states keys live only in this tab's memory. Pinned by
          // privacy_test.dart so it cannot drift from the transport.
          Text(
            kIsWeb ? aiPrivacyDisclosureWeb : aiPrivacyDisclosure,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 8),
            // Stage 4 web-build honesty note: the deployed demo runs from
            // memory — nothing is saved to this device (there is no device
            // filesystem in the browser tab).
            Text(
              'Running as a web demo: returns and settings are kept in this '
              'browser tab\'s memory only and are not saved after you leave '
              'the page.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  static String _shortDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // --- TurboTax-format bridges (TXF import, .tax inspection) -------------

  /// Import a ClearFile return file and report the outcome precisely
  /// (D1: cancelled is silent, failures say why, migrations list their
  /// notes) — the same dialog treatment the TXF import gives.
  Future<void> _importReturnFile(BuildContext context) async {
    final outcome = await state.importFromFile();
    if (!context.mounted) return;
    switch (outcome) {
      case ReturnImportCancelled():
        return;
      case ReturnImportFailed():
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Could not import this file'),
            content: Text(outcome.reason),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      case ReturnImportOk():
        if (outcome.warnings.isNotEmpty) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Import notes'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final note in outcome.warnings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(note,
                            style:
                                Theme.of(ctx).textTheme.bodySmall),
                      ),
                  ],
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
    }
  }

  Future<void> _importTxf(BuildContext context) async {
    final outcome = await state.importFromTxf();
    if (!context.mounted) return;
    if (outcome.error != null) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Could not import this file'),
          content: Text(outcome.error!),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }
    final notes = outcome.result?.warnings ?? const <String>[];
    if (notes.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('TXF import notes'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final note in notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(note, style: Theme.of(ctx).textTheme.bodySmall),
                  ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _inspectTax(BuildContext context) async {
    final insp = await state.inspectTaxFile();
    if (insp == null || !context.mounted) return;
    final scheme = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tax file inspection'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insp.summary,
                    style: Theme.of(ctx).textTheme.bodyMedium),
                if (insp.entries.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Entries',
                      style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  for (final e in insp.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${e.name} — ${e.size} B, method ${e.method}'
                        '${e.entropy != null
                            ? ', entropy ${e.entropy!.toStringAsFixed(2)} bits/byte'
                            : ''}'
                        '${e.likelyEncrypted == true
                            ? ' — likely encrypted' : ''}',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: e.likelyEncrypted == true
                                  ? scheme.error
                                  : scheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                ],
                if (insp.warnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final w in insp.warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(w,
                          style: Theme.of(ctx).textTheme.bodySmall),
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (insp.clearfileContainer && insp.filing != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                state.importInspected(insp);
              },
              child: const Text('Import return'),
            ),
        ],
      ),
    );
  }
}
