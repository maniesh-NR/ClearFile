// SPDX-License-Identifier: GPL-3.0-only
import 'dart:io';

import 'package:clearfile/ai/settings.dart';
import 'package:clearfile/models/dependent.dart';
import 'package:clearfile/models/filing_status.dart';
import 'package:clearfile/models/w2.dart';
import 'package:clearfile/ui/app_state.dart';
import 'package:clearfile/ui/screens/settings.dart';
import 'package:clearfile/ui/steps/deductions_step.dart';
import 'package:clearfile/ui/steps/dependents_step.dart';
import 'package:clearfile/ui/steps/income_step.dart';
import 'package:clearfile/ui/steps/payments_step.dart';
import 'package:clearfile/ui/steps/status_step.dart';
import 'package:clearfile/ui/widgets/money_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Per-interview-step widget coverage (Stage-1 item 8), plus the two
/// duplicate-row guards (D6): value-equal W-2s / dependents and duplicated
/// model-chain entries.
///
/// Conventions (ADR-006, extended by the D4 seam): the fake
/// [FakeReturnStore] does no filesystem work, so state mutations and
/// `startNewReturn()` resolve inside the binding's test zone with no
/// `runAsync` wrapping. The only dart:io left is `AiSettingsStore.load()`
/// in `boot()` and the fire-and-forget settings save inside
/// `updateSettings()` (never awaited, never completed in-zone — harmless,
/// assertions target in-memory state). `AppState.dispose()` still must run
/// before each test body returns: `update()` arms a real 600 ms autosave
/// Timer and `_verifyInvariants` asserts no pending timers at test end.
void main() {
  Future<AppState> boot(WidgetTester tester, String label) async {
    // Tall surface so whole step ListViews build and stay visible without
    // scrolling.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final state = AppState(
      store: FakeReturnStore(),
      settingsStore: AiSettingsStore(File(
          '/tmp/clearfile_steps_${label}_${DateTime.now().microsecondsSinceEpoch}.json')),
    );
    await tester.runAsync(state.bootstrap);
    await state.startNewReturn();
    return state;
  }

  /// Hosts a step the way the real shell does: wrapped in a
  /// ListenableBuilder so state mutations (notifyListeners) rebuild the
  /// step, exactly like `Shell` does in production.
  Widget host(AppState state, Widget Function() build) => MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: state,
            builder: (context, _) => build(),
          ),
        ),
      );

  testWidgets('status step: filing status radio and the 65+ switches land',
      (tester) async {
    final state = await boot(tester, 'status');
    final r = state.current!;

    await tester.pumpWidget(
        host(state, () => StatusStep(state: state, r: state.current!)));

    expect(find.text('Single'), findsOneWidget);
    expect(find.text('Married filing jointly'), findsOneWidget);
    // Spouse switches only exist once a joint status is selected.
    expect(find.text('My spouse was 65 or older'), findsNothing);

    await tester.tap(find.text('Married filing jointly'));
    await tester.pump();
    expect(r.filingStatus, FilingStatus.marriedJoint);
    expect(find.text('My spouse was 65 or older'), findsOneWidget);
    expect(find.text('My spouse is legally blind'), findsOneWidget);

    await tester.tap(find.text('I was 65 or older on Dec 31, 2025'));
    await tester.pump();
    expect(r.taxpayer65OrOlder, isTrue);

    state.dispose();
  });

  testWidgets(
      'income step: two value-equal blank W-2s stay distinct (D6 guard)',
      (tester) async {
    final state = await boot(tester, 'income');
    final r = state.current!;

    await tester.pumpWidget(
        host(state, () => IncomeStep(state: state, r: state.current!)));

    await tester.tap(find.text('Add W-2'));
    await tester.pump();
    // Second blank W-2 added through the state seam: it is value-EQUAL to
    // the first (W2Entry implements ==), so ValueKey(w2) would have thrown
    // 'Duplicate keys' right here. ObjectKey keeps the cards distinct.
    state.update((x) => x.w2s.add(W2Entry()));
    await tester.pump();

    expect(r.w2s, hasLength(2));
    expect(find.text('W-2'), findsNWidgets(2));
    expect(find.text('Employer name'), findsNWidgets(2));

    // Fill the first card.
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Employer name').first, 'Acme Corp');
    await tester.enterText(
        find
            .widgetWithText(MoneyField, 'Box 1 - wages, tips, other compensation')
            .first,
        '52500');
    await tester.pump();
    expect(r.w2s[0].employer, 'Acme Corp');
    expect(r.w2s[0].wages, 52500);
    expect(find.text('W-2 - Acme Corp'), findsOneWidget);

    // Remove the first card: identity removal leaves exactly one W-2
    // (the old List.remove would also have dropped the first EQUAL entry,
    // which here is the same card; the guard is the two-blank-rows render
    // above).
    await tester.tap(find.byTooltip('Remove this W-2').first);
    await tester.pump();
    expect(r.w2s, hasLength(1));
    expect(find.text('W-2'), findsOneWidget);
    expect(find.text('W-2 - Acme Corp'), findsNothing);

    state.dispose();
  });

  testWidgets('deductions step: comparison chips track itemized inputs',
      (tester) async {
    final state = await boot(tester, 'deductions');
    final r = state.current!;

    await tester.pumpWidget(
        host(state, () => DeductionsStep(state: state, r: state.current!)));

    // Empty return: standard wins, itemized is zero.
    expect(find.textContaining('Standard \$'), findsOneWidget);
    expect(find.textContaining('Itemized \$0'), findsOneWidget);
    expect(find.text('Standard deduction is larger'), findsOneWidget);

    // Enter SALT and real-estate taxes; the itemized chip must follow.
    await tester.enterText(
        find
            .widgetWithText(MoneyField, 'State & local income or sales tax (SALT)')
            .first,
        '10000');
    await tester.pump();
    expect(find.textContaining('Itemized \$10,000'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(MoneyField, 'Real estate taxes').first, '2000');
    await tester.pump();
    expect(find.textContaining('Itemized \$12,000'), findsOneWidget);

    // Adjustments-to-income card.
    await tester.enterText(
        find
            .widgetWithText(MoneyField, 'Student loan interest (1098-E, Box 1)')
            .first,
        '800');
    await tester.pump();
    expect(r.studentLoanInterest, 800);

    state.dispose();
  });

  testWidgets(
      'dependents step: two value-equal blank dependents stay distinct (D6 guard)',
      (tester) async {
    final state = await boot(tester, 'dependents');
    final r = state.current!;

    await tester.pumpWidget(
        host(state, () => DependentsStep(state: state, r: state.current!)));

    await tester.tap(find.text('Add dependent'));
    await tester.pump();
    // Second blank dependent: value-EQUAL to the first (Dependent implements
    // ==); ValueKey(d) would have thrown 'Duplicate keys' here.
    state.update((x) => x.dependents.add(Dependent()));
    await tester.pump();

    expect(r.dependents, hasLength(2));
    expect(find.text('New dependent'), findsNWidgets(2));
    expect(find.text('First and last name'), findsNWidgets(2));

    // Fill the first card and flip its credit switch.
    await tester.enterText(
        find.widgetWithText(TextFormField, 'First and last name').first,
        'Ada Lovelace');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Age at the end of 2025').first,
        '10');
    await tester.tap(find.text('Qualifying child under 17').first);
    await tester.pump();
    expect(r.dependents[0].name, 'Ada Lovelace');
    expect(r.dependents[0].age, 10);
    expect(r.dependents[0].qualifyingChild, isTrue);
    expect(r.dependents[1].qualifyingChild, isFalse);

    // Remove the first card; exactly one remains.
    await tester.tap(find.byTooltip('Remove').first);
    await tester.pump();
    expect(r.dependents, hasLength(1));
    expect(r.dependents.single.name, '');

    state.dispose();
  });

  testWidgets('payments step: summary adds withholding and estimates',
      (tester) async {
    final state = await boot(tester, 'payments');
    final r = state.current!;
    state.update((x) => x.w2s
        .add(W2Entry(employer: 'Acme', wages: 52500, withholding: 6200)));

    await tester.pumpWidget(
        host(state, () => PaymentsStep(state: state, r: state.current!)));

    await tester.enterText(
        find
            .widgetWithText(MoneyField, 'Estimated federal tax payments')
            .first,
        '1000');
    await tester.pump();
    expect(r.estimatedPayments, 1000);

    expect(find.textContaining('Withholding from 1 W-2: \$6,200'),
        findsOneWidget);
    expect(find.textContaining('Estimated payments: \$1,000'), findsOneWidget);
    expect(find.textContaining('Total payments: \$7,200'), findsOneWidget);

    state.dispose();
  });

  testWidgets(
      'settings: removing a duplicated chain model drops exactly one row (D6 guard)',
      (tester) async {
    final state = await boot(tester, 'chain');

    // Seed a duplicate of the first chain entry (value-equal, distinct row).
    final first = state.settings.chain.first;
    await tester.runAsync(() async {
      state.updateSettings((s) {
        s.chain.add(AiModelSpec(provider: first.provider, modelId: first.modelId));
      });
    });

    await tester.pumpWidget(
        host(state, () => SettingsScreen(state: state)));
    final modelId = state.settings.chain.first.modelId;
    final before = state.settings.chain.length;

    // Remove via the first duplicate's tile. The old removeWhere would
    // delete BOTH copies at once; the fix must drop exactly one.
    await tester.tap(find.byTooltip('Remove from chain').first);
    await tester.pump();

    expect(state.settings.chain, hasLength(before - 1));
    expect(
      state.settings.chain.where((m) => m.modelId == modelId),
      hasLength(1),
    );

    state.dispose();
  });
}
