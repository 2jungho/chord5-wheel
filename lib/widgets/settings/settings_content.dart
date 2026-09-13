import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_state.dart';
import '../../models/ai_provider_config.dart';
import 'sections/general_settings_section.dart';
import 'sections/instrument_settings_section.dart';
import 'sections/ai_provider_settings_section.dart';
import 'sections/prompt_settings_section.dart';

/// 공통 설정 바디 위젯
/// [SettingsDialog] 및 [SettingsDrawer]에서 공통으로 임베드하여 사용합니다.
class SettingsContent extends StatefulWidget {
  final ScrollController? scrollController;

  const SettingsContent({
    super.key,
    this.scrollController,
  });

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(24),
      child: Consumer<SettingsState>(
        builder: (context, settings, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 일반 설정 (앱 테마, 마스터 볼륨)
              GeneralSettingsSection(settings: settings),
              const SizedBox(height: 24),

              // 2. 악기 및 튜닝 설정
              InstrumentSettingsSection(settings: settings),
              const SizedBox(height: 24),

              // 3. AI 프로바이더 및 모델/키 설정
              AiProviderSettingsSection(
                settings: settings,
                apiKeyController: _apiKeyController,
                isEditingApiKey: _isEditingApiKey,
                onToggleEditingApiKey: (val) {
                  setState(() => _isEditingApiKey = val);
                },
              ),

              // 4. 시스템 프롬프트 및 페르소나 설정 (API 키 설정 완료 시 활성화)
              if ((settings.currentApiKey.isNotEmpty ||
                      settings.aiProviderType == AIProviderType.custom) &&
                  !_isEditingApiKey) ...[
                const SizedBox(height: 20),
                PromptSettingsSection(
                  settings: settings,
                  systemPromptController: _systemPromptController,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
