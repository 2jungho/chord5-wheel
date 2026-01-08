import '../../models/music_constants.dart';

class NoteUtils {
  static final Map<String, int> _noteIndexMap = {
    'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3, 'E': 4, 'F': 5,
    'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8, 'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10,
    'B': 11,
    'Am': 9, 'Em': 4, 'Bm': 11, 'F#m': 6, 'C#m': 1, 'G#m': 8,
    'Ebm': 3, 'Bbm': 10, 'Fm': 5, 'Cm': 0, 'Gm': 7, 'Dm': 2,
  };

  static String normalizeNoteName(String name) {
    return name.replaceAll('m', '');
  }

  static int getNoteIndex(String noteName) {
    final norm = normalizeNoteName(noteName);
    return _noteIndexMap[norm] ?? 0;
  }

  static String getNoteName(int chromaticIndex, bool useSharp) {
    final idx = (chromaticIndex % 12 + 12) % 12;
    final scale = useSharp
        ? MusicConstants.CHROMATIC_SHARP
        : MusicConstants.CHROMATIC_SCALE;
    return scale[idx];
  }

  static String transposeNote(String note, int semitones) {
    if (note.isEmpty) return note;
    final idx = getNoteIndex(note);
    final newIdx = (idx + semitones + 12) % 12;
    bool useSharp = !note.contains('b');
    return getNoteName(newIdx, useSharp);
  }

  static int intervalToSemitone(String iv) {
    if (iv == '1') return 0;
    if (iv == 'b2') return 1;
    if (iv == '2') return 2;
    if (iv == 'b3') return 3;
    if (iv == '3') return 4;
    if (iv == '4') return 5;
    if (iv == 'b5') return 6;
    if (iv == '5') return 7;
    if (iv == '#5' || iv == 'b6') return 8;
    if (iv == '6' || iv == 'bb7') return 9;
    if (iv == 'b7') return 10;
    if (iv == '7') return 11;
    return 0;
  }

  static String getIntervalName(int st) {
    const map = {
      0: '1P',
      1: 'm2',
      2: 'M2',
      3: 'm3',
      4: 'M3',
      5: 'P4',
      6: 'd5',
      7: 'P5',
      8: 'm6',
      9: 'M6',
      10: 'm7',
      11: 'M7'
    };
    return map[st] ?? '?';
  }
}
