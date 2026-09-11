import 'ai_provider_interface.dart';
import 'openai_compatible_provider.dart';

/// OpenAI API (Chat Completions SSE Streaming) Provider
///
/// Wraps [OpenAICompatibleProvider] with the official OpenAI API endpoint,
/// providing instance-isolated API key handling without static global state.
class OpenAIProvider implements AIProvider {
  final OpenAICompatibleProvider _underlying;

  OpenAIProvider(
    String apiKey, {
    String? modelName,
    String? systemPrompt,
  }) : _underlying = OpenAICompatibleProvider(
          apiKey: apiKey,
          baseUrl: 'https://api.openai.com/v1',
          modelName: modelName ?? 'gpt-4o',
          systemPrompt: systemPrompt,
          providerLabel: 'OpenAI',
        );

  @override
  Stream<String> sendMessageStream(String userMessage, String contextStr) {
    return _underlying.sendMessageStream(userMessage, contextStr);
  }

  @override
  void clearSession() {
    _underlying.clearSession();
  }
}
