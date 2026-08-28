import '../utils/theory/chord_utils.dart';
import '../utils/theory/note_utils.dart';

/// 카포(Capo) 프렛별 변환 결과 및 연주 난이도 모델
class CapoOption {
  final int fret;
  final List<String> transposedChords;
  final int openChordCount;
  final int barreChordCount;
  final double score; // 0.0 ~ 100.0
  final String keyFormName; // e.g. "C 폼", "G 폼", "D 폼", "Am 폼"

  const CapoOption({
    required this.fret,
    required this.transposedChords,
    required this.openChordCount,
    required this.barreChordCount,
    required this.score,
    required this.keyFormName,
  });

  bool get isAllOpen => openChordCount == transposedChords.length && transposedChords.isNotEmpty;
}

class CapoService {
  /// 취미 기타리스트가 잡기 쉬운 대표적인 오픈 코드 목록 (루트 + 기본 퀄리티)
  static const Set<String> _friendlyOpenChords = {
    // 5대 오픈 메이저 (CAGED Open)
    'C', 'G', 'D', 'A', 'E',
    // 대표 오픈 마이너
    'Am', 'Em', 'Dm',
    // 쉬운 오픈 7th / 텐션
    'Cmaj7', 'G7', 'D7', 'A7', 'E7', 'Em7', 'Am7', 'Dm7', 'Cadd9', 'Dsus4', 'Asus2', 'Asus4', 'Fmaj7', 'B7'
  };

  /// 특정 코드가 오픈 폼으로 연주 가능한 쉬운 코드인지 판별
  static bool isOpenFriendly(String chordSymbol) {
    if (chordSymbol.isEmpty) return false;
    final clean = chordSymbol.split('/')[0].trim();
    if (_friendlyOpenChords.contains(clean)) return true;

    // 추가로 단순 3화음 메이저/마이너 중 오픈 가능한 것 체크
    final root = NoteUtils.normalizeNoteName(clean.length >= 2 && (clean[1] == '#' || clean[1] == 'b') ? clean.substring(0, 2) : clean.substring(0, 1));
    const easyRoots = {'C', 'G', 'D', 'A', 'E'};
    const easyMinorRoots = {'A', 'E', 'D'};
    final isMinor = clean.contains('m') && !clean.contains('maj');

    if (isMinor) {
      return easyMinorRoots.contains(root);
    } else {
      return easyRoots.contains(root);
    }
  }

  /// 카포를 끼웠을 때 연주해야 하는 코드 계산 (N프렛 카포 시 소리는 N반음 높아지므로, 손가락 폼은 N반음 내려야 함)
  static String transposeForCapo(String originalChord, int capoFret) {
    if (capoFret == 0 || originalChord.isEmpty) return originalChord;
    // Capo N means actual sound = fingered + N.
    // Therefore fingered = original - N semitones.
    return ChordUtils.transposeChord(originalChord, -capoFret);
  }

  /// 전체 코드 진행에 대해 1~9 프렛의 카포 옵션을 분석하고 난이도 순으로 정렬하여 반환
  static List<CapoOption> calculateCapoOptions(List<String> originalChords) {
    if (originalChords.isEmpty) return [];

    final options = <CapoOption>[];

    // Capo 0 (원곡 그대로)부터 Capo 9까지 계산
    for (int fret = 0; fret <= 9; fret++) {
      final transposed = originalChords.map((c) => transposeForCapo(c, fret)).toList();
      
      int openCount = 0;
      int barreCount = 0;

      for (var chord in transposed) {
        if (isOpenFriendly(chord)) {
          openCount++;
        } else {
          barreCount++;
        }
      }

      // 점수 계산: 오픈 코드 비율(70%) + 낮은 프렛 선호도(30%)
      final total = transposed.length;
      final openRatio = total > 0 ? (openCount / total) : 0.0;
      final fretPenalty = fret * 3.0; // 프렛이 너무 높으면 손이 비좁아지므로 약간 감점
      double score = (openRatio * 100.0) - fretPenalty;
      if (score < 0) score = 0;

      // 대표 Key Form 이름 (첫 번째 코드 또는 가장 쉬운 루트 기준)
      String keyForm = '';
      if (transposed.isNotEmpty) {
        final firstRoot = transposed[0].length >= 2 && (transposed[0][1] == '#' || transposed[0][1] == 'b')
            ? transposed[0].substring(0, 2)
            : transposed[0].substring(0, 1);
        keyForm = '$firstRoot 폼';
      }

      options.add(CapoOption(
        fret: fret,
        transposedChords: transposed,
        openChordCount: openCount,
        barreChordCount: barreCount,
        score: score,
        keyFormName: keyForm,
      ));
    }

    // 최고 점수 순 정렬 (단, Capo 0도 옵션에 포함)
    return options;
  }

  /// 가장 추천하는 최적의 카포 옵션 1개 반환
  static CapoOption? getBestCapoOption(List<String> originalChords) {
    final list = calculateCapoOptions(originalChords);
    if (list.isEmpty) return null;

    // Capo > 0 중 점수가 가장 높은 것 또는 Capo 0보다 개선된 것 찾기
    final filtered = list.where((o) => o.fret > 0).toList();
    if (filtered.isEmpty) return list.first;

    filtered.sort((a, b) => b.score.compareTo(a.score));
    return filtered.first;
  }
}
