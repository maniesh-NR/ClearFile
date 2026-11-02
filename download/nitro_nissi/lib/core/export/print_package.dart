/// Printable return package (PDF) - summary, income, deductions, credits,
/// and the e-file-ready JSON as an appendix.
///
/// Uses the pure-Dart `pdf` package so it works on every target including
/// the web build. Documents produced by this app are estimates for review,
/// not official IRS forms (see docs/SCOPE.md).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../tax/model.dart';
import '../tax/engine.dart';
import '../efile/mef_json.dart';

class PrintPackage {
  const PrintPackage();

  Future<Uint8List> build(TaxReturnData d, TaxResult r) async {
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
    );

    pw.Widget row(String label, double value, {bool bold = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
              pw.Text(_money(value),
                  style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            ],
          ),
        );

    pw.Widget section(String title) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
          child: pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(6),
            color: PdfColors.indigo50,
            child: pw.Text(title,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ),
        );

    final mef = const MeFExporter().export(d, r);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Nitro Nissi',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text('Federal Return Package - Tax Year ${d.taxYear} (estimate, not an official form)',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text(_statusLabel(d.filingStatus), style: pw.TextStyle(fontSize: 10)),
                pw.Text('Prepared ${_today()}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ]),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.indigo300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(r.isRefund ? 'Estimated refund' : 'Estimated balance due',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Text(_money(r.refundOrOwe.abs()),
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: r.isRefund ? PdfColors.green800 : PdfColors.red800)),
              ],
            ),
          ),
          section('Taxpayers'),
          pw.Text(
            '${d.taxpayer.firstName} ${d.taxpayer.lastName}'
            '${d.spouse != null ? ' & ${d.spouse!.firstName} ${d.spouse!.lastName}' : ''}'
            '  ·  ${d.dependents.length} dependent(s)',
            style: pw.TextStyle(fontSize: 10),
          ),
          section('Income'),
          row('Wages (W-2)', r.wages),
          if (r.seNet > 0) row('Self-employment net profit', r.seNet),
          if (r.taxableInterest > 0) row('Taxable interest', r.taxableInterest),
          if (r.ordinaryDividends > 0) row('Ordinary dividends', r.ordinaryDividends),
          if (r.netShortTermGain + r.netLongTermGain != 0)
            row('Net capital gain', r.netShortTermGain + r.netLongTermGain),
          if (r.retirementTaxable > 0) row('Retirement distributions (taxable)', r.retirementTaxable),
          if (r.socialSecurityTaxable > 0) row('Social Security (taxable part)', r.socialSecurityTaxable),
          if (r.unemployment > 0) row('Unemployment', r.unemployment),
          row('Total income', r.totalIncome, bold: true),
          section('Adjustments & AGI'),
          if (r.halfSeTaxDeduction > 0) row('One-half of SE tax', -r.halfSeTaxDeduction),
          if (r.iraDeduction > 0) row('IRA contribution', -r.iraDeduction),
          if (r.studentLoanInterestDeduction > 0) row('Student loan interest', -r.studentLoanInterestDeduction),
          if (r.obbbaTipsDeduction > 0) row('Qualified tips deduction (OBBBA)', -r.obbbaTipsDeduction),
          if (r.obbbaOvertimeDeduction > 0) row('Qualified overtime deduction (OBBBA)', -r.obbbaOvertimeDeduction),
          if (r.obbbaCarLoanDeduction > 0) row('Car loan interest deduction (OBBBA)', -r.obbbaCarLoanDeduction),
          row('Adjusted gross income', r.agi, bold: true),
          section('Deduction'),
          row(r.deductionUsed == r.itemizedDeductionUsed ? 'Itemized deductions' : 'Standard deduction',
              r.deductionUsed),
          if (r.qbiDeduction > 0) row('QBI deduction (§199A)', -r.qbiDeduction),
          if (r.seniorDeduction > 0) row('Senior deduction (OBBBA)', -r.seniorDeduction),
          row('Taxable income', r.taxableIncome, bold: true),
          section('Tax'),
          row('Ordinary tax', r.ordinaryTax),
          if (r.preferentialTax > 0) row('Preferential rates (0/15/20%)', r.preferentialTax),
          if (r.seTax > 0) row('Self-employment tax', r.seTax),
          if (r.niit > 0) row('Net investment income tax', r.niit),
          if (r.additionalMedicareTax > 0) row('Additional Medicare tax', r.additionalMedicareTax),
          row('Total tax', r.totalTax, bold: true),
          section('Credits'),
          if (r.ctcTotal > 0) row('Child Tax Credit (incl. refundable)', r.ctcTotal),
          if (r.childCareCredit > 0) row('Child & dependent care credit', r.childCareCredit),
          if (r.aotcNonrefundable + r.aotcRefundable > 0)
            row('American opportunity credit', r.aotcNonrefundable + r.aotcRefundable),
          if (r.llcCredit > 0) row('Lifetime learning credit', r.llcCredit),
          if (r.saversCredit > 0) row("Saver's credit", r.saversCredit),
          if (r.eitc > 0) row('Earned Income Tax Credit', r.eitc),
          section('Payments'),
          row('Withholding + estimated payments', r.totalPayments),
          row(r.isRefund ? 'REFUND' : 'AMOUNT OWED', r.refundOrOwe.abs(), bold: true),
          pw.SizedBox(height: 16),
          pw.Text(
            'This package was produced by Nitro Nissi, a clean-room open-source estimator. '
            'It is not filed with the IRS. Review everything and consult a tax professional '
            'for advice about your situation.',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Appendix: e-file-ready JSON (MeF-style layout)',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(const JsonEncoder.withIndent('  ').convert(mef),
              style: pw.TextStyle(fontSize: 6, color: PdfColors.grey800)),
        ],
      ),
    );

    return doc.save();
  }

  String _money(double v) {
    final neg = v < 0;
    final a = v.abs().round();
    final s = a.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '${neg ? '-' : ''}\$$s';
  }

  String _statusLabel(FilingStatus s) {
    switch (s) {
      case FilingStatus.single:
        return 'Single';
      case FilingStatus.marriedJointly:
        return 'Married filing jointly';
      case FilingStatus.marriedSeparately:
        return 'Married filing separately';
      case FilingStatus.headOfHousehold:
        return 'Head of household';
      case FilingStatus.qualifyingSurvivingSpouse:
        return 'Qualifying surviving spouse';
    }
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
