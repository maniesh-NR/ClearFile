/// Prompt library + structured document extraction for the AI assistant.
///
/// Design rules:
///  - The AI NEVER writes directly into the return. Everything it produces
///    becomes a *suggestion* the user reviews on screen.
///  - Personal data (names/SSNs) is stripped before sending unless the user
///    explicitly turns that off (it is on by default).
///  - The system prompt insists on plain language and disclaims tax advice.
library;

import 'dart:convert';

import '../tax/model.dart';

class AiPrompts {
  static const String systemAssistant = '''
You are the built-in assistant inside Nitro Nissi, an open-source US federal
tax preparation app (2024 and 2025 tax years). You help taxpayers understand
concepts and complete their return.

Rules:
- Use plain language (6th-8th grade reading level). Short paragraphs.
- You are NOT a tax professional and this is NOT tax advice. Recommend the
  user consults a professional for complex situations.
- Never invent IRS rules, numbers, forms or deadlines. If unsure, say so.
- The engine computes all numbers; do not recompute taxes unless asked to
  explain a number, and then explain which inputs drive it.
- When the user pastes document text (W-2, 1099), extract values into the
  requested JSON structure and nothing else.
- Reply in the user's language (English or Spanish).
''';

  /// Extract structured fields from pasted document text.
  static String extractionPrompt(String docType, String text) {
    const schema = '''
{
  "employerName": "", "employerEin": "",
  "wages": 0, "federalWithholding": 0, "ssWages": 0, "ssWithholding": 0, "medicareWithholding": 0,
  "qualifiedTips": 0, "qualifiedOvertime": 0
}''';
    return '''
Extract data from this $docType document text into strict JSON matching this
shape (numbers only, no currency symbols; use 0 when absent):

$schema

Document text:
"""$text"""

Respond with ONLY the JSON object.''';
  }

  /// Review an anonymized return summary for commonly missed items.
  static String reviewPrompt(String summaryJson) {
    return '''
Review this anonymized tax return summary. List up to 6 concrete suggestions
for things the filer may have missed or should double-check (deductions,
credits, common errors for their situation). Ignore anything already present.

Return strict JSON: {"suggestions": [{"title": "", "detail": "", "topic": ""}]}

Summary:
$summaryJson

Respond with ONLY the JSON.''';
  }

  /// Build an anonymized/short summary of the return for AI context.
  static String summarizeReturn(TaxReturnData d, Map<String, double> resultLines,
      {required bool anonymize}) {
    final m = <String, dynamic>{
      'taxYear': d.taxYear,
      'filingStatus': d.filingStatus.name,
      'w2Count': d.w2s.length,
      'wages': d.w2s.fold<double>(0, (a, w) => a + w.wages),
      'federalWithholding': d.w2s.fold<double>(0, (a, w) => a + w.federalWithholding),
      'selfEmploymentNet': d.selfEmployment.fold<double>(0, (a, s) => a + s.netProfit),
      'interest': d.interest.fold<double>(0, (a, i) => a + i.taxableInterest),
      'dividends': d.dividends.fold<double>(0, (a, x) => a + x.ordinaryDividends),
      'capitalGainsEntries': d.capitalGains.length,
      'dependents': d.dependents.length,
      'itemizedEntered': d.itemized.mortgageInterest > 0 ||
          d.itemized.saltTaxes > 0 ||
          d.itemized.charitableCash > 0,
      'ira': d.adjustments.iraContributions,
      'studentLoanInterest': d.adjustments.studentLoanInterest,
      'hasOvertime': d.w2s.any((w) => w.qualifiedOvertime > 0),
      'hasTips': d.w2s.any((w) => w.qualifiedTips > 0),
      'result': resultLines,
    };
    if (!anonymize) {
      m['firstNameInitial'] =
          d.taxpayer.firstName.isEmpty ? '' : d.taxpayer.firstName[0];
    }
    return jsonEncode(m);
  }
}
