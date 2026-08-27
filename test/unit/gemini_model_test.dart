import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/models/gemini_model.dart';

void main() {
  group('GeminiModel Tests', () {
    test('GeminiModel enum parsing and values', () {
      expect(GeminiModel.fromId('gemini-3.7-flash'), GeminiModel.flash37);
      expect(GeminiModel.fromId('gemini-3.6-flash'), GeminiModel.flash36);
      expect(GeminiModel.fromId('gemini-3.5-flash'), GeminiModel.flash35);
      expect(GeminiModel.fromId('gemini-3.5-flash-lite'), GeminiModel.flash35Lite);
      expect(GeminiModel.fromId('gemini-3.1-pro-preview'), GeminiModel.pro31);
      expect(GeminiModel.fromId('gemini-2.5-flash'), GeminiModel.flash25);
      expect(GeminiModel.fromId('gemini-2.5-pro'), GeminiModel.pro25);
      expect(GeminiModel.fromId('gemma-4-31b-it'), GeminiModel.gemma4_31b);

      // Legacy fallback mappings
      expect(GeminiModel.fromId('gemini-3-flash-preview'), GeminiModel.flash37);
      expect(GeminiModel.fromId('gemini-2.5-flash-lite'), GeminiModel.flash35Lite);
      expect(GeminiModel.fromId('gemma-3-27b-it'), GeminiModel.gemma4_31b);
      expect(GeminiModel.fromId('unknown-model'), GeminiModel.flash37);
    });

    test('GeminiModel labels and default thinking levels', () {
      for (final model in GeminiModel.values) {
        expect(model.label, isNotEmpty);
        expect(model.id, isNotEmpty);
        expect(model.defaultThinking, isNotNull);
      }

      expect(GeminiModel.flash37.defaultThinking, ThinkingLevel.high);
      expect(GeminiModel.flash36.defaultThinking, ThinkingLevel.medium);
      expect(GeminiModel.flash35.defaultThinking, ThinkingLevel.medium);
      expect(GeminiModel.flash35Lite.defaultThinking, ThinkingLevel.low);
      expect(GeminiModel.pro31.defaultThinking, ThinkingLevel.low);
    });

    test('ThinkingLevel enum parsing', () {
      expect(ThinkingLevel.fromId('high'), ThinkingLevel.high);
      expect(ThinkingLevel.fromId('medium'), ThinkingLevel.medium);
      expect(ThinkingLevel.fromId('low'), ThinkingLevel.low);
      expect(ThinkingLevel.fromId('off'), ThinkingLevel.off);

      // Fallback
      expect(ThinkingLevel.fromId('unknown'), ThinkingLevel.medium);

      expect(ThinkingLevel.high.id, 'high');
      expect(ThinkingLevel.medium.id, 'medium');
      expect(ThinkingLevel.low.id, 'low');
      expect(ThinkingLevel.off.id, 'off');
    });
  });
}
