import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/services/harmonic_suggestion_service.dart';

void main() {
  group('HarmonicSuggestionService Tests', () {
    test('suggestions for Dm in C Major include A7 and Eb7', () {
      final suggestions = HarmonicSuggestionService.getSuggestionsForTarget(
        targetChordSymbol: 'Dm',
        currentKey: 'C Major',
      );

      expect(suggestions.isNotEmpty, isTrue);

      final symbols = suggestions.map((s) => s.chordSymbol).toList();
      // Secondary dominant of Dm is A7
      expect(symbols.contains('A7'), isTrue);
      // Tritone substitution of Dm is Eb7
      expect(symbols.contains('Eb7'), isTrue);
      // Passing diminished of Dm is C#dim7
      expect(symbols.contains('C#dim7'), isTrue);
    });

    test('suggestions for C Major include G7 and Bb7 (Backdoor)', () {
      final suggestions = HarmonicSuggestionService.getSuggestionsForTarget(
        targetChordSymbol: 'C',
        currentKey: 'C Major',
      );

      final symbols = suggestions.map((s) => s.chordSymbol).toList();
      expect(symbols.contains('G7'), isTrue);
      expect(symbols.contains('Bb7'), isTrue);
    });
  });
}
