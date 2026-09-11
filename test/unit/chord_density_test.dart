import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/utils/theory_utils.dart';

void main() {
  group('Chord Quality Conversion Tests (Triad <-> 7th)', () {
    test('convertQuality: Triad to 7th expansion', () {
      // Major to Maj7 (or 7 if dominant)
      expect(ChordUtils.convertQuality('', toSeventh: true), 'Maj7');
      expect(ChordUtils.convertQuality('M', toSeventh: true), 'Maj7');
      expect(ChordUtils.convertQuality('', toSeventh: true, functionTag: 'V'), '7');
      expect(ChordUtils.convertQuality('', toSeventh: true, functionTag: '5'), '7');
      expect(ChordUtils.convertQuality('', toSeventh: true, functionTag: '57'), '7');
      expect(ChordUtils.convertQuality('M', toSeventh: true, functionTag: 'V'), '7');

      // Minor to m7
      expect(ChordUtils.convertQuality('m', toSeventh: true), 'm7');
      expect(ChordUtils.convertQuality('min', toSeventh: true), 'm7');

      // Diminished to m7b5
      expect(ChordUtils.convertQuality('dim', toSeventh: true), 'm7b5');
      expect(ChordUtils.convertQuality('o', toSeventh: true), 'm7b5');

      // Augmented to 7#5
      expect(ChordUtils.convertQuality('aug', toSeventh: true), '7#5');
      expect(ChordUtils.convertQuality('+', toSeventh: true), '7#5');
    });

    test('convertQuality: 7th to Triad simplification', () {
      // Major 7th & Dominant to Triad
      expect(ChordUtils.convertQuality('Maj7', toSeventh: false), '');
      expect(ChordUtils.convertQuality('maj7', toSeventh: false), '');
      expect(ChordUtils.convertQuality('M7', toSeventh: false), '');
      expect(ChordUtils.convertQuality('7', toSeventh: false), '');
      expect(ChordUtils.convertQuality('9', toSeventh: false), '');
      expect(ChordUtils.convertQuality('6', toSeventh: false), '');

      // Minor 7th / extensions to m
      expect(ChordUtils.convertQuality('m7', toSeventh: false), 'm');
      expect(ChordUtils.convertQuality('min7', toSeventh: false), 'm');
      expect(ChordUtils.convertQuality('m9', toSeventh: false), 'm');
      expect(ChordUtils.convertQuality('m11', toSeventh: false), 'm');

      // Half-dim / dim7 to dim
      expect(ChordUtils.convertQuality('m7b5', toSeventh: false), 'dim');
      expect(ChordUtils.convertQuality('dim7', toSeventh: false), 'dim');
      expect(ChordUtils.convertQuality('o7', toSeventh: false), 'dim');

      // Augmented 7th to aug
      expect(ChordUtils.convertQuality('7#5', toSeventh: false), 'aug');
      expect(ChordUtils.convertQuality('aug7', toSeventh: false), 'aug');
    });

    test('convertChordDensity: Full symbol conversion via ChordUtils and TheoryUtils', () {
      expect(ChordUtils.convertChordDensity('C', toSeventh: true), 'CMaj7');
      expect(ChordUtils.convertChordDensity('G', toSeventh: true, functionTag: 'V'), 'G7');
      expect(ChordUtils.convertChordDensity('Dm', toSeventh: true), 'Dm7');
      expect(ChordUtils.convertChordDensity('Bdim', toSeventh: true), 'Bm7b5');
      expect(ChordUtils.convertChordDensity('Caug', toSeventh: true), 'C7#5');

      expect(TheoryUtils.convertChordDensity('CMaj7', toSeventh: false), 'C');
      expect(TheoryUtils.convertChordDensity('G7', toSeventh: false), 'G');
      expect(TheoryUtils.convertChordDensity('Dm7', toSeventh: false), 'Dm');
      expect(TheoryUtils.convertChordDensity('Bm7b5', toSeventh: false), 'Bdim');
    });
  });
}
