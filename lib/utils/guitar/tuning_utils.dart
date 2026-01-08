class TuningUtils {
  static const TUNING_NOTES = ['E', 'A', 'D', 'G', 'B', 'E'];

  static int get6thStringFret(String noteName) {
    const map = {
      'E': 0, 'F': 1, 'F#': 2, 'Gb': 2, 'G': 3, 'G#': 4, 'Ab': 4,
      'A': 5, 'A#': 6, 'Bb': 6, 'B': 7, 'C': 8, 'C#': 9, 'Db': 9,
      'D': 10, 'D#': 11, 'Eb': 11,
    };
    return map[noteName] ?? 0;
  }

  static int get5thStringFret(String noteName) {
    const map = {
      'A': 0, 'A#': 1, 'Bb': 1, 'B': 2, 'C': 3, 'C#': 4, 'Db': 4,
      'D': 5, 'D#': 6, 'Eb': 6, 'E': 7, 'F': 8, 'F#': 9, 'Gb': 9,
      'G': 10, 'G#': 11, 'Ab': 11,
    };
    return map[noteName] ?? 0;
  }
}
