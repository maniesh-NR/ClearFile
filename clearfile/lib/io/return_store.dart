// SPDX-License-Identifier: GPL-3.0-only
import 'dart:io';

import '../models/tax_return.dart';
import 'return_format.dart';

/// Persistence seam for saved returns (Stage-1 debt D4).
///
/// [AppState] and the widget tests talk to this interface. The production
/// implementation is [FileReturnStore]; tests inject in-memory fakes
/// (`test/fakes.dart`) so widget tests escape the `tester.runAsync`
/// filesystem tax (ADR-006) — store futures then resolve inside the
/// binding's test zone and `pumpAndSettle` is safe to use again.
abstract class ReturnStore {
  Future<List<TaxReturnData>> listReturns();

  Future<void> save(TaxReturnData r);

  Future<void> delete(String id);
}

/// File-backed [ReturnStore]: one JSON file per return inside a `returns/`
/// folder of the app's private data directory.
///
/// Nothing leaves the device. Files use the SAME unified envelope as the
/// export/import picker flow (`ReturnFileCodec`, ADR-015), so an exported
/// `.clearfile.json` can be dropped back in at any time; files written by
/// older builds (flat layout) are migrated on read.
class FileReturnStore implements ReturnStore {
  FileReturnStore(this.baseDirectory);

  final Directory baseDirectory;

  Directory get _returnsDir => Directory('${baseDirectory.path}/returns');

  Future<void> ensureReady() async {
    if (!await _returnsDir.exists()) {
      await _returnsDir.create(recursive: true);
    }
  }

  @override
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
        // Unified envelope + legacy layouts, with the version guard
        // (ReturnFileCodec). Corrupt or future-version files are skipped
        // rather than crashing the home screen.
        returns.add(ReturnFileCodec.decode(text).filing);
      } catch (_) {
        // Unreadable files are skipped rather than crashing the home screen.
      }
    }
    returns.sort((a, b) => b.modified.compareTo(a.modified));
    return returns;
  }

  @override
  Future<File> save(TaxReturnData r) async {
    await ensureReady();
    r.modified = DateTime.now();
    final file = File('${_returnsDir.path}/${_safeName(r.id)}.json');
    return file.writeAsString(ReturnFileCodec.encode(r));
  }

  @override
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
