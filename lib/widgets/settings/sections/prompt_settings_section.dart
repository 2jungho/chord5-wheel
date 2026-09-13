import 'package:flutter/material.dart';
import '../../../providers/settings_state.dart';

/// 시스템 프롬프트 및 AI 페르소나 설정 섹션
class PromptSettingsSection extends StatelessWidget {
  final SettingsState settings;
  final TextEditingController systemPromptController;

  const PromptSettingsSection({
    super.key,
    required this.settings,
    required this.systemPromptController,
  });

  Widget _buildPersonaChip(
    BuildContext context,
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
          systemPromptController.text = promptText;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Persona
        Text('AI 페르소나 (Persona)',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPersonaChip(
              context,
              '친절한 선생님',
              '당신은 친절한 기타 이론 선생님입니다.\n사용자의 질문에 대해 음악 이론적으로 분석하고, 초보자도 이해하기 쉽도록 친절하게 설명해주세요.\n답변은 반드시 한국어(Korean)로 작성해야 합니다.',
              Icons.sentiment_satisfied_alt,
            ),
            _buildPersonaChip(
              context,
              '간결한 답변',
              '당신은 숙련된 음악가입니다.\n질문에 대해 핵심만 간결하고 명확하게 답변해주세요.\n부연 설명은 최소화하고, 결론 위주로 한국어(Korean)로 작성해주세요.',
              Icons.short_text,
            ),
            _buildPersonaChip(
              context,
              '전문가',
              '당신은 깊이 있는 음악 이론 전문가입니다.\n화성학적 배경, 스케일의 유래, 연관된 고급 이론까지 상세하게 분석하여 한국어(Korean)로 설명해주세요.',
              Icons.school,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: systemPromptController,
          maxLines: 2,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'AI에게 부여할 역할이나 답변 스타일을 입력하세요.',
            filled: true,
            fillColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          onChanged: settings.setSystemPrompt,
        ),

        const SizedBox(height: 20),

        // Chat Font Size
        Row(
          children: [
            Text('채팅 글자 크기',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Text('${settings.chatFontSize.toInt()} px',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
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
    );
  }
}
