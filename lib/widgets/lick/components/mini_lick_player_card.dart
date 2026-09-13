import 'package:flutter/material.dart';
import '../../../models/lick/artist_lick_model.dart';

/// Reusable mini card for displaying an [ArtistLick], with playback state, note sequence preview,
/// technique badge, and optional chord insertion action.
class MiniLickPlayerCard extends StatelessWidget {
  final ArtistLick lick;
  final bool isPlaying;
  final int activeNoteIndex;
  final NoteTechnique activeTechnique;
  final VoidCallback onTogglePlay;
  final VoidCallback onOpenVault;
  final VoidCallback? onInsertChord;
  final double width;
  final String vaultActionText;

  const MiniLickPlayerCard({
    super.key,
    required this.lick,
    required this.isPlaying,
    required this.activeNoteIndex,
    required this.activeTechnique,
    required this.onTogglePlay,
    required this.onOpenVault,
    this.onInsertChord,
    this.width = 250,
    this.vaultActionText = '5대 Box 보기',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isPlaying
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlaying
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isPlaying ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Artist & Play Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            lick.artist,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lick.cagedForm,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lick.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onTogglePlay,
                icon: Icon(
                  isPlaying ? Icons.stop : Icons.play_arrow,
                  size: 16,
                  color: isPlaying ? Colors.redAccent : colorScheme.primary,
                ),
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                ),
                tooltip: isPlaying ? '정지' : '미리듣기 (테크닉 반영)',
              ),
            ],
          ),

          // Center: Note preview & Real-time technique badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: lick.notes.asMap().entries.map((entry) {
                        final noteIdx = entry.key;
                        final note = entry.value;
                        final isThisNotePlaying =
                            isPlaying && activeNoteIndex == noteIdx;

                        return Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: isThisNotePlaying
                                ? Colors.amber
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isThisNotePlaying
                                  ? Colors.amber
                                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '${note.fret}${note.technique.symbol}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isThisNotePlaying
                                  ? Colors.black
                                  : colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (isPlaying && activeTechnique != NoteTechnique.none) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: Text(
                      activeTechnique.label,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom: Actions row
          Row(
            mainAxisAlignment: onInsertChord != null
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.end,
            children: [
              if (onInsertChord != null)
                TextButton.icon(
                  onPressed: onInsertChord,
                  icon: const Icon(Icons.add, size: 12),
                  label: Text('${lick.targetChord} 삽입', style: const TextStyle(fontSize: 10)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    visualDensity: VisualDensity.compact,
                    minimumSize: Size.zero,
                  ),
                ),
              InkWell(
                onTap: onOpenVault,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vaultActionText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios, size: 9, color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
