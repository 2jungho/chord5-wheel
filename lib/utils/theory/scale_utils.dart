import '../../models/music_constants.dart';
import 'note_utils.dart';

class ScaleUtils {
  static final Map<String, List<int>> _scalePatterns = {
    // 7 Modes
    'Ionian': [2, 2, 1, 2, 2, 2, 1],
    'Dorian': [2, 1, 2, 2, 2, 1, 2],
    'Phrygian': [1, 2, 2, 2, 1, 2, 2],
    'Lydian': [2, 2, 2, 1, 2, 2, 1],
    'Mixolydian': [2, 2, 1, 2, 2, 1, 2],
    'Aeolian': [2, 1, 2, 2, 1, 2, 2],
    'Locrian': [1, 2, 2, 1, 2, 2, 2],
    // Pentatonic & Blues
    'Major Pentatonic': [2, 2, 3, 2, 3],
    'Minor Pentatonic': [3, 2, 2, 3, 2],
    'Blues': [3, 2, 1, 1, 3, 2],
    // Harmonic/Melodic Minor
    'Harmonic Minor': [2, 1, 2, 2, 1, 3, 1],
    'Melodic Minor': [2, 1, 2, 2, 2, 2, 1],
    // Dominant & Altered Scales
    'Phrygian Dominant': [1, 3, 1, 2, 1, 2, 2],
    'Lydian Dominant': [2, 2, 2, 1, 2, 1, 2],
    'Altered': [1, 2, 1, 2, 2, 2, 2],
    'Diminished (H-W)': [1, 2, 1, 2, 1, 2, 1, 2],
    'Whole Tone': [2, 2, 2, 2, 2, 2],
  };

  static List<String> calculateScaleNotes(
    String rootNoteName,
    String modeName,
  ) {
    final rootNoteStr = NoteUtils.normalizeNoteName(rootNoteName);
    final rootIndex = NoteUtils.getNoteIndex(rootNoteStr);

    final pat = _scalePatterns[modeName];
    if (pat == null) return [];

    const circleMap = {
      'C': 0, 'G': 1, 'D': 2, 'A': 3, 'E': 4, 'B': 5,
      'F#': 6, 'Gb': 6, 'Db': 7, 'C#': 7, 'Ab': 8, 'G#': 8,
      'Eb': 9, 'D#': 9, 'Bb': 10, 'A#': 10, 'F': 11,
    };
    final rootCircleIdx = circleMap[rootNoteStr];

    int modeOffset = 0;
    try {
      final m = MusicConstants.MODES
          .firstWhere((element) => element.name == modeName);
      modeOffset = m.offset;
    } catch (_) {}

    bool useSharp = true;
    if (rootCircleIdx != null) {
      final pIdx = (rootCircleIdx + modeOffset + 12) % 12;
      useSharp = (pIdx >= 0 && pIdx <= 5);
    } else {
      useSharp = !rootNoteStr.contains('b') && rootNoteStr != 'F';
    }

    final scaleNotes = <String>[];
    int currentVal = rootIndex;

    for (int interval in pat) {
      scaleNotes.add(NoteUtils.getNoteName(currentVal, useSharp));
      currentVal += interval;
    }

    return scaleNotes;
  }

  static List<String> getRelatedScales(String root, List<String> chordNotes) {
    List<String> validScales = [];
    final chordIndices = chordNotes.map((n) => NoteUtils.getNoteIndex(n)).toSet();

    for (var entry in _scalePatterns.entries) {
      String scaleName = entry.key;
      List<String> scaleNotes = calculateScaleNotes(root, scaleName);
      final scaleIndices = scaleNotes.map((n) => NoteUtils.getNoteIndex(n)).toSet();

      bool match = chordIndices.every((ci) => scaleIndices.contains(ci));
      if (match) {
        validScales.add(scaleName);
      }
    }
    return validScales;
  }

  static List<String> getScaleIntervals(String modeName) {
    final pat = _scalePatterns[modeName];
    if (pat == null) return [];

    List<String> intervals = ['1P'];
    int semitones = 0;
    for (int i = 0; i < pat.length - 1; i++) {
      semitones += pat[i];
      intervals.add(NoteUtils.getIntervalName(semitones));
    }
    return intervals;
  }

  static Map<String, List<String>> classifyScaleNotes(
      List<String> scaleNotes, String modeName) {
    final chordTones = <String>[];
    final otherNotes = <String>[];

    for (int i = 0; i < scaleNotes.length; i++) {
      if (i == 0 || i == 2 || i == 4 || i == 6) {
        chordTones.add(scaleNotes[i]);
      } else {
        otherNotes.add(scaleNotes[i]);
      }
    }

    return {
      'chordTones': chordTones,
      'otherNotes': otherNotes,
    };
  }
}
