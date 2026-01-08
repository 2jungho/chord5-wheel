import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/utils/theory/note_utils.dart';
import 'package:guitar_theory_app/utils/theory/scale_utils.dart';
import 'package:guitar_theory_app/utils/theory/chord_utils.dart';
import 'package:guitar_theory_app/utils/theory/progression_utils.dart';
import 'package:guitar_theory_app/utils/guitar/voicing_generator.dart';

void main() {
  group('NoteUtils Tests', () {
    test('transposeNote', () {
      expect(NoteUtils.transposeNote('C', 2), 'D');
      expect(NoteUtils.transposeNote('C', 1), 'C#');
      expect(NoteUtils.transposeNote('B', 1), 'C');
      expect(NoteUtils.transposeNote('G', 7), 'D');
    });

    test('getNoteIndex', () {
      expect(NoteUtils.getNoteIndex('C'), 0);
      expect(NoteUtils.getNoteIndex('A'), 9);
      expect(NoteUtils.getNoteIndex('Cm'), 0);
    });
  });

  group('ScaleUtils Tests', () {
    test('calculateScaleNotes Ionian', () {
      final notes = ScaleUtils.calculateScaleNotes('C', 'Ionian');
      expect(notes, ['C', 'D', 'E', 'F', 'G', 'A', 'B']);
    });

    test('calculateScaleNotes Dorian', () {
      final notes = ScaleUtils.calculateScaleNotes('D', 'Dorian');
      expect(notes, ['D', 'E', 'F', 'G', 'A', 'B', 'C']);
    });
  });

  group('ChordUtils Tests', () {
    test('parseChordQuality Maj7', () {
      final (intervals, _, isMinor) = ChordUtils.parseChordQuality('Maj7');
      expect(intervals, containsAll(['1', '3', '5', '7']));
      expect(isMinor, false);
    });

    test('parseChordQuality m7', () {
      final (intervals, _, isMinor) = ChordUtils.parseChordQuality('m7');
      expect(intervals, containsAll(['1', 'b3', '5', 'b7']));
      expect(isMinor, true);
    });

    test('analyzeChord Cmaj7', () {
      final chord = ChordUtils.analyzeChord('Cmaj7');
      expect(chord.root, 'C');
      expect(chord.quality, 'maj7');
      expect(chord.notes, containsAll(['C', 'E', 'G', 'B']));
    });
  });

  group('ProgressionUtils Tests', () {
    test('parseProgressionText 2-5-1', () {
      final blocks = ProgressionUtils.parseProgressionText('Dm7-G7-Cmaj7', 'C Major');
      expect(blocks.length, 3);
      expect(blocks[0].chordSymbol, 'Dm7');
      expect(blocks[0].functionTag, 'ii');
      expect(blocks[1].chordSymbol, 'G7');
      expect(blocks[1].functionTag, 'V');
      expect(blocks[2].chordSymbol, 'Cmaj7');
      expect(blocks[2].functionTag, 'I');
    });
  });

  group('VoicingGenerator Tests', () {
    test('calculateChordShape Cmaj7', () {
      final voicing = VoicingGenerator.calculateChordShape('C', 'Maj7');
      expect(voicing.rootString, 5); // Should prefer 5th string for C
      // Expected logic: r5=3. s['r5']=[-1, 0, 2, 1, 2, 0].
      // offsets + root(3): [-1, 3, 5, 4, 5, 3] -> [3, 5, 4, 5, 3] (omitting 6th string mute)
      // frets[0] is 6th string. -1.
      expect(voicing.frets[0], -1);
      expect(voicing.frets[1], 3); // C on A string
    });
  });
}
