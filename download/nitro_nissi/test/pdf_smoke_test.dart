/// Smoke test: the printable package builds valid PDF bytes.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitro_nissi/core/tax/engine.dart';
import 'package:nitro_nissi/core/tax/model.dart';
import 'package:nitro_nissi/core/tax/params_2025.dart';
import 'package:nitro_nissi/core/export/print_package.dart';

void main() {
  test('print package builds a PDF', () async {
    final d = TaxReturnData(taxYear: 2025)
      ..w2s.add(W2Entry(employerName: 'Acme', wages: 60000, federalWithholding: 5500));
    final r = const FederalEngine().compute(d, params2025);
    final bytes = await const PrintPackage().build(d, r);
    expect(bytes.lengthInBytes, greaterThan(1000));
    expect(bytes[0], 0x25); // '%PDF'
    expect(bytes[1], 0x50);
  });
}
