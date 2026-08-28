import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/services/capo_service.dart';

void main() {
  group('CapoService Tests', () {
    test('transposition for Capo 3 on Eb - Bb - Cm - Ab', () {
      final chords = ['Eb', 'Bb', 'Cm', 'Ab'];
      final options = CapoService.calculateCapoOptions(chords);

      expect(options.length, equals(10)); // 0 to 9

      // Capo 3: Eb - 3 semitones = C, Bb - 3 = G, Cm - 3 = Am, Ab - 3 = F
      final capo3 = options.firstWhere((o) => o.fret == 3);
      expect(capo3.transposedChords, equals(['C', 'G', 'Am', 'F']));
      expect(capo3.openChordCount, greaterThanOrEqualTo(3));
    });

    test('getBestCapoOption finds easy open shapes', () {
      final chords = ['F#m', 'C#m', 'D', 'E'];
      final best = CapoService.getBestCapoOption(chords);

      expect(best, isNotNull);
      expect(best!.fret, greaterThan(0));
    });
  });
}
