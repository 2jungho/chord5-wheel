import 'package:flutter/foundation.dart';

mixin ViewControlStateMixin on ChangeNotifier {
  // 기본 표시 인터벌 세트
  static const Set<String> _defaultIntervals = {
    '1P',
    'm2',
    'M2',
    'm3',
    'M3',
    'P4',
    '#4',
    'b5',
    'd5',
    'P5',
    'm6',
    'M6',
    'b7',
    'm7',
    '7M',
    'M7'
  };

  Set<String> _visibleIntervals = Set.from(_defaultIntervals);
  String? _selectedCagedForm;
  bool? _showPentatonicOnBackground;

  Set<String> get visibleIntervals => _visibleIntervals;
  String? get selectedCagedForm => _selectedCagedForm;
  bool get showPentatonicOnBackground => _showPentatonicOnBackground ?? true;

  void toggleInterval(String interval) {
    final newSet = Set<String>.from(_visibleIntervals);
    if (newSet.contains(interval)) {
      newSet.remove(interval);
    } else {
      newSet.add(interval);
    }
    _visibleIntervals = newSet;
    notifyListeners();
  }

  void togglePentatonicBackground() {
    _showPentatonicOnBackground = !showPentatonicOnBackground;
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
    notifyListeners();
  }
}
