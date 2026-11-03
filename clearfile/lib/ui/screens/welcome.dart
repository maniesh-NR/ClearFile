import 'package:flutter/material.dart';

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
            onPressed: state.importFromFile,
            icon: const Icon(Icons.file_open_outlined),
            label: const Text('Import a .clearfile.json file'),
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
          Text(
            'Your data stays on this device. AI features run on your own free '
            'API keys and call the providers directly.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  static String _shortDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
