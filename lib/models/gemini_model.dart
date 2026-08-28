enum ThinkingLevel {
  high('high', 'High (심층 추론)'),
  medium('medium', 'Medium (균형 추론, Fast)'),
  low('low', 'Low (빠른 응답)'),
  off('off', 'Off (추론 끄기)');

  final String id;
  final String label;

  const ThinkingLevel(this.id, this.label);

  static ThinkingLevel fromId(String id) {
    return ThinkingLevel.values.firstWhere(
      (e) => e.id.toLowerCase() == id.toLowerCase(),
      orElse: () => ThinkingLevel.medium,
    );
  }
}

enum GeminiModel {
  flash37('gemini-3.7-flash', 'Gemini 3.7 Flash', ThinkingLevel.high),
  flash36('gemini-3.6-flash', 'Gemini 3.6 Flash', ThinkingLevel.medium),
  flash35('gemini-3.5-flash', 'Gemini 3.5 Flash', ThinkingLevel.medium),
  flash35Lite('gemini-3.5-flash-lite', 'Gemini 3.5 Flash Lite', ThinkingLevel.low),
  pro31('gemini-3.1-pro-preview', 'Gemini 3.1 Pro', ThinkingLevel.low),
  flash25('gemini-2.5-flash', 'Gemini 2.5 Flash', ThinkingLevel.off),
  pro25('gemini-2.5-pro', 'Gemini 2.5 Pro', ThinkingLevel.off),
  gemma4_31b('gemma-4-31b-it', 'Gemma 4 31B', ThinkingLevel.off);

  final String id;
  final String label;
  final ThinkingLevel defaultThinking;

  const GeminiModel(this.id, this.label, this.defaultThinking);

  /// UI 배지용 컴팩트 약어 라벨 (예: 3.7F, 3.5F, 3.5FL, 3.1P)
  String get shortLabel {
    return label
        .replaceFirst('Gemini ', '')
        .replaceFirst('Flash Lite', 'FL')
        .replaceFirst('Flash', 'F')
        .replaceFirst('Pro', 'P')
        .replaceAll(' ', '');
  }

  static GeminiModel fromId(String id) {
    if (id == 'gemini-3-flash-preview') return GeminiModel.flash37;
    if (id == 'gemini-2.5-flash-lite') return GeminiModel.flash35Lite;
    if (id == 'gemma-3-27b-it') return GeminiModel.gemma4_31b;

    return GeminiModel.values.firstWhere(
      (e) => e.id == id,
      orElse: () => GeminiModel.flash37,
    );
  }
}
