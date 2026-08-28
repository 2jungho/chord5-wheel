import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guitar_theory_app/models/ai_provider_config.dart';
import 'package:guitar_theory_app/services/ai_service.dart';
import 'package:guitar_theory_app/providers/settings_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Multi-AI Provider Configuration & Model Info Tests', () {
    test('Provider preset models contain correct definitions', () {
      // Gemini
      expect(AIModelInfo.geminiModels.length, greaterThanOrEqualTo(4));
      expect(AIModelInfo.geminiModels.first.id, contains('gemini-3.7-flash'));
      expect(AIModelInfo.geminiModels.first.shortLabel, '3.7F');

      // OpenAI
      expect(AIModelInfo.openAiModels.length, greaterThanOrEqualTo(4));
      expect(AIModelInfo.openAiModels.any((m) => m.id == 'gpt-4o'), isTrue);

      // Claude
      expect(AIModelInfo.claudeModels.length, greaterThanOrEqualTo(3));
      expect(AIModelInfo.claudeModels.any((m) => m.id.contains('claude-3-7-sonnet')), isTrue);
    });

    test('SettingsState multi-provider keys and model selection logic', () async {
      final settings = SettingsState();

      // Default should be Gemini
      expect(settings.aiProviderType, AIProviderType.gemini);
      expect(settings.aiProvider, 'gemini');

      // Switch to Claude
      settings.setAiProvider('claude');
      expect(settings.aiProviderType, AIProviderType.claude);
      expect(settings.aiProvider, 'claude');
      expect(settings.currentModelId, 'claude-3-7-sonnet-20250219');

      // Set Claude API Key
      settings.setClaudeApiKey('sk-ant-test1234');
      expect(settings.claudeApiKey, 'sk-ant-test1234');
      expect(settings.currentApiKey, 'sk-ant-test1234');
      expect(settings.hasApiKey, isTrue);

      // Switch to Custom / Ollama
      settings.setAiProvider('custom');
      expect(settings.customBaseUrl, 'http://localhost:11434/v1');
      expect(settings.customModelName, 'llama3');
      expect(settings.currentModelId, 'llama3');
      expect(settings.hasApiKey, isTrue); // Custom does not strictly require an API key
    });

    test('AIService factory routing across all providers without throw', () {
      // 1. Gemini
      final geminiService = AIService(
        apiKey: 'test-key',
        provider: 'gemini',
        modelName: 'gemini-2.5-flash',
        systemPrompt: 'System',
      );
      expect(geminiService, isNotNull);

      // 2. OpenAI
      final openAiService = AIService(
        apiKey: 'test-key',
        provider: 'openai',
        modelName: 'gpt-4o',
        systemPrompt: 'System',
      );
      expect(openAiService, isNotNull);

      // 3. Claude
      final claudeService = AIService(
        apiKey: 'test-key',
        provider: 'claude',
        modelName: 'claude-3-7-sonnet-20250219',
        systemPrompt: 'System',
      );
      expect(claudeService, isNotNull);

      // 4. Custom
      final customService = AIService(
        apiKey: 'test-key',
        provider: 'custom',
        modelName: 'llama3:latest',
        customBaseUrl: 'http://localhost:11434/v1',
        systemPrompt: 'System',
      );
      expect(customService, isNotNull);
    });
  });
}
