// SPDX-License-Identifier: GPL-3.0-only
import 'package:clearfile/io/return_store.dart';
import 'package:clearfile/models/tax_return.dart';

/// In-memory [ReturnStore] for widget tests (Stage-1 debt D4).
///
/// No dart:io anywhere, so an AppState wired to a FakeReturnStore completes
/// its store futures inside the binding's test zone — widget tests escape
/// the `tester.runAsync` filesystem tax (ADR-006) and can pump normally.
class FakeReturnStore implements ReturnStore {
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
