import '../lib/models/scale_model.dart';
import '../lib/models/music_constants.dart';
import '../lib/utils/theory_utils.dart';

void main() {
  const root = 'C';
  print('--- Character Note Verification (Root: $root) ---');

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
    print('\nMode: ${modeData.name}');
    print('Notes: ${notes.join(' ')}');
    print('Character Note: $charNote');

    // Additional verification
    String status = 'OK';
    String expectedCharNote = '';

    switch (modeData.name) {
      case 'Ionian':
        expectedCharNote = 'F';
        break; // P4
      case 'Dorian':
        expectedCharNote = 'A';
        break; // M6
      case 'Phrygian':
        expectedCharNote = 'Db';
        break; // b2
      case 'Lydian':
        expectedCharNote = 'F#';
        break; // #4
      case 'Mixolydian':
        expectedCharNote = 'Bb';
        break; // b7
      case 'Aeolian':
        expectedCharNote = 'Ab';
        break; // b6
      case 'Locrian':
        expectedCharNote = 'Gb';
        break; // b5
    }

    if (charNote != expectedCharNote) {
      status = 'FAIL (Expected $expectedCharNote, Got $charNote)';
    }

    print('Verification: $status');
  }
}
