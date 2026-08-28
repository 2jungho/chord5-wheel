import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/models/progression/progression_models.dart';
import 'package:guitar_theory_app/services/midi/midi_export_service.dart';

void main() {
  group('MidiExportService Tests', () {
    test('generate valid MIDI Type 1 file with 5 tracks', () {
      final session = ProgressionSession(
        title: 'Jazz 2-5-1 Test',
        key: 'C Major',
        bpm: 120,
        rhythmPattern: RhythmPattern.presets.first,
        progression: const [
          ChordBlock(chordSymbol: 'Dm7', duration: 4),
          ChordBlock(chordSymbol: 'G7', duration: 4),
          ChordBlock(chordSymbol: 'Cmaj7', duration: 4),
        ],
      );

      final bytes = MidiExportService.exportSessionToMidi(session);

      expect(bytes.isNotEmpty, isTrue);

      // Verify SMF Header 'MThd'
      expect(bytes[0], equals(0x4D)); // 'M'
      expect(bytes[1], equals(0x54)); // 'T'
      expect(bytes[2], equals(0x68)); // 'h'
      expect(bytes[3], equals(0x64)); // 'd'

      // Verify Header length = 6
      expect(bytes[4], equals(0x00));
      expect(bytes[5], equals(0x00));
      expect(bytes[6], equals(0x00));
      expect(bytes[7], equals(0x06));

      // Verify Format = 1
      expect(bytes[8], equals(0x00));
      expect(bytes[9], equals(0x01));

      // Verify Track count = 5
      expect(bytes[10], equals(0x00));
      expect(bytes[11], equals(0x05));
    });
  });
}
