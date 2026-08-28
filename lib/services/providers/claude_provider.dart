import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'ai_provider_interface.dart';
import '../../models/gemini_model.dart';

/// Anthropic Claude API (Messages API SSE Streaming) Provider
class ClaudeProvider implements AIProvider {
  final String _apiKey;
  final String _modelName;
  final String? _systemPrompt;
  final ThinkingLevel? _thinkingLevel;
  final List<Map<String, String>> _messages = [];

  ClaudeProvider(
    String apiKey, {
    String? modelName,
    String? systemPrompt,
    ThinkingLevel? thinkingLevel,
  })  : _apiKey = apiKey,
        _modelName = modelName ?? 'claude-3-7-sonnet-20250219',
        _systemPrompt = systemPrompt,
        _thinkingLevel = thinkingLevel;

  @override
  Stream<String> sendMessageStream(
      String userMessage, String contextStr) async* {
    final systemInstruction = _systemPrompt ??
        'You are a helpful Guitar Theory Tutor AI assistant. Analyze user questions based on provided Context. Use Markdown. IMPORTANT: You MUST answer strictly in Korean (한국어). Provide detailed explanations.';

    String fullUserMessage = userMessage;
    if (contextStr.isNotEmpty) {
      fullUserMessage = '''
[Context]
$contextStr

[Question]
$userMessage
''';
    }

    _messages.add({'role': 'user', 'content': fullUserMessage});

    final requestBody = <String, dynamic>{
      'model': _modelName,
      'max_tokens': 4096,
      'system': systemInstruction,
      'messages': _messages,
      'stream': true,
    };

    // Claude 3.7 Thinking 지원
    if (_thinkingLevel != null &&
        _thinkingLevel != ThinkingLevel.off &&
        _modelName.contains('claude-3-7')) {
      final budgetTokens = switch (_thinkingLevel!) {
        ThinkingLevel.high => 8000,
        ThinkingLevel.medium => 4000,
        ThinkingLevel.low => 2000,
        ThinkingLevel.off => 0,
      };
      if (budgetTokens > 0) {
        requestBody['thinking'] = {
          'type': 'enabled',
          'budget_tokens': budgetTokens,
        };
        requestBody['max_tokens'] = budgetTokens + 4096;
      }
    }

    final client = http.Client();
    try {
      final request = http.Request(
        'POST',
        Uri.parse('https://api.anthropic.com/v1/messages'),
      );
      request.headers.addAll({
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      });
      request.body = jsonEncode(requestBody);

      final response = await client.send(request);

      if (response.statusCode != 200) {
        final errBody = await response.stream.bytesToString();
        debugPrint('Claude API Error: ${response.statusCode} - $errBody');
        if (response.statusCode == 401) {
          yield '⚠️ Anthropic Claude 인증 실패: API Key가 올바르지 않습니다.';
        } else if (response.statusCode == 429) {
          yield '⚠️ Anthropic Claude 사용량 한도 초과: 크레딧 또는 사용량을 확인해주세요.';
        } else {
          yield '⚠️ Claude API 오류 (${response.statusCode}): $errBody';
        }
        return;
      }

      final accumulatedText = StringBuffer();

      // Parse SSE Stream
      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final trimmed = line.trim();
        if (trimmed.startsWith('data: ')) {
          final dataStr = trimmed.substring(6).trim();
          if (dataStr == '[DONE]') break;

          try {
            final json = jsonDecode(dataStr) as Map<String, dynamic>;
            final type = json['type'] as String?;

            if (type == 'content_block_delta') {
              final delta = json['delta'] as Map<String, dynamic>?;
              if (delta != null && delta['type'] == 'text_delta') {
                final text = delta['text'] as String? ?? '';
                if (text.isNotEmpty) {
                  accumulatedText.write(text);
                  yield text;
                }
              }
            }
          } catch (_) {}
        }
      }

      // Assistant 답변 히스토리 저장
      if (accumulatedText.isNotEmpty) {
        _messages.add({
          'role': 'assistant',
          'content': accumulatedText.toString(),
        });
      }
    } catch (e) {
      debugPrint('Claude Exception: $e');
      yield 'Error: $e';
    } finally {
      client.close();
    }
  }

  @override
  void clearSession() {
    _messages.clear();
  }
}
