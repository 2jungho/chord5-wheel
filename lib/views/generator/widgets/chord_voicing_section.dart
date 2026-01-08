import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/chord_model.dart';
import '../../../widgets/common/guitar/guitar_chord_widget.dart';
import '../../../widgets/common/chord_detail_dialog.dart';
import '../../../providers/settings_state.dart';

class ChordVoicingSection extends StatelessWidget {
  final String root;
  final String quality;
  final List<String> notes;
  final List<ChordVoicing> voicings;
  final void Function(ChordVoicing) onPlayVoicing;
  final String selectedStyle;
  final ValueChanged<String> onStyleSelected;
  final int? selectedVoicingIndex;
  final ValueChanged<int> onVoicingSelected;

  const ChordVoicingSection({
    super.key,
    required this.root,
    required this.quality,
    required this.notes,
    required this.voicings,
    required this.onPlayVoicing,
    required this.selectedStyle,
    required this.onStyleSelected,
    this.selectedVoicingIndex,
    required this.onVoicingSelected,
  });

  @override
  Widget build(BuildContext context) {
    // SettingsState 구독 추가
    final settings = context.watch<SettingsState>();
    final currentInstrument = settings.selectedInstrument;

    // Define available styles
    final styles = ['CAGED', 'Drop', 'Shell'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recommended Voicings',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12)),
            // Filter Chips
            Row(
              mainAxisSize: MainAxisSize.min,
              children: styles.map((style) {
                final isSelected = style == selectedStyle;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor:
                          Colors.transparent, // remove bg for clean look
                    ),
                    child: ChoiceChip(
                      label: Text(style),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      selected: isSelected,
                      onSelected: (_) => onStyleSelected(style),
                      selectedColor: Theme.of(context).colorScheme.primary,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      showCheckmark: false,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: voicings.isEmpty
              ? Center(
                  child: Text(
                    'No voicings found for this style.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: voicings.length,
                  itemBuilder: (context, index) {
                    final voicing = voicings[index];
                    final isSelected = index == selectedVoicingIndex;

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () => onVoicingSelected(index),
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (context) => ChordDetailDialog(
                              root: root,
                              quality: quality,
                              voicing: voicing,
                              notes: notes,
                              onPlay: () => onPlayVoicing(voicing),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 140, // Increased width for horizontal diagram
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2)
                                : Border.all(
                                    color: Theme.of(context)
                                        .dividerColor
                                        .withValues(alpha: 0.8)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                voicing.name ?? '',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${voicing.startFret}fr',
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 100, // Reduced height
                                width: 130, // Increased width
                                child: CustomPaint(
                                  painter: GuitarChordPainter(
                                    voicing: voicing,
                                    isMainChord: false,
                                    stringCount: currentInstrument
                                        .stringCount, // stringCount 전달
                                    colorScheme: Theme.of(context).colorScheme,
                                    dividerColor:
                                        Theme.of(context).dividerColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
