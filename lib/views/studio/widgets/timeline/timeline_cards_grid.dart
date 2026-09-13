import 'package:flutter/material.dart';
import '../../../../providers/studio_state.dart';
import '../../../../models/progression/progression_models.dart';
import 'timeline_chord_card.dart';

/// 타임라인 코드 카드 그리드 뷰
class TimelineCardsGrid extends StatelessWidget {
  final StudioState studio;
  final ProgressionSession session;

  const TimelineCardsGrid({
    super.key,
    required this.studio,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 60) return const SizedBox.shrink();

            int crossAxisCount = (constraints.maxWidth / 160).floor();
            double sidePadding = 24.0;
            double spacing = 16.0;

            if (constraints.maxWidth < 360) {
              crossAxisCount = 2;
              sidePadding = 8.0;
              spacing = 8.0;
            }

            if (constraints.maxWidth < 220) {
              crossAxisCount = 1;
              sidePadding = 4.0;
              spacing = 4.0;
            } else if (crossAxisCount < 2) {
              crossAxisCount = 2;
            }

            if (crossAxisCount > 4) crossAxisCount = 4;

            return GridView.builder(
              padding: EdgeInsets.fromLTRB(sidePadding, 24, sidePadding, 48),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: 24,
                childAspectRatio: 0.85,
              ),
              itemCount: session.progression.length,
              itemBuilder: (context, index) {
                final block = session.progression[index];
                return TimelineChordCard(
                  block: block,
                  index: index,
                  studio: studio,
                );
              },
            );
          },
        ),
        _buildMoreBarsBadge(context, session),
      ],
    );
  }

  Widget _buildMoreBarsBadge(BuildContext context, ProgressionSession session) {
    if (session.progression.length <= 4) return const SizedBox.shrink();
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondaryContainer
                  .withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_double_arrow_down,
                    size: 14,
                    color:
                        Theme.of(context).colorScheme.onSecondaryContainer),
                const SizedBox(width: 6),
                Text(
                  '${session.progression.length - 4} More Bars Below',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
