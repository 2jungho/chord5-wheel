import '../chord_model.dart';

enum RhythmActionType {
  down, // Downstroke
  up, // Upstroke
  mute, // Muted stroke (X)
  bass, // Bass string only (Root)
  none, // Empty step
}

class RhythmStep {
  final int position; // 0-15 (for 16th notes)
  final RhythmActionType action;
  final bool isAccent;

  const RhythmStep({
    required this.position,
    required this.action,
    this.isAccent = false,
  });

  Map<String, dynamic> toJson() => {
        'pos': position,
        'type': action.name,
        'accent': isAccent,
      };

  factory RhythmStep.fromJson(Map<String, dynamic> json) => RhythmStep(
        position: json['pos'],
        action: RhythmActionType.values.byName(json['type']),
        isAccent: json['accent'] ?? false,
      );

  RhythmStep copyWith({
    int? position,
    RhythmActionType? action,
    bool? isAccent,
  }) {
    return RhythmStep(
      position: position ?? this.position,
      action: action ?? this.action,
      isAccent: isAccent ?? this.isAccent,
    );
  }
}

class RhythmPattern {
  final String name;
  final List<RhythmStep> steps;

  const RhythmPattern({
    required this.name,
    this.steps = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  factory RhythmPattern.fromJson(Map<String, dynamic> json) => RhythmPattern(
        name: json['name'],
        steps:
            (json['steps'] as List).map((s) => RhythmStep.fromJson(s)).toList(),
      );

  RhythmPattern copyWith({
    String? name,
    List<RhythmStep>? steps,
  }) {
    return RhythmPattern(
      name: name ?? this.name,
      steps: steps ?? this.steps,
    );
  }

  // --- Presets ---
  static List<RhythmPattern> get presets => [
        const RhythmPattern(name: '4-Beat Basic', steps: [
          RhythmStep(
              position: 0, action: RhythmActionType.down, isAccent: true),
          RhythmStep(position: 4, action: RhythmActionType.down),
          RhythmStep(
              position: 8, action: RhythmActionType.down, isAccent: true),
          RhythmStep(position: 12, action: RhythmActionType.down),
        ]),
        const RhythmPattern(name: '8-Beat Pop', steps: [
          RhythmStep(
              position: 0, action: RhythmActionType.down, isAccent: true),
          RhythmStep(position: 4, action: RhythmActionType.down),
          RhythmStep(position: 6, action: RhythmActionType.up),
          RhythmStep(
              position: 8, action: RhythmActionType.down, isAccent: true),
          RhythmStep(position: 12, action: RhythmActionType.down),
          RhythmStep(position: 14, action: RhythmActionType.up),
        ]),
        const RhythmPattern(name: 'Calypso', steps: [
          RhythmStep(
              position: 0, action: RhythmActionType.down, isAccent: true),
          RhythmStep(position: 4, action: RhythmActionType.down),
          RhythmStep(position: 6, action: RhythmActionType.up),
          RhythmStep(position: 10, action: RhythmActionType.up),
          RhythmStep(position: 12, action: RhythmActionType.down),
          RhythmStep(position: 14, action: RhythmActionType.up),
        ]),
        const RhythmPattern(name: 'Slow Rock', steps: [
          RhythmStep(
              position: 0, action: RhythmActionType.down, isAccent: true),
          RhythmStep(position: 4, action: RhythmActionType.down),
          RhythmStep(
              position: 8, action: RhythmActionType.down, isAccent: true),
          RhythmStep(position: 10, action: RhythmActionType.down),
          RhythmStep(position: 12, action: RhythmActionType.down),
          RhythmStep(position: 14, action: RhythmActionType.up),
        ]),
        const RhythmPattern(name: 'Shuffle', steps: [
          RhythmStep(
              position: 0, action: RhythmActionType.down, isAccent: true),
          RhythmStep(position: 2, action: RhythmActionType.up),
          RhythmStep(position: 4, action: RhythmActionType.down),
          RhythmStep(position: 6, action: RhythmActionType.up),
          RhythmStep(
              position: 8, action: RhythmActionType.down, isAccent: true),
          RhythmStep(position: 10, action: RhythmActionType.up),
          RhythmStep(position: 12, action: RhythmActionType.down),
          RhythmStep(position: 14, action: RhythmActionType.up),
        ]),
        const RhythmPattern(name: '16-Beat Funky', steps: [
          RhythmStep(
              position: 0, action: RhythmActionType.down, isAccent: true),
          RhythmStep(position: 2, action: RhythmActionType.mute),
          RhythmStep(position: 4, action: RhythmActionType.down),
          RhythmStep(position: 6, action: RhythmActionType.mute),
          RhythmStep(
              position: 8, action: RhythmActionType.down, isAccent: true),
          RhythmStep(position: 10, action: RhythmActionType.up),
          RhythmStep(position: 12, action: RhythmActionType.down),
          RhythmStep(position: 14, action: RhythmActionType.mute),
        ]),
      ];
}

class ChordBlock {
  final String chordSymbol;
  final int duration; // In beats (e.g., 4 = 1 bar in 4/4)
  final String? functionTag; // Roman numerals (e.g., "ii", "V7", "I")
  final String? scale; // Recommended scale (e.g., "D Dorian")
  final Chord? chordDetail; // Analyzed chord data
  final ChordVoicing? voicing; // Specific guitar voicing for this block

  const ChordBlock({
    required this.chordSymbol,
    this.duration = 4,
    this.functionTag,
    this.scale,
    this.chordDetail,
    this.voicing,
  });

  Map<String, dynamic> toJson() => {
        'chordSymbol': chordSymbol,
        'duration': duration,
        'functionTag': functionTag,
        'scale': scale,
      };

  factory ChordBlock.fromJson(Map<String, dynamic> json) => ChordBlock(
        chordSymbol: json['chordSymbol'],
        duration: json['duration'],
        functionTag: json['functionTag'],
        scale: json['scale'],
      );

  ChordBlock copyWith({
    String? chordSymbol,
    int? duration,
    String? functionTag,
    String? scale,
    Chord? chordDetail,
    ChordVoicing? voicing,
  }) {
    return ChordBlock(
      chordSymbol: chordSymbol ?? this.chordSymbol,
      duration: duration ?? this.duration,
      functionTag: functionTag ?? this.functionTag,
      scale: scale ?? this.scale,
      chordDetail: chordDetail ?? this.chordDetail,
      voicing: voicing ?? this.voicing,
    );
  }
}

class ProgressionSession {
  final String title;
  final String? arrangementStyle;
  final int bpm;
  final String key;
  final List<ChordBlock> progression;
  final RhythmPattern rhythmPattern;

  const ProgressionSession({
    this.title = 'Untitled Progression',
    this.arrangementStyle,
    this.bpm = 120,
    required this.key,
    this.progression = const [],
    required this.rhythmPattern,
  });

  Map<String, dynamic> toJson() => {
        'projectTitle': title,
        'arrangementStyle': arrangementStyle,
        'bpm': bpm,
        'key': key,
        'progression': progression.map((c) => c.toJson()).toList(),
        'rhythmPattern': rhythmPattern.toJson(),
      };

  factory ProgressionSession.fromJson(Map<String, dynamic> json) =>
      ProgressionSession(
        title: json['projectTitle'],
        arrangementStyle: json['arrangementStyle'],
        bpm: json['bpm'],
        key: json['key'],
        progression: (json['progression'] as List)
            .map((c) => ChordBlock.fromJson(c))
            .toList(),
        rhythmPattern: RhythmPattern.fromJson(json['rhythmPattern']),
      );

  ProgressionSession copyWith({
    String? title,
    String? arrangementStyle,
    int? bpm,
    String? key,
    List<ChordBlock>? progression,
    RhythmPattern? rhythmPattern,
    bool clearArrangement = false,
  }) {
    return ProgressionSession(
      title: title ?? this.title,
      arrangementStyle:
          clearArrangement ? null : (arrangementStyle ?? this.arrangementStyle),
      bpm: bpm ?? this.bpm,
      key: key ?? this.key,
      progression: progression ?? this.progression,
      rhythmPattern: rhythmPattern ?? this.rhythmPattern,
    );
  }
}
