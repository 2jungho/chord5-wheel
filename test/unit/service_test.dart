import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/services/music_theory_service.dart';
import 'package:guitar_theory_app/models/chord_model.dart';
import 'package:guitar_theory_app/models/music_constants.dart';

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
  });
}
