import 'models/scale_model.dart';
import 'models/music_constants.dart';
import 'utils/theory_utils.dart';

void main() {
  const root = 'C';
  print('--- Character Note Verification (Root: $root) ---\n');

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

    // Simple expected Logic check (Hardcoded for C root)
    switch (modeData.name) {
      case 'Ionian':
        expectedCharNote = 'F';
        break; // P4 (Note: Code uses index 3)
      case 'Dorian':
        expectedCharNote = 'A';
        break; // M6 (C Dorian: C D Eb F G A Bb) -> 6th note is A
      case 'Phrygian':
        expectedCharNote = 'Db';
        break; // b2 (C Phrygian: C Db Eb F G Ab Bb) -> 2nd note is Db
      case 'Lydian':
        expectedCharNote = 'F#';
        break; // #4 (C Lydian: C D E F# G A B) -> 4th note is F#
      case 'Mixolydian':
        expectedCharNote = 'Bb';
        break; // b7 (C Mixolydian: C D E F G A Bb) -> 7th note is Bb
      case 'Aeolian':
        expectedCharNote = 'Ab';
        break; // b6 (C Aeolian: C D Eb F G Ab Bb) -> 6th note is Ab
      case 'Locrian':
        expectedCharNote = 'Gb';
        break; // b5 (C Locrian: C Db Eb F Gb Ab Bb) -> 5th note is Gb
    }

    if (charNote != expectedCharNote) {
      status = 'FAIL (Expected $expectedCharNote, Got $charNote)';
    }

    print('Verification: $status');
    print('-------------------------');
  }
}
