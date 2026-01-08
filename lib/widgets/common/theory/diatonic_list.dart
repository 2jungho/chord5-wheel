import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/music_state.dart';
import '../../../models/chord_model.dart';

class DiatonicList extends StatelessWidget {
  const DiatonicList({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<MusicState,
        ({List<Chord> diatonicChords, int selectedDiatonicIndex})>(
      selector: (_, state) => (
        diatonicChords: state.diatonicChords,
        selectedDiatonicIndex: state.selectedDiatonicIndex
      ),
      builder: (context, data, _) {
        final chords = data.diatonicChords;
        if (chords.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.piano,
                    color: Theme.of(context).colorScheme.onSurface, size: 18),
                const SizedBox(width: 8),
                Text('Diatonic Chords',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
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
}
