import 'package:flutter/material.dart';
import '../../../../widgets/common/ai/quota_error_widget.dart';

class JamMoodPromptCard extends StatelessWidget {
  final TextEditingController promptController;
  final bool isGeneratingJam;
  final String? aiJamTitle;
  final String? aiJamExplanation;
  final String? aiJamPromptError;
  final Function(String) onGenerate;
  final VoidCallback onClearExplanation;

  static const List<({String label, String prompt, IconData icon})> moodPresets = [
    (
      label: '🌧️ 비 오는 로파이',
      prompt: '비 오는 날 새벽 창밖을 보며 연주하는 감성적인 칠 로파이 비트',
      icon: Icons.water_drop_outlined,
    ),
    (
      label: '🌆 시티팝 드라이브',
      prompt: '80년대 레트로 시티팝 느낌의 세련되고 경쾌한 드라이브 그루브',
      icon: Icons.location_city_outlined,
    ),
    (
      label: '🎸 슬로우 블루스',
      prompt: '존 메이어 스타일의 따뜻하고 그루비한 슬로우 템포 블루스 잼',
      icon: Icons.electric_bolt_outlined,
    ),
    (
      label: '☕ 감성 어쿠스틱',
      prompt: '따뜻한 통기타와 부드러운 건반이 어우러진 잔잔한 카페 발라드',
      icon: Icons.coffee_outlined,
    ),
    (
      label: '✨ 네오소울 그루브',
      prompt: '세련된 텐션 코드와 펑키한 드럼 스윙이 돋보이는 네오소울 잼',
      icon: Icons.auto_awesome,
    ),
    (
      label: '⚡ 80s 펑키 록',
      prompt: '강렬한 베이스 리프와 직선적인 드럼 비트의 신나는 펑크 록',
      icon: Icons.flash_on,
    ),
  ];

  const JamMoodPromptCard({
    super.key,
    required this.promptController,
    required this.isGeneratingJam,
    required this.aiJamTitle,
    required this.aiJamExplanation,
    required this.aiJamPromptError,
    required this.onGenerate,
    required this.onClearExplanation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 15,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                "AI 분위기 & 사운드 프롬프트 (Mood Prompt)",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (aiJamTitle != null)
                InkWell(
                  onTap: onClearExplanation,
                  child: const Row(
                    children: [
                      Icon(Icons.close, size: 14, color: Colors.grey),
                      SizedBox(width: 2),
                      Text("해설 닫기",
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Prompt Input Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: promptController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText:
                        "원하는 곡 분위기나 스타일을 입력하세요 (예: 비 오는 새벽 로파이, 존 메이어 블루스)",
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.6),
                    ),
                    prefixIcon: const Icon(Icons.music_note, size: 16),
                    suffixIcon: promptController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: promptController.clear,
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  onSubmitted: onGenerate,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed:
                    isGeneratingJam || promptController.text.trim().isEmpty
                        ? null
                        : () => onGenerate(promptController.text.trim()),
                icon: isGeneratingJam
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 15),
                label: Text(
                  isGeneratingJam ? "생성 중..." : "AI 잼 생성",
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Mood Preset Quick Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: moodPresets.map((preset) {
              return ActionChip(
                avatar: Icon(preset.icon, size: 13),
                label: Text(preset.label, style: const TextStyle(fontSize: 11)),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                visualDensity: VisualDensity.compact,
                onPressed: isGeneratingJam
                    ? null
                    : () {
                        promptController.text = preset.prompt;
                        onGenerate(preset.prompt);
                      },
              );
            }).toList(),
          ),

          // Error Message
          if (aiJamPromptError != null) ...[
            const SizedBox(height: 8),
            QuotaErrorWidget.isQuotaErrorDetected(aiJamPromptError!)
                ? QuotaErrorWidget(
                    errorMessage: aiJamPromptError!,
                    onRetry: () => onGenerate(promptController.text),
                  )
                : Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      aiJamPromptError!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
          ],

          // AI Insight & Explanation Card
          if (aiJamTitle != null && aiJamExplanation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.library_music,
                          size: 15, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          aiJamTitle!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "타임라인 자동 적용됨",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (aiJamExplanation!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      aiJamExplanation!,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
