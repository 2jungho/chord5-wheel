import 'package:flutter/material.dart';
import '../../../../providers/studio_state.dart';

/// 타임라인 상단 CAGED 폼 선택 바
class TimelineCagedBar extends StatelessWidget {
  final StudioState studio;

  const TimelineCagedBar({
    super.key,
    required this.studio,
  });

  static const List<String> cagedStyles = [
    'C',
    'C-A',
    'A',
    'A-G',
    'G',
    'G-E',
    'E',
    'E-D',
    'D',
    'D-C',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showLabel = constraints.maxWidth > 300;
          final showIcon = constraints.maxWidth > 40;

          return Row(
            children: [
              if (showIcon) ...[
                Icon(Icons.grid_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Voicing Shape (CAGED)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                SizedBox(width: showLabel ? 16 : 8),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, innerConstraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: innerConstraints.maxWidth),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final style in cagedStyles)
                              _buildCagedNode(context, style),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCagedNode(BuildContext context, String style) {
    final isMainNode = !style.contains('-');
    final isSelected = studio.timelineVoicingStyle == style;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMainNode ? 2 : 1),
      child: Tooltip(
        message: isMainNode ? '$style Form' : 'Bridge: $style',
        child: InkWell(
          onTap: () => studio.setTimelineVoicingStyle(style),
          borderRadius: BorderRadius.circular(isMainNode ? 20 : 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isMainNode ? 32 : 36,
            height: isMainNode ? 32 : 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: isMainNode ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isMainNode ? null : BorderRadius.circular(6),
              color: isSelected
                  ? colorScheme.primary
                  : (isMainNode
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3)),
              border: isSelected
                  ? Border.all(color: colorScheme.primary, width: 1.5)
                  : (isMainNode
                      ? Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2))
                      : null),
            ),
            child: Text(
              isMainNode ? style : 'BR',
              style: TextStyle(
                fontSize: isMainNode ? 12 : 9,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : (isMainNode ? FontWeight.w600 : FontWeight.w500),
                color: isSelected
                    ? colorScheme.onPrimary
                    : (isMainNode
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
