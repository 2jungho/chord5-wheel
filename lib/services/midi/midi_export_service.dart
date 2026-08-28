import 'dart:typed_data';
import '../../models/progression/progression_models.dart';
import '../../utils/theory/chord_utils.dart';
import '../../utils/theory/note_utils.dart';
import 'midi_file_writer.dart';
import 'midi_downloader.dart';

class MidiExportService {
  /// Note string to MIDI note number helper (e.g. 'C' at octave 4 -> 60)
  static int _noteToMidiNumber(String noteName, int octave) {
    final idx = NoteUtils.getNoteIndex(noteName);
    return (octave + 1) * 12 + idx;
  }

  /// Convert a progression session into standard Type 1 multi-track MIDI bytes
  static Uint8List exportSessionToMidi(ProgressionSession session) {
    const ppqn = 480; // Ticks per quarter note
    final writer = MidiFileWriter(ticksPerQuarterNote: ppqn);

    final conductor = writer.createTrack('Conductor');
    final drums = writer.createTrack('Drums');
    final bass = writer.createTrack('Bass');
    final keys = writer.createTrack('Keys (Rhodes)');
    final guitar = writer.createTrack('Guitar');

    // 1. Conductor Track
    conductor.addTimeSignature(atTick: 0, numerator: 4, denominator: 4);
    conductor.addTempo(atTick: 0, bpm: session.bpm);

    if (session.progression.isEmpty) {
      return writer.buildMidiFile();
    }

    int currentTick = 0;

    for (var block in session.progression) {
      final chord = ChordUtils.analyzeChord(block.chordSymbol);
      final beats = block.duration > 0 ? block.duration : 4;
      final int blockTicks = beats * ppqn;
      final rootMidiBass = _noteToMidiNumber(chord.root, 2); // Bass octave 2 (36 ~ 47)
      
      // Calculate 5th for bass groove
      final fifthRootIdx = (NoteUtils.getNoteIndex(chord.root) + 7) % 12;
      final fifthNoteName = NoteUtils.getNoteName(fifthRootIdx, true);
      final fifthMidiBass = _noteToMidiNumber(fifthNoteName, 2);

      // Keyboard & Guitar notes in octave 4 & 5
      final chordMidiNotes = chord.notes.map((n) => _noteToMidiNumber(n, 4)).toList();

      // --- Track 1: Drums (Channel 9 / MIDI 10) ---
      for (int b = 0; b < beats; b++) {
        final beatStart = currentTick + (b * ppqn);
        final isDownbeat = (b % 4 == 0 || b % 4 == 2); // Beats 1 & 3
        final isBackbeat = (b % 4 == 1 || b % 4 == 3); // Beats 2 & 4

        // Kick on 1 & 3
        if (isDownbeat) {
          drums.addNoteOn(atTick: beatStart, channel: 9, midiNote: 36, velocity: 100);
          drums.addNoteOff(atTick: beatStart + 120, channel: 9, midiNote: 36);
        }

        // Snare on 2 & 4
        if (isBackbeat) {
          drums.addNoteOn(atTick: beatStart, channel: 9, midiNote: 38, velocity: 105);
          drums.addNoteOff(atTick: beatStart + 120, channel: 9, midiNote: 38);
        }

        // Hi-Hats on 8th notes (every 240 ticks)
        drums.addNoteOn(atTick: beatStart, channel: 9, midiNote: 42, velocity: 80);
        drums.addNoteOff(atTick: beatStart + 100, channel: 9, midiNote: 42);

        final eighthTick = beatStart + (ppqn ~/ 2);
        drums.addNoteOn(atTick: eighthTick, channel: 9, midiNote: 42, velocity: 70);
        drums.addNoteOff(atTick: eighthTick + 100, channel: 9, midiNote: 42);
      }

      // --- Track 2: Bass (Channel 1) ---
      for (int b = 0; b < beats; b++) {
        final beatStart = currentTick + (b * ppqn);
        final note = (b % 4 == 2) ? fifthMidiBass : rootMidiBass;
        bass.addNoteOn(atTick: beatStart, channel: 1, midiNote: note, velocity: 90);
        bass.addNoteOff(atTick: beatStart + (ppqn - 60), channel: 1, midiNote: note);
      }

      // --- Track 3: Keys (Channel 0) ---
      // Sustained chord on beat 1 for entire block
      for (var note in chordMidiNotes) {
        keys.addNoteOn(atTick: currentTick, channel: 0, midiNote: note, velocity: 85);
        keys.addNoteOff(atTick: currentTick + blockTicks - 60, channel: 0, midiNote: note);
      }

      // --- Track 4: Guitar (Channel 2) ---
      // Rhythmic strums on beats
      for (int b = 0; b < beats; b++) {
        final beatStart = currentTick + (b * ppqn);
        int strumOffset = 0;
        for (var note in chordMidiNotes) {
          guitar.addNoteOn(atTick: beatStart + strumOffset, channel: 2, midiNote: note + 12, velocity: 75);
          guitar.addNoteOff(atTick: beatStart + strumOffset + 380, channel: 2, midiNote: note + 12);
          strumOffset += 15; // Realistic strum delay
        }
      }

      currentTick += blockTicks;
    }

    return writer.buildMidiFile();
  }

  /// Export and trigger file download
  static void downloadSessionAsMidi(ProgressionSession session) {
    final midiBytes = exportSessionToMidi(session);
    final sanitizedName = (session.title.isNotEmpty ? session.title : 'chord_progression')
        .replaceAll(RegExp(r'[^\w\s\-]'), '_')
        .replaceAll(' ', '_');
    final filename = '$sanitizedName.mid';
    downloadFileCrossPlatform(filename, midiBytes);
  }
}
