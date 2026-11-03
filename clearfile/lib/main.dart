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
    store: ReturnStore(base),
    settingsStore: AiSettingsStore(File('${base.path}/ai_settings.json')),
  );
  await state.bootstrap();
  runApp(ClearFileApp(state: state));
}

class ClearFileApp extends StatelessWidget {
  const ClearFileApp({super.key, required this.state});

  final AppState state;

  /// Teal seed matching the web prototype's MD3 scheme.
  static const Color _seed = Color(0xFF00696E);

  @override
  Widget build(BuildContext context) {
    // Teal seed matching the web prototype's MD3 scheme. (Dynamic wallpaper
    // color was dropped: the dynamic_color package's ColorScheme type
    // conflicts with the material_ui split shipped with Flutter 3.47.)
    final light = ColorScheme.fromSeed(seedColor: _seed);
    final dark =
        ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
    return MaterialApp(
      title: 'ClearFile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: light,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: dark,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      themeMode: ThemeMode.system,
      home: Shell(state: state),
    );
  }
}
