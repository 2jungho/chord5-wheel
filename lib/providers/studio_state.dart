import 'package:flutter/material.dart';
import 'dart:math';
import '../models/progression/progression_models.dart';
import '../models/progression/progression_presets.dart';
import 'view_control_state_mixin.dart';
import '../utils/theory_utils.dart';
import '../utils/guitar_utils.dart';
import '../models/fretboard_marker.dart';
import '../models/chord_model.dart';

class StudioState extends ChangeNotifier with ViewControlStateMixin {
  ProgressionSession _session;

  // 선택 상태 관련
  int _selectedBlockIndex = 0;
  List<VoiceLeadingLine> _voiceLeadingLines = [];
  String _timelineVoicingStyle = 'E'; // E, A, G, C, D

  StudioState()
      : _session = const ProgressionSession(
          key: 'C Major',
          rhythmPattern: RhythmPattern(
            name: 'Default 4/4',
            steps: [
              RhythmStep(
                  position: 0, action: RhythmActionType.down, isAccent: true),
              RhythmStep(position: 4, action: RhythmActionType.down),
              RhythmStep(
                  position: 8, action: RhythmActionType.down, isAccent: true),
              RhythmStep(position: 12, action: RhythmActionType.down),
            ],
          ),
          progression: [],
        );

  ProgressionSession get session => _session;
  int get selectedBlockIndex => _selectedBlockIndex;
  String get timelineVoicingStyle => _timelineVoicingStyle;
  List<VoiceLeadingLine> get voiceLeadingLines => _voiceLeadingLines;

  void selectBlock(int index) {
    if (index >= 0 && index < _session.progression.length) {
      _selectedBlockIndex = index;
      _calculateVoiceLeading();

      // 현재 선택된 보이싱의 폼(Form)을 파악하여 ViewControl 패널 상태 동기화
      final block = _session.progression[index];
      if (block.voicing != null) {
        final name = block.voicing!.name ?? '';

        // 1. 이름 기반 매칭
        if (name.startsWith('E Form')) {
          selectCagedForm('E Form', force: true);
        } else if (name.startsWith('A Form')) {
          selectCagedForm('A Form', force: true);
        } else if (name.startsWith('D Form')) {
          selectCagedForm('D Form', force: true);
        } else if (name.startsWith('G Form')) {
          selectCagedForm('G Form', force: true);
        } else if (name.startsWith('C Form')) {
          selectCagedForm('C Form', force: true);
        }
        // 2. 이름 매칭 실패 시 루트 스트링 기반 추론 (Fallback)
        else {
          int rStr = block.voicing!.rootString;
          // 메타데이터가 부정확할 수 있으므로 실제 프렛 데이터에서 가장 낮은 줄(Bass) 감지
          for (int i = 0; i < 6; i++) {
            if (block.voicing!.frets[i] != -1) {
              // i=0(6번줄) -> 6, i=1(5번줄) -> 5 ...
              rStr = 6 - i;
              break;
            }
          }

          if (rStr == 6) {
            selectCagedForm('E Form', force: true);
          } else if (rStr == 5) {
            selectCagedForm('A Form', force: true);
          } else if (rStr == 4) {
            selectCagedForm('D Form', force: true);
          } else {
            // 그 외(3,2,1번줄 루트 등)는 일단 전체 표시
            selectCagedForm(null, force: true);
          }
        }
      } else {
        selectCagedForm(null, force: true);
      }

      notifyListeners();
    }
  }

  void setTimelineVoicingStyle(String style) {
    if (_timelineVoicingStyle == style) return;
    _timelineVoicingStyle = style;

    // 기존 블록들의 보이싱 일괄 업데이트
    ChordVoicing? lastVoicing;
    final newProgression = _session.progression.map((block) {
      if (block.chordDetail == null) return block;
      final voicings = GuitarUtils.generateAllVoicings(
          block.chordDetail!.root, block.chordDetail!.quality);
      final newVoicing = _findBestVoicingForStyle(
          voicings, _timelineVoicingStyle,
          previousVoicing: lastVoicing);
      lastVoicing = newVoicing;
      return block.copyWith(voicing: newVoicing);
    }).toList();

    _session = _session.copyWith(progression: newProgression);
    // 현재 선택된 블록의 변경된 보이싱에 맞춰 CAGED Form 상태 갱신
    selectBlock(_selectedBlockIndex);
    notifyListeners();
  }

  ChordVoicing? _findBestVoicingForStyle(
      List<ChordVoicing> voicings, String style,
      {ChordVoicing? previousVoicing}) {
    if (voicings.isEmpty) return null;

    int targetFret;

    if (style == 'Auto') {
      // Auto: 직전 코드의 위치를 따라감 (흐름 중시)
      targetFret = previousVoicing?.startFret ?? 0;
      if (previousVoicing == null) return voicings.first;
    } else {
      // CAGED Form: Key Root의 해당 폼 위치를 기준으로 고정 (포지션 중시)
      // 예: C Key, E Form -> C 코드를 E Form으로 잡는 8프렛이 기준
      targetFret = _calculateAnchorFret(style);
    }

    // Target Fret과 가장 가까운(거리 차이가 적은) 보이싱 찾기
    final sorted = List<ChordVoicing>.from(voicings);
    sorted.sort((a, b) {
      final diffA = (a.startFret - targetFret).abs();
      final diffB = (b.startFret - targetFret).abs();
      int compare = diffA.compareTo(diffB);

      // 거리가 같다면? CAGED 폼 이름이 일치하는 것 우선 (옵션)
      // 또는 프렛 번호가 낮은 것 우선
      if (compare == 0) {
        return a.startFret.compareTo(b.startFret);
      }
      return compare;
    });

    return sorted.first;
  }

  /// 현재 Key의 Root Note를 주어진 [formStyle] (예: 'E Form')으로 잡았을 때의 프렛 위치를 반환
  int _calculateAnchorFret(String formStyle) {
    if (formStyle == 'Auto') return 0;

    // Hybrid Form parsing (e.g., "C-A")
    if (formStyle.contains('-')) {
      final parts = formStyle.split('-');
      final form1 = parts[0];
      final form2 = parts[1];

      int anchor1 = _calculateAnchorFret(form1);
      int anchor2 = _calculateAnchorFret(form2);

      // Wrap-around handling (e.g., D-C where D=10, C=3? No, C should be 15)
      // Usually CAGED order is C(3) A(5) G(8) E(10) D(12) C(15)...
      // If anchor2 is significantly smaller than anchor1 (suggesting lower octave), add 12
      if (anchor2 < anchor1) {
        anchor2 += 12;
      }
      // Special case: if difference is too big (reverse wrap?), though uncommon in this ordered list
      if ((anchor2 - anchor1).abs() > 6) {
        // Try to bring them closer
        if (anchor2 > anchor1) anchor1 += 12;
      }

      return (anchor1 + anchor2) ~/ 2;
    }

    // 1. Key Root 파싱 (예: "C Major" -> "C")
    final keyParts = _session.key.split(' ');
    final rootNote = TheoryUtils.normalizeNoteName(keyParts[0]);

    // 2. 해당 Root로 Form에 해당하는 보이싱 생성
    // 퀄리티는 Major 기준으로 위치만 잡으면 됨
    final cagedVoicings = GuitarUtils.generateCAGEDVoicings(rootNote, '');

    // 3. 해당 Form과 일치하는 보이싱의 startFret 반환
    final match = cagedVoicings.firstWhere(
      (v) => v.name?.startsWith('$formStyle Form') ?? false,
      orElse: () => ChordVoicing(frets: [], startFret: 0, rootString: 6),
    );

    return match.startFret;
  }

  void updateKey(String newKeyString) {
    if (_session.key == newKeyString) return;

    final oldKeyParts = _session.key.split(' ');
    final oldRootStr = TheoryUtils.normalizeNoteName(oldKeyParts[0]);
    final oldMode = oldKeyParts.length > 1 ? oldKeyParts[1] : 'Major';

    final newKeyParts = newKeyString.split(' ');
    final newRootStr = TheoryUtils.normalizeNoteName(newKeyParts[0]);
    final newMode = newKeyParts.length > 1 ? newKeyParts[1] : 'Major';

    List<ChordBlock> newProgression = [];

    // Check if Mode Changed (Major <-> Minor)
    if (oldMode != newMode) {
      // 1. Prepare Scale Info
      final oldScaleName = oldMode == 'Minor' ? 'Aeolian' : 'Ionian';
      final newScaleName = newMode == 'Minor' ? 'Aeolian' : 'Ionian';

      final oldScaleNotes =
          TheoryUtils.calculateScaleNotes(oldRootStr, oldScaleName);

      final newDiatonics = TheoryUtils.getDiatonicChords(
          TheoryUtils.calculateScaleNotes(newRootStr, newScaleName),
          newScaleName);

      // 2. Map chords by Degree
      newProgression = _session.progression.map((block) {
        final chord = TheoryUtils.analyzeChord(block.chordSymbol);
        final chordRootIdx = TheoryUtils.getNoteIndex(chord.root);

        // Find Degree in Old Scale
        int degreeIndex = -1;
        for (int i = 0; i < oldScaleNotes.length; i++) {
          final noteIdx = TheoryUtils.getNoteIndex(oldScaleNotes[i]);
          if (noteIdx == chordRootIdx) {
            degreeIndex = i;
            break;
          }
        }

        if (degreeIndex != -1 && degreeIndex < newDiatonics.length) {
          // Found Diatonic Match -> Switch to New Diatonic Chord
          final newChordData = newDiatonics[degreeIndex];
          final newSymbol = newChordData.root + newChordData.quality;

          final isMinor = newMode == 'Minor';
          final newTag = isMinor
              ? TheoryUtils.getMinorRomanNumeral(degreeIndex + 1)
              : TheoryUtils.getRomanNumeral(degreeIndex + 1);

          final analyzed = TheoryUtils.analyzeChord(newSymbol);
          final voicings =
              GuitarUtils.generateAllVoicings(analyzed.root, analyzed.quality);
          final newVoicing =
              _findBestVoicingForStyle(voicings, _timelineVoicingStyle);

          return block.copyWith(
            chordSymbol: newSymbol,
            functionTag: newTag,
            chordDetail: analyzed,
            voicing: newVoicing,
          );
        } else {
          // Non-diatonic: Fallback to Simple Transposition (Semitone)
          final oldIdx = TheoryUtils.getNoteIndex(oldRootStr);
          final newIdx = TheoryUtils.getNoteIndex(newRootStr);
          final semitones = newIdx - oldIdx;

          final newSymbol =
              TheoryUtils.transposeChord(block.chordSymbol, semitones);
          final analyzed = TheoryUtils.analyzeChord(newSymbol);
          final voicings =
              GuitarUtils.generateAllVoicings(analyzed.root, analyzed.quality);
          final newVoicing =
              _findBestVoicingForStyle(voicings, _timelineVoicingStyle);

          return block.copyWith(
            chordSymbol: newSymbol,
            chordDetail: analyzed,
            voicing: newVoicing,
          );
        }
      }).toList();
    } else {
      // Same Mode: Simple Transposition
      final oldIdx = TheoryUtils.getNoteIndex(oldRootStr);
      final newIdx = TheoryUtils.getNoteIndex(newRootStr);
      final semitones = newIdx - oldIdx;

      newProgression = _session.progression.map((block) {
        final newSymbol =
            TheoryUtils.transposeChord(block.chordSymbol, semitones);
        final analyzed = TheoryUtils.analyzeChord(newSymbol);
        final voicings =
            GuitarUtils.generateAllVoicings(analyzed.root, analyzed.quality);
        final newVoicing =
            _findBestVoicingForStyle(voicings, _timelineVoicingStyle);

        return block.copyWith(
          chordSymbol: newSymbol,
          chordDetail: analyzed,
          voicing: newVoicing,
        );
      }).toList();
    }

    _session = _session.copyWith(
      key: newKeyString,
      progression: newProgression,
    );
    // 키 변경에 따른 코드 및 보이싱 변화를 CAGED Form 상태에 반영
    selectBlock(_selectedBlockIndex);
    notifyListeners();
  }

  void addChord(ChordBlock chord) {
    // 인터벌 태그 자동 생성
    String? tag = chord.functionTag;
    if (tag == null) {
      tag = TheoryUtils.getFunctionTag(_session.key, chord.chordSymbol);
    }

    final analyzed = TheoryUtils.analyzeChord(chord.chordSymbol);
    final voicings =
        GuitarUtils.generateAllVoicings(analyzed.root, analyzed.quality);
    final lastVoicing = _session.progression.isNotEmpty
        ? _session.progression.last.voicing
        : null;
    final defaultVoicing = _findBestVoicingForStyle(
        voicings, _timelineVoicingStyle,
        previousVoicing: lastVoicing);

    final newChord = chord.copyWith(
      chordDetail: analyzed,
      voicing: defaultVoicing,
      functionTag: tag,
    );

    _session = _session.copyWith(
      progression: [..._session.progression, newChord],
    );
    notifyListeners();
  }

  void addProgressionFromText(String text,
      {bool replace = false, String? title}) {
    final parsedBlocks = TheoryUtils.parseProgressionText(text, _session.key);
    ChordVoicing? lastVoicing = _session.progression.isNotEmpty
        ? _session.progression.last.voicing
        : null;

    final newBlocks = parsedBlocks.map((block) {
      final analyzed = TheoryUtils.analyzeChord(block.chordSymbol);
      final voicings =
          GuitarUtils.generateAllVoicings(analyzed.root, analyzed.quality);
      final defaultVoicing = _findBestVoicingForStyle(
          voicings, _timelineVoicingStyle,
          previousVoicing: lastVoicing);
      lastVoicing = defaultVoicing;

      return block.copyWith(
        chordDetail: analyzed,
        voicing: defaultVoicing,
      );
    }).toList();

    if (newBlocks.isNotEmpty) {
      if (replace) {
        _session = _session.copyWith(
          progression: newBlocks,
          // 교체(Replace) 시, 제목이 주어지면 적용하고 없으면 초기화(Untitled)
          title: title ?? 'Untitled Progression',
        );
      } else {
        _session = _session.copyWith(
          progression: [..._session.progression, ...newBlocks],
        );
      }
      // 코드가 추가된 후 첫 번째 블록을 자동으로 선택하여 프렛보드에 표시
      selectBlock(0);
    }
  }

  /// 새로운 코드 진행으로 전체를 교체합니다. (AI 검색 등에서 사용)
  void setProgression(List<ChordBlock> blocks,
      {String? key,
      String? title,
      String? arrangementStyle,
      bool clearArrangement = false}) {
    ChordVoicing? lastVoicing;

    final processedBlocks = blocks.map((block) {
      final analyzed = TheoryUtils.analyzeChord(block.chordSymbol);
      final voicings =
          GuitarUtils.generateAllVoicings(analyzed.root, analyzed.quality);
      final defaultVoicing = _findBestVoicingForStyle(
        voicings,
        _timelineVoicingStyle,
        previousVoicing: lastVoicing,
      );
      lastVoicing = defaultVoicing;

      return block.copyWith(
        chordDetail: analyzed,
        voicing: defaultVoicing,
        functionTag:
            TheoryUtils.getFunctionTag(key ?? _session.key, block.chordSymbol),
      );
    }).toList();

    _session = _session.copyWith(
      key: (key != null && key.isNotEmpty) ? key : _session.key,
      title: (title != null && title.isNotEmpty) ? title : _session.title,
      arrangementStyle: arrangementStyle,
      clearArrangement: clearArrangement,
      progression: processedBlocks,
    );

    _selectedBlockIndex = 0;
    _calculateVoiceLeading();
    notifyListeners();
  }

  /// 현재 진행과 유사한(같은 태그를 가진) 다른 프리셋으로 무작위 변경합니다.
  String? regenerateSimilarProgression() {
    // 1. 현재 진행과 매칭되는 프리셋 찾기
    final matched = TheoryUtils.matchProgressionToPreset(_session.progression);

    // 매칭된게 없으면(커스텀 진행 등), 'Basic' 태그나 전체에서 랜덤 추천
    // 혹은 아무 동작 안함. 여기서는 매칭된게 있을 때만 동작하도록 함.
    if (matched == null) return null;

    final targetTag = matched.tags.isNotEmpty ? matched.tags.first : null;

    // 2. 후보군 필터링 (같은 태그, 다른 제목)
    final candidates = kProgressionPresets.where((p) {
      if (targetTag != null && !p.tags.contains(targetTag)) return false;
      return p.title != matched.title;
    }).toList();

    if (candidates.isEmpty) return null;

    // 3. 랜덤 선택 및 적용
    final random = Random();
    final newPreset = candidates[random.nextInt(candidates.length)];

    addProgressionFromText(newPreset.progression,
        replace: true, title: newPreset.title);
    return newPreset.title;
  }

  void removeChord(int index) {
    final newList = List<ChordBlock>.from(_session.progression);
    if (index >= 0 && index < newList.length) {
      newList.removeAt(index);
      _session = _session.copyWith(progression: newList);

      // 인덱스 보정: 삭제된 위치가 현재 선택된 곳보다 앞이거나 같으면 인덱스 감소
      if (_selectedBlockIndex >= newList.length) {
        _selectedBlockIndex = newList.isEmpty ? 0 : newList.length - 1;
      }
      _calculateVoiceLeading();
      notifyListeners();
    }
  }

  void clearProgression() {
    _session = _session.copyWith(progression: []);
    _selectedBlockIndex = 0;
    _voiceLeadingLines = [];
    notifyListeners();
  }

  // --- Rhythm Editing ---
  void updateRhythmPattern(RhythmPattern pattern) {
    _session = _session.copyWith(rhythmPattern: pattern);
    notifyListeners();
  }

  void toggleRhythmStep(int position) {
    final currentSteps = List<RhythmStep>.from(_session.rhythmPattern.steps);
    final index = currentSteps.indexWhere((s) => s.position == position);

    if (index >= 0) {
      // Rotate: Down -> Up -> Mute -> None
      // Rotate: Down -> Up -> Mute -> Bass -> None -> Down
      final currentAction = currentSteps[index].action;
      RhythmActionType nextAction;
      switch (currentAction) {
        case RhythmActionType.down:
          nextAction = RhythmActionType.up;
          break;
        case RhythmActionType.up:
          nextAction = RhythmActionType.mute;
          break;
        case RhythmActionType.mute:
          nextAction = RhythmActionType.bass;
          break;
        case RhythmActionType.bass:
          nextAction = RhythmActionType.none;
          break;
        case RhythmActionType.none:
          nextAction = RhythmActionType.down;
          break;
      }

      if (nextAction == RhythmActionType.none) {
        currentSteps.removeAt(index);
      } else {
        currentSteps[index] = currentSteps[index].copyWith(action: nextAction);
      }
    } else {
      currentSteps
          .add(RhythmStep(position: position, action: RhythmActionType.down));
    }

    currentSteps.sort((a, b) => a.position.compareTo(b.position));
    _session = _session.copyWith(
      rhythmPattern: _session.rhythmPattern.copyWith(steps: currentSteps),
    );

    notifyListeners();
  }

  void toggleAccent(int position) {
    final currentSteps = List<RhythmStep>.from(_session.rhythmPattern.steps);
    final index = currentSteps.indexWhere((s) => s.position == position);

    if (index >= 0) {
      currentSteps[index] =
          currentSteps[index].copyWith(isAccent: !currentSteps[index].isAccent);
      _session = _session.copyWith(
        rhythmPattern: _session.rhythmPattern.copyWith(steps: currentSteps),
      );

      notifyListeners();
    }
  }

  void _calculateVoiceLeading() {
    // 1. 유효성 검사: 코드 진행이 최소 2개 이상이어야 함
    if (_session.progression.length < 2 ||
        _selectedBlockIndex < 0 ||
        _selectedBlockIndex >= _session.progression.length) {
      _voiceLeadingLines = [];
      return;
    }

    final currentBlock = _session.progression[_selectedBlockIndex];
    // 마지막 블록인 경우 첫 번째 블록으로 루프 연결
    final nextIndex = (_selectedBlockIndex < _session.progression.length - 1)
        ? _selectedBlockIndex + 1
        : 0;
    final nextBlock = _session.progression[nextIndex];

    if (currentBlock.voicing == null || nextBlock.voicing == null) {
      _voiceLeadingLines = [];
      return;
    }

    // 2. Fretboard Map 생성 (현재 코드, 다음 코드)
    final root1 = currentBlock.chordDetail?.root ??
        TheoryUtils.analyzeChord(currentBlock.chordSymbol).root;
    final root2 = nextBlock.chordDetail?.root ??
        TheoryUtils.analyzeChord(nextBlock.chordSymbol).root;

    final map1 =
        GuitarUtils.generateMapFromVoicing(currentBlock.voicing!, root1);
    final map2 = GuitarUtils.generateMapFromVoicing(nextBlock.voicing!, root2);

    // 3. 라인 계산
    _voiceLeadingLines = GuitarUtils.calculateVoiceLeading(map1, map2);
  }
}
