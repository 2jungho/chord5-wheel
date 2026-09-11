import '../models/chord_model.dart';
import '../models/fretboard_marker.dart';
import '../models/progression/progression_models.dart';
import 'guitar/pentatonic_box_calculator.dart';
import 'theory_utils.dart';

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
  static const tuningNotes = TuningUtils.tuningNotes;
  // ignore: constant_identifier_names
  static const TUNING_NOTES = tuningNotes;

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
    List<String>? tuning,
  }) =>
      FretboardMapper.generateFretboardMap(
        root: root,
        notes: notes,
        ghostNotes: ghostNotes,
        scaleNameForIntervals: scaleNameForIntervals,
        maxFret: maxFret,
        tuning: tuning,
      );

  static Map<int, List<FretboardMarker>> generateMapFromVoicing(
          ChordVoicing voicing, String root, [List<String>? tuning]) =>
      FretboardMapper.generateMapFromVoicing(voicing, root, tuning);

  static List<VoiceLeadingLine> calculateVoiceLeading(
    Map<int, List<FretboardMarker>> fromMap,
    Map<int, List<FretboardMarker>> toMap,
  ) =>
      VoiceLeading.calculateVoiceLeading(fromMap, toMap);

  static String getVoicingDescription(ChordVoicing voicing) =>
      FretboardMapper.getVoicingDescription(voicing);

  /// 스튜디오 타임라인의 선택된 코드 블록 및 펜타토닉/솔로 박스 설정을 기반으로 지판 하이라이트 맵을 생성합니다.
  static ({
    Map<int, List<FretboardMarker>> highlightMap,
    String? rootNote,
    bool isMinor,
  }) generateStudioFretboardMap({
    required ProgressionSession session,
    required int selectedBlockIndex,
    required bool showPentatonicOnBackground,
    required int selectedPentatonicBox,
    required List<String> tuningNotes,
  }) {
    Map<int, List<FretboardMarker>> highlightMap = {};
    String? rootNote;
    bool isMinor = false;

    if (session.progression.isEmpty) {
      return (highlightMap: highlightMap, rootNote: rootNote, isMinor: isMinor);
    }

    final safeIndex = selectedBlockIndex.clamp(0, session.progression.length - 1);
    final currentChordBlock = session.progression[safeIndex];
    final Chord chordData = TheoryUtils.analyzeChord(currentChordBlock.chordSymbol);
    rootNote = chordData.root;
    isMinor = chordData.quality.contains('m') && !chordData.quality.contains('maj');

    if (currentChordBlock.voicing != null) {
      highlightMap = generateMapFromVoicing(
        currentChordBlock.voicing!,
        rootNote,
        tuningNotes,
      );
    } else {
      highlightMap = generateFretboardMap(
        root: rootNote,
        notes: chordData.notes,
        tuning: tuningNotes,
      );
    }

    // Key Center 기반 펜타토닉 / 솔로 박스 노트 생성 및 병합
    if (showPentatonicOnBackground && session.key.isNotEmpty) {
      String keyRoot = 'C';
      bool isKeyMinor = false;
      final parts = session.key.split(' ');
      if (parts.isNotEmpty) {
        keyRoot = parts[0];
        isKeyMinor = session.key.contains('Minor');
      }

      Map<int, List<FretboardMarker>> boxMarkers;
      if (selectedPentatonicBox > 0) {
        boxMarkers = PentatonicBoxCalculator.generateBoxMarkers(
          keyRoot: keyRoot,
          isMinorKey: isKeyMinor,
          boxNumber: selectedPentatonicBox,
          currentChordRoot: rootNote,
        );
      } else {
        final scaleType = isKeyMinor ? 'Minor Pentatonic' : 'Major Pentatonic';
        final pentatonicNotes = TheoryUtils.calculateScaleNotes(keyRoot, scaleType);
        boxMarkers = generateFretboardMap(
          root: keyRoot,
          notes: [],
          ghostNotes: pentatonicNotes,
        );
      }

      // 기존 highlightMap에 병합
      for (int s = 0; s < 6; s++) {
        final ghostMarkers = boxMarkers[s] ?? [];
        if (ghostMarkers.isEmpty) continue;

        if (!highlightMap.containsKey(s)) {
          highlightMap[s] = ghostMarkers;
        } else {
          final existingFrets = highlightMap[s]!.map((m) => m.fret).toSet();
          for (var gm in ghostMarkers) {
            if (!existingFrets.contains(gm.fret)) {
              highlightMap[s]!.add(gm);
            }
          }
          highlightMap[s]!.sort((a, b) => a.fret.compareTo(b.fret));
        }
      }
    }

    return (highlightMap: highlightMap, rootNote: rootNote, isMinor: isMinor);
  }
}