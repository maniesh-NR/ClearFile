// SPDX-License-Identifier: GPL-3.0-only
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/tax_return.dart';

/// Export/import of the open ClearFile return format through the platform
/// file picker. Files carry the `.clearfile.json` extension and a
/// `format: "clearfile.return"` marker.
class ReturnFileIO {
  static const String fileExtension = 'clearfile.json';

  /// Picks any file and returns its bytes, or null when the user
  /// cancelled or the file could not be read.
  static Future<Uint8List?> pickAnyFileBytes(String dialogTitle) async {
    final files = await FilePicker.pickFiles(
      dialogTitle: dialogTitle,
      type: FileType.any,
    );
    if (files.isEmpty) return null;
    final path = files.first.path;
    if (path == null) return null;
    try {
      return await File(path).readAsBytes();
    } catch (_) {
      return null;
    }
  }

  /// Picks any file and returns its UTF-8 text (a leading BOM is
  /// tolerated), or null when the user cancelled or reading failed.
  static Future<String?> pickAnyFileText(String dialogTitle) async {
    final files = await FilePicker.pickFiles(
      dialogTitle: dialogTitle,
      type: FileType.any,
    );
    if (files.isEmpty) return null;
    final path = files.first.path;
    if (path == null) return null;
    try {
      var text = await File(path).readAsString(encoding: utf8);
      if (text.startsWith('﻿')) text = text.substring(1);
      return text;
    } catch (_) {
      return null;
    }
  }

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
