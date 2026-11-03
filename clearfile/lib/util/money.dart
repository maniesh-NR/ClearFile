/// Money and percent formatting helpers shared by the UI and the review
/// rules. Locale-independent on purpose so tests and every platform render
/// identical strings.
library;

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
