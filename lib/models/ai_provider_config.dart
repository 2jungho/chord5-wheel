import 'gemini_model.dart';

/// 지원하는 AI 프로바이더 종류
enum AIProviderType {
  gemini('gemini', 'Google Gemini', 'assets/images/icons8-gemini.png'),
  openai('openai', 'OpenAI ChatGPT', 'assets/images/icons8-chatgpt.png'),
  claude('claude', 'Anthropic Claude', 'assets/images/icons8-gemini.png'),
  custom('custom', 'Custom (Ollama/Groq)', 'assets/images/icons8-gemini.png');

  final String id;
  final String label;
  final String iconAsset;

  const AIProviderType(this.id, this.label, this.iconAsset);

  static AIProviderType fromId(String id) {
    return AIProviderType.values.firstWhere(
      (e) => e.id.toLowerCase() == id.toLowerCase(),
      orElse: () => AIProviderType.gemini,
    );
  }
}

/// 개별 AI 모델 메타데이터
class AIModelInfo {
  final String id;
  final String label;
  final String shortLabel;
  final AIProviderType provider;
  final bool supportsThinking;
  final ThinkingLevel defaultThinking;

  const AIModelInfo({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.provider,
    this.supportsThinking = false,
    this.defaultThinking = ThinkingLevel.medium,
  });

  // --- 모델 프리셋 목록 ---

  // 1. Google Gemini
  static const List<AIModelInfo> geminiModels = [
    AIModelInfo(
      id: 'gemini-3.7-flash',
      label: 'Gemini 3.7 Flash',
      shortLabel: '3.7F',
      provider: AIProviderType.gemini,
      supportsThinking: true,
      defaultThinking: ThinkingLevel.high,
    ),
    AIModelInfo(
      id: 'gemini-3.6-flash',
      label: 'Gemini 3.6 Flash',
      shortLabel: '3.6F',
      provider: AIProviderType.gemini,
      supportsThinking: true,
      defaultThinking: ThinkingLevel.medium,
    ),
    AIModelInfo(
      id: 'gemini-3.5-flash',
      label: 'Gemini 3.5 Flash',
      shortLabel: '3.5F',
      provider: AIProviderType.gemini,
      supportsThinking: true,
      defaultThinking: ThinkingLevel.medium,
    ),
    AIModelInfo(
      id: 'gemini-3.5-flash-lite',
      label: 'Gemini 3.5 Flash Lite',
      shortLabel: '3.5FL',
      provider: AIProviderType.gemini,
      supportsThinking: true,
      defaultThinking: ThinkingLevel.low,
    ),
    AIModelInfo(
      id: 'gemini-3.1-pro-preview',
      label: 'Gemini 3.1 Pro',
      shortLabel: '3.1P',
      provider: AIProviderType.gemini,
      supportsThinking: true,
      defaultThinking: ThinkingLevel.low,
    ),
    AIModelInfo(
      id: 'gemini-2.5-flash',
      label: 'Gemini 2.5 Flash',
      shortLabel: '2.5F',
      provider: AIProviderType.gemini,
      supportsThinking: false,
      defaultThinking: ThinkingLevel.off,
    ),
  ];

  // 2. OpenAI ChatGPT
  static const List<AIModelInfo> openAiModels = [
    AIModelInfo(
      id: 'gpt-4o',
      label: 'GPT-4o (Omni)',
      shortLabel: '4o',
      provider: AIProviderType.openai,
    ),
    AIModelInfo(
      id: 'gpt-4o-mini',
      label: 'GPT-4o mini',
      shortLabel: '4o-m',
      provider: AIProviderType.openai,
    ),
    AIModelInfo(
      id: 'o3-mini',
      label: 'o3-mini (추론형)',
      shortLabel: 'o3-m',
      provider: AIProviderType.openai,
      supportsThinking: true,
      defaultThinking: ThinkingLevel.medium,
    ),
    AIModelInfo(
      id: 'o1',
      label: 'o1 (고성능 추론)',
      shortLabel: 'o1',
      provider: AIProviderType.openai,
      supportsThinking: true,
      defaultThinking: ThinkingLevel.high,
    ),
  ];

  // 3. Anthropic Claude
  static const List<AIModelInfo> claudeModels = [
    AIModelInfo(
      id: 'claude-3-7-sonnet-20250219',
      label: 'Claude 3.7 Sonnet',
      shortLabel: '3.7S',
      provider: AIProviderType.claude,
      supportsThinking: true,
      defaultThinking: ThinkingLevel.high,
    ),
    AIModelInfo(
      id: 'claude-3-5-sonnet-20241022',
      label: 'Claude 3.5 Sonnet',
      shortLabel: '3.5S',
      provider: AIProviderType.claude,
    ),
    AIModelInfo(
      id: 'claude-3-5-haiku-20241022',
      label: 'Claude 3.5 Haiku',
      shortLabel: '3.5H',
      provider: AIProviderType.claude,
    ),
  ];

  /// 프로바이더별 기본 모델 목록 반환
  static List<AIModelInfo> getModelsForProvider(AIProviderType provider) {
    switch (provider) {
      case AIProviderType.gemini:
        return geminiModels;
      case AIProviderType.openai:
        return openAiModels;
      case AIProviderType.claude:
        return claudeModels;
      case AIProviderType.custom:
        return [
          const AIModelInfo(
            id: 'custom-model',
            label: 'Custom Model',
            shortLabel: 'Custom',
            provider: AIProviderType.custom,
          ),
        ];
    }
  }

  /// 모델 ID로 AIModelInfo 검색 (기본값: Gemini 3.7 Flash)
  static AIModelInfo fromId(String id, [AIProviderType? fallbackProvider]) {
    final allModels = [
      ...geminiModels,
      ...openAiModels,
      ...claudeModels,
    ];

    return allModels.firstWhere(
      (m) => m.id == id,
      orElse: () {
        if (fallbackProvider != null) {
          final providerList = getModelsForProvider(fallbackProvider);
          if (providerList.isNotEmpty) return providerList.first;
        }
        return geminiModels.first;
      },
    );
  }
}
