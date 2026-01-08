import 'package:flutter/material.dart';

import '../models/chord_model.dart';
import '../utils/theory_utils.dart';
import '../audio/audio_manager.dart';
import '../models/fretboard_marker.dart';
import '../utils/guitar_utils.dart';

import 'view_control_state_mixin.dart';

/// GeneratorView의 상태를 관리하는 Provider입니다.
/// 코드 분석, 스케일 추천, 보이싱 생성 등의 로직을 담당합니다.
/// 리팩토링: 비즈니스 로직은 TheoryUtils 및 GuitarUtils로 이관됨.
class GeneratorState extends ChangeNotifier with ViewControlStateMixin {
  final AudioManager _audioManager = AudioManager();

  // --- 상태 변수 ---
  String _analyzedRoot = '';
  String _analyzedQuality = '';
  List<String> _chordNotes = [];
  String _analyzedIntervals = '';
  List<String> _chordIntervalList = [];
  List<ChordVoicing> _allGeneratedVoicings = [];

  // 초기 검색 상태 (Reset 기능용)
  String? _initialRoot;
  String? _initialQuality;

  List<String> _relatedScales = [];
  String? _selectedScaleName;
  bool _isMinor = false;

  String _selectedVoicingStyle = 'CAGED';

  // 프렛보드 마커 (0=LowE ... 5=HighE)
  Map<int, List<FretboardMarker>> _fretboardHighlights = {};
  String? _basePentatonicName;
  int? _selectedVoicingIndex;

  // --- Getters ---
  String get analyzedRoot => _analyzedRoot;
  String get analyzedQuality => _analyzedQuality;
  List<String> get chordNotes => _chordNotes;
  String get analyzedIntervals => _analyzedIntervals;
  List<String> get chordIntervalList => _chordIntervalList;

  // 복귀 가능 여부: 현재 코드가 초기 검색 코드와 다르면 true
  bool get canRestore {
    if (_initialRoot == null || _initialRoot!.isEmpty) return false;
    return _analyzedRoot != _initialRoot || _analyzedQuality != _initialQuality;
  }

  // Filtered Voicings
  List<ChordVoicing> get generatedVoicings {
    if (_selectedVoicingStyle == 'All') return _allGeneratedVoicings;
    return _allGeneratedVoicings.where((v) {
      return v.tags.contains(_selectedVoicingStyle);
    }).toList();
  }

  String get selectedVoicingStyle => _selectedVoicingStyle;

  bool get isMinor => _isMinor;

  int? get selectedVoicingIndex => _selectedVoicingIndex;

  List<String> get relatedScales => _relatedScales;
  String? get selectedScaleName => _selectedScaleName;
  String? get basePentatonicName => _basePentatonicName;
  Map<int, List<FretboardMarker>> get fretboardHighlights =>
      _fretboardHighlights;

  Set<String> get availableIntervals {
    return _fretboardHighlights.values
        .expand((markers) => markers)
        .map((m) => m.interval)
        .toSet();
  }

  bool get hasAnalysisResult => _analyzedRoot.isNotEmpty;

  /// 코드 분석 메인 로직
  /// [isNavigation]이 true이면(대체 코드 이동 등), 초기 검색 상태를 덮어쓰지 않고 현재 상태만 변경합니다.
  Future<void> analyzeChord(String input, {bool isNavigation = false}) async {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) return;

    // 정규식: 루트와 퀄리티 분리 (예: Cmaj7 -> C, maj7)
    final rootRegex = RegExp(r'^([A-G][#b]?)(.*)$');
    final match = rootRegex.firstMatch(cleanInput);

    if (match != null) {
      final r = match.group(1) ?? 'C';
      final q = match.group(2) ?? '';

      // 1. 인터벌 및 퀄리티 추론 (TheoryUtils 사용)
      final (intervals, intervalStr, isMinor) =
          TheoryUtils.parseChordQuality(q);

      // 2. 실제 노트 계산 (TheoryUtils 사용)
      final rootIdx = TheoryUtils.getNoteIndex(r);
      final calcNotes = intervals.map((iv) {
        final semi = TheoryUtils.intervalToSemitone(iv);
        return TheoryUtils.getNoteName(rootIdx + semi, true);
      }).toList();

      // 3. 관련 스케일 검색
      final scales = TheoryUtils.getRelatedScales(r, calcNotes);

      // 4. 보이싱 생성 (All styles)
      final voicings = GuitarUtils.generateAllVoicings(r, q);

      // 상태 업데이트
      _analyzedRoot = r;
      _analyzedQuality = q;
      _analyzedIntervals = intervalStr;
      _chordIntervalList = intervalStr.split(' ');
      _chordNotes = calcNotes;
      _relatedScales = scales;
      _allGeneratedVoicings = voicings;
      _isMinor = isMinor;

      // 초기 상태 저장 (검색창 등 명시적 입력인 경우에만)
      if (!isNavigation) {
        _initialRoot = r;
        _initialQuality = q;
      } else if (_initialRoot == null) {
        // 내비게이션 중인데 초기값이 없다면 현재 값을 초기값으로 설정 (방어 코드)
        _initialRoot = r;
        _initialQuality = q;
      }

      // 초기 상태 로직: 'Chord Tones'를 기본으로 표시 (selectedScaleName = null)
      _selectedScaleName = null;
      _updateFretboardMap(); // 기본: 코드 톤 표시

      _selectedVoicingIndex = null;
      _selectedVoicingStyle = 'CAGED'; // Reset filter
      resetViewFilters(); // Reset filters for new analysis

      // Auto-select the first generated voicing if available (UX improvement)
      // This ensures the first CAGED form is highlighted on initial load
      if (generatedVoicings.isNotEmpty) {
        selectVoicing(0);
      }

      notifyListeners();
    }
  }

  /// 초기 검색 코드로 복귀
  void restoreInitialChord() {
    if (canRestore) {
      analyzeChord('$_initialRoot$_initialQuality', isNavigation: true);
      // isNavigation: true is technically weird here, but effectively restores state.
      // Actually, if we restore, do we want to reset initial?
      // No, initial is initial.
      // If we treat Restore as "Going back", keeping Initial as is is correct.
      // Wait, if I restore, I am AT the initial chord. So canRestore becomes false.
      // Correct.
    }
  }

  void setVoicingStyle(String style) {
    if (_selectedVoicingStyle != style) {
      _selectedVoicingStyle = style;
      _selectedVoicingIndex = null; // 필터 변경 시 선택 초기화
      notifyListeners();
    }
  }

  /// 보이싱 선택 (하이라이트 + 재생 + 프렛보드 연동)
  void selectVoicing(int index) {
    final voicings = generatedVoicings;
    if (index < 0 || index >= voicings.length) return;

    if (_selectedVoicingIndex == index) {
      _selectedVoicingIndex = null;
      selectCagedForm(null); // 하이라이트 해제 시 프렛보드 포커스도 해제
    } else {
      _selectedVoicingIndex = index;
      final selectedV = voicings[index];

      // 1. 보이싱 재생
      playVoicing(selectedV);

      // 2. CAGED 폼인 경우 프렛보드 포커스 연동
      if (selectedV.name != null && selectedV.name!.contains('Form')) {
        String form = selectedV.name!.split(' ')[0]; // "E", "Em", etc.
        if (form.endsWith('m')) {
          form = form.substring(0, form.length - 1);
        }
        selectCagedForm(form, force: true);
      } else {
        selectCagedForm(null); // CAGED가 아닌 경우 포커스 해제
      }
    }
    notifyListeners();
  }

  // _parseQuality, _intervalToSemitone, _generateVoicingsLocal, _addVoicing 삭제됨

  /// 스케일 선택
  void selectScale(String scaleName) {
    if (_selectedScaleName == scaleName) return;
    _selectedScaleName = scaleName;
    final scaleNotes =
        TheoryUtils.calculateScaleNotes(_analyzedRoot, scaleName);
    _updateFretboardMap(scaleNotes);
    notifyListeners();
  }

  /// 코드 톤 보기
  void selectChordTones() {
    _selectedScaleName = null;
    _updateFretboardMap(null);
    notifyListeners();
  }

  /// 스케일 재생
  Future<void> playSelectedScale() async {
    if (_selectedScaleName == null || _analyzedRoot.isEmpty) return;
    final notes =
        TheoryUtils.calculateScaleNotes(_analyzedRoot, _selectedScaleName!);
    if (notes.isEmpty) return;
    int octave = 3;
    int lastIdx = TheoryUtils.getNoteIndex(notes[0]);
    for (String note in notes) {
      int idx = TheoryUtils.getNoteIndex(note);
      if (idx < lastIdx) octave++;
      lastIdx = idx;
      _audioManager.playNote(note, octave);
      await Future.delayed(const Duration(milliseconds: 250));
    }
    _audioManager.playNote(notes[0], octave);
  }

  /// 코드 스트러밍 재생 (Generic)
  void playChordStrum() {
    _audioManager.playStrum(_chordNotes);
  }

  /// 특정 보이싱 재생 (Real Voicing)
  Future<void> playVoicing(ChordVoicing voicing) async {
    // Standard Guitar Tuning Absolute Pitches (assuming C0 = 0)
    // E2=28, A2=33, D3=38, G3=43, B3=47, E4=52
    const openStringPitches = [28, 33, 38, 43, 47, 52];

    for (int i = 0; i < 6; i++) {
      final fret = voicing.frets[i];
      if (fret != -1) {
        final absPitch = openStringPitches[i] + fret;
        final octave = absPitch ~/ 12; // integer division
        final noteIndex = absPitch % 12;
        final noteName = TheoryUtils.getNoteName(
            noteIndex, !_analyzedRoot.contains('b')); // simple sharp/flat logic

        _audioManager.playNote(noteName, octave);
        await Future.delayed(
            const Duration(milliseconds: 35)); // Fast arpeggio effect
      }
    }
  }

  /// 프렛보드 맵 업데이트
  void _updateFretboardMap([List<String>? specificNotes]) {
    String root = _analyzedRoot;
    if (root.isEmpty) root = 'C';

    List<String> notes = [];
    List<String> ghostNotes = [];

    _basePentatonicName = null;

    if (specificNotes != null) {
      // 1. 특정 스케일 선택 시
      notes = List.from(specificNotes);

      // 펜타토닉 노트 식별 (Ghost Note)
      if (specificNotes.length >= 3) {
        final rIdx = TheoryUtils.getNoteIndex(root);
        final thirdIdx = TheoryUtils.getNoteIndex(specificNotes[2]);
        final semitones = (thirdIdx - rIdx + 12) % 12;

        String pentaName = '';
        if (semitones == 3) {
          pentaName = '$root Minor Pentatonic';
        } else if (semitones == 4) {
          pentaName = '$root Major Pentatonic';
        }

        if (pentaName.isNotEmpty) {
          _basePentatonicName = pentaName;
          final standardName =
              (semitones == 3) ? 'Minor Pentatonic' : 'Major Pentatonic';
          final pNotes = TheoryUtils.calculateScaleNotes(root, standardName);
          ghostNotes.addAll(pNotes);
        }
      }
    } else {
      // 2. 기본 모드: 코드 톤
      if (_analyzedRoot.isNotEmpty) {
        notes = List.from(_chordNotes);

        final standardPentaName =
            _isMinor ? 'Minor Pentatonic' : 'Major Pentatonic';
        _basePentatonicName = '$_analyzedRoot $standardPentaName';

        final pentaNotes =
            TheoryUtils.calculateScaleNotes(_analyzedRoot, standardPentaName);
        ghostNotes.addAll(pentaNotes);
      }
    }

    _fretboardHighlights = GuitarUtils.generateFretboardMap(
        root: root,
        notes: notes,
        ghostNotes: ghostNotes,
        scaleNameForIntervals: _selectedScaleName);
  }
}
