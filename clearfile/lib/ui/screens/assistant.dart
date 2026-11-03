import 'package:flutter/material.dart';

import '../app_state.dart';

/// The AI assistant chat: setup card when unconfigured, conversation bubbles,
/// quick prompts, and per-attempt error reporting when the whole chain fails.
class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key, required this.state});

  final AppState state;

  static const List<String> _quickPrompts = [
    'Can I deduct my home office?',
    'Why is my refund smaller than last year?',
    'What is the difference between a credit and a deduction?',
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final settings = state.settings;
        final scheme = Theme.of(context).colorScheme;
        final body = Column(
          children: [
            Expanded(child: _ChatList(state: state)),
            if (!settings.assistantEnabled)
              _SetupCard(
                state: state,
                title: 'The assistant is off',
                body: 'Turn it on and add a free API key to chat. '
                    'Keys live only on this device.',
                actionLabel: 'Open Settings',
              )
            else if (!settings.isConfigured)
              _SetupCard(
                state: state,
                title: 'Add a free API key to start',
                body: 'ClearFile runs on your own key - Google AI Studio or '
                    'OpenRouter both work, and both have free tiers. The key '
                    'is stored on this device and sent only to the provider '
                    'you chose.',
                actionLabel: 'Open Settings',
              )
            else if (state.chat.isEmpty)
              _Bubble(
                fromUser: false,
                text: state.assistant.welcomeMessage,
                caption: null,
              ),
            if (state.assistantError != null)
              _ErrorCard(message: state.assistantError!),
            if (state.assistantBusy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Trying the model chain...'),
                  ],
                ),
              ),
            if (settings.assistantEnabled &&
                settings.isConfigured &&
                state.chat.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final prompt in _quickPrompts)
                      ActionChip(
                        label: Text(prompt),
                        onPressed: () => state.sendAssistantMessage(prompt),
                      ),
                  ],
                ),
              ),
            _InputRow(state: state),
          ],
        );
        return Scaffold(
          appBar: AppBar(
            title: const Text('ClearFile Assist'),
            actions: [
              if (state.chat.isNotEmpty)
                IconButton(
                  tooltip: 'Clear conversation',
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: state.clearChat,
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: 'AI settings',
                  icon: Icon(Icons.tune,
                      color: scheme.onSurfaceVariant),
                  onPressed: () => state.selectTab(4),
                ),
              ),
            ],
          ),
          body: body,
        );
      },
    );
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    if (state.chat.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: state.chat.length,
      itemBuilder: (context, index) {
        final turn = state.chat[index];
        final caption = turn.fromUser || index != state.chat.length - 1
            ? null
            : state.servedByLabel;
        return _Bubble(fromUser: turn.fromUser, text: turn.content, caption: caption);
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.fromUser, required this.text, this.caption});

  final bool fromUser;
  final String text;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(fromUser ? 16 : 4),
      bottomRight: Radius.circular(fromUser ? 4 : 16),
    );
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.widthOf(context) * 0.82,
        ),
        decoration: BoxDecoration(
          color: fromUser ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: radius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: fromUser ? scheme.onPrimary : scheme.onSurface,
                  ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 6),
              Text(
                'served by $caption',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: fromUser
                          ? scheme.onPrimary.withValues(alpha: 0.7)
                          : scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.state,
    required this.title,
    required this.body,
    required this.actionLabel,
  });

  final AppState state;
  final String title;
  final String body;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiaryContainer,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: scheme.onTertiaryContainer),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onTertiaryContainer,
                        )),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => state.selectTab(4),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Every model on the chain failed.\n$message',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputRow extends StatefulWidget {
  const _InputRow({required this.state});

  final AppState state;

  @override
  State<_InputRow> createState() => _InputRowState();
}

class _InputRowState extends State<_InputRow> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await widget.state.sendAssistantMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        widget.state.settings.assistantEnabled &&
            widget.state.settings.isConfigured &&
            !widget.state.assistantBusy;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ask a tax question...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: enabled ? _send : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
