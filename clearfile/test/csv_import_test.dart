import 'package:clearfile/io/csv_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the bundled template', () {
    final result = parseW2Csv(w2CsvTemplate);
    expect(result.entries, hasLength(2));
    expect(result.entries.first.employer, 'Acme Corp');
    expect(result.entries.first.wages, 52500);
    expect(result.entries.first.withholding, 6200);
    expect(result.entries[1].employer, 'Beta School District');
    expect(result.entries[1].wages, 38200);
    expect(result.entries[1].withholding, closeTo(3410.50, 0.001));
    expect(result.warnings, isEmpty);
  });

  test('handles quoted commas, doubled quotes and CRLF', () {
    const csv =
        'employer,box1_wages,box2\r\n"Smith, John & ""Co""",1000,100\r\n';
    final result = parseW2Csv(csv);
    expect(result.entries.single.employer, 'Smith, John & "Co"');
    expect(result.entries.single.wages, 1000);
    expect(result.entries.single.withholding, 100);
  });

  test('accepts header synonyms case-insensitively', () {
    const csv = 'Employer Name,Wages,Federal Tax Withheld\nAcme,10,1\n';
    final r = parseW2Csv(csv);
    expect(r.entries.single.employer, 'Acme');
    expect(r.entries.single.wages, 10);
    expect(r.entries.single.withholding, 1);
  });

  test('throws when no wages column exists', () {
    expect(() => parseW2Csv('employer,name\nA,B\n'), throwsFormatException);
  });

  test('throws on an empty file', () {
    expect(() => parseW2Csv(''), throwsFormatException);
  });

  test('skips rows with unreadable numbers and warns', () {
    const csv = 'employer,box1_wages,box2\nA,abc,1\nB,200,5\n';
    final r = parseW2Csv(csv);
    expect(r.entries, hasLength(1));
    expect(r.entries.single.employer, 'B');
    expect(r.warnings, hasLength(1));
  });

  test('allows a missing withholding column', () {
    const csv = 'employer,wages\nA,500\n';
    final r = parseW2Csv(csv);
    expect(r.entries.single.wages, 500);
    expect(r.entries.single.withholding, 0);
  });

  test('strips dollar signs and thousands separators', () {
    const csv = 'employer,wages,withholding\nA,"\$52,500.00","6,200"\n';
    final r = parseW2Csv(csv);
    expect(r.entries.single.wages, 52500);
    expect(r.entries.single.withholding, 6200);
  });

  test('empty trailing lines are ignored', () {
    const csv = 'employer,wages,withholding\nA,100,10\n\n\n';
    final r = parseW2Csv(csv);
    expect(r.entries, hasLength(1));
  });
}
