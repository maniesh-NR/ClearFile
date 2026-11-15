// SPDX-License-Identifier: GPL-3.0-only
import 'dart:convert';

import '../models/filing_status.dart';
import '../models/json_codec.dart';
import '../models/tax_return.dart';

/// The unified ClearFile return file format (ADR-015, Stage-3 close-out).
///
/// ONE envelope on both codebases and both media (the exported/imported file
/// and the autosaved store file):
///
/// ```json
/// {
///   "format": "clearfile-return",
///   "version": 2,
///   "app": "ClearFile 1.0.1",
///   "savedAt": "2026-11-15T...Z",
///   "filing": { "...TaxReturnData fields..." }
/// }
/// ```
///
/// The file extension is `.clearfile.json`. Readers also accept, with
/// migration and warnings:
///
///  * **version 1 envelopes** — the pre-parity web prototype's `.cfr` shape
///    (`clearfile-return`, `filing` in the old field names), migrated with
///    the same conservative mapping the web parser applies;
///  * **the legacy flat layout** — `format: "clearfile.return"` with the
///    filing fields at the top level next to the marker, written by the
///    Flutter app through v1.0.1 and by the autosave store until this
///    change; it is the same filing model, so the lift is lossless.
///
/// The `clearfile.json` entry inside a ClearFile exchange container (the
/// `.tax`-extension ZIP the web prototype writes) carries this same envelope.
///
/// Version guard (DEBT D3): files claiming a version higher than
/// [ReturnFileCodec.version] are refused — no format change ships before a
/// version guard.
class ReturnFileCodec {
  ReturnFileCodec._();

  /// Envelope marker of the unified format.
  static const String format = 'clearfile-return';

  /// Current schema version. Version 2 is the parity filing shape
  /// (ADR-009): the reference `TaxReturnData` model.
  static const int version = 2;

  /// Marker of the pre-unification flat layout (accepted on read only).
  static const String legacyFlatFormat = 'clearfile.return';

  /// Writer identity recorded in the envelope (informational).
  static const String app = 'ClearFile 1.0.1';

  /// Serializes [r] as the unified envelope (pretty-printed JSON).
  static String encode(TaxReturnData r) {
    // The model's own flat serialization carries its legacy markers; the
    // envelope is the single place the format identity lives now.
    final filing = Map<String, dynamic>.from(r.toJson())
      ..remove('format')
      ..remove('formatVersion');
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'format': format,
      'version': version,
      'app': app,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'filing': filing,
    });
  }

  /// Decodes a ClearFile return file of any accepted vintage.
  ///
  /// Throws [ReturnFormatException] with a user-readable message on files
  /// that are not valid JSON, not ClearFile returns, or claim an
  /// unsupported future version.
  static DecodedReturnFile decode(String text) {
    final Object decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const ReturnFormatException('The file is not valid JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ReturnFormatException(
          'The file does not contain a ClearFile return.');
    }
    final marker = decoded['format'];
    if (marker == format) {
      return _decodeEnvelope(decoded);
    }
    if (marker == legacyFlatFormat) {
      return _decodeLegacyFlat(decoded);
    }
    final markerText = marker == null ? '(missing)' : marker.toString();
    throw ReturnFormatException(
        'Unrecognized format "$markerText" — expected '
        '"$format". This is not a ClearFile return.');
  }

  // --- Envelope (clearfile-return) ----------------------------------------

  static DecodedReturnFile _decodeEnvelope(Map<String, dynamic> file) {
    final v = file['version'];
    if (v is! int || v < 1) {
      throw ReturnFormatException('Unsupported version ${v ?? '(missing)'} '
          '(this build supports up to $version).');
    }
    if (v > version) {
      // Version guard (D3): future files are refused, never guessed at.
      throw ReturnFormatException('Unsupported version $v '
          '(this build supports up to $version).');
    }
    final raw = file['filing'];
    final Map<String, dynamic> filing;
    if (raw == null) {
      filing = <String, dynamic>{};
    } else if (raw is Map) {
      filing = Map<String, dynamic>.from(raw);
    } else {
      throw const ReturnFormatException('The file has no return payload.');
    }
    final warnings = <String>[];
    final migrated =
        v == 1 ? _migrateWebV1(filing, warnings) : filing;
    return _finish(migrated, warnings);
  }

  // --- Legacy flat layout (clearfile.return) ------------------------------

  static DecodedReturnFile _decodeLegacyFlat(Map<String, dynamic> file) {
    final legacyVersion = file['formatVersion'];
    if (legacyVersion is int && legacyVersion > 1) {
      throw ReturnFormatException('Unsupported version $legacyVersion '
          '(this build supports up to $version).');
    }
    // The flat layout wrote the SAME filing model at the top level, so the
    // migration is a lossless envelope lift with no warnings.
    final filing = Map<String, dynamic>.from(file)
      ..remove('format')
      ..remove('formatVersion');
    return _finish(filing, <String>[]);
  }

  // --- Shared tolerant tail ------------------------------------------------

  /// Applies the same defaulting rules (and warnings) the web parser
  /// (`src/lib/files/cfr.ts`) applies, so both readers report the same
  /// conditions on the same file.
  static DecodedReturnFile _finish(
      Map<String, dynamic> filing, List<String> warnings) {
    final statusRaw = filing['filingStatus'];
    final statusKnown = statusRaw is String &&
        FilingStatus.values.any((s) => s.jsonName == statusRaw);
    if (!statusKnown) {
      warnings.add('Filing status was missing; defaulted to single.');
    }
    final year = readInt(filing, 'taxYear', 2025);
    if (year != 2025) {
      filing['taxYear'] = 2025;
      warnings.add('Tax year was missing or unsupported; defaulted to 2025 '
          '(the engine supports TY2025).');
    }
    return DecodedReturnFile(TaxReturnData.fromJson(filing), warnings);
  }

  // --- v1 (pre-parity web shape) migration --------------------------------

  /// Conservative v1 → v2 mapping, mirroring the web parser's `migrateV1`
  /// field-for-field (including the warning wording, so both engines give
  /// the same account of what a migration dropped).
  static Map<String, dynamic> _migrateWebV1(
      Map<String, dynamic> o, List<String> warnings) {
    o['taxYear'] = 2025;
    warnings.add(
        'Saved with an older prototype: the return was migrated to the '
        'current engine model.');
    final s = o['status'];
    if (s == 'mfj') {
      o['filingStatus'] = 'marriedJoint';
    } else if (s == 'mfs') {
      o['filingStatus'] = 'marriedSeparate';
    } else if (s == 'hoh') {
      o['filingStatus'] = 'headOfHousehold';
    } else if (s is String) {
      o['filingStatus'] = s;
    }
    o.remove('status');
    o['interestIncome'] = readDouble(o, 'interest');
    o['ordinaryDividends'] = readDouble(o, 'dividends');
    if (readDouble(o, 'adjustments') > 0) {
      warnings.add('"Adjustments to income" had no equivalent in the '
          'current model and was dropped — re-enter it as student loan '
          'interest if that is what it was.');
    }
    o.remove('interest');
    o.remove('dividends');
    o.remove('adjustments');

    final item = o['itemized'] is Map
        ? Map<String, dynamic>.from(o['itemized'] as Map)
        : <String, dynamic>{};
    o['stateLocalIncomeOrSalesTax'] = readDouble(item, 'taxesPaid');
    o['realEstateTax'] = 0;
    o['mortgageInterest'] = readDouble(item, 'mortgageInterest');
    o['charitableCash'] = readDouble(item, 'charity');
    o['charitableNonCash'] = 0;
    if (readDouble(item, 'medical') > 0 || readDouble(item, 'other') > 0) {
      warnings.add('Medical and "other" itemized expenses have no equivalent '
          'in the current model and were dropped.');
    }
    o.remove('itemized');

    final kids = readInt(o, 'qualifyingChildren').clamp(0, 100);
    final others = readInt(o, 'otherDependents').clamp(0, 100);
    o.remove('qualifyingChildren');
    o.remove('otherDependents');
    final dependents = <Map<String, dynamic>>[];
    for (var i = 0; i < kids; i++) {
      dependents.add(<String, dynamic>{
        'name': '',
        'age': 0,
        'relationship': '',
        'qualifyingChild': true,
        'otherDependentCredit': false,
      });
    }
    for (var i = 0; i < others; i++) {
      dependents.add(<String, dynamic>{
        'name': '',
        'age': 0,
        'relationship': '',
        'qualifyingChild': false,
        'otherDependentCredit': true,
      });
    }
    if (dependents.isNotEmpty) {
      warnings.add(
          'Dependent counts were migrated; re-enter their names in the '
          'Dependents step.');
    }
    o['dependents'] = dependents;
    return o;
  }
}

/// A successfully decoded return file: the filing plus every migration
/// warning the reader owes the user.
class DecodedReturnFile {
  const DecodedReturnFile(this.filing, this.warnings);

  final TaxReturnData filing;
  final List<String> warnings;
}

/// Raised by [ReturnFileCodec.decode] on files that cannot be read as a
/// ClearFile return. [message] is user-readable and is surfaced in the
/// import dialogs verbatim.
class ReturnFormatException implements Exception {
  const ReturnFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Outcome of the picker-driven return import (DEBT D1: cancelled,
/// unreadable and wrong-format are distinct outcomes with feedback, never
/// one silent null).
sealed class ReturnImport {
  const ReturnImport();
}

/// The user closed the picker without choosing a file — nothing to report.
final class ReturnImportCancelled extends ReturnImport {
  const ReturnImportCancelled();
}

/// A file was chosen but could not be read as a ClearFile return.
/// [reason] is user-readable.
final class ReturnImportFailed extends ReturnImport {
  const ReturnImportFailed(this.reason);

  final String reason;
}

/// A return was read; [warnings] carries the migration notes (if any).
final class ReturnImportOk extends ReturnImport {
  const ReturnImportOk(this.filing, this.warnings);

  final TaxReturnData filing;
  final List<String> warnings;
}

/// Decodes [text] and maps hard failures to the [ReturnImport] outcome
/// tree (the picker-independent half of the import flow, unit-testable
/// without a dialog).
ReturnImport decodeReturnImport(String text) {
  try {
    final decoded = ReturnFileCodec.decode(text);
    return ReturnImportOk(decoded.filing, decoded.warnings);
  } on ReturnFormatException catch (e) {
    return ReturnImportFailed(e.message);
  }
}
