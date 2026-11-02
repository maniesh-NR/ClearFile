/// Global application state (ChangeNotifier).
///
/// One source of truth for: the return being edited, AI settings, UI
/// preferences, autosave and the derived tax result. UI screens never mutate
/// the model directly — they call [mutate] which marks dirty state and
/// schedules a debounced autosave.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/tax/model.dart';
import '../core/tax/engine.dart';
import '../core/tax/params_2024.dart';
import '../core/tax/params_2025.dart';
import '../core/tax/validation.dart';
import '../core/ai/ai_client.dart';
import '../core/io/tax_file.dart';

class EligibilityAnswers {
  bool usCitizenResident = true;
  bool hasValidSsn = true;
  bool filingForCurrentYear = true;
  bool incomeSupported = true; // wages, interest, dividends, small SE, retirement, unemployment
  bool noComplexSituations = true; // no rental, k-1, farm, foreign income, bankruptcy
  Map<String, dynamic> toJson() => {
        'usCitizenResident': usCitizenResident,
        'hasValidSsn': hasValidSsn,
        'filingForCurrentYear': filingForCurrentYear,
        'incomeSupported': incomeSupported,
        'noComplexSituations': noComplexSituations,
      };

  static EligibilityAnswers fromJson(Map<String, dynamic> j) => EligibilityAnswers()
    ..usCitizenResident = j['usCitizenResident'] as bool? ?? true
    ..hasValidSsn = j['hasValidSsn'] as bool? ?? true
    ..filingForCurrentYear = j['filingForCurrentYear'] as bool? ?? true
    ..incomeSupported = j['incomeSupported'] as bool? ?? true
    ..noComplexSituations = j['noComplexSituations'] as bool? ?? true;

  bool get allYes =>
      usCitizenResident && hasValidSsn && filingForCurrentYear && incomeSupported && noComplexSituations;
}

class AppState extends ChangeNotifier {
  TaxReturnData data = TaxReturnData();
  AiSettings ai = AiSettings();
  EligibilityAnswers eligibility = EligibilityAnswers();

  String? openedFilePath; // desktop only (display name on other platforms)
  bool dirty = false;
  bool firstRunDone = false;
  bool eligibilityDone = false;
  ThemeMode themeMode = ThemeMode.system;
  String localeCode = 'system'; // 'system' | 'en' | 'es'

  final Validator validator = const Validator();
  final FederalEngine engine = const FederalEngine();

  Timer? _autosaveTimer;
  Future<void> Function(AppState state)? autosaveHook;
  Future<void> Function(AppState state)? loadHook;

  YearParams get params => data.taxYear == 2024 ? params2024 : params2025;

  TaxResult get result => engine.compute(data, params);

  List<Issue> get issues => validator.validate(data);

  void mutate(void Function(TaxReturnData d) fn) {
    fn(data);
    dirty = true;
    notifyListeners();
    _scheduleAutosave();
  }

  void mutateAi(void Function(AiSettings a) fn) {
    fn(ai);
    dirty = true;
    notifyListeners();
    _scheduleAutosave();
  }

  void setTaxYear(int year) {
    if (year == data.taxYear) return;
    mutate((d) => d.taxYear = year == 2024 ? 2024 : 2025);
  }

  void newReturn({int taxYear = 2025}) {
    data = TaxReturnData(taxYear: taxYear);
    openedFilePath = null;
    dirty = true;
    notifyListeners();
    _scheduleAutosave();
  }

  void loadReturn(TaxReturnData d, {String? path}) {
    data = d;
    openedFilePath = path;
    dirty = false;
    notifyListeners();
  }

  void markSaved(String? path) {
    openedFilePath = path;
    dirty = false;
    notifyListeners();
  }

  void setThemeMode(ThemeMode m) {
    themeMode = m;
    notifyListeners();
    _scheduleAutosave();
  }

  void setLocale(String code) {
    localeCode = code;
    notifyListeners();
    _scheduleAutosave();
  }

  void finishFirstRun() {
    firstRunDone = true;
    notifyListeners();
    _scheduleAutosave();
  }

  void finishEligibility() {
    eligibilityDone = true;
    notifyListeners();
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 800), () {
      final hook = autosaveHook;
      if (hook != null) unawaited(hook(this));
    });
  }

  // ---- persistence (wire format for settings + prefs) ----
  Map<String, dynamic> preferencesJson() => {
        'firstRunDone': firstRunDone,
        'eligibilityDone': eligibilityDone,
        'themeMode': themeMode.name,
        'localeCode': localeCode,
        'eligibility': eligibility.toJson(),
        'ai': ai.toJson(),
      };

  void loadPreferencesJson(Map<String, dynamic> j) {
    firstRunDone = j['firstRunDone'] as bool? ?? false;
    eligibilityDone = j['eligibilityDone'] as bool? ?? false;
    themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == j['themeMode'], orElse: () => ThemeMode.system);
    localeCode = j['localeCode'] as String? ?? 'system';
    eligibility = j['eligibility'] == null
        ? EligibilityAnswers()
        : EligibilityAnswers.fromJson((j['eligibility'] as Map).cast<String, dynamic>());
    ai = j['ai'] == null
        ? AiSettings()
        : AiSettings.fromJson((j['ai'] as Map).cast<String, dynamic>());
    notifyListeners();
  }

  /// Serialize the current return for autosave (.nnx text).
  String autosavePayload() => TaxFile.save(data);

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    super.dispose();
  }
}
