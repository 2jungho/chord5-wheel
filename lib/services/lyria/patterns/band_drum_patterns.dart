import '../../../audio/audio_manager.dart';
import '../../../audio/virtual_band_synth.dart';

/// 가상 밴드 드럼 연주 패턴 생성기
class BandDrumPatterns {
  static void play(String style, int step, double vol) {
    switch (style) {
      case 'Rock':
        // Driving Rock: Punchy downbeat Kick (0, 8, 10); Crack Snare on 4, 12; Ghost on 15; 8th Hats
        if (step == 0 || step == 8 || step == 10) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.95);
        }
        if (step == 4 || step == 12) {
          AudioManager().playDrum(DrumSound.snare, volume: vol * 0.90);
        } else if (step == 15) {
          AudioManager().playDrum(DrumSound.snare, volume: vol * 0.35); // Ghost note
        }
        if (step % 2 == 0) {
          if (step == 14) {
            AudioManager().playDrum(DrumSound.hiHatOpen, volume: vol * 0.65);
          } else {
            AudioManager().playDrum(DrumSound.hiHatClosed,
                volume: (step % 4 == 0 ? vol * 0.70 : vol * 0.50));
          }
        }
        break;

      case 'Neo-Soul':
        // Dilla-style syncopated pocket: Kick on 0, 6, 11; Snappy Rimshot on 4, 12 + ghost 15; Dynamic 16th hats
        if (step == 0) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.85);
        } else if (step == 6 || step == 11) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.75);
        }
        if (step == 4 || step == 12) {
          AudioManager().playDrum(DrumSound.rimshot, volume: vol * 0.85);
        } else if (step == 7 || step == 15) {
          AudioManager().playDrum(DrumSound.rimshot, volume: vol * 0.30); // Subtle ghost rim
        }
        if (step % 2 == 0 || step == 3 || step == 7) {
          if (step == 14) {
            AudioManager().playDrum(DrumSound.hiHatOpen, volume: vol * 0.55);
          } else {
            AudioManager().playDrum(DrumSound.hiHatClosed,
                volume: (step % 4 == 2 ? vol * 0.60 : vol * 0.40));
          }
        }
        break;

      case 'Jazz Funk':
        // Tight 16th funk pocket: Kick on 0, 3, 6, 10; Snare backbeat on 4, 12 + ghost 7, 13, 15
        if (step == 0 || step == 10) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.90);
        } else if (step == 3 || step == 6) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.75);
        }
        if (step == 4 || step == 12) {
          AudioManager().playDrum(DrumSound.snare, volume: vol * 0.85);
        } else if (step == 7 || step == 13 || step == 15) {
          AudioManager().playDrum(DrumSound.snare, volume: vol * 0.35); // Funk ghost notes
        }
        if (step == 14) {
          AudioManager().playDrum(DrumSound.hiHatOpen, volume: vol * 0.65);
        } else {
          AudioManager().playDrum(DrumSound.hiHatClosed,
              volume: (step % 2 == 0 ? vol * 0.60 : vol * 0.40));
        }
        break;

      case 'Lofi Chill':
        // Warm boom-bap: Low warm kick on 0, 7; Vintage wood snare on 4, 12; Soft 8th hats
        if (step == 0) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.80);
        } else if (step == 7) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.70);
        }
        if (step == 4 || step == 12) {
          AudioManager().playDrum(DrumSound.snare, volume: vol * 0.75);
        }
        if (step % 2 == 0) {
          if (step == 14) {
            AudioManager().playDrum(DrumSound.hiHatOpen, volume: vol * 0.45);
          } else {
            AudioManager().playDrum(DrumSound.hiHatClosed,
                volume: (step % 4 == 0 ? vol * 0.45 : vol * 0.30));
          }
        }
        break;

      case 'Blues':
        // 12/8 Triplet shuffle: Kick on 0, 8; Snare on 4, 12; Swung hats on triplet grid
        if (step == 0 || step == 8) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.85);
        }
        if (step == 4 || step == 12) {
          AudioManager().playDrum(DrumSound.snare, volume: vol * 0.80);
        }
        if (step == 0 ||
            step == 3 ||
            step == 4 ||
            step == 7 ||
            step == 8 ||
            step == 11 ||
            step == 12 ||
            step == 15) {
          AudioManager().playDrum(DrumSound.hiHatClosed,
              volume: (step % 4 == 0 ? vol * 0.60 : vol * 0.40));
        }
        break;

      case 'City Pop':
        // Disco 4-on-the-floor Kick (0, 4, 8, 12); Snare on 4, 12; Shimmering open hats on offbeats (2, 6, 10, 14)
        if (step == 0 || step == 4 || step == 8 || step == 12) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.90);
        }
        if (step == 4 || step == 12) {
          AudioManager().playDrum(DrumSound.snare, volume: vol * 0.85);
        }
        if (step == 2 || step == 6 || step == 10 || step == 14) {
          AudioManager().playDrum(DrumSound.hiHatOpen, volume: vol * 0.65);
        } else {
          AudioManager().playDrum(DrumSound.hiHatClosed, volume: vol * 0.45);
        }
        break;

      case 'Acoustic Ballad':
      default:
        // Gentle soft kick on 0, 8; Warm rimshot on 4, 12; Whisper hats on quarter notes
        if (step == 0 || step == 8) {
          AudioManager().playDrum(DrumSound.kick, volume: vol * 0.70);
        }
        if (step == 4 || step == 12) {
          AudioManager().playDrum(DrumSound.rimshot, volume: vol * 0.65);
        }
        if (step % 4 == 0) {
          AudioManager().playDrum(DrumSound.hiHatClosed, volume: vol * 0.35);
        }
        break;
    }
  }
}
