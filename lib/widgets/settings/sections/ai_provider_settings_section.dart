import 'package:flutter/material.dart';
import '../../../providers/settings_state.dart';
import '../../../models/gemini_model.dart';
import '../../../models/ai_provider_config.dart';
import 'settings_section_title.dart';

/// AI 서비스 제공자 및 모델 설정 섹션
class AiProviderSettingsSection extends StatelessWidget {
  final SettingsState settings;
  final TextEditingController apiKeyController;
  final bool isEditingApiKey;
  final ValueChanged<bool> onToggleEditingApiKey;

  const AiProviderSettingsSection({
    super.key,
    required this.settings,
    required this.apiKeyController,
    required this.isEditingApiKey,
    required this.onToggleEditingApiKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionTitle('AI 모델 설정', icon: Icons.auto_awesome),
        const SizedBox(height: 8),

        // 1. AI Provider Select Box (Dropdown)
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'AI 서비스 제공자',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context)
                        .dividerColor
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AIProviderType>(
                    value: settings.aiProviderType,
                    isExpanded: true,
                    items: AIProviderType.values.map((provider) {
                      return DropdownMenuItem<AIProviderType>(
                        value: provider,
                        child: Row(
                          children: [
                            Icon(
                              provider == AIProviderType.gemini
                                  ? Icons.auto_awesome
                                  : provider == AIProviderType.openai
                                      ? Icons.psychology
                                      : provider == AIProviderType.claude
                                          ? Icons.wb_incandescent_outlined
                                          : Icons.terminal,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              provider.label,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newProvider) {
                      if (newProvider != null) {
                        settings.setAiProvider(newProvider.id);
                        apiKeyController.text =
                            settings.getApiKeyForProvider(newProvider);
                        onToggleEditingApiKey(false);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Custom Base URL & Model Name (When Custom is selected)
        if (settings.aiProviderType == AIProviderType.custom) ...[
          Row(
            children: [
              Expanded(
                flex: 6,
                child: TextField(
                  controller:
                      TextEditingController(text: settings.customBaseUrl),
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Base URL (Endpoint)',
                    hintText: 'http://localhost:11434/v1',
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: settings.setCustomBaseUrl,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: TextField(
                  controller:
                      TextEditingController(text: settings.customModelName),
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Model Name',
                    hintText: 'llama3',
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: settings.setCustomModelName,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // 3. API Key / Status
        _buildAiStatusSection(context),

        // 4. AI Model Settings (Shown when active or for Custom)
        if ((settings.currentApiKey.isNotEmpty ||
                settings.aiProviderType == AIProviderType.custom) &&
            !isEditingApiKey) ...[
          const SizedBox(height: 16),
          if (settings.aiProviderType != AIProviderType.custom)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('사용 모델',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  flex: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: settings.currentModelId,
                        isDense: true,
                        isExpanded: true,
                        items: AIModelInfo.getModelsForProvider(
                                settings.aiProviderType)
                            .map((m) => DropdownMenuItem(
                                  value: m.id,
                                  child: Text(
                                    '${m.label} (${m.shortLabel})',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ))
                            .toList(),
                        onChanged: (modelId) {
                          if (modelId == null) return;
                          switch (settings.aiProviderType) {
                            case AIProviderType.gemini:
                              settings.setGeminiModel(
                                  GeminiModel.fromId(modelId));
                              break;
                            case AIProviderType.openai:
                              settings.setOpenAiModelId(modelId);
                              break;
                            case AIProviderType.claude:
                              settings.setClaudeModelId(modelId);
                              break;
                            case AIProviderType.custom:
                              settings.setCustomModelName(modelId);
                              break;
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),

          // Thinking Level Selector
          if (settings.currentModelInfo.supportsThinking ||
              settings.aiProviderType == AIProviderType.gemini)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    '추론 강도 (Thinking)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ThinkingLevel>(
                        value: settings.thinkingLevel,
                        isDense: true,
                        isExpanded: true,
                        items: ThinkingLevel.values
                            .map((lvl) => DropdownMenuItem(
                                  value: lvl,
                                  child: Text(lvl.label,
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (lvl) {
                          if (lvl != null) {
                            settings.setThinkingLevel(lvl);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }

  Widget _buildAiStatusSection(BuildContext context) {
    final currentKey = settings.currentApiKey;
    final isCustom = settings.aiProviderType == AIProviderType.custom;

    if (currentKey.isEmpty && !isCustom || isEditingApiKey) {
      final hint = switch (settings.aiProviderType) {
        AIProviderType.gemini => 'Enter Google Gemini API Key',
        AIProviderType.openai => 'Enter OpenAI API Key (sk-...)',
        AIProviderType.claude => 'Enter Anthropic Claude API Key (sk-ant-...)',
        AIProviderType.custom => 'Enter Optional API Key for Custom/Ollama',
      };

      final guide = switch (settings.aiProviderType) {
        AIProviderType.gemini =>
          'Get your key from Google AI Studio (aistudio.google.com)',
        AIProviderType.openai =>
          'Get your key from OpenAI Platform (platform.openai.com)',
        AIProviderType.claude =>
          'Get your key from Anthropic Console (console.anthropic.com)',
        AIProviderType.custom =>
          'Local Ollama/Groq requires no key or custom authorization bearer',
      };

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: apiKeyController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              filled: true,
              fillColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  final val = apiKeyController.text.trim();
                  settings.updateApiKeyForProvider(settings.aiProviderType, val);
                  onToggleEditingApiKey(false);
                  apiKeyController.text = settings.currentApiKey;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('API Key Updated'),
                      duration: Duration(milliseconds: 1000)));
                },
              ),
            ),
            obscureText: true,
            onSubmitted: (value) {
              settings.updateApiKeyForProvider(
                  settings.aiProviderType, value.trim());
              onToggleEditingApiKey(false);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(guide,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        ],
      );
    } else {
      final label = switch (settings.aiProviderType) {
        AIProviderType.gemini => 'Google Gemini 활성화됨',
        AIProviderType.openai => 'OpenAI ChatGPT 활성화됨',
        AIProviderType.claude => 'Anthropic Claude 활성화됨',
        AIProviderType.custom => 'Custom Endpoint 활성화됨',
      };

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 16, color: Colors.green),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                onToggleEditingApiKey(true);
                apiKeyController.text = settings.currentApiKey;
              },
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                settings.clearCurrentApiKey();
                apiKeyController.clear();
                onToggleEditingApiKey(false);
              },
            ),
          ],
        ),
      );
    }
  }
}
