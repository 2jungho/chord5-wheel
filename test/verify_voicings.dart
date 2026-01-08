import '../lib/utils/guitar_utils.dart';
import '../lib/utils/theory_utils.dart';
import '../lib/models/chord_model.dart'; // Import ChordVoicing class

void main() {
  print('=== Verifying Drop & Shell Voicings ===\n');

  // Test Cases
  final tests = [
    {'root': 'C', 'quality': 'maj7'},
    {'root': 'C', 'quality': '7'},
    {'root': 'C', 'quality': 'm7'},
    {'root': 'A', 'quality': 'm7'}, // Corrected: Root 'A', Quality 'm7'
    {'root': 'G', 'quality': 'maj7'},
  ];

  for (var t in tests) {
    String r = t['root']!;
    String q = t['quality']!;
    print('Checking $r$q...');

    // Shell
    List<ChordVoicing> shells = GuitarUtils.generateShellVoicings(r, q);
    for (var v in shells) {
      print('  [${v.name ?? "Shell"}] RootString: ${v.rootString}');
      print('    Frets: ${v.frets}');
      List<String> notes = TheoryUtils.getNotesFromVoicing(v, r);
      print('    Notes: $notes');
    }

    // Drop
    List<ChordVoicing> drops = GuitarUtils.generateDropVoicings(r, q);
    for (var v in drops) {
      print('  [${v.name ?? "Drop"}] RootString: ${v.rootString}');
      print('    Frets: ${v.frets}');
      List<String> notes = TheoryUtils.getNotesFromVoicing(v, r);
      print('    Notes: $notes');
    }
    print('');
  }
}
