/// JSON field helpers used by all model classes so that numbers stored as
/// `int` or `double` (or missing) are read back safely.
library;

double readDouble(Map<String, dynamic> json, String key, [double fallback = 0]) {
  final v = json[key];
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) {
    final parsed = double.tryParse(v);
    if (parsed != null) return parsed;
  }
  return fallback;
}

int readInt(Map<String, dynamic> json, String key, [int fallback = 0]) {
  final v = json[key];
  if (v == null) return fallback;
  if (v is num) return v.toInt();
  if (v is String) {
    final parsed = int.tryParse(v);
    if (parsed != null) return parsed;
  }
  return fallback;
}

String readString(Map<String, dynamic> json, String key, [String fallback = '']) {
  final v = json[key];
  if (v == null) return fallback;
  return v.toString();
}

bool readBool(Map<String, dynamic> json, String key, [bool fallback = false]) {
  final v = json[key];
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == 'true' || v == '1';
  return fallback;
}

DateTime readDate(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is String) {
    final parsed = DateTime.tryParse(v);
    if (parsed != null) return parsed;
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
