import 'package:flutter/material.dart';
import '../models/music_constants.dart';
import '../models/chord_model.dart';
import '../models/scale_model.dart';
import '../utils/theory_utils.dart';
import '../utils/guitar_utils.dart';
import '../models/caged_model.dart';
import 'view_control_state_mixin.dart';

/// 앱 전역에서 음악 이론 상태를 관리하는 Provider입니다.
/// Circle of Fifths의 선택 상태(Key, Mode), 다이아토닉 코드, 현재 스케일 등을 계산하고 관리합니다.
class MusicState extends ChangeNotifier with ViewControlStateMixin {
  // --- 상태 변수 (State Variables) ---

  // 현재 선택된 Key의 인덱스 (Circle of Fifths 순서 기준)
  int _currentKeyIndex = 0;

  // 현재 선택된 Mode의 인덱스 (Ionian, Dorian 등)
  int _currentModeIndex = 1; // 기본값: Ionian (Major)

  // 휠의 내부 링(Inner Ring - Minor) 선택 여부
  // False: Major(Outer Ring), True: Minor(Inner Ring)
  bool _isInnerRingSelected = false;

  // 현재 선택된 다이아토닉 코드의 인덱스 (상세 정보를 보기 위함)
  int _selectedDiatonicIndex = 0;

  // 현재 선택된 CAGED 패턴 이름 (UI 강조용)
  String? _selectedCagedPatternName;

  // --- 파생 데이터 (Derived Data / Cache) ---
  // 상태가 변할 때마다 _calculateState() 메서드를 통해 재계산됩니다.

  late Scale _currentScale; // 현재 스케일 정보
  late List<Chord> _diatonicChords; // 현재 Key/Mode의 다이아토닉 코드 목록
  late ChordVoicing _mainChordVoicing; // 선택된 코드의 기타 보이싱 정보

  // --- Getters (외부에서 상태 접근용) ---
  int get currentKeyIndex => _currentKeyIndex;
  int get currentModeIndex => _currentModeIndex;
  bool get isInnerRingSelected => _isInnerRingSelected;
  int get selectedDiatonicIndex => _selectedDiatonicIndex;
  String? get selectedCagedPatternName => _selectedCagedPatternName;

  Scale get currentScale => _currentScale;
  List<Chord> get diatonicChords => _diatonicChords;
  ChordVoicing get mainChordVoicing => _mainChordVoicing;

  /// 현재 루트 노트 이름 (예: "C", "Am"에서 "A")
  /// Inner Ring(Minor)이 선택된 경우 Minor Key 이름을 반환하지만, 'm' 접미사는 제거합니다.
  String get rootNote {
    final keyData = MusicConstants.KEYS[_currentKeyIndex];
    return _isInnerRingSelected
        ? keyData.minor.replaceAll('m', '')
        : keyData.name;
  }

  ModeData get currentMode => MusicConstants.MODES[_currentModeIndex];

  /// 현재 선택된 코드 객체 반환
  Chord get selectedChord => _diatonicChords.isNotEmpty
      ? _diatonicChords[_selectedDiatonicIndex % _diatonicChords.length]
      : const Chord(root: 'C', quality: 'Maj7'); // 폴백(Fallback)

  // 생성자: 초기 상태 계산
  MusicState() {
    _calculateState();
  }

  // --- 액션 (Actions) / 상태 변경 메서드 ---

  /// Key 변경 (인덱스 기반)
  void changeKey(int index) {
    if (index < 0 || index >= MusicConstants.KEYS.length) return;
    _currentKeyIndex = index;
    // resetViewFilters(); // View Filters Reset -> Removed to keep selection consistent? No, filters should reset on key change.
    // However, we want to auto-select the first CAGED form.
    _selectedCagedPatternName = null; // Reset explicitly
    selectCagedForm(null); // Clear focus

    _calculateState();
    notifyListeners();
  }

  /// 휠의 특정 슬라이스(Key) 선택 시 호출
  /// [index]: Key 인덱스
  /// [isInner]: Inner Ring(Minor) 선택 여부
  void selectKeySlice(int index, bool isInner) {
    _currentKeyIndex = index;
    _isInnerRingSelected = isInner;

    // JS 원본 로직 반영:
    // Inner Ring 선택 시 Aeolian(Natural Minor) 모드로 자동 전환
    // Outer Ring 선택 시 Ionian(Major) 모드로 자동 전환
    if (isInner) {
      _currentModeIndex = 4; // Aeolian (Natural Minor)
    } else {
      _currentModeIndex = 1; // Ionian (Major)
    }

    _selectedDiatonicIndex = 0; // 코드 선택 초기화
    _selectedCagedPatternName = null; // CAGED 선택 초기화
    selectCagedForm(null); // Clear Focus

    _calculateState();
    notifyListeners();
  }

  /// 모드 변경 (Ionian, Dorian, Phrygian 등)
  void changeMode(int modeIndex) {
    if (modeIndex < 0 || modeIndex >= MusicConstants.MODES.length) return;
    _currentModeIndex = modeIndex;
    _selectedDiatonicIndex = 0;
    _selectedCagedPatternName = null;
    selectCagedForm(null); // Clear Focus

    _calculateState();
    notifyListeners();
  }

  /// 다이아토닉 코드 목록 중 하나를 선택
  void selectDiatonicChord(int index) {
    _selectedDiatonicIndex = index;
    _selectedCagedPatternName = null; // 코드가 바뀌면 CAGED 선택도 초기화

    // 코드가 바뀌었으므로, 해당 코드의 첫 번째 CAGED 폼을 자동 선택
    _setDefaultCagedSelection();

    _calculateMainChordVoicing(); // 보이싱만 다시 계산하면 됨
    notifyListeners();
  }

  /// CAGED 패턴 선택
  void selectCagedPattern(String patternName, String? form) {
    if (_selectedCagedPatternName == patternName) {
      _selectedCagedPatternName = null;
      selectCagedForm(null);
    } else {
      _selectedCagedPatternName = patternName;
      if (form != null) {
        // "E Form" -> "E", "Em Form" -> "E"
        String normalizedForm = form.split(' ')[0];
        if (normalizedForm.endsWith('m')) {
          normalizedForm =
              normalizedForm.substring(0, normalizedForm.length - 1);
        }
        selectCagedForm(normalizedForm, force: true);
      } else {
        selectCagedForm(null);
      }
    }
    notifyListeners();
  }

  /// 사용자가 수동으로 보이싱(CAGED 폼 등)을 선택했을 때 호출됨
  void setCustomVoicing(ChordVoicing voicing) {
    _mainChordVoicing = voicing;
    notifyListeners();
  }

  // --- 계산 로직 (Calculation Logic) ---

  /// 현재 설정(Key, Mode, Ring)에 따라 모든 파생 데이터를 다시 계산합니다.
  void _calculateState() {
    // 1. 루트 노트와 모드 결정
    final root = TheoryUtils.normalizeNoteName(rootNote);
    final mode = currentMode;

    // 2. 스케일 구성음 계산 (TheoryUtils 활용)
    final scaleNotes = TheoryUtils.calculateScaleNotes(root, mode.name);

    _currentScale = Scale(
      root: root,
      mode: mode,
      notes: scaleNotes,
      intervals: mode.formula.split(' '),
    );

    // 3. 다이아토닉 코드 목록 생성
    _diatonicChords = TheoryUtils.getDiatonicChords(scaleNotes, mode.name);

    // 4. 기본 보이싱 계산 (Generic) - 먼저 초기화
    _calculateMainChordVoicing();

    // 5. CAGED 기본 선택 및 덮어쓰기 (First Form)
    _setDefaultCagedSelection();
  }

  /// 현재 선택된 코드(_selectedChord)에 대한 기타 보이싱을 계산합니다.
  void _calculateMainChordVoicing() {
    if (_diatonicChords.isEmpty) return;
    final target = selectedChord;
    // GuitarUtils를 통해 알고리즘적으로 프렛 위치를 계산
    _mainChordVoicing = GuitarUtils.calculateChordShape(
      target.root,
      target.quality,
    );
  }

  /// 현재 코드에 맞는 첫 번째(가장 낮은 프렛의) CAGED 폼을 찾아 선택 상태로 설정합니다.
  void _setDefaultCagedSelection() {
    if (_diatonicChords.isEmpty) return;

    final chord = selectedChord;
    final isMinor =
        chord.quality.contains('m') && !chord.quality.contains('Maj');
    final rootIdx = TheoryUtils.getNoteIndex(chord.root);

    // E string Reference Fret (0-11)
    int rootFretOnE = (rootIdx - 4 + 12) % 12;

    final patterns = isMinor ? minorCagedPatterns : majorCagedPatterns;

    // Find the one with lowest start fret
    CagedPattern? bestPattern;
    int bestStartFret = 999;

    for (var pattern in patterns) {
      int startFret = rootFretOnE + pattern.baseOffset;
      while (startFret > 12) {
        startFret -= 12;
      }

      // Simple calculation of minFret to ensure sorting matches CagedList
      // (Real calculation needs dot logic but baseOffset + root is close enough for determining order usually)
      // Let's use the same logic as CagedList roughly
      // Or just prefer the one with smallest positive startFret

      if (startFret < bestStartFret) {
        bestStartFret = startFret;
        bestPattern = pattern;
      }
    }

    if (bestPattern != null) {
      _selectedCagedPatternName = bestPattern.name;

      // Update Fretboard Highlight (selectCagedForm)
      String form = bestPattern.cagedName;
      String normalizedForm = form.split(' ')[0];
      if (normalizedForm.endsWith('m')) {
        normalizedForm = normalizedForm.substring(0, normalizedForm.length - 1);
      }
      selectCagedForm(normalizedForm,
          force:
              true); // Do not notifyListeners inside helper called by calculateState?
      // Actually selectCagedForm does NOT notifyListeners if mixed in?
      // ViewControlStateMixin uses mutable state but usually expects consumer to pull.
      // But _calculateState is called before notifyListeners in actions. So it's fine.

      // Update Main Chord Voicing to match this pattern
      // ONLY if safe (m7b5, dim, aug etc are not supported by simple CAGED dots logic)
      bool isSafe = !chord.quality.contains('b5') &&
          !chord.quality.contains('dim') &&
          !chord.quality.contains('aug') &&
          !chord.quality.contains('+');

      if (isSafe) {
        _calculateVoicingForPattern(bestPattern, bestStartFret, isMinor);
      }
    }
  }

  void _calculateVoicingForPattern(
      CagedPattern pattern, int startFret, bool isMinor) {
    List<int> frets = [-1, -1, -1, -1, -1, -1];

    for (var dot in pattern.dots) {
      int strIdx = 6 - dot.s;
      int realFret = startFret + dot.o;
      if (frets[strIdx] == -1) {
        frets[strIdx] = realFret;
      }
    }

    // Calculate final start fret for display logic (similar to CagedList)
    int minFret = 999;
    for (int f in frets) if (f != -1 && f < minFret) minFret = f;

    int displayStartFret =
        minFret != 999 ? minFret : (startFret > 0 ? startFret : 1);
    if (minFret == 0) displayStartFret = 1;

    _mainChordVoicing = ChordVoicing(
      frets: frets,
      startFret: displayStartFret,
      rootString: pattern.rootString,
      name: pattern.cagedName,
    );
  }
}
