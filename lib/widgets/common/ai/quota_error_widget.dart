import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/gemini_model.dart';
import '../../../providers/settings_state.dart';

class QuotaErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String errorMessage;

  const QuotaErrorWidget({
    super.key,
    required this.onRetry,
    required this.errorMessage,
  });

  static bool isQuotaErrorDetected(String message) {
    final lower = message.toLowerCase();
    return lower.contains('quota') ||
        lower.contains('429') ||
        lower.contains('exhausted') ||
        lower.contains('api 사용량이 초과') ||
        lower.contains('limit');
  }

  @override
  Widget build(BuildContext context) {
    final isQuotaError = isQuotaErrorDetected(errorMessage);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withOpacity(0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              isQuotaError
                  ? '⚠️ API 사용량이 초과되었습니다.\n(Free Tier Limit)'
                  : '오류가 발생했습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            if (!isQuotaError) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 20),
            if (isQuotaError) ...[
              const Text(
                '다른 모델로 변경하여 시도해보세요:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Consumer<SettingsState>(
                builder: (context, settings, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<GeminiModel>(
                        value: settings.geminiModel,
                        isDense: true,
                        items: GeminiModel.values.map((model) {
                          return DropdownMenuItem(
                            value: model,
                            child: Text(
                              model.label,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (newModel) {
                          if (newModel != null) {
                            settings.setGeminiModel(newModel);
                            onRetry(); // 모델 변경 시 즉시 재시도
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('재시도'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
