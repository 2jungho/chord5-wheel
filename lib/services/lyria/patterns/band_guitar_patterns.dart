import '../../../audio/audio_manager.dart';
import '../../../models/chord_model.dart';
import '../../../models/progression/progression_models.dart';

/// Guitar accompaniment pattern generator with style-specific fingerpicking & chucking for Virtual Band.
class BandGuitarPatterns {
  const BandGuitarPatterns._();

  /// Plays guitar notes/voicings corresponding to the given style and 16-step sequencer step.
  static void play(String style, int step, ChordBlock block, Chord detail, double vol) {
    final voicing = block.voicing;
    final notes = detail.notes.isNotEmpty ? detail.notes : [detail.root];
    final rootSym = block.chordSymbol;

    switch (style) {
      case 'Acoustic Ballad':
        // Real Travis / Folk Fingerpicking pattern:
        // Step 0 (Beat 1): Root Bass Note (String 6 or 5)
        // Step 4 (Beat 2): String 3 (G String picking)
        // Step 8 (Beat 3): Treble Pinch (Strings 1 & 2 together)
        // Step 12 (Beat 4): String 4 (D String middle fill)
        if (step == 0) {
          if (voicing != null) {
            final bassStringIdx = (voicing.frets[0] != -1) ? 0 : 1;
            AudioManager().playVoicingString(voicing, bassStringIdx, root: rootSym, volume: vol * 0.85);
          } else {
            AudioManager().playNote(notes[0], 2);
          }
        } else if (step == 4) {
          if (voicing != null) {
            AudioManager().playVoicingString(voicing, 3, root: rootSym, volume: vol * 0.70);
          } else if (notes.length > 1) {
            AudioManager().playNote(notes[1], 3);
          }
        } else if (step == 8) {
          if (voicing != null) {
            AudioManager().playVoicingPinch(voicing, root: rootSym, volume: vol * 0.75);
          } else {
            AudioManager().playStrum(notes.sublist(notes.length > 2 ? 1 : 0));
          }
        } else if (step == 12) {
          if (voicing != null) {
            AudioManager().playVoicingString(voicing, 2, root: rootSym, volume: vol * 0.65);
          } else if (notes.length > 2) {
            AudioManager().playNote(notes[2], 3);
          }
        }
        break;

      case 'City Pop':
      case 'Jazz Funk':
        // 16-Beat Syncopated Funk Chucking & Staccato Cutting:
        // Steps 2, 6, 10, 14: Rhythmic Offbeat Chucks & Accents
        // Step 0: Downbeat Push
        if (step == 0) {
          if (voicing != null) {
            AudioManager().playStaccatoVoicing(voicing, root: rootSym, volume: vol * 0.75);
          } else {
            AudioManager().playStrum(notes);
          }
        } else if (step == 6 || step == 10) {
          // Sharp Staccato Offbeat Cut
          if (voicing != null) {
            AudioManager().playStaccatoVoicing(voicing, root: rootSym, volume: vol * 0.80);
          } else {
            AudioManager().playStrum(notes);
          }
        } else if (step == 14) {
          // Ghost 16th-note pick into next bar
          if (voicing != null) {
            AudioManager().playVoicingPinch(voicing, root: rootSym, volume: vol * 0.60);
          }
        }
        break;

      case 'Neo-Soul':
      case 'Lofi Chill':
        // Laid-Back Swinging Comping:
        // Step 0: Soft Root Arpeggio / Voicing
        // Step 6: Swing offbeat chord stab
        // Step 10: High tension pinch
        // Step 14: Soft passing strum
        if (step == 0) {
          if (voicing != null) {
            AudioManager().playVoicing(voicing, root: rootSym);
          } else {
            AudioManager().playStrum(notes);
          }
        } else if (step == 6) {
          if (voicing != null) {
            AudioManager().playStaccatoVoicing(voicing, root: rootSym, volume: vol * 0.65);
          } else {
            AudioManager().playStrum(notes);
          }
        } else if (step == 10) {
          if (voicing != null) {
            AudioManager().playVoicingPinch(voicing, root: rootSym, volume: vol * 0.70);
          }
        } else if (step == 14) {
          if (voicing != null) {
            AudioManager().playVoicingString(voicing, 3, root: rootSym, volume: vol * 0.55);
          }
        }
        break;

      case 'Blues':
        // Chicago Blues 12-bar Shuffle Strum:
        // Step 4 (Beat 2) & Step 12 (Beat 4): Heavy Backbeat Strum
        // Step 6 & Step 14: Swung Upbeat Ghost
        if (step == 0) {
          if (voicing != null) {
            AudioManager().playVoicing(voicing, root: rootSym);
          } else {
            AudioManager().playStrum(notes);
          }
        } else if (step == 4 || step == 12) {
          if (voicing != null) {
            AudioManager().playVoicing(voicing, root: rootSym);
          } else {
            AudioManager().playStrum(notes);
          }
        } else if (step == 6 || step == 14) {
          if (voicing != null) {
            AudioManager().playVoicingPinch(voicing, root: rootSym, volume: vol * 0.60);
          }
        }
        break;

      case 'Rock':
      default:
        // Driving 8-beat down/up power rhythm:
        // Step 0 (Beat 1), Step 4 (Beat 2), Step 8 (Beat 3), Step 10 (Syncopated Up), Step 12 (Beat 4)
        if (step == 0 || step == 4 || step == 8 || step == 12) {
          if (voicing != null) {
            AudioManager().playVoicing(voicing, root: rootSym);
          } else {
            AudioManager().playStrum(notes);
          }
        } else if (step == 10) {
          if (voicing != null) {
            AudioManager().playStaccatoVoicing(voicing, root: rootSym, volume: vol * 0.70);
          }
        }
        break;
    }
  }
}
