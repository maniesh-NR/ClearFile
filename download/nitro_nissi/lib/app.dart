/// App root: wires AppState, autosave, theming and localization.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'state/app_state.dart';
import 'core/io/tax_file.dart';
import 'services/platform_io.dart';
import 'ui/theme.dart';
import 'ui/screens/welcome.dart';

class NitroApp extends StatefulWidget {
  final AppState state;
  const NitroApp({super.key, required this.state});

  @override
  State<NitroApp> createState() => _NitroAppState();
}

class _NitroAppState extends State<NitroApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    widget.state.autosaveHook = _autosave;
    _restore();
    widget.state.addListener(_syncLocale);
    _syncLocale();
  }

  @override
  void dispose() {
    widget.state.removeListener(_syncLocale);
    super.dispose();
  }

  void _syncLocale() {
    final code = widget.state.localeCode;
    final next = code == 'system' ? null : Locale(code);
    if (next != _locale) {
      setState(() => _locale = next);
    }
  }

  Future<void> _autosave(AppState s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nn_prefs', jsonEncode(s.preferencesJson()));
      if (ioBackend.hasFileSystem) {
        final dir = await const PlatformIo().returnsDirectory();
        final path = s.openedFilePath ??
            '$dir/autosave.nnx'; // backend normalizes separators
        await const PlatformIo()
            .saveBytes(path, 'autosave.nnx', utf8.encode(s.autosavePayload()));
      }
    } catch (_) {
      // Autosave failures are non-fatal by design.
    }
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('nn_prefs');
      if (raw != null) {
        widget.state
            .loadPreferencesJson((jsonDecode(raw) as Map).cast<String, dynamic>());
      }
      if (ioBackend.hasFileSystem) {
        final dir = await const PlatformIo().returnsDirectory();
        if (dir != null) {
          final text = await ioBackend.readFileText('$dir/autosave.nnx');
          if (text != null) {
            try {
              final data = TaxFile.load(text);
              widget.state.loadReturn(data, path: null);
            } catch (_) {
              // Corrupt autosave: keep fresh return, preserve prefs.
            }
          }
        }
      }
    } catch (_) {
      // First run or unreadable storage: defaults are fine.
    }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: 'Nitro Nissi',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(lightDynamic),
          darkTheme: buildDarkTheme(darkDynamic),
          themeMode: widget.state.themeMode,
          locale: _locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WelcomeScreen(state: widget.state),
        );
      },
    );
  }
}
