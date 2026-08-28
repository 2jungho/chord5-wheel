import '../utils/theory/chord_utils.dart';
import '../utils/theory/note_utils.dart';

/// 화성학적 추천 경과화음 모델
class HarmonicSuggestion {
  final String chordSymbol;
  final String category; // e.g. '세컨더리 도미넌트 (V7)', '트라이톤 대리 (SubV7)', '디미니시 경과음', '2-5-1 분할'
  final String romanNumeral; // e.g. 'V7/vi', 'subV7/ii', '#Idim7'
  final String description; // 한국어 화성학 설명
  final List<String> notes;

  const HarmonicSuggestion({
    required this.chordSymbol,
    required this.category,
    required this.romanNumeral,
    required this.description,
    required this.notes,
  });
}

class HarmonicSuggestionService {
  /// 타겟 코드(Target Chord)와 현재 키(Key)를 분석하여 앞에 삽입하기 좋은 화성학적 경과화음 리스트 반환
  static List<HarmonicSuggestion> getSuggestionsForTarget({
    required String targetChordSymbol,
    String currentKey = 'C Major',
  }) {
    if (targetChordSymbol.isEmpty) return [];

    final suggestions = <HarmonicSuggestion>[];
    final targetChord = ChordUtils.analyzeChord(targetChordSymbol);
    final targetRoot = targetChord.root;
    final isTargetMinor = targetChord.quality.contains('m') && !targetChord.quality.contains('maj');

    final targetRootIdx = NoteUtils.getNoteIndex(targetRoot);

    // 1. 세컨더리 도미넌트 (Secondary Dominant - V7 of Target)
    // Target의 5도 위 = +7 반음
    final v7RootIdx = (targetRootIdx + 7) % 12;
    final v7Root = NoteUtils.getNoteName(v7RootIdx, !targetRoot.contains('b'));
    final v7Symbol = '${v7Root}7';
    final v7Chord = ChordUtils.analyzeChord(v7Symbol);
    suggestions.add(HarmonicSuggestion(
      chordSymbol: v7Symbol,
      category: '세컨더리 도미넌트 (V7)',
      romanNumeral: 'V7/$targetChordSymbol',
      description: '$targetChordSymbol(으)로 강한 해결감(Tension & Release)을 만들어주는 5도 도미넌트 세븐스 코드입니다.',
      notes: v7Chord.notes,
    ));

    // 1-1. 재즈/얼터드 텐션 세컨더리 도미넌트 (V7b9)
    if (isTargetMinor) {
      final v7b9Symbol = '${v7Root}7b9';
      final v7b9Chord = ChordUtils.analyzeChord(v7b9Symbol);
      suggestions.add(HarmonicSuggestion(
        chordSymbol: v7b9Symbol,
        category: '얼터드 세컨더리 (V7b9)',
        romanNumeral: 'V7(b9)/$targetChordSymbol',
        description: '마이너 코드로 진입할 때 매력적이고 어두운 긴장감을 더해주는 재즈/네오소울 텐션 코드입니다.',
        notes: v7b9Chord.notes,
      ));
    }

    // 2. 트라이톤 대리코드 (Tritone Substitution - SubV7)
    // Target의 반음 위 = +1 반음 (또는 V7의 증4도 대리)
    final subV7RootIdx = (targetRootIdx + 1) % 12;
    final subV7Root = NoteUtils.getNoteName(subV7RootIdx, false);
    final subV7Symbol = '${subV7Root}7';
    final subV7Chord = ChordUtils.analyzeChord(subV7Symbol);
    suggestions.add(HarmonicSuggestion(
      chordSymbol: subV7Symbol,
      category: '트라이톤 대리 (SubV7)',
      romanNumeral: 'SubV7/$targetChordSymbol',
      description: '베이스가 반음 하행($subV7Root → $targetRoot)하며 세련되고 부드러운 재즈 사운드를 연출합니다.',
      notes: subV7Chord.notes,
    ));

    // 3. 상행 디미니시 경과음 (Passing Diminished 7th)
    // Target의 반음 아래 = -1 반음
    final dimRootIdx = (targetRootIdx - 1 + 12) % 12;
    final dimRoot = NoteUtils.getNoteName(dimRootIdx, true);
    final dimSymbol = '${dimRoot}dim7';
    final dimChord = ChordUtils.analyzeChord(dimSymbol);
    suggestions.add(HarmonicSuggestion(
      chordSymbol: dimSymbol,
      category: '상행 디미니시 (#Idim7)',
      romanNumeral: '#Idim7',
      description: '반음 상행($dimRoot → $targetRoot)하며 클래식과 보사노바에서 자주 쓰이는 우아한 경과음입니다.',
      notes: dimChord.notes,
    ));

    // 4. 서브도미넌트 마이너 (Minor Plagal / Backdoor)
    // Target이 C 메이저 계열인 경우 Bb7 또는 Fm 계열
    if (!isTargetMinor) {
      final bviiRootIdx = (targetRootIdx - 2 + 12) % 12;
      final bviiRoot = NoteUtils.getNoteName(bviiRootIdx, false);
      final bviiSymbol = '${bviiRoot}7';
      final bviiChord = ChordUtils.analyzeChord(bviiSymbol);
      suggestions.add(HarmonicSuggestion(
        chordSymbol: bviiSymbol,
        category: '백도어 도미넌트 (bVII7)',
        romanNumeral: 'bVII7',
        description: 'V7 대신 사용하여 감성적인 팝/R&B 느낌으로 종지(Cadence)를 완성합니다.',
        notes: bviiChord.notes,
      ));
    }

    return suggestions;
  }
}
