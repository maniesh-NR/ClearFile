// SPDX-License-Identifier: GPL-3.0-only
import 'package:clearfile/ai/assistant.dart';
import 'package:clearfile/ai/cascade.dart';
import 'package:clearfile/ai/settings.dart';
import 'package:clearfile/models/dependent.dart';
import 'package:clearfile/models/tax_return.dart';
import 'package:clearfile/models/w2.dart';
import 'package:clearfile/tax/calculator.dart';
import 'package:clearfile/tax/review_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stage-0 gate privacy contract (ADV-LEGAL conditions 2/3, 2026-11-14):
///
/// 1. The AI review prompt is de-identified by construction — employer
///    strings and dependent names/ages never appear, whether or not return
///    sharing is on.
/// 2. `sendReturnContext` defaults to OFF (sharing figures is opt-in).
/// 3. The ambient chat system prompt carries figures only when sharing is
///    on — and never names.
void main() {
  final r = TaxReturnData(
    w2s: [
      W2Entry(employer: 'Acme Confidential Corp', wages: 52500, withholding: 6200),
    ],
    dependents: [
      Dependent(
          name: 'Secretia Childname',
          age: 9,
          relationship: 'Daughter',
          qualifyingChild: true),
    ],
  );
  final result = const TaxCalculator().compute(r);
  // No network happens in these prompt-building paths; the cascade is just
  // the constructor's required collaborator.
  final assistant = ClearFileAssistant(AiCascade());

  test('review prompt never contains employer or dependent names', () {
    final prompt = assistant.buildReviewPrompt(r, result, const []);
    expect(prompt.contains('Acme Confidential Corp'), isFalse,
        reason: 'employer name leaked into the review prompt');
    expect(prompt.contains('Secretia Childname'), isFalse,
        reason: 'dependent name leaked into the review prompt');
    expect(prompt.contains('Daughter'), isFalse,
        reason: 'dependent relationship leaked into the review prompt');
  });

  test('review prompt keeps de-identified counts and figures', () {
    final prompt = assistant.buildReviewPrompt(r, result, const []);
    expect(prompt.contains('w2Count'), isTrue);
    expect(prompt.contains('dependentCount'), isTrue);
    expect(prompt.contains('qualifyingChildCount'), isTrue);
  });

  test('return-figure sharing defaults to off', () {
    expect(AiSettings().sendReturnContext, isFalse,
        reason: 'sendReturnContext must default to false (opt-in sharing)');
    expect(
        AiSettings.fromJson(<String, dynamic>{}).sendReturnContext, isFalse,
        reason:
            'a settings file written before the field existed must read as off');
  });

  test('system prompt includes figures only when sharing is on', () {
    final off = AiSettings()..sendReturnContext = false;
    final on = AiSettings()..sendReturnContext = true;

    final pOff = assistant.systemPromptFor(r, result, off);
    expect(pOff.contains('AGI'), isFalse,
        reason: 'figures must not appear when sharing is off');
    expect(pOff.contains('Acme Confidential Corp'), isFalse);
    expect(pOff.contains('Secretia Childname'), isFalse);

    final pOn = assistant.systemPromptFor(r, result, on);
    expect(pOn.contains('AGI'), isTrue,
        reason: 'totals must appear when the user opted in');
    expect(pOn.contains('Acme Confidential Corp'), isFalse,
        reason: 'names must never appear in the system prompt');
    expect(pOn.contains('Secretia Childname'), isFalse);
  });

  test('findings carrying names never leak into the review prompt', () {
    // ADV-ENG Stage-1 finding 2: review-finding DETAILS interpolate employer
    // and dependent names (review_rules.dart). The review prompt embeds only
    // finding TITLES (static strings) — pin that contract so a future
    // "improvement" including f.detail cannot leak names silently.
    //
    // Fixture triggers both name-bearing findings: withholding > wages
    // (employer detail) and qualifying child aged 17+ (name detail).
    final leaky = TaxReturnData(
      w2s: [
        W2Entry(employer: 'Leaky Employer LLC', wages: 1000, withholding: 2000),
      ],
      dependents: [
        Dependent(
            name: 'Leaky Childname',
            age: 17,
            relationship: 'Son',
            qualifyingChild: true),
      ],
    );
    final leakyResult = const TaxCalculator().compute(leaky);
    final findings = runReview(leaky, leakyResult);
    // The fixture must actually trigger the name-bearing findings, else the
    // test proves nothing.
    expect(
        findings.any((f) => f.detail.contains('Leaky Employer LLC')), isTrue,
        reason: 'fixture must trigger the employer-name finding detail');
    expect(findings.any((f) => f.detail.contains('Leaky Childname')), isTrue,
        reason: 'fixture must trigger the dependent-name finding detail');

    final prompt =
        assistant.buildReviewPrompt(leaky, leakyResult, findings);
    expect(prompt.contains('Leaky Employer LLC'), isFalse,
        reason: 'employer name leaked into the review prompt via findings');
    expect(prompt.contains('Leaky Childname'), isFalse,
        reason: 'dependent name leaked into the review prompt via findings');
  });
}
