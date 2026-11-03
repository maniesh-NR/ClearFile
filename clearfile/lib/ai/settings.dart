import 'dart:convert';
import 'dart:io';

import '../models/json_codec.dart';

/// Which provider a model in the fallback chain belongs to.
enum AiProviderKind { google, openrouter }

/// One entry in the editable model chain. The chain is tried top-to-bottom;
/// the first model that answers serves the request.
class AiModelSpec {
  const AiModelSpec({
    required this.provider,
    required this.modelId,
    this.enabled = true,
  });

  final AiProviderKind provider;
  final String modelId;
  final bool enabled;

  String get label => switch (provider) {
        AiProviderKind.google => '$modelId - Google AI Studio',
        AiProviderKind.openrouter => '$modelId - OpenRouter',
      };

  AiModelSpec copyWith({bool? enabled}) =>
      AiModelSpec(provider: provider, modelId: modelId, enabled: enabled ?? this.enabled);

  Map<String, dynamic> toJson() =>
      {'provider': provider.name, 'modelId': modelId, 'enabled': enabled};

  static AiModelSpec fromJson(Map<String, dynamic> json) => AiModelSpec(
        provider: json['provider'] == 'openrouter'
            ? AiProviderKind.openrouter
            : AiProviderKind.google,
        modelId: readString(json, 'modelId'),
        enabled: readBool(json, 'enabled', true),
      );

  @override
  bool operator ==(Object other) =>
      other is AiModelSpec &&
      other.provider == provider &&
      other.modelId == modelId &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(provider, modelId, enabled);
}

/// Suggested models shown in the "add model" sheet. Defaults reflect the
/// free tiers of Google AI Studio and OpenRouter as of 2026-11 (the
/// OpenRouter rungs were verified against the live free-model catalogue on
/// 2026-11-03: Nemotron 3.5 Super VL answered all task types fastest and most
/// faithfully; the 550B Nemotron 3 Ultra and OpenRouter's own free-pool
/// router serve as deep fallbacks). Model lineups change often, so every
/// entry stays editable in-app.
const List<AiModelSpec> suggestedModels = [
  AiModelSpec(provider: AiProviderKind.google, modelId: 'gemini-3.1-pro-preview'),
  AiModelSpec(provider: AiProviderKind.google, modelId: 'gemini-3.8-flash'),
  AiModelSpec(provider: AiProviderKind.google, modelId: 'gemini-3.5-flash-lite'),
  AiModelSpec(provider: AiProviderKind.openrouter, modelId: 'nvidia/nemotron-3.5-super-vl:free'),
  AiModelSpec(provider: AiProviderKind.openrouter, modelId: 'nvidia/nemotron-3-ultra-550b-a55b:free'),
  AiModelSpec(provider: AiProviderKind.openrouter, modelId: 'openrouter/free'),
];

/// User-held AI configuration. API keys are bring-your-own, stored only in
/// the app's private settings file on this device, and never sent anywhere
/// except directly to the chosen provider.
class AiSettings {
  AiSettings({
    this.assistantEnabled = false,
    this.googleApiKey = '',
    this.openrouterApiKey = '',
    List<AiModelSpec>? chain,
    this.sendReturnContext = true,
  }) : chain = chain ?? List<AiModelSpec>.from(suggestedModels);

  bool assistantEnabled;
  String googleApiKey;
  String openrouterApiKey;
  List<AiModelSpec> chain;

  /// Whether return figures may be included in the assistant prompt.
  bool sendReturnContext;

  bool get isConfigured =>
      googleApiKey.trim().isNotEmpty || openrouterApiKey.trim().isNotEmpty;

  bool hasKeyFor(AiProviderKind provider) => switch (provider) {
        AiProviderKind.google => googleApiKey.trim().isNotEmpty,
        AiProviderKind.openrouter => openrouterApiKey.trim().isNotEmpty,
      };

  Map<String, dynamic> toJson() => {
        'assistantEnabled': assistantEnabled,
        'googleApiKey': googleApiKey,
        'openrouterApiKey': openrouterApiKey,
        'sendReturnContext': sendReturnContext,
        'chain': chain.map((m) => m.toJson()).toList(),
      };

  static AiSettings fromJson(Map<String, dynamic> json) => AiSettings(
        assistantEnabled: readBool(json, 'assistantEnabled'),
        googleApiKey: readString(json, 'googleApiKey'),
        openrouterApiKey: readString(json, 'openrouterApiKey'),
        sendReturnContext: readBool(json, 'sendReturnContext', true),
        chain: (json['chain'] as List? ?? [])
            .whereType<Map>()
            // 'mistral' entries belong to a provider whose free tier ended
            // on 2026-09-21; drop them instead of misrouting to Google.
            .where((m) => m['provider'] != 'mistral')
            .map((m) => AiModelSpec.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );

  AiSettings clone() => AiSettings.fromJson(toJson());
}

/// Persists [AiSettings] as JSON in the app's private directory.
class AiSettingsStore {
  AiSettingsStore(this.file);

  final File file;
  AiSettings settings = AiSettings();

  Future<void> load() async {
    if (!await file.exists()) return;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) {
        settings = AiSettings.fromJson(decoded);
      }
    } catch (_) {
      // Corrupt settings fall back to defaults.
    }
  }

  Future<void> save() async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(settings.toJson()));
  }
}
