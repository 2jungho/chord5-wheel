import '../models/music_constants.dart';
import '../models/scale_model.dart';
import '../models/chord_model.dart';
import '../models/caged_model.dart';

import '../utils/theory/note_utils.dart';
import '../utils/theory/scale_utils.dart';
import '../utils/theory/chord_utils.dart';
import '../utils/guitar/voicing_generator.dart';
import '../utils/guitar/tuning_utils.dart';

class MusicTheoryService {
  /// Calculates scale and diatonic chords based on key and mode indices.
  static (Scale, List<Chord>) calculateKeyContext(
      int keyIndex, int modeIndex, bool isInnerRing) {
    
    final keyData = MusicConstants.KEYS[keyIndex];
    String rootNoteName = isInnerRing 
        ? keyData.minor.replaceAll('m', '') 
        : keyData.name;
    
    final modeData = MusicConstants.MODES[modeIndex];
    
    // 1. Root & Mode
    final root = NoteUtils.normalizeNoteName(rootNoteName);
    
    // 2. Scale Notes
    final scaleNotes = ScaleUtils.calculateScaleNotes(root, modeData.name);
    
    final scale = Scale(
      root: root,
      mode: modeData,
      notes: scaleNotes,
      intervals: modeData.formula.split(' '),
    );
    
    // 3. Diatonic Chords
    final diatonicChords = ChordUtils.getDiatonicChords(scaleNotes, modeData.name);
    
    return (scale, diatonicChords);
  }

  /// Calculates the default voicing for a given chord.
  static ChordVoicing calculateMainVoicing(Chord chord) {
    return VoicingGenerator.calculateChordShape(chord.root, chord.quality);
  }

  /// Finds the best CAGED pattern (lowest position) for a given chord.
  static (String patternName, ChordVoicing voicing)? findBestCagedPattern(
      Chord chord) {
    
    final isMinor = chord.quality.contains('m') && !chord.quality.contains('Maj');
    final rootIdx = NoteUtils.getNoteIndex(chord.root);

    // E string Reference Fret (0-11)
    int rootFretOnE = (rootIdx - 4 + 12) % 12;

    final patterns = isMinor ? minorCagedPatterns : majorCagedPatterns;

    CagedPattern? bestPattern;
    int bestStartFret = 999;

    for (var pattern in patterns) {
      int startFret = rootFretOnE + pattern.baseOffset;
      while (startFret >= 12) {
        startFret -= 12;
      }
      // Prefer lowest positive fret
      if (startFret < bestStartFret) {
        bestStartFret = startFret;
        bestPattern = pattern;
      }
    }

    if (bestPattern != null) {
      // Calculate voicing manually as in original MusicState logic
      // Or use VoicingGenerator if it supports specific pattern generation?
      // VoicingGenerator has _addVoicingToResult but it's private and tied to "Generate All".
      // We should replicate the logic or make VoicingGenerator expose specific form generation.
      // For now, I'll replicate the simple logic from MusicState to keep it consistent.
      
      List<int> frets = [-1, -1, -1, -1, -1, -1];
      for (var dot in bestPattern.dots) {
        int strIdx = 6 - dot.s;
        int realFret = bestStartFret + dot.o;
        if (frets[strIdx] == -1) {
          frets[strIdx] = realFret;
        }
      }

      int minFret = 999;
      for (int f in frets) if (f != -1 && f < minFret) minFret = f;
      int displayStartFret = minFret != 999 ? minFret : (bestStartFret > 0 ? bestStartFret : 1);
      if (minFret == 0) displayStartFret = 1;

      final voicing = ChordVoicing(
        frets: frets,
        startFret: displayStartFret,
        rootString: bestPattern.rootString,
        name: bestPattern.cagedName,
      );
      
      return (bestPattern.name, voicing);
    }
    return null;
  }
}
