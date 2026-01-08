enum GeminiModel {
  flash3('gemini-3-flash-preview', 'Gemini 3.0 Flash'),
  flash25('gemini-2.5-flash', 'Gemini 2.5 Flash'),
  flashLite25('gemini-2.5-flash-lite', 'Gemini 2.5 Flash Lite'),
  gemma3_27b('gemma-3-27b-it', 'Gemma 3 27B');

  final String id;
  final String label;

  const GeminiModel(this.id, this.label);

  static GeminiModel fromId(String id) {
    return GeminiModel.values.firstWhere(
      (e) => e.id == id,
      orElse: () => GeminiModel.flashLite25,
    );
  }
}
