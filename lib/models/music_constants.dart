class MusicConstants {
  static const List<String> NOTE_NAMES = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];
  static const List<String> CHROMATIC_SCALE = [
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'Gb',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];
  static const List<String> CHROMATIC_SHARP = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  // Circle of Fifths order
  // Key Definition: name, minor, accidentals, index
  static const List<KeyData> KEYS = [
    KeyData(name: 'C', minor: 'Am', accidentals: 0, index: 0),
    KeyData(name: 'G', minor: 'Em', accidentals: 1, index: 1),
    KeyData(name: 'D', minor: 'Bm', accidentals: 2, index: 2),
    KeyData(name: 'A', minor: 'F#m', accidentals: 3, index: 3),
    KeyData(name: 'E', minor: 'C#m', accidentals: 4, index: 4),
    KeyData(name: 'B', minor: 'G#m', accidentals: 5, index: 5),
    KeyData(name: 'Gb', minor: 'Ebm', accidentals: 6, index: 6),
    KeyData(name: 'Db', minor: 'Bbm', accidentals: -5, index: 7),
    KeyData(name: 'Ab', minor: 'Fm', accidentals: -4, index: 8),
    KeyData(name: 'Eb', minor: 'Cm', accidentals: -3, index: 9),
    KeyData(name: 'Bb', minor: 'Gm', accidentals: -2, index: 10),
    KeyData(name: 'F', minor: 'Dm', accidentals: -1, index: 11),
  ];

  static const List<ModeData> MODES = [
    ModeData(
      name: 'Lydian',
      offset: 1,
      interval: '#4',
      formula: '1 2 3 #4 5 6 7',
      chordType: 'Maj7(#11)',
      isMinor: false,
      description: '4도음(#4)이 특징인 몽환적 모드',
    ),
    ModeData(
      name: 'Ionian',
      offset: 0,
      interval: '3',
      formula: '1 2 3 4 5 6 7',
      chordType: 'Maj7',
      isMinor: false,
      description: '3도(M3)가 특징인 메이저 스케일',
    ),
    ModeData(
      name: 'Mixolydian',
      offset: -1,
      interval: 'b7',
      formula: '1 2 3 4 5 6 b7',
      chordType: '7',
      isMinor: false,
      description: '7도음(b7)이 특징인 블루지한 모드',
    ),
    ModeData(
      name: 'Dorian',
      offset: -2,
      interval: 'M6',
      formula: '1 2 b3 4 5 6 b7',
      chordType: 'm7(13)',
      isMinor: true,
      description: '6도(M6)가 특징인 세련된 마이너',
    ),
    ModeData(
      name: 'Aeolian',
      offset: -3,
      interval: 'b6',
      formula: '1 2 b3 4 5 b6 b7',
      chordType: 'm7(b13)',
      isMinor: true,
      description: '기본 내추럴 마이너 스케일',
    ),
    ModeData(
      name: 'Phrygian',
      offset: -4,
      interval: 'b2',
      formula: '1 b2 b3 4 5 b6 b7',
      chordType: 'm7',
      isMinor: true,
      description: '2도(b2)가 특징인 스페니쉬 마이너',
    ),
    ModeData(
      name: 'Locrian',
      offset: -5,
      interval: 'b5',
      formula: '1 b2 b3 4 b5 b6 b7',
      chordType: 'm7b5',
      isMinor: true,
      description: '5도(b5)가 특징인 불안정한 모드',
    ),
  ];
}

class KeyData {
  final String name;
  final String minor;
  final int accidentals;
  final int index;

  const KeyData({
    required this.name,
    required this.minor,
    required this.accidentals,
    required this.index,
  });
}

class ModeData {
  final String name;
  final int offset;
  final String interval;
  final String formula;
  final String chordType;
  final bool isMinor;
  final String description;

  const ModeData({
    required this.name,
    required this.offset,
    required this.interval,
    required this.formula,
    required this.chordType,
    required this.isMinor,
    required this.description,
  });
}
