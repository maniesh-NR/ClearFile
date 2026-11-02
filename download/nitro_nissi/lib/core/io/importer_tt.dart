/// Best-effort importer for proprietary TurboTax return files and common
/// interchange formats.
///
/// IMPORTANT — read docs/FILE_FORMATS.md before changing this file.
/// Modern TurboTax desktop formats (.tax20xx) are proprietary, undocumented
/// and may be encrypted. This importer therefore does *structural* analysis:
/// it detects containers (ZIP, OLE2/CFB, raw JSON/CSV), inflates zlib/deflate
/// streams it finds, and scans the decoded text for tax field keys. Every
/// match lands in a [ImportPreview] that the user reviews field-by-field in
/// the UI before anything is applied. We never silently overwrite data, we
/// never attempt to circumvent encryption (that is a hard policy — see
/// docs/REVERSE_ENGINEERING_PLAN.md), and unknown files produce a clear
/// explanation instead of a crash.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../tax/model.dart';
import 'ole_cfb.dart';

/// One field candidate found in a foreign file.
class ImportField {
  final String key; // canonical key, e.g. w2.wages
  final String label; // display label
  final Object? value; // double or String
  final double confidence; // 0..1
  final String source; // where it came from (stream/entry/line)
  const ImportField(this.key, this.label, this.value, this.confidence, this.source);

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'value': value,
        'confidence': confidence,
        'source': source,
      };
}

class ImportPreview {
  final String detectedFormat; // e.g. 'zip/json', 'ole2', 'raw-json', 'csv', 'unknown'
  final String note; // human-readable note (l10n key chosen by caller)
  final List<ImportField> fields;
  const ImportPreview(this.detectedFormat, this.note, this.fields);

  bool get isEmpty => fields.isEmpty;
}

class TurboTaxImporter {
  const TurboTaxImporter();

  static const _zipSig = [0x50, 0x4B];
  static const _cfbSig = [0xD0, 0xCF, 0x11, 0xE0];

  /// Main entry: analyze bytes of any supported file.
  ImportPreview analyze(Uint8List bytes, String fileName) {
    try {
      if (bytes.length >= 4 && bytes[0] == _zipSig[0] && bytes[1] == _zipSig[1]) {
        return _analyzeZip(bytes, fileName);
      }
      if (bytes.length >= 4 && _matchesSig(bytes, _cfbSig)) {
        return _analyzeCfb(bytes, fileName);
      }
      final text = _decodeText(bytes);
      final trimmed = text.trimLeft();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        return _analyzeJsonText(text, 'raw-json');
      }
      if (trimmed.contains(',') && trimmed.split('\n').first.contains(',')) {
        return _analyzeCsv(text, fileName);
      }
      // Fallback: deep scan for zlib streams or embedded JSON in binary blobs.
      return _deepScan(bytes, 'unknown-binary');
    } catch (_) {
      return ImportPreview('error', 'importErrorUnknown', const []);
    }
  }

  bool _matchesSig(Uint8List b, List<int> sig) {
    for (var i = 0; i < sig.length; i++) {
      if (b[i] != sig[i]) return false;
    }
    return true;
  }

  ImportPreview _analyzeZip(Uint8List bytes, String fileName) {
    final fields = <ImportField>[];
    String innerFormat = 'zip';
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final f in archive.files) {
        if (f.isFile) {
          final data = f.content as Uint8List? ?? Uint8List(0);
          final text = _decodeText(data);
          final t = text.trimLeft();
          if (t.startsWith('{') || t.startsWith('[')) {
            fields.addAll(_extractFromJson(text, f.name));
            innerFormat = 'zip/json';
          } else if (t.contains(',') && t.contains('\n')) {
            fields.addAll(_extractFromCsv(text, f.name));
            innerFormat = 'zip/csv';
          } else {
            fields.addAll(_scanText(text, f.name));
            innerFormat = 'zip/binary';
          }
        }
      }
    } catch (_) {
      // Encrypted or non-standard zip.
      return ImportPreview('zip-encrypted', 'importNoteZipEncrypted', const []);
    }
    return ImportPreview(innerFormat, 'importNotePreview', fields);
  }

  ImportPreview _analyzeCfb(Uint8List bytes, String fileName) {
    try {
      final cfb = CompoundFileReader(bytes);
      final fields = <ImportField>[];
      for (final s in cfb.streams) {
        final data = s.data;
        if (data == null || data.isEmpty) continue;
        // Try direct text.
        final text = _decodeText(data);
        final t = text.trimLeft();
        if (t.startsWith('{')) {
          fields.addAll(_extractFromJson(text, s.name));
          continue;
        }
        // Try inflating zlib streams inside.
        final inflated = _inflateAll(data);
        for (final chunk in inflated) {
          final chunkText = _decodeText(chunk);
          fields.addAll(_scanText(chunkText, s.name));
        }
        // Also scan raw for embedded JSON.
        fields.addAll(_scanText(text, s.name));
      }
      if (fields.isEmpty) {
        return ImportPreview('ole2', 'importNoteOle2NoFields', const []);
      }
      return ImportPreview('ole2', 'importNotePreview', fields);
    } catch (_) {
      return ImportPreview('ole2', 'importNoteOle2Unknown', const []);
    }
  }

  ImportPreview _analyzeJsonText(String text, String format) {
    final fields = _extractFromJson(text, 'inline');
    return ImportPreview(format, 'importNotePreview', fields);
  }

  ImportPreview _analyzeCsv(String text, String fileName) {
    return ImportPreview('csv', 'importNotePreview', _extractFromCsv(text, fileName));
  }

  ImportPreview _deepScan(Uint8List bytes, String format) {
    final fields = <ImportField>[];
    for (final chunk in _inflateAll(bytes)) {
      final text = _decodeText(chunk);
      fields.addAll(_scanText(text, 'inflated'));
    }
    if (fields.isEmpty) {
      fields.addAll(_scanText(_decodeText(bytes), 'raw'));
    }
    if (fields.isEmpty) {
      return ImportPreview(format, 'importNoteUnknown', const []);
    }
    return ImportPreview(format, 'importNotePreview', fields);
  }

  /// Find and inflate zlib/deflate streams. Returns decoded chunks.
  ///
  /// Strategy: locate zlib stream headers (0x78 followed by a valid FLG),
  /// then attempt decode over a few growing window sizes. Bounded work;
  /// failures are silently skipped (best-effort by design).
  List<Uint8List> _inflateAll(Uint8List data) {
    final out = <Uint8List>[];
    const windows = [4096, 65536, 1048576];
    for (var i = 0; i < data.length - 2 && out.length < 8; i++) {
      final b0 = data[i];
      if (b0 != 0x78) continue; // common zlib CMF byte
      final b1 = data[i + 1];
      final v = (b0 << 8) | b1;
      if (v % 31 != 0 || (b1 & 0x20) != 0) continue; // not a zlib header
      for (final w in windows) {
        final end = (i + w) < data.length ? (i + w) : data.length;
        try {
          final candidate = data.sublist(i, end);
          final inf = ZLibDecoder().decodeBytes(candidate, verify: false);
          if (inf.length > 16) {
            out.add(Uint8List.fromList(inf));
            i += candidate.length - 1;
          }
          break;
        } catch (_) {
          // try next window size
        }
      }
    }
    return out;
  }

  String _decodeText(Uint8List bytes) {
    // UTF-16LE heuristic (high zero-byte density).
    var zeros = 0;
    final probe = bytes.length > 512 ? 512 : bytes.length;
    for (var i = 1; i < probe; i += 2) {
      if (bytes[i] == 0) zeros++;
    }
    if (zeros > probe ~/ 4) {
      return const Utf16Decoder(le: true).convert(bytes);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  // ---------------- Field mapping ----------------

  static const Map<String, List<String>> _keyMap = {
    'w2.employer': ['employername', 'employer_name', 'employername1', 'employersname', 'employer'],
    'w2.ein': ['ein', 'employeridentificationnumber', 'employerein', 'fein'],
    'w2.wages': ['wages', 'wagestipsothercomp', 'wagesTipsOther', 'w2wages', 'fedwages', 'box1'],
    'w2.withholding': ['federalwithholding', 'federalincometaxwithheld', 'withholding', 'box2', 'fedwithholding'],
    'w2.ssWages': ['socialsecuritywages', 'sswages', 'box3'],
    'w2.ssWithholding': ['socialsecuritytaxwithheld', 'sstaxwithheld', 'box4'],
    'w2.medicareWithholding': ['medicarewithholding', 'medicaretaxwithheld', 'box6'],
    'w2.qualifiedTips': ['qualifiedtips', 'tipsreported', 'tips'],
    'w2.qualifiedOvertime': ['qualifiedovertime', 'overtimepay', 'overtime'],
    'interest.taxable': ['taxableinterest', 'interestincome', '1099int', 'interest'],
    'interest.taxExempt': ['taxexemptinterest', 'taxexempt'],
    'dividends.ordinary': ['ordinarydividends', 'dividends', '1099div'],
    'dividends.qualified': ['qualifieddividends', 'qualdividends'],
    'capgains.proceeds': ['proceeds', 'grossproceeds', 'salesprice'],
    'capgains.basis': ['costbasis', 'basis', 'cost'],
    'capgains.longTerm': ['islongterm', 'longterm', 'holdingperiod'],
    'se.netProfit': ['netprofit', 'selfemploymentincome', 'schedulecnet', 'netincome', 'businessincome'],
    'retirement.taxable': ['taxableamount', 'pensionincome', 'iraDistribution', '1099r'],
    'ss.benefits': ['socialsecuritybenefits', 'ssabenefits', 'ssbenefits'],
    'unemployment.amount': ['unemploymentcompensation', 'unemploymentincome', 'unemployment'],
    'adjustments.ira': ['iracontribution', 'iradeduction', 'traditionalira'],
    'adjustments.studentLoanInterest': ['studentloaninterest', 'slinterest'],
    'deductions.salt': ['statelocaltaxes', 'salt', 'statetaxeswithheld'],
    'deductions.mortgage': ['mortgageinterest', 'homeMortgageInterest', '1098interest'],
    'deductions.charity': ['charitablecontributions', 'charity', 'giftsToCharity'],
    'taxpayer.firstName': ['firstname', 'taxpayerfirstname'],
    'taxpayer.lastName': ['lastname', 'taxpayerlastname'],
    'taxpayer.ssn': ['ssn', 'socialsecuritynumber', 'taxpayerssn'],
    'spouse.firstName': ['spousefirstname', 'spousefirst'],
    'spouse.lastName': ['spouselastname', 'spouselast'],
    'spouse.ssn': ['spousessn'],
    'filingStatus': ['filingstatus', 'status'],
  };

  static const _labelOverrides = {
    'w2.employer': 'Employer name',
    'w2.ein': 'Employer EIN',
    'w2.wages': 'W-2 wages (Box 1)',
    'w2.withholding': 'Federal withholding (Box 2)',
    'w2.ssWages': 'Social Security wages (Box 3)',
    'w2.ssWithholding': 'Social Security withheld (Box 4)',
    'w2.medicareWithholding': 'Medicare withheld (Box 6)',
    'w2.qualifiedTips': 'Qualified tips (OBBBA)',
    'w2.qualifiedOvertime': 'Qualified overtime (OBBBA)',
  };

  List<ImportField> _extractFromJson(String text, [String source = 'json']) {
    try {
      final j = jsonDecode(text);
      final out = <ImportField>[];
      void walk(dynamic node, String path) {
        if (node is Map) {
          node.forEach((k, v) {
            if (v is Map || v is List) {
              walk(v, path.isEmpty ? '$k' : '$path.$k');
            } else {
              _tryMap('$k', v, '$source:$path.$k', out);
            }
          });
        } else if (node is List) {
          for (var i = 0; i < node.length; i++) {
            walk(node[i], '$path[$i]');
          }
        }
      }

      walk(j, '');
      return out;
    } catch (_) {
      return _scanText(text, source);
    }
  }

  void _tryMap(String rawKey, Object? rawValue, String source, List<ImportField> out) {
    final k = rawKey.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (k.isEmpty || rawValue == null) return;
    for (final entry in _keyMap.entries) {
      for (final alias in entry.value) {
        double conf = 0;
        if (k == alias.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')) {
          conf = 0.9;
        } else if (k.contains(alias.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))) {
          conf = 0.55;
        }
        if (conf > 0) {
          out.add(ImportField(
            entry.key,
            _labelOverrides[entry.key] ?? entry.key,
            _coerce(entry.key, rawValue),
            conf,
            source,
          ));
          return;
        }
      }
    }
  }

  Object? _coerce(String key, Object? v) {
    if (key == 'taxpayer.firstName' ||
        key == 'taxpayer.lastName' ||
        key == 'taxpayer.ssn' ||
        key == 'spouse.firstName' ||
        key == 'spouse.lastName' ||
        key == 'spouse.ssn' ||
        key == 'w2.employer' ||
        key == 'w2.ein' ||
        key == 'filingStatus') {
      return v is String ? v : v.toString();
    }
    if (key == 'capgains.longTerm') {
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      return s == 'true' || s == 'long' || s == '1';
    }
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(RegExp(r'[$,\s]'), '');
    return double.tryParse(s) ?? v;
  }

  /// Regex scan over arbitrary text for `"key": value` or key = value shapes.
  List<ImportField> _scanText(String text, String source) {
    final out = <ImportField>[];
    for (final entry in _keyMap.entries) {
      for (final alias in entry.value) {
        final pattern = RegExp(
          '"?${RegExp.escape(alias)}"?\\s*[:=]\\s*"?([0-9][0-9,\\.]*|[^",\\n\\}]{2,60})"?',
          caseSensitive: false,
        );
        for (final m in pattern.allMatches(text)) {
          out.add(ImportField(
            entry.key,
            _labelOverrides[entry.key] ?? entry.key,
            _coerce(entry.key, m.group(1)),
            0.4,
            source,
          ));
        }
      }
    }
    return out;
  }

  List<ImportField> _extractFromCsv(String text, String fileName) {
    final fields = <ImportField>[];
    final lines = const LineSplitter().convert(text);
    if (lines.isEmpty) return fields;
    final headers = _splitCsvLine(lines.first);
    for (var r = 1; r < lines.length; r++) {
      final cells = _splitCsvLine(lines[r]);
      final rowTag = lines.length > 2 ? 'row$r' : fileName;
      for (var c = 0; c < headers.length && c < cells.length; c++) {
        _tryMap(headers[c], cells[c], '$rowTag:${headers[c]}', fields);
      }
    }
    return fields;
  }

  List<String> _splitCsvLine(String line) {
    final out = <String>[];
    var cur = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          cur.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        out.add(cur.toString().trim());
        cur = StringBuffer();
      } else {
        cur.write(ch);
      }
    }
    out.add(cur.toString().trim());
    return out;
  }
}

class Utf16Decoder {
  final bool le;
  const Utf16Decoder({required this.le});

  String convert(List<int> bytes) {
    final sb = StringBuffer();
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      final code = le ? (bytes[i] | (bytes[i + 1] << 8)) : ((bytes[i] << 8) | bytes[i + 1]);
      if (code == 0) continue;
      sb.writeCharCode(code);
    }
    return sb.toString();
  }
}

/// Apply a reviewed preview onto a return. Only fields the user kept are applied.
TaxReturnData applyImport(TaxReturnData base, List<ImportField> accepted) {
  final d = base;
  double numOf(List<ImportField> fs, String key) {
    for (final f in fs) {
      if (f.key == key && f.value is num) return (f.value as num).toDouble();
    }
    return 0;
  }

  String str(List<ImportField> fs, String key) {
    for (final f in fs) {
      if (f.key == key && f.value is String) return f.value as String;
    }
    return '';
  }

  // Filing status.
  final fs = str(accepted, 'filingStatus').toLowerCase();
  if (fs.contains('joint')) d.filingStatus = FilingStatus.marriedJointly;
  if (fs.contains('separate')) d.filingStatus = FilingStatus.marriedSeparately;
  if (fs.contains('head')) d.filingStatus = FilingStatus.headOfHousehold;

  // People.
  if (str(accepted, 'taxpayer.firstName').isNotEmpty) {
    d.taxpayer.firstName = str(accepted, 'taxpayer.firstName');
  }
  if (str(accepted, 'taxpayer.lastName').isNotEmpty) {
    d.taxpayer.lastName = str(accepted, 'taxpayer.lastName');
  }
  if (str(accepted, 'taxpayer.ssn').isNotEmpty) {
    d.taxpayer.ssn = str(accepted, 'taxpayer.ssn');
  }
  if (str(accepted, 'spouse.firstName').isNotEmpty) {
    d.spouse ??= Person();
    d.spouse!.firstName = str(accepted, 'spouse.firstName');
    d.spouse!.lastName = str(accepted, 'spouse.lastName');
    d.spouse!.ssn = str(accepted, 'spouse.ssn');
  }

  // Interest / dividends.
  final ti = numOf(accepted, 'interest.taxable');
  if (ti > 0) {
    d.interest.add(InterestIncome(
        payer: 'Imported', taxableInterest: ti, taxExemptInterest: numOf(accepted, 'interest.taxExempt')));
  }

  final od = numOf(accepted, 'dividends.ordinary');
  if (od > 0) {
    d.dividends.add(DividendIncome(
        payer: 'Imported',
        ordinaryDividends: od,
        qualifiedDividends: numOf(accepted, 'dividends.qualified')));
  }

  final proceeds = numOf(accepted, 'capgains.proceeds');
  if (proceeds > 0) {
    d.capitalGains.add(CapitalGainEntry(
      description: 'Imported sale',
      proceeds: proceeds,
      costBasis: numOf(accepted, 'capgains.basis'),
      isLongTerm: accepted.any((f) => f.key == 'capgains.longTerm' && f.value == true),
    ));
  }

  final seNet = numOf(accepted, 'se.netProfit');
  if (seNet > 0) {
    d.selfEmployment.add(SelfEmploymentIncome(businessName: 'Imported business', netProfit: seNet));
  }

  final rt = numOf(accepted, 'retirement.taxable');
  if (rt > 0) {
    d.retirement.add(RetirementIncome(payer: 'Imported', grossDistribution: rt, taxableAmount: rt));
  }

  final ue = numOf(accepted, 'unemployment.amount');
  if (ue > 0) d.adjustments.unemploymentAmount = ue;

  final ira = numOf(accepted, 'adjustments.ira');
  if (ira > 0) d.adjustments.iraContributions = ira;
  final sli = numOf(accepted, 'adjustments.studentLoanInterest');
  if (sli > 0) d.adjustments.studentLoanInterest = sli;

  final salt = numOf(accepted, 'deductions.salt');
  if (salt > 0) d.itemized.saltTaxes = salt;
  final mi = numOf(accepted, 'deductions.mortgage');
  if (mi > 0) d.itemized.mortgageInterest = mi;
  final ch = numOf(accepted, 'deductions.charity');
  if (ch > 0) d.itemized.charitableCash = ch;

  // W-2: group by employer name when present; else create one.
  final employer = str(accepted, 'w2.employer');
  final wages = numOf(accepted, 'w2.wages');
  if (wages > 0 || employer.isNotEmpty) {
    final existing = employer.isEmpty
        ? null
        : d.w2s.where((w) => w.employerName.toLowerCase() == employer.toLowerCase()).firstOrNull;
    if (existing != null) {
      if (wages > 0) existing.wages = wages;
      existing.federalWithholding = numOf(accepted, 'w2.withholding');
      existing.ssWages = numOf(accepted, 'w2.ssWages');
      existing.ssWithholding = numOf(accepted, 'w2.ssWithholding');
      existing.medicareWithholding = numOf(accepted, 'w2.medicareWithholding');
      existing.employerEin = str(accepted, 'w2.ein');
    } else {
      d.w2s.add(W2Entry(
        employerName: employer.isEmpty ? 'Imported employer' : employer,
        employerEin: str(accepted, 'w2.ein'),
        wages: wages,
        federalWithholding: numOf(accepted, 'w2.withholding'),
        ssWages: numOf(accepted, 'w2.ssWages'),
        ssWithholding: numOf(accepted, 'w2.ssWithholding'),
        medicareWithholding: numOf(accepted, 'w2.medicareWithholding'),
        qualifiedTips: numOf(accepted, 'w2.qualifiedTips'),
        qualifiedOvertime: numOf(accepted, 'w2.qualifiedOvertime'),
      ));
    }
  }

  return d;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
