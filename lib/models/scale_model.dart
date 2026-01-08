import 'music_constants.dart';

class Scale {
  final String root;
  final ModeData mode;
  final List<String> notes;
  final List<String> intervals;

  const Scale({
    required this.root,
    required this.mode,
    required this.notes,
    this.intervals = const [], // e.g. ['P1', 'M2', 'M3', ...]
  });

  String get name => '$root ${mode.name}';

  // Helper to get character note based on mode logic
  String get characterNote {
    int idx = 0;
    switch (mode.name) {
      case 'Lydian':
        idx = 3;
        break; // #4
      case 'Ionian':
        idx = 3;
        break; // P4 (Note: Ionian char note often argued, but following existing JS logic which used index 3)
      case 'Mixolydian':
        idx = 6;
        break; // b7
      case 'Dorian':
        idx = 5;
        break; // M6
      case 'Aeolian':
        idx = 5;
        break; // b6
      case 'Phrygian':
        idx = 1;
        break; // b2
      case 'Locrian':
        idx = 4;
        break; // b5
      default:
        idx = 0;
    }
    if (idx < notes.length) return notes[idx];
    return '';
  }
}
