import '../models/chord_model.dart';
import '../models/fretboard_marker.dart';

import 'guitar/tuning_utils.dart';
import 'guitar/voicing_generator.dart';
import 'guitar/fretboard_mapper.dart';
import 'guitar/voice_leading.dart';

export 'guitar/tuning_utils.dart';
export 'guitar/voicing_generator.dart';
export 'guitar/fretboard_mapper.dart';
export 'guitar/voice_leading.dart';

/// Legacy Facade for Guitar Utilities.
/// Refactored to delegate to specific utility classes in `lib/utils/guitar/`.
class GuitarUtils {
  static const TUNING_NOTES = TuningUtils.TUNING_NOTES;

  static int get6thStringFret(String noteName) =>
      TuningUtils.get6thStringFret(noteName);

  static int get5thStringFret(String noteName) =>
      TuningUtils.get5thStringFret(noteName);

  static ChordVoicing calculateChordShape(String root, String quality) =>
      VoicingGenerator.calculateChordShape(root, quality);

  static List<ChordVoicing> generateAllVoicings(String root, String quality) =>
      VoicingGenerator.generateAllVoicings(root, quality);

  static List<ChordVoicing> generateVoicings(String root, String quality) =>
      VoicingGenerator.generateVoicings(root, quality);

  static List<ChordVoicing> generateCAGEDVoicings(
          String root, String quality) =>
      VoicingGenerator.generateCAGEDVoicings(root, quality);

  static List<ChordVoicing> generateShellVoicings(
          String root, String quality) =>
      VoicingGenerator.generateShellVoicings(root, quality);

  static List<ChordVoicing> generateDropVoicings(String root, String quality) =>
      VoicingGenerator.generateDropVoicings(root, quality);

  static Map<int, List<FretboardMarker>> generateFretboardMap({
    required String root,
    required List<String> notes,
    List<String> ghostNotes = const [],
    String? scaleNameForIntervals,
    int maxFret = 17,
  }) =>
      FretboardMapper.generateFretboardMap(
        root: root,
        notes: notes,
        ghostNotes: ghostNotes,
        scaleNameForIntervals: scaleNameForIntervals,
        maxFret: maxFret,
      );

  static Map<int, List<FretboardMarker>> generateMapFromVoicing(
          ChordVoicing voicing, String root) =>
      FretboardMapper.generateMapFromVoicing(voicing, root);

  static List<VoiceLeadingLine> calculateVoiceLeading(
    Map<int, List<FretboardMarker>> fromMap,
    Map<int, List<FretboardMarker>> toMap,
  ) =>
      VoiceLeading.calculateVoiceLeading(fromMap, toMap);

  static String getVoicingDescription(ChordVoicing voicing) =>
      FretboardMapper.getVoicingDescription(voicing);
}