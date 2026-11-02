/// Settings — AI keys with guided free-key instructions, model chain
/// editor, automation toggles, appearance and language.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/common.dart';
import '../../state/app_state.dart';
import '../../core/ai/ai_client.dart';
import '../../services/platform_io.dart';

const kGoogleAiStudioUrl = 'https://aistudio.google.com/apikey';
const kMistralConsoleUrl = 'https://console.mistral.ai/api-keys/';

class SettingsScreen extends StatefulWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _testResult;
  bool _testing = false;

  Future<void> _open(String url) async {
    try {
      await const PlatformIo().openLink(url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpen(url))));
      }
    }
  }

  Future<void> _testChain() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final reply = await AiClient().testChain(widget.state.ai);
      setState(() {
        _testResult = 'OK — ${reply.provider}/${reply.model}';
      });
    } on AiException catch (e) {
      final bad = e.attempts
          .where((a) => a.outcome != 'ok')
          .map((a) => '${a.provider}/${a.model}: ${a.outcome}')
          .join('; ');
      setState(() {
        _testResult = 'FAILED — $bad';
      });
    } catch (e) {
      setState(() {
        _testResult = 'FAILED — $e';
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final ai = widget.state.ai;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(loc.settingsAiHeader, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _KeyCard(
            title: loc.googleKeyTitle,
            subtitle: loc.googleKeySteps,
            link: kGoogleAiStudioUrl,
            linkLabel: loc.googleKeyLink,
            value: ai.googleApiKey,
            onOpen: _open,
            onChanged: (v) => widget.state.mutateAi((a) => a.googleApiKey = v.trim()),
          ),
          const SizedBox(height: 12),
          _KeyCard(
            title: loc.mistralKeyTitle,
            subtitle: loc.mistralKeySteps,
            link: kMistralConsoleUrl,
            linkLabel: loc.mistralKeyLink,
            value: ai.mistralApiKey,
            onOpen: _open,
            onChanged: (v) => widget.state.mutateAi((a) => a.mistralApiKey = v.trim()),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(loc.chainHeader,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _testing ? null : _testChain,
                        icon: _testing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.bolt),
                        label: Text(loc.testChain),
                      ),
                    ],
                  ),
                  if (_testResult != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_testResult!),
                    ),
                  const SizedBox(height: 8),
                  Text(loc.chainNote, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  for (var i = 0; i < ai.chain.length; i++)
                    _ChainRow(
                      index: i,
                      entry: ai.chain[i],
                      onToggle: (v) =>
                          widget.state.mutateAi((a) => a.chain[i].enabled = v),
                      onUp: i > 0
                          ? () => widget.state.mutateAi((a) {
                                final t = a.chain[i - 1];
                                a.chain[i - 1] = a.chain[i];
                                a.chain[i] = t;
                              })
                          : null,
                      onDown: i < ai.chain.length - 1
                          ? () => widget.state.mutateAi((a) {
                                final t = a.chain[i + 1];
                                a.chain[i + 1] = a.chain[i];
                                a.chain[i] = t;
                              })
                          : null,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.automationHeader,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  ToggleRow(
                    label: loc.toggleShareContext,
                    value: ai.shareReturnContext,
                    onChanged: (v) =>
                        widget.state.mutateAi((a) => a.shareReturnContext = v),
                  ),
                  ToggleRow(
                    label: loc.toggleAnonymize,
                    value: ai.anonymizePersonalData,
                    onChanged: (v) =>
                        widget.state.mutateAi((a) => a.anonymizePersonalData = v),
                  ),
                  ToggleRow(
                    label: loc.toggleAutoDeductions,
                    value: ai.autoSuggestDeductions,
                    onChanged: (v) =>
                        widget.state.mutateAi((a) => a.autoSuggestDeductions = v),
                  ),
                  ToggleRow(
                    label: loc.toggleAutoExtract,
                    value: ai.autoExtractPastedDocs,
                    onChanged: (v) =>
                        widget.state.mutateAi((a) => a.autoExtractPastedDocs = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.appearanceHeader,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ChoiceCards<String>(
                    label: loc.themeLabel,
                    value: widget.state.themeMode.name,
                    options: const {
                      'system': 'System',
                      'light': 'Light',
                      'dark': 'Dark',
                    },
                    onChanged: (v) => widget.state.setThemeMode(
                        ThemeMode.values.firstWhere((m) => m.name == v)),
                  ),
                  ChoiceCards<String>(
                    label: loc.languageLabel,
                    value: widget.state.localeCode,
                    options: const {
                      'system': 'System',
                      'en': 'English',
                      'es': 'Español',
                    },
                    onChanged: widget.state.setLocale,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Nitro Nissi 1.0.0 — GPL-3.0 · clean-room · not affiliated with '
              'Intuit/TurboTax or the IRS · estimates only, not tax advice',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _KeyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String link;
  final String linkLabel;
  final String value;
  final Future<void> Function(String) onOpen;
  final ValueChanged<String> onChanged;

  const _KeyCard({
    required this.title,
    required this.subtitle,
    required this.link,
    required this.linkLabel,
    required this.value,
    required this.onOpen,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => onOpen(link),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(linkLabel),
            ),
            TextFieldSpec(
              label: title,
              value: value,
              obscure: true,
              hint: 'AIza… /  …',
              onChanged: onChanged,
            ),
            Text(
              'Keys are stored only on this device and sent only to the '
              'provider you chose.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainRow extends StatelessWidget {
  final int index;
  final ModelEntry entry;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onUp;
  final VoidCallback? onDown;

  const _ChainRow({
    required this.index,
    required this.entry,
    required this.onToggle,
    this.onUp,
    this.onDown,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('${index + 1}.',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entry.provider.name}: ${entry.modelId}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(entry.freeTierNote,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(onPressed: onUp, icon: const Icon(Icons.arrow_upward, size: 18)),
          IconButton(onPressed: onDown, icon: const Icon(Icons.arrow_downward, size: 18)),
          Switch(value: entry.enabled, onChanged: onToggle),
        ],
      ),
    );
  }
}
