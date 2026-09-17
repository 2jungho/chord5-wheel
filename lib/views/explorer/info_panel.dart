import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/music_state.dart';
import '../../audio/audio_manager.dart';
import '../../widgets/common/chord_info_section.dart';
import '../../providers/settings_state.dart';
import '../../widgets/lick/chord_lick_recommendation_card.dart';
import 'widgets/mode_info_section.dart';

class InfoPanel extends StatelessWidget {
  final bool withContainer;
  final bool showLickSection;
  final bool? isWide;

  const InfoPanel({
    super.key,
    this.withContainer = true,
    this.showLickSection = true,
    this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicState>(
      builder: (context, state, _) {
        final mode = state.currentMode;
        final root = state.rootNote;
        final scale = state.currentScale;
        final chord = state.selectedChord;
        final voicing = state.mainChordVoicing;

        // Character Note
        final charNote = scale.characterNote;

        // 1. Mode Info Card
        final modeInfoCard = ModeInfoSection(
          mode: mode,
          root: root,
          scale: scale,
          charNote: charNote,
          withContainer: withContainer,
        );

        // 2. Main Chord Viewer Content
        Widget chordInfoContent = ChordInfoSection(
          root: chord.root,
          quality: chord.quality,
          intervals: chord.intervals.join(', '),
          notes: chord.notes,
          onPlay: () {
            if (voicing.frets.any((f) => f != -1)) {
              AudioManager().playVoicing(voicing, root: chord.root);
            } else {
              AudioManager().playStrum(chord.notes);
            }
          },
          voicing: voicing,
          characterNote: charNote,
          degree: chord.degree,
          instrument: context.watch<SettingsState>().selectedInstrument,
        );

        Widget baseChordCard = withContainer
            ? Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 238),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                        color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                        blurRadius: 4)
                  ],
                ),
                child: chordInfoContent,
              )
            : SizedBox(
                width: double.infinity,
                child: chordInfoContent,
              );

        Widget chordInfoCard = showLickSection
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  baseChordCard,
                  ChordLickRecommendationCard(
                    chordRoot: chord.root,
                    chordQuality: chord.quality,
                    keyContext: '$root ${mode.name}',
                  ),
                ],
              )
            : baseChordCard;

        Widget buildContent(bool wide) {
          if (wide) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: modeInfoCard),
                  const SizedBox(width: 14),
                  Expanded(child: chordInfoCard),
                ],
              ),
            );
          } else {
            if (!withContainer) {
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
        }

        if (isWide != null) {
          return buildContent(isWide!);
        }

        return LayoutBuilder(
          builder: (context, constraints) =>
              buildContent(constraints.maxWidth > 700),
        );
      },
    );
  }
}
