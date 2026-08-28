import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../audio/audio_manager.dart';
import '../../../../models/instrument_model.dart';
import '../../../../models/progression/progression_models.dart';
import '../../../../providers/settings_state.dart';
import '../../../../providers/studio_state.dart';
import '../../../../utils/theory_utils.dart';
import '../../../../widgets/common/guitar/guitar_chord_widget.dart';
import '../../../../widgets/common/piano/piano_chord_widget.dart';
import 'chord_insert_dialog.dart';


class TimelineChordCard extends StatelessWidget {
  final ChordBlock block;
  final int index;
  final StudioState studio;

  const TimelineChordCard({
    super.key,
    required this.block,
    required this.index,
    required this.studio,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = studio.selectedBlockIndex == index;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.2),
                  Theme.of(context).colorScheme.surface,
                ]
              : [
                  Theme.of(context).colorScheme.surfaceContainerHigh,
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: isSelected ? 2.0 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 0),
            ),
          const BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            studio.selectBlock(index);
            if (block.voicing != null &&
                block.voicing!.frets.any((f) => f != -1)) {
              AudioManager().playVoicing(block.voicing!,
                  root: block.chordSymbol);
            } else {
              final notes =
                  TheoryUtils.analyzeChord(block.chordSymbol).notes;
              AudioManager().playStrum(notes);
            }
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Bar Number Label
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Bar ${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            block.chordSymbol,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                          ),
                          if (block.functionTag != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${block.functionTag!})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                          if (block.chordDetail != null) ...[
                            const SizedBox(width: 2),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  studio.selectBlock(index);
                                  if (block.voicing != null &&
                                      block.voicing!.frets
                                          .any((f) => f != -1)) {
                                    AudioManager().playVoicing(block.voicing!,
                                        root: block.chordSymbol);
                                  } else {
                                    final notes = TheoryUtils.analyzeChord(
                                            block.chordSymbol)
                                        .notes;
                                    AudioManager().playStrum(notes);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Icon(
                                    Icons.volume_up_rounded,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (block.voicing != null)
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Consumer<SettingsState>(
                            builder: (context, settings, _) {
                              if (settings.selectedInstrument.type ==
                                  InstrumentType.piano) {
                                return PianoChordWidget(
                                  notes: TheoryUtils.analyzeChord(
                                          block.chordSymbol)
                                      .notes,
                                  width: 130,
                                  height: 80,
                                  showLabels: true,
                                );
                              }
                              return GuitarChordWidget(
                                voicing: block.voicing!,
                                width: 130,
                                height: 100,
                                stringCount:
                                    settings.selectedInstrument.stringCount,
                              );
                            },
                          ),
                        ),
                      )
                    else
                      const Expanded(
                        child: Center(
                          child: Icon(Icons.music_off,
                              size: 24, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 2,
                top: 0,
                child: IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    size: 15,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  onPressed: () {
                    ChordInsertDialog.show(
                      context,
                      targetChord: block.chordSymbol,
                      currentKey: studio.session.key,
                      insertIndex: index,
                      onInsert: (newChord, idx) {
                        studio.insertChordAt(idx, newChord);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('\'$newChord\' 코드가 Bar ${idx + 1}에 삽입되었습니다.'),
                            duration: const Duration(milliseconds: 1500),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                  tooltip: '앞에 경과 화음(화성 확장) 삽입',
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  onPressed: () => studio.removeChord(index),
                  tooltip: '삭제',
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
