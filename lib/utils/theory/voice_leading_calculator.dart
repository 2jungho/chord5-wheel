import '../../models/chord_model.dart';
import '../../models/progression/progression_models.dart';
import '../../models/fretboard_marker.dart';
import '../../utils/theory_utils.dart';
import '../../utils/guitar_utils.dart';

/// 스튜디오 타임라인 및 화성학 계산을 위한 순수 헬퍼 클래스
class VoiceLeadingCalculator {
  /// 현재 세션과 선택된 블록 인덱스를 바탕으로 보이스 리딩 연결선 목록을 계산합니다.
  static List<VoiceLeadingLine> calculateVoiceLeading({
    required ProgressionSession session,
    required int selectedBlockIndex,
  }) {
    if (session.progression.length < 2 ||
        selectedBlockIndex < 0 ||
        selectedBlockIndex >= session.progression.length) {
      return [];
    }

    final currentBlock = session.progression[selectedBlockIndex];
    final nextIndex = (selectedBlockIndex < session.progression.length - 1)
        ? selectedBlockIndex + 1
        : 0;
    final nextBlock = session.progression[nextIndex];

    if (currentBlock.voicing == null || nextBlock.voicing == null) {
      return [];
    }

    final root1 = currentBlock.chordDetail?.root ??
        TheoryUtils.analyzeChord(currentBlock.chordSymbol).root;
    final root2 = nextBlock.chordDetail?.root ??
        TheoryUtils.analyzeChord(nextBlock.chordSymbol).root;

    final map1 =
        GuitarUtils.generateMapFromVoicing(currentBlock.voicing!, root1);
    final map2 = GuitarUtils.generateMapFromVoicing(nextBlock.voicing!, root2);

    return GuitarUtils.calculateVoiceLeading(map1, map2);
  }

  /// 현재 Key의 Root Note를 주어진 [formStyle] (예: 'E Form')으로 잡았을 때의 프렛 앵커 위치를 계산합니다.
  static int calculateAnchorFret({
    required String key,
    required String formStyle,
  }) {
    if (formStyle == 'Auto') return 0;

    // Hybrid Form parsing (e.g., "C-A")
    if (formStyle.contains('-')) {
      final parts = formStyle.split('-');
      final form1 = parts[0];
      final form2 = parts[1];

      int anchor1 = calculateAnchorFret(key: key, formStyle: form1);
      int anchor2 = calculateAnchorFret(key: key, formStyle: form2);

      if (anchor2 < anchor1) {
        anchor2 += 12;
      }
      if ((anchor2 - anchor1).abs() > 6) {
        if (anchor2 > anchor1) anchor1 += 12;
      }

      return (anchor1 + anchor2) ~/ 2;
    }

    final keyParts = key.split(' ');
    final rootNote = TheoryUtils.normalizeNoteName(keyParts.isNotEmpty ? keyParts[0] : 'C');

    final cagedVoicings = GuitarUtils.generateCAGEDVoicings(rootNote, '');

    final match = cagedVoicings.firstWhere(
      (v) => v.name?.startsWith('$formStyle Form') ?? false,
      orElse: () => ChordVoicing(frets: [], startFret: 0, rootString: 6),
    );

    return match.startFret;
  }
}
