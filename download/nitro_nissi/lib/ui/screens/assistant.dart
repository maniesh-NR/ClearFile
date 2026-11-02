/// AI assistant — chat with the fallback chain, quick actions, and
/// automation entry points (deduction review, document extraction).
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../core/ai/ai_client.dart';
import '../../core/ai/prompts.dart';

class _ChatMsg {
  final String text;
  final bool fromUser;
  final String? meta;
  const _ChatMsg(this.text, this.fromUser, [this.meta]);
}

class AssistantScreen extends StatefulWidget {
  final AppState state;
  const AssistantScreen({super.key, required this.state});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controller = TextEditingController();
  final _client = AiClient();
  final _messages = <_ChatMsg>[];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMsg(
        'Welcome! Ask me anything about your return, or use a quick action below. '
        'I use your own free API keys (Google AI Studio first, then Mistral) and '
        'fall back automatically when a model is unavailable.\n\n'
        'I am not a tax professional and this is not tax advice.',
        false));
  }

  Future<void> _send(String text, {String? overrideUser}) async {
    final s = widget.state;
    if (s.ai.googleApiKey.isEmpty && s.ai.mistralApiKey.isEmpty) {
      setState(() {
        _messages.add(_ChatMsg(text, true));
        _messages.add(_ChatMsg(
            'No AI keys configured yet. Open Settings → AI assistant and add a '
            'free key from Google AI Studio or Mistral. Links and step-by-step '
            'instructions are right there.',
            false));
      });
      return;
    }
    setState(() {
      _messages.add(_ChatMsg(text, true));
      _busy = true;
    });
    String contextBlock = '';
    if (s.ai.shareReturnContext) {
      final r = s.result;
      final summary = AiPrompts.summarizeReturn(
          s.data, {'agi': r.agi, 'totalTax': r.totalTax, 'refundOrOwe': r.refundOrOwe},
          anonymize: s.ai.anonymizePersonalData);
      contextBlock = '\n\nCurrent return context (JSON):\n$summary';
    }
    try {
      final reply = await _client.send(
        settings: s.ai,
        system: AiPrompts.systemAssistant,
        user: (overrideUser ?? text) + contextBlock,
      );
      setState(() {
        _messages.add(_ChatMsg(
            reply.text, false, 'via ${reply.provider}/${reply.model}'));
      });
    } on AiException catch (e) {
      final details = e.attempts
          .map((a) => '• ${a.provider}/${a.model}: ${a.outcome} ${a.detail}')
          .join('\n');
      setState(() {
        _messages.add(_ChatMsg(
            'All AI models in your chain failed. Attempts:\n$details\n\n'
            'Check your keys and rate limits in Settings → AI assistant.',
            false));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMsg('Error: $e', false));
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reviewReturn() async {
    final s = widget.state;
    final r = s.result;
    final summary = AiPrompts.summarizeReturn(s.data, {
      'agi': r.agi,
      'totalTax': r.totalTax,
      'refundOrOwe': r.refundOrOwe,
      'ctc': r.ctcTotal,
      'eitc': r.eitc,
      'seTax': r.seTax,
      'deductionUsed': r.deductionUsed,
    }, anonymize: s.ai.anonymizePersonalData);
    await _send('', overrideUser: AiPrompts.reviewPrompt(summary));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_busy ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final m = _messages[i];
                return Align(
                  alignment: m.fromUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: const BoxConstraints(maxWidth: 640),
                    decoration: BoxDecoration(
                      color: m.fromUser
                          ? scheme.primaryContainer
                          : scheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(m.text),
                        if (m.meta != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(m.meta!,
                                style: Theme.of(context).textTheme.labelSmall),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.reviews_outlined, size: 18),
                  label: Text(loc.quickReviewReturn),
                  onPressed: _busy ? null : _reviewReturn,
                ),
                ActionChip(
                  avatar: const Icon(Icons.receipt_long, size: 18),
                  label: Text(loc.quickDeductions),
                  onPressed: _busy
                      ? null
                      : () => _send(
                          'Which common deductions or credits might I be missing? '
                          'Ask me about anything you need to know.'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.school_outlined, size: 18),
                  label: Text(loc.quickExplain),
                  onPressed: _busy
                      ? null
                      : () => _send(
                          'Explain adjusted gross income (AGI), the standard '
                          'deduction and taxable income in plain language.'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: loc.askPlaceholder,
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isEmpty || _busy) return;
                      _controller.clear();
                      _send(v.trim());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _busy
                      ? null
                      : () {
                          final v = _controller.text.trim();
                          if (v.isEmpty) return;
                          _controller.clear();
                          _send(v);
                        },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
