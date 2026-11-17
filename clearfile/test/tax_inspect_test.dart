// SPDX-License-Identifier: GPL-3.0-only
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:clearfile/io/tax_inspect.dart';
import 'package:clearfile/models/tax_return.dart';
import 'package:clearfile/models/w2.dart';

/// .tax container inspection tests. Containers are built in-test with a
/// minimal STORE-only ZIP writer (the same shape the web prototype's
/// exporter writes); no proprietary material is used anywhere.
void main() {
  test('ClearFile exchange container is detected and imported', () {
    final filing = TaxReturnData(
      displayName: 'Exchange test',
      w2s: [],
      interestIncome: 120,
    );
    final json = const JsonEncoder.withIndent('  ').convert(filing.toJson());
    final bytes = _makeZip([
      _ZipEntry('clearfile.json', utf8.encode(json)),
      _ZipEntry('README.txt', utf8.encode('ClearFile exchange container')),
    ]);

    final insp = analyzeTaxFile(bytes);
    expect(insp.isZip, isTrue);
    expect(insp.clearfileContainer, isTrue);
    expect(insp.intuitModernContainer, isFalse);
    expect(insp.filing, isNotNull);
    expect(insp.filing!.interestIncome, 120);
    expect(insp.summary, contains('ClearFile exchange container'));
  });

  test('web-written envelope container imports (cross-codebase shape, '
      'ADR-015)', () {
    // The web prototype's exportTaxContainer writes the VERSIONED envelope
    // (clearfile-return v2) into clearfile.json — the unified codec accepts
    // it, where the pre-unification marker check did not.
    final filing = TaxReturnData(
      displayName: 'Web container',
      w2s: [W2Entry(employer: 'Initech', wages: 60000, withholding: 6000)],
    );
    final envelope = jsonEncode({
      'format': 'clearfile-return',
      'version': 2,
      'app': 'ClearFile prototype 0.2',
      'savedAt': '2026-11-15T02:00:00.000Z',
      'filing': filing.toJson()
        ..remove('format')
        ..remove('formatVersion'),
    });
    final bytes = _makeZip([
      _ZipEntry('clearfile.json', utf8.encode(envelope)),
      _ZipEntry('README.txt', utf8.encode('ClearFile exchange container')),
    ]);

    final insp = analyzeTaxFile(bytes);
    expect(insp.clearfileContainer, isTrue);
    expect(insp.filing, isNotNull);
    expect(insp.filing!.displayName, 'Web container');
    expect(insp.filing!.w2s.single.employer, 'Initech');
  });

  test('container with an unreadable clearfile.json falls through with a '
      'warning', () {
    final bytes = _makeZip([
      _ZipEntry('clearfile.json', utf8.encode('this is not json')),
      _ZipEntry('README.txt', utf8.encode('ClearFile exchange container')),
    ]);
    final insp = analyzeTaxFile(bytes);
    expect(insp.clearfileContainer, isFalse);
    expect(insp.filing, isNull);
    expect(insp.warnings.any((w) => w.contains('could not be parsed')),
        isTrue);
  });

  test('modern Intuit container shape is detected, flagged encrypted, '
      'never imported', () {
    // "Encrypted" stand-in: uniform high-entropy bytes. NOT real key
    // material or real payload — purely synthetic.
    final rng = Random(1234);
    final encryptedLooking =
        List<int>.generate(1024, (_) => rng.nextInt(256));
    final manifest = utf8.encode('<manifest/>');

    final bytes = _makeZip([
      _ZipEntry('manifest.xml', manifest),
      _ZipEntry('tax:7a1c2d3e-4f5a-6789-abcd-ef0123456789', encryptedLooking),
    ]);

    final insp = analyzeTaxFile(bytes);
    expect(insp.isZip, isTrue);
    expect(insp.intuitModernContainer, isTrue);
    expect(insp.clearfileContainer, isFalse);
    expect(insp.filing, isNull);

    final data = insp.entries.firstWhere((e) => e.name.startsWith('tax:'));
    expect(data.entropy, isNotNull);
    expect(data.entropy!, greaterThan(7.5));
    expect(data.likelyEncrypted, isTrue);

    // The safe bridges must be named, and the copy must state it does not
    // decrypt (protocol §2.2/§7).
    expect(insp.summary, contains('does not decrypt'));
    expect(insp.summary, contains('TXF'));
  });

  test('low-entropy textual entries are not flagged encrypted', () {
    final bytes = _makeZip([
      _ZipEntry(
          'notes.txt',
          utf8.encode('hello hello hello hello hello '
              'hello hello hello hello hello hello hello hello hello hello '
              'hello hello hello hello hello hello hello hello hello hello')),
    ]);
    final insp = analyzeTaxFile(bytes);
    expect(insp.entries.single.likelyEncrypted, isFalse);
    expect(insp.entries.single.preview, contains('hello'));
  });

  test('non-ZIP file: honest summary with entropy, no crash', () {
    final rng = Random(99);
    final blob = Uint8List.fromList(
        List<int>.generate(4096, (_) => rng.nextInt(256)));
    final insp = analyzeTaxFile(blob);
    expect(insp.isZip, isFalse);
    expect(insp.entries, isEmpty);
    expect(insp.summary, contains('Not a ZIP container'));
    expect(insp.summary, contains('bits/byte'));

    final textual = analyzeTaxFile(utf8.encode('just some text'));
    expect(textual.summary, contains('not high-entropy'));
  });

  test('empty file: no crash, empty summary note', () {
    final insp = analyzeTaxFile(Uint8List(0));
    expect(insp.isZip, isFalse);
    expect(insp.summary, contains('empty'));
  });

  test('deflate entries are listed but not extracted', () {
    final bytes = _makeZip([
      _ZipEntry('stored.txt', utf8.encode('plain')),
    ], deflateAlso: [
      _ZipEntry('compressed.bin', utf8.encode('not actually deflated')),
    ]);
    final insp = analyzeTaxFile(bytes);
    expect(insp.entries, hasLength(2));
    final compressed =
        insp.entries.firstWhere((e) => e.name == 'compressed.bin');
    expect(compressed.method, 8);
    expect(compressed.entropy, isNull);
    expect(insp.warnings.any((w) => w.contains('deflate')), isTrue);
  });

  test('truncated ZIP: warning about the missing central directory', () {
    final garbage = Uint8List(64);
    garbage[0] = 0x50;
    garbage[1] = 0x4b;
    garbage[2] = 0x03;
    garbage[3] = 0x04;
    final insp = analyzeTaxFile(garbage);
    expect(insp.isZip, isTrue);
    expect(insp.warnings.any((w) => w.contains('end-of-central-directory')),
        isTrue);
  });

  test('crafted central-directory name running past EOF never throws '
      '(ENG-1 regression, Stage-2 entry gate)', () {
    // A valid single-entry ZIP, then the central entry's name-length field
    // is forged to 0xFFFF: the 46-byte header still fits at EOF but the
    // claimed name field runs far past it — the exact shape that crashed
    // _readZipDirectory with a RangeError before the 2026-11-17 bounds
    // check. The contract under test: never throws on malformed input.
    final valid = _makeZip([_ZipEntry('a.txt', utf8.encode('x'))]);
    final forged = Uint8List.fromList(valid);
    final view = ByteData.view(forged.buffer);

    // Locate the EOCD from the tail, then the first central entry, using
    // the same scan the inspector uses.
    var eocd = -1;
    for (var i = forged.length - 22; i >= 0; i--) {
      if (view.getUint32(i, Endian.little) == 0x06054b50) {
        eocd = i;
        break;
      }
    }
    final ptr = view.getUint32(eocd + 16, Endian.little);
    expect(view.getUint32(ptr, Endian.little), 0x02014b50);
    view.setUint16(ptr + 28, 0xFFFF, Endian.little); // nameLen past EOF

    final insp = analyzeTaxFile(forged);
    expect(insp.isZip, isTrue);
    expect(insp.warnings.any(
        (w) => w.contains('name extends past end of file')), isTrue);
  });
}

/* ---------------- minimal STORE-only ZIP writer (test fixture) ----------- */

class _ZipEntry {
  _ZipEntry(this.name, this.data);
  final String name;
  final List<int> data;
}

final List<int> _crcTable = _buildCrcTable();

List<int> _buildCrcTable() {
  final table = List<int>.filled(256, 0);
  for (var i = 0; i < 256; i++) {
    var c = i;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    }
    table[i] = c;
  }
  return table;
}

int _crc32(List<int> data) {
  var c = 0xFFFFFFFF;
  for (final b in data) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >>> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

Uint8List _bytes(int size, void Function(ByteData) fill) {
  final b = Uint8List(size);
  fill(ByteData.view(b.buffer));
  return b;
}

/// STORE-method ZIP writer for test fixtures (port of the web prototype's
/// `makeZip`); `deflateAlso` emits entries with method 8 whose payloads are
/// NOT actually deflated (listing behavior is what the tests pin).
Uint8List _makeZip(List<_ZipEntry> stored,
    {List<_ZipEntry> deflateAlso = const []}) {
  final all = [
    ...stored.map((e) => (e, 0)),
    ...deflateAlso.map((e) => (e, 8)),
  ];

  final locals = <int>[];
  final centrals = <int>[];
  var offset = 0;

  for (final (entry, method) in all) {
    final nameBytes = ascii.encode(entry.name);
    final data = entry.data;
    final crc = _crc32(data);
    final size = data.length;

    final local = _bytes(30 + nameBytes.length + size, (lv) {
      lv.setUint32(0, 0x04034b50, Endian.little);
      lv.setUint16(4, 20, Endian.little);
      lv.setUint16(6, 0, Endian.little);
      lv.setUint16(8, method, Endian.little);
      lv.setUint16(10, 0, Endian.little);
      lv.setUint16(12, 0x21, Endian.little); // 1980-01-01
      lv.setUint32(14, crc, Endian.little);
      lv.setUint32(18, size, Endian.little);
      lv.setUint32(22, size, Endian.little);
      lv.setUint16(26, nameBytes.length, Endian.little);
      lv.setUint16(28, 0, Endian.little);
    });
    local.setRange(30, 30 + nameBytes.length, nameBytes);
    local.setRange(30 + nameBytes.length, local.length, data);
    locals.addAll(local);

    final central = _bytes(46 + nameBytes.length, (cv) {
      cv.setUint32(0, 0x02014b50, Endian.little);
      cv.setUint16(4, 20, Endian.little);
      cv.setUint16(6, 20, Endian.little);
      cv.setUint16(8, 0, Endian.little);
      cv.setUint16(10, method, Endian.little);
      cv.setUint16(12, 0, Endian.little);
      cv.setUint16(14, 0x21, Endian.little);
      cv.setUint32(16, crc, Endian.little);
      cv.setUint32(20, size, Endian.little);
      cv.setUint32(24, size, Endian.little);
      cv.setUint16(28, nameBytes.length, Endian.little);
      cv.setUint16(30, 0, Endian.little);
      cv.setUint16(32, 0, Endian.little);
      cv.setUint16(34, 0, Endian.little);
      cv.setUint16(36, 0, Endian.little);
      cv.setUint32(38, 0, Endian.little);
      cv.setUint32(42, offset, Endian.little);
    });
    central.setRange(46, 46 + nameBytes.length, nameBytes);
    centrals.addAll(central);

    offset += local.length;
  }

  final centralSize = centrals.length;
  final end = _bytes(22, (ev) {
    ev.setUint32(0, 0x06054b50, Endian.little);
    ev.setUint16(4, 0, Endian.little);
    ev.setUint16(6, 0, Endian.little);
    ev.setUint16(8, all.length, Endian.little);
    ev.setUint16(10, all.length, Endian.little);
    ev.setUint32(12, centralSize, Endian.little);
    ev.setUint32(16, offset, Endian.little);
    ev.setUint16(20, 0, Endian.little);
  });

  return Uint8List.fromList([...locals, ...centrals, ...end]);
}
