import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/ai_provider_config.dart';
import '../../models/gemini_model.dart';
import '../../providers/settings_state.dart';

class ChatPanelHeader extends StatelessWidget {
  final SettingsState settings;
  final VoidCallback onClearChat;
  final VoidCallback? onClose;
  final VoidCallback onLaunchExternalWeb;
  final bool isMobile;

  const ChatPanelHeader({
    super.key,
    required this.settings,
    required this.onClearChat,
    this.onClose,
    required this.onLaunchExternalWeb,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  settings.aiProviderType == AIProviderType.openai
                      ? Icons.psychology
                      : settings.aiProviderType == AIProviderType.claude
                          ? Icons.wb_incandescent_outlined
                          : settings.aiProviderType == AIProviderType.custom
                              ? Icons.terminal
                              : Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  switch (settings.aiProviderType) {
                    AIProviderType.gemini => 'Gemini',
                    AIProviderType.openai => 'ChatGPT',
                    AIProviderType.claude => 'Claude',
                    AIProviderType.custom => 'Custom AI',
                  },
                  style: GoogleFonts.notoSansKr(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                if (settings.aiProviderType != AIProviderType.custom)
                  Theme(
                    data: Theme.of(context).copyWith(
                      popupMenuTheme: PopupMenuThemeData(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        elevation: 10,
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      tooltip: 'AI 모델 변경',
                      initialValue: settings.currentModelId,
                      position: PopupMenuPosition.under,
                      constraints: const BoxConstraints(
                        minWidth: 200,
                        maxWidth: 260,
                      ),
                      padding: EdgeInsets.zero,
                      onSelected: (newModelId) {
                        switch (settings.aiProviderType) {
                          case AIProviderType.gemini:
                            settings.setGeminiModel(
                              GeminiModel.fromId(newModelId),
                            );
                            break;
                          case AIProviderType.openai:
                            settings.setOpenAiModelId(newModelId);
                            break;
                          case AIProviderType.claude:
                            settings.setClaudeModelId(newModelId);
                            break;
                          case AIProviderType.custom:
                            settings.setCustomModelName(newModelId);
                            break;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'AI 모델이 ${AIModelInfo.fromId(newModelId).label}(으)로 변경되었습니다.',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      itemBuilder: (context) {
                        final models = AIModelInfo.getModelsForProvider(
                          settings.aiProviderType,
                        );
                        return models.map((m) {
                          final isSelected = m.id == settings.currentModelId;
                          return PopupMenuItem<String>(
                            value: m.id,
                            height: 38,
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  size: 16,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).hintColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    m.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.15)
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    m.shortLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              settings.currentModelInfo.shortLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onLaunchExternalWeb,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Opacity(
                  opacity: 0.7,
                  child: Image.asset(
                    settings.aiProvider == 'openai'
                        ? 'assets/images/icons8-chatgpt.png'
                        : 'assets/images/icons8-gemini.png',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
            ),
            onPressed: onClearChat,
            tooltip: '대화 지우기',
          ),
          if (onClose != null)
            IconButton(
              icon: Icon(
                Icons.close,
                color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
              ),
              onPressed: onClose,
              tooltip: '닫기',
            ),
        ],
      ),
    );
  }
}
