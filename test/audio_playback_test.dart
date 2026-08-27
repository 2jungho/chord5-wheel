import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/models/chord_model.dart';
import 'package:guitar_theory_app/audio/audio_manager.dart';
import 'package:guitar_theory_app/audio/virtual_band_synth.dart';
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

    test('VirtualBandSynth generates valid WAV buffers for drums, bass, keys', () {
      final kick = VirtualBandSynth.generateKick();
      expect(kick.length, greaterThan(44)); // Has RIFF + data
      expect(String.fromCharCodes(kick.sublist(0, 4)), equals('RIFF'));

      final snare = VirtualBandSynth.generateSnare();
      expect(snare.length, greaterThan(44));
      expect(String.fromCharCodes(snare.sublist(0, 4)), equals('RIFF'));

      final hihatClosed = VirtualBandSynth.generateHiHatClosed();
      expect(hihatClosed.length, greaterThan(44));

      final bass = VirtualBandSynth.generateBassNote(55.0); // A1
      expect(bass.length, greaterThan(44));

      final keys = VirtualBandSynth.generateKeyboardNote(261.63); // C4
      expect(keys.length, greaterThan(44));
    });

    test('VirtualBandSynth noteToFrequency produces accurate frequencies', () {
      expect(VirtualBandSynth.noteToFrequency('A', 4), closeTo(440.0, 0.01));
      expect(VirtualBandSynth.noteToFrequency('C', 4), closeTo(261.63, 0.01));
      expect(VirtualBandSynth.noteToFrequency('A', 2), closeTo(110.0, 0.01));
    });
  });
}

