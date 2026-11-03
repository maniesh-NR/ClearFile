import 'package:http/http.dart' as http;

import 'providers.dart';
import 'settings.dart';

/// One model that was tried and failed, with the reason.
class AiAttempt {
  const AiAttempt(this.model, this.failure, this.message);

  final AiModelSpec model;
  final AiFailureKind failure;
  final String message;

  String get shortReason => switch (failure) {
        AiFailureKind.rateLimit => 'rate limit',
        AiFailureKind.quota => 'quota exhausted',
        AiFailureKind.auth => 'API key rejected',
        AiFailureKind.modelNotFound => 'model not found',
        AiFailureKind.network => 'network error',
        AiFailureKind.server => 'provider error',
        AiFailureKind.other => 'failed',
      };
}

/// Successful outcome of a cascaded request.
class CascadeResult {
  const CascadeResult(this.text, this.servedBy, this.failedAttempts);

  /// The assistant reply.
  final String text;

  /// The model that actually answered.
  final AiModelSpec servedBy;

  /// Models tried before it, in order.
  final List<AiAttempt> failedAttempts;
}

/// Thrown when every enabled, key-backed model in the chain failed.
class AiCascadeException implements Exception {
  const AiCascadeException(this.attempts);

  final List<AiAttempt> attempts;

  @override
  String toString() =>
      'All models failed: ${attempts.map((a) => '${a.model.modelId} (${a.shortReason})').join('; ')}';
}

/// Executes a chat completion against the user's editable model chain.
///
/// Order of operations for each request:
///  1. Walk the chain top-to-bottom (highest-performance free model first).
///  2. Skip disabled models and providers with no API key.
///  3. On a failure, record the attempt and continue down the chain. An auth
///     failure marks the whole provider dead for this request.
///  4. The first model that answers wins; the reply records which model
///     served it and every model that was skipped over.
class AiCascade {
  AiCascade({http.Client? client, this.timeout = defaultAiTimeout})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  Future<CascadeResult> complete({
    required AiSettings settings,
    required String system,
    required List<ChatTurn> conversation,
    double temperature = 0.2,
    int maxTokens = 1024,
  }) async {
    final failures = <AiAttempt>[];
    final deadProviders = <AiProviderKind>{};

    for (final spec in settings.chain) {
      if (!spec.enabled) continue;
      if (deadProviders.contains(spec.provider)) continue;
      if (!settings.hasKeyFor(spec.provider)) continue;

      try {
        final text = switch (spec.provider) {
          AiProviderKind.google => await callGoogleModel(
              _client,
              apiKey: settings.googleApiKey.trim(),
              model: spec.modelId,
              system: system,
              conversation: conversation,
              timeout: timeout,
              temperature: temperature,
              maxOutputTokens: maxTokens,
            ),
          AiProviderKind.openrouter => await callOpenrouterModel(
              _client,
              apiKey: settings.openrouterApiKey.trim(),
              model: spec.modelId,
              system: system,
              conversation: conversation,
              timeout: timeout,
              temperature: temperature,
              maxTokens: maxTokens,
            ),
        };
        return CascadeResult(text, spec, List.unmodifiable(failures));
      } on AiCallException catch (e) {
        failures.add(AiAttempt(spec, e.kind, e.message));
        if (e.kind == AiFailureKind.auth) {
          deadProviders.add(spec.provider);
        }
      }
    }
    throw AiCascadeException(List.unmodifiable(failures));
  }
}
