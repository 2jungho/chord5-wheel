import 'package:flutter/foundation.dart';
import '../utils/theory_utils.dart';

mixin ViewControlStateMixin on ChangeNotifier {
  // 기본 표시 인터벌 세트 (표준 정규화 키 및 연관 동의어 일괄 포함)
  static final Set<String> _defaultIntervals = {
    '1P', '1',
    'm2', 'b2',
    'M2', '2',
    'm3', 'b3',
    'M3', '3',
    'P4', '4',
    '#4', 'b5', 'd5', 'A4',
    'P5', '5',
    'm6', 'b6', '#5', 'A5',
    'M6', '6', 'bb7',
    'm7', 'b7',
    'M7', '7', '7M'
  };

  Set<String> _visibleIntervals = Set.from(_defaultIntervals);
  String? _selectedCagedForm;
  bool? _showPentatonicOnBackground;
  int _selectedPentatonicBox = 0; // 0: All, 1~5: Box 1~5

  Set<String> get visibleIntervals => _visibleIntervals;
  String? get selectedCagedForm => _selectedCagedForm;
  bool get showPentatonicOnBackground => _showPentatonicOnBackground ?? true;
  int get selectedPentatonicBox => _selectedPentatonicBox;

  void toggleInterval(String interval) {
    final newSet = Set<String>.from(_visibleIntervals);
    final synonyms = NoteUtils.getIntervalSynonyms(interval);

    final isVisible = synonyms.any((s) => newSet.contains(s));
    if (isVisible) {
      newSet.removeAll(synonyms);
    } else {
      newSet.addAll(synonyms);
    }
    _visibleIntervals = newSet;
    notifyListeners();
  }

  void togglePentatonicBackground() {
    _showPentatonicOnBackground = !showPentatonicOnBackground;
    notifyListeners();
  }

  void selectPentatonicBox(int boxNumber) {
    if (_selectedPentatonicBox == boxNumber) {
      _selectedPentatonicBox = 0; // Toggle off to All
    } else {
      _selectedPentatonicBox = boxNumber;
    }
    notifyListeners();
  }

  void selectCagedForm(String? form, {bool force = false}) {
    if (!force && _selectedCagedForm == form) {
      _selectedCagedForm = null;
    } else {
      _selectedCagedForm = form;
    }
    notifyListeners();
  }

  void resetViewFilters() {
    _visibleIntervals = Set.from(_defaultIntervals);
    _selectedCagedForm = null;
    _showPentatonicOnBackground = true;
    _selectedPentatonicBox = 0;
    notifyListeners();
  }

}
