import '../models/w2.dart';

/// Result of parsing a W-2 CSV file: mapped [entries] plus human-readable
/// [warnings] for rows that were skipped.
class CsvW2Import {
  const CsvW2Import(this.entries, this.warnings);

  final List<W2Entry> entries;
  final List<String> warnings;
}

/// The template offered by the "Import W-2s from CSV" flow.
const String w2CsvTemplateHeader =
    'employer,box1_wages,box2_federal_tax_withheld';

const String w2CsvTemplate = '''
employer,box1_wages,box2_federal_tax_withheld
Acme Corp,52500.00,6200.00
Beta School District,38200.00,3410.50
''';

/// Parses W-2 data from CSV text.
///
/// Column names are matched case-insensitively after removing spaces,
/// underscores and punctuation, and a number of common synonyms are accepted
/// (see [_columnFor]). A wages column is required; withholding and employer
/// are optional. Quoted fields with embedded commas, doubled quotes and
/// CRLF line endings are handled.
///
/// Throws [FormatException] when no header can be understood.
CsvW2Import parseW2Csv(String contents) {
  final rows = parseCsvRows(contents);
  if (rows.isEmpty) {
    throw const FormatException('The file appears to be empty.');
  }
  final header = rows.first.map(_normalizeHeader).toList();
  final employerIdx = _columnFor(header, _employerNames);
  final wagesIdx = _columnFor(header, _wagesNames);
  final withholdingIdx = _columnFor(header, _withholdingNames);

  if (wagesIdx == null) {
    throw const FormatException(
        'Could not find a wages column. Expected a header such as '
        '"box1_wages", "wages" or "Box 1".');
  }

  final entries = <W2Entry>[];
  final warnings = <String>[];

  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.isEmpty || row.every((cell) => cell.trim().isEmpty)) continue;

    String cell(int idx) => idx != null && idx < row.length ? row[idx].trim() : '';

    final wages = _parseAmount(cell(wagesIdx));
    final withholding =
        withholdingIdx == null ? 0.0 : _parseAmount(cell(withholdingIdx));
    final employer = cell(employerIdx);

    if (wages == null || (withholdingIdx != null && withholding == null)) {
      warnings.add('Row $i skipped: a number could not be read.');
      continue;
    }
    entries.add(W2Entry(
      employer: employer,
      wages: wages ?? 0,
      withholding: withholding ?? 0,
    ));
  }

  return CsvW2Import(entries, warnings);
}

/// Minimal RFC 4180-style parser: quoted fields, doubled quotes, commas and
/// CRLF or LF line endings.
List<List<String>> parseCsvRows(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
      continue;
    }
    if (c == '"') {
      inQuotes = true;
    } else if (c == ',') {
      row.add(field.toString());
      field = StringBuffer();
    } else if (c == '\r') {
      // Swallow; the following \n (if any) ends the row.
    } else if (c == '\n') {
      row.add(field.toString());
      rows.add(row);
      row = <String>[];
      field = StringBuffer();
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  // Drop a trailing fully-empty row caused by a final newline.
  if (rows.isNotEmpty &&
      rows.last.every((cell) => cell.isEmpty) &&
      rows.last.length == 1) {
    rows.removeLast();
  }
  return rows;
}

String _normalizeHeader(String raw) =>
    raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

const Set<String> _employerNames = {
  'employer',
  'employername',
  'company',
  'employernamebox1',
};

const Set<String> _wagesNames = {
  'box1',
  'box1wages',
  'wages',
  'w2wages',
  'box1wagestipsothercompensation',
  'wagestipsothercompensation',
  'box1wagestipsother',
};

const Set<String> _withholdingNames = {
  'box2',
  'box2wages',
  'box2federaltaxwithheld',
  'federaltaxwithheld',
  'withholding',
  'federalwithholding',
  'federalincometaxwithheld',
};

int? _columnFor(List<String> header, Set<String> names) {
  for (var i = 0; i < header.length; i++) {
    if (names.contains(header[i])) return i;
  }
  return null;
}

double? _parseAmount(String raw) {
  final cleaned = raw
      .replaceAll('\$', '')
      .replaceAll(',', '')
      .replaceAll(RegExp(r'\s'), '');
  if (cleaned.isEmpty) return 0;
  return double.tryParse(cleaned);
}
