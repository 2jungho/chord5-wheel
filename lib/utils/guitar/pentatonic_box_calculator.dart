import '../../models/fretboard_marker.dart';
import '../theory/note_utils.dart';
import '../theory/scale_utils.dart';

class PentatonicBox {
  final int boxNumber; // 1 to 5
  final String name; // e.g. "Box 1 (기본 마이너 폼)"
  final int startFret;
  final int endFret;
  final String rootNote;
  final bool isMinor;

  const PentatonicBox({
    required this.boxNumber,
    required this.name,
    required this.startFret,
    required this.endFret,
    required this.rootNote,
    required this.isMinor,
  });
}

class PentatonicBoxCalculator {
  /// 1~5번 펜타토닉 박스 정의 (루트 프렛 오프셋 기준)
  static const List<({int boxNum, String name, int offsetStart, int offsetEnd})> _boxDefinitions = [
    (boxNum: 1, name: 'Box 1 (6번줄 루트 폼)', offsetStart: 0, offsetEnd: 3),
    (boxNum: 2, name: 'Box 2 (확장 폼)', offsetStart: 2, offsetEnd: 5),
    (boxNum: 3, name: 'Box 3 (5번줄 루트 폼)', offsetStart: 5, offsetEnd: 8),
    (boxNum: 4, name: 'Box 4 (중간 폼)', offsetStart: 7, offsetEnd: 10),
    (boxNum: 5, name: 'Box 5 (저음 폼)', offsetStart: 9, offsetEnd: 12),
  ];

  /// 특정 Key(메이저 또는 마이너)에 대한 5가지 펜타토닉 박스 목록 반환
  static List<PentatonicBox> getBoxesForKey(String keyRoot, bool isMinorKey) {
    // 마이너 펜타토닉 루트 기준으로 정규화
    // 메이저 키의 경우 나란한한조(Relative Minor)로 변환: Major Root - 3 반음
    final minorRootName = isMinorKey
        ? keyRoot
        : NoteUtils.transposeNote(keyRoot, -3);

    final minorRootIdx = NoteUtils.getNoteIndex(minorRootName);
    // 6번줄(E)에서의 프렛 위치 (E=4) -> (minorRootIdx - 4 + 12) % 12
    final baseFret = (minorRootIdx - 4 + 12) % 12;

    return _boxDefinitions.map((def) {
      int start = (baseFret + def.offsetStart) % 12;
      int end = start + (def.offsetEnd - def.offsetStart);
      return PentatonicBox(
        boxNumber: def.boxNum,
        name: def.name,
        startFret: start,
        endFret: end,
        rootNote: minorRootName,
        isMinor: isMinorKey,
      );
    }).toList();
  }

  /// 특정 박스에 속하는 프렛보드 마커 맵 생성 (블루스 노트 및 타겟 톤 포함)
  static Map<int, List<FretboardMarker>> generateBoxMarkers({
    required String keyRoot,
    required bool isMinorKey,
    required int boxNumber, // 1 to 5 (0 = 전체 박스)
    String? currentChordRoot,
  }) {
    final minorRoot = isMinorKey ? keyRoot : NoteUtils.transposeNote(keyRoot, -3);
    final minorRootIdx = NoteUtils.getNoteIndex(minorRoot);
    final pentatonicNotes = ScaleUtils.calculateScaleNotes(minorRoot, 'Minor Pentatonic');
    
    // Blue Note = minor root + 6 semitones (b5)
    final blueNoteIdx = (minorRootIdx + 6) % 12;

    final boxes = getBoxesForKey(keyRoot, isMinorKey);
    final selectedBox = boxes.firstWhere(
      (b) => b.boxNumber == boxNumber,
      orElse: () => boxes.first,
    );

    final tuning = [4, 9, 2, 7, 11, 4]; // E, A, D, G, B, E (0=Low E, 5=High E)
    final result = <int, List<FretboardMarker>>{};

    for (int stringIdx = 0; stringIdx < 6; stringIdx++) {
      final openNote = tuning[stringIdx];
      final markers = <FretboardMarker>[];

      for (int fret = 0; fret <= 15; fret++) {
        // 박스 범위 필터 (boxNumber > 0 일 때)
        if (boxNumber > 0) {
          final inRange = (fret >= selectedBox.startFret && fret <= selectedBox.endFret) ||
              (fret >= selectedBox.startFret + 12 && fret <= selectedBox.endFret + 12);
          if (!inRange) continue;
        }

        final noteIdx = (openNote + fret) % 12;
        final isScaleNote = pentatonicNotes.any((n) => NoteUtils.getNoteIndex(n) == noteIdx);

        final isBlueNote = (noteIdx == blueNoteIdx);
        final isRoot = (noteIdx == minorRootIdx);
        final isChordRoot = (currentChordRoot != null &&
            NoteUtils.getNoteIndex(currentChordRoot) == noteIdx);

        if (isScaleNote || isBlueNote) {
          String interval = isRoot ? '1P' : (isBlueNote ? 'b5' : 'P5');


          markers.add(FretboardMarker(
            fret: fret,
            interval: interval,
            isGhost: !isRoot && !isBlueNote && !isChordRoot,
          ));
        }
      }
      result[stringIdx] = markers;
    }

    return result;
  }
}
