// SPDX-License-Identifier: GPL-3.0-only
/// The palette-fixture generator (N2 session 1, D44): emits the seed →
/// scheme corpus consumed by the Rust core's palette tests
/// (`fixtures/palette/cases.json`).
///
/// ## The reference (the app's exact call path)
///
/// The shipped Flutter app themes via `ColorScheme.fromSeed(seedColor:
/// …, brightness: …)` (`clearfile/lib/main.dart:62-64`). This generator
/// calls THAT EXACT API under `flutter test` — no reimplementation: the
/// corpus's role values come from `ColorScheme.fromSeed` itself, and the
/// tonal ladders from `SchemeTonalSpot` (the exact DynamicScheme
/// `ColorScheme.fromSeed` constructs internally — Flutter 3.47.9's
/// `color_scheme.dart` is a straight `MaterialDynamicColors.*.getArgb`
/// pass-through, verified at the N2 gate against the SDK).
///
/// ## Provenance
///
/// - material_color_utilities **0.13.0** (NOT "3.47.9" — that is the SDK
///   version; the N2 gate corrected the mislabel), pinned in the pubspec;
///   the scratch `pubspec.lock` must resolve the same content hash
///   `9c337007…48b` clearfile/pubspec.lock does (checked by hand at
///   regeneration per fixtures/palette/README.md).
/// - NOT golden fixtures: the annex-(d) authoring discipline applies to
///   `fixtures/tax/`; this corpus is the palette differential contract
///   (the reference's own outputs, integer parity — tolerance 0 by
///   construction; integer ARGB admits no tolerance).
///
/// ## Determinism
///
/// MCU is pure deterministic math; the seed list is a fixed literal (the
/// app's own seed plus a deterministic xorshift sample with edge seeds);
/// no timestamps anywhere in the output. Two runs are byte-identical
/// (verified at generation; the corpus README carries the digest).
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter/material.dart' show ColorScheme, Brightness;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// The app's own seed (`clearfile/lib/main.dart:58`).
const int appSeed = 0xFF00696E;

/// The scheme roles `ColorScheme.fromSeed` produces (the M3 role set,
/// field-by-field from Flutter 3.47.9's ColorScheme; each is a straight
/// MaterialDynamicColors pass-through). Ordered by the spec's role
/// families: primary, secondary, tertiary, error, then outline, the
/// surface container ladder, then the inverse/shadow family.
const List<String> schemeRoles = [
  'primary', 'onPrimary', 'primaryContainer', 'onPrimaryContainer',
  'secondary', 'onSecondary', 'secondaryContainer', 'onSecondaryContainer',
  'tertiary', 'onTertiary', 'tertiaryContainer', 'onTertiaryContainer',
  'error', 'onError', 'errorContainer', 'onErrorContainer',
  'outline', 'outlineVariant',
  'surface', 'onSurface',
  'surfaceDim', 'surfaceBright',
  'surfaceContainerLowest', 'surfaceContainerLow', 'surfaceContainer',
  'surfaceContainerHigh', 'surfaceContainerHighest',
  'onSurfaceVariant',
  'inverseSurface', 'onInverseSurface', 'inversePrimary',
  'shadow', 'scrim', 'surfaceTint',
];

/// The six tonal palettes a DynamicScheme carries (ladder = tones 0..100).
const List<String> paletteNames = [
  'primary', 'secondary', 'tertiary',
  'neutral', 'neutralVariant', 'error',
];

/// A straight field pass-through — no mapping decisions of our own.
/// Every ColorScheme field the corpus pins, one explicit case, in the
/// same order as [schemeRoles] (the N2-gate ENG-1 field-by-field
/// requirement).
int roleValue(ColorScheme s, String role) {
  final Color c = switch (role) {
    'primary' => s.primary,
    'onPrimary' => s.onPrimary,
    'primaryContainer' => s.primaryContainer,
    'onPrimaryContainer' => s.onPrimaryContainer,
    'secondary' => s.secondary,
    'onSecondary' => s.onSecondary,
    'secondaryContainer' => s.secondaryContainer,
    'onSecondaryContainer' => s.onSecondaryContainer,
    'tertiary' => s.tertiary,
    'onTertiary' => s.onTertiary,
    'tertiaryContainer' => s.tertiaryContainer,
    'onTertiaryContainer' => s.onTertiaryContainer,
    'error' => s.error,
    'onError' => s.onError,
    'errorContainer' => s.errorContainer,
    'onErrorContainer' => s.onErrorContainer,
    'outline' => s.outline,
    'outlineVariant' => s.outlineVariant,
    'surface' => s.surface,
    'onSurface' => s.onSurface,
    'surfaceDim' => s.surfaceDim,
    'surfaceBright' => s.surfaceBright,
    'surfaceContainerLowest' => s.surfaceContainerLowest,
    'surfaceContainerLow' => s.surfaceContainerLow,
    'surfaceContainer' => s.surfaceContainer,
    'surfaceContainerHigh' => s.surfaceContainerHigh,
    'surfaceContainerHighest' => s.surfaceContainerHighest,
    'onSurfaceVariant' => s.onSurfaceVariant,
    'inverseSurface' => s.inverseSurface,
    'onInverseSurface' => s.onInverseSurface,
    'inversePrimary' => s.inversePrimary,
    'shadow' => s.shadow,
    'scrim' => s.scrim,
    'surfaceTint' => s.surfaceTint,
    _ => throw ArgumentError('unmapped role: $role'),
  };
  return c.value;
}

/// Deterministic xorshift64* over the 32-bit opaque-color space.
class SeedRng {
  int state;
  SeedRng(this.state);
  int next() {
    var x = state;
    x ^= x >>> 12;
    x = (x << 25) & 0xFFFFFFFFFFFFFFFF; // 64-bit wrap on the VM
    x ^= x >>> 27;
    state = x;
    return (x * 0x2545F4914F6CDD1D) & 0xFFFFFFFFFFFFFFFF;
  }

  int nextOpaqueColor() => 0xFF000000 | (next() & 0x00FFFFFF);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate the palette corpus (D44)', () {
    // 1. The seed list: the app seed + edge seeds + the deterministic
    //    sample. Fixed literals — no clock, no dart:math Random.
    final seeds = <int>[appSeed, 0xFF000000, 0xFFFFFFFF, 0xFFFF0000,
      0xFF00FF00, 0xFF0000FF, 0xFF808080, 0xFF123456];
    final rng = SeedRng(0x9E3779B97F4A7C15);
    while (seeds.length < 33) {
      seeds.add(rng.nextOpaqueColor());
    }

    // 2. Emit: per seed — the six tonal ladders (tones 0..100) once,
    //    then the scheme roles for light AND dark.
    final entries = <Map<String, Object?>>[];
    for (final seed in seeds) {
      final hct = Hct.fromInt(seed);
      // MCU 0.13.0: the variant class CONSTRUCTS the DynamicScheme
      // (SchemeTonalSpot: primary chroma 36, secondary 16, tertiary
      // hue+60/chroma 24, neutral 6, neutralVariant 8 — the exact
      // scheme ColorScheme.fromSeed builds).
      final dynamic scheme = SchemeTonalSpot(
        sourceColorHct: hct,
        isDark: false,
        contrastLevel: 0.0,
      );
      final ladders = <String, List<int>>{};
      final palettes = <String, TonalPalette>{
        'primary': scheme.primaryPalette,
        'secondary': scheme.secondaryPalette,
        'tertiary': scheme.tertiaryPalette,
        'neutral': scheme.neutralPalette,
        'neutralVariant': scheme.neutralVariantPalette,
        'error': scheme.errorPalette,
      };
      for (final name in paletteNames) {
        ladders[name] =
            List<int>.generate(101, (tone) => palettes[name]!.get(tone));
      }

      ColorScheme roleScheme(int brightnessIsDark) => ColorScheme.fromSeed(
            seedColor: Color(seed),
            brightness:
                brightnessIsDark == 1 ? Brightness.dark : Brightness.light,
          );
      Map<String, int> rolesOf(ColorScheme s) => {
            for (final role in schemeRoles) role: roleValue(s, role),
          };

      entries.add({
        'seed': seed,
        'seedArgb': '0x${seed.toRadixString(16).padLeft(8, '0').toUpperCase()}',
        'ladders': ladders,
        'light': rolesOf(roleScheme(0)),
        'dark': rolesOf(roleScheme(1)),
      });
    }

    const expectedMcuHash =
        '9c337007e82b1889149c82ed242ed1cb24a66044e30979c44912381e9be4c48b';
    final doc = <String, Object?>{
      'kind': 'clearfile-palette',
      'generator': 'scripts/palette_tool/test/generate_palette_fixtures.dart',
      'reference':
          'material_color_utilities 0.13.0 (content hash $expectedMcuHash) '
          'via Flutter 3.47.9 ColorScheme.fromSeed — the app\'s exact call '
          'path (SchemeTonalSpot, contrast 0); the tonal ladders from the '
          'DynamicScheme the same API constructs',
      'mcuSha256': expectedMcuHash,
      'seedCount': entries.length,
      'roleCount': schemeRoles.length,
      'paletteCount': paletteNames.length,
      'note': 'Palette differential corpus per D44/ADR-017: inputs are '
          'fixed seed literals; every expected value is the reference '
          'implementation\'s own output (integer ARGB — parity admits no '
          'tolerance). NOT golden fixtures: the annex-(d) discipline '
          'applies to fixtures/tax/. Consumed by the Rust core\'s palette '
          'tests (fixtures/palette/cases.json).',
      'cases': entries,
    };

    // Resolve against the package root (the test CWD), two levels up to
    // the repo root, then fixtures/palette/ — never a bare ../fixtures
    // (which lands under scripts/).
    final out = File('../../fixtures/palette/cases.json');
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(doc) + '\n');

    // 3. The self-check: every value in the opaque range, every seed
    //    accounted for.
    expect(entries.length, 33);
    expect(schemeRoles.length, 34);
    for (final e in entries) {
      final ladders = e['ladders'] as Map<String, List<int>>;
      expect(ladders.length, 6);
      for (final name in paletteNames) {
        expect(ladders[name]!.length, 101);
        for (final v in ladders[name]!) {
          expect(v, inInclusiveRange(0, 0xFFFFFFFF));
        }
      }
      for (final b in ['light', 'dark']) {
        final roles = e[b] as Map<String, int>;
        expect(roles.length, schemeRoles.length);
        for (final v in roles.values) {
          expect(v, inInclusiveRange(0, 0xFFFFFFFF));
        }
      }
    }
    // ignore: avoid_print
    print('palette corpus: ${entries.length} seeds × '
        '(6 ladders × 101 tones + 2 × ${schemeRoles.length} roles) written');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
