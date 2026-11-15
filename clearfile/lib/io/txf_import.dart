// SPDX-License-Identifier: GPL-3.0-only
import '../models/tax_return.dart';
import '../models/w2.dart';
import '../util/money.dart';

/// TXF (Tax Exchange Format, published spec v042) import — the documented
/// safe bridge for TurboTax-exported data (RE protocol §2.5: prefer the
/// safe bridges — TurboTax's own TXF export — over any format RE).
///
/// Parses the published V042 structure: a header (V/A/D) followed by
/// `^`-terminated records whose fields are single-letter-tagged lines
/// (T type, N refnum, C copy, L line, $ amount, P description/text,
/// X detail, D date). Only summary (`TS`) records are imported; detail
/// (`TD`) records are ignored per spec §VII.A ("may be safely ignored").
///
/// Refnums follow the spec's tax line item table:
///   460 Salary (W-2 box 1)      461 Federal withholding (W-2 box 2)
///   466 Payer (W-2)             506/507/513 the spouse counterparts
///   287 Interest income (Sch B, summed across L lines)
///   286 Total dividend income   683 Qualified dividend
///   488 Capital gain distributions   257 Other income (1040:21)
///   275 State taxes + 544 Local taxes (Sch A:5)
///   276 Real estate tax (A:6)   283/545 Home mortgage interest (A:10/11)
///   280 Cash charity (A:16)     485 Non-cash charity (A:17)
///   268/521 Federal estimated tax   636 Student loan interest
///
/// Sign convention per spec §VII.B: income is positive, expenses and tax
/// payments are negative — magnitudes are stored, because ClearFile's model
/// stores positive amounts. Unknown refnums are skipped and reported (honest
/// import, no guessing).

class TxfImportResult {
  const TxfImportResult(this.returnData, this.warnings, this.unknownCodes);

  final TaxReturnData returnData;

  /// Human-readable notes for the import dialog (skips, sign oddities…).
  final List<String> warnings;

  /// Refnums present in the file that ClearFile does not map (deduped).
  final List<int> unknownCodes;
}

class TxfParseException implements Exception {
  const TxfParseException(this.message);

  final String message;

  @override
  String toString() => 'TxfParseException: $message';
}

/// UI-level outcome of a TXF import: the parsed result (which may carry
/// warnings), a user-facing error, or a cancellation.
class TxfImportOutcome {
  const TxfImportOutcome({this.result, this.error});

  const TxfImportOutcome.cancelled()
      : result = null,
        error = null;

  final TxfImportResult? result;
  final String? error;

  bool get cancelled => result == null && error == null;
}

const int _maxBytes = 5 * 1024 * 1024;
const int _maxRecords = 10000;
const int _maxLineLength = 4096;

class _W2Accumulator {
  String? payer;
  double salary = 0;
  double withholding = 0;
}

TxfImportResult parseTxf(String contents) {
  if (contents.length > _maxBytes) {
    throw const TxfParseException(
        'File exceeds the 5 MB parser limit (parser hardening, ADV-ENG #11).');
  }

  final warnings = <String>[];
  final unknown = <int>{};
  final rawLines =
      contents.split('\n').map((l) => l.replaceAll('\r', '')).toList();

  // Header fields (V version / A program / D date) before the first '^'.
  String? version;
  String? exportDate;
  var sawHeaderTerminator = false;
  final records = <_TxfRecord>[];

  for (var i = 0; i < rawLines.length; i++) {
    final raw = rawLines[i];
    if (raw.length > _maxLineLength) {
      throw TxfParseException(
          'Line ${i + 1} exceeds the 4096-character parser limit.');
    }
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line == '^') {
      sawHeaderTerminator = true;
      continue;
    }
    if (!sawHeaderTerminator) {
      final tag = line[0];
      final value = line.substring(1).trim();
      if (tag == 'V') version = value;
      if (tag == 'D') exportDate = value;
      continue;
    }
    final rec = _TxfRecord();
    records.add(rec);
    if (records.length > _maxRecords) {
      throw const TxfParseException(
          'More than 10,000 records (parser hardening).');
    }
    // The triggering line is itself the record's first field line (a
    // record may legally start at `N460` — T defaults to S per spec).
    _applyField(rec, line);
    // Accumulate further fields until the record terminator.
    while (i + 1 < rawLines.length) {
      final nextRaw = rawLines[++i].replaceAll('\r', '');
      if (nextRaw.length > _maxLineLength) {
        throw TxfParseException(
            'Line ${i + 1} exceeds the 4096-character parser limit.');
      }
      final next = nextRaw.trim();
      if (next.isEmpty) continue;
      if (next == '^') break;
      _applyField(rec, next);
    }
    if (rec.refnum == null) {
      rec.malformed = true;
    }
  }

  if (version == null) {
    warnings.add('No V version field found; parsed the records anyway.');
  } else if (version != '042') {
    warnings
        .add('TXF spec version V$version parsed (the suite pins V042).');
  }
  if (exportDate != null) {
    final year = int.tryParse(exportDate.substring(exportDate.length - 4));
    if (year != null && year != 2025) {
      warnings.add('TXF carries no tax-year field; the export date is '
          '$year, so the return stays on 2025 — edit it after import.');
    }
  }

  // --- W-2 copies (grouped by the C copy field; spouse codes live in a
  // separate copy space per spec §III) -------------------------------
  final w2s = <String, _W2Accumulator>{};

  // --- scalar sums --------------------------------------------------------
  var interest = 0.0;
  var divTotal = 0.0;
  var divQualified = 0.0;
  var capGainDist = 0.0;
  var otherIncome = 0.0;
  var stateLocalTax = 0.0;
  var realEstateTax = 0.0;
  var mortgageInterest = 0.0;
  var charityCash = 0.0;
  var charityNonCash = 0.0;
  var estimatedPayments = 0.0;
  var studentLoanInterest = 0.0;

  var detailRecordsIgnored = 0;
  var malformedRecords = 0;
  var importableRecords = 0;

  for (final rec in records) {
    if (rec.malformed) {
      malformedRecords++;
      continue;
    }
    if (rec.type == 'D') {
      detailRecordsIgnored++;
      continue;
    }
    if (rec.type != null && rec.type != 'S') {
      warnings.add('Record N${rec.refnum} has unknown type '
          '"${rec.type}"; skipped.');
      continue;
    }
    final code = rec.refnum!;
    final amount = _amountOf(rec, warnings, code);
    switch (code) {
      // --- W-2 family (copy-grouped) --------------------------------------
      case 460:
      case 506:
        _w2Slot(w2s, code == 460, rec.copy).salary =
            _first(_w2Slot(w2s, code == 460, rec.copy).salary, amount,
                warnings, 'W-2 salary (copy ${rec.copy})');
      case 461:
      case 507:
        _w2Slot(w2s, code == 461, rec.copy).withholding =
            _first(_w2Slot(w2s, code == 461, rec.copy).withholding,
                amount.abs(), warnings, 'W-2 withholding (copy ${rec.copy})');
      case 466:
      case 513:
        _w2Slot(w2s, code == 466, rec.copy).payer ??= rec.text;
      // --- income (summed across L lines, per the spec's multi-line model)
      case 287:
        interest += amount;
      case 286:
        divTotal += amount;
      case 683:
        divQualified += amount;
      case 488:
        capGainDist += amount;
      case 257:
        otherIncome += amount;
      // --- deductions / payments (magnitudes) ----------------------------
      case 275:
      case 544:
        stateLocalTax += amount.abs();
      case 276:
        realEstateTax += amount.abs();
      case 283:
      case 545:
        mortgageInterest += amount.abs();
      case 280:
        charityCash += amount.abs();
      case 485:
        charityNonCash += amount.abs();
      case 268:
      case 521:
        estimatedPayments += amount.abs();
      case 636:
        studentLoanInterest += amount.abs();
      default:
        unknown.add(code);
    }
    importableRecords++;
  }

  final w2Entries = <W2Entry>[];
  final orderedKeys = w2s.keys.toList()..sort();
  for (final key in orderedKeys) {
    final acc = w2s[key]!;
    if (acc.salary == 0 && acc.withholding == 0 && (acc.payer ?? '').isEmpty) {
      continue;
    }
    w2Entries
        .add(W2Entry(employer: acc.payer ?? '', wages: acc.salary, withholding: acc.withholding));
  }

  if (divQualified > 0 && divTotal > 0 && divQualified > divTotal) {
    warnings.add('Qualified dividends exceed total dividends; the ordinary '
        'portion was clamped to zero.');
  }
  final ordinary = divQualified > 0 ? divTotal - divQualified : divTotal;
  if (divQualified > 0 && divTotal == 0) {
    warnings.add('Qualified dividends imported with no total-dividend record; '
        'the ordinary portion is unknown and left at zero.');
  }

  if (importableRecords == 0) {
    throw const TxfParseException(
        'No importable summary (TS) records were found. The file may be a '
        'detail-only export or not a TXF file at all.');
  }

  final filing = TaxReturnData(
    displayName: 'Imported from TXF',
    w2s: w2Entries,
    interestIncome: interest,
    ordinaryDividends: ordinary > 0 ? ordinary : 0,
    qualifiedDividends: divQualified,
    longTermCapitalGains: capGainDist,
    otherIncome: otherIncome,
    studentLoanInterest: studentLoanInterest,
    stateLocalIncomeOrSalesTax: stateLocalTax,
    realEstateTax: realEstateTax,
    mortgageInterest: mortgageInterest,
    charitableCash: charityCash,
    charitableNonCash: charityNonCash,
    estimatedPayments: estimatedPayments,
  );

  if (detailRecordsIgnored > 0) {
    warnings.add('$detailRecordsIgnored detail (TD) records ignored, '
        'per the spec.');
  }
  if (malformedRecords > 0) {
    warnings.add('$malformedRecords records had no N refnum and were '
        'skipped.');
  }
  if (unknown.isNotEmpty) {
    warnings.add('Refnums present but not mapped by the demo scope: '
        '${(unknown.toList()..sort()).join(", ")}.');
  }
  if (filing.w2s.isEmpty) {
    warnings.add('No W-2 wage records found — only the non-wage fields '
        'imported.');
  }

  return TxfImportResult(filing, warnings, unknown.toList()..sort());
}

class _TxfRecord {
  String? type;
  int? refnum;
  int copy = 1;
  int line = 1;
  String? text;
  bool malformed = false;
  final List<String> amounts = [];
}

/// Applies one `T`/`N`/`C`/`L`/`$`/`P`/`X`/`D` field line to [rec].
/// Detail ('X') and date ('D') lines carry nothing the importer needs.
void _applyField(_TxfRecord rec, String line) {
  final tag = line[0];
  final value = line.substring(1).trim();
  switch (tag) {
    case 'T':
      rec.type = value.toUpperCase();
    case 'N':
      rec.refnum = int.tryParse(value);
    case 'C':
      rec.copy = int.tryParse(value) ?? 1;
    case 'L':
      rec.line = int.tryParse(value) ?? 1;
    case r'$':
      rec.amounts.add(value);
    case 'P':
      rec.text = value;
    case 'X':
    case 'D':
    default:
      break;
  }
}

_W2Accumulator _w2Slot(Map<String, _W2Accumulator> map, bool self, int copy) =>
    map.putIfAbsent('${self ? 'self' : 'spouse'}:$copy', _W2Accumulator.new);

double _amountOf(_TxfRecord rec, List<String> warnings, int code) {
  if (rec.amounts.isEmpty) return 0;
  var total = 0.0;
  for (final raw in rec.amounts) {
    final parsed = parseMoney(raw);
    if (parsed == null) {
      warnings.add('Record N$code: amount "$raw" could not be read; '
          'skipped.');
      continue;
    }
    total += parsed;
  }
  return total;
}

double _first(double current, double value, List<String> warnings,
    String what) {
  if (current != 0) {
    warnings.add('Duplicate $what record; the first one was kept.');
    return current;
  }
  return value;
}
