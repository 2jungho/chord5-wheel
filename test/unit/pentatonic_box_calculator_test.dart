import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/utils/guitar/pentatonic_box_calculator.dart';

void main() {
  group('PentatonicBoxCalculator Tests', () {
    test('calculate 5 boxes for A Minor (should have Box 1 at fret 5)', () {
      final boxes = PentatonicBoxCalculator.getBoxesForKey('A', true);

      expect(boxes.length, equals(5));

      final box1 = boxes.firstWhere((b) => b.boxNumber == 1);
      // A Minor root is A (note 9). 6th string E is note 4.
      // (9 - 4 + 12) % 12 = 5th fret.
      expect(box1.startFret, equals(5));
      expect(box1.endFret, equals(8));
    });

    test('calculate 5 boxes for C Major (Relative minor = A Minor, Box 1 at fret 5)', () {
      final boxes = PentatonicBoxCalculator.getBoxesForKey('C', false);

      expect(boxes.length, equals(5));

      final box1 = boxes.firstWhere((b) => b.boxNumber == 1);
      expect(box1.startFret, equals(5));
      expect(box1.endFret, equals(8));
      expect(box1.rootNote, equals('A'));
    });

    test('generateBoxMarkers contains blue note b5 and root notes in box 1', () {
      final markers = PentatonicBoxCalculator.generateBoxMarkers(
        keyRoot: 'A',
        isMinorKey: true,
        boxNumber: 1,
      );

      expect(markers.isNotEmpty, isTrue);

      // Verify that markers exist on all 6 strings within frets 5-8
      bool foundBlueNote = false;
      bool foundRoot = false;

      for (var stringMarkers in markers.values) {
        for (var m in stringMarkers) {
          if (m.interval == 'b5') foundBlueNote = true;
          if (m.interval == '1P') foundRoot = true;
        }
      }

      expect(foundBlueNote, isTrue, reason: 'Box 1 should include the b5 blue note');
      expect(foundRoot, isTrue, reason: 'Box 1 should include root notes (1P)');
    });
  });
}
