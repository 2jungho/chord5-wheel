enum InstrumentType {
  guitar,
  bass,
  piano,
  ukulele,
  custom,
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
