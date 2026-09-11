const String kDefaultGuitarTheorySystemPrompt =
    'You are a helpful Guitar Theory Tutor AI assistant. Analyze user questions based on provided Context. Use Markdown. IMPORTANT: You MUST answer strictly in Korean (한국어). Provide detailed explanations.';

/// Standard helper to wrap user message with context if present
String buildPromptWithContext(String userMessage, String contextStr) {
  if (contextStr.isEmpty) return userMessage;
  return '''
[Context]
$contextStr

[Question]
$userMessage
''';
}

abstract class AIProvider {
  /// Sends a message and returns a stream of response chunks
  Stream<String> sendMessageStream(String userMessage, String contextStr);

  /// Clears the current session or history
  void clearSession();
}
