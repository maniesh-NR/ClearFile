/// Minimal pure-Dath Compound File Binary (OLE2) reader — used by the
/// best-effort TurboTax importer to enumerate container streams.
///
/// Implements enough of [MS-CFB] to walk the FAT, directory tree and the
/// mini stream. No COM, no external dependencies.
library;

import 'dart:typed_data';

class CfbEntry {
  final String name;
  final int type; // 1=storage 2=stream 5=root
  final int startSector;
  final int size;
  Uint8List? data;

  CfbEntry(this.name, this.type, this.startSector, this.size, [this.data]);

  bool get isStream => type == 2;
}

class CompoundFileReader {
  final Uint8List _bytes;
  late final int _sectorSize;
  late final int _miniSectorSize;
  late final Uint32List _fat;
  Uint32List? _miniFat;
  late final List<CfbEntry> _entries;
  late final CfbEntry _root;

  CompoundFileReader(this._bytes) {
    final sig = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1];
    for (var i = 0; i < 8; i++) {
      if (_bytes[i] != sig[i]) {
        throw const FormatException('Not a Compound File Binary container');
      }
    }
    final bd = ByteData.sublistView(_bytes);
    _sectorSize = 1 << bd.getUint16(30, Endian.little);
    _miniSectorSize = 1 << bd.getUint16(32, Endian.little);
    final numFatSectors = bd.getUint32(44, Endian.little);
    final firstDirSector = bd.getUint32(48, Endian.little);
    final miniCutoff = bd.getUint32(56, Endian.little);
    final firstMiniFat = bd.getUint32(60, Endian.little);
    final numMiniFat = bd.getUint32(64, Endian.little);
    final firstDifat = bd.getUint32(68, Endian.little);

    // --- Build the FAT sector list from DIFAT ---
    final fatSectors = <int>[];
    for (var i = 0; i < 109; i++) {
      final s = bd.getUint32(76 + i * 4, Endian.little);
      if (_isSectorUsed(s)) fatSectors.add(s);
    }
    var difatSector = firstDifat;
    var guard = 0;
    while (_isSectorUsed(difatSector) && difatSector != 0xFFFFFFFE && guard++ < 100000) {
      final base = _sectorOffset(difatSector);
      final perSector = _sectorSize ~/ 4 - 1;
      for (var i = 0; i < perSector; i++) {
        final s = bd.getUint32(base + i * 4, Endian.little);
        if (_isSectorUsed(s)) fatSectors.add(s);
      }
      difatSector = bd.getUint32(base + perSector * 4, Endian.little);
    }
    if (fatSectors.length < numFatSectors) {
      // Header may overstate; proceed with what we found.
    }

    // --- Read FAT ---
    final fatList = <int>[];
    for (final s in fatSectors) {
      final off = _sectorOffset(s);
      for (var i = 0; i < _sectorSize ~/ 4; i++) {
        fatList.add(bd.getUint32(off + i * 4, Endian.little));
      }
    }
    _fat = Uint32List.fromList(fatList);

    Uint32List readMiniFat() {
      final out = <int>[];
      for (final s in _chain(firstMiniFat, numMiniFat * _sectorSize)) {
        for (var i = 0; i < _sectorSize ~/ 4; i++) {
          out.add(bd.getUint32(s + i * 4, Endian.little));
        }
      }
      return Uint32List.fromList(out);
    }

    // --- Directory ---
    _entries = [];
    final dirBytes = _readChain(firstDirSector, null);
    final n = dirBytes.length ~/ 128;
    for (var i = 0; i < n; i++) {
      final e = dirBytes.sublist(i * 128, (i + 1) * 128);
      final nameLen = e[64] | (e[65] << 8);
      final type = e[66];
      if (type == 0) continue; // empty
      var name = '';
      if (nameLen >= 2 && nameLen <= 64) {
        name = String.fromCharCodes(
            List<int>.generate(nameLen ~/ 2, (k) => e[k * 2] | (e[k * 2 + 1] << 8)));
        if (name.endsWith('\u0000')) name = name.substring(0, name.length - 1);
      }
      final start = ByteData.sublistView(e).getUint32(116, Endian.little);
      final size = ByteData.sublistView(e).getUint64(120, Endian.little);
      _entries.add(CfbEntry(name, type, start, size));
    }
    if (_entries.isEmpty || _entries.first.type != 5) {
      throw const FormatException('CFB root entry missing');
    }
    _root = _entries.first;

    // --- Mini FAT + mini stream ---
    if (numMiniFat > 0 && firstMiniFat != 0xFFFFFFFE) {
      _miniFat = readMiniFat();
      final miniStream = _readChain(_root.startSector, _root.size);
      for (final e in _entries) {
        if (e.isStream && e.size < miniCutoff && e.size > 0) {
          e.data = _readMiniChain(miniStream, _miniFat!, e.startSector, e.size);
        }
      }
    }
    for (final e in _entries) {
      if (e.isStream && e.data == null && e.size > 0) {
        e.data = _readChain(e.startSector, e.size);
      }
    }
  }

  static bool _isSectorUsed(int s) => s != 0xFFFFFFFF && s != 0xFFFFFFFE && s != 0xFFFFFFFD;

  int _sectorOffset(int sector) => 512 + sector * _sectorSize; // header is 512 bytes

  List<int> _chain(int start, int? sizeHint) {
    final chunks = <int>[];
    var s = start;
    var guard = 0;
    while (s != 0xFFFFFFFE && _isSectorUsed(s) && guard++ < 1000000) {
      final off = _sectorOffset(s);
      if (off + _sectorSize > _bytes.length) break;
      chunks.addAll(_bytes.sublist(off, off + _sectorSize));
      if (sizeHint != null && chunks.length >= sizeHint) break;
      final next = s < _fat.length ? _fat[s] : 0xFFFFFFFE;
      s = next;
    }
    return chunks;
  }

  Uint8List _readChain(int start, int? size) {
    final raw = _chain(start, size);
    final len = size == null ? raw.length : (raw.length < size ? raw.length : size);
    return Uint8List.fromList(raw.sublist(0, len));
  }

  Uint8List _readMiniChain(Uint8List miniStream, Uint32List miniFat, int start, int size) {
    final out = <int>[];
    var s = start;
    var guard = 0;
    while (s != 0xFFFFFFFE && guard++ < 1000000 && out.length < size) {
      final off = s * _miniSectorSize;
      if (off + _miniSectorSize > miniStream.length) break;
      out.addAll(miniStream.sublist(off, off + _miniSectorSize));
      s = s < miniFat.length ? miniFat[s] : 0xFFFFFFFE;
    }
    final len = out.length < size ? out.length : size;
    return Uint8List.fromList(out.sublist(0, len));
  }

  List<CfbEntry> get streams => _entries.where((e) => e.isStream).toList();
}
