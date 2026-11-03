import 'dart:io';

import 'package:clearfile/ai/settings.dart';
import 'package:clearfile/io/return_store.dart';
import 'package:clearfile/main.dart';
import 'package:clearfile/models/tax_return.dart';
import 'package:clearfile/models/w2.dart';
import 'package:clearfile/tax/calculator.dart';
import 'package:clearfile/ui/app_state.dart';
import 'package:clearfile/ui/widgets/money_field.dart';
import 'package:clearfile/util/money.dart';
import 'package:flutter_test/flutter_test.dart';

/// File I/O must run inside [WidgetTester.runAsync] in this SDK because the
/// binding's test zone intercepts dart:io Futures and the await never
/// resolves. `pumpAndSettle` is replaced with explicit [TestWidgetsFlutterBinding.pump]
/// durations for the same reason: the AppState autosave [Timer] is a real
/// timer that, when fired inside the binding zone, triggers file I/O that
/// would otherwise hang the settle loop.
///
/// [AppState.dispose] is called explicitly at the end of every test body
/// because the framework's `_verifyInvariants` (which asserts no timers are
/// pending) runs BEFORE addTearDown callbacks. The autosave debounce timer
/// started by [AppState.update] would otherwise trip that assertion.

void main() {
  Future<AppState> bootstrap(WidgetTester tester, String label) async {
    final dir = await tester.runAsync(
        () => Directory('/tmp/clearfile_test_${label}_${DateTime.now().microsecondsSinceEpoch}')
            .create(recursive: true));
    final directory = dir!; // runAsync returns T? but create never returns null.
    final state = AppState(
      store: ReturnStore(directory),
      settingsStore: AiSettingsStore(File('${directory.path}/ai.json')),
    );
    await tester.runAsync(state.bootstrap);
    return state;
  }

  testWidgets('app boots to the welcome screen with the demo banner',
      (tester) async {
    final state = await bootstrap(tester, 'welcome');

    await tester.pumpWidget(ClearFileApp(state: state));
    await tester.pump();

    expect(find.text('ClearFile'), findsWidgets);
    expect(find.text('Demonstration software'), findsOneWidget);
    expect(find.text('Start a 2025 federal return'), findsOneWidget);
    expect(find.text('clean-room tax assistant'), findsOneWidget);
    state.dispose();
  });

  testWidgets('starting a return opens the interview at step 1',
      (tester) async {
    final state = await bootstrap(tester, 'start');

    await tester.pumpWidget(ClearFileApp(state: state));
    await tester.pump();
    // Tap the home-screen button to exercise the real UX path, then wait for
    // the underlying [AppState.startNewReturn] future to finish in a real
    // async zone. The button's onPressed tears off that future and discards
    // it; file I/O in the binding's test zone would otherwise never settle,
    // so we drive the same call ourselves inside runAsync.
    await tester.tap(find.text('Start a 2025 federal return'));
    await tester.runAsync(() => state.startNewReturn());
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.text('Filing status'), findsWidgets);
    expect(find.text('Single'), findsOneWidget);
    state.dispose();
  });

  testWidgets('a wage entry flows through the engine to the results hero',
      (tester) async {
    final state = await bootstrap(tester, 'flow');

    await tester.pumpWidget(ClearFileApp(state: state));
    await tester.pump();
    await tester.tap(find.text('Start a 2025 federal return'));
    await tester.runAsync(() => state.startNewReturn());
    await tester.pumpAndSettle();

    // Jump to the income step.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Add a W-2 and enter wages of 52,500 with 6,200 withheld.
    await tester.tap(find.text('Add W-2'));
    await tester.pumpAndSettle();

    final moneyFields = find.byType(MoneyField);
    expect(moneyFields, findsNWidgets(2));
    await tester.enterText(moneyFields.at(0), '52500');
    await tester.pump();
    await tester.enterText(moneyFields.at(1), '6200');
    await tester.pump();

    // Payments step, then results. Use explicit pump durations instead of
    // pumpAndSettle so the AppState autosave timer's eventual file I/O does
    // not run inside the binding's test zone (which hangs - see header).
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('See my results'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Federal refund expected'), findsOneWidget);
    // The exact figure comes from the same engine the calculator tests
    // hand-verify against published TY2025 parameters. It appears in both
    // the hero card and the Form-1040-style summary, so we accept any
    // positive match count.
    final expected = const TaxCalculator().compute(TaxReturnData(
      w2s: [W2Entry(employer: 'Test', wages: 52500, withholding: 6200)],
    ));
    expect(find.text(formatMoney(expected.refund)), findsWidgets);

    // Entering wages started the 600ms autosave debounce [Timer]. The
    // framework's _verifyInvariants asserts no timers are pending at test
    // end, so dispose (which cancels the timer) before the body returns.
    state.dispose();
  });
}
