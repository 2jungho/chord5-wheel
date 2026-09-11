import '../models/lick/artist_lick_model.dart';
import '../models/lick/artist_lick_presets.dart';
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

  /// 5대 펜타토닉 / CAGED Box 정의
  static const List<({int boxNumber, String cagedForm, String name, String description, int baseOffset})> cagedBoxDefinitions = [
    (boxNumber: 1, cagedForm: 'E Form', name: 'Box 1 (E Form)', description: '6번줄 루트 폼', baseOffset: 0),
    (boxNumber: 2, cagedForm: 'D Form', name: 'Box 2 (D Form)', description: '4번줄 루트 폼', baseOffset: 2),
    (boxNumber: 3, cagedForm: 'C Form', name: 'Box 3 (C Form)', description: '5번줄 루트 폼', baseOffset: 5),
    (boxNumber: 4, cagedForm: 'A Form', name: 'Box 4 (A Form)', description: '고음/5번줄 루트 폼', baseOffset: 7),
    (boxNumber: 5, cagedForm: 'G Form', name: 'Box 5 (G Form)', description: '저음/6번줄 루트 폼', baseOffset: 10),
  ];

  /// 릭의 음들을 목표하는 CAGED Box(1~5)의 프렛보드 위치로 매핑하여 새로운 ArtistLick을 반환합니다.
  static ArtistLick mapLickToBox(
    ArtistLick lick,
    int targetBox, {
    String? key,
  }) {
    if (targetBox == lick.pentatonicBox || lick.notes.isEmpty) {
      return lick;
    }

    final targetDef = cagedBoxDefinitions.firstWhere(
      (d) => d.boxNumber == targetBox,
      orElse: () => cagedBoxDefinitions.first,
    );

    final origDef = cagedBoxDefinitions.firstWhere(
      (d) => d.boxNumber == lick.pentatonicBox,
      orElse: () => cagedBoxDefinitions.first,
    );

    // 원곡 릭의 평균 프렛 계산
    double avgFret = 0.0;
    for (final n in lick.notes) {
      avgFret += n.fret;
    }
    avgFret /= lick.notes.length;

    // 목표 박스 오프셋 적용
    int offset = targetDef.baseOffset - origDef.baseOffset;
    if (offset > 6) offset -= 12;
    if (offset < -6) offset += 12;

    int targetCenterFret = (avgFret + offset).round();
    while (targetCenterFret < 2) {
      targetCenterFret += 12;
    }
    while (targetCenterFret > 15) {
      targetCenterFret -= 12;
    }

    // 각 줄별 개방현 음 (1: E4(52), 2: B3(47), 3: G3(43), 4: D3(38), 5: A2(33), 6: E2(28))
    const stringBaseSemitones = [0, 52, 47, 43, 38, 33, 28];

    // 첫 번째 음의 후보군 생성
    final firstNote = lick.notes.first;
    final firstCandidates = _findCandidatesForNote(
      firstNote,
      targetCenterFret,
      stringBaseSemitones,
    );

    if (firstCandidates.isEmpty) {
      return lick.copyWith(
        cagedForm: targetDef.cagedForm,
        pentatonicBox: targetBox,
      );
    }

    // 최적 경로 탐색 (최소 스트링 점프 & 최소 프렛 이동 & 같은 줄 테크닉 보존)
    List<LickNote> bestPath = [];
    double bestScore = double.infinity;

    for (final initialCandidate in firstCandidates) {
      final currentPath = [initialCandidate];
      double currentScore = (initialCandidate.fret - targetCenterFret).abs() * 1.0;

      for (int i = 1; i < lick.notes.length; i++) {
        final prev = currentPath.last;
        final origNote = lick.notes[i];
        final prevOrigNote = lick.notes[i - 1];

        final candidates = _findCandidatesForNote(
          origNote,
          targetCenterFret,
          stringBaseSemitones,
        );

        LickNote? bestNext;
        double bestStepScore = double.infinity;

        final origPitchDiff = calculateAbsolutePitch(origNote.string, origNote.fret) -
            calculateAbsolutePitch(prevOrigNote.string, prevOrigNote.fret);

        for (final cand in candidates) {
          double stepScore = 0.0;

          // 줄 이동 비용
          final stringDiff = (cand.string - prev.string).abs();
          stepScore += stringDiff * 3.0;

          // 프렛 이동 비용
          final fretDiff = (cand.fret - prev.fret).abs();
          stepScore += fretDiff * 1.5;

          // 중심 프렛과의 거리
          final centerDist = (cand.fret - targetCenterFret).abs();
          stepScore += centerDist * 1.0;

          // 테크닉 보존: 원곡에서 같은 줄이었던 경우 같은 줄 유지 강력 선호
          final origSameString = (origNote.string == prevOrigNote.string);
          final candSameString = (cand.string == prev.string);
          if (origSameString && !candSameString) {
            stepScore += 8.0;
          } else if (origSameString && candSameString) {
            stepScore -= 4.0;
          }

          // 피치 진행 방향 (상행/하행) 일치 여부
          final candPitchDiff = calculateAbsolutePitch(cand.string, cand.fret) -
              calculateAbsolutePitch(prev.string, prev.fret);
          if (origPitchDiff > 0 && candPitchDiff <= 0) {
            stepScore += 6.0;
          } else if (origPitchDiff < 0 && candPitchDiff >= 0) {
            stepScore += 6.0;
          } else if (origPitchDiff == 0 && candPitchDiff == 0) {
            stepScore -= 2.0;
          }

          if (stepScore < bestStepScore) {
            bestStepScore = stepScore;
            bestNext = cand;
          }
        }

        if (bestNext != null) {
          currentPath.add(bestNext);
          currentScore += bestStepScore;
        } else {
          currentPath.add(origNote);
          currentScore += 30.0;
        }
      }

      if (currentScore < bestScore) {
        bestScore = currentScore;
        bestPath = currentPath;
      }
    }

    return lick.copyWith(
      cagedForm: targetDef.cagedForm,
      pentatonicBox: targetBox,
      notes: bestPath,
    );
  }

  static List<LickNote> _findCandidatesForNote(
    LickNote note,
    int targetCenterFret,
    List<int> stringBaseSemitones,
  ) {
    final noteIdx = NoteUtils.getNoteIndex(note.noteName);
    final candidates = <LickNote>[];

    for (int string = 1; string <= 6; string++) {
      final base = stringBaseSemitones[string];
      final baseFret = (noteIdx - (base % 12) + 12) % 12;

      for (int oct = 0; oct <= 2; oct++) {
        final fret = baseFret + oct * 12;
        if (fret >= 0 && fret <= 21) {
          if ((fret - targetCenterFret).abs() <= 3) {
            candidates.add(note.copyWith(
              string: string,
              fret: fret,
            ));
          }
        }
      }
    }

    // 만약 ±3프렛 이내에 없으면 ±5프렛까지 확장
    if (candidates.isEmpty) {
      for (int string = 1; string <= 6; string++) {
        final base = stringBaseSemitones[string];
        final baseFret = (noteIdx - (base % 12) + 12) % 12;

        for (int oct = 0; oct <= 2; oct++) {
          final fret = baseFret + oct * 12;
          if (fret >= 0 && fret <= 21) {
            if ((fret - targetCenterFret).abs() <= 5) {
              candidates.add(note.copyWith(
                string: string,
                fret: fret,
              ));
            }
          }
        }
      }
    }

    return candidates;
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

  /// 특정 코드(루트 및 퀄리티)에 가장 잘 어울리는 기타 거장의 시그니처 릭을 추천합니다.
  /// 릭 풀(pool)이 비어있으면 기본 프리셋(kArtistLickPresets)에서 매칭합니다.
  /// 원곡 키가 다른 경우 대상 코드의 루트에 맞춰 자동 조옮김(Transposition)된 릭을 반환합니다.
  static List<ArtistLick> findLicksForChord({
    List<ArtistLick>? pool,
    required String chordRoot,
    required String chordQuality,
    String? keyContext,
    int limit = 5,
  }) {
    final licksPool = (pool != null && pool.isNotEmpty) ? pool : kArtistLickPresets;
    final normRoot = NoteUtils.normalizeNoteName(chordRoot);
    final isMinor = chordQuality.toLowerCase().contains('m') &&
        !chordQuality.toLowerCase().contains('maj');
    final isDom7 = chordQuality == '7' ||
        chordQuality == '9' ||
        chordQuality == '13' ||
        chordQuality.contains('7#9');
    final isMaj7 = chordQuality.toLowerCase().contains('maj');

    final scored = <({ArtistLick lick, double score})>[];

    for (final origLick in licksPool) {
      double score = 0.0;
      final targetChord = origLick.targetChord;
      final targetQuality = targetChord.replaceAll(RegExp(r'^[A-Ga-g][#b]?'), '');
      final targetIsMinor = targetQuality.toLowerCase().contains('m') &&
          !targetQuality.toLowerCase().contains('maj');
      final targetIsDom7 = (targetQuality.contains('7') &&
              !targetQuality.toLowerCase().contains('maj')) ||
          targetQuality.contains('9') ||
          targetQuality.contains('13');
      final targetIsMaj7 = targetQuality.toLowerCase().contains('maj');

      // 1. 화성학적 퀄리티 적합도 평가
      if (isDom7 && targetIsDom7) {
        score += 50.0;
      } else if (isMinor && targetIsMinor) {
        score += 50.0;
      } else if (isMaj7 && targetIsMaj7) {
        score += 50.0;
      } else if (isDom7 && origLick.genre.toLowerCase().contains('blues')) {
        score += 35.0; // 블루스 릭은 7th 도미넌트에 매우 적합
      } else if (isMinor && origLick.genre.toLowerCase().contains('blues')) {
        score += 35.0; // 마이너 블루스 릭 호환
      } else if (!isMinor && !isDom7 && !targetIsMinor) {
        score += 30.0; // 일반 메이저 계열 호환
      }

      // 2. 루트 일치 여부 평가
      final origLickRoot = NoteUtils.normalizeNoteName(
        origLick.defaultKey.split(' ')[0],
      );
      final isExactRoot = origLickRoot == normRoot;
      if (isExactRoot) {
        score += 40.0;
      }

      // 3. 디그리(Degree) 일치 여부 (KeyContext가 있는 경우)
      if (keyContext != null && keyContext.isNotEmpty) {
        final keyRoot = NoteUtils.normalizeNoteName(keyContext.split(' ')[0]);
        final semitoneDiff = (NoteUtils.getNoteIndex(normRoot) - NoteUtils.getNoteIndex(keyRoot)) % 12;
        const semitoneToDegrees = {
          0: ['I', 'i'],
          2: ['ii', 'II'],
          4: ['iii', 'III'],
          5: ['IV', 'iv'],
          7: ['V', 'v', 'V7'],
          9: ['vi', 'VI'],
          11: ['vii', 'VII'],
        };
        final currentDegrees = semitoneToDegrees[semitoneDiff] ?? [];
        for (final d in currentDegrees) {
          if (origLick.applicableDegrees.contains(d)) {
            score += 25.0;
            break;
          }
        }
      }

      // 최소 적합도 이상인 릭만 선별
      if (score >= 30.0) {
        // 루트가 다르면 대상 코드의 루트에 맞추어 자동 조옮김
        final targetKeyName = '$normRoot ${isMinor ? "Minor" : "Major"}';
        final readyLick = isExactRoot
            ? origLick
            : transposeLick(origLick, toKey: targetKeyName);

        scored.add((lick: readyLick, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    // 중복 id 방지 및 limit 적용
    final result = <ArtistLick>[];
    final seenIds = <String>{};
    for (final item in scored) {
      if (!seenIds.contains(item.lick.id)) {
        seenIds.add(item.lick.id);
        result.add(item.lick);
        if (result.length >= limit) break;
      }
    }

    return result;
  }

  /// 코드 진행(Progression) 전체 및 선택 블록에 가장 잘 어울리는 기타 거장의 시그니처 릭을 추천합니다.
  static List<ArtistLick> findLicksForProgression({
    List<ArtistLick>? pool,
    required List<String> progressionChords,
    String? selectedChord,
    String? key,
    String? genre,
    int limit = 6,
  }) {
    if (progressionChords.isEmpty && (selectedChord == null || selectedChord.isEmpty)) {
      return (pool != null && pool.isNotEmpty)
          ? pool.take(limit).toList()
          : kArtistLickPresets.take(limit).toList();
    }

    final licksPool = (pool != null && pool.isNotEmpty) ? pool : kArtistLickPresets;
    final cleanChords = progressionChords
        .where((c) => c.isNotEmpty)
        .map((c) => c.trim())
        .toList();

    // 현재 선택된 특정 코드가 있다면 우선 반영
    final focusChord = (selectedChord != null && selectedChord.isNotEmpty)
        ? selectedChord
        : (cleanChords.isNotEmpty ? cleanChords.first : 'C');

    final focusRoot = NoteUtils.normalizeNoteName(focusChord.replaceAll(RegExp(r'[^A-Ga-g#b]'), ''));
    final focusQuality = focusChord.replaceAll(RegExp(r'^[A-Ga-g][#b]?'), '');

    // 진행 내 코드들에서 릭 매칭
    final chordMatched = findLicksForChord(
      pool: licksPool,
      chordRoot: focusRoot,
      chordQuality: focusQuality,
      keyContext: key,
      limit: limit,
    );

    // 장르 일치 가산점
    if (genre != null && genre.isNotEmpty) {
      chordMatched.sort((a, b) {
        final aGenreMatch = a.genre.toLowerCase().contains(genre.toLowerCase()) ? 1 : 0;
        final bGenreMatch = b.genre.toLowerCase().contains(genre.toLowerCase()) ? 1 : 0;
        return bGenreMatch.compareTo(aGenreMatch);
      });
    }

    return chordMatched.take(limit).toList();
  }
}
