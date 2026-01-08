import '../models/chord_model.dart';
import '../models/progression/progression_models.dart';
import '../models/progression/progression_presets.dart';

import 'theory/note_utils.dart';
import 'theory/scale_utils.dart';
import 'theory/chord_utils.dart';
import 'theory/progression_utils.dart';

export 'theory/note_utils.dart';
export 'theory/scale_utils.dart';
export 'theory/chord_utils.dart';
export 'theory/progression_utils.dart';

/// Legacy Facade for Theory Utilities.
/// Refactored to delegate to specific utility classes in `lib/utils/theory/`.
class TheoryUtils {
  static String normalizeNoteName(String name) =>
      NoteUtils.normalizeNoteName(name);

  static int getNoteIndex(String noteName) => NoteUtils.getNoteIndex(noteName);

  static String getNoteName(int chromaticIndex, bool useSharp) =>
      NoteUtils.getNoteName(chromaticIndex, useSharp);

  static List<String> calculateScaleNotes(
          String rootNoteName, String modeName) =>
      ScaleUtils.calculateScaleNotes(rootNoteName, modeName);

  static List<String> getRelatedScales(String root, List<String> chordNotes) =>
      ScaleUtils.getRelatedScales(root, chordNotes);

  static List<String> getScaleIntervals(String modeName) =>
      ScaleUtils.getScaleIntervals(modeName);

  static String getIntervalName(int st) => NoteUtils.getIntervalName(st);

  static List<Chord> getDiatonicChords(
          List<String> scaleNotes, String modeName) =>
      ChordUtils.getDiatonicChords(scaleNotes, modeName);

  static (List<String> intervals, String displayStr, bool isMinor)
      parseChordQuality(String q) => ChordUtils.parseChordQuality(q);

  static int intervalToSemitone(String iv) => NoteUtils.intervalToSemitone(iv);

  static List<String> getGuideTones(String root, String quality) =>
      ChordUtils.getGuideTones(root, quality);

  static Map<String, String> findDiatonicKeys(String root, String quality) =>
      ChordUtils.findDiatonicKeys(root, quality);

  static String getRomanNumeral(int degree) =>
      ChordUtils.getRomanNumeral(degree);

  static String getMinorRomanNumeral(int degree) =>
      ChordUtils.getMinorRomanNumeral(degree);

  static List<Map<String, dynamic>> analyzeTensions(
          String root, String scaleName) =>
      ChordUtils.analyzeTensions(root, scaleName);

  static List<Map<String, String>> findSubstitutions(
          String root, String quality) =>
      ChordUtils.findSubstitutions(root, quality);

  static List<Map<String, dynamic>> getChordInversionsWithOctave(
          String root, String quality) =>
      ChordUtils.getChordInversionsWithOctave(root, quality);

  static Chord analyzeChord(String symbol) => ChordUtils.analyzeChord(symbol);

  static List<String> getNotesFromVoicing(
          ChordVoicing voicing, String rootNote) =>
      ChordUtils.getNotesFromVoicing(voicing, rootNote);

  static Map<String, List<String>> classifyScaleNotes(
          List<String> scaleNotes, String modeName) =>
      ScaleUtils.classifyScaleNotes(scaleNotes, modeName);

  static List<ChordBlock> parseProgressionText(String text, String key) =>
      ProgressionUtils.parseProgressionText(text, key);

  static String transposeNote(String note, int semitones) =>
      NoteUtils.transposeNote(note, semitones);

  static String transposeChord(String chordSymbol, int semitones) =>
      ChordUtils.transposeChord(chordSymbol, semitones);

  static String? getFunctionTag(String key, String chordSymbol) =>
      ProgressionUtils.getFunctionTag(key, chordSymbol);

  static ProgressionPreset? matchProgressionToPreset(
          List<ChordBlock> progression) =>
      ProgressionUtils.matchProgressionToPreset(progression);
}