import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ai/assistant.dart';
import '../ai/cascade.dart';
import '../ai/providers.dart';
import '../ai/settings.dart';
import '../io/files.dart';
import '../io/return_store.dart';
import '../models/tax_return.dart';
import '../tax/calculator.dart';
import '../tax/results.dart';
import '../tax/review_rules.dart';

/// App-wide state: the open return, its computed result, AI settings and the
/// assistant conversation.
///
/// Every mutation goes through [update], which recomputes the return and
/// schedules a debounced autosave. The UI listens with [ListenableBuilder].
class AppState extends ChangeNotifier {
  AppState({required this.store, required this.settingsStore});

  final ReturnStore store;
  final AiSettingsStore settingsStore;
  final ClearFileAssistant assistant = ClearFileAssistant(AiCascade());

  /// The return being edited, or null when none is open.
  TaxReturnData? current;
  TaxResult? result;
  List<TaxReturnData> savedReturns = const [];

  /// Shell navigation index: 0 Home, 1 Return, 2 Results, 3 Assistant,
  /// 4 Settings.
  int selectedIndex = 0;

  /// Interview step within the return editor (0-4).
  int stepIndex = 0;
  static const int stepCount = 5;
  static const List<String> stepTitles = [
    'Filing status',
    'Income',
    'Deductions',
    'Dependents',
    'Payments',
  ];

  final List<ChatTurn> chat = [];
  bool assistantBusy = false;
  String? assistantError;
  String? servedByLabel;

  Timer? _saveDebounce;

  AiSettings get settings => settingsStore.settings;

  Future<void> bootstrap() async {
    await settingsStore.load();
    savedReturns = await store.listReturns();
    notifyListeners();
  }

  void selectTab(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  void nextStep() {
    if (stepIndex < stepCount - 1) {
      stepIndex++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (stepIndex > 0) {
      stepIndex--;
      notifyListeners();
    }
  }

  Future<void> startNewReturn() async {
    final r = TaxReturnData();
    await store.save(r);
    savedReturns = await store.listReturns();
    _open(r);
  }

  Future<void> openReturn(TaxReturnData r) async {
    _open(r);
  }

  Future<void> importFromFile() async {
    final r = await ReturnFileIO.importReturn();
    if (r == null) return;
    await store.save(r);
    savedReturns = await store.listReturns();
    _open(r);
  }

  Future<void> exportCurrent() async {
    final r = current;
    if (r == null) return;
    await ReturnFileIO.exportReturn(r);
  }

  void _open(TaxReturnData r) {
    current = r;
    stepIndex = 0;
    selectedIndex = 1;
    _recompute();
    notifyListeners();
  }

  Future<void> closeReturn() async {
    _saveDebounce?.cancel();
    final r = current;
    if (r != null) await store.save(r);
    savedReturns = await store.listReturns();
    current = null;
    result = null;
    selectedIndex = 0;
    notifyListeners();
  }

  Future<void> deleteReturn(TaxReturnData r) async {
    await store.delete(r.id);
    if (current?.id == r.id) {
      current = null;
      result = null;
      selectedIndex = 0;
    }
    savedReturns = await store.listReturns();
    notifyListeners();
  }

  /// Applies [mutate] to the open return, recomputes and schedules a save.
  void update(void Function(TaxReturnData r) mutate) {
    final r = current;
    if (r == null) return;
    mutate(r);
    r.modified = DateTime.now();
    _recompute();
    notifyListeners();
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), () {
      store.save(r);
    });
  }

  void updateSettings(void Function(AiSettings s) mutate) {
    mutate(settingsStore.settings);
    settingsStore.save();
    notifyListeners();
  }

  void _recompute() {
    result = current == null ? null : const TaxCalculator().compute(current!);
  }

  // --- Assistant ------------------------------------------------------------

  Future<void> sendAssistantMessage(String text) async {
    if (text.trim().isEmpty || assistantBusy) return;
    chat.add(ChatTurn(fromUser: true, content: text.trim()));
    await _runAssistant();
  }

  /// Sends the pre-submit AI review request and shows the reply in the chat.
  Future<void> runAssistantReview() async {
    if (assistantBusy) return;
    final r = current;
    final res = result;
    if (r == null || res == null) return;
    final findings = runReview(r, res);
    final prompt = assistant.buildReviewPrompt(r, res, findings);
    chat.add(const ChatTurn(
        fromUser: true, content: 'Please review my return before I finish.'));
    await _runAssistant(userOverride: prompt);
  }

  Future<void> _runAssistant({String? userOverride}) async {
    assistantBusy = true;
    assistantError = null;
    notifyListeners();
    try {
      final conversation = userOverride == null
          ? List<ChatTurn>.of(chat)
          : [
              ...chat.sublist(0, chat.length - 1),
              ChatTurn(fromUser: true, content: userOverride),
            ];
      final outcome = await assistant.sendMessage(
        settings: settings,
        conversation: conversation,
        returnData: current,
        result: result,
      );
      chat.add(ChatTurn(fromUser: false, content: outcome.text));
      servedByLabel = outcome.servedBy.label;
    } on AiCascadeException catch (e) {
      assistantError = e.toString();
    } catch (e) {
      assistantError = e.toString();
    } finally {
      assistantBusy = false;
      notifyListeners();
    }
  }

  Future<String> testConnection() async {
    try {
      final outcome = await assistant.cascade.complete(
        settings: settings,
        system: 'You are a connectivity test. Reply with exactly: OK',
        conversation: const [ChatTurn(fromUser: true, content: 'ping')],
        maxTokens: 8,
      );
      return 'OK - answered by ${outcome.servedBy.label}';
    } on AiCascadeException catch (e) {
      return 'Failed - $e';
    }
  }

  void clearChat() {
    chat.clear();
    assistantError = null;
    servedByLabel = null;
    notifyListeners();
  }

  /// Cancels the pending autosave timer. Call from `dispose()` in tests and
  /// when the state owner is torn down; otherwise the [Timer] started by
  /// [update] can outlive the widget tree and leak.
  ///
  /// Idempotent: a second call (e.g. once from the test body, once from the
  /// framework's tree teardown) is a safe no-op. The base class asserts
  /// against double-dispose in debug mode, so we guard with a local flag.
  bool _disposed = false;
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _saveDebounce?.cancel();
    super.dispose();
  }
}
