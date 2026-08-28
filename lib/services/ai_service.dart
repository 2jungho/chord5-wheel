import 'dart:convert';
import 'providers/ai_provider_interface.dart';
import 'providers/gemini_provider.dart';
import 'providers/openai_provider.dart';
import 'providers/claude_provider.dart';
import 'providers/openai_compatible_provider.dart';
import '../models/gemini_model.dart';

class AIService {
  late final AIProvider _provider;

  AIService({
    required String apiKey,
    required String provider,
    String? modelName,
    String? systemPrompt,
    ThinkingLevel? thinkingLevel,
    String? customBaseUrl,
  }) {
    switch (provider.toLowerCase()) {
      case 'gemini':
        _provider = GeminiProvider(
          apiKey.trim(),
          modelName: modelName ?? GeminiModel.flash37.id,
          systemPrompt: systemPrompt,
          thinkingLevel: thinkingLevel,
        );
        break;

      case 'openai':
        _provider = OpenAIProvider(
          apiKey.trim(),
          modelName: modelName ?? 'gpt-4o',
          systemPrompt: systemPrompt,
        );
        break;

      case 'claude':
        _provider = ClaudeProvider(
          apiKey.trim(),
          modelName: modelName ?? 'claude-3-7-sonnet-20250219',
          systemPrompt: systemPrompt,
          thinkingLevel: thinkingLevel,
        );
        break;

      case 'deepseek':
        _provider = OpenAICompatibleProvider(
          apiKey: apiKey.trim(),
          baseUrl: 'https://api.deepseek.com/v1',
          modelName: modelName ?? 'deepseek-chat',
          systemPrompt: systemPrompt,
          providerLabel: 'DeepSeek',
        );
        break;

      case 'custom':
        _provider = OpenAICompatibleProvider(
          apiKey: apiKey.trim().isNotEmpty ? apiKey.trim() : 'custom-key',
          baseUrl: (customBaseUrl != null && customBaseUrl.trim().isNotEmpty)
              ? customBaseUrl.trim()
              : 'http://localhost:11434/v1',
          modelName: modelName ?? 'llama3',
          systemPrompt: systemPrompt,
          providerLabel: 'Custom AI',
        );
        break;

      default:
        _provider = GeminiProvider(
          apiKey.trim(),
          modelName: modelName ?? GeminiModel.flash37.id,
          systemPrompt: systemPrompt,
          thinkingLevel: thinkingLevel,
        );
        break;
    }
  }

  /// Sends a message and returns a Stream of the response chunks.
  Stream<String> sendMessageStream(String userMessage,
      {Map<String, dynamic>? contextData}) {
    String contextStr = '';
    if (contextData != null && contextData.isNotEmpty) {
      contextStr = _formatContext(contextData);
    }
    return _provider.sendMessageStream(userMessage, contextStr);
  }

  String _formatContext(Map<String, dynamic> data) {
    return data.entries.map((e) => '- ${e.key}: ${e.value}').join('\n');
  }

  void clearSession() {
    _provider.clearSession();
  }

  /// Extracts a JSON object (Map) from the response string.
  /// Handles Markdown code blocks and extraneous text.
  static Map<String, dynamic> extractJson(String response) {
    try {
      final jsonString = _cleanJsonString(response);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException(
          'Failed to parse JSON object: $e\nOriginal: $response');
    }
  }

  /// Extracts a JSON list (List) from the response string.
  static List<dynamic> extractJsonList(String response) {
    try {
      final jsonString = _cleanJsonString(response);
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      throw FormatException(
          'Failed to parse JSON list: $e\nOriginal: $response');
    }
  }

  /// Removes Markdown code blocks (```json ... ```) and finds the first '{' or '['
  /// to the last '}' or ']'.
  static String _cleanJsonString(String raw) {
    String cleaned = raw.trim();

    // 1. Remove Markdown code blocks if present
    final codeBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = codeBlockRegex.firstMatch(cleaned);
    if (match != null) {
      cleaned = match.group(1)!.trim();
    }

    // 2. Find the first '{' or '[' and the last '}' or ']'
    final int firstBrace = cleaned.indexOf('{');
    final int firstBracket = cleaned.indexOf('[');

    int start = -1;
    int end = -1;

    // Determine if it looks like an object or a list
    bool isObject = false;

    if (firstBrace != -1 && (firstBracket == -1 || firstBrace < firstBracket)) {
      isObject = true;
      start = firstBrace;
    } else if (firstBracket != -1) {
      isObject = false;
      start = firstBracket;
    }

    if (start != -1) {
      if (isObject) {
        end = cleaned.lastIndexOf('}');
      } else {
        end = cleaned.lastIndexOf(']');
      }

      if (end != -1 && end > start) {
        return cleaned.substring(start, end + 1);
      }
    }

    // If no clear boundaries found, return original (might fail parsing)
    return cleaned;
  }
}
