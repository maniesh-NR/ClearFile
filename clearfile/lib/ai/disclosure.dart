// SPDX-License-Identifier: GPL-3.0-only
import 'settings.dart';

/// Single source of truth for what the AI assistant actually does with data
/// (Stage 5, D12). Every privacy-facing surface (Welcome footer, Settings
/// privacy section) renders this text; `privacy_test.dart` pins the load-
/// bearing facts so the copy cannot drift from the behavior:
///
/// - keys are stored in PLAINTEXT JSON in [aiSettingsFileName] inside the
///   app's documents directory — named file and format, in-app (D12);
/// - keys travel ONLY as the `x-goog-api-key` (Google) and `Authorization`
///   (OpenRouter) headers directly to the provider endpoints;
/// - return figures are sent only when the Privacy switch is on, and the
///   review button sends the same de-identified figures;
/// - chat text the user types goes to the chosen provider.
const String aiPrivacyDisclosure =
    'When the AI assistant is enabled, ClearFile sends requests directly to '
    'the provider endpoints you chose (generativelanguage.googleapis.com or '
    'openrouter.ai). Your API keys are stored in PLAINTEXT JSON in the file '
    '$aiSettingsFileName in this app\'s documents directory, and travel only '
    'as the x-goog-api-key / Authorization request headers to that provider - '
    'never anywhere else. What is sent: the system and chat text you type; '
    'de-identified return figures (never names, SSNs, or employer names) only '
    'when "Share anonymous return figures" is on or when you tap the review '
    'button. Nothing is sent until you ask a question.';
