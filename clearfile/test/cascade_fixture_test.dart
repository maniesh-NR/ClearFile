// SPDX-License-Identifier: GPL-3.0-only
import 'dart:convert';
import 'dart:io';

import 'package:clearfile/ai/cascade.dart';
import 'package:clearfile/ai/providers.dart';
import 'package:clearfile/ai/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Shared recorded-fixture cascade e2e (Stage 5): the SAME synthetic
/// provider-response fixtures under `fixtures/ai/` also drive the web
/// ladder suite (`scripts/ai_cascade_fixture_test.mjs`) — one fixture set,
/// two runners, the D33/D34 shared-fixture discipline. Fixtures are
/// synthetic (see fixtures/ai/README.md); each carries its own `expect`
/// record and the runner asserts the observed behavior against it.
Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('../fixtures/ai/$name.json').readAsStringSync())
        as Map<String, dynamic>;

AiFailureKind _kind(String fixtureKind) => switch (fixtureKind) {
      'success' => AiFailureKind.other, // never compared for successes
      'rateLimit' => AiFailureKind.rateLimit,
      'quota' => AiFailureKind.quota,
      'auth' => AiFailureKind.auth,
      'modelNotFound' => AiFailureKind.modelNotFound,
      'network' => AiFailureKind.network,
      'server' => AiFailureKind.server,
      _ => AiFailureKind.other,
    };

/// Serves each request from the fixture mapped to the rung's model id.
(http.Client, List<http.Request> requests) _fixtureClient(
    Map<String, String> fixtureByModel) {
  final requests = <http.Request>[];
  final client = MockClient((request) async {
    requests.add(request);
    final url = request.url.toString();
    final modelInUrl =
        url.contains('generativelanguage') ? url.split('/models/').last.split(':').first : null;
    final modelInBody = url.contains('openrouter.ai')
        ? (jsonDecode(request.body) as Map<String, dynamic>)['model'] as String
        : null;
    final fixtureName = fixtureByModel[modelInUrl ?? modelInBody];
    if (fixtureName == null) {
      throw StateError('no fixture mapped for model ${modelInUrl ?? modelInBody}');
    }
    return http.Response.bytes(
        utf8.encode(jsonEncode(_fixture(fixtureName)['body'])),
        _fixture(fixtureName)['status'] as int,
        headers: {'content-type': 'application/json'});
  });
  return (client, requests);
}

AiSettings _chain(List<(String, AiProviderKind)> specs,
        {String googleKey = 'g-key', String orKey = 'or-key'}) =>
    AiSettings(
      googleApiKey: googleKey,
      openrouterApiKey: orKey,
      chain: specs
          .map((s) => AiModelSpec(provider: s.$2, modelId: s.$1, enabled: true))
          .toList(),
    );

void main() {
  test(
      'fixture walk 1: the six-rung default chain steps down to a served '
      'answer, carrying each fixture\'s expected failure kind', () async {
    final (client, requests) = _fixtureClient({
      'gemini-3.1-pro-preview': 'google_429_quota',
      'gemini-3.8-flash': 'google_401_invalid_key',
      'nvidia/nemotron-3.5-super-vl:free': 'hostile_error_429',
      'nvidia/nemotron-3-ultra-550b-a55b:free': 'openrouter_402_free_exhausted',
      'openrouter/free': 'openrouter_200_success',
    });
    final cascade = AiCascade(client: client);

    // The app's own default chain (suggestedModels): 3 Google rungs then 3
    // OpenRouter rungs. The 401 kills the Google provider, so rung 3 is
    // skipped without a request.
    final result = await cascade.complete(
      settings: _chain([
        ('gemini-3.1-pro-preview', AiProviderKind.google),
        ('gemini-3.8-flash', AiProviderKind.google),
        ('gemini-3.5-flash-lite', AiProviderKind.google),
        ('nvidia/nemotron-3.5-super-vl:free', AiProviderKind.openrouter),
        ('nvidia/nemotron-3-ultra-550b-a55b:free', AiProviderKind.openrouter),
        ('openrouter/free', AiProviderKind.openrouter),
      ]),
      system: 'sys',
      conversation: const [ChatTurn(fromUser: true, content: 'Q')],
    );

    expect(result.servedBy.modelId, 'openrouter/free');
    // NOTE (cross-side difference, recorded in fixtures/ai/README.md): the
    // Dart classifier sniffs the quota wording inside a 429 body
    // (AiFailureKind.quota — treated like rate limiting by the cascade),
    // while the web ladder maps any 429 flat to rate-limit. Both step down;
    // the kinds differ, so each runner asserts its own side's truth.
    expect(
        [for (final a in result.failedAttempts) a.failure],
        equals([
          AiFailureKind.quota, // google_429_quota (Dart-side classification)
          AiFailureKind.auth, // google_401_invalid_key (provider dies)
          AiFailureKind.rateLimit, // hostile_error_429
          AiFailureKind.quota, // openrouter_402_free_exhausted
        ]));

    // Outbound request shape, pinned from the fixtures' side of the contract:
    final googleCalls = requests
        .where((r) => r.url.toString().contains('generativelanguage'))
        .toList();
    expect(googleCalls, hasLength(2),
        reason: 'the auth-killed rung 3 must never be called');
    for (final r in googleCalls) {
      expect(r.url.queryParameters.containsKey('key'), isFalse);
      expect(r.headers['x-goog-api-key'], 'g-key');
    }
    final orCalls = requests
        .where((r) => r.url.toString().contains('openrouter.ai'))
        .toList();
    expect(orCalls, hasLength(3));
    for (final r in orCalls) {
      expect(r.headers['authorization'], 'Bearer or-key');
      expect(r.headers['x-title'], 'ClearFile');
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      expect((body['reasoning'] as Map)['enabled'], false);
    }
    // The hostile fixture's attacker text stayed inside the bounded snippet,
    // and the generic UI summary never carries it. Bound math: the clip caps
    // provider text at 200 chars + "..."; the worst prefix ("OpenRouter " +
    // the longest model id + " responded NNN: ") is ~65 chars → 268 max.
    expect(
        result.failedAttempts
            .map((a) => a.message)
            .every((m) => m.length <= 268),
        isTrue);
  });

  test(
      'fixture walk 2: geo-block (400) and provider 5xx fall through to the '
      'next rung, matching each fixture\'s recorded kind', () async {
    final (client, requests) = _fixtureClient({
      'gemini-3.1-pro-preview': 'google_400_geo_block',
      'nvidia/nemotron-3.5-super-vl:free': 'openrouter_503',
      'gemini-3.8-flash': 'google_200_success',
    });
    final cascade = AiCascade(client: client);

    final result = await cascade.complete(
      settings: _chain([
        ('gemini-3.1-pro-preview', AiProviderKind.google),
        ('nvidia/nemotron-3.5-super-vl:free', AiProviderKind.openrouter),
        ('gemini-3.8-flash', AiProviderKind.google),
      ]),
      system: 'sys',
      conversation: const [ChatTurn(fromUser: true, content: 'Q')],
    );

    expect(result.servedBy.modelId, 'gemini-3.8-flash');
    expect(result.failedAttempts, hasLength(2));
    expect(result.failedAttempts[0].failure,
        _kind(_fixture('google_400_geo_block')['expect']['kind'] as String));
    expect(result.failedAttempts[1].failure,
        _kind(_fixture('openrouter_503')['expect']['kind'] as String));
    // Same bound math as walk 1 (clip 200 + "..." + worst-case prefix).
    expect(
        result.failedAttempts.every((a) => a.message.length <= 268), isTrue);
    expect(requests, hasLength(3));
  });
}
