import '../../../audio/audio_manager.dart';
import '../../../models/chord_model.dart';

/// Keyboard / Electric piano chord pattern generator for Virtual Band accompaniment styles.
class BandKeysPatterns {
  const BandKeysPatterns._();

  /// Plays keyboard notes/chords corresponding to the given style and 16-step sequencer step.
  static void play(String style, int step, Chord detail, double vol) {
    final chordNotes = detail.notes.isNotEmpty ? detail.notes : [detail.root];

    switch (style) {
      case 'Acoustic Ballad':
        // Elegant Piano Arpeggio:
        // Step 0: Warm Root & 5th chord backing
        // Step 6: Mid-voicing melody note
        // Step 10: Treble melody sparkle
        // Step 14: Harmonic transition note
        if (step == 0) {
          AudioManager().playKeyboardChord(chordNotes, octave: 3, volume: vol * 0.70);
        } else if (step == 6 && chordNotes.length >= 2) {
          AudioManager().playKeyboardNote(chordNotes[1], 4, volume: vol * 0.55);
        } else if (step == 10 && chordNotes.length >= 3) {
          AudioManager().playKeyboardNote(chordNotes[2], 4, volume: vol * 0.60);
        } else if (step == 14 && chordNotes.isNotEmpty) {
          AudioManager().playKeyboardNote(chordNotes[0], 4, volume: vol * 0.45);
        }
        break;

      case 'City Pop':
      case 'Jazz Funk':
        // Syncopated 80s Rhodes / Synth Brass Stabs:
        // Steps 3, 6, 11: Punchy offbeat stabs
        if (step == 3 || step == 6 || step == 11) {
          AudioManager().playKeyboardChord(chordNotes, octave: 4, volume: vol * 0.72);
        }
        break;

      case 'Neo-Soul':
      case 'Lofi Chill':
        // Lush Fender Rhodes Comping:
        // Step 0: Deep warm root chord
        // Step 6: Laid-back offbeat 9th/11th chord swell
        // Step 10: High bell sparkle
        if (step == 0) {
          AudioManager().playKeyboardChord(chordNotes, octave: 3, volume: vol * 0.65);
        } else if (step == 6) {
          AudioManager().playKeyboardChord(chordNotes, octave: 4, volume: vol * 0.60);
        } else if (step == 10 && chordNotes.length >= 2) {
          AudioManager().playKeyboardNote(chordNotes.last, 4, volume: vol * 0.55);
        }
        break;

      case 'Blues':
        // Hammond Organ Backbeat & Leslie Swells on 4 & 12:
        if (step == 0) {
          AudioManager().playKeyboardChord(chordNotes, octave: 3, volume: vol * 0.60);
        } else if (step == 4 || step == 12) {
          AudioManager().playKeyboardChord(chordNotes, octave: 4, volume: vol * 0.75);
        }
        break;

      case 'Rock':
      default:
        // Heavy Rock Organ / Piano Wall of Sound on 0 & 8:
        if (step == 0 || step == 8) {
          AudioManager().playKeyboardChord(chordNotes, octave: 3, volume: vol * 0.70);
        }
        break;
    }
  }
}
