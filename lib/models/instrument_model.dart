enum InstrumentType {
  guitar,
  bass,
  piano,
  ukulele,
  custom,
}

/// 다양한 기타 튜닝 프리셋
enum TuningPreset {
  standard,     // E-A-D-G-B-E
  dropD,        // D-A-D-G-B-E
  halfStepDown, // Eb-Ab-Db-Gb-Bb-Eb
  dadgad,       // D-A-D-G-A-D
  openD,        // D-A-D-F#-A-D
  openG,        // D-G-D-G-B-D
  dropC,        // C-G-C-F-A-D
}

extension TuningPresetExtension on TuningPreset {
  String get label {
    switch (this) {
      case TuningPreset.standard:
        return 'Standard (E A D G B E)';
      case TuningPreset.dropD:
        return 'Drop D (D A D G B E)';
      case TuningPreset.halfStepDown:
        return 'Half-Step Down (Eb Ab Db Gb Bb Eb)';
      case TuningPreset.dadgad:
        return 'DADGAD (D A D G A D)';
      case TuningPreset.openD:
        return 'Open D (D A D F# A D)';
      case TuningPreset.openG:
        return 'Open G (D G D G B D)';
      case TuningPreset.dropC:
        return 'Drop C (C G C F A D)';
    }
  }

  String get shortName {
    switch (this) {
      case TuningPreset.standard:
        return 'Standard';
      case TuningPreset.dropD:
        return 'Drop D';
      case TuningPreset.halfStepDown:
        return 'Eb Tuning';
      case TuningPreset.dadgad:
        return 'DADGAD';
      case TuningPreset.openD:
        return 'Open D';
      case TuningPreset.openG:
        return 'Open G';
      case TuningPreset.dropC:
        return 'Drop C';
    }
  }

  /// 6번줄부터 1번줄까지의 음 이름 (Pitch notation without octave)
  List<String> get notes {
    switch (this) {
      case TuningPreset.standard:
        return ['E', 'A', 'D', 'G', 'B', 'E'];
      case TuningPreset.dropD:
        return ['D', 'A', 'D', 'G', 'B', 'E'];
      case TuningPreset.halfStepDown:
        return ['Eb', 'Ab', 'Db', 'Gb', 'Bb', 'Eb'];
      case TuningPreset.dadgad:
        return ['D', 'A', 'D', 'G', 'A', 'D'];
      case TuningPreset.openD:
        return ['D', 'A', 'D', 'F#', 'A', 'D'];
      case TuningPreset.openG:
        return ['D', 'G', 'D', 'G', 'B', 'D'];
      case TuningPreset.dropC:
        return ['C', 'G', 'C', 'F', 'A', 'D'];
    }
  }
}

class Instrument {
  final String id;
  final String name;
  final InstrumentType type;
  final int stringCount; // For string instruments
  final List<String> tuning; // Open string notes (starting from lowest string)
  final bool
      isFretted; // True for Guitar/Bass, False for Piano/Violin(technically fretless but handled differently)

  const Instrument({
    required this.id,
    required this.name,
    required this.type,
    this.stringCount = 6,
    this.tuning = const ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'], // Standard Guitar
    this.isFretted = true,
  });

  // Predefined Instruments
  static const Instrument guitarStandard = Instrument(
    id: 'guitar_std',
    name: 'Guitar (Standard)',
    type: InstrumentType.guitar,
    stringCount: 6,
    tuning: ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'],
  );

  static const Instrument bassStandard = Instrument(
    id: 'bass_std',
    name: 'Bass (4-String)',
    type: InstrumentType.bass,
    stringCount: 4,
    tuning: ['E1', 'A1', 'D2', 'G2'],
  );

  static const Instrument bass5String = Instrument(
    id: 'bass_5str',
    name: 'Bass (5-String)',
    type: InstrumentType.bass,
    stringCount: 5,
    tuning: ['B0', 'E1', 'A1', 'D2', 'G2'],
  );

  static const Instrument piano = Instrument(
    id: 'piano_88',
    name: 'Piano',
    type: InstrumentType.piano,
    stringCount: 0, // Not applicable
    tuning: [], // Not applicable
    isFretted: false,
  );

  static const Instrument ukulele = Instrument(
    id: 'ukulele_std',
    name: 'Ukulele',
    type: InstrumentType.ukulele,
    stringCount: 4,
    tuning: ['G4', 'C4', 'E4', 'A4'], // Re-entrant tuning
  );
}
