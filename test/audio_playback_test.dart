import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/models/chord_model.dart';
import 'package:guitar_theory_app/audio/audio_manager.dart';
import 'package:guitar_theory_app/utils/theory_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioManager playback & note parsing tests', () {
    test('AudioManager instance exists and initializes', () async {
      final audioManager = AudioManager();
      expect(audioManager, isNotNull);
      await audioManager.initialize();
    });

    test('AudioManager playStrum runs without error for common chords', () async {
      final audioManager = AudioManager();
      final chord = TheoryUtils.analyzeChord('Am');
      expect(chord.notes, equals(['A', 'C', 'E']));
      await audioManager.playStrum(chord.notes);
    });

    test('AudioManager playVoicing runs without error for barre chord', () async {
      final audioManager = AudioManager();
      // A minor barre chord at 5th fret: [5, 7, 7, 5, 5, 5]
      final voicing = ChordVoicing(
        frets: [5, 7, 7, 5, 5, 5],
        startFret: 5,
        rootString: 6,
        name: 'Em Form',
      );
      await audioManager.playVoicing(voicing, root: 'Am');
    });

    test('AudioManager playNote handles note strings with and without octaves', () async {
      final audioManager = AudioManager();
      await audioManager.playNote('A', 3);
      await audioManager.playNote('C3', 3);
      await audioManager.playNote('Db4', 4);
      await audioManager.playNote('F#', 2);
    });
  });
}
