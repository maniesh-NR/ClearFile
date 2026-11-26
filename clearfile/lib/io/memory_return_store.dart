// SPDX-License-Identifier: GPL-3.0-only
import '../models/tax_return.dart';
import 'return_store.dart';

/// In-memory [ReturnStore] for the web build (Stage 4).
///
/// The production store ([FileReturnStore]) is file-backed; the web platform
/// has no filesystem, so the web build runs every session from memory: saved
/// returns live for the tab's lifetime only and are NOT persisted across
/// reloads. This is disclosed on the Welcome screen when running on the web
/// (`kIsWeb` banner note) — the deploy never ships a silent persistence
/// change. Native platforms keep the file store unchanged.
class MemoryReturnStore implements ReturnStore {
  final Map<String, TaxReturnData> _byId = {};

  @override
  Future<List<TaxReturnData>> listReturns() async {
    final list = _byId.values.toList()
      ..sort((a, b) => b.modified.compareTo(a.modified));
    return list;
  }

  @override
  Future<void> save(TaxReturnData r) async {
    // Mirrors FileReturnStore: saving stamps the modification time, which
    // listReturns() sorts on.
    r.modified = DateTime.now();
    _byId[r.id] = r;
  }

  @override
  Future<void> delete(String id) async {
    _byId.remove(id);
  }
}
