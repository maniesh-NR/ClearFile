// SPDX-License-Identifier: GPL-3.0-only
/// Money and percent formatting helpers shared by the UI and the review
/// rules. Locale-independent on purpose so tests and every platform render
/// identical strings.
library;

/// Tolerant money parsing shared by the money field and the W-2 CSV
/// importer (Stage-1 debt D2: the two parsers had drifted apart).
///
/// Behaviour, pinned by `test/money_parse_test.dart`:
/// - Empty or whitespace-only input parses as 0 — a blank cell or cleared
///   field means "no amount", not an error.
/// - `$`, thousands commas and whitespace are stripped anywhere.
/// - Text that still does not parse returns null; callers decide whether
///   that means a skipped CSV row with a warning or an ignored field edit.
/// - A comma followed by only one or two trailing digits is never valid
///   US thousands grouping, so inputs like "6,5" or "6,50" (a decimal-comma
///   locale leaking through) are refused as null instead of silently
///   parsing as 65 / 650. Full European formats ("1.234,56") are out of
///   scope for this US-format prototype and are not rehabilitated.
double? parseMoney(String raw) {
  final stripped = raw.replaceAll('\$', '').replaceAll(RegExp(r'\s'), '');
  if (RegExp(r'^-?\d+,\d{1,2}$').hasMatch(stripped)) return null;
  final cleaned = stripped.replaceAll(',', '');
  if (cleaned.isEmpty) return 0;
  return double.tryParse(cleaned);
}

String formatMoney(double value, {bool withCents = false}) {
  final negative = value < 0;
  final abs = value.abs();
  final shown = withCents ? abs.toStringAsFixed(2) : abs.round().toString();
  final parts = shown.split('.');
  final grouped = _groupThousands(parts[0]);
  final withDecimals =
      parts.length > 1 && parts[1].isNotEmpty ? '.$parts[1]' : '';
  return '${negative ? '-' : ''}\$$grouped$withDecimals';
}

/// Like [formatMoney] but always shows a sign, for delta chips
/// ("+$412" / "-$412").
String formatSignedMoney(double value, {bool withCents = false}) {
  final sign = value >= 0 ? '+' : '-';
  return '$sign${formatMoney(value.abs(), withCents: withCents)}';
}

String formatPercent(double value) => '${(value * 100).toStringAsFixed(1)}%';

String _groupThousands(String digits) {
  if (digits.length <= 3) return digits;
  final buffer = StringBuffer();
  var count = 0;
  for (var i = digits.length - 1; i >= 0; i--) {
    buffer.write(digits[i]);
    count++;
    if (count % 3 == 0 && i > 0) buffer.write(',');
  }
  return buffer.toString().split('').reversed.join();
}
