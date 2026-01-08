class ProgressionPreset {
  final String title;
  final String progression;
  final List<String> tags;
  final String description;
  final Map<String, List<String>>
      famousSongs; // Genre -> List of "Title - Artist"

  const ProgressionPreset({
    required this.title,
    required this.progression,
    required this.tags,
    this.description = '',
    this.famousSongs = const {},
  });
}

const List<ProgressionPreset> kProgressionPresets = [
  // 1. Pop & Ballad Essentials
  ProgressionPreset(
    title: 'Money Chord (Pop)',
    progression: 'C-G-Am-F',
    tags: ['Basic', 'Pop', 'Major'],
    description: '가장 대중적이고 히트곡에 많이 쓰이는 진행 (I-V-vi-IV)',
    famousSongs: {
      'Pop': [
        'Let It Be - The Beatles',
        'I\'m Yours - Jason Mraz',
        'Price Tag - Jessie J'
      ],
      'K-Pop': ['벚꽃 엔딩 - 버스커 버스커', '밤편지 - 아이유']
    },
  ),
  ProgressionPreset(
    title: '50s Progression',
    progression: 'C-Am-F-G',
    tags: ['Basic', 'Oldies', 'Ballad'],
    description: '50년대 팝과 발라드의 정석 (I-vi-IV-V)',
    famousSongs: {
      'Oldies': ['Stand By Me - Ben E. King', 'Unchained Melody'],
      'Pop': ['Baby - Justin Bieber']
    },
  ),
  ProgressionPreset(
    title: 'Canon Variation',
    progression: 'C-G-Am-Em-F-C-F-G',
    tags: ['Basic', 'Classical', 'Pop'],
    description: '파헬벨의 캐논 변주곡 진행',
    famousSongs: {
      'Pop': ['Basket Case - Green Day', 'Memories - Maroon 5'],
      'K-Pop': ['아로하 - 쿨', '너에게 난 나에게 넌']
    },
  ),

  // 2. Jazz Essentials
  ProgressionPreset(
    title: 'Jazz 2-5-1 (Major)',
    progression: 'Dm7-G7-CMaj7',
    tags: ['Jazz', 'Essential', 'Major'],
    description: '재즈의 가장 기초가 되는 2-5-1 진행 (ii-V-I)',
    famousSongs: {
      'Jazz': ['Autumn Leaves (Major)', 'Fly Me To The Moon'],
      'Pop': ['Sunday Morning - Maroon 5']
    },
  ),
  ProgressionPreset(
    title: 'Jazz 2-5-1 (Minor)',
    progression: 'Bm7b5-E7-Am7',
    tags: ['Jazz', 'Essential', 'Minor'],
    description: '마이너 키에서의 2-5-1 진행 (ii-V-i)',
    famousSongs: {
      'Jazz': ['Blue Bossa', 'Black Orpheus', 'Autumn Leaves (Minor)']
    },
  ),
  ProgressionPreset(
    title: 'Standard Turnaround (3-6-2-5)',
    progression: 'Em7-A7-Dm7-G7',
    tags: ['Jazz', 'Turnaround', 'Standard'],
    description: 'iii-VI-ii-V 진행 (C Major Key)',
    famousSongs: {
      'Jazz': ['I Got Rhythm', 'All The Things You Are']
    },
  ),

  ProgressionPreset(
    title: 'Coltrane Changes',
    progression: 'CMaj7-Eb7-AbMaj7-B7-EMaj7-G7-CMaj7',
    tags: ['Jazz', 'Complex', 'Advanced'],
    description: '장3도 간격의 토닉 시스템 (Giant Steps)',
    famousSongs: {
      'Jazz': ['Giant Steps', 'Countdown']
    },
  ),

  // 3. Blues Essentials
  ProgressionPreset(
    title: 'Simple Blues',
    progression: 'C7-F7-C7-G7',
    tags: ['Blues', 'Traditional'],
    description: '블루스 12마디 형식의 핵심 뼈대',
    famousSongs: {
      'Blues': ['Sweet Home Chicago', 'Pride and Joy'],
      'Rock': ['Johnny B. Goode']
    },
  ),

  // 4. Genre Specific Favorites
  ProgressionPreset(
    title: 'Royal Road (J-Pop)',
    progression: 'FM7-G7-Em7-Am7',
    tags: ['J-Pop', 'Anime', 'Emotional'],
    description: '일본 음악과 애니메이션의 왕도 진행 (IV-V-iii-vi)',
    famousSongs: {
      'J-Pop': ['Lemon - Kenshi Yonezu', 'Pretender'],
      'Anime': ['God Knows...', 'Blue Bird']
    },
  ),
  ProgressionPreset(
    title: 'Just the Two of Us (R&B)',
    progression: 'FM7-E7-Am7-Gm7-C7',
    tags: ['R&B', 'Neo-Soul', 'Groovy'],
    description: '세련된 도시적 감성의 R&B 진행',
    famousSongs: {
      'R&B': ['Just the Two of Us'],
      'K-Pop': ['Instagram - DEAN']
    },
  ),
];
