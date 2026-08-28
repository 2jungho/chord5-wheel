import 'package:flutter/material.dart';

enum BandInstrumentCategory {
  drums,
  bass,
  keys,
  guitar,
}

extension BandInstrumentCategoryExtension on BandInstrumentCategory {
  String get displayName {
    switch (this) {
      case BandInstrumentCategory.drums:
        return '드럼';
      case BandInstrumentCategory.bass:
        return '베이스';
      case BandInstrumentCategory.keys:
        return '건반';
      case BandInstrumentCategory.guitar:
        return '기타';
    }
  }

  IconData get icon {
    switch (this) {
      case BandInstrumentCategory.drums:
        return Icons.album_rounded;
      case BandInstrumentCategory.bass:
        return Icons.speaker_group_rounded;
      case BandInstrumentCategory.keys:
        return Icons.piano_rounded;
      case BandInstrumentCategory.guitar:
        return Icons.music_note_rounded;
    }
  }
}

class SoundProfile {
  final String id;
  final BandInstrumentCategory category;
  final String name;
  final String shortName;
  final String description;
  final String genreTag;
  final IconData icon;

  const SoundProfile({
    required this.id,
    required this.category,
    required this.name,
    required this.shortName,
    required this.description,
    required this.genreTag,
    required this.icon,
  });
}

class BandSoundProfiles {
  // --- DRUMS PROFILES ---
  static const drumsAcoustic = SoundProfile(
    id: 'drums_acoustic',
    category: BandInstrumentCategory.drums,
    name: '스튜디오 어쿠스틱 (Studio Kit)',
    shortName: '어쿠스틱',
    description: '선명한 비터 펀치와 우드 스네어가 살아있는 스튜디오 드럼',
    genreTag: 'Rock / Pop / Ballad',
    icon: Icons.album_rounded,
  );

  static const drumsLofi = SoundProfile(
    id: 'drums_lofi',
    category: BandInstrumentCategory.drums,
    name: '빈티지 로파이 (Vintage Lo-Fi)',
    shortName: '로파이',
    description: '따뜻한 로우패스 톤과 묵직한 붐뱁 킥 & 우드 쉘',
    genreTag: 'Lofi Chill / R&B',
    icon: Icons.radio_rounded,
  );

  static const drumsBrush = SoundProfile(
    id: 'drums_brush',
    category: BandInstrumentCategory.drums,
    name: '재즈 림샷 (Jazz Rimshot)',
    shortName: '재즈/림',
    description: '섬세하고 감성적인 크로스스틱 림샷 & 소프트 심벌',
    genreTag: 'Jazz / Neo-Soul / Ballad',
    icon: Icons.nightlife_rounded,
  );

  static const drumsElectronic = SoundProfile(
    id: 'drums_electronic',
    category: BandInstrumentCategory.drums,
    name: '80s 디스코/일렉트로 (80s Electronic)',
    shortName: '일렉트로',
    description: '808/909 펀치 킥과 찰랑이는 디스코 오픈 하이햇',
    genreTag: 'City Pop / Dance / Funk',
    icon: Icons.graphic_eq_rounded,
  );

  // --- BASS PROFILES ---
  static const bassJazz = SoundProfile(
    id: 'bass_jazz',
    category: BandInstrumentCategory.bass,
    name: '펜더 재즈 베이스 (Fender Jazz)',
    shortName: '재즈 핑거',
    description: '따뜻한 핑거링 터치와 풍성한 아날로그 앰프 웜 톤',
    genreTag: 'Neo-Soul / Pop / R&B',
    icon: Icons.speaker_group_rounded,
  );

  static const bassSlap = SoundProfile(
    id: 'bass_slap',
    category: BandInstrumentCategory.bass,
    name: '프레시전 슬랩 (Precision Slap)',
    shortName: '펑키 슬랩',
    description: '어택이 쫀득하고 날렵한 옥타브 슬랩 & 팝 사운드',
    genreTag: 'Funk / City Pop / Rock',
    icon: Icons.bolt_rounded,
  );

  static const bassUpright = SoundProfile(
    id: 'bass_upright',
    category: BandInstrumentCategory.bass,
    name: '어쿠스틱 우드 콘트라베이스 (Upright Bass)',
    shortName: '우드 베이스',
    description: '깊고 둥글게 울려 퍼지는 정통 어쿠스틱 콘트라베이스 저음',
    genreTag: 'Jazz / Acoustic / Ballad',
    icon: Icons.nature_rounded,
  );

  static const bassSynth = SoundProfile(
    id: 'bass_synth',
    category: BandInstrumentCategory.bass,
    name: '80s 아날로그 신스 베이스 (Analog Moog)',
    shortName: '신스 베이스',
    description: '두툼한 아날로그 톱니파와 서브 베이스 에너지를 전달',
    genreTag: 'City Pop / Synthwave / Rock',
    icon: Icons.tune_rounded,
  );

  // --- KEYS PROFILES ---
  static const keysPiano = SoundProfile(
    id: 'keys_piano',
    category: BandInstrumentCategory.keys,
    name: '어쿠스틱 그랜드 피아노 (Grand Piano)',
    shortName: '그랜드 피아노',
    description: '맑고 정갈한 해머 타건감과 웅장한 어쿠스틱 룸 울림',
    genreTag: 'Ballad / Pop / Classical',
    icon: Icons.piano_rounded,
  );

  static const keysRhodes = SoundProfile(
    id: 'keys_rhodes',
    category: BandInstrumentCategory.keys,
    name: '펜더 로즈 E.피아노 (Fender Rhodes)',
    shortName: '로즈 E.피아노',
    description: '영롱한 벨 차임(Bell Chime)과 스테레오 코러스 배음',
    genreTag: 'Neo-Soul / Lofi / Jazz',
    icon: Icons.waves_rounded,
  );

  static const keysOrgan = SoundProfile(
    id: 'keys_organ',
    category: BandInstrumentCategory.keys,
    name: '빈티지 해먼드 오르간 (Hammond B3)',
    shortName: '빈티지 오르간',
    description: '로터리 스피커(Leslie) 회전 바이브레이션과 퍼커시브 어택',
    genreTag: 'Blues / Rock / Gospel',
    icon: Icons.surround_sound_rounded,
  );

  static const keysPad = SoundProfile(
    id: 'keys_pad',
    category: BandInstrumentCategory.keys,
    name: '아날로그 웜 신스 패드 (Warm Synth Pad)',
    shortName: '신스 패드',
    description: '몽환적이고 넓은 스테레오 공간감으로 배경을 포근하게 감싸줌',
    genreTag: 'City Pop / Ambient / Electronic',
    icon: Icons.blur_on_rounded,
  );

  // --- GUITAR PROFILES ---
  static const guitarAcoustic = SoundProfile(
    id: 'guitar_acoustic',
    category: BandInstrumentCategory.guitar,
    name: '스틸 통기타 (Acoustic Steel)',
    shortName: '스틸 통기타',
    description: '찰랑거리는 스틸현 찰현음과 풍성한 어쿠스틱 바디 공명',
    genreTag: 'Acoustic / Folk / Pop',
    icon: Icons.music_note_rounded,
  );

  static const guitarClean = SoundProfile(
    id: 'guitar_clean',
    category: BandInstrumentCategory.guitar,
    name: '클린 일렉기타 (Electric Clean / Strat)',
    shortName: '클린 일렉',
    description: '맑고 선명한 싱글 픽업 톤과 아날로그 코러스 공간감',
    genreTag: 'Blues / Neo-Soul / Pop',
    icon: Icons.electric_bolt_rounded,
  );

  static const guitarNylon = SoundProfile(
    id: 'guitar_nylon',
    category: BandInstrumentCategory.guitar,
    name: '나일론 클래식 기타 (Classical Nylon)',
    shortName: '나일론 기타',
    description: '핑거링에 최적화된 부드럽고 둥근 어택과 따뜻한 중저음',
    genreTag: 'Bossa Nova / Jazz / Latin',
    icon: Icons.spa_rounded,
  );

  static const guitarCrunch = SoundProfile(
    id: 'guitar_crunch',
    category: BandInstrumentCategory.guitar,
    name: '크런치 오버드라이브 (Crunch Electric)',
    shortName: '크런치 일렉',
    description: '진공관 앰프를 살짝 드라이브시킨 거칠고 펀치력 있는 록 질감',
    genreTag: 'Rock / Blues / Funky Rock',
    icon: Icons.fireplace_rounded,
  );

  static const List<SoundProfile> allDrums = [
    drumsAcoustic,
    drumsLofi,
    drumsBrush,
    drumsElectronic,
  ];

  static const List<SoundProfile> allBass = [
    bassJazz,
    bassSlap,
    bassUpright,
    bassSynth,
  ];

  static const List<SoundProfile> allKeys = [
    keysPiano,
    keysRhodes,
    keysOrgan,
    keysPad,
  ];

  static const List<SoundProfile> allGuitar = [
    guitarAcoustic,
    guitarClean,
    guitarNylon,
    guitarCrunch,
  ];

  static List<SoundProfile> getProfilesForCategory(BandInstrumentCategory category) {
    switch (category) {
      case BandInstrumentCategory.drums:
        return allDrums;
      case BandInstrumentCategory.bass:
        return allBass;
      case BandInstrumentCategory.keys:
        return allKeys;
      case BandInstrumentCategory.guitar:
        return allGuitar;
    }
  }

  static SoundProfile getProfileById(String id, BandInstrumentCategory category) {
    final list = getProfilesForCategory(category);
    return list.firstWhere((p) => p.id == id, orElse: () => list.first);
  }

  /// 장르/스타일에 따른 추천 4대 악기 프로파일 자동 세팅
  static Map<BandInstrumentCategory, SoundProfile> getRecommendedProfilesForStyle(String style) {
    final s = style.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');

    if (s.contains('lofi') || s.contains('로파이') || s.contains('비오는') || s.contains('chill')) {
      return {
        BandInstrumentCategory.drums: drumsLofi,
        BandInstrumentCategory.bass: bassJazz,
        BandInstrumentCategory.keys: keysRhodes,
        BandInstrumentCategory.guitar: guitarNylon,
      };
    }

    if (s.contains('city') || s.contains('시티팝') || s.contains('disco') || s.contains('디스코') || s.contains('dance')) {
      return {
        BandInstrumentCategory.drums: drumsElectronic,
        BandInstrumentCategory.bass: bassSlap,
        BandInstrumentCategory.keys: keysPad,
        BandInstrumentCategory.guitar: guitarClean,
      };
    }

    if (s.contains('blue') || s.contains('블루스')) {
      return {
        BandInstrumentCategory.drums: drumsBrush,
        BandInstrumentCategory.bass: bassJazz,
        BandInstrumentCategory.keys: keysOrgan,
        BandInstrumentCategory.guitar: guitarCrunch,
      };
    }

    if (s.contains('acoustic') || s.contains('어쿠스틱') || s.contains('ballad') || s.contains('발라드') || s.contains('감성')) {
      return {
        BandInstrumentCategory.drums: drumsAcoustic,
        BandInstrumentCategory.bass: bassUpright,
        BandInstrumentCategory.keys: keysPiano,
        BandInstrumentCategory.guitar: guitarAcoustic,
      };
    }

    if (s.contains('rock') || s.contains('록') || s.contains('락') || s.contains('punk')) {
      return {
        BandInstrumentCategory.drums: drumsAcoustic,
        BandInstrumentCategory.bass: bassSlap,
        BandInstrumentCategory.keys: keysOrgan,
        BandInstrumentCategory.guitar: guitarCrunch,
      };
    }

    if (s.contains('jazz') || s.contains('funk') || s.contains('재즈') || s.contains('펑키')) {
      return {
        BandInstrumentCategory.drums: drumsBrush,
        BandInstrumentCategory.bass: bassUpright,
        BandInstrumentCategory.keys: keysRhodes,
        BandInstrumentCategory.guitar: guitarClean,
      };
    }

    // Default Neo-Soul
    return {
      BandInstrumentCategory.drums: drumsBrush,
      BandInstrumentCategory.bass: bassJazz,
      BandInstrumentCategory.keys: keysRhodes,
      BandInstrumentCategory.guitar: guitarClean,
    };
  }

}
