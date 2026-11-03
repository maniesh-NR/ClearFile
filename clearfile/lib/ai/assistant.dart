import '../models/tax_return.dart';
import '../tax/results.dart';
import '../tax/review_rules.dart';
import '../util/money.dart';
import 'cascade.dart';
import 'providers.dart';
import 'settings.dart';

/// High-level assistant behaviour: prompts, return context and the AI review
/// pass. The raw model calls happen in [AiCascade].
class ClearFileAssistant {
  ClearFileAssistant(this.cascade);

  final AiCascade cascade;

  static const String _persona = '''
You are ClearFile Assist, the built-in assistant of ClearFile - a community
tax-preparation PROTOTYPE covering a simplified 2025 US federal return.
ClearFile is demonstration software, is not IRS-authorized, and cannot e-file.

Rules you must follow in every reply:
- Write in plain language at roughly an 8th-grade reading level, in the same
  language the user writes in.
- Ground statements about US federal tax rules in the 2025 tax year and cite
  the IRS source you rely on (for example "IRS Pub 17" or "Form 1040
  instructions") whenever you state a rule, threshold, limit or deadline.
- Use figures from the RETURN CONTEXT section when it is present; never
  invent numbers for the user's situation. If you are unsure, say so.
- Do not promise refunds, do not claim anything was filed, and remind the
  user that ClearFile is a demo when they talk about filing for real.
- Prefer short paragraphs and one-line bullet points. Stay under ~250 words
  unless the user asks for more detail.''';

  /// Builds the system prompt, optionally including non-identifying return
  /// figures the user agreed to share with their own AI provider.
  String systemPromptFor(TaxReturnData r, TaxResult? result, AiSettings s) {
    if (!s.sendReturnContext || result == null) return _persona;
    final buffer = StringBuffer(_persona);
    buffer.write('\n\nRETURN CONTEXT (2025 demo return, use these figures):\n');
    buffer.write('- Filing status: ${r.filingStatus.label}\n');
    buffer.write('- Total income: ${formatMoney(result.totalIncome)}\n');
    buffer.write('- AGI: ${formatMoney(result.agi)}\n');
    buffer.write('- Deduction used: ${formatMoney(result.deductionUsed)} '
        '(${result.deductionMethodUsed.name})\n');
    buffer.write('- Taxable income: ${formatMoney(result.taxableIncome)}\n');
    buffer.write('- Total tax: ${formatMoney(result.totalTax)}\n');
    if (result.refund > 0) {
      buffer.write('- Refund so far: ${formatMoney(result.refund)}\n');
    }
    if (result.amountOwed > 0) {
      buffer.write('- Balance due so far: ${formatMoney(result.amountOwed)}\n');
    }
    buffer.write('- Qualifying children: ${result.qualifyingChildren}\n');
    buffer.write(
        '- Itemized components: SALT ${formatMoney(result.saltAllowed)} of '
        '${formatMoney(result.saltPaid)} paid (cap ${formatMoney(result.saltCap)}), '
        'mortgage interest ${formatMoney(r.mortgageInterest)}, charity '
        '${formatMoney(r.charitableCash + r.charitableNonCash)}\n');
    if (r.studentLoanInterest > 0) {
      buffer.write(
          '- Student loan interest paid: ${formatMoney(r.studentLoanInterest)}\n');
    }
    if (r.taxpayer65OrOlder || r.spouse65OrOlder) {
      buffer.write('- At least one taxpayer is 65 or older\n');
    }
    return buffer.toString();
  }

  /// Sends a conversation. [returnData]/[result] attach context when present
  /// and allowed by settings.
  Future<CascadeResult> sendMessage({
    required AiSettings settings,
    required List<ChatTurn> conversation,
    TaxReturnData? returnData,
    TaxResult? result,
  }) {
    final system = returnData == null
        ? _persona
        : systemPromptFor(returnData, result, settings);
    return cascade.complete(
      settings: settings,
      system: system,
      conversation: conversation,
    );
  }

  /// A plain-language review request covering the whole return.
  String buildReviewPrompt(
    TaxReturnData r,
    TaxResult result,
    List<ReviewFinding> deterministicFindings,
  ) {
    final checkedTitles =
        deterministicFindings.map((f) => '- ${f.title}').join('\n');
    final summary = <String, dynamic>{
      'filingStatus': r.filingStatus.name,
      'w2s': r.w2s
          .map((w) => {
                'employer': w.employer,
                'box1': w.wages,
                'box2': w.withholding,
              })
          .toList(),
      'interestIncome': r.interestIncome,
      'ordinaryDividends': r.ordinaryDividends,
      'qualifiedDividends': r.qualifiedDividends,
      'longTermCapitalGains': r.longTermCapitalGains,
      'otherIncome': r.otherIncome,
      'studentLoanInterest': r.studentLoanInterest,
      'deductionMethod': r.deductionMethod.name,
      'stateLocalTaxes': r.stateLocalIncomeOrSalesTax,
      'realEstateTaxes': r.realEstateTax,
      'mortgageInterest': r.mortgageInterest,
      'charitableCash': r.charitableCash,
      'charitableNonCash': r.charitableNonCash,
      'estimatedPayments': r.estimatedPayments,
      'dependents': r.dependents
          .map((d) => {
                'name': d.name,
                'age': d.age,
                'qualifyingChild': d.qualifyingChild,
                'otherDependentCredit': d.otherDependentCredit,
              })
          .toList(),
      'computed': {
        'agi': result.agi,
        'taxableIncome': result.taxableIncome,
        'totalTax': result.totalTax,
        'refund': result.refund,
        'amountOwed': result.amountOwed,
      },
    };
    return '''
Please review my 2025 demo return summary below and reply with a short
plain-language checklist:
1. Anything missing or inconsistent that could change my refund or balance.
2. Two or three specific numbers I should double-check against my W-2s or
   1098-E/1099s.
3. One line about anything I might be over-paying or leaving on the table.
Keep every item to a single line. Do not restate the summary.

The app already flagged these deterministically (do not repeat them):
$checkedTitles

Return summary (JSON):
$summary''';
  }

  /// Pre-fills a question when the user taps "Ask about this field".
  String buildFieldQuestion(String fieldTitle, String fieldValue) =>
      'About the "$fieldTitle" field (currently '
      '"${fieldValue.isEmpty ? "empty" : fieldValue}"): '
      'what is this for, where do I find the number, and does it usually '
      'affect my refund? Please cite the IRS source.';

  /// Pre-fills the first-time setup message.
  String get welcomeMessage => '''
Hi! I'm ClearFile Assist. I can explain any field in plain language, answer
"can I deduct X?" questions with IRS citations, and review your return for
things that look off.

I run on YOUR free API key - either Google AI Studio or OpenRouter - and I try
the strongest free model first, automatically dropping to the next one if a
model is busy or hits its free limit.

Set me up from Settings > AI assistant (takes about two minutes).''';
}
