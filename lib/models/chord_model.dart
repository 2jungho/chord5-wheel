class Chord {
  final String root;
  final String quality;
  final String displayQuality;
  final String degree; // e.g. I, ii, V7
  final List<String> notes;
  final List<String> intervals;

  const Chord({
    required this.root,
    required this.quality,
    this.displayQuality = '',
    this.degree = '',
    this.notes = const [],
    this.intervals = const [],
  });

  // Calculate full name e.g. C + Maj7 = CMaj7
  String get name => '$root$quality';
  String get displayName =>
      '$root${displayQuality.isEmpty ? quality : displayQuality}';

  @override
  String toString() => 'Chord($name, $degree)';
}

class ChordVoicing {
  final List<int> frets; // 6 strings, -1 for mute, 0 for open
  final int startFret;
  final int
      rootString; // 6 = Low E, 5 = A string... (1-6 based logic in UI, but model can store index)
  final String? name;
  final List<String> tags;

  const ChordVoicing({
    required this.frets,
    required this.startFret,
    required this.rootString,
    this.name,
    this.tags = const [],
  });
}
