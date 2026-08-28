import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_state.dart';
import '../../models/instrument_model.dart';
import '../../models/gemini_model.dart';
import '../../models/ai_provider_config.dart';
import '../../utils/app_theme.dart';
import '../common/dialogs/changelog_dialog.dart';


class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  late TextEditingController _apiKeyController;
  late TextEditingController _systemPromptController;
  bool _isEditingApiKey = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsState>();
    _apiKeyController = TextEditingController(text: settings.currentApiKey);
    _systemPromptController =
        TextEditingController(text: settings.systemPrompt);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  Widget _buildPersonaChip(
    BuildContext context,
    SettingsState settings,
    TextEditingController controller,
    String label,
    String promptText,
    IconData? icon,
  ) {
    final isSelected = settings.systemPrompt.trim() == promptText.trim();
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 14,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 4),
          ],
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          settings.setSystemPrompt(promptText);
          controller.text = promptText;
        }
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 320,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Row(
              children: [
                Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                Text(
                  '환경 설정 (Settings)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle(context, '일반 (GENERAL)'),
                _buildGeneralSettings(context),
                const SizedBox(height: 24),
                Divider(color: Theme.of(context).dividerColor),
                const SizedBox(height: 24),
                _buildSectionTitle(context, '악기 (INSTRUMENT)'),
                _buildInstrumentSettings(context),
                const SizedBox(height: 24),
                Divider(color: Theme.of(context).dividerColor),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'AI 모델 설정'),
                _buildAIModelSettings(context),
                const SizedBox(height: 24),
                Divider(color: Theme.of(context).dividerColor),
                const SizedBox(height: 24),
                _buildSectionTitle(context, '정보 (INFO)'),
                _buildInfoSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext context) {
    final settings = context.watch<SettingsState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Theme Preset Selection
        const Text('앱 테마 (Theme Palette)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 10),
        ...AppThemePreset.values.map((preset) {
          final isSelected = settings.themePreset == preset;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: InkWell(
              onTap: () => settings.setThemePreset(preset),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6)
                      : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: preset.primaryAccent,
                        border: Border.all(color: Colors.white70, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        preset.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, size: 16, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 18),



        // Master Volume
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('마스터 볼륨', style: TextStyle(fontWeight: FontWeight.w500)),
            Text('${(settings.masterVolume * 100).toInt()}%',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: settings.masterVolume,
          onChanged: (value) => settings.setMasterVolume(value),
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildInstrumentSettings(BuildContext context) {
    final settings = context.watch<SettingsState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: settings.selectedInstrumentId,
              isExpanded: true,
              items: settings.availableInstruments
                  .map((Instrument inst) => DropdownMenuItem<String>(
                        value: inst.id,
                        child: Row(
                          children: [
                            Icon(
                                inst.type == InstrumentType.piano
                                    ? Icons.piano
                                    : Icons.music_note,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(inst.name,
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  settings.setInstrument(val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIModelSettings(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final currentKey = settings.currentApiKey;
    final isCustom = settings.aiProviderType == AIProviderType.custom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. AI Provider Select Box (Dropdown)
        Text(
          'AI 서비스 제공자',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AIProviderType>(
              value: settings.aiProviderType,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
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
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (AIProviderType? newProvider) {
                if (newProvider != null) {
                  settings.setAiProvider(newProvider.id);
                  _apiKeyController.text =
                      settings.getApiKeyForProvider(newProvider);
                  setState(() => _isEditingApiKey = false);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 2. Custom Base URL & Model Name (When Custom is selected)
        if (settings.aiProviderType == AIProviderType.custom) ...[
          TextField(
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
          const SizedBox(height: 8),
          TextField(
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
          const SizedBox(height: 12),
        ],

        // 3. API Key Input / Active Status
        if (currentKey.isEmpty && !isCustom || _isEditingApiKey) ...[
          TextField(
            controller: _apiKeyController,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
            decoration: InputDecoration(
              hintText: switch (settings.aiProviderType) {
                AIProviderType.gemini => 'API Key (Google Gemini)',
                AIProviderType.openai => 'API Key (OpenAI ChatGPT)',
                AIProviderType.claude => 'API Key (Anthropic Claude)',
                AIProviderType.custom => 'Optional API Key (Custom/Ollama)',
              },
              hintStyle: TextStyle(
                  color: Theme.of(context).hintColor, fontSize: 12),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: Icon(Icons.save,
                    color: Theme.of(context).colorScheme.primary, size: 20),
                onPressed: () {
                  final val = _apiKeyController.text.trim();
                  settings.updateApiKeyForProvider(
                      settings.aiProviderType, val);
                  setState(() => _isEditingApiKey = false);
                  _apiKeyController.text = settings.currentApiKey;

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          '${settings.aiProviderType.label} 설정이 저장되었습니다.'),
                      duration: const Duration(seconds: 1)));
                },
              ),
            ),
            obscureText: true,
            onSubmitted: (value) {
              settings.updateApiKeyForProvider(
                  settings.aiProviderType, value.trim());
              setState(() => _isEditingApiKey = false);
            },
          ),
          const SizedBox(height: 4),
          Text(
            switch (settings.aiProviderType) {
              AIProviderType.gemini => 'aistudio.google.com 에서 발급받은 키를 입력하세요.',
              AIProviderType.openai => 'platform.openai.com 에서 발급받은 키를 입력하세요.',
              AIProviderType.claude => 'console.anthropic.com 에서 발급받은 키를 입력하세요.',
              AIProviderType.custom => '로컬 Ollama는 키 없이 바로 사용 가능합니다.',
            },
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            '${settings.aiProviderType.label} 활성화됨',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: 12))),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isEditingApiKey = true;
                          _apiKeyController.text = currentKey;
                        });
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      color: Theme.of(context).colorScheme.primary,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        settings.clearCurrentApiKey();
                        _apiKeyController.clear();
                        setState(() => _isEditingApiKey = false);
                      },
                      icon: const Icon(Icons.delete, size: 16),
                      color: Theme.of(context).colorScheme.error,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                if (settings.aiProviderType != AIProviderType.custom) ...[
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.psychology, size: 16),
                      const SizedBox(width: 8),
                      const Text('사용 모델', style: TextStyle(fontSize: 12)),
                      const Spacer(),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: settings.currentModelId,
                          isDense: true,
                          items: AIModelInfo.getModelsForProvider(
                                  settings.aiProviderType)
                              .map((m) => DropdownMenuItem(
                                    value: m.id,
                                    child: Text('${m.label} (${m.shortLabel})',
                                        style: const TextStyle(fontSize: 11)),
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
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
                if (settings.currentModelInfo.supportsThinking ||
                    settings.aiProviderType == AIProviderType.gemini) ...[
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 16),
                      const SizedBox(width: 8),
                      const Text('추론 강도', style: TextStyle(fontSize: 12)),
                      const Spacer(),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<ThinkingLevel>(
                          value: settings.thinkingLevel,
                          isDense: true,
                          items: ThinkingLevel.values
                              .map((lvl) => DropdownMenuItem(
                                    value: lvl,
                                    child: Text(lvl.label,
                                        style: const TextStyle(fontSize: 11)),
                                  ))
                              .toList(),
                          onChanged: (lvl) {
                            if (lvl != null) {
                              settings.setThinkingLevel(lvl);
                            }
                          },
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildSectionTitle(context, 'AI 페르소나 (Persona)'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildPersonaChip(
              context,
              settings,
              _systemPromptController,
              '친절한 선생님',
              '당신은 친절한 기타 이론 선생님입니다.\n사용자의 질문에 대해 음악 이론적으로 분석하고, 초보자도 이해하기 쉽도록 친절하게 설명해주세요.\n답변은 반드시 한국어(Korean)로 작성해야 합니다.',
              Icons.sentiment_satisfied_alt,
            ),
            _buildPersonaChip(
              context,
              settings,
              _systemPromptController,
              '간결한 답변',
              '당신은 숙련된 음악가입니다.\n질문에 대해 핵심만 간결하고 명확하게 답변해주세요.\n부연 설명은 최소화하고, 결론 위주로 한국어(Korean)로 작성해주세요.',
              Icons.short_text,
            ),
            _buildPersonaChip(
              context,
              settings,
              _systemPromptController,
              '전문가',
              '당신은 깊이 있는 음악 이론 전문가입니다.\n화성학적 배경, 스케일의 유래, 연관된 고급 이론까지 상세하게 분석하여 한국어(Korean)로 설명해주세요.',
              Icons.school,
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _systemPromptController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'AI에게 부여할 역할이나 답변 스타일을 입력하세요.',
            filled: true,
            fillColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface),
          onChanged: (val) {
            settings.setSystemPrompt(val);
          },
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(context, '채팅 설정'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('글자 크기', style: TextStyle(fontSize: 13)),
            Text('${settings.chatFontSize.toInt()} px',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
        Slider(
          value: settings.chatFontSize,
          min: 12.0,
          max: 24.0,
          divisions: 12,
          onChanged: (val) => settings.setChatFontSize(val),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history, size: 20),
          title:
              const Text('변경 이력 (Changelog)', style: TextStyle(fontSize: 14)),
          onTap: () {
            Navigator.pop(context); // Close Drawer
            showDialog(
              context: context,
              builder: (context) => const ChangelogDialog(),
            );
          },
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.info_outline, size: 20),
          title: Text('개발자 정보 (Developer)', style: TextStyle(fontSize: 14)),
          subtitle: Text('2jungho@gmail.com', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
