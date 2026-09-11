import 'package:flutter/material.dart';
import '../../../models/lick/artist_lick_model.dart';

/// 아티스트 릭 보관함 - 화성학적 분석 & 연주 가이드 패널
class LickTheoryPanel extends StatelessWidget {
  final ArtistLick lick;
  final ({String summary, List<String> noteAnalyses}) analysis;

  const LickTheoryPanel({
    super.key,
    required this.lick,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, size: 20, color: colorScheme.tertiary),
              const SizedBox(width: 8),
              Text(
                '화성학적 분석 & 연주 가이드',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            analysis.summary,
            style: const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 플레이 팁 & 화성학 타겟팅:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  lick.theoryTips,
                  style: TextStyle(fontSize: 11, height: 1.4, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('음표별 화성학 역할:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 6),
          ...analysis.noteAnalyses.map(
            (noteStr) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('• $noteStr', style: const TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}
