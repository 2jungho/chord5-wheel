abstract class AIProvider {
  /// Sends a message and returns a stream of response chunks
  Stream<String> sendMessageStream(String userMessage, String contextStr);

  /// Clears the current session or history
  void clearSession();
}
