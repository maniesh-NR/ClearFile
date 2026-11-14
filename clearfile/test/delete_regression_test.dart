import 'dart:io';

import 'package:clearfile/ai/settings.dart';
import 'package:clearfile/io/return_store.dart';
import 'package:clearfile/ui/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression for ADV-ENG Stage-0 finding 1 (2026-11-14):
/// deleting the open return inside the 600 ms autosave debounce window used
/// to resurrect it on disk — the timer captured the return object and rewrote
/// the JSON after `store.delete`.
///
/// Plain `test()` (not `testWidgets`): file I/O resolves fine outside the
/// binding's widget-test zone; a fixed /tmp path avoids
/// `Directory.systemTemp` quirks (see widget_test.dart header).
void main() {
  test('deleting the open return inside the autosave window does not resurrect it',
      () async {
    final path =
        '/tmp/clearfile_delete_test_${DateTime.now().microsecondsSinceEpoch}';
    final dir = Directory(path);
    await dir.create(recursive: true);
    addTearDown(() => dir.delete(recursive: true));

    final state = AppState(
      store: ReturnStore(dir),
      settingsStore: AiSettingsStore(File('$path/ai.json')),
    );

    await state.startNewReturn();
    final id = state.current!.id;

    // Arm the autosave debounce (a no-op mutation still schedules the Timer).
    state.update((r) {});

    // Delete inside the 600 ms window.
    await state.deleteReturn(state.current!);
    expect(state.current, isNull);

    // Let any unguarded timer fire.
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final listed = await state.store.listReturns();
    expect(listed.where((r) => r.id == id), isEmpty,
        reason: 'the debounced autosave resurrected the deleted return');

    state.dispose();
  });
}
