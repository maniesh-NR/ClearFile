import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../models/tax_return.dart';

/// Export/import of the open ClearFile return format through the platform
/// file picker. Files carry the `.clearfile.json` extension and a
/// `format: "clearfile.return"` marker.
class ReturnFileIO {
  static const String fileExtension = 'clearfile.json';

  /// Returns the path written, or null when the user cancelled.
  static Future<String?> exportReturn(TaxReturnData r) async {
    final bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(r.toJson()),
    );
    final uri = await FilePicker.saveFile(
      fileName: '${_safeFileName(r.displayName)}.$fileExtension',
      bytes: bytes,
      mimeType: 'application/json',
      dialogTitle: 'Export ClearFile return',
    );
    if (uri == null) return null;
    return uri.scheme == 'file' ? uri.toFilePath() : uri.toString();
  }

  /// Returns the parsed return, or null when cancelled or unreadable.
  static Future<TaxReturnData?> importReturn() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Open a ClearFile return',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (files.isEmpty) return null;
    final path = files.first.path;
    if (path == null) return null;
    try {
      final text = await File(path).readAsString();
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic> &&
          decoded['format'] == 'clearfile.return') {
        return TaxReturnData.fromJson(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _safeFileName(String name) {
    final cleaned = name.trim().replaceAll(RegExp(r'[^\w\s.-]'), '');
    return cleaned.isEmpty ? 'return' : cleaned;
  }
}
