/// Material Design 3 theming.
///
/// Brand seed: deep indigo. On Android 12+ we blend the system dynamic
/// palette when the user enables it; everywhere else we use the seeded
/// schemes so the app looks identical across platforms (a TurboTax-like
/// familiar layout in Material You clothing).
library;

import 'package:flutter/material.dart';

const Color kSeedLight = Color(0xFF283593); // Indigo 800
const Color kSeedDark = Color(0xFF9FA8DA);

const kBrandSurfaceLight = Color(0xFFFCF8FF);
const kBrandSurfaceDark = Color(0xFF121318);

ThemeData buildLightTheme(ColorScheme? dynamicScheme) {
  final scheme = dynamicScheme ??
      ColorScheme.fromSeed(seedColor: kSeedLight, brightness: Brightness.light);
  return _base(scheme, kBrandSurfaceLight);
}

ThemeData buildDarkTheme(ColorScheme? dynamicScheme) {
  final scheme = dynamicScheme ??
      ColorScheme.fromSeed(seedColor: kSeedDark, brightness: Brightness.dark);
  return _base(scheme, kBrandSurfaceDark);
}

ThemeData _base(ColorScheme scheme, Color surface) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: surface,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      isDense: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(120, 48),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(96, 44)),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withAlpha(120)),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: surface,
      scrolledUnderElevation: 2,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
