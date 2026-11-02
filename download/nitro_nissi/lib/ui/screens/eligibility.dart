/// Eligibility screener — Direct File-inspired: a handful of plain-language
/// yes/no questions up front, then a clear verdict with honest limits.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../shell.dart';

class EligibilityScreen extends StatefulWidget {
  final AppState state;
  const EligibilityScreen({super.key, required this.state});

  @override
  State<EligibilityScreen> createState() => _EligibilityScreenState();
}

class _EligibilityScreenState extends State<EligibilityScreen> {
  int _q = 0;

  static const _questions = [
    ('usCitizenResident', Icons.flag_outlined),
    ('hasValidSsn', Icons.badge_outlined),
    ('incomeSupported', Icons.payments_outlined),
    ('noComplexSituations', Icons.account_tree_outlined),
  ];

  void _answer(bool yes) {
    final key = _questions[_q].$1;
    setState(() {
      switch (key) {
        case 'usCitizenResident':
          widget.state.eligibility.usCitizenResident = yes;
          break;
        case 'hasValidSsn':
          widget.state.eligibility.hasValidSsn = yes;
          break;
        case 'incomeSupported':
          widget.state.eligibility.incomeSupported = yes;
          break;
        case 'noComplexSituations':
          widget.state.eligibility.noComplexSituations = yes;
          break;
      }
      widget.state.eligibilityDone = true;
      _q++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    String qText(int i) {
      switch (_questions[i].$1) {
        case 'usCitizenResident':
          return loc.eligQ1;
        case 'hasValidSsn':
          return loc.eligQ2;
        case 'incomeSupported':
          return loc.eligQ3;
        default:
          return loc.eligQ4;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.eligibilityTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _q < _questions.length
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LinearProgressIndicator(
                          value: _q / _questions.length, minHeight: 4),
                      const SizedBox(height: 32),
                      Icon(_questions[_q].$2, size: 44, color: scheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        qText(_q),
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.tonal(
                            onPressed: () => _answer(true),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(loc.answerYes),
                            ),
                          ),
                          const SizedBox(width: 16),
                          FilledButton.tonal(
                            onPressed: () => _answer(false),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(loc.answerNo),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : _verdict(loc, scheme),
          ),
        ),
      ),
    );
  }

  Widget _verdict(AppLocalizations loc, ColorScheme scheme) {
    final e = widget.state.eligibility;
    final ok = e.allYes;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          ok ? Icons.verified_outlined : Icons.info_outline,
          size: 56,
          color: ok ? scheme.primary : scheme.tertiary,
        ),
        const SizedBox(height: 16),
        Text(
          ok ? loc.eligOkTitle : loc.eligPartialTitle,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          ok ? loc.eligOkBody : loc.eligPartialBody,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          icon: const Icon(Icons.arrow_forward),
          label: Text(loc.eligContinue),
          onPressed: () {
            widget.state.finishEligibility();
            widget.state.finishFirstRun();
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => Shell(state: widget.state)));
          },
        ),
      ],
    );
  }
}
