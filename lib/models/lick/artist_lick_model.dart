/// 연주 테크닉 정의
enum NoteTechnique {
  none(symbol: '', label: 'Normal', bendSemitones: 0),
  bendHalf(symbol: '½', label: 'Half Bend', bendSemitones: 1),
  bendFull(symbol: 'Full', label: 'Full Bend', bendSemitones: 2),
  bend1Half(symbol: '1½', label: '1.5 Bend', bendSemitones: 3),
  slide(symbol: '/', label: 'Slide', bendSemitones: 0),
  hammer(symbol: 'h', label: 'Hammer-on', bendSemitones: 0),
  pull(symbol: 'p', label: 'Pull-off', bendSemitones: 0),
  vibrato(symbol: '~', label: 'Vibrato', bendSemitones: 0),
  rake(symbol: 'x', label: 'Rake', bendSemitones: 0),
  tap(symbol: 'T', label: 'Right-hand Tap', bendSemitones: 0),
  harmonic(symbol: 'NH', label: 'Natural Harmonic', bendSemitones: 0);

  final String symbol;
  final String label;
  final int bendSemitones;

  const NoteTechnique({
    required this.symbol,
    required this.label,
    required this.bendSemitones,
  });

  static NoteTechnique fromString(String? name) {
    if (name == null) return NoteTechnique.none;
    return NoteTechnique.values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => NoteTechnique.none,
    );
  }
}

/// 릭을 구성하는 단일 노트 모델
class LickNote {
  final int string; // 1 (고음 E) ~ 6 (저음 E)
  final int fret; // 0 ~ 24
  final double duration; // 박자 (0.125: 32분/셋잇단, 0.25: 16분음표, 0.5: 8분음표, 1.0: 4분음표)
  final String interval; // 'R', 'b3', '3', '4', 'b5', '5', '6', 'b7', '7', '9' 등
  final String noteName; // 'C', 'E', 'G' 등
  final NoteTechnique technique;
  final bool isTargetNote; // 주요 화성학적 해결음/코드톤 여부

  const LickNote({
    required this.string,
    required this.fret,
    this.duration = 0.5,
    required this.interval,
    required this.noteName,
    this.technique = NoteTechnique.none,
    this.isTargetNote = false,
  });

  factory LickNote.fromJson(Map<String, dynamic> json) {
    return LickNote(
      string: (json['string'] as num).toInt(),
      fret: (json['fret'] as num).toInt(),
      duration: (json['duration'] as num?)?.toDouble() ?? 0.5,
      interval: json['interval'] as String? ?? 'R',
      noteName: json['noteName'] as String? ?? 'C',
      technique: NoteTechnique.fromString(json['technique'] as String?),
      isTargetNote: json['isTargetNote'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'string': string,
      'fret': fret,
      'duration': duration,
      'interval': interval,
      'noteName': noteName,
      'technique': technique.name,
      'isTargetNote': isTargetNote,
    };
  }

  LickNote copyWith({
    int? string,
    int? fret,
    double? duration,
    String? interval,
    String? noteName,
    NoteTechnique? technique,
    bool? isTargetNote,
  }) {
    return LickNote(
      string: string ?? this.string,
      fret: fret ?? this.fret,
      duration: duration ?? this.duration,
      interval: interval ?? this.interval,
      noteName: noteName ?? this.noteName,
      technique: technique ?? this.technique,
      isTargetNote: isTargetNote ?? this.isTargetNote,
    );
  }
}

/// 아티스트 시그니처 릭 모델
class ArtistLick {
  final String id;
  final String artistId; // 외래키 (예: 'hendrix', 'clapton', 'gilmour')
  final String artist; // UI 표시용 이름 (예: 'Jimi Hendrix')
  final String genre; // 'Blues', 'Classic & Hard Rock', etc.
  final String title; // 예: 'Little Wing Chord-Melody Fill'
  final String difficulty; // 'Beginner', 'Intermediate', 'Advanced'
  final String defaultKey; // 예: 'G Major', 'E Minor'
  final String targetChord; // 예: 'G', 'Em7', 'E7'
  final List<String> applicableDegrees; // ['I', 'IV', 'V'], ['i', 'iv'] 등
  final String scaleUsed; // 예: 'Major Pentatonic + 6th', 'Blues Scale'
  final String cagedForm; // 예: 'E Form', 'A Form'
  final int pentatonicBox; // 1 ~ 5
  final String description; // 릭 해설 및 곡/스타일 배경
  final String theoryTips; // 화성학적 타겟팅 및 연주 팁
  final List<String> tags; // ['Double Stop', 'Blue Note', 'Ballad', 'Texas Shuffle']
  final List<LickNote> notes;

  const ArtistLick({
    required this.id,
    this.artistId = '',
    required this.artist,
    this.genre = 'Blues',
    required this.title,
    this.difficulty = 'Intermediate',
    required this.defaultKey,
    required this.targetChord,
    required this.applicableDegrees,
    required this.scaleUsed,
    required this.cagedForm,
    required this.pentatonicBox,
    required this.description,
    required this.theoryTips,
    required this.tags,
    required this.notes,
  });

  factory ArtistLick.fromJson(Map<String, dynamic> json) {
    return ArtistLick(
      id: json['id'] as String,
      artistId: json['artistId'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      genre: json['genre'] as String? ?? 'Blues',
      title: json['title'] as String,
      difficulty: json['difficulty'] as String? ?? 'Intermediate',
      defaultKey: json['defaultKey'] as String,
      targetChord: json['targetChord'] as String,
      applicableDegrees: (json['applicableDegrees'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      scaleUsed: json['scaleUsed'] as String? ?? '',
      cagedForm: json['cagedForm'] as String? ?? '',
      pentatonicBox: (json['pentatonicBox'] as num?)?.toInt() ?? 1,
      description: json['description'] as String? ?? '',
      theoryTips: json['theoryTips'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      notes: (json['notes'] as List<dynamic>?)
              ?.map((e) => LickNote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'artistId': artistId,
      'artist': artist,
      'genre': genre,
      'title': title,
      'difficulty': difficulty,
      'defaultKey': defaultKey,
      'targetChord': targetChord,
      'applicableDegrees': applicableDegrees,
      'scaleUsed': scaleUsed,
      'cagedForm': cagedForm,
      'pentatonicBox': pentatonicBox,
      'description': description,
      'theoryTips': theoryTips,
      'tags': tags,
      'notes': notes.map((n) => n.toJson()).toList(),
    };
  }

  ArtistLick copyWith({
    String? id,
    String? artistId,
    String? artist,
    String? genre,
    String? title,
    String? difficulty,
    String? defaultKey,
    String? targetChord,
    List<String>? applicableDegrees,
    String? scaleUsed,
    String? cagedForm,
    int? pentatonicBox,
    String? description,
    String? theoryTips,
    List<String>? tags,
    List<LickNote>? notes,
  }) {
    return ArtistLick(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      artist: artist ?? this.artist,
      genre: genre ?? this.genre,
      title: title ?? this.title,
      difficulty: difficulty ?? this.difficulty,
      defaultKey: defaultKey ?? this.defaultKey,
      targetChord: targetChord ?? this.targetChord,
      applicableDegrees: applicableDegrees ?? this.applicableDegrees,
      scaleUsed: scaleUsed ?? this.scaleUsed,
      cagedForm: cagedForm ?? this.cagedForm,
      pentatonicBox: pentatonicBox ?? this.pentatonicBox,
      description: description ?? this.description,
      theoryTips: theoryTips ?? this.theoryTips,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
    );
  }
}
