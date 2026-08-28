import '../theory/note_utils.dart';

class TuningUtils {
  static const tuningNotes = ['E', 'A', 'D', 'G', 'B', 'E'];
  // ignore: constant_identifier_names
  static const TUNING_NOTES = tuningNotes;

  static int get6thStringFret(String noteName, [List<String>? currentTuning]) {
    final openNote = currentTuning != null && currentTuning.isNotEmpty
        ? currentTuning[0]
        : 'E';
    final openVal = NoteUtils.getNoteIndex(openNote);
    final targetVal = NoteUtils.getNoteIndex(noteName);
    return (targetVal - openVal + 12) % 12;
  }

  static int get5thStringFret(String noteName, [List<String>? currentTuning]) {
    final openNote = currentTuning != null && currentTuning.length > 1
        ? currentTuning[1]
        : 'A';
    final openVal = NoteUtils.getNoteIndex(openNote);
    final targetVal = NoteUtils.getNoteIndex(noteName);
    return (targetVal - openVal + 12) % 12;
  }

  /// 특정 줄의 개방현에 맞춰 타겟 노트의 프렛 번호를 반환 (0~11)
  static int getStringFret(int stringIndex, String noteName, [List<String>? currentTuning]) {
    final tuning = currentTuning ?? TUNING_NOTES;
    if (stringIndex < 0 || stringIndex >= tuning.length) return 0;
    final openVal = NoteUtils.getNoteIndex(tuning[stringIndex]);
    final targetVal = NoteUtils.getNoteIndex(noteName);
    return (targetVal - openVal + 12) % 12;
  }
}

