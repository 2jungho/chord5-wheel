import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_state.dart';
import '../../models/instrument_model.dart';
import '../../models/gemini_model.dart';
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
        // Theme Mode
        const Text('테마 (Theme)', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode, size: 16),
                label: Text('라이트')),
            ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode, size: 16),
                label: Text('다크')),
          ],
          selected: {settings.themeMode},
          onSelectionChanged: (Set<ThemeMode> newSelection) {
            settings.setThemeMode(newSelection.first);
          },
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(height: 24),

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
    const providerLabel = 'Google Gemini';

    if (currentKey.isEmpty || _isEditingApiKey) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _apiKeyController,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'API Key (Google Gemini)',
              hintStyle: TextStyle(color: Theme.of(context).hintColor),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: Icon(Icons.save,
                    color: Theme.of(context).colorScheme.primary),
                onPressed: () {
                  final val = _apiKeyController.text.trim();
                  settings.updateApiKey(val);
                  setState(() => _isEditingApiKey = false);
                  _apiKeyController.text = settings.currentApiKey;

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Google Gemini 모델이 활성화되었습니다.'),
                      duration: Duration(seconds: 1)));
                },
              ),
            ),
            obscureText: true,
            onSubmitted: (value) {
              settings.updateApiKey(value.trim());
              setState(() => _isEditingApiKey = false);
            },
          ),
          const SizedBox(height: 4),
          Text('※ 입력된 Key에 따라 자동으로 검증된 Gemini 모델이 선택됩니다.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11)),
        ],
      );
    } else {
      return Column(
        children: [
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
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('$providerLabel 활성화됨',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: 13))),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isEditingApiKey = true;
                          _apiKeyController.text = currentKey;
                        });
                      },
                      icon: const Icon(Icons.edit, size: 18),
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
                      icon: const Icon(Icons.delete, size: 18),
                      color: Theme.of(context).colorScheme.error,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    const Icon(Icons.psychology, size: 18),
                    const SizedBox(width: 8),
                    const Text('사용 모델', style: TextStyle(fontSize: 13)),
                    const Spacer(),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<GeminiModel>(
                        value: settings.geminiModel,
                        isDense: true,
                        items: GeminiModel.values
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m.label,
                                      style: const TextStyle(fontSize: 12)),
                                ))
                            .toList(),
                        onChanged: (m) {
                          if (m != null) {
                            settings.setGeminiModel(m);
                          }
                        },
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'AI 페르소나 (Persona)'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
          ),
        ],
      );
    }
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
