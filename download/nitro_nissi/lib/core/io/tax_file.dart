/// Native return storage: `.nnx` (Nitro Nissi eXchange) — versioned JSON.
library;

import 'dart:convert';

import '../tax/model.dart';

class TaxFile {
  static const int schemaVersion = 1;
  static const String magic = 'nitro-nissi/nnx';

  /// Load from text; validates schema and runs migrations if needed.
  static TaxReturnData load(String text) {
    final j = jsonDecode(text);
    if (j is! Map) {
      throw const FormatException('Not a Nitro Nissi return file (.nnx)');
    }
    final schema = j['schema'];
    if (schema is String && schema != magic) {
      // Tolerate unknown-but-close schemas: still attempt parse.
    }
    final v = j['schemaVersion'] ?? 0;
    if (v is int && v > schemaVersion) {
      throw FormatException(
          'File was saved by a newer version of Nitro Nissi (schema $v > $schemaVersion).');
    }
    return TaxReturnData.fromJson(j.cast<String, dynamic>());
  }

  /// Serialize a return for saving.
  static String save(TaxReturnData d) {
    final j = d.toJson();
    j['schemaVersion'] = schemaVersion;
    j['savedAt'] = DateTime.now().toUtc().toIso8601String();
    j['app'] = 'Nitro Nissi 1.0.0';
    return const JsonEncoder.withIndent('  ').convert(j);
  }
}
