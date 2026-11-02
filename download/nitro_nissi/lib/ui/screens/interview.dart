/// Interview screen — renders one topic as a paged wizard.
///
/// Layout mirrors TurboTax placements: progress on top, question card in
/// the center, "Why do we ask?" info on the right on wide screens (Direct
/// File's plain-language pattern on narrow ones). Back / Continue at the
/// bottom right, as in TurboTax.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../wizard_spec.dart';
import 'list_editors.dart';
import 'review.dart';
import 'results.dart';

class InterviewScreen extends StatefulWidget {
  final AppState state;
  final String topicId;
  const InterviewScreen({super.key, required this.state, required this.topicId});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final topics = buildTopics(loc);
    final topic = topics.firstWhere(
      (t) => t.id == widget.topicId,
      orElse: () => topics.first,
    );
    final wide = MediaQuery.of(context).size.width >= 1200;

    return Scaffold(
      appBar: AppBar(
        title: Text('${topic.title} — ${loc.topicStep(_page + 1, topic.pages.length)}'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_page + 1) / topic.pages.length,
            minHeight: 4,
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final spec = topic.pages[_page];
              final info = spec.info;
              final form = _pageBody(spec, loc);
              if (wide && info != null) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: form),
                      const SizedBox(width: 20),
                      SizedBox(width: 300, child: InfoPanel(title: loc.whyWeAsk, body: info)),
                    ],
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (info != null) ...[
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      leading: Icon(Icons.help_outline,
                          color: Theme.of(context).colorScheme.primary),
                      title: Text(loc.whyWeAsk),
                      children: [InfoPanel(title: '', body: info)],
                    ),
                    const SizedBox(height: 8),
                  ],
                  form,
                ],
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 1,
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: _page > 0
                  ? () => setState(() => _page--)
                  : () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
              label: Text(loc.back),
            ),
            const Spacer(),
            if (topic.pages[_page].kind == PageKind.review)
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ResultsScreen(state: widget.state)),
                ),
                icon: const Icon(Icons.calculate_outlined),
                label: Text(loc.seeResults),
              )
            else
              FilledButton.icon(
                onPressed: () {
                  if (_page < topic.pages.length - 1) {
                    setState(() => _page++);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ReviewScreen(state: widget.state)),
                    );
                  }
                },
                icon: const Icon(Icons.arrow_forward),
                label: Text(loc.continueLabel),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pageBody(PageSpec spec, AppLocalizations loc) {
    switch (spec.kind) {
      case PageKind.form:
        return _FormPage(state: widget.state, spec: spec);
      case PageKind.listW2:
        return W2ListEditor(state: widget.state);
      case PageKind.listDependents:
        return DependentsListEditor(state: widget.state);
      case PageKind.listInterest:
        return InterestListEditor(state: widget.state);
      case PageKind.listDividends:
        return DividendsListEditor(state: widget.state);
      case PageKind.listCapitalGains:
        return CapGainsListEditor(state: widget.state);
      case PageKind.listSe:
        return SeListEditor(state: widget.state);
      case PageKind.listRetirement:
        return RetirementListEditor(state: widget.state);
      case PageKind.listOther:
      case PageKind.review:
        return _FormPage(state: widget.state, spec: spec);
    }
  }
}

class _FormPage extends StatelessWidget {
  final AppState state;
  final PageSpec spec;
  const _FormPage({required this.state, required this.spec});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        Text(spec.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        for (final section in spec.sections) ...[
          _SectionCard(state: state, section: section),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final AppState state;
  final SectionSpec section;
  const _SectionCard({required this.state, required this.section});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final f in section.fields)
              _FieldRenderer(state: state, field: f),
          ],
        ),
      ),
    );
  }
}

class _FieldRenderer extends StatelessWidget {
  final AppState state;
  final FieldSpec field;
  const _FieldRenderer({required this.state, required this.field});

  @override
  Widget build(BuildContext context) {
    final d = state.data;
    switch (field.kind) {
      case FieldKind.money:
        return MoneyField(
          label: field.label,
          hint: field.hint,
          value: _d(field.get(d)),
          onChanged: (v) => state.mutate((dd) => field.set(dd, v)),
        );
      case FieldKind.number:
        return MoneyField(
          label: field.label,
          hint: field.hint,
          value: _d(field.get(d)),
          onChanged: (v) => state.mutate((dd) => field.set(dd, v)),
        );
      case FieldKind.text:
      case FieldKind.ssn:
        final raw = _s(field.get(d));
        return TextFieldSpec(
          label: field.label,
          hint: field.hint,
          value: raw,
          onChanged: (v) => state.mutate((dd) => field.set(dd, v)),
        );
      case FieldKind.date:
        final raw = _s(field.get(d));
        return TextFieldSpec(
          label: field.label,
          hint: 'YYYY-MM-DD',
          value: raw.isEmpty ? '' : raw.substring(0, raw.length.clamp(0, 10)),
          onChanged: (v) => state.mutate((dd) => field.set(dd, v)),
        );
      case FieldKind.choice:
        final choices = field.choices ?? const <ChoiceOption<String>>[];
        return ChoiceCards<String>(
          label: field.label,
          value: _s(field.get(d)),
          options: {for (final c in choices) c.value: c.label},
          onChanged: (v) => state.mutate((dd) => field.set(dd, v)),
        );
      case FieldKind.toggle:
        return ToggleRow(
          label: field.label,
          value: _b(field.get(d)),
          onChanged: (v) => state.mutate((dd) => field.set(dd, v)),
        );
    }
  }
}

double _d(Object? v) => (v is num) ? v.toDouble() : 0;
String _s(Object? v) => v == null ? '' : v.toString();
bool _b(Object? v) => v == true;
