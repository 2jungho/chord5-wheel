import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/music_state.dart';
import '../../audio/audio_manager.dart';
import '../../widgets/common/chord_info_section.dart';
import '../../providers/settings_state.dart';

class InfoPanel extends StatelessWidget {
  final bool withContainer;

  const InfoPanel({super.key, this.withContainer = true});

  // _handleGenerateMoodPreview removed (Legacy MusicGen)

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicState>(
      builder: (context, state, _) {
        final mode = state.currentMode;
        final scale = state.currentScale;
        final chord = state.selectedChord;
        final voicing = state.mainChordVoicing;
        final root = state.rootNote;

        // Character Note
        final charNote = scale.characterNote;

        // 1. Mode Info Content
        Widget modeInfoContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    // Parent Key logic...
                  ],
                ),
                /* Legacy MusicGen Button Removed */
              ],
            ),
            const SizedBox(height: 16),

            // Scale Notes
            Text('Scale Formula & Notes',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
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
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest;
                final textColor = isHighlight
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface;
                final subTextColor = isHighlight
                    ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)
                    : Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.7);

                return Container(
                  width: 42,
                  height: 54,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      if (isHighlight)
                        BoxShadow(
                          color: bgColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                    border: Border.all(
                        color: isHighlight
                            ? bgColor
                            : Theme.of(context).dividerColor,
                        width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(n,
                          style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(f,
                          style: TextStyle(
                              color: subTextColor,
                              fontSize: 10,
                              fontWeight: isHighlight
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
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
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(
                mode.description,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.4),
              ),
            ),
          ],
        );

        Widget modeInfoCard = withContainer
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.1),
                        blurRadius: 4)
                  ],
                ),
                child: modeInfoContent,
              )
            : SizedBox(
                width: double.infinity,
                child: modeInfoContent,
              );

        // 2. Main Chord Viewer Content
        Widget chordInfoContent = ChordInfoSection(
          root: chord.root,
          quality: chord.quality,
          intervals: chord.intervals.join(', '),
          notes: chord.notes,
          onPlay: () => AudioManager().playStrum(chord.notes),
          voicing: voicing,
          characterNote: charNote,
          degree: chord.degree,
          instrument: context.watch<SettingsState>().selectedInstrument,
        );

        Widget chordInfoCard = withContainer
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.1),
                        blurRadius: 4)
                  ],
                ),
                child: chordInfoContent,
              )
            : SizedBox(
                width: double.infinity,
                child: chordInfoContent,
              );

        return LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 700;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: modeInfoCard),
                  const SizedBox(width: 24),
                  Expanded(child: chordInfoCard),
                ],
              );
            } else {
              if (!withContainer) {
                // When merged in dashboard, separation is handled by parent divider
                // But here we still need to return both.
                // Parent likely calls InfoPanel just once.
                return Column(children: [
                  modeInfoCard,
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: Theme.of(context).dividerColor),
                  ),
                  chordInfoCard
                ]);
              }
              return Column(
                children: [
                  modeInfoCard,
                  const SizedBox(height: 24),
                  chordInfoCard,
                ],
              );
            }
          },
        );
      },
    );
  }
}
