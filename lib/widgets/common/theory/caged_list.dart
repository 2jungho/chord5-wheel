import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/music_state.dart';
import '../../../models/chord_model.dart';
import '../../../utils/theory_utils.dart';

import '../../../audio/audio_manager.dart';
import '../guitar/guitar_chord_widget.dart';
import '../../../models/caged_model.dart';
import '../../../providers/settings_state.dart';

import '../../../models/instrument_model.dart';
import '../../common/piano/piano_inversion_list.dart';

class CagedList extends StatefulWidget {
  const CagedList({super.key});

  @override
  State<CagedList> createState() => _CagedListState();
}

class _CagedListState extends State<CagedList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SettingsState 구독: 악기 변경에 따른 리빌드
    final settings = context.watch<SettingsState>();
    final currentInstrument = settings.selectedInstrument;

    // 피아노 선택 시 CAGED 대신 Inversion List 표시
    if (currentInstrument.type == InstrumentType.piano) {
      return const PianoInversionList();
    }

    return Selector<MusicState,
        ({Chord selectedChord, String? selectedCagedPatternName})>(
      selector: (_, state) => (
        selectedChord: state.selectedChord,
        selectedCagedPatternName: state.selectedCagedPatternName
      ),
      builder: (context, data, _) {
        final chord = data.selectedChord;
        final isMinor =
            chord.quality.contains('m') && !chord.quality.contains('Maj');

        // Use Actual Root (No Relative Minor conversion)
        int rootIdx = TheoryUtils.getNoteIndex(chord.root);
        // E string Reference Fret (0-11)
        int rootFretOnE = (rootIdx - 4 + 12) % 12;

        // Select Patterns
        final patterns = isMinor ? minorCagedPatterns : majorCagedPatterns;

        // Calculate and Sort
        final displayItems = patterns.map((pattern) {
          int startFret = rootFretOnE + pattern.baseOffset;
          // Normalize Octave (0-12 prefered)
          while (startFret > 12) {
            startFret -= 12;
          }
          // Calculate Voicing immediately for display
          final result = _calculateCagedVoicing(pattern, startFret, isMinor);

          return _CagedItemData(pattern, startFret, result);
        }).toList();

        displayItems.sort((a, b) => a.startFret.compareTo(b.startFret));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('🔥 CAGED System',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                if (chord.displayName.isNotEmpty)
                  Text(' : ${chord.displayName}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),
            Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 12), // 스크롤바 공간 확보
                child: Row(
                  children: displayItems.map((item) {
                    final isSelected =
                        data.selectedCagedPatternName == item.pattern.name;
                    return _CagedItem(
                      data: item,
                      isSelected: isSelected,
                      stringCount: currentInstrument.stringCount,
                      onTap: () {
                        // Use context.read inside the callback
                        final state = context.read<MusicState>();
                        _handleTap(context, state, item);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleTap(BuildContext context, MusicState state, _CagedItemData item) {
    state.selectCagedPattern(
        item.pattern.name, item.pattern.cagedName); // 패턴 선택 상태 업데이트
    state.setCustomVoicing(item.result.voicing);
    AudioManager().playStrum(item.result.notes);
  }

  _CagedResult _calculateCagedVoicing(
      CagedPattern pattern, int startFret, bool isMinor) {
    List<int> frets = [-1, -1, -1, -1, -1, -1];
    List<String> notes = [];

    // All dots in pattern are valid chord tones now
    for (var dot in pattern.dots) {
      int strIdx = 6 - dot.s;
      int realFret = startFret + dot.o;
      if (frets[strIdx] == -1) {
        frets[strIdx] = realFret;
      }
    }

    // Min Fret logic (for display start)
    int minFret = 999;
    int maxFret = -1;
    for (int f in frets) {
      if (f != -1) {
        if (f < minFret) minFret = f;
        if (f > maxFret) maxFret = f;
      }
    }

    // Auto-Shift Logic:
    // If we have a wide stretch or high fret, try to frame it nicely.
    // Standard box is 5 frets.
    // If minFret is the "start", we show minFret to minFret+4.
    // Ensure this covers all notes if possible.
    int finalStartFret =
        minFret != 999 ? minFret : (startFret > 0 ? startFret : 1);
    // If any note is below finalStartFret (impossible if min is min)
    // If any note is > finalStartFret + 4, we might need to adjust, but usually minFret is best start.
    // Exception: Open strings (fret 0).
    // If we have fret 0, startFret usually should be 1 (and 0 is drawn as open).
    if (minFret == 0) finalStartFret = 1;

    // Collect Notes
    for (int i = 0; i < 6; i++) {
      if (frets[i] != -1) {
        final tuningIndices = [4, 9, 2, 7, 11, 4]; // E A D G B E
        int noteIdx = (tuningIndices[i] + frets[i]) % 12;
        notes.add(TheoryUtils.getNoteName(noteIdx, true));
      }
    }

    return _CagedResult(
      voicing: ChordVoicing(
        frets: frets,
        startFret: finalStartFret,
        rootString: pattern.rootString,
        name: pattern.cagedName,
      ),
      notes: notes,
    );
  }
}

class _CagedItemData {
  final CagedPattern pattern;
  final int startFret;
  final _CagedResult result;
  _CagedItemData(this.pattern, this.startFret, this.result);
}

class _CagedResult {
  final ChordVoicing voicing;
  final List<String> notes;
  _CagedResult({required this.voicing, required this.notes});
}

class _CagedItem extends StatelessWidget {
  final _CagedItemData data;
  final bool isSelected;
  final int stringCount;
  final VoidCallback onTap;

  const _CagedItem({
    required this.data,
    this.isSelected = false,
    this.stringCount = 6,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100, // Slightly wider to fit unified painter
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2)
              : Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.8)),
        ),
        child: Column(
          children: [
            Text(data.pattern.cagedName,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            Text(
                '${data.result.voicing.startFret}fr', // Use actual voicing start fret
                style: TextStyle(
                    color: Theme.of(context).hintColor, fontSize: 10)),
            const SizedBox(height: 8),
            SizedBox(
              height: 90, // Reduced height for horizontal widget
              width: 120, // Increased width
              child: CustomPaint(
                painter: GuitarChordPainter(
                  voicing: data.result.voicing,
                  isMainChord: false,
                  stringCount: stringCount,
                  colorScheme: Theme.of(context).colorScheme,
                  dividerColor: Theme.of(context).dividerColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
