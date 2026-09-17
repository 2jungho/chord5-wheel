import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/music_constants.dart';
import '../../../models/scale_model.dart';
import '../../../providers/lyria_state.dart';

/// Section widget displaying Mode title, AI Soundscape trigger, scale notes/intervals chips, and mode description.
class ModeInfoSection extends StatelessWidget {
  final ModeData mode;
  final String root;
  final Scale scale;
  final String charNote;
  final bool withContainer;

  const ModeInfoSection({
    super.key,
    required this.mode,
    required this.root,
    required this.scale,
    required this.charNote,
    this.withContainer = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$root ${mode.name == "Ionian" ? "Major" : (mode.name == "Aeolian" ? "Minor" : mode.name)}',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Builder(
              builder: (context) {
                final lyria = context.watch<LyriaState>();
                final isThisModePlaying =
                    lyria.isMoodscapePlaying && lyria.currentMoodscapeMode == mode.name;

                return Tooltip(
                  message: isThisModePlaying
                      ? '사운드스케이프 중지'
                      : '$root ${mode.name} 모드 AI 사운드스케이프 감상',
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      if (isThisModePlaying) {
                        lyria.stopPlayback();
                      } else {
                        lyria.playModeMoodscape(mode.name, root, charNote);
                      }
                    },
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      backgroundColor: isThisModePlaying
                          ? Colors.redAccent.withValues(alpha: 0.2)
                          : colorScheme.primaryContainer.withValues(alpha: 0.7),
                    ),
                    icon: Icon(
                      isThisModePlaying ? Icons.stop_rounded : Icons.auto_awesome,
                      size: 16,
                      color: isThisModePlaying ? Colors.redAccent : colorScheme.primary,
                    ),
                    label: Text(
                      isThisModePlaying ? '중지' : 'AI 모드 감상',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isThisModePlaying ? Colors.redAccent : colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Scale Notes
        Text(
          'Scale Formula & Notes',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(scale.notes.length, (i) {
            final n = scale.notes[i];
            final f = scale.intervals.length > i ? scale.intervals[i] : '';

            // 강조 로직: 루트(1P) 또는 특징음(CharNote)인 경우 강조
            final isRoot = f == '1P';
            final isCharNote =
                charNote.isNotEmpty && n == charNote.split(' ')[0];
            final isHighlight = isRoot || isCharNote;

            final bgColor = isHighlight
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest;
            final textColor = isHighlight
                ? colorScheme.onPrimary
                : colorScheme.onSurface;
            final subTextColor = isHighlight
                ? colorScheme.onPrimary.withValues(alpha: 0.8)
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

            return Container(
              width: 42,
              height: 54,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  if (isHighlight)
                    BoxShadow(
                      color: bgColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
                border: Border.all(
                  color: isHighlight ? bgColor : theme.dividerColor,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    n,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    f,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 10,
                      fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        // Description
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            mode.description,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );

    if (!withContainer) {
      return SizedBox(
        width: double.infinity,
        child: content,
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 238),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: content,
    );
  }
}
