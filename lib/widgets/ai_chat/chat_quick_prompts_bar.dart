import 'package:flutter/material.dart';

class ChatQuickPromptsBar extends StatelessWidget {
  final bool canRegenerate;
  final VoidCallback onRegenerate;
  final List<String> prompts;
  final ValueChanged<String> onSelectPrompt;

  const ChatQuickPromptsBar({
    super.key,
    required this.canRegenerate,
    required this.onRegenerate,
    required this.prompts,
    required this.onSelectPrompt,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          // Regenerate Button
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 4.0),
            child: IconButton(
              onPressed: canRegenerate ? onRegenerate : null,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: '답변 재생성',
              color: canRegenerate
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: prompts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = prompts[index];
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return ActionChip(
                  label: Text(prompt),
                  onPressed: () => onSelectPrompt(prompt),
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isDark ? FontWeight.w500 : FontWeight.normal,
                    color: isDark
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  side: isDark
                      ? BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                        )
                      : BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
