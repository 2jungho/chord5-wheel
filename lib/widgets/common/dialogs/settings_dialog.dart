import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/settings_state.dart';
import '../../../../models/gemini_model.dart';
import '../../../../models/instrument_model.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _apiKeyController;
  late TextEditingController _systemPromptController;
  late TextEditingController _hfTokenController;
  bool _isEditingApiKey = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsState>();
    _apiKeyController = TextEditingController(text: settings.currentApiKey);
    _systemPromptController =
        TextEditingController(text: settings.systemPrompt);
    _hfTokenController = TextEditingController(text: settings.huggingFaceToken);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _systemPromptController.dispose();
    _hfTokenController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(BuildContext context, String title,
      {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionButton<T>(
    BuildContext context, {
    required T value,
    required T groupValue,
    required String label,
    required Function(T) onSelected,
    IconData? icon,
  }) {
    final isSelected = value == groupValue;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: () => onSelected(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: colorScheme.primary.withOpacity(0.5))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonaChip(
    BuildContext context,
    SettingsState settings,
    TextEditingController controller,
    String label,
    String promptText,
    IconData icon,
  ) {
    final isSelected = settings.systemPrompt.trim() == promptText.trim();
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          settings.setSystemPrompt(promptText);
          controller.text = promptText;
        }
      },
      showCheckmark: false,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Text('환경 설정 (Settings)',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    tooltip: '닫기',
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Consumer<SettingsState>(
                  builder: (context, settings, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- GENERAL SECTION ---
                        _buildSectionTitle(context, '일반 (GENERAL)',
                            icon: Icons.dashboard_customize),
                        const SizedBox(height: 8),

                        // Theme
                        Row(
                          children: [
                            _buildSelectionButton(
                              context,
                              value: ThemeMode.system,
                              groupValue: settings.themeMode,
                              label: '시스템',
                              icon: Icons.brightness_auto,
                              onSelected: settings.setThemeMode,
                            ),
                            const SizedBox(width: 8),
                            _buildSelectionButton(
                              context,
                              value: ThemeMode.light,
                              groupValue: settings.themeMode,
                              label: '라이트',
                              icon: Icons.light_mode,
                              onSelected: settings.setThemeMode,
                            ),
                            const SizedBox(width: 8),
                            _buildSelectionButton(
                              context,
                              value: ThemeMode.dark,
                              groupValue: settings.themeMode,
                              label: '다크',
                              icon: Icons.dark_mode,
                              onSelected: settings.setThemeMode,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Master Volume
                        Row(
                          children: [
                            Text('마스터 볼륨',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface)),
                            const SizedBox(width: 12),
                            Icon(Icons.volume_down,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            Expanded(
                              child: Slider(
                                value: settings.masterVolume,
                                min: 0.0,
                                max: 1.0,
                                onChanged: settings.setMasterVolume,
                              ),
                            ),
                            Icon(Icons.volume_up,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 40,
                              child: Text(
                                  '${(settings.masterVolume * 100).toInt()}%',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // --- INSTRUMENT SECTION ---
                        _buildSectionTitle(context, '악기 (INSTRUMENT)',
                            icon: Icons.music_note),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Theme.of(context).dividerColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: settings.selectedInstrumentId,
                              isExpanded: true,
                              icon: const Icon(Icons.expand_more),
                              items: settings.availableInstruments
                                  .map((Instrument inst) =>
                                      DropdownMenuItem<String>(
                                        value: inst.id,
                                        child: Row(
                                          children: [
                                            Icon(
                                                inst.type ==
                                                        InstrumentType.piano
                                                    ? Icons.piano
                                                    : Icons.grid_view,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary),
                                            const SizedBox(width: 12),
                                            Text(inst.name,
                                                style: const TextStyle(
                                                    fontSize: 14)),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) settings.setInstrument(val);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --- AI SECTION ---
                        _buildSectionTitle(context, 'AI 모델 설정',
                            icon: Icons.auto_awesome),
                        const SizedBox(height: 8),

                        // API Key / Status
                        _buildAiStatusSection(context, settings),

                        // AI Model Settings (Shown only when Active)
                        if (settings.currentApiKey.isNotEmpty &&
                            !_isEditingApiKey) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text('사용 모델',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontWeight: FontWeight.w500)),
                              ),
                              Expanded(
                                flex: 7,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<GeminiModel>(
                                      value: settings.geminiModel,
                                      isDense: true,
                                      isExpanded: true,
                                      items: GeminiModel.values
                                          .map((m) => DropdownMenuItem(
                                                value: m,
                                                child: Text(m.label,
                                                    style: const TextStyle(
                                                        fontSize: 13)),
                                              ))
                                          .toList(),
                                      onChanged: (m) {
                                        if (m != null)
                                          settings.setGeminiModel(m);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Persona
                          Text('AI 페르소나 (Persona)',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
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
                          const SizedBox(height: 12),
                          TextField(
                            controller: _systemPromptController,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'AI에게 부여할 역할이나 답변 스타일을 입력하세요.',
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            onChanged: settings.setSystemPrompt,
                          ),

                          const SizedBox(height: 20),
                          // Chat Font
                          Row(
                            children: [
                              Text('채팅 글자 크기',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.w500)),
                              const Spacer(),
                              Text('${settings.chatFontSize.toInt()} px',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: settings.chatFontSize,
                              min: 12.0,
                              max: 24.0,
                              divisions: 12,
                              onChanged: settings.setChatFontSize,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('v1.9.1 • 2jungho@gmail.com',
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5))),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('닫기'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiStatusSection(BuildContext context, SettingsState settings) {
    if (settings.currentApiKey.isEmpty || _isEditingApiKey) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _apiKeyController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Enter Google Gemini API Key',
              isDense: true,
              filled: true,
              fillColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  final val = _apiKeyController.text.trim();
                  settings.updateApiKey(val);
                  setState(() => _isEditingApiKey = false);
                  _apiKeyController.text = settings.currentApiKey;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('API Key Updated'),
                      duration: Duration(milliseconds: 1000)));
                },
              ),
            ),
            obscureText: true,
            onSubmitted: (value) {
              settings.updateApiKey(value.trim());
              setState(() => _isEditingApiKey = false);
            },
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 4),
            child: Text('Get your key from Google AI Studio',
                style: TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            const Expanded(
                child: Text('Google Gemini 활성화됨',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green))),
            IconButton(
              icon: const Icon(Icons.edit, size: 16, color: Colors.green),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  _isEditingApiKey = true;
                  _apiKeyController.text = settings.currentApiKey;
                });
              },
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                settings.clearCurrentApiKey();
                _apiKeyController.clear();
                setState(() => _isEditingApiKey = false);
              },
            ),
          ],
        ),
      );
    }
  }
}
