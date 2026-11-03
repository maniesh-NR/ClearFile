import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ai/settings.dart';
import '../app_state.dart';

/// Settings: AI assistant enablement, provider keys, the editable model
/// chain, privacy, data management and the about section.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});

  final AppState state;

  static const _googleKeyUrl = 'https://aistudio.google.com/apikey';
  static const _openrouterKeyUrl = 'https://openrouter.ai/settings/keys';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionHeader('AI assistant'),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      value: state.settings.assistantEnabled,
                      onChanged: (v) => state
                          .updateSettings((s) => s.assistantEnabled = v),
                      title: const Text('Enable ClearFile Assist'),
                      subtitle: const Text(
                          'Runs on your own free API keys; nothing is sent '
                          'unless you ask a question.'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionHeader('API keys (stored only on this device)'),
              _KeyField(
                label: 'Google AI Studio key',
                value: state.settings.googleApiKey,
                linkUrl: _googleKeyUrl,
                linkLabel: 'aistudio.google.com/apikey',
                onChanged: (v) =>
                    state.updateSettings((s) => s.googleApiKey = v),
              ),
              const SizedBox(height: 12),
              _KeyField(
                label: 'OpenRouter key',
                value: state.settings.openrouterApiKey,
                linkUrl: _openrouterKeyUrl,
                linkLabel: 'openrouter.ai/settings/keys',
                onChanged: (v) =>
                    state.updateSettings((s) => s.openrouterApiKey = v),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _testConnection(context),
                icon: const Icon(Icons.network_check),
                label: const Text('Test connection'),
              ),
              const SizedBox(height: 8),
              Text(
                'Free tiers have daily limits (OpenRouter\'s free models: '
                'roughly 50 requests/day without credits, 1,000/day once you '
                'have bought \$10 of credits; Google AI Studio also rate-limits '
                'per minute). When one model is busy, ClearFile steps down the '
                'chain automatically.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              _SectionHeader('Model chain (tried top to bottom)'),
              for (final spec in state.settings.chain)
                _ChainTile(
                  state: state,
                  spec: spec,
                  removable: state.settings.chain.length > 1,
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () => _addModelSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add a model'),
                ),
              ),
              const SizedBox(height: 16),
              _SectionHeader('Privacy'),
              Card(
                margin: EdgeInsets.zero,
                child: SwitchListTile(
                  value: state.settings.sendReturnContext,
                  onChanged: (v) =>
                      state.updateSettings((s) => s.sendReturnContext = v),
                  title: const Text('Share anonymous return figures'),
                  subtitle: const Text(
                      'When on, totals like AGI and taxable income (never '
                      'names or SSNs) are included so answers fit your '
                      'numbers.'),
                ),
              ),
              const SizedBox(height: 16),
              _SectionHeader('Your data'),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.file_upload_outlined),
                      title: const Text('Export current return'),
                      subtitle: const Text('.clearfile.json - open format'),
                      enabled: state.current != null,
                      onTap: state.exportCurrent,
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep_outlined),
                      title: const Text('Clear the assistant conversation'),
                      onTap: state.clearChat,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionHeader('About'),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ClearFile 1.0.0 - demonstration software',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text(
                        'A clean-room study of consumer tax-preparation '
                        'software. The engine implements a simplified 2025 US '
                        'federal return and omits many real rules (no SE tax, '
                        'no state returns, simplified credits). ClearFile is '
                        'not IRS-authorized, cannot e-file, and must not be '
                        'used to file a real tax return. All data stays on '
                        'this device.',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Model lineups were last verified against the live '
                'OpenRouter free catalogue on 2026-11-03.',
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

  Future<void> _testConnection(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Testing the model chain...')),
    );
    final result = await state.testConnection();
    messenger.showSnackBar(SnackBar(content: Text(result)));
  }

  Future<void> _addModelSheet(BuildContext context) async {
    final present = state.settings.chain
        .map((m) => '${m.provider.name}:${m.modelId}')
        .toSet();
    final candidates = suggestedModels
        .where((m) => !present.contains('${m.provider.name}:${m.modelId}'))
        .toList();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text('Suggested free models',
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Verified against the free tiers of Google AI Studio and '
              'OpenRouter on 2026-11-03. Every entry stays editable and can '
              'be removed later.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            for (final m in candidates)
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: Text(m.modelId),
                subtitle: Text(m.provider.name),
                onTap: () {
                  state.updateSettings((s) => s.chain.add(
                        AiModelSpec(
                            provider: m.provider, modelId: m.modelId),
                      ));
                  Navigator.pop(ctx);
                },
              ),
            if (candidates.isEmpty)
              const ListTile(
                title: Text('All suggested models are already on the chain'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _KeyField extends StatefulWidget {
  const _KeyField({
    required this.label,
    required this.value,
    required this.linkUrl,
    required this.linkLabel,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String linkUrl;
  final String linkLabel;
  final ValueChanged<String> onChanged;

  @override
  State<_KeyField> createState() => _KeyFieldState();
}

class _KeyFieldState extends State<_KeyField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: widget.value,
              obscureText: _obscured,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: widget.label,
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscured = !_obscured),
                ),
              ),
              onChanged: widget.onChanged,
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => _openLink(context, widget.linkUrl),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text('Get a free key: ${widget.linkLabel}'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainTile extends StatelessWidget {
  const _ChainTile({
    required this.state,
    required this.spec,
    required this.removable,
  });

  final AppState state;
  final AiModelSpec spec;
  final bool removable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          spec.provider == AiProviderKind.google
              ? Icons.auto_awesome
              : Icons.hub_outlined,
          color: scheme.primary,
        ),
        title: Text(spec.modelId),
        subtitle: Text(spec.provider.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: spec.enabled,
              onChanged: (v) {
                final index = state.settings.chain.indexOf(spec);
                if (index >= 0) {
                  state.updateSettings(
                      (s) => s.chain[index] = s.chain[index].copyWith(enabled: v));
                }
              },
            ),
            if (removable)
              IconButton(
                tooltip: 'Remove from chain',
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => state.updateSettings(
                    (s) => s.chain.removeWhere((m) => m == spec)),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openLink(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text('Could not open $url')));
  }
}
