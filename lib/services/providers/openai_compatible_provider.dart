import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'ai_provider_interface.dart';

/// OpenAI 호환 REST API (DeepSeek, Ollama, Groq, OpenRouter, vLLM 등) 범용 SSE Provider
class OpenAICompatibleProvider implements AIProvider {
  final String _apiKey;
  final String _baseUrl;
  final String _modelName;
  final String? _systemPrompt;
  final String _providerLabel;
  final List<Map<String, String>> _messages = [];

  OpenAICompatibleProvider({
    required String apiKey,
    required String baseUrl,
    required String modelName,
    String? systemPrompt,
    String providerLabel = 'AI',
  })  : _apiKey = apiKey,
        _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _modelName = modelName,
        _systemPrompt = systemPrompt,
        _providerLabel = providerLabel;

  @override
  Stream<String> sendMessageStream(
      String userMessage, String contextStr) async* {
    final systemInstruction = _systemPrompt ??
        'You are a helpful Guitar Theory Tutor AI assistant. Analyze user questions based on provided Context. Use Markdown. IMPORTANT: You MUST answer strictly in Korean (한국어). Provide detailed explanations.';

    if (_messages.isEmpty) {
      _messages.add({'role': 'system', 'content': systemInstruction});
    }

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
      'messages': _messages,
      'stream': true,
    };

    final client = http.Client();
    try {
      final endpoint = _baseUrl.contains('/chat/completions')
          ? _baseUrl
          : '$_baseUrl/chat/completions';

      final request = http.Request('POST', Uri.parse(endpoint));
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      });
      request.body = jsonEncode(requestBody);

      final response = await client.send(request);

      if (response.statusCode != 200) {
        final errBody = await response.stream.bytesToString();
        debugPrint('$_providerLabel API Error: ${response.statusCode} - $errBody');
        if (response.statusCode == 401) {
          yield '⚠️ $_providerLabel 인증 실패: API Key가 올바르지 않습니다.';
        } else if (response.statusCode == 429) {
          yield '⚠️ $_providerLabel 사용량 한도 초과: 잔여 크레딧 또는 사용량을 확인해주세요.';
        } else {
          yield '⚠️ $_providerLabel 오류 (${response.statusCode}): $errBody';
        }
        return;
      }

      final accumulatedText = StringBuffer();

      // SSE 파싱
      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final trimmed = line.trim();
        if (trimmed.startsWith('data: ')) {
          final dataStr = trimmed.substring(6).trim();
          if (dataStr == '[DONE]') break;

          try {
            final json = jsonDecode(dataStr) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              if (delta != null) {
                // 1. 일반 응답 텍스트
                final content = delta['content'] as String?;
                if (content != null && content.isNotEmpty) {
                  accumulatedText.write(content);
                  yield content;
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
      debugPrint('$_providerLabel Exception: $e');
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
