import 'dart:convert';
import 'dart:io';

import '../models/tax_return.dart';

/// Local storage for returns: one JSON file per return inside a
/// `returns/` folder of the app's private data directory.
///
/// Nothing leaves the device. The same JSON layout is used by the
/// export/import file picker flow, so an exported file can be dropped back
/// in at any time.
class ReturnStore {
  ReturnStore(this.baseDirectory);

  final Directory baseDirectory;

  Directory get _returnsDir => Directory('${baseDirectory.path}/returns');

  Future<void> ensureReady() async {
    if (!await _returnsDir.exists()) {
      await _returnsDir.create(recursive: true);
    }
  }

  Future<List<TaxReturnData>> listReturns() async {
    await ensureReady();
    final returns = <TaxReturnData>[];
    final files = await _returnsDir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();
    for (final file in files) {
      try {
        final text = await file.readAsString();
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) {
          returns.add(TaxReturnData.fromJson(decoded));
        }
      } catch (_) {
        // Unreadable files are skipped rather than crashing the home screen.
      }
    }
    returns.sort((a, b) => b.modified.compareTo(a.modified));
    return returns;
  }

  Future<File> save(TaxReturnData r) async {
    await ensureReady();
    r.modified = DateTime.now();
    final file = File('${_returnsDir.path}/${_safeName(r.id)}.json');
    return file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(r.toJson()));
  }

  Future<void> delete(String id) async {
    final file = File('${_returnsDir.path}/${_safeName(id)}.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Guards against path traversal if a hand-edited file ever contains a
  /// crafted id.
  static String _safeName(String id) =>
      id.replaceAll(RegExp('[^A-Za-z0-9_-]'), 'x');
}
