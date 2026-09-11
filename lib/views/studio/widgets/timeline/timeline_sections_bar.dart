import 'package:flutter/material.dart';
import '../../../../providers/studio_state.dart';
import '../../../../models/progression/progression_models.dart';

class TimelineSectionsBar extends StatelessWidget {
  final StudioState studio;
  final ProgressionSession session;

  const TimelineSectionsBar({
    super.key,
    required this.studio,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final sections = session.sections.isNotEmpty
        ? session.sections
        : [SongSection(id: 'main', name: 'Main', progression: session.progression)];
    final activeIdx = session.activeSectionIndex.clamp(0, sections.length - 1);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.layers_outlined,
              size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            'Song Form:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sections.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                // Add Section Button
                if (index == sections.length) {
                  return PopupMenuButton<String>(
                    tooltip: '새 섹션 추가',
                    offset: const Offset(0, 30),
                    onSelected: (type) {
                      studio.addSection(type);
                    },
                    itemBuilder: (context) => [
                      'Intro',
                      'Verse',
                      'Chorus',
                      'Bridge',
                      'Outro',
                    ]
                        .map((type) => PopupMenuItem(
                              value: type,
                              child: Text('+ $type 추가',
                                  style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 13, color: theme.colorScheme.primary),
                          const SizedBox(width: 2),
                          Text('섹션 추가',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary)),
                        ],
                      ),
                    ),
                  );
                }

                final section = sections[index];
                final isSelected = index == activeIdx;

                return InkWell(
                  onTap: () => studio.selectSection(index),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.dividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          section.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (section.progression.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.black.withValues(alpha: 0.25)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${section.progression.length}마디',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                        if (sections.length > 1 && isSelected) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => studio.removeSection(index),
                            child: const Icon(Icons.close,
                                size: 11, color: Colors.white70),
                          ),
                        ],
                      ],
                    ),
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
