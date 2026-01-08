import '../../models/chord_model.dart';
import 'note_utils.dart';
import 'scale_utils.dart';

class ChordUtils {
  static (List<String> intervals, String displayStr, bool isMinor)
      parseChordQuality(String q) {
    List<String> intervals = ['1', '3', '5'];
    bool isMinor = false;

    if (q.contains('dim')) {
      intervals = ['1', 'b3', 'b5'];
      isMinor = true;
    } else if (q.contains('aug') || q.contains('+')) {
      intervals = ['1', '3', '#5'];
    } else if (q.contains('sus2')) {
      intervals = ['1', '2', '5'];
    } else if (q.contains('sus') || q.contains('sus4')) {
      intervals = ['1', '4', '5'];
    } else if (q.contains('m') && !q.contains('maj')) {
      intervals = ['1', 'b3', '5'];
      isMinor = true;
    }

    if (q.contains('dim7')) {
      intervals = ['1', 'b3', 'b5', 'bb7'];
      isMinor = true;
    } else if (q.contains('m7b5')) {
      intervals = ['1', 'b3', 'b5', 'b7'];
      isMinor = true;
    } else {
      if (q.contains('maj7') || q.contains('M7') || q.contains('Maj7')) {
        if (!intervals.contains('7')) intervals.add('7');
      } else if (q.contains('7')) {
        if (!intervals.contains('b7')) intervals.add('b7');
      }

      if (q.contains('6')) {
        intervals.remove('b7');
        intervals.remove('7');
        if (!intervals.contains('6')) intervals.add('6');
      }

      if (q.contains('9')) {
        if (!intervals.contains('2')) intervals.add('2');
        if (!q.contains('add') && !q.contains('maj9') && !q.contains('m9')) {
          if (!intervals.contains('b7') && !intervals.contains('7')) {
            intervals.add('b7');
          }
        }
        if (q.contains('maj9')) {
          if (!intervals.contains('7')) intervals.add('7');
        } else if (q.contains('m9')) {
          if (!intervals.contains('b7')) intervals.add('b7');
        }
      }
    }

    final map = {
      '1': '1',
      'b2': 'm2',
      '2': 'M2',
      'b3': 'm3',
      '3': 'M3',
      '4': 'P4',
      '#4': 'A4',
      'b5': 'd5',
      '5': 'P5',
      '#5': 'A5',
      '6': 'M6',
      'b7': 'm7',
      '7': 'M7',
      'bb7': 'd7'
    };
    String intervalStr = intervals.map((i) => map[i] ?? i).join(' ');

    return (intervals, intervalStr, isMinor);
  }

  static List<String> getGuideTones(String root, String quality) {
    List<String> targetIntervals = [];

    if (quality.contains('m7b5')) {
      targetIntervals = ['b3', 'b7'];
    } else if (quality.contains('dim7')) {
      targetIntervals = ['b3', 'bb7'];
    } else if (quality.contains('m')) {
      if (quality.contains('Maj7') || quality.contains('M7')) {
        targetIntervals = ['b3', '7'];
      } else {
        targetIntervals = ['b3', 'b7'];
      }
    } else if (quality.contains('Maj7') || quality.contains('M7')) {
      targetIntervals = ['3', '7'];
    } else {
      if (quality.contains('7')) {
        targetIntervals = ['3', 'b7'];
      } else {
        targetIntervals = ['3'];
      }
    }

    List<String> notes = [];
    int rootIdx = NoteUtils.getNoteIndex(root);
    bool useSharp = !root.contains('b') && root != 'F';

    for (String iv in targetIntervals) {
      int st = NoteUtils.intervalToSemitone(iv);
      int noteIdx = (rootIdx + st) % 12;
      notes.add(NoteUtils.getNoteName(noteIdx, useSharp));
    }

    return notes;
  }

  static Map<String, String> findDiatonicKeys(String root, String quality) {
    final possibleKeys = <String, String>{};
    final rootIdx = NoteUtils.getNoteIndex(root);
    final (intervals, _, isMinor) = parseChordQuality(quality);

    String simplifiedQuality = '';
    if (quality.contains('m7b5'))
      simplifiedQuality = 'm7b5';
    else if (quality.contains('m7'))
      simplifiedQuality = 'm7';
    else if (quality.contains('Maj7') || quality.contains('M7'))
      simplifiedQuality = 'Maj7';
    else if (quality.contains('7'))
      simplifiedQuality = '7';
    else if (isMinor)
      simplifiedQuality = 'm7';
    else
      simplifiedQuality = 'Maj7';

    final standardKeys = [
      'C', 'G', 'D', 'A', 'E', 'B', 'F#', 'Db', 'Ab', 'Eb', 'Bb', 'F'
    ];

    for (String keyRoot in standardKeys) {
      final scaleNotes = ScaleUtils.calculateScaleNotes(keyRoot, 'Ionian');
      int degreeIndex = -1;
      for (int k = 0; k < scaleNotes.length; k++) {
        if (NoteUtils.getNoteIndex(scaleNotes[k]) == rootIdx) {
          degreeIndex = k;
          break;
        }
      }

      if (degreeIndex != -1) {
        final diatonicQualities = [
          'Maj7', 'm7', 'm7', 'Maj7', '7', 'm7', 'm7b5'
        ];
        final expectedQ = diatonicQualities[degreeIndex];

        bool match = false;
        if (simplifiedQuality == expectedQ) match = true;
        if (degreeIndex == 4 && simplifiedQuality == '7') match = true;

        if (match) {
          final degreeRoman = getRomanNumeral(degreeIndex + 1);
          possibleKeys[keyRoot] = degreeRoman;
        }
      }
    }
    return possibleKeys;
  }

  static String getRomanNumeral(int degree) {
    const romans = ['I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii°'];
    return romans[degree - 1];
  }

  static String getMinorRomanNumeral(int degree) {
    const romans = ['i', 'ii°', 'bIII', 'iv', 'v', 'bVI', 'bVII'];
    return romans[degree - 1];
  }

  static List<Map<String, dynamic>> analyzeTensions(
      String root, String scaleName) {
    final results = <Map<String, dynamic>>[];
    if (scaleName == 'Chord Tones') return results;

    final scaleNotes = ScaleUtils.calculateScaleNotes(root, scaleName);
    final tensionIndices = [1, 3, 5];

    for (int i in tensionIndices) {
      if (i >= scaleNotes.length) continue;

      final note = scaleNotes[i];
      final degree = (i == 1) ? '9' : (i == 3) ? '11' : (i == 5) ? '13' : '?';

      String status = 'Available';

      if (scaleName.contains('Ionian')) {
        if (degree == '11') status = 'Avoid (S4)';
        if (degree == '9') status = 'Available (9)';
        if (degree == '13') status = 'Available (13)';
      } else if (scaleName.contains('Dorian')) {
        if (degree == '13')
          status = 'Char. (Maj6)';
        else
          status = 'Available';
      } else if (scaleName.contains('Phrygian')) {
        if (degree == '9') status = 'Char. (b9)';
      } else if (scaleName.contains('Lydian')) {
        if (degree == '11') status = 'Char. (#11)';
      } else if (scaleName.contains('Mixolydian')) {
        if (degree == '11')
          status = 'Avoid (S4)';
      } else if (scaleName.contains('Aeolian')) {
        if (degree == '13') status = 'Avoid (b6)';
      } else if (scaleName.contains('Locrian')) {
        if (degree == '9') status = 'Avoid (b9)';
      }

      results.add({'note': note, 'degree': degree, 'status': status});
    }
    return results;
  }

  static List<Map<String, String>> findSubstitutions(
      String root, String quality) {
    final subs = <Map<String, String>>[];
    final rootIdx = NoteUtils.getNoteIndex(root);
    final (intervals, _, isMinor) = parseChordQuality(quality);

    if (quality.contains('Maj7') || (!isMinor && quality == '')) {
      final viIdx = (rootIdx + 9) % 12;
      final viRoot = NoteUtils.getNoteName(viIdx, true);
      subs.add({'root': viRoot, 'quality': 'm7', 'relation': 'Relative Minor'});

      final iiiIdx = (rootIdx + 4) % 12;
      final iiiRoot = NoteUtils.getNoteName(iiiIdx, true);
      subs.add(
          {'root': iiiRoot, 'quality': 'm7', 'relation': 'Mediants (iii)'});
    } else if (quality.contains('m7') || isMinor) {
      final bIIIIdx = (rootIdx + 3) % 12;
      final bIIIRoot = NoteUtils.getNoteName(bIIIIdx, false);
      subs.add(
          {'root': bIIIRoot, 'quality': 'Maj7', 'relation': 'Relative Major'});
    }

    if (quality == '7' || quality.contains('Dom')) {
      final tritoneIdx = (rootIdx + 6) % 12;
      final tritoneRoot = NoteUtils.getNoteName(tritoneIdx, false);
      subs.add(
          {'root': tritoneRoot, 'quality': '7', 'relation': 'Tritone Sub'});
    }

    if (quality == '7') {
      final b9Idx = (rootIdx + 1) % 12;
      final b9Root = NoteUtils.getNoteName(b9Idx, false);
      subs.add(
          {'root': b9Root, 'quality': 'dim7', 'relation': 'b9 Diminished'});
    }

    return subs;
  }

  static List<Map<String, dynamic>> getChordInversionsWithOctave(
      String root, String quality) {
    final (intervals, _, _) = parseChordQuality(quality);
    final rootIdx = NoteUtils.getNoteIndex(root);
    bool useSharp = !root.contains('b') && root != 'F';

    List<int> baseIndices = intervals.map((iv) {
      return (rootIdx + NoteUtils.intervalToSemitone(iv)) % 12;
    }).toList();

    int baseOctave = 3;
    List<int> rootPosMidi = [];
    int lastVal = -1;

    for (int idx in baseIndices) {
      int val = idx;
      if (lastVal == -1) {
        val += baseOctave * 12;
      } else {
        val += baseOctave * 12;
        if (val <= lastVal) val += 12;
      }
      rootPosMidi.add(val);
      lastVal = val;
    }

    List<Map<String, dynamic>> inversions = [];

    List<String> midiToNoteNames(List<int> midis) {
      return midis.map((m) {
        int r = m % 12;
        int o = (m / 12).floor();
        return '${NoteUtils.getNoteName(r, useSharp)}${o - 1}';
      }).toList();
    }

    inversions.add({
      'name': 'Root Pos',
      'notes': midiToNoteNames(rootPosMidi),
    });

    List<int> inv1 = List.from(rootPosMidi);
    int first = inv1.removeAt(0);
    inv1.add(first + 12);
    inversions.add({
      'name': '1st Inv',
      'notes': midiToNoteNames(inv1),
    });

    List<int> inv2 = List.from(inv1);
    int second = inv2.removeAt(0);
    inv2.add(second + 12);
    inversions.add({
      'name': '2nd Inv',
      'notes': midiToNoteNames(inv2),
    });

    if (baseIndices.length >= 4) {
      List<int> inv3 = List.from(inv2);
      int third = inv3.removeAt(0);
      inv3.add(third + 12);
      inversions.add({
        'name': '3rd Inv',
        'notes': midiToNoteNames(inv3),
      });
    }

    return inversions;
  }

  static Chord analyzeChord(String symbol) {
    String root = '';
    String quality = '';

    if (symbol.length >= 2 && (symbol[1] == '#' || symbol[1] == 'b')) {
      root = symbol.substring(0, 2);
      quality = symbol.substring(2);
    } else if (symbol.isNotEmpty) {
      root = symbol.substring(0, 1);
      quality = symbol.substring(1);
    }

    final rootIdx = NoteUtils.getNoteIndex(root);
    final (intervals, _, _) = parseChordQuality(quality);

    bool useSharp = !root.contains('b') && root != 'F';
    final notes = intervals.map((iv) {
      final st = NoteUtils.intervalToSemitone(iv);
      return NoteUtils.getNoteName((rootIdx + st) % 12, useSharp);
    }).toList();

    return Chord(
      root: root,
      quality: quality,
      notes: notes,
      intervals: intervals,
    );
  }

  static List<String> getNotesFromVoicing(
      ChordVoicing voicing, String rootNote) {
    final tuningIndices = [4, 9, 2, 7, 11, 4];
    final bool useSharp = !rootNote.contains('b') && rootNote != 'F';
    final orderedNotes = <String>[];

    for (int i = 0; i < 6; i++) {
      final fret = voicing.frets[i];
      if (fret != -1) {
        final openNoteIdx = tuningIndices[i];
        final noteIdx = (openNoteIdx + fret) % 12;
        final noteName = NoteUtils.getNoteName(noteIdx, useSharp);

        if (!orderedNotes.contains(noteName)) {
          orderedNotes.add(noteName);
        }
      }
    }
    return orderedNotes;
  }

  static String transposeChord(String chordSymbol, int semitones) {
    if (chordSymbol.isEmpty) return chordSymbol;

    String root = '';
    String quality = '';

    if (chordSymbol.length >= 2 &&
        (chordSymbol[1] == '#' || chordSymbol[1] == 'b')) {
      root = chordSymbol.substring(0, 2);
      quality = chordSymbol.substring(2);
    } else {
      root = chordSymbol.substring(0, 1);
      quality = chordSymbol.substring(1);
    }

    final newRoot = NoteUtils.transposeNote(root, semitones);
    return '$newRoot$quality';
  }

  static List<Chord> getDiatonicChords(
    List<String> scaleNotes,
    String modeName,
  ) {
    if (scaleNotes.length != 7) return [];

    const modeOrder = [
      'Ionian',
      'Dorian',
      'Phrygian',
      'Lydian',
      'Mixolydian',
      'Aeolian',
      'Locrian',
    ];
    final startIdx = modeOrder.indexOf(modeName);
    if (startIdx == -1) return [];

    final majorChordQualities = ['Maj7', 'm7', 'm7', 'Maj7', '7', 'm7', 'm7b5'];

    final chords = <Chord>[];
    for (int i = 0; i < 7; i++) {
      var quality = majorChordQualities[(startIdx + i) % 7];
      String dLabel = (i + 1).toString();

      if (quality.contains('Maj')) {
        dLabel += 'M';
      } else if (quality == 'm7b5') {
        dLabel += 'dim';
      } else if (quality.contains('m')) {
        dLabel += 'm';
      } else if (quality == '7') {
        dLabel += '7';
      }

      String displayQ = quality;
      if (i == 0 && modeName == 'Lydian') displayQ = 'Maj7(#11)';

      if (i == 4 && modeName == 'Aeolian') {
        quality = '7';
        displayQ = '7';
      }

      final notes = [
        scaleNotes[i],
        scaleNotes[(i + 2) % 7],
        scaleNotes[(i + 4) % 7],
        scaleNotes[(i + 6) % 7],
      ];

      if (i == 4 && modeName == 'Aeolian') {
        notes[1] = NoteUtils.transposeNote(notes[1], 1);
      }

      chords.add(
        Chord(
          root: scaleNotes[i],
          quality: quality,
          displayQuality: displayQ,
          degree: dLabel,
          notes: notes,
        ),
      );
    }
    return chords;
  }
}
