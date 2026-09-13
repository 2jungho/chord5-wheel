import '../../../audio/audio_manager.dart';
import '../../../models/chord_model.dart';
import '../../../utils/theory_utils.dart';

/// Bass line pattern generator for Virtual Band accompaniment styles.
class BandBassPatterns {
  const BandBassPatterns._();

  /// Plays bass notes corresponding to the given style and 16-step sequencer step.
  static void play(String style, int step, Chord detail, double vol) {
    final root = detail.root;
    final notes = detail.notes;
    final fifth = notes.length >= 3 ? notes[2] : root;
    final third = notes.length >= 2 ? notes[1] : root;

    switch (style) {
      case 'Rock':
        // Driving 8th notes on Root with 5th accent on 12
        if (step % 2 == 0) {
          if (step == 12) {
            AudioManager().playBassNote(fifth, 2, volume: vol * 0.80);
          } else {
            AudioManager().playBassNote(root, 2, volume: vol * 0.85);
          }
        }
        break;

      case 'Neo-Soul':
        // Melodic walking bassline: Deep Root on 0, 5th on 6, Upper Octave on 11
        if (step == 0) {
          AudioManager().playBassNote(root, 2, volume: vol * 0.85);
        } else if (step == 6) {
          AudioManager().playBassNote(fifth, 2, volume: vol * 0.75);
        } else if (step == 11) {
          AudioManager().playBassNote(root, 3, volume: vol * 0.70);
        }
        break;

      case 'Jazz Funk':
        // Syncopated funk bass: Root on 0, 3; Octave on 6; 5th on 10; Leading note on 14
        if (step == 0 || step == 3) {
          AudioManager().playBassNote(root, 2, volume: vol * 0.85);
        } else if (step == 6) {
          AudioManager().playBassNote(root, 3, volume: vol * 0.80);
        } else if (step == 10) {
          AudioManager().playBassNote(fifth, 2, volume: vol * 0.75);
        } else if (step == 14) {
          AudioManager().playBassNote(third, 2, volume: vol * 0.70);
        }
        break;

      case 'Blues':
        // Walking Blues Bass: Beat 1 (0) Root -> Beat 2 (4) 3rd -> Beat 3 (8) 5th -> Beat 4 (12) 6th
        if (step == 0) {
          AudioManager().playBassNote(root, 2, volume: vol * 0.85);
        } else if (step == 4) {
          AudioManager().playBassNote(third, 2, volume: vol * 0.80);
        } else if (step == 8) {
          AudioManager().playBassNote(fifth, 2, volume: vol * 0.80);
        } else if (step == 12) {
          final sixthNote = TheoryUtils.transposeNote(root, 9);
          AudioManager().playBassNote(sixthNote, 2, volume: vol * 0.75);
        }
        break;

      case 'City Pop':
        // Disco Octave Slap Bass: Low Root on 0, 4, 8, 12; High Octave on 2, 6, 10, 14
        if (step == 0 || step == 4 || step == 8 || step == 12) {
          AudioManager().playBassNote(root, 2, volume: vol * 0.85);
        } else if (step == 2 || step == 6 || step == 10 || step == 14) {
          AudioManager().playBassNote(root, 3, volume: vol * 0.75);
        }
        break;

      case 'Lofi Chill':
      case 'Acoustic Ballad':
      default:
        // Deep Warm Sustained Root on Beat 1 (0), 5th on Beat 3 (8)
        if (step == 0) {
          AudioManager().playBassNote(root, 2, volume: vol * 0.80);
        } else if (step == 8) {
          AudioManager().playBassNote(fifth, 2, volume: vol * 0.70);
        }
        break;
    }
  }
}
