import '../../models/fretboard_marker.dart';

class VoiceLeading {
  static List<VoiceLeadingLine> calculateVoiceLeading(
    Map<int, List<FretboardMarker>> fromMap,
    Map<int, List<FretboardMarker>> toMap,
  ) {
    List<VoiceLeadingLine> lines = [];

    for (int s = 0; s < 6; s++) {
      final fromMarkers = fromMap[s] ?? [];
      for (var fMarker in fromMarkers) {
        if (fMarker.interval.contains('7')) {
          VoiceLeadingLine? res = _findNearestInterval(
              s, fMarker, toMap, '3', VoiceLeadingType.resolution);
          if (res != null) lines.add(res);
        }
      }
    }

    for (int s = 0; s < 6; s++) {
      final fromMarkers = fromMap[s] ?? [];
      for (var fMarker in fromMarkers) {
        if (lines.any((l) => l.fromStr == s && l.fromFret == fMarker.fret)) {
          continue;
        }

        VoiceLeadingLine? eco =
            _findNearestMarker(s, fMarker, toMap, VoiceLeadingType.economical);
        if (eco != null) lines.add(eco);
      }
    }

    return lines;
  }

  static VoiceLeadingLine? _findNearestInterval(
      int fromStr,
      FretboardMarker fromMarker,
      Map<int, List<FretboardMarker>> toMap,
      String targetIntervalPart,
      VoiceLeadingType type) {
    VoiceLeadingLine? best;
    double minDistance = 100.0;

    for (int s = (fromStr - 1).clamp(0, 5);
        s <= (fromStr + 1).clamp(0, 5);
        s++) {
      final toMarkers = toMap[s] ?? [];
      for (var tMarker in toMarkers) {
        if (tMarker.interval.contains(targetIntervalPart)) {
          double dist = (fromMarker.fret - tMarker.fret).abs().toDouble() +
              (fromStr - s).abs().toDouble() * 2.0;

          if (dist < minDistance && dist < 6.0) {
            minDistance = dist;
            best = VoiceLeadingLine(
              fromStr: fromStr,
              fromFret: fromMarker.fret,
              toStr: s,
              toFret: tMarker.fret,
              interval: tMarker.interval,
              type: type,
            );
          }
        }
      }
    }
    return best;
  }

  static VoiceLeadingLine? _findNearestMarker(
      int fromStr,
      FretboardMarker fromMarker,
      Map<int, List<FretboardMarker>> toMap,
      VoiceLeadingType type) {
    VoiceLeadingLine? best;
    double minDistance = 100.0;

    for (int s = (fromStr - 1).clamp(0, 5);
        s <= (fromStr + 1).clamp(0, 5);
        s++) {
      final toMarkers = toMap[s] ?? [];
      for (var tMarker in toMarkers) {
        double dist = (fromMarker.fret - tMarker.fret).abs().toDouble() +
            (fromStr - s).abs().toDouble() * 2.0;

        if (dist < minDistance && dist < 5.0) {
          minDistance = dist;
          best = VoiceLeadingLine(
            fromStr: fromStr,
            fromFret: fromMarker.fret,
            toStr: s,
            toFret: tMarker.fret,
            interval: tMarker.interval,
            type: type,
          );
        }
      }
    }
    return best;
  }
}
