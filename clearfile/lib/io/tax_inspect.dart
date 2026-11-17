// SPDX-License-Identifier: GPL-3.0-only
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../models/tax_return.dart';
import 'return_format.dart';

/// Read-only inspection of `.tax` files (RE protocol §1–§5, §7).
///
/// What this does — and deliberately does NOT do:
///  - Detects the ZIP wrapper family (the modern desktop `.tax` container)
///    and lists entries from the central directory (name, sizes, method).
///  - Extracts only STORE-method entries; DEFLATE entries are listed but
///    not extracted (honest, dependency-free reading).
///  - Recognizes ClearFile's own open exchange container and imports it.
///  - Recognizes the *shape* of the modern Intuit container (a
///    `manifest.xml` entry plus a `tax:<uuid>` data entry) and reports
///    per-entry Shannon entropy so encrypted payloads are flagged —
///    the public write-up (§1 of the protocol) documents the AES layer.
///  - No decryption, no key material, no ready-made decryptor: protocol
///    §2.2 / §7.2 / §7.3 hard lines. The safe bridges for real Intuit
///    data are TurboTax's own TXF export and printed PDFs (§2.5).
class TaxInspection {
  const TaxInspection({
    required this.isZip,
    required this.clearfileContainer,
    required this.intuitModernContainer,
    required this.entries,
    required this.warnings,
    required this.summary,
    this.filing,
  });

  final bool isZip;

  /// True when the file is ClearFile's open ZIP exchange container
  /// (`.tax` extension, `clearfile.json` payload) — fully importable.
  final bool clearfileContainer;

  /// True when the entry names match the modern Intuit container shape
  /// (`manifest.xml` + `tax:<uuid>`). Nothing is decrypted; the summary
  /// says exactly that and points at the safe bridges.
  final bool intuitModernContainer;

  /// The parsed return when [clearfileContainer] is true.
  final TaxReturnData? filing;

  final List<TaxEntryInfo> entries;
  final List<String> warnings;
  final String summary;
}

class TaxEntryInfo {
  const TaxEntryInfo({
    required this.name,
    required this.size,
    required this.method,
    this.entropy,
    this.likelyEncrypted,
    this.preview,
  });

  /// Entry name from the ZIP central directory.
  final String name;

  /// Uncompressed size of the entry (or extracted stored size).
  final int size;

  /// ZIP compression method (0 stored / 8 deflate / other).
  final int method;

  /// Shannon entropy in bits/byte over stored data (null when not
  /// extracted or too small to mean anything).
  final double? entropy;

  /// True when [entropy] is ≥ 7.5 — the signature of an encrypted or
  /// already-compressed payload (protocol Phase 1).
  final bool? likelyEncrypted;

  /// Text preview for small textual stored entries.
  final String? preview;
}

/// Inspect an in-memory `.tax` file. Never throws on malformed input —
/// the analysis reports what it could and could not establish.
TaxInspection analyzeTaxFile(Uint8List bytes) {
  final warnings = <String>[];

  if (!_looksZip(bytes)) {
    // Phase-1 passive identification for non-ZIP files: entropy over the
    // first 4 KiB tells encrypted/legacy-binary from anything textual.
    final entropy = _entropy(bytes, 0, bytes.length);
    return TaxInspection(
      isZip: false,
      clearfileContainer: false,
      intuitModernContainer: false,
      entries: const [],
      warnings: const [],
      summary: bytes.isEmpty
          ? 'The file is empty.'
          : 'Not a ZIP container (no PK signature). This is either a '
              'legacy binary tax format or an unknown container. Whole-file '
              'entropy is ${entropy.toStringAsFixed(2)} bits/byte '
              '(${entropy >= 7.5 ? 'encrypted/compressed-looking' : 'not '
                  'high-entropy'}). The legacy formats have no public '
              'documentation (protocol §1); ClearFile imports TurboTax data '
              'through the documented TXF export and PDFs instead.',
    );
  }

  final dir = _readZipDirectory(bytes, warnings);
  final entries = <TaxEntryInfo>[];

  var sawDeflate = false;
  for (final e in dir) {
    var entropy = 0.0;
    var encrypted = false;
    String? preview;
    if (e.stored != null) {
      entropy = _entropyOf(e.stored!);
      encrypted = e.stored!.length >= 128 && entropy >= 7.5;
      if (_looksTextual(e.name) && e.stored!.length < 200000) {
        preview = const Utf8Decoder(allowMalformed: true)
            .convert(e.stored!.take(300).toList());
      }
    }
    if (e.method == 8) sawDeflate = true;
    entries.add(TaxEntryInfo(
      name: e.name,
      size: e.stored?.length ?? e.uncompressedSize,
      method: e.method,
      entropy: e.stored == null || e.stored!.isEmpty ? null : entropy,
      likelyEncrypted: e.stored == null ? null : encrypted,
      preview: preview,
    ));
  }

  // ClearFile exchange container: import fully.
  final clearfileEntry =
      dir.where((e) => e.name == 'clearfile.json' && e.stored != null);
  if (clearfileEntry.isNotEmpty) {
    try {
      final text = utf8.decode(clearfileEntry.first.stored!);
      try {
        // Unified codec (ADR-015): the container's clearfile.json entry is
        // the same envelope the web prototype writes (clearfile-return,
        // versioned, guarded) — plus the legacy flat layout older builds
        // wrote. Both import; migrations surface as warnings.
        final decoded = ReturnFileCodec.decode(text);
        return TaxInspection(
          isZip: true,
          clearfileContainer: true,
          intuitModernContainer: false,
          filing: decoded.filing,
          entries: entries,
          warnings: [...warnings, ...decoded.warnings],
          summary: 'This is a ClearFile exchange container (.tax '
              'extension, open ZIP format). The full return can be '
              'imported.',
        );
      } on ReturnFormatException catch (e) {
        warnings.add('clearfile.json could not be parsed: ${e.message}');
      }
    } catch (_) {
      warnings
          .add('clearfile.json could not be parsed as JSON/UTF-8.');
    }
  }

  // Modern Intuit container shape: manifest.xml + tax:<uuid> entry
  // (public write-up, protocol §5). Report the shape, decrypt nothing.
  final hasManifest = dir.any((e) => e.name == 'manifest.xml');
  final hasTaxData = dir.any((e) => e.name.startsWith('tax:'));
  if (hasManifest && hasTaxData) {
    return TaxInspection(
      isZip: true,
      clearfileContainer: false,
      intuitModernContainer: true,
      entries: entries,
      warnings: warnings,
      summary: 'This matches the modern TurboTax .tax container shape '
          '(ZIP with a manifest.xml plus a tax:<uuid> data entry). The '
          'entries are AES-encrypted with per-year key/IV constants '
          'embedded in the TurboTax binary (public write-up, protocol '
          '§5). ClearFile does not decrypt Intuit files and ships no key '
          'material (protocol §2.2/§7) — import this return via '
          'TurboTax\'s own TXF export (Tax > Print & Save / Export) or '
          'the printed PDF, both of which are the documented safe '
          'bridges.',
    );
  }

  return TaxInspection(
    isZip: true,
    clearfileContainer: false,
    intuitModernContainer: false,
    entries: entries,
    warnings: warnings,
    summary: sawDeflate
        ? 'ZIP container detected. Some entries are compressed and listed '
            'only; stored entries are analyzed below. No ClearFile return '
            'payload was found, so nothing can be imported automatically.'
        : 'ZIP container detected with the entries listed below. No '
            'ClearFile return payload was found, so nothing can be '
            'imported automatically.',
  );
}

/* ---------------- ZIP central-directory reader (STORE extraction) ------ */

class _ZipDirEntry {
  _ZipDirEntry(this.name, this.method, this.uncompressedSize, this.stored);
  final String name;
  final int method;
  final int uncompressedSize;
  final List<int>? stored; // non-null only for STORE entries
}

bool _looksZip(Uint8List bytes) =>
    bytes.length > 4 &&
    bytes[0] == 0x50 &&
    bytes[1] == 0x4b &&
    (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07);

List<_ZipDirEntry> _readZipDirectory(Uint8List bytes, List<String> notes) {
  final out = <_ZipDirEntry>[];
  final view = ByteData.sublistView(bytes);

  // Locate the end-of-central-directory record from the tail.
  var eocd = -1;
  final scanFrom = bytes.length >= 66000 ? bytes.length - 66000 : 0;
  for (var i = bytes.length - 22; i >= scanFrom; i--) {
    if (view.getUint32(i, Endian.little) == 0x06054b50) {
      eocd = i;
      break;
    }
  }
  if (eocd < 0) {
    notes.add('No ZIP end-of-central-directory record found.');
    return out;
  }

  final count = view.getUint16(eocd + 10, Endian.little);
  var ptr = view.getUint32(eocd + 16, Endian.little);
  const maxEntries = 4096; // parser-hardening cap (untrusted input)

  for (var n = 0; n < count && out.length < maxEntries; n++) {
    if (ptr + 46 > bytes.length ||
        view.getUint32(ptr, Endian.little) != 0x02014b50) {
      notes.add('Central directory truncated or corrupt; stopped early.');
      break;
    }
    final method = view.getUint16(ptr + 10, Endian.little);
    final compSize = view.getUint32(ptr + 20, Endian.little);
    final uncompSize = view.getUint32(ptr + 24, Endian.little);
    final nameLen = view.getUint16(ptr + 28, Endian.little);
    final extraLen = view.getUint16(ptr + 30, Endian.little);
    final commentLen = view.getUint16(ptr + 32, Endian.little);
    final localOffset = view.getUint32(ptr + 42, Endian.little);
    // ENG-1 (Stage-2 entry gate, 2026-11-17): the 46-byte header may fit
    // while the claimed name length runs past EOF — bounds-check before
    // the sublist, mirroring the truncated-header branch above.
    if (ptr + 46 + nameLen > bytes.length) {
      notes.add('Central directory entry name extends past end of file; '
          'stopped early.');
      break;
    }
    final name = String.fromCharCodes(bytes.sublist(ptr + 46, ptr + 46 + nameLen));

    List<int>? stored;
    if (method == 0 &&
        localOffset + 30 <= bytes.length &&
        view.getUint32(localOffset, Endian.little) == 0x04034b50) {
      final lNameLen = view.getUint16(localOffset + 26, Endian.little);
      final lExtraLen = view.getUint16(localOffset + 28, Endian.little);
      final dataStart = localOffset + 30 + lNameLen + lExtraLen;
      final dataEnd = dataStart + compSize;
      if (dataEnd <= bytes.length) {
        stored = bytes.sublist(dataStart, dataEnd);
      } else {
        notes.add('Entry "$name" extends past end of file; skipped.');
      }
    } else if (method == 8) {
      notes.add('Entry "$name" is deflate-compressed; listed only.');
    } else if (method != 0) {
      notes.add('Entry "$name" uses unsupported compression method '
          '$method; skipped.');
    }

    out.add(_ZipDirEntry(name, method, uncompSize, stored));
    ptr += 46 + nameLen + extraLen + commentLen;
  }
  return out;
}

bool _looksTextual(String name) =>
    RegExp(r'\.(json|txt|xml|csv|md)$', caseSensitive: false).hasMatch(name);

/* ---------------- entropy (protocol Phase 1) ---------------------------- */

double _entropyOf(List<int> data) => _entropy(Uint8List.fromList(data), 0, data.length);

double _entropy(Uint8List bytes, int offset, int length) {
  if (length <= 0) return 0;
  final counts = List<int>.filled(256, 0);
  final end = (offset + length > bytes.length) ? bytes.length : offset + length;
  for (var i = offset; i < end; i++) {
    counts[bytes[i]]++;
  }
  var h = 0.0;
  final n = end - offset;
  for (final c in counts) {
    if (c == 0) continue;
    final p = c / n;
    h -= p * (math.log(p) / math.ln2);
  }
  return h;
}
