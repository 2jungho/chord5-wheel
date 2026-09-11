import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/services/music_theory_service.dart';
import 'package:guitar_theory_app/models/chord_model.dart';
import 'package:guitar_theory_app/models/progression/progression_models.dart';

void main() {
  group('MusicTheoryService Tests', () {
    test('calculateKeyContext C Major', () {
      final (scale, chords) = MusicTheoryService.calculateKeyContext(0, 1, false); // C Key, Ionian Mode
      
      expect(scale.root, 'C');
      expect(scale.mode.name, 'Ionian');
      expect(scale.notes, ['C', 'D', 'E', 'F', 'G', 'A', 'B']);
      
      expect(chords.length, 7);
      expect(chords[0].root, 'C');
      expect(chords[0].quality, 'Maj7');
    });

    test('findBestCagedPattern C Major', () {
      final chord = Chord(root: 'C', quality: 'Maj7');
      final result = MusicTheoryService.findBestCagedPattern(chord);
      
      expect(result, isNotNull);
      final (patternName, voicing) = result!;
      
      // C Major best pattern is usually C Form or similar low fret?
      // Root C is fret 8 on E string.
      // C Form (Root 5) -> fret 3.
      // E Form (Root 6) -> fret 8.
      // A Form (Root 5) -> fret 3 (same as C form location approximately? No, A form root is string 5).
      // Root C on String 5 is fret 3.
      // A Form baseOffset 7. 3 + 7 = 10? No.
      // Let's trace:
      // Root C index 0.
      // RootFretOnE = (0 - 4 + 12)%12 = 8.
      
      // E Form: 8 + 0 = 8.
      // D Form: 8 + 2 = 10.
      // C Form: 8 + 4 = 12 -> 0. (Open C!)
      // A Form: 8 + 7 = 15 -> 3.
      // G Form: 8 + 9 = 17 -> 5.
      
      // Lowest positive? 0 is lowest.
      // If startFret 0, pattern C Form.
      
      expect(patternName, "Position 3"); // C Form
      expect(voicing.name, "C Form");
    });

    test('buildChordBlock creates valid ChordBlock with voicing and detail', () {
      final block = MusicTheoryService.buildChordBlock(
        chordSymbol: 'C',
        key: 'C Major',
        style: 'E',
      );

      expect(block.chordSymbol, 'C');
      expect(block.chordDetail?.root, 'C');
      expect(block.chordDetail?.quality, '');
      expect(block.functionTag, 'I');
      expect(block.voicing, isNotNull);
    });

    test('findBestVoicingForStyle selects appropriate voicing by form and auto', () {
      final voicings = [
        ChordVoicing(frets: [-1, 3, 2, 0, 1, 0], startFret: 1, rootString: 5, name: 'C Form'),
        ChordVoicing(frets: [8, 10, 10, 9, 8, 8], startFret: 8, rootString: 6, name: 'E Form'),
      ];

      // Auto without previous: returns first
      final autoFirst = MusicTheoryService.findBestVoicingForStyle(
        voicings,
        'Auto',
        key: 'C Major',
      );
      expect(autoFirst?.name, 'C Form');

      // Auto with previous at fret 7: should pick E Form at fret 8 (distance 1 vs 6)
      final previous = ChordVoicing(frets: [], startFret: 7, rootString: 6);
      final autoClose = MusicTheoryService.findBestVoicingForStyle(
        voicings,
        'Auto',
        key: 'C Major',
        previousVoicing: previous,
      );
      expect(autoClose?.name, 'E Form');
    });

    test('remapProgression handles mode changes and same-mode transposition', () {
      final blocks = [
        ChordBlock(chordSymbol: 'C', duration: 4, functionTag: 'I'),
        ChordBlock(chordSymbol: 'F', duration: 4, functionTag: 'IV'),
        ChordBlock(chordSymbol: 'G', duration: 4, functionTag: 'V'),
      ];

      // 1. Same mode transposition: C Major -> D Major (+2 semitones)
      final transposed = MusicTheoryService.remapProgression(
        progression: blocks,
        oldKey: 'C Major',
        newKey: 'D Major',
      );
      expect(transposed[0].chordSymbol, 'D');
      expect(transposed[1].chordSymbol, 'G');
      expect(transposed[2].chordSymbol, 'A');

      // 2. Mode change: C Major -> A Minor (I, IV, V -> i, iv, v)
      final remappedMode = MusicTheoryService.remapProgression(
        progression: blocks,
        oldKey: 'C Major',
        newKey: 'A Minor',
      );
      expect(remappedMode[0].chordSymbol, 'Am7'); // Diatonic 1 in Aeolian
      expect(remappedMode[1].chordSymbol, 'Dm7'); // Diatonic 4 in Aeolian
      expect(remappedMode[2].chordSymbol, 'E7'); // Harmonic Minor Dominant V7 in Aeolian
      expect(remappedMode[0].functionTag, 'i');
      expect(remappedMode[1].functionTag, 'iv');
      expect(remappedMode[2].functionTag, 'v');

      // 3. Non-diatonic fallback across mode change
      final nonDiatonicBlocks = [
        ChordBlock(chordSymbol: 'F#', duration: 4), // F# is non-diatonic in C Major
      ];
      final nonDiatonicResult = MusicTheoryService.remapProgression(
        progression: nonDiatonicBlocks,
        oldKey: 'C Major',
        newKey: 'D Minor', // +2 semitones
      );
      // F# + 2 semitones = G#
      expect(nonDiatonicResult[0].chordSymbol, 'G#');
    });
  });
}
