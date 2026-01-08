import 'package:google_generative_ai/google_generative_ai.dart';
import 'ai_provider_interface.dart';
import '../../models/gemini_model.dart';

class GeminiProvider implements AIProvider {
  late final GenerativeModel _model;
  ChatSession? _session;
  final String? _systemPrompt;

  GeminiProvider(String apiKey, {String? modelName, String? systemPrompt})
      : _systemPrompt = systemPrompt {
    _model = GenerativeModel(
      model: modelName ?? GeminiModel.flashLite25.id,
      apiKey: apiKey,
    );
  }

  @override
  Stream<String> sendMessageStream(
      String userMessage, String contextStr) async* {
    final bool isFirstMessage = _session == null;
    if (_session == null) {
      _session = _model.startChat();
    }

    String fullPrompt = userMessage;

    if (contextStr.isNotEmpty) {
      if (isFirstMessage) {
        final instruction = _systemPrompt ??
            '''
You are a helpful Guitar Theory Tutor AI assistant in a Guitar Theory App.
Analyze the user's questions based on the provided [Current App Context].
Explain concepts clearly, suggest practice tips, or analyze the theory behind what they are seeing.
Use Markdown for formatting.

CRITICAL INSTRUCTION:
1. You MUST answer strictly in Korean (한국어). even if the user asks in English.
2. Provide detailed, comprehensive, and friendly explanations.
''';

        fullPrompt = '''
$instruction

[Current App Context]
$contextStr

[User Question]
$userMessage
''';
      } else {
        fullPrompt = '''
[Context Update]
$contextStr

[User Question]
$userMessage
''';
      }
    }

    final content = Content.text(fullPrompt);
    bool hasYielded = false;
    try {
      final responseStream = _session!.sendMessageStream(content);

      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          hasYielded = true;
          yield chunk.text!;
        }
      }
    } catch (e) {
      // SDK Version mismatch workaround:
      // If we received valid content but fail on the final metadata chunk (Unhandled format),
      // we ignore the error so the user sees the complete response.
      final msg = e.toString();
      if (hasYielded &&
          msg.contains('Unhandled format') &&
          msg.contains('role: model')) {
        return;
      }
      rethrow;
    }
  }

  @override
  void clearSession() {
    _session = null;
  }
}
