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

class SongSection {
  final String id;
  final String name; // 'Intro', 'Verse', 'Chorus', 'Bridge', 'Outro'
  final List<ChordBlock> progression;
  final String? key; // 전조(Modulation) 시 섹션별 키
  final int repeatCount;

  const SongSection({
    required this.id,
    required this.name,
    this.progression = const [],
    this.key,
    this.repeatCount = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'progression': progression.map((c) => c.toJson()).toList(),
        'key': key,
        'repeatCount': repeatCount,
      };

  factory SongSection.fromJson(Map<String, dynamic> json) => SongSection(
        id: json['id'] ?? 'sec_main',
        name: json['name'] ?? 'Verse',
        progression: (json['progression'] as List? ?? [])
            .map((c) => ChordBlock.fromJson(c))
            .toList(),
        key: json['key'],
        repeatCount: json['repeatCount'] ?? 1,
      );

  SongSection copyWith({
    String? id,
    String? name,
    List<ChordBlock>? progression,
    String? key,
    int? repeatCount,
  }) {
    return SongSection(
      id: id ?? this.id,
      name: name ?? this.name,
      progression: progression ?? this.progression,
      key: key ?? this.key,
      repeatCount: repeatCount ?? this.repeatCount,
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
  final List<SongSection> sections;
  final int activeSectionIndex;

  const ProgressionSession({
    this.title = 'Untitled Progression',
    this.arrangementStyle,
    this.bpm = 120,
    required this.key,
    this.progression = const [],
    required this.rhythmPattern,
    this.sections = const [],
    this.activeSectionIndex = 0,
  });

  /// 현재 활성화된 섹션 반환 (없으면 메인 progression 기반 기본 섹션)
  SongSection get currentSection {
    if (sections.isNotEmpty && activeSectionIndex >= 0 && activeSectionIndex < sections.length) {
      return sections[activeSectionIndex];
    }
    return SongSection(id: 'main', name: 'Main', progression: progression, key: key);
  }

  Map<String, dynamic> toJson() => {
        'projectTitle': title,
        'arrangementStyle': arrangementStyle,
        'bpm': bpm,
        'key': key,
        'progression': progression.map((c) => c.toJson()).toList(),
        'rhythmPattern': rhythmPattern.toJson(),
        'sections': sections.map((s) => s.toJson()).toList(),
        'activeSectionIndex': activeSectionIndex,
      };

  factory ProgressionSession.fromJson(Map<String, dynamic> json) {
    final progList = (json['progression'] as List? ?? [])
        .map((c) => ChordBlock.fromJson(c))
        .toList();
    final rawSections = json['sections'] as List?;
    List<SongSection> parsedSections = [];
    if (rawSections != null && rawSections.isNotEmpty) {
      parsedSections =
          rawSections.map((s) => SongSection.fromJson(s)).toList();
    } else {
      parsedSections = [
        SongSection(id: 'main', name: 'Main', progression: progList)
      ];
    }

    return ProgressionSession(
      title: json['projectTitle'] ?? 'Untitled Progression',
      arrangementStyle: json['arrangementStyle'],
      bpm: json['bpm'] ?? 120,
      key: json['key'] ?? 'C Major',
      progression: progList,
      rhythmPattern: json['rhythmPattern'] != null
          ? RhythmPattern.fromJson(json['rhythmPattern'])
          : RhythmPattern.presets.first,
      sections: parsedSections,
      activeSectionIndex: json['activeSectionIndex'] ?? 0,
    );
  }

  ProgressionSession copyWith({
    String? title,
    String? arrangementStyle,
    int? bpm,
    String? key,
    List<ChordBlock>? progression,
    RhythmPattern? rhythmPattern,
    List<SongSection>? sections,
    int? activeSectionIndex,
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
      sections: sections ?? this.sections,
      activeSectionIndex: activeSectionIndex ?? this.activeSectionIndex,
    );
  }
}

