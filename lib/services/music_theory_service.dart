import '../models/music_constants.dart';
import '../models/scale_model.dart';
import '../models/chord_model.dart';
import '../models/caged_model.dart';
import '../models/progression/progression_models.dart';

import '../utils/theory/note_utils.dart';
import '../utils/theory/scale_utils.dart';
import '../utils/theory/chord_utils.dart';
import '../utils/theory/progression_utils.dart';
import '../utils/theory/voice_leading_calculator.dart';
import '../utils/guitar/voicing_generator.dart';

class MusicTheoryService {
  /// Calculates scale and diatonic chords based on key and mode indices.
  static (Scale, List<Chord>) calculateKeyContext(
      int keyIndex, int modeIndex, bool isInnerRing) {
    
    final keyData = MusicConstants.KEYS[keyIndex];
    String rootNoteName = isInnerRing 
        ? keyData.minor.replaceAll('m', '') 
        : keyData.name;
    
    final modeData = MusicConstants.MODES[modeIndex];
    
    // 1. Root & Mode
    final root = NoteUtils.normalizeNoteName(rootNoteName);
    
    // 2. Scale Notes
    final scaleNotes = ScaleUtils.calculateScaleNotes(root, modeData.name);
    
    final scale = Scale(
      root: root,
      mode: modeData,
      notes: scaleNotes,
      intervals: modeData.formula.split(' '),
    );
    
    // 3. Diatonic Chords
    final diatonicChords = ChordUtils.getDiatonicChords(scaleNotes, modeData.name);
    
    return (scale, diatonicChords);
  }

  /// Calculates the default voicing for a given chord.
  static ChordVoicing calculateMainVoicing(Chord chord) {
    return VoicingGenerator.calculateChordShape(chord.root, chord.quality);
  }

  /// Finds the best CAGED pattern (lowest position) for a given chord.
  static (String patternName, ChordVoicing voicing)? findBestCagedPattern(
      Chord chord) {
    
    final isMinor = chord.quality.contains('m') && !chord.quality.contains('Maj');
    final rootIdx = NoteUtils.getNoteIndex(chord.root);

    // E string Reference Fret (0-11)
    int rootFretOnE = (rootIdx - 4 + 12) % 12;

    final patterns = isMinor ? minorCagedPatterns : majorCagedPatterns;

    CagedPattern? bestPattern;
    int bestStartFret = 999;

    for (var pattern in patterns) {
      int startFret = rootFretOnE + pattern.baseOffset;
      while (startFret >= 12) {
        startFret -= 12;
      }
      // Prefer lowest positive fret
      if (startFret < bestStartFret) {
        bestStartFret = startFret;
        bestPattern = pattern;
      }
    }

    if (bestPattern != null) {
      // Calculate voicing manually as in original MusicState logic
      // Or use VoicingGenerator if it supports specific pattern generation?
      // VoicingGenerator has _addVoicingToResult but it's private and tied to "Generate All".
      // We should replicate the logic or make VoicingGenerator expose specific form generation.
      // For now, I'll replicate the simple logic from MusicState to keep it consistent.
      
      List<int> frets = [-1, -1, -1, -1, -1, -1];
      for (var dot in bestPattern.dots) {
        int strIdx = 6 - dot.s;
        int realFret = bestStartFret + dot.o;
        if (frets[strIdx] == -1) {
          frets[strIdx] = realFret;
        }
      }

      int minFret = 999;
      for (int f in frets) {
        if (f != -1 && f < minFret) minFret = f;
      }
      int displayStartFret = minFret != 999 ? minFret : (bestStartFret > 0 ? bestStartFret : 1);
      if (minFret == 0) displayStartFret = 1;

      final voicing = ChordVoicing(
        frets: frets,
        startFret: displayStartFret,
        rootString: bestPattern.rootString,
        name: bestPattern.cagedName,
      );
      
      return (bestPattern.name, voicing);
    }
    return null;
  }

  /// 주어진 보이싱 목록 중 스타일(CAGED 폼 또는 'Auto')과 키에 가장 적합한 보이싱을 선택합니다.
  static ChordVoicing? findBestVoicingForStyle(
    List<ChordVoicing> voicings,
    String style, {
    required String key,
    ChordVoicing? previousVoicing,
  }) {
    if (voicings.isEmpty) return null;

    int targetFret;

    if (style == 'Auto') {
      // Auto: 직전 코드의 위치를 따라감 (흐름 중시)
      targetFret = previousVoicing?.startFret ?? 0;
      if (previousVoicing == null) return voicings.first;
    } else {
      // CAGED Form: Key Root의 해당 폼 위치를 기준으로 고정 (포지션 중시)
      targetFret = VoiceLeadingCalculator.calculateAnchorFret(
        key: key,
        formStyle: style,
      );
    }

    // Target Fret과 가장 가까운(거리 차이가 적은) 보이싱 찾기
    final sorted = List<ChordVoicing>.from(voicings);
    sorted.sort((a, b) {
      final diffA = (a.startFret - targetFret).abs();
      final diffB = (b.startFret - targetFret).abs();
      int compare = diffA.compareTo(diffB);

      // 거리가 같다면 프렛 번호가 낮은 것 우선
      if (compare == 0) {
        return a.startFret.compareTo(b.startFret);
      }
      return compare;
    });

    return sorted.first;
  }

  /// 코드 심볼로부터 ChordBlock의 화성 분석 및 최적 보이싱을 계산하여 반환합니다.
  static ChordBlock buildChordBlock({
    required String chordSymbol,
    required String key,
    String style = 'Auto',
    ChordVoicing? previousVoicing,
    String? functionTag,
    int duration = 4,
    ChordBlock? existingBlock,
  }) {
    final analyzed = ChordUtils.analyzeChord(chordSymbol);
    final voicings =
        VoicingGenerator.generateAllVoicings(analyzed.root, analyzed.quality);
    final bestVoicing = findBestVoicingForStyle(
      voicings,
      style,
      key: key,
      previousVoicing: previousVoicing,
    );

    final tag =
        functionTag ?? ProgressionUtils.getFunctionTag(key, chordSymbol);

    if (existingBlock != null) {
      return existingBlock.copyWith(
        chordSymbol: chordSymbol,
        functionTag: tag,
        chordDetail: analyzed,
        voicing: bestVoicing,
        duration: duration,
      );
    }

    return ChordBlock(
      chordSymbol: chordSymbol,
      duration: duration,
      chordDetail: analyzed,
      voicing: bestVoicing,
      functionTag: tag,
    );
  }

  /// 키 또는 모드가 변경되었을 때 코드 진행을 재매핑하고 새로운 보이싱을 적용한 진행 목록을 반환합니다.
  static List<ChordBlock> remapProgression({
    required List<ChordBlock> progression,
    required String oldKey,
    required String newKey,
    String style = 'Auto',
  }) {
    final remappedData = ProgressionUtils.calculateRemappedChords(
      progression: progression,
      oldKey: oldKey,
      newKey: newKey,
    );

    ChordVoicing? lastVoicing;
    return remappedData.map((data) {
      final block = buildChordBlock(
        chordSymbol: data.symbol,
        key: newKey,
        style: style,
        previousVoicing: lastVoicing,
        functionTag: data.tag,
        duration: data.originalBlock.duration,
        existingBlock: data.originalBlock,
      );
      lastVoicing = block.voicing;
      return block;
    }).toList();
  }
}
