import 'package:flutter/material.dart';
import '../../models/chord_model.dart';
import '../../utils/theory_utils.dart';
import '../../utils/guitar_utils.dart';
import 'guitar/guitar_chord_widget.dart';
import 'dialogs/app_dialog_frame.dart';

class ChordDetailDialog extends StatelessWidget {
  final String root;
  final String quality;
  final ChordVoicing voicing;
  final List<String> notes;
  final VoidCallback? onPlay;
  final String? characterNote;

  const ChordDetailDialog({
    super.key,
    required this.root,
    required this.quality,
    required this.voicing,
    required this.notes,
    this.onPlay,
    this.characterNote,
  });

  @override
  Widget build(BuildContext context) {
    final displayQuality = TheoryUtils.formatDisplayQuality(quality);
    final voicingNotes = TheoryUtils.getNotesFromVoicing(voicing, root);

    return AppDialogFrame(
      title: '$root $displayQuality',
      subtitle: 'Starting Fret: ${voicing.startFret}fr',
      width: 440,
      height: 640,
      headerTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onPlay != null)
            IconButton(
              onPressed: onPlay,
              icon: Icon(
                Icons.volume_up,
                size: 26,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'Play Chord',
            ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: '닫기',
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHigh,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ),
      ],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Large Chord Diagram
            Center(
              child: GuitarChordWidget(
                voicing: voicing,
                width: 280,
                height: 220,
                isMain: true,
              ),
            ),
            const SizedBox(height: 20),

            // Notes Info
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Voicing Notes: ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      voicingNotes.join(' - '),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description Info
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voicing Style Info',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    GuitarUtils.getVoicingDescription(voicing),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
