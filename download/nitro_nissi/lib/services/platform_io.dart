/// Platform services: file dialogs, links, storage locations.
///
/// Desktop (Windows/macOS/Linux) uses native open/save dialogs via
/// file_selector; Android uses its SAF-backed implementation; web uses the
/// browser's file input / download mechanism — all behind one small API.
library;

import 'package:file_selector/file_selector.dart';
import 'package:url_launcher/url_launcher.dart';

import 'io_backend.dart';

const ioBackend = IoBackend();

class OpenedFile {
  final String name;
  final List<int> bytes;
  final String? path; // null on web
  const OpenedFile(this.name, this.bytes, this.path);
}

class PlatformIo {
  const PlatformIo();

  bool get hasFileSystem => ioBackend.hasFileSystem;
  bool get isDesktop => ioBackend.isDesktop;

  static const _openTypes = [
    XTypeGroup(label: 'Tax returns', extensions: [
      'nnx', 'json', 'csv', 'txt', 'tax', 'tax2022', 'tax2023', 'tax2024', 'tax2025'
    ]),
    XTypeGroup(label: 'All files'),
  ];

  Future<OpenedFile?> pickOpen() async {
    final file = await openFile(acceptedTypeGroups: _openTypes);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return OpenedFile(file.name, bytes, file.path);
  }

  /// Returns the chosen path (native) or null (web saves use the browser
  /// download flow inside [saveBytes]).
  Future<String?> pickSavePath(String suggestedName) async {
    if (!ioBackend.hasFileSystem) return null;
    final location = await getSaveLocation(suggestedName: suggestedName);
    return location?.path;
  }

  Future<void> saveBytes(String? path, String suggestedName, List<int> bytes) async {
    if (path != null) {
      await ioBackend.writeBytes(path, bytes);
      return;
    }
    // Web (or path-less) fallback: trigger a download named suggestedName.
    await ioBackend.writeBytes(suggestedName, bytes);
  }

  Future<String?> returnsDirectory() => ioBackend.returnsDirectory();

  Future<void> openLink(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) throw Exception('could-not-open $url');
  }
}
