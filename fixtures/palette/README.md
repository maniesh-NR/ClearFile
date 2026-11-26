# The palette differential corpus (`cases.json`)

The seed → scheme corpus consumed by the Rust core's palette tests
(D44, N2 session 1, ADR-017's "MD3-from-seed palette generation").

## The contract

- **33 seeds** (the app's own seed `0xFF00696E` + edge seeds incl. black,
  white, the full-sat primaries, gray + a deterministic xorshift64\*
  sample — fixed literals, no clock, no `dart:math` Random).
- Per seed: the **six tonal ladders** (primary/secondary/tertiary/
  neutral/neutralVariant/error, tones 0..100 — the full continuum, not
  just the breakpoints) + the **34 scheme roles for light AND dark**
  (primary…tertiary containers, the error family, outline/s, the
  surface container ladder, onSurfaceVariant, the inverse family, shadow,
  scrim, surfaceTint).
- **Integer ARGB parity, tolerance 0 by construction** — integer values
  admit no tolerance. These are NOT golden fixtures (the annex-(d)
  authoring discipline applies to `fixtures/tax/`): every expected value
  is the reference implementation's own output.

## The reference (the app's exact call path)

- **material_color_utilities 0.13.0** (content hash
  `9c337007e82b1889149c82ed242ed1cb24a66044e30979c44912381e9be4c48b` —
  the version and hash `clearfile/pubspec.lock` resolves, NOT "3.47.9";
  that is the Flutter SDK version).
- The scheme roles come from **`ColorScheme.fromSeed`** itself (the exact
  API `clearfile/lib/main.dart:62-64` calls), via the scratch package at
  `scripts/palette_tool/` (which exists so the generator can call the
  framework API under `flutter test` without touching `clearfile/`).
- The tonal ladders come from the `SchemeTonalSpot` DynamicScheme that
  `ColorScheme.fromSeed` constructs (MCU 0.13.0's SchemeTonalSpot:
  primary chroma 36, secondary 16, tertiary hue+60/chroma 24, neutral 6,
  neutralVariant 8).

## Regeneration (byte-identical)

```
cd scripts/palette_tool
../../tools/flutter/bin/flutter test test/generate_palette_fixtures.dart
sha256sum ../../fixtures/palette/cases.json
```

Two consecutive runs are byte-identical. The committed file's digest is
`da1ceaf4b37f1ac851fcef7fde0833c7c90d746842986c1a14737177ef3252b7`.
If a run disagrees, something non-deterministic has been introduced —
treat it as a defect, never commit the drift. The scratch package's
`pubspec.lock` must keep resolving the same material_color_utilities
content hash (check with `grep -A4 material_color_utilities
scripts/palette_tool/pubspec.lock`).
