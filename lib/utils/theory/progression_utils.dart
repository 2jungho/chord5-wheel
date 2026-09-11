import '../../models/progression/progression_models.dart';
import '../../models/progression/progression_presets.dart';
import 'note_utils.dart';
import 'scale_utils.dart';
import 'chord_utils.dart';

class ProgressionUtils {
  static List<ChordBlock> parseProgressionText(String text, String key) {
    if (text.isEmpty) return [];

    final List<ChordBlock> blocks = [];
    final tokens = text.split(RegExp(r'[-\s,]+'));

    final keyParts = key.split(' ');
    final keyRoot = NoteUtils.normalizeNoteName(keyParts[0]);
    final isMinor = keyParts.length > 1 && keyParts[1] == 'Minor';

    final scaleName = isMinor ? 'Aeolian' : 'Ionian';
    final scaleNotes = ScaleUtils.calculateScaleNotes(keyRoot, scaleName);

    final qualities = isMinor
        ? ['m7', 'm7b5', 'Maj7', 'm7', '7', 'Maj7', '7']
        : ['Maj7', 'm7', 'm7', 'Maj7', '7', 'm7', 'm7b5'];

    for (String token in tokens) {
      if (token.isEmpty) continue;

      String chordSymbol = '';
      String? functionTag;

      final degreeMatch = RegExp(r'^([1-7]|[iIvV]+)(.*)$').firstMatch(token);
      if (degreeMatch != null) {
        String degStr = degreeMatch.group(1)!.toLowerCase();
        String suffix = degreeMatch.group(2)!;

        int degree = 0;
        if (RegExp(r'^[1-7]$').hasMatch(degStr)) {
          degree = int.parse(degStr);
        } else {
          const romanMap = {
            'i': 1,
            'ii': 2,
            'iii': 3,
            'iv': 4,
            'v': 5,
            'vi': 6,
            'vii': 7
          };
          degree = romanMap[degStr] ?? 0;
        }

        if (degree >= 1 && degree <= 7 && scaleNotes.length == 7) {
          final root = scaleNotes[degree - 1];
          final quality = qualities[degree - 1];
          chordSymbol = root + quality;
          functionTag = isMinor
              ? ChordUtils.getMinorRomanNumeral(degree)
              : ChordUtils.getRomanNumeral(degree);

          if (suffix.isNotEmpty) {
            if (suffix == 'dom' || suffix == '7') {
              chordSymbol = '${root}7';
            } else if (suffix == 'm' || suffix == 'min') {
              chordSymbol = '${root}m7';
            } else if (suffix == 'maj' || suffix == 'M') {
              chordSymbol = '${root}Maj7';
            }
          }
        }
      }

      if (chordSymbol.isEmpty) {
        chordSymbol = token;
        if (chordSymbol.isNotEmpty) {
          chordSymbol = chordSymbol[0].toUpperCase() + chordSymbol.substring(1);
        }
      }

      if (functionTag == null && chordSymbol.isNotEmpty) {
        functionTag = getFunctionTag(key, chordSymbol);
      }

      if (chordSymbol.isNotEmpty) {
        blocks.add(ChordBlock(
          chordSymbol: chordSymbol,
          duration: 4,
          functionTag: functionTag,
        ));
      }
    }

    return blocks;
  }

  static String? getFunctionTag(String key, String chordSymbol) {
    if (key.isEmpty || chordSymbol.isEmpty) return null;

    final keyParts = key.split(' ');
    final keyRoot = NoteUtils.normalizeNoteName(keyParts[0]);
    final isMinor = keyParts.length > 1 && keyParts[1] == 'Minor';

    final scaleName = isMinor ? 'Aeolian' : 'Ionian';
    final scaleNotes = ScaleUtils.calculateScaleNotes(keyRoot, scaleName);

    final chordRoot = ChordUtils.analyzeChord(chordSymbol).root;
    final chordRootIdx = NoteUtils.getNoteIndex(chordRoot);

    int degree = -1;
    for (int i = 0; i < scaleNotes.length; i++) {
      if (NoteUtils.getNoteIndex(scaleNotes[i]) == chordRootIdx) {
        degree = i + 1;
        break;
      }
    }

    if (degree != -1) {
      return isMinor
          ? ChordUtils.getMinorRomanNumeral(degree)
          : ChordUtils.getRomanNumeral(degree);
    }
    return null;
  }

  static ProgressionPreset? matchProgressionToPreset(
      List<ChordBlock> progression) {
    if (progression.isEmpty) return null;

    final currentTags = progression.map((b) => b.functionTag ?? '?').join('-');

    for (final preset in kProgressionPresets) {
      final blocksMajor = parseProgressionText(preset.progression, 'C Major');
      final presetTagsMajor =
          blocksMajor.map((b) => b.functionTag ?? '?').join('-');

      if (currentTags == presetTagsMajor) {
        return preset;
      }

      final blocksMinor = parseProgressionText(preset.progression, 'A Minor');
      final presetTagsMinor =
          blocksMinor.map((b) => b.functionTag ?? '?').join('-');

      if (currentTags == presetTagsMinor) {
        return preset;
      }

      final majorToMinorMap = {
        'I': 'i',
        'ii': 'ii°',
        'iii': 'bIII',
        'IV': 'iv',
        'V': 'v',
        'vi': 'bVI',
        'vii°': 'bVII',
        'vii': 'bVII',
      };

      final presetTagsParallel = blocksMajor.map((b) {
        final tag = b.functionTag ?? '';
        return majorToMinorMap[tag] ?? tag;
      }).join('-');

      if (currentTags == presetTagsParallel) {
        return preset;
      }
    }
    return null;
  }

  /// 키 또는 모드가 변경되었을 때 코드 진행의 각 코드를 전조 및 다이아토닉 매핑하여 반환합니다.
  static List<({String symbol, String? tag, ChordBlock originalBlock})>
      calculateRemappedChords({
    required List<ChordBlock> progression,
    required String oldKey,
    required String newKey,
  }) {
    if (oldKey == newKey || progression.isEmpty) {
      return progression
          .map((b) => (
                symbol: b.chordSymbol,
                tag: b.functionTag,
                originalBlock: b,
              ))
          .toList();
    }

    final oldKeyParts = oldKey.split(' ');
    final oldRootStr = NoteUtils.normalizeNoteName(oldKeyParts[0]);
    final oldMode = oldKeyParts.length > 1 ? oldKeyParts[1] : 'Major';

    final newKeyParts = newKey.split(' ');
    final newRootStr = NoteUtils.normalizeNoteName(newKeyParts[0]);
    final newMode = newKeyParts.length > 1 ? newKeyParts[1] : 'Major';

    final oldIdx = NoteUtils.getNoteIndex(oldRootStr);
    final newIdx = NoteUtils.getNoteIndex(newRootStr);
    final semitones = newIdx - oldIdx;

    if (oldMode != newMode) {
      final oldScaleName = oldMode == 'Minor' ? 'Aeolian' : 'Ionian';
      final newScaleName = newMode == 'Minor' ? 'Aeolian' : 'Ionian';

      final oldScaleNotes =
          ScaleUtils.calculateScaleNotes(oldRootStr, oldScaleName);
      final newDiatonics = ChordUtils.getDiatonicChords(
          ScaleUtils.calculateScaleNotes(newRootStr, newScaleName),
          newScaleName);

      return progression.map((block) {
        final chord = ChordUtils.analyzeChord(block.chordSymbol);
        final chordRootIdx = NoteUtils.getNoteIndex(chord.root);

        int degreeIndex = -1;
        for (int i = 0; i < oldScaleNotes.length; i++) {
          final noteIdx = NoteUtils.getNoteIndex(oldScaleNotes[i]);
          if (noteIdx == chordRootIdx) {
            degreeIndex = i;
            break;
          }
        }

        if (degreeIndex != -1 && degreeIndex < newDiatonics.length) {
          final newChordData = newDiatonics[degreeIndex];
          final newSymbol = newChordData.root + newChordData.quality;
          final isMinor = newMode == 'Minor';
          final newTag = isMinor
              ? ChordUtils.getMinorRomanNumeral(degreeIndex + 1)
              : ChordUtils.getRomanNumeral(degreeIndex + 1);

          return (
            symbol: newSymbol,
            tag: newTag,
            originalBlock: block,
          );
        } else {
          final newSymbol =
              ChordUtils.transposeChord(block.chordSymbol, semitones);
          return (
            symbol: newSymbol,
            tag: block.functionTag,
            originalBlock: block,
          );
        }
      }).toList();
    } else {
      return progression.map((block) {
        final newSymbol =
            ChordUtils.transposeChord(block.chordSymbol, semitones);
        return (
          symbol: newSymbol,
          tag: block.functionTag,
          originalBlock: block,
        );
      }).toList();
    }
  }
}
