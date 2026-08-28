import 'package:flutter/material.dart';
import '../../../models/progression/progression_models.dart';

/// 코드 카드 및 타임라인에서 스트럼 주법(다운/업/뮤트/베이스) 및 아르페지오 가이드를 표시하는 위젯
class StrumTabStrip extends StatelessWidget {
  final RhythmPattern pattern;
  final int activeBeat; // 1~4 or 0 (when inactive)
  final bool isCompact;
  final bool showFingerpicking;

  const StrumTabStrip({
    super.key,
    required this.pattern,
    this.activeBeat = 0,
    this.isCompact = true,
    this.showFingerpicking = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = pattern.steps;

    if (steps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 4 : 8, vertical: isCompact ? 2 : 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: steps.map((step) {
          // step.position is 0~15
          final stepBeat = (step.position ~/ 4) + 1;
          final isCurrentStepActive = activeBeat > 0 && activeBeat == stepBeat;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 2.0 : 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionIcon(context, step, isCurrentStepActive),
                if (!isCompact && showFingerpicking) ...[
                  const SizedBox(height: 2),
                  Text(
                    _getFingerpickingString(step),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isCurrentStepActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionIcon(
      BuildContext context, RhythmStep step, bool isActive) {
    final theme = Theme.of(context);

    String symbol;
    Color color;

    switch (step.action) {
      case RhythmActionType.down:
        symbol = '↓';
        color = step.isAccent ? theme.colorScheme.primary : theme.colorScheme.onSurface;
        break;
      case RhythmActionType.up:
        symbol = '↑';
        color = theme.colorScheme.secondary;
        break;
      case RhythmActionType.mute:
        symbol = '✕';
        color = Colors.redAccent.shade200;
        break;
      case RhythmActionType.bass:
        symbol = 'B';
        color = Colors.amber;
        break;
      case RhythmActionType.none:
        symbol = '·';
        color = Colors.grey;
        break;
    }

    if (isActive) {
      color = theme.colorScheme.tertiary;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 3 : 5, vertical: isCompact ? 1 : 2),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.tertiary.withValues(alpha: 0.25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: isActive
            ? Border.all(color: theme.colorScheme.tertiary, width: 1)
            : null,
      ),
      child: Text(
        symbol,
        style: TextStyle(
          fontSize: isCompact ? 11 : 13,
          fontWeight: step.isAccent || isActive ? FontWeight.w900 : FontWeight.bold,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }

  String _getFingerpickingString(RhythmStep step) {
    // 16분음표 위치별 추천 아르페지오 줄 번호 가이드 (P-i-m-a)
    switch (step.position % 16) {
      case 0:
        return '6(P)';
      case 4:
        return '3(i)';
      case 6:
      case 8:
        return '2(m)';
      case 10:
      case 12:
        return '1(a)';
      case 14:
        return '2(m)';
      default:
        return '3(i)';
    }
  }
}
