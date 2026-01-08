import 'package:flutter/foundation.dart';
import 'package:dart_openai/dart_openai.dart';
import 'ai_provider_interface.dart';

class OpenAIProvider implements AIProvider {
  final List<OpenAIChatCompletionChoiceMessageModel> _history = [];
  final String? _systemPrompt;

  OpenAIProvider(String apiKey, {String? systemPrompt})
      : _systemPrompt = systemPrompt {
    OpenAI.apiKey = apiKey;
  }

  @override
  Stream<String> sendMessageStream(
      String userMessage, String contextStr) async* {
    // 1. Initialize System Message if history is empty
    if (_history.isEmpty) {
      final instruction = _systemPrompt ??
          'You are a helpful Guitar Theory Tutor AI assistant. Analyze user questions based on provided Context. Use Markdown. IMPORTANT: You MUST answer strictly in Korean (한국어). Provide detailed explanations.';
      _history.add(OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(instruction),
        ],
        role: OpenAIChatMessageRole.system,
      ));
    }

    // 2. Prepare User Message with Context
    String contentText = userMessage;
    if (contextStr.isNotEmpty) {
      contentText = '''
[Context]
$contextStr

[Question]
$userMessage
''';
    }

    _history.add(OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(contentText),
      ],
      role: OpenAIChatMessageRole.user,
    ));

    try {
      // Using gpt-4o-mini for speed and cost efficiency
      final stream = OpenAI.instance.chat.createStream(
        model: "gpt-4o-mini",
        messages: _history,
      );

      String accumulatedResponse = '';

      await for (final chunk in stream) {
        final contentList = chunk.choices.first.delta.content;
        if (contentList != null && contentList.isNotEmpty) {
          final text = contentList.map((e) => e?.text ?? '').join();
          accumulatedResponse += text;
          yield text;
        }
      }

      // 3. Save Assistant Response to History
      _history.add(OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
              accumulatedResponse),
        ],
        role: OpenAIChatMessageRole.assistant,
      ));
    } catch (e) {
      debugPrint('OpenAI Error: $e');
      final errStr = e.toString();
      if (errStr.contains('statusCode: 429')) {
        yield '⚠️ OpenAI 사용량 한도 초과 (Quota Exceeded)\n\nAPI 사용량이 한도를 초과했습니다. OpenAI 플랫폼에서 요금제를 확인하시거나, 무료로 사용 가능한 **Google Gemini**로 설정을 변경해주세요.';
      } else if (errStr.contains('statusCode: 401')) {
        yield '⚠️ 인증 실패 (Unauthorized)\n\nOpenAI API Key가 유효하지 않습니다. 설정에서 올바른 키를 입력했는지 확인해주세요.';
      } else {
        yield 'Error: $errStr';
      }
    }
  }

  @override
  void clearSession() {
    _history.clear();
  }
}
