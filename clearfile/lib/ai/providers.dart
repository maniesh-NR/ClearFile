import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Why a single model call failed. The cascade uses this to decide whether
/// to try the next model in the chain.
enum AiFailureKind {
  /// HTTP 429 or an explicit rate-limit message.
  rateLimit,

  /// Free-tier quota exhausted (treated like rate limiting).
  quota,

  /// The API key was rejected. The rest of that provider is skipped.
  auth,

  /// The model id no longer exists (404) - common as lineups change.
  modelNotFound,

  /// Timeout or connection failure.
  network,

  /// Provider-side 5xx.
  server,

  /// Anything else.
  other,
}

/// Thrown by the transports; consumed by the cascade.
class AiCallException implements Exception {
  AiCallException(this.kind, this.message, [this.status]);

  final AiFailureKind kind;
  final String message;
  final int? status;

  @override
  String toString() => 'AiCallException($kind, $message)';
}

/// One turn of an ongoing conversation.
class ChatTurn {
  const ChatTurn({required this.fromUser, required this.content});

  final bool fromUser;
  final String content;
}

const Duration defaultAiTimeout = Duration(seconds: 90);

/// Calls one Google AI Studio (Generative Language API) model.
Future<String> callGoogleModel(
  http.Client client, {
  required String apiKey,
  required String model,
  required String system,
  required List<ChatTurn> conversation,
  Duration timeout = defaultAiTimeout,
  double temperature = 0.2,
  int maxOutputTokens = 1024,
}) async {
  final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
  final body = <String, dynamic>{
    'contents': conversation
        .map((t) => {
              'role': t.fromUser ? 'user' : 'model',
              'parts': [
                {'text': t.content}
              ],
            })
        .toList(),
    'systemInstruction': {
      'parts': [
        {'text': system}
      ],
    },
    'generationConfig': {
      'temperature': temperature,
      'maxOutputTokens': maxOutputTokens,
    },
  };

  final http.Response response;
  try {
    response = await client
        .post(uri, headers: {'content-type': 'application/json'},
            body: jsonEncode(body))
        .timeout(timeout);
  } on TimeoutException {
    throw AiCallException(AiFailureKind.network, '$model timed out');
  } on SocketException catch (e) {
    throw AiCallException(AiFailureKind.network, e.message);
  } on http.ClientException catch (e) {
    throw AiCallException(AiFailureKind.network, e.message);
  }

  if (response.statusCode >= 200 && response.statusCode < 300) {
    return _extractGoogleText(response, model);
  }
  throw _httpError('Google', model, response);
}

String _extractGoogleText(http.Response response, String model) {
  final data = jsonDecode(utf8.decode(response.bodyBytes));
  if (data is! Map) {
    throw AiCallException(AiFailureKind.other, '$model returned no JSON');
  }
  final candidates = data['candidates'];
  if (candidates is List && candidates.isNotEmpty) {
    final first = candidates.first;
    if (first is Map) {
      final content = first['content'];
      if (content is Map) {
        final parts = content['parts'];
        if (parts is List) {
          final text = parts
              .whereType<Map>()
              .map((p) => p['text'])
              .whereType<String>()
              .join('');
          if (text.trim().isNotEmpty) return text;
        }
      }
      // Content was blocked (e.g. safety filter) rather than failing.
      final finish = first['finishReason'];
      throw AiCallException(
          AiFailureKind.other, '$model returned no text (finishReason: $finish)');
    }
  }
  final feedback = data['promptFeedback'];
  throw AiCallException(
      AiFailureKind.other, '$model returned no text ($feedback)');
}

/// Calls one OpenRouter model (OpenAI-compatible chat completions).
///
/// OpenRouter's free-tier models cover the fallback rungs since Mistral's
/// free direct-inference tier ended on 2026-09-21. Native clients do not
/// face CORS restrictions, so the call is a plain HTTPS POST.
Future<String> callOpenrouterModel(
  http.Client client, {
  required String apiKey,
  required String model,
  required String system,
  required List<ChatTurn> conversation,
  Duration timeout = defaultAiTimeout,
  double temperature = 0.2,
  int maxTokens = 1024,
}) async {
  final uri = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
  final messages = <Map<String, String>>[
    {'role': 'system', 'content': system},
    for (final turn in conversation)
      {
        'role': turn.fromUser ? 'user' : 'assistant',
        'content': turn.content,
      },
  ];
  final body = <String, dynamic>{
    'model': model,
    'messages': messages,
    'temperature': temperature,
    'max_tokens': maxTokens,
    // Nemotron-family free models are reasoning models whose thinking
    // tokens count against max_tokens and can starve the visible content;
    // ClearFile's tasks need transcription and JSON, not deliberation.
    'reasoning': {'enabled': false},
  };

  final http.Response response;
  try {
    response = await client.post(uri,
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $apiKey',
          'X-Title': 'ClearFile',
        },
        body: jsonEncode(body));
  } on TimeoutException {
    throw AiCallException(AiFailureKind.network, '$model timed out');
  } on SocketException catch (e) {
    throw AiCallException(AiFailureKind.network, e.message);
  } on http.ClientException catch (e) {
    throw AiCallException(AiFailureKind.network, e.message);
  }

  if (response.statusCode >= 200 && response.statusCode < 300) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is Map) {
      final choices = data['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map) {
          final message = first['message'];
          if (message is Map) {
            final content = message['content'];
            if (content is String && content.trim().isNotEmpty) return content;
          }
        }
      }
    }
    throw AiCallException(AiFailureKind.other, '$model returned no text');
  }
  throw _httpError('OpenRouter', model, response);
}

AiCallException _httpError(
    String provider, String model, http.Response response) {
  var detail = '';
  try {
    final data = jsonDecode(response.body);
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      final msg = error['message'];
      if (msg != null) detail = msg.toString();
    } else if (data is Map && data['message'] != null) {
      detail = data['message'].toString();
    }
  } catch (_) {}
  if (detail.isEmpty) {
    detail = response.body.length > 200
        ? response.body.substring(0, 200)
        : response.body;
  }

  final lower = detail.toLowerCase();
  var kind = AiFailureKind.other;
  switch (response.statusCode) {
    case 429:
      kind = lower.contains('quota') ? AiFailureKind.quota : AiFailureKind.rateLimit;
    case 401:
    case 403:
      kind = AiFailureKind.auth;
    // OpenRouter: credits or the daily free-model allowance ran out.
    case 402:
      kind = AiFailureKind.quota;
    case 404:
      kind = AiFailureKind.modelNotFound;
    default:
      if (response.statusCode >= 500) {
        kind = AiFailureKind.server;
      } else if (response.statusCode == 400 &&
          lower.contains('location is not supported')) {
        // Google geo-blocks some regions before auth; the key may be fine.
        kind = AiFailureKind.other;
      } else if (response.statusCode == 400 &&
          (lower.contains('api key') || lower.contains('api_key'))) {
        kind = AiFailureKind.auth;
      } else if (response.statusCode == 400 && lower.contains('quota')) {
        kind = AiFailureKind.quota;
      }
  }
  return AiCallException(kind, '$provider $model responded '
      '${response.statusCode}: $detail', response.statusCode);
}
