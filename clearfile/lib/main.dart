// SPDX-License-Identifier: GPL-3.0-only
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'ai/settings.dart';
import 'io/return_store.dart';
import 'ui/app_state.dart';
import 'ui/shell.dart';

/// ClearFile - a clean-room, demonstration tax-return prototype.
///
/// THIS IS DEMONSTRATION SOFTWARE: it is not IRS-authorized, cannot e-file,
/// and must not be used to prepare a real tax return.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final base = await getApplicationDocumentsDirectory();
  final state = AppState(
    store: FileReturnStore(base),
    settingsStore:
        AiSettingsStore(File('${base.path}/$aiSettingsFileName')),
  );
  await state.bootstrap();
  runApp(ClearFileApp(state: state));
}

class ClearFileApp extends StatelessWidget {
  const ClearFileApp({super.key, required this.state});

  final AppState state;

  /// Teal seed matching the web prototype's MD3 scheme.
  ///
  /// "Material You" here means the MD3 tonal-palette system Flutter itself
  /// ships (`ColorScheme.fromSeed`, built on material_color_utilities) —
  /// one seed grows the full primary/secondary/tertiary tonal scheme and
  /// every component follows it, identically on Android, iOS, macOS,
  /// Windows, Linux and web. Wallpaper-derived dynamic color is Android
  /// 12+ only by platform capability and stays dropped per ADR-007
  /// (dynamic_color/Flutter 3.47 incompatibility). The 2026-11-15 retry
  /// against dynamic_color 2.1.0 hit the same recorded clash
  /// (argument_type_not_assignable against the material_ui split) and was
  /// reverted; the next revisit rides a release rebuilt for the split.
  static const Color _seed = Color(0xFF00696E);

  @override
  Widget build(BuildContext context) {
    final light = ColorScheme.fromSeed(seedColor: _seed);
    final dark =
        ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
    return MaterialApp(
      title: 'ClearFile',
      debugShowCheckedModeBanner: false,
      theme: _md3Theme(light),
      darkTheme: _md3Theme(dark),
      themeMode: ThemeMode.system,
      home: Shell(state: state),
    );
  }

  /// Material 3 theme grown from the seed scheme: flat tint-free surfaces,
  /// floating snackbars, comfortable filled buttons — the same MD3
  /// component styling on every operating system.
  ThemeData _md3Theme(ColorScheme scheme) => ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          surfaceTintColor: scheme.surface,
          centerTitle: false,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        dialogTheme: DialogThemeData(
          surfaceTintColor: scheme.surface,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      );
}
