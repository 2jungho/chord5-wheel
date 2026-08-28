import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/models/chord_model.dart';
import 'package:guitar_theory_app/models/progression/progression_models.dart';
import 'package:guitar_theory_app/services/lyria/virtual_band_sequencer.dart';
import 'package:guitar_theory_app/utils/theory_utils.dart';

void main() {
  group('Dynamic Groove VirtualBandSequencer Tests', () {
    test('Should initialize with correct rhythm parameters and allow start/stop', () {
      final sequencer = VirtualBandSequencer(
        bpm: 128.0,
        style: 'City Pop',
        volume: 0.85,
      );

      expect(sequencer.bpm, 128.0);
      expect(sequencer.style, 'City Pop');
      expect(sequencer.volume, 0.85);
      expect(sequencer.isRunning, isFalse);

      final chord = TheoryUtils.analyzeChord('C');
      final block = ChordBlock(
        chordSymbol: 'C',
        functionTag: 'I',
        duration: 4,
        chordDetail: chord,
        voicing: const ChordVoicing(
          frets: [-1, 3, 2, 0, 1, 0],
          startFret: 1,
          rootString: 5,
        ),
      );

      sequencer.start([block]);
      expect(sequencer.isRunning, isTrue);

      sequencer.stop();
      expect(sequencer.isRunning, isFalse);
    });

    test('Should support updating styles dynamically across all 5 major genres', () {
      final sequencer = VirtualBandSequencer();

      sequencer.updateStyle('Acoustic Ballad');
      expect(sequencer.style, 'Acoustic Ballad');

      sequencer.updateStyle('City Pop');
      expect(sequencer.style, 'City Pop');

      sequencer.updateStyle('Neo-Soul');
      expect(sequencer.style, 'Neo-Soul');

      sequencer.updateStyle('Blues');
      expect(sequencer.style, 'Blues');

      sequencer.updateStyle('Rock');
      expect(sequencer.style, 'Rock');
    });

    test('Should toggle instrument states cleanly', () {
      final sequencer = VirtualBandSequencer();
      expect(sequencer.drumsEnabled, isTrue);
      expect(sequencer.bassEnabled, isTrue);
      expect(sequencer.keysEnabled, isTrue);
      expect(sequencer.guitarEnabled, isTrue);

      sequencer.setInstruments(drums: false, guitar: false);
      expect(sequencer.drumsEnabled, isFalse);
      expect(sequencer.guitarEnabled, isFalse);
      expect(sequencer.bassEnabled, isTrue);
      expect(sequencer.keysEnabled, isTrue);
    });
  });
}
