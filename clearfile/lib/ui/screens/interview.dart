import 'package:flutter/material.dart';

import '../../models/tax_return.dart';
import '../app_state.dart';
import '../steps/deductions_step.dart';
import '../steps/dependents_step.dart';
import '../steps/income_step.dart';
import '../steps/payments_step.dart';
import '../steps/status_step.dart';

/// The five-step return editor: status, income, deductions, dependents and
/// payments, with a progress header matching the web prototype.
class InterviewScreen extends StatelessWidget {
  const InterviewScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final r = state.current;
        if (r == null) return _EmptyState(state: state);
        final scheme = Theme.of(context).colorScheme;
        final isLast = state.stepIndex == AppState.stepCount - 1;
        return Scaffold(
          appBar: AppBar(
            title: Text(r.displayName),
            actions: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'TY${r.taxYear}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Step ${state.stepIndex + 1} of ${AppState.stepCount}',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppState.stepTitles[state.stepIndex],
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (state.stepIndex + 1) / AppState.stepCount,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
              Expanded(child: _stepFor(state, r)),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: state.stepIndex == 0
                            ? null
                            : state.previousStep,
                        child: const Text('Back'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: isLast
                            ? () => state.selectTab(2)
                            : state.nextStep,
                        child: Text(isLast ? 'See my results' : 'Continue'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _stepFor(AppState state, TaxReturnData r) {
    switch (state.stepIndex) {
      case 0:
        return StatusStep(state: state, r: r);
      case 1:
        return IncomeStep(state: state, r: r);
      case 2:
        return DeductionsStep(state: state, r: r);
      case 3:
        return DependentsStep(state: state, r: r);
      case 4:
        return PaymentsStep(state: state, r: r);
    }
    return const SizedBox.shrink();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note_outlined,
              size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text('No return is open',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Start a return on the Home tab to begin the interview.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: state.startNewReturn,
            icon: const Icon(Icons.add),
            label: const Text('Start a 2025 return'),
          ),
        ],
      ),
    );
  }
}
