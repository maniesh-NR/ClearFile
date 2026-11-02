/// AI provider chain: Google AI Studio (Gemini) first, then Mistral.
///
/// The user supplies their own free API keys (see Settings screen and
/// docs/AI_SETUP.md). The chain tries the highest-performance free model
/// first and automatically falls to the next entry when a key is missing,
/// the model is inaccessible (401/403/404), a free-tier limit is hit (429),
/// or the provider errors (5xx). No data leaves the device except the
/// explicit AI requests the user triggers; keys are stored only locally.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

enum AiProvider { google, mistral }

class ModelEntry {
  final AiProvider provider;
  final String modelId;
  final String label;
  final String freeTierNote;
  bool enabled;

  ModelEntry({
    required this.provider,
    required this.modelId,
    required this.label,
    required this.freeTierNote,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'modelId': modelId,
        'label': label,
        'freeTierNote': freeTierNote,
        'enabled': enabled,
      };

  static ModelEntry fromJson(Map<String, dynamic> j) => ModelEntry(
        provider: AiProvider.values.firstWhere((e) => e.name == j['provider'],
            orElse: () => AiProvider.google),
        modelId: j['modelId'] as String? ?? '',
        label: j['label'] as String? ?? '',
        freeTierNote: j['freeTierNote'] as String? ?? '',
        enabled: j['enabled'] as bool? ?? true,
      );
}

/// Default chain, ordered highest performance first. Free-tier availability
/// changes over time; the fallback makes ordering safe and users can edit it.
List<ModelEntry> defaultChain() => [
      ModelEntry(
        provider: AiProvider.google,
        modelId: 'gemini-4-argon',
        label: 'Gemini 4 Argon (flagship)',
        freeTierNote: 'Free tier may be limited or billing-gated; skipped automatically if unavailable',
      ),
      ModelEntry(
        provider: AiProvider.google,
        modelId: 'gemini-3.8-flash',
        label: 'Gemini 3.8 Flash',
        freeTierNote: 'Stable Flash generation; usually available on the free tier',
      ),
      ModelEntry(
        provider: AiProvider.google,
        modelId: 'gemini-3.6-flash',
        label: 'Gemini 3.6 Flash',
        freeTierNote: 'Free tier with per-minute/day limits',
      ),
      ModelEntry(
        provider: AiProvider.google,
        modelId: 'gemini-2.5-flash',
        label: 'Gemini 2.5 Flash (legacy)',
        freeTierNote: 'Still served; access limited to accounts that used it before',
      ),
      ModelEntry(
        provider: AiProvider.mistral,
        modelId: 'mistral-large-latest',
        label: 'Mistral Large (latest)',
        freeTierNote: 'Free "Experiment" plan (~1 req/s, 500k tokens/min)',
      ),
      ModelEntry(
        provider: AiProvider.mistral,
        modelId: 'mistral-small-latest',
        label: 'Mistral Small (latest)',
        freeTierNote: 'Free "Experiment" plan; fastest of the free Mistral models',
      ),
    ];

class AiSettings {
  String googleApiKey;
  String mistralApiKey;
  List<ModelEntry> chain;
  bool shareReturnContext; // include (optionally anonymized) numbers in prompts
  bool anonymizePersonalData; // strip names/SSNs when sharing context
  bool autoSuggestDeductions;
  bool autoExtractPastedDocs;

  AiSettings({
    this.googleApiKey = '',
    this.mistralApiKey = '',
    List<ModelEntry>? chain,
    this.shareReturnContext = true,
    this.anonymizePersonalData = true,
    this.autoSuggestDeductions = true,
    this.autoExtractPastedDocs = true,
  }) : chain = chain ?? defaultChain();

  Map<String, dynamic> toJson() => {
        'googleApiKey': googleApiKey,
        'mistralApiKey': mistralApiKey,
        'chain': chain.map((e) => e.toJson()).toList(),
        'shareReturnContext': shareReturnContext,
        'anonymizePersonalData': anonymizePersonalData,
        'autoSuggestDeductions': autoSuggestDeductions,
        'autoExtractPastedDocs': autoExtractPastedDocs,
      };

  static AiSettings fromJson(Map<String, dynamic> j) => AiSettings(
        googleApiKey: j['googleApiKey'] as String? ?? '',
        mistralApiKey: j['mistralApiKey'] as String? ?? '',
        chain: (j['chain'] as List?)
                ?.map((e) => ModelEntry.fromJson((e as Map).cast<String, dynamic>()))
                .toList() ??
            defaultChain(),
        shareReturnContext: j['shareReturnContext'] as bool? ?? true,
        anonymizePersonalData: j['anonymizePersonalData'] as bool? ?? true,
        autoSuggestDeductions: j['autoSuggestDeductions'] as bool? ?? true,
        autoExtractPastedDocs: j['autoExtractPastedDocs'] as bool? ?? true,
      );
}

class AiAttempt {
  final String provider;
  final String model;
  final int? status;
  final String outcome; // 'ok' | 'skipped' | 'error'
  final String detail;

  const AiAttempt(this.provider, this.model, this.status, this.outcome, this.detail);
}

class AiReply {
  final String text;
  final String provider;
  final String model;
  final List<AiAttempt> attempts;

  const AiReply(this.text, this.provider, this.model, this.attempts);
}

class AiException implements Exception {
  final String message;
  final List<AiAttempt> attempts;
  AiException(this.message, this.attempts);
}

class AiClient {
  /// Sends a chat-style request through the fallback chain.
  ///
  /// [system] is the persona/instructions; [user] is the request body.
  Future<AiReply> send({
    required AiSettings settings,
    required String system,
    required String user,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final attempts = <AiAttempt>[];
    try {
      for (final entry in settings.chain) {
        if (!entry.enabled) continue;
        final key = entry.provider == AiProvider.google
            ? settings.googleApiKey
            : settings.mistralApiKey;
        if (key.isEmpty) {
          attempts.add(AiAttempt(entry.provider.name, entry.modelId, null, 'skipped',
              'no API key configured'));
          continue;
        }
        try {
          final text = await _call(c, entry, key, system, user);
          attempts.add(AiAttempt(entry.provider.name, entry.modelId, 200, 'ok', ''));
          return AiReply(text, entry.provider.name, entry.modelId, attempts);
        } on AiHttpError catch (e) {
          attempts.add(AiAttempt(entry.provider.name, entry.modelId, e.status,
              e.retryable ? 'skipped' : 'error', e.body));
          if (!e.retryable && e.status != 400 && e.status != 404) {
            // Non-retryable, non-model-specific problem: keep trying chain anyway.
          }
        } catch (e) {
          attempts.add(AiAttempt(entry.provider.name, entry.modelId, null, 'error', e.toString()));
        }
      }
      throw AiException('all-failed', attempts);
    } finally {
      if (client == null) c.close();
    }
  }

  Future<String> _call(
      http.Client c, ModelEntry entry, String key, String system, String user) async {
    if (entry.provider == AiProvider.google) {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/${entry.modelId}:generateContent');
      final body = jsonEncode({
        'systemInstruction': {'parts': [
          {'text': system}
        ]},
        'contents': [
          {'role': 'user', 'parts': [
            {'text': user}
          ]}
        ],
        'generationConfig': {'temperature': 0.2},
      });
      final resp = await c
          .post(url.replace(queryParameters: {'key': key}),
              headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 90));
      if (resp.statusCode != 200) {
        throw AiHttpError(resp.statusCode, resp.body);
      }
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      final candidates = j['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw AiHttpError(200, 'empty response (blocked or filtered)');
      }
      final content = (candidates.first as Map)['content'] as Map;
      final parts = content['parts'] as List;
      final sb = StringBuffer();
      for (final part in parts) {
        sb.write((part as Map)['text'] ?? '');
      }
      return sb.toString();
    } else {
      final url = Uri.parse('https://api.mistral.ai/v1/chat/completions');
      final body = jsonEncode({
        'model': entry.modelId,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
        'temperature': 0.2,
      });
      final resp = await c
          .post(url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $key',
              },
              body: body)
          .timeout(const Duration(seconds: 90));
      if (resp.statusCode != 200) {
        throw AiHttpError(resp.statusCode, resp.body);
      }
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = j['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw AiHttpError(200, 'empty response');
      }
      final msg = (choices.first as Map)['message'] as Map;
      return msg['content']?.toString() ?? '';
    }
  }

  /// Quick connectivity test used by the Settings screen.
  Future<AiReply> testChain(AiSettings settings) {
    return send(settings: settings, system: 'Reply with the single word: OK', user: 'ping');
  }
}

class AiHttpError implements Exception {
  final int status;
  final String body;
  AiHttpError(this.status, this.body);

  /// Skip to the next chain entry on: missing key (401), forbidden (403),
  /// unknown model (404), quota/limits (429), server trouble (>=500),
  /// and bad requests that usually mean "model not available to you" (400).
  bool get retryable =>
      status == 400 || status == 401 || status == 403 || status == 404 || status == 429 || status >= 500;
}
