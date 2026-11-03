import 'dart:convert';

import 'package:clearfile/ai/cascade.dart';
import 'package:clearfile/ai/providers.dart';
import 'package:clearfile/ai/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _googleOk([String text = 'Answer']) => http.Response(
    jsonEncode({
      'candidates': [
        {
          'content': {'parts': [{'text': text}]}
        }
      ]
    }),
    200);

http.Response _openrouterOk([String text = 'Answer']) => http.Response(
    jsonEncode({
      'choices': [
        {
          'message': {'content': text}
        }
      ]
    }),
    200);

http.Response _status(int code, String message) => http.Response(
    jsonEncode({
      'error': {'code': code, 'message': message}
    }),
    code);

AiModelSpec _google(String model, {bool enabled = true}) =>
    AiModelSpec(provider: AiProviderKind.google, modelId: model, enabled: enabled);

AiModelSpec _openrouter(String model, {bool enabled = true}) =>
    AiModelSpec(provider: AiProviderKind.openrouter, modelId: model, enabled: enabled);

AiSettings _settings({
  String googleKey = 'g-key',
  String openrouterKey = '',
  List<AiModelSpec>? chain,
}) =>
    AiSettings(
      googleApiKey: googleKey,
      openrouterApiKey: openrouterKey,
      chain: chain ??
          [
            _google('gemini-3.1-pro-preview'),
            _google('gemini-3.8-flash'),
            _openrouter('nvidia/nemotron-3.5-super-vl:free'),
          ],
    );

void main() {
  test('falls to the next model on a 429 rate limit', () async {
    final urls = <String>[];
    final bodies = <String>[];
    var call = 0;
    final client = MockClient((request) async {
      urls.add(request.url.toString());
      bodies.add(request.body);
      call++;
      return call == 1
          ? _status(429, 'Resource has been exhausted')
          : _googleOk('Fallback answer');
    });
    final cascade = AiCascade(client: client);

    final result = await cascade.complete(
      settings: _settings(),
      system: 'You are a test.',
      conversation: const [
        ChatTurn(fromUser: true, content: 'Hi'),
        ChatTurn(fromUser: false, content: 'Hello'),
        ChatTurn(fromUser: true, content: 'What is the standard deduction?'),
      ],
    );

    expect(result.servedBy.modelId, 'gemini-3.8-flash');
    expect(result.text, 'Fallback answer');
    expect(result.failedAttempts, hasLength(1));
    expect(result.failedAttempts.first.model.modelId, 'gemini-3.1-pro-preview');
    expect(result.failedAttempts.first.failure, AiFailureKind.rateLimit);
    expect(urls.first, contains('gemini-3.1-pro-preview:generateContent'));

    // Multi-turn conversation and system prompt were forwarded.
    final sentBody = jsonDecode(bodies.first) as Map<String, dynamic>;
    expect((sentBody['contents'] as List), hasLength(3));
    expect(
        (sentBody['systemInstruction']['parts'] as List).first['text'],
        'You are a test.');
  });

  test('an auth failure skips the rest of that provider', () async {
    final urls = <String>[];
    var call = 0;
    final client = MockClient((request) async {
      urls.add(request.url.toString());
      call++;
      return call == 1
          ? _status(401, 'API key not valid. Please pass a valid API key.')
          : _openrouterOk('Via OpenRouter');
    });
    final cascade = AiCascade(client: client);

    final result = await cascade.complete(
      settings: _settings(openrouterKey: 'or-key'),
      system: 'sys',
      conversation: const [ChatTurn(fromUser: true, content: 'Q')],
    );

    expect(result.servedBy.modelId, 'nvidia/nemotron-3.5-super-vl:free');
    expect(result.servedBy.provider, AiProviderKind.openrouter);
    expect(result.failedAttempts, hasLength(1));
    expect(result.failedAttempts.first.failure, AiFailureKind.auth);
    // The second Google model must not have been called at all.
    expect(urls.where((u) => u.contains('gemini-3.8-flash')), isEmpty);
    expect(urls.last, contains('openrouter.ai'));
  });

  test('disabled models and key-less providers are skipped silently', () async {
    var call = 0;
    final client = MockClient((request) async {
      call++;
      return _googleOk('Direct answer');
    });
    final cascade = AiCascade(client: client);

    final result = await cascade.complete(
      settings: _settings(
        chain: [
          _google('gemini-3.1-pro-preview', enabled: false),
          _openrouter('nvidia/nemotron-3.5-super-vl:free'), // no key configured
          _google('gemini-3.8-flash'),
        ],
      ),
      system: 'sys',
      conversation: const [ChatTurn(fromUser: true, content: 'Q')],
    );

    expect(result.servedBy.modelId, 'gemini-3.8-flash');
    expect(result.failedAttempts, isEmpty);
    expect(call, 1);
  });

  test('a 404 model-not-found falls through', () async {
    var call = 0;
    final client = MockClient((request) async {
      call++;
      return call == 1
          ? _status(404,
              'models/gemini-3.1-pro-preview is not found for API version v1beta')
          : _googleOk('Next in line');
    });
    final cascade = AiCascade(client: client);

    final result = await cascade.complete(
      settings: _settings(),
      system: 'sys',
      conversation: const [ChatTurn(fromUser: true, content: 'Q')],
    );

    expect(result.failedAttempts.first.failure, AiFailureKind.modelNotFound);
    expect(result.text, 'Next in line');
  });

  test('throws when every model fails, reporting each attempt', () async {
    var call = 0;
    final client = MockClient((request) async {
      call++;
      return call == 1
          ? _status(429, 'Rate limited')
          : _status(503, 'Backend overloaded');
    });
    final cascade = AiCascade(client: client);

    await expectLater(
      cascade.complete(
        settings: _settings(chain: [
          _google('gemini-3.1-pro-preview'),
          _google('gemini-3.8-flash'),
        ]),
        system: 'sys',
        conversation: const [ChatTurn(fromUser: true, content: 'Q')],
      ),
      throwsA(isA<AiCascadeException>()
          .having((e) => e.attempts.length, 'count', 2)
          .having(
              (e) => e.attempts.last.failure, 'last failure', AiFailureKind.server)),
    );
  });

  test('settings survive a JSON roundtrip', () {
    final original = AiSettings(
      assistantEnabled: true,
      googleApiKey: 'g',
      openrouterApiKey: 'or',
      sendReturnContext: false,
      chain: [
        _google('gemini-3.1-pro-preview'),
        _openrouter('nvidia/nemotron-3.5-super-vl:free', enabled: false),
      ],
    );
    final restored = AiSettings.fromJson(original.toJson());
    expect(restored.assistantEnabled, true);
    expect(restored.googleApiKey, 'g');
    expect(restored.openrouterApiKey, 'or');
    expect(restored.sendReturnContext, false);
    expect(restored.chain, original.chain);
  });

  test('default chain starts with the strongest free models', () {
    final settings = AiSettings();
    expect(settings.chain.first.modelId, 'gemini-3.1-pro-preview');
    expect(settings.chain.last.modelId, 'openrouter/free');
    expect(settings.chain, hasLength(6));
  });

  test('mistral entries from old settings files are dropped on load', () {
    final legacy = <String, dynamic>{
      'assistantEnabled': true,
      'googleApiKey': 'g',
      'mistralApiKey': 'stale',
      'openrouterApiKey': 'or',
      'sendReturnContext': true,
      'chain': [
        {
          'provider': 'mistral',
          'modelId': 'mistral-small-latest',
          'enabled': true,
        },
        {
          'provider': 'openrouter',
          'modelId': 'nvidia/nemotron-3.5-super-vl:free',
          'enabled': true,
        },
      ],
    };
    final restored = AiSettings.fromJson(legacy);
    expect(restored.chain, hasLength(1));
    expect(restored.chain.single.provider, AiProviderKind.openrouter);
  });
}
