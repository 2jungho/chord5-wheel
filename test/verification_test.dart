import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/models/scale_model.dart';
import 'package:guitar_theory_app/models/music_constants.dart';
import 'package:guitar_theory_app/utils/theory_utils.dart';

void main() {
  test('Character Note Verification', () {
    const root = 'C';
    print('\n--- Character Note Verification (Root: $root) ---\n');

    for (var modeData in MusicConstants.MODES) {
      // 1. Calculate notes
      final notes = TheoryUtils.calculateScaleNotes(root, modeData.name);

      // 2. Create Scale object
      final scale = Scale(
        root: root,
        mode: modeData,
        notes: notes,
        intervals: TheoryUtils.getScaleIntervals(modeData.name),
      );

      // 3. Get Character Note
      final charNote = scale.characterNote;

      // 4. Output
      print('Mode: ${modeData.name}');
      print('Notes: ${notes.join(' ')}');
      print('Character Note: $charNote');

      // Additional verification
      String status = 'OK';
      String expectedCharNote = '';

      switch (modeData.name) {
        case 'Ionian':
          expectedCharNote = 'F';
          break;
        case 'Dorian':
          expectedCharNote = 'A';
          break;
        case 'Phrygian':
          expectedCharNote = 'Db';
          break;
        case 'Lydian':
          expectedCharNote = 'F#';
          break;
        case 'Mixolydian':
          expectedCharNote = 'Bb';
          break;
        case 'Aeolian':
          expectedCharNote = 'Ab';
          break;
        case 'Locrian':
          expectedCharNote = 'Gb';
          break;
      }

      if (charNote != expectedCharNote) {
        status = 'FAIL (Expected $expectedCharNote, Got $charNote)';
      }

      print('Verification: $status');
      print('-------------------------');
    }
  });
}
