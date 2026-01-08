import '../../models/fretboard_marker.dart';
import '../../models/chord_model.dart';
import '../theory/note_utils.dart';
import 'tuning_utils.dart';

class FretboardMapper {
  static Map<int, List<FretboardMarker>> generateFretboardMap({
    required String root,
    required List<String> notes,
    List<String> ghostNotes = const [],
    String? scaleNameForIntervals,
    int maxFret = 17,
  }) {
    final newMap = <int, List<FretboardMarker>>{};
    
    int rootIdx = NoteUtils.getNoteIndex(root);
    Set<int> targetIndices =
        notes.map((n) => NoteUtils.getNoteIndex(n)).toSet();
    Set<int> ghostIndices =
        ghostNotes.map((n) => NoteUtils.getNoteIndex(n)).toSet();

    for (int strIdx = 0; strIdx < 6; strIdx++) {
      final openNote = TuningUtils.TUNING_NOTES[strIdx];
      final openVal = NoteUtils.getNoteIndex(openNote);

      if (!newMap.containsKey(strIdx)) newMap[strIdx] = [];

      for (int fret = 0; fret <= maxFret; fret++) {
        final noteVal = (openVal + fret) % 12;
        bool isTarget = targetIndices.contains(noteVal);
        bool isGhost = ghostIndices.contains(noteVal);

        if (isTarget || isGhost) {
          final diff = (noteVal - rootIdx + 12) % 12;
          final intervalName = _getIntervalName(diff, scaleNameForIntervals);

          final finalIsGhost = isGhost && !isTarget;

          newMap[strIdx]!.add(FretboardMarker(
            fret: fret,
            interval: intervalName,
            isGhost: finalIsGhost,
          ));
        }
      }
    }
    return newMap;
  }

  static Map<int, List<FretboardMarker>> generateMapFromVoicing(
      ChordVoicing voicing, String root) {
    final map = <int, List<FretboardMarker>>{};

    for (int i = 0; i < 6; i++) {
      final fret = voicing.frets[i];
      if (fret != -1) {
        final openVal = NoteUtils.getNoteIndex(TuningUtils.TUNING_NOTES[i]);
        final noteVal = (openVal + fret) % 12;

        final intervalName = generateFretboardMap(
                root: root, notes: [NoteUtils.getNoteName(noteVal, true)])
            .values
            .first
            .first
            .interval;

        map[i] = [
          FretboardMarker(fret: fret, interval: intervalName, isGhost: false)
        ];
      }
    }
    return map;
  }

  static String _getIntervalName(int semitones, String? contextScaleName) {
    if (semitones == 6) {
      if (contextScaleName != null &&
          (contextScaleName.contains('Lydian') ||
              contextScaleName.contains('Whole'))) {
        return '#4';
      }
      return 'd5';
    }

    const map = {
      0: '1P', 1: 'm2', 2: 'M2', 3: 'm3', 4: 'M3', 5: 'P4',
      // 6 handled
      7: 'P5', 8: 'm6', 9: 'M6', 10: 'm7', 11: 'M7'
    };
    return map[semitones] ?? '';
  }

  static String getVoicingDescription(ChordVoicing voicing) {
    if (voicing.tags.contains('Shell')) {
      return "가이드 톤(3도, 7도) 위주의 쉘 보이싱은 불필요한 음을 생략하여 명확한 리듬과 화성을 전달합니다. 주로 재즈 컴핑(Comping)에서 베이스나 피아노와 겹치지 않게 연주할 때 유용합니다.";
    }

    if (voicing.tags.contains('Drop')) {
      if (voicing.name?.contains('Drop 2') ?? false) {
        return "Drop 2 보이싱은 밀집 화음(Close voicing)에서 두 번째로 높은 음을 옥타브 아래로 떨어뜨려 만듭니다. 줄 건너뜀 없이 인접한 네 줄을 사용하거나(1234, 2345번 줄), 5번줄 루트 폼에서 자주 사용됩니다. 부드럽고 세련된 재즈 사운드를 만듭니다.";
      }
      if (voicing.name?.contains('Drop 3') ?? false) {
        return "Drop 3 보이싱은 밀집 화음에서 세 번째로 높은 음을 옥타브 아래로 떨어뜨립니다. 6번줄이나 5번줄을 루트로 하며, 중간에 줄을 하나 건너뛰는 구조입니다. 저음역대와 중음역대를 아우르는 풍성하고 개방적인 소리가 특징입니다.";
      }
      return "재즈 스타일의 Drop 보이싱으로, 성부의 배치를 넓게 하여 풍성하면서도 명료한 울림을 줍니다.";
    }

    if (voicing.tags.contains('CAGED')) {
      String form = "";
      if (voicing.name?.startsWith('E Form') ?? false)
        form = "E";
      else if (voicing.name?.startsWith('A Form') ?? false)
        form = "A";
      else if (voicing.name?.startsWith('D Form') ?? false)
        form = "D";
      else if (voicing.name?.startsWith('G Form') ?? false)
        form = "G";
      else if (voicing.name?.startsWith('C Form') ?? false) form = "C";

      return "CAGED 시스템의 $form 폼을 기반으로 한 보이싱입니다. 개방현 코드($form 코드)의 모양을 그대로 지판 위로 옮겨온 형태로, 넥 전체에서 코드를 찾고 연결하는 데 기초가 됩니다.";
    }

    if (voicing.tags.contains('Open')) {
      return "개방현(Open String)을 포함하여 풍성하고 긴 서스테인을 가진 보이싱입니다. 어쿠스틱 기타 스트러밍이나 포크, 팝 스타일 연주에 적합합니다.";
    }

    return "기본적인 트라이어드(3화음) 또는 7화음 구조의 보이싱입니다.";
  }
}
