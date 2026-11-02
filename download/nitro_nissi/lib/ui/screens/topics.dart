/// Topics home — the TurboTax-like checklist with progress per topic.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../core/tax/validation.dart';
import '../../services/platform_io.dart' show ioBackend;
import '../wizard_spec.dart';
import '../widgets/common.dart';
import 'interview.dart';
import 'review.dart';
import 'results.dart';

class TopicsScreen extends StatelessWidget {
  final AppState state;
  const TopicsScreen({super.key, required this.state});

  double _progressFor(TopicSpec t) {
    // Heuristic: page counts with any non-empty bound value count as done.
    final d = state.data;
    int done = 0;
    for (final p in t.pages) {
      final has = p.sections.any((s) => s.fields.any((f) {
            final v = f.get(d);
            return v != null && '$v'.isNotEmpty && '$v' != '0' && '$v' != '0.0';
          }));
      if (has) done++;
    }
    return t.pages.isEmpty ? 0 : done / t.pages.length;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final topics = buildTopics(loc);
    final issues = state.issues;
    final errors = issues.where((i) => i.severity == IssueSeverity.error).length;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (issues.isNotEmpty) ...[
            SeverityBanner(
              isError: errors > 0,
              isWarning: errors == 0,
              message: errors > 0
                  ? loc.issuesFound(errors)
                  : loc.issuesFoundInfo(issues.length),
            ),
            const SizedBox(height: 12),
          ],
          Text(loc.topicsHeader, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(loc.topicsSubheader, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          for (final t in topics) ...[
            _TopicCard(
              spec: t,
              progress: _progressFor(t),
              onTap: () {
                Navigator.of(context, rootNavigator: false).push(
                  MaterialPageRoute(builder: (_) => InterviewScreen(state: state, topicId: t.id)),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.verified_outlined),
            label: Text(loc.continueToReview),
            onPressed: () {
              Navigator.of(context, rootNavigator: false).push(
                MaterialPageRoute(builder: (_) => ReviewScreen(state: state)),
              );
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.calculate_outlined),
            label: Text(loc.jumpToResults),
            onPressed: () {
              Navigator.of(context, rootNavigator: false).push(
                MaterialPageRoute(builder: (_) => ResultsScreen(state: state)),
              );
            },
          ),
          const SizedBox(height: 16),
          _SavedNote(state: state),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final TopicSpec spec;
  final double progress;
  final VoidCallback onTap;

  const _TopicCard({required this.spec, required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(spec.icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spec.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(progress >= 1 ? Icons.check_circle : Icons.chevron_right,
                  color: progress >= 1 ? scheme.primary : scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedNote extends StatelessWidget {
  final AppState state;
  const _SavedNote({required this.state});

  @override
  Widget build(BuildContext context) {
    if (!ioBackend.hasFileSystem) return const SizedBox.shrink();
    final name = state.openedFilePath != null
        ? state.openedFilePath!.split(RegExp(r'[\\/]')).last
        : 'autosave.nnx';
    return Row(
      children: [
        Icon(Icons.save_outlined, size: 14, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.autosaveNote(name),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

