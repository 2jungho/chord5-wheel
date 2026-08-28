import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/music_state.dart';
import '../../../models/chord_model.dart';
import '../../capo/capo_modal.dart';


class DiatonicList extends StatelessWidget {
  const DiatonicList({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<
        MusicState,
        ({
          List<Chord> diatonicChords,
          int selectedDiatonicIndex,
          bool isSeventhMode
        })>(
      selector: (_, state) => (
        diatonicChords: state.diatonicChords,
        selectedDiatonicIndex: state.selectedDiatonicIndex,
        isSeventhMode: state.isSeventhMode,
      ),
      builder: (context, data, _) {
        final chords = data.diatonicChords;
        if (chords.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(Icons.piano,
                      color: Theme.of(context).colorScheme.onSurface, size: 18),
                  const SizedBox(width: 8),
                  Text('Diatonic Chords',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  _buildChordTypeToggle(context, data.isSeventhMode),
                  const SizedBox(width: 12),
                  Tooltip(
                    message: '현재 Key의 다이아토닉 코드 오픈코드 카포 위치 추천',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        final chordNames = chords.map((c) => c.name).toList();
                        CapoModal.show(context, chords: chordNames);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.music_note,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '카포 추천',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 4,
              runSpacing: 8,
              children: chords.asMap().entries.map((e) {
                final index = e.key;
                final chord = e.value;
                final isSelected = index == data.selectedDiatonicIndex;

                return GestureDetector(
                  onTap: () =>
                      context.read<MusicState>().selectDiatonicChord(index),
                  child: Container(
                    width: 76,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor,
                          width: isSelected ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          chord.displayName.isEmpty
                              ? chord.name
                              : chord.displayName,
                          style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(chord.degree,
                            style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withValues(alpha: 0.7)
                                    : Theme.of(context).hintColor,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChordTypeToggle(BuildContext context, bool isSeventh) {
    final theme = Theme.of(context);
    return Container(
      height: 26,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(
            context,
            label: '3화음',
            isSelected: !isSeventh,
            onTap: () => context.read<MusicState>().setSeventhMode(false),
          ),
          _buildToggleOption(
            context,
            label: '7화음',
            isSelected: isSeventh,
            onTap: () => context.read<MusicState>().setSeventhMode(true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
