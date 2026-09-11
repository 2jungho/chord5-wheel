import 'package:flutter/material.dart';
import 'dart:math';
import '../models/progression/progression_models.dart';
import '../models/progression/progression_presets.dart';
import 'view_control_state_mixin.dart';
import '../utils/theory_utils.dart';
import '../utils/guitar_utils.dart';
import '../models/fretboard_marker.dart';
import '../models/chord_model.dart';
import '../utils/theory/voice_leading_calculator.dart';
import '../services/music_theory_service.dart';

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
        final form = NoteUtils.normalizeCagedForm(block.voicing!.name);
        if (form.isNotEmpty) {
          selectCagedForm('$form Form', force: true);
        } else {
          // 이름 매칭 실패 시 루트 스트링 기반 추론 (Fallback)
          int rStr = block.voicing!.rootString;
          for (int i = 0; i < 6; i++) {
            if (block.voicing!.frets[i] != -1) {
              rStr = 6 - i;
              break;
            }
          }

          const rootStringForms = {
            6: 'E Form',
            5: 'A Form',
            4: 'D Form',
          };
          selectCagedForm(rootStringForms[rStr], force: true);
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
      final newVoicing = MusicTheoryService.findBestVoicingForStyle(
        voicings,
        _timelineVoicingStyle,
        key: _session.key,
        previousVoicing: lastVoicing,
      );
      lastVoicing = newVoicing;
      return block.copyWith(voicing: newVoicing);
    }).toList();

    _session = _session.copyWith(progression: newProgression);
    // 현재 선택된 블록의 변경된 보이싱에 맞춰 CAGED Form 상태 갱신
    selectBlock(_selectedBlockIndex);
    notifyListeners();
  }

  void updateKey(String newKeyString) {
    if (_session.key == newKeyString) return;

    final newProgression = MusicTheoryService.remapProgression(
      progression: _session.progression,
      oldKey: _session.key,
      newKey: newKeyString,
      style: _timelineVoicingStyle,
    );

    _session = _session.copyWith(
      key: newKeyString,
      progression: newProgression,
    );
    // 키 변경에 따른 코드 및 보이싱 변화를 CAGED Form 상태에 반영
    selectBlock(_selectedBlockIndex);
    notifyListeners();
  }

  /// 코드 블록 시퀀스에 순차적 보이싱(Voice Leading)을 적용하여 일괄 빌드하는 공통 헬퍼
  List<ChordBlock> _buildProgressionBlocks(
    Iterable<ChordBlock> blocks, {
    String? key,
    String? Function(ChordBlock)? symbolTransformer,
  }) {
    ChordVoicing? lastVoicing;
    final activeKey = key ?? _session.key;
    return blocks.map((block) {
      final symbol = symbolTransformer != null
          ? (symbolTransformer(block) ?? block.chordSymbol)
          : block.chordSymbol;
      final newBlock = MusicTheoryService.buildChordBlock(
        chordSymbol: symbol,
        key: activeKey,
        style: _timelineVoicingStyle,
        previousVoicing: lastVoicing,
        functionTag: block.functionTag,
        duration: block.duration,
        existingBlock: block,
      );
      lastVoicing = newBlock.voicing;
      return newBlock;
    }).toList();
  }

  void addChord(ChordBlock chord) {
    final lastVoicing = _session.progression.isNotEmpty
        ? _session.progression.last.voicing
        : null;

    final newChord = MusicTheoryService.buildChordBlock(
      chordSymbol: chord.chordSymbol,
      key: _session.key,
      style: _timelineVoicingStyle,
      previousVoicing: lastVoicing,
      functionTag: chord.functionTag,
      duration: chord.duration,
      existingBlock: chord,
    );

    _session = _session.copyWith(
      progression: [..._session.progression, newChord],
    );
    notifyListeners();
  }

  void addProgressionFromText(String text,
      {bool replace = false, String? title}) {
    final parsedBlocks = TheoryUtils.parseProgressionText(text, _session.key);
    final newBlocks = _buildProgressionBlocks(parsedBlocks);

    if (newBlocks.isNotEmpty) {
      if (replace) {
        _session = _session.copyWith(
          progression: newBlocks,
          title: title ??
              (text.trim().isNotEmpty ? text.trim() : 'Untitled Progression'),
        );
      } else {
        final existingTitle = (_session.title.isNotEmpty &&
                _session.title != 'Untitled Progression')
            ? _session.title
            : null;
        _session = _session.copyWith(
          progression: [..._session.progression, ...newBlocks],
          title: title ??
              existingTitle ??
              [..._session.progression, ...newBlocks]
                  .map((b) => b.chordSymbol)
                  .join('-'),
        );
      }

      // 코드가 추가된 후 첫 번째 블록을 자동으로 선택하여 프렛보드에 표시
      selectBlock(0);
    }
  }

  /// 타임라인 진행의 모든 코드를 3화음(Triad) <-> 7화음(7th)으로 일괄 변환
  void convertProgressionDensity({required bool toSeventh}) {
    if (_session.progression.isEmpty) return;

    final newProgression = _buildProgressionBlocks(
      _session.progression,
      symbolTransformer: (block) => TheoryUtils.convertChordDensity(
        block.chordSymbol,
        toSeventh: toSeventh,
        functionTag: block.functionTag,
      ),
    );

    _session = _session.copyWith(progression: newProgression);
    _calculateVoiceLeading();
    notifyListeners();
  }

  /// 새로운 코드 진행으로 전체를 교체합니다. (AI 검색 등에서 사용)
  void setProgression(List<ChordBlock> blocks,
      {String? key,
      String? title,
      String? arrangementStyle,
      bool clearArrangement = false}) {
    final activeKey = (key != null && key.isNotEmpty) ? key : _session.key;
    final processedBlocks = _buildProgressionBlocks(blocks, key: activeKey);

    _session = _session.copyWith(
      key: activeKey,
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

  void insertChordAt(int index, String chordSymbol, {int duration = 4}) {
    final newBlock = MusicTheoryService.buildChordBlock(
      chordSymbol: chordSymbol,
      key: _session.key,
      style: _timelineVoicingStyle,
      duration: duration,
    );

    final newList = List<ChordBlock>.from(_session.progression);
    final safeIndex = index.clamp(0, newList.length);
    newList.insert(safeIndex, newBlock);

    _session = _session.copyWith(progression: newList);
    selectBlock(safeIndex);
    notifyListeners();
  }

  void applyTransposedChords(List<String> newChordSymbols) {
    if (newChordSymbols.isEmpty) return;
    ChordVoicing? lastVoicing;

    final newBlocks = newChordSymbols.map((symbol) {
      final newBlock = MusicTheoryService.buildChordBlock(
        chordSymbol: symbol,
        key: _session.key,
        style: _timelineVoicingStyle,
        previousVoicing: lastVoicing,
      );
      lastVoicing = newBlock.voicing;
      return newBlock;
    }).toList();

    final existingTitle = (_session.title.isNotEmpty &&
            _session.title != 'Untitled Progression')
        ? '${_session.title} (Capo)'
        : newChordSymbols.join('-');

    _session = _session.copyWith(
      progression: newBlocks,
      title: existingTitle,
    );
    selectBlock(0);
    notifyListeners();
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

  // --- Song Section Arranger ---

  /// 새 송 폼 섹션 추가 (예: Intro, Verse, Chorus, Bridge, Outro)
  void addSection(String name, {List<ChordBlock>? initialChords}) {
    final currentSections = List<SongSection>.from(_session.sections);
    if (currentSections.isEmpty) {
      currentSections.add(SongSection(
        id: 'sec_1',
        name: 'Verse',
        progression: _session.progression,
      ));
    }

    final newSection = SongSection(
      id: 'sec_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      progression: initialChords ?? [],
      key: _session.key,
    );

    currentSections.add(newSection);
    final newIndex = currentSections.length - 1;

    _session = _session.copyWith(
      sections: currentSections,
      activeSectionIndex: newIndex,
      progression: newSection.progression,
    );

    _selectedBlockIndex = 0;
    _calculateVoiceLeading();
    notifyListeners();
  }

  /// 활성 섹션 전환
  void selectSection(int index) {
    if (index >= 0 && index < _session.sections.length) {
      // 1. 현재 섹션에 현재 progression 저장
      final currentSections = List<SongSection>.from(_session.sections);
      if (_session.activeSectionIndex >= 0 &&
          _session.activeSectionIndex < currentSections.length) {
        currentSections[_session.activeSectionIndex] =
            currentSections[_session.activeSectionIndex]
                .copyWith(progression: _session.progression);
      }

      // 2. 새 섹션으로 전환
      final targetSection = currentSections[index];
      _session = _session.copyWith(
        sections: currentSections,
        activeSectionIndex: index,
        progression: targetSection.progression,
        key: targetSection.key ?? _session.key,
      );

      _selectedBlockIndex = 0;
      _calculateVoiceLeading();
      notifyListeners();
    }
  }

  /// 섹션 삭제
  void removeSection(int index) {
    if (_session.sections.length <= 1) return; // 최소 1개 유지
    final currentSections = List<SongSection>.from(_session.sections);
    if (index >= 0 && index < currentSections.length) {
      currentSections.removeAt(index);
      final newIndex = (_session.activeSectionIndex >= currentSections.length)
          ? currentSections.length - 1
          : _session.activeSectionIndex;

      _session = _session.copyWith(
        sections: currentSections,
        activeSectionIndex: newIndex,
        progression: currentSections[newIndex].progression,
      );

      _selectedBlockIndex = 0;
      _calculateVoiceLeading();
      notifyListeners();
    }
  }

  /// 섹션 이름 변경
  void renameSection(int index, String newName) {
    if (index >= 0 && index < _session.sections.length) {
      final currentSections = List<SongSection>.from(_session.sections);
      currentSections[index] = currentSections[index].copyWith(name: newName);
      _session = _session.copyWith(sections: currentSections);
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

  void _updateRhythmSteps(void Function(List<RhythmStep> steps) update) {
    final currentSteps = List<RhythmStep>.from(_session.rhythmPattern.steps);
    update(currentSteps);
    currentSteps.sort((a, b) => a.position.compareTo(b.position));
    _session = _session.copyWith(
      rhythmPattern: _session.rhythmPattern.copyWith(steps: currentSteps),
    );
    notifyListeners();
  }

  void toggleRhythmStep(int position) {
    _updateRhythmSteps((steps) {
      final index = steps.indexWhere((s) => s.position == position);

      if (index >= 0) {
        // Rotate: Down -> Up -> Mute -> Bass -> None -> Down
        final currentAction = steps[index].action;
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
          steps.removeAt(index);
        } else {
          steps[index] = steps[index].copyWith(action: nextAction);
        }
      } else {
        steps.add(RhythmStep(position: position, action: RhythmActionType.down));
      }
    });
  }

  void toggleAccent(int position) {
    _updateRhythmSteps((steps) {
      final index = steps.indexWhere((s) => s.position == position);
      if (index >= 0) {
        steps[index] =
            steps[index].copyWith(isAccent: !steps[index].isAccent);
      }
    });
  }

  void _calculateVoiceLeading() {
    _voiceLeadingLines = VoiceLeadingCalculator.calculateVoiceLeading(
      session: _session,
      selectedBlockIndex: _selectedBlockIndex,
    );
  }
}
