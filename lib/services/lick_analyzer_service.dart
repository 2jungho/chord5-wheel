import '../models/lick/artist_lick_model.dart';
import '../models/fretboard_marker.dart';
import '../utils/theory/note_utils.dart';
import '../utils/theory/chord_utils.dart';

/// 아티스트 릭의 조옮김(Transposition), 화성학 분석, 지판 마커 생성을 담당하는 순수 서비스
class LickAnalyzerService {
  /// 기타 줄(1~6)과 프렛(0~24)에 따른 절대 세미톤 피치를 반환합니다.
  static int calculateAbsolutePitch(int string, int fret) {
    const stringBaseSemitones = [52, 47, 43, 38, 33, 28]; // 1번줄 ~ 6번줄
    final strIndex = (string - 1).clamp(0, 5);
    return stringBaseSemitones[strIndex] + fret;
  }

  /// 릭의 기본 키(defaultKey)에서 목표 키(toKey)로 릭의 모든 음을 조옮김(Transpose)합니다.
  static ArtistLick transposeLick(
    ArtistLick lick, {
    required String toKey,
  }) {
    final fromRoot = NoteUtils.normalizeNoteName(lick.defaultKey.split(' ')[0]);
    final toRoot = NoteUtils.normalizeNoteName(toKey.split(' ')[0]);

    int semitones = (NoteUtils.getNoteIndex(toRoot) - NoteUtils.getNoteIndex(fromRoot)) % 12;
    if (semitones > 6) semitones -= 12;
    if (semitones < -6) semitones += 12;

    if (semitones == 0) return lick;

    // 타겟 코드 전조
    final newTargetChord = ChordUtils.transposeChord(lick.targetChord, semitones);

    // 각 노트 전조 및 프렛 범위 보정
    final transposedNotes = lick.notes.map((note) {
      final newNoteName = NoteUtils.transposeNote(note.noteName, semitones);
      int newFret = note.fret + semitones;

      // 지판 범위 (0 ~ 17프렛) 보정
      if (newFret < 0) {
        newFret += 12;
      } else if (newFret > 17) {
        newFret -= 12;
      }

      return note.copyWith(
        fret: newFret,
        noteName: newNoteName,
      );
    }).toList();

    return lick.copyWith(
      defaultKey: toKey,
      targetChord: newTargetChord,
      notes: transposedNotes,
    );
  }

  /// 릭의 각 음이 배경 코드(chordSymbol)와 만났을 때의 화성학적 관계를 분석합니다.
  static ({String summary, List<String> noteAnalyses}) analyzeHarmonicContext(
    ArtistLick lick,
    String chordSymbol,
  ) {
    final analyzedChord = ChordUtils.analyzeChord(chordSymbol);
    final chordRoot = analyzedChord.root;
    final chordNotes = analyzedChord.notes;

    final noteAnalyses = <String>[];
    int targetNoteCount = 0;
    int blueNoteCount = 0;

    for (int i = 0; i < lick.notes.length; i++) {
      final note = lick.notes[i];
      final noteName = note.noteName;
      final semitones = (NoteUtils.getNoteIndex(noteName) - NoteUtils.getNoteIndex(chordRoot) + 12) % 12;

      String role;
      if (noteName == chordRoot) {
        role = 'Root (안정적 종결)';
        targetNoteCount++;
      } else if (chordNotes.contains(noteName)) {
        role = '코드톤 (${note.interval}, 완벽한 화성적 착지)';
        targetNoteCount++;
      } else if (semitones == 6) {
        role = '블루노트 b5 (강렬한 긴장감/Blues Tension)';
        blueNoteCount++;
      } else if (semitones == 2) {
        role = '9도 (감미로운 텐션/Add9)';
      } else if (semitones == 9) {
        role = '장6도 13th (세련된 재지 사운드)';
      } else {
        role = '경과음 (${note.interval} Passing Tone)';
      }

      noteAnalyses.add('${i + 1}번째 음 [$noteName] : $role');
    }

    final summaryBuffer = StringBuffer();
    summaryBuffer.write('$chordSymbol 코드 위에서 연주 시: ');
    if (targetNoteCount >= 2) {
      summaryBuffer.write('핵심 코드톤을 정밀하게 타겟팅하여 화성적 안정감이 뛰어납니다. ');
    }
    if (blueNoteCount > 0) {
      summaryBuffer.write('b5 블루노트를 경유하여 정통 블루스의 매운맛(Tension)을 자아냅니다. ');
    }
    summaryBuffer.write('사용 폼: ${lick.cagedForm} (펜타토닉 Box ${lick.pentatonicBox}).');

    return (
      summary: summaryBuffer.toString(),
      noteAnalyses: noteAnalyses,
    );
  }

  /// 릭의 노트들을 FretboardMapWidget에서 사용할 highlightMap으로 변환합니다.
  static Map<int, List<FretboardMarker>> mapLickToHighlightMap(ArtistLick lick) {
    final Map<int, List<FretboardMarker>> map = {
      0: [],
      1: [],
      2: [],
      3: [],
      4: [],
      5: [],
    };

    for (final note in lick.notes) {
      // 1번줄(고음 E) -> 인덱스 5, 6번줄(저음 E) -> 인덱스 0
      final strIdx = (6 - note.string).clamp(0, 5);

      // 중복 프렛 체크 방지 (같은 위치에 여러 번 칠 경우 인터벌 유지)
      final existingIndex = map[strIdx]!.indexWhere((m) => m.fret == note.fret);
      if (existingIndex == -1) {
        map[strIdx]!.add(FretboardMarker(
          fret: note.fret,
          interval: note.interval,
          isGhost: false,
        ));
      }
    }

    return map;
  }

  /// 릭의 연속적인 음들의 진행 방향을 프렛보드 상의 연결선(VoiceLeadingLine)으로 생성합니다.
  static List<VoiceLeadingLine> generateLickFlowLines(ArtistLick lick) {
    final lines = <VoiceLeadingLine>[];
    if (lick.notes.length < 2) return lines;

    for (int i = 0; i < lick.notes.length - 1; i++) {
      final current = lick.notes[i];
      final next = lick.notes[i + 1];

      final fromStr = (6 - current.string).clamp(0, 5);
      final toStr = (6 - next.string).clamp(0, 5);

      lines.add(VoiceLeadingLine(
        fromStr: fromStr,
        fromFret: current.fret,
        toStr: toStr,
        toFret: next.fret,
        interval: next.interval,
        type: next.isTargetNote
            ? VoiceLeadingType.resolution
            : VoiceLeadingType.economical,
      ));
    }

    return lines;
  }
}
