/// Native (desktop/Android) IO backend.

import 'dart:io';

import 'package:path_provider/path_provider.dart';

class IoBackend {
  const IoBackend();

  bool get hasFileSystem => true;

  bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  bool get isAndroid => Platform.isAndroid;

  /// Directory where returns and autosave live (app documents / NitroNissi).
  /// Android: prefer the app-specific external dir so users can reach the
  /// files with any file manager without permissions.
  Future<String?> returnsDirectory() async {
    try {
      final base = isAndroid
          ? await getExternalStorageDirectory() ??
              getApplicationDocumentsDirectoryCompat()
          : await getApplicationDocumentsDirectoryCompat();
      final dir = Directory('${base.path}${Platform.pathSeparator}NitroNissi');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> getApplicationDocumentsDirectoryCompat() async {
    // Kept as a function to make the async chain explicit.
    return getApplicationDocumentsDirectory();
  }

  Future<void> writeBytes(String path, List<int> bytes) async {
    await File(path).writeAsBytes(bytes, flush: true);
  }

  Future<String?> readFileText(String path) async {
    try {
      final f = File(path);
      if (!await f.exists()) return null;
      return await f.readAsString();
    } catch (_) {
      return null;
    }
  }
}
