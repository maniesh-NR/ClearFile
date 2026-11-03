import 'dart:convert';
import 'dart:io';

import 'models/json_codec.dart';

/// Which provider a model in the fallback chain belongs to.
enum AiProviderKind { google, mistral }

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
        AiProviderKind.mistral => '$modelId - Mistral',
      };

  AiModelSpec copyWith({bool? enabled}) =>
      AiModelSpec(provider: provider, modelId: modelId, enabled: enabled ?? this.enabled);

  Map<String, dynamic> toJson() =>
      {'provider': provider.name, 'modelId': modelId, 'enabled': enabled};

  static AiModelSpec fromJson(Map<String, dynamic> json) => AiModelSpec(
        provider: json['provider'] == 'mistral'
            ? AiProviderKind.mistral
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
/// free tiers of Google AI Studio and Mistral as of late 2026; because model
/// lineups change often, every entry stays editable in-app.
const List<AiModelSpec> suggestedModels = [
  AiModelSpec(provider: AiProviderKind.google, modelId: 'gemini-2.5-pro'),
  AiModelSpec(provider: AiProviderKind.google, modelId: 'gemini-2.5-flash'),
  AiModelSpec(provider: AiProviderKind.google, modelId: 'gemini-2.0-flash'),
  AiModelSpec(provider: AiProviderKind.mistral, modelId: 'mistral-small-latest'),
  AiModelSpec(provider: AiProviderKind.mistral, modelId: 'open-mistral-nemo'),
];

/// User-held AI configuration. API keys are bring-your-own, stored only in
/// the app's private settings file on this device, and never sent anywhere
/// except directly to the chosen provider.
class AiSettings {
  AiSettings({
    this.assistantEnabled = false,
    this.googleApiKey = '',
    this.mistralApiKey = '',
    List<AiModelSpec>? chain,
    this.sendReturnContext = true,
  }) : chain = chain ?? List<AiModelSpec>.from(suggestedModels);

  bool assistantEnabled;
  String googleApiKey;
  String mistralApiKey;
  List<AiModelSpec> chain;

  /// Whether return figures may be included in the assistant prompt.
  bool sendReturnContext;

  bool get isConfigured =>
      googleApiKey.trim().isNotEmpty || mistralApiKey.trim().isNotEmpty;

  bool hasKeyFor(AiProviderKind provider) => switch (provider) {
        AiProviderKind.google => googleApiKey.trim().isNotEmpty,
        AiProviderKind.mistral => mistralApiKey.trim().isNotEmpty,
      };

  Map<String, dynamic> toJson() => {
        'assistantEnabled': assistantEnabled,
        'googleApiKey': googleApiKey,
        'mistralApiKey': mistralApiKey,
        'sendReturnContext': sendReturnContext,
        'chain': chain.map((m) => m.toJson()).toList(),
      };

  static AiSettings fromJson(Map<String, dynamic> json) => AiSettings(
        assistantEnabled: readBool(json, 'assistantEnabled'),
        googleApiKey: readString(json, 'googleApiKey'),
        mistralApiKey: readString(json, 'mistralApiKey'),
        sendReturnContext: readBool(json, 'sendReturnContext', true),
        chain: (json['chain'] as List? ?? [])
            .whereType<Map>()
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
