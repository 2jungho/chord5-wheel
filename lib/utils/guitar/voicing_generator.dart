import '../../models/chord_model.dart';
import '../theory/note_utils.dart';
import '../theory/chord_utils.dart';
import 'tuning_utils.dart';

class VoicingGenerator {
  static ChordVoicing calculateChordShape(String root, String quality) {
    final normRoot = NoteUtils.normalizeNoteName(root);
    final r6 = TuningUtils.get6thStringFret(normRoot);
    final r5 = TuningUtils.get5thStringFret(normRoot);

    const shapes = {
      'Maj7': {
        'r6': [0, -1, 1, 1, 0, -1],
        'r5': [-1, 0, 2, 1, 2, 0],
      },
      'm7': {
        'r6': [0, -1, 0, 0, 0, -1],
        'r5': [-1, 0, 2, 0, 1, 0],
      },
      '7': {
        'r6': [0, -1, 0, 1, 0, -1],
        'r5': [-1, 0, 2, 0, 2, 0],
      },
      'm7b5': {
        'r6': [0, -1, 0, 0, -1, -1],
        'r5': [-1, 0, 1, 0, 1, -1],
      },
    };

    String qKey = 'Maj7';
    if (quality.contains('m7b5'))
      qKey = 'm7b5';
    else if (quality.contains('m7'))
      qKey = 'm7';
    else if (quality.contains('Maj7'))
      qKey = 'Maj7';
    else if (quality.contains('7')) qKey = '7';

    final s = shapes[qKey] ?? shapes['Maj7']!;

    List<int> chosenOffsets;
    int startFret = 0;
    int rootString = 6;

    if (r6 <= 5) {
      chosenOffsets = s['r6']!;
      startFret = (r6 - 1 < 0) ? 0 : r6 - 1;
      rootString = 6;
    } else if (r5 <= 8) {
      chosenOffsets = s['r5']!;
      startFret = (r5 - 1 < 0) ? 0 : r5 - 1;
      rootString = 5;
    } else {
      chosenOffsets = s['r6']!;
      startFret = (r6 - 1 < 0) ? 0 : r6 - 1;
      rootString = 6;
    }

    final rootFretBase = (rootString == 6) ? r6 : r5;

    final frets = chosenOffsets.map((o) {
      if (o == -1) return -1;
      return rootFretBase + o;
    }).toList();

    return ChordVoicing(
      frets: frets,
      startFret: startFret,
      rootString: rootString,
      name: '$root$quality',
    );
  }

  static List<ChordVoicing> generateAllVoicings(String root, String quality) {
    final all = <ChordVoicing>[];
    all.addAll(generateCAGEDVoicings(root, quality));
    all.addAll(generateDropVoicings(root, quality));
    all.addAll(generateShellVoicings(root, quality));

    final unique = <String, ChordVoicing>{};
    for (var v in all) {
      final key = v.frets.join(',');
      if (!unique.containsKey(key)) {
        unique[key] = v;
      } else {
        final existing = unique[key]!;
        final mergedTags = {...existing.tags, ...v.tags}.toList();

        unique[key] = ChordVoicing(
          frets: existing.frets,
          startFret: existing.startFret,
          rootString: existing.rootString,
          name: existing.name,
          tags: mergedTags,
        );
      }
    }

    final resultList = unique.values.toList();
    resultList.sort((a, b) => a.startFret.compareTo(b.startFret));

    return resultList;
  }

  static List<ChordVoicing> generateVoicings(String root, String quality) {
    return generateAllVoicings(root, quality);
  }

  static List<ChordVoicing> generateCAGEDVoicings(String root, String quality) {
    final List<ChordVoicing> results = [];
    final (intervals, _, isMinor) = ChordUtils.parseChordQuality(quality);

    // Feature Detection based on intervals
    bool isSus4 = intervals.contains('4') || quality.contains('sus4');
    bool isSus2 = intervals.contains('2') &&
        !intervals.contains('3') &&
        !intervals.contains('b3');
    bool isAug = intervals.contains('#5');
    bool isDim = intervals.contains('b3') && intervals.contains('b5');
    bool isDim7 = isDim && intervals.contains('bb7');
    bool is6 = intervals.contains('6');

    bool hasb7 = intervals.contains('b7');
    bool hasM7 = intervals.contains('7');
    bool hasb5 = intervals.contains('b5');

    // --- E Form (Root 6) ---
    List<int> ePattern;
    if (isSus4) {
      // Esus4: 0 2 2 2 0 0
      ePattern = [0, 2, 2, 2, 0, 0];
    } else if (isSus2) {
      // Esus2: 0 2 4 4 0 0 (Stretch) or simple 0 2 2 x x x?
      // Use standard movable: 0 2 4 4 x x
      ePattern = [0, 2, 4, 4, -99, -99];
    } else if (isAug) {
      // Eaug: 0 3 2 1 1 0
      ePattern = [0, 3, 2, 1, 1, 0];
    } else if (isDim || isDim7) {
      // Gdim7 shape (Root 6): 0 x -1 0 -1 x (Root, bb7, b3, b5)
      // Note: -1 on String 4 relative to 0 is physically tricky if 0 is open?
      // If Root is 3(G), String 4 is 2(E). 3-1=2. Correct.
      ePattern = [0, -99, -1, 0, -1, -99];
    } else if (is6) {
      // E6: 0 2 2 1 2 0
      ePattern = [0, 2, 2, 1, 2, 0];
    } else if (isMinor) {
      if (hasb5 && hasb7) {
        ePattern = [0, -99, 0, 0, -1, -99]; // m7b5
      } else if (hasb7) {
        ePattern = [0, 2, 0, 0, 0, 0]; // m7
      } else {
        ePattern = [0, 2, 2, 0, 0, 0]; // m
      }
    } else {
      if (hasb7) {
        ePattern = [0, 2, 0, 1, 0, 0]; // 7
      } else if (hasM7) {
        ePattern = [0, 2, 1, 1, 0, 0]; // Maj7
      } else {
        ePattern = [0, 2, 2, 1, 0, 0]; // Maj
      }
    }

    int idx = NoteUtils.getNoteIndex(root);
    int rootFret = (idx - 4 + 12) % 12;
    _addVoicingToResult(results, "E Form", 6, rootFret, ePattern,
        tags: ['CAGED']);

    // --- G Form (Root 6) ---
    List<int> gPattern;
    if (isSus4) {
      // Gsus4: 0 x 0 0 1 3 (Relative to 3: 0 x -3 -3 -2 0)
      // G(3 2 0 0 0 3). Sus4 change B->C (String 5 & 2).
      // String 5: 2->3 (+1). String 2: 0->1 (+1).
      // 3 3 0 0 1 3.
      // Relative: 0 0 -3 -3 -2 0.
      gPattern = [0, 0, -3, -3, -2, 0];
    } else if (isSus2) {
      // Gsus2: 3 0 0 0 x 3. (A->A)
      // 3 x 0 2 3 3.
      // Hard. Use E-form mostly.
      gPattern = [0, -99, -3, -1, 0, 0];
    } else if (isAug) {
      // Gaug: 3 2 1 0 0 3
      gPattern = [0, -1, -2, -3, -3, 0];
    } else if (isDim || isDim7) {
      // Skip G form for dim (awkward)
      gPattern = [0, -99, -99, -99, -99, -99];
    } else if (is6) {
      // G6: 3 2 0 0 0 0 ==> 0 -1 -3 -3 -3 -3
      gPattern = [0, -1, -3, -3, -3, -3];
    } else if (isMinor) {
      if (hasb7) {
        gPattern = [0, -2, 0, -3, 0, -2];
      } else {
        gPattern = [0, -2, -3, -3, 0, 0];
      }
    } else {
      if (hasb7) {
        gPattern = [0, -1, -3, -3, -3, -2];
      } else if (hasM7) {
        gPattern = [0, -1, -3, -3, -3, -1];
      } else {
        gPattern = [0, -1, -3, -3, -3, 0];
      }
    }
    // Only add if not all -99
    if (!gPattern.every((p) => p == -99)) {
      _addVoicingToResult(results, "G Form", 6, rootFret, gPattern,
          tags: ['CAGED']);
    }

    // --- A Form (Root 5) ---
    List<int> aPattern;
    if (isSus4) {
      // Asus4: x 0 2 2 3 0 -> [-99, 0, 2, 2, 3, 0]
      aPattern = [-99, 0, 2, 2, 3, 0];
    } else if (isSus2) {
      // Asus2: x 0 2 2 0 0 -> [-99, 0, 2, 2, 0, 0]
      aPattern = [-99, 0, 2, 2, 0, 0];
    } else if (isAug) {
      // Aaug: x 0 3 2 2 1 -> [-99, 0, 3, 2, 2, 1]
      aPattern = [-99, 0, 3, 2, 2, 1];
    } else if (isDim || isDim7) {
      // Cdim7 (Root 5): x 3 4 2 4 x -> [-99, 0, 1, -1, 1, -99]
      aPattern = [-99, 0, 1, -1, 1, -99];
    } else if (is6) {
      // A6: x 0 2 2 2 2 -> [-99, 0, 2, 2, 2, 2]
      aPattern = [-99, 0, 2, 2, 2, 2];
    } else if (isMinor) {
      if (hasb5 && hasb7) {
        aPattern = [-99, 0, 1, 0, 1, -99]; // m7b5
      } else if (hasb7) {
        aPattern = [-99, 0, 2, 0, 1, 0];
      } else {
        aPattern = [-99, 0, 2, 2, 1, 0];
      }
    } else {
      if (hasb7) {
        aPattern = [-99, 0, 2, 0, 2, 0];
      } else if (hasM7) {
        aPattern = [-99, 0, 2, 1, 2, 0];
      } else {
        aPattern = [-99, 0, 2, 2, 2, 0];
      }
    }

    int rootFret5 = (NoteUtils.getNoteIndex(root) - 9 + 12) % 12;
    _addVoicingToResult(results, "A Form", 5, rootFret5, aPattern,
        tags: ['CAGED']);

    // --- C Form (Root 5) ---
    List<int> cPattern;
    if (isSus4) {
      // C form Sus4: x 3 3 0 1 1 -> [-99, 0, 0, -3, -2, -2] (Hard)
      // Simplified: x 3 x 0 1 1 -> [-99, 0, -99, -3, -2, -2]
      cPattern = [-99, 0, -99, -3, -2, -2];
    } else if (isSus2) {
      cPattern = [-99, -99, -99, -99, -99, -99]; // Skip
    } else if (isAug) {
      // Caug: x 3 2 1 1 x -> [-99, 0, -1, -2, -2, -99]
      cPattern = [-99, 0, -1, -2, -2, -99];
    } else if (isDim || isDim7) {
      cPattern = [-99, -99, -99, -99, -99, -99]; // Skip
    } else if (is6) {
      // C6: x 3 2 2 1 x -> [-99, 0, -1, -1, -2, -99]
      cPattern = [-99, 0, -1, -1, -2, -99];
    } else if (isMinor) {
      if (hasb7) {
        cPattern = [-99, 0, -2, 0, -2, -99];
      } else {
        cPattern = [-99, 0, -2, -3, -2, -99];
      }
    } else {
      if (hasb7) {
        cPattern = [-99, 0, -1, 0, -2, -3];
      } else if (hasM7) {
        cPattern = [-99, 0, -1, -3, -3, -3];
      } else {
        cPattern = [-99, 0, -1, -3, -2, -3];
      }
    }
    if (!cPattern.every((p) => p == -99)) {
      _addVoicingToResult(results, "C Form", 5, rootFret5, cPattern,
          tags: ['CAGED']);
    }

    // --- D Form (Root 4) ---
    List<int> dPattern;
    if (isSus4) {
      // Dsus4: x x 0 2 3 3 -> [-99, -99, 0, 2, 3, 3]
      dPattern = [-99, -99, 0, 2, 3, 3];
    } else if (isSus2) {
      // Dsus2: x x 0 2 3 0 -> [-99, -99, 0, 2, 3, 0]
      dPattern = [-99, -99, 0, 2, 3, 0];
    } else if (isAug) {
      // Daug: x x 0 3 3 2 -> [-99, -99, 0, 3, 3, 2]
      dPattern = [-99, -99, 0, 3, 3, 2];
    } else if (isDim || isDim7) {
      // Ddim7: x x 0 1 0 1 -> [-99, -99, 0, 1, 0, 1]
      dPattern = [-99, -99, 0, 1, 0, 1];
    } else if (is6) {
      // D6: x x 0 2 0 2 -> [-99, -99, 0, 2, 0, 2]
      dPattern = [-99, -99, 0, 2, 0, 2];
    } else if (isMinor) {
      if (hasb5 && hasb7) {
        dPattern = [-99, -99, 0, 1, 1, 1]; // m7b5
      } else if (hasb7) {
        dPattern = [-99, -99, 0, 2, 1, 1];
      } else {
        dPattern = [-99, -99, 0, 2, 3, 1];
      }
    } else {
      if (hasb7) {
        dPattern = [-99, -99, 0, 2, 1, 2];
      } else if (hasM7) {
        dPattern = [-99, -99, 0, 2, 2, 2];
      } else {
        dPattern = [-99, -99, 0, 2, 3, 2];
      }
    }

    int rootFret4 = (NoteUtils.getNoteIndex(root) - 2 + 12) % 12;
    _addVoicingToResult(results, "D Form", 4, rootFret4, dPattern,
        tags: ['CAGED']);

    return results;
  }

  static List<ChordVoicing> generateShellVoicings(String root, String quality) {
    final List<ChordVoicing> results = [];
    final (intervals, _, isMinor) = ChordUtils.parseChordQuality(quality);
    bool hasb7 = intervals.contains('b7') || intervals.contains('bb7');
    bool hasM7 = intervals.contains('7');

    if (!hasb7 && !hasM7) return results;

    List<int> eShellPattern;
    if (isMinor) {
      if (hasb7) {
        eShellPattern = [0, -99, 0, 0, -99, -99];
      } else {
        eShellPattern = [0, -99, 1, 0, -99, -99];
      }
    } else {
      if (hasb7) {
        eShellPattern = [0, -99, 0, 1, -99, -99];
      } else {
        eShellPattern = [0, -99, 1, 1, -99, -99];
      }
    }

    int idx = NoteUtils.getNoteIndex(root);
    int rootFret = (idx - 4 + 12) % 12;
    _addVoicingToResult(results, "Shell (R6)", 6, rootFret, eShellPattern,
        tags: ['Shell', 'Jazz']);

    List<int> aShellPattern;
    if (isMinor) {
      if (hasb7) {
        aShellPattern = [-99, 0, -2, 0, -99, -99];
      } else {
        aShellPattern = [-99, 0, -2, 1, -99, -99];
      }
    } else {
      if (hasb7) {
        aShellPattern = [-99, 0, -1, 0, -99, -99];
      } else {
        aShellPattern = [-99, 0, -1, 1, -99, -99];
      }
    }

    if (isMinor && hasb7) {
      aShellPattern = [-99, 0, -2, 0, -99, -99];
    }

    int rootFret5 = (NoteUtils.getNoteIndex(root) - 9 + 12) % 12;
    _addVoicingToResult(results, "Shell (R5)", 5, rootFret5, aShellPattern,
        tags: ['Shell', 'Jazz']);

    return results;
  }

  static List<ChordVoicing> generateDropVoicings(String root, String quality) {
    final List<ChordVoicing> results = [];
    final (intervals, _, isMinor) = ChordUtils.parseChordQuality(quality);
    bool hasb7 = intervals.contains('b7') || intervals.contains('bb7');
    bool hasb5 = intervals.contains('b5');
    bool hasM7 = intervals.contains('7');

    int idx = NoteUtils.getNoteIndex(root);

    List<int> drop3Root6;
    if (isMinor) {
      if (hasb5) {
        drop3Root6 = [0, -99, 0, 0, -1, -99];
      } else if (hasb7) {
        drop3Root6 = [0, -99, 0, 0, 0, -99];
      } else if (hasM7) {
        drop3Root6 = [0, -99, 1, 0, 0, -99];
      } else {
        drop3Root6 = [0, -99, 0, 0, 0, -99];
      }
    } else {
      if (hasb7) {
        drop3Root6 = [0, -99, 0, 1, 0, -99];
      } else {
        drop3Root6 = [0, -99, 1, 1, 0, -99];
      }
    }
    int rootFret6 = (idx - 4 + 12) % 12;
    _addVoicingToResult(results, "Drop 3 (R6)", 6, rootFret6, drop3Root6,
        tags: ['Drop', 'Jazz']);

    List<int> drop3Root5;
    if (isMinor) {
      if (hasb5) {
        drop3Root5 = [-99, 0, -99, 0, 1, -1];
      } else if (hasb7) {
        drop3Root5 = [-99, 0, -99, 0, 1, 0];
      } else if (hasM7) {
        drop3Root5 = [-99, 0, -99, 1, 1, 0];
      } else {
        drop3Root5 = [-99, 0, -99, 0, 1, 0];
      }
    } else {
      if (hasb7) {
        drop3Root5 = [-99, 0, -99, 0, 2, 0];
      } else {
        drop3Root5 = [-99, 0, -99, 1, 2, 0];
      }
    }
    int rootFret5 = (NoteUtils.getNoteIndex(root) - 9 + 12) % 12;
    _addVoicingToResult(results, "Drop 3 (R5)", 5, rootFret5, drop3Root5,
        tags: ['Drop', 'Jazz']);

    List<int> drop2Root4;
    if (isMinor) {
      if (hasb5) {
        drop2Root4 = [-99, -99, 0, 1, 1, 1];
      } else if (hasb7) {
        drop2Root4 = [-99, -99, 0, 2, 1, 1];
      } else if (hasM7) {
        drop2Root4 = [-99, -99, 0, 2, 2, 1];
      } else {
        drop2Root4 = [-99, -99, 0, 2, 1, 1];
      }
    } else {
      if (hasb7) {
        drop2Root4 = [-99, -99, 0, 2, 1, 2];
      } else {
        drop2Root4 = [-99, -99, 0, 2, 2, 2];
      }
    }
    int rootFret4 = (idx - 2 + 12) % 12;
    _addVoicingToResult(results, "Drop 2 (R4)", 4, rootFret4, drop2Root4,
        tags: ['Drop', 'Jazz']);

    return results;
  }

  static void _addVoicingToResult(List<ChordVoicing> list, String name,
      int rootString, int actualRootFret, List<int> pattern,
      {List<String> tags = const []}) {
    List<int> rawFrets = [];
    bool needsOctaveShift = false;

    for (int p in pattern) {
      if (p == -99) {
        rawFrets.add(-1);
      } else {
        int f = actualRootFret + p;
        if (f < 0) {
          needsOctaveShift = true;
        }
        rawFrets.add(f);
      }
    }

    List<int> frets;
    if (needsOctaveShift) {
      frets = rawFrets.map((f) => f == -1 ? -1 : f + 12).toList();
    } else {
      frets = rawFrets;
    }

    var finalTags = List<String>.from(tags);
    if (frets.contains(0) && !finalTags.contains('Open')) {
      finalTags.add('Open');
    }

    int minFret = 99;
    for (int f in frets) {
      if (f > 0 && f < minFret) minFret = f;
    }
    if (minFret == 99) minFret = 1;
    bool hasOpenString = frets.contains(0);
    int displayStartFret = hasOpenString ? 1 : minFret;

    list.add(ChordVoicing(
        frets: frets,
        startFret: displayStartFret,
        rootString: rootString,
        name: name,
        tags: finalTags));
  }
}
