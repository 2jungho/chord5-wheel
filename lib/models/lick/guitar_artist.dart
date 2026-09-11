/// 기타리스트 아티스트 엔티티 모델
class GuitarArtist {
  final String id; // 예: 'hendrix', 'page', 'gilmour'
  final String name; // 예: 'Jimi Hendrix'
  final String koreanName; // 예: '지미 헨드릭스'
  final String genre; // 'Blues & Blues Rock', 'Classic & Hard Rock', etc.
  final String era; // '1960s', '1970s', '1980s', 'Modern'
  final String signatureGuitar; // 예: 'Fender Stratocaster'
  final String bio; // 아티스트 설명 및 대표 사운드 특징
  final List<String> famousSongs; // 대표곡
  final String? avatarAsset; // 아바타 또는 이미지 에셋 경로

  const GuitarArtist({
    required this.id,
    required this.name,
    required this.koreanName,
    required this.genre,
    required this.era,
    required this.signatureGuitar,
    required this.bio,
    required this.famousSongs,
    this.avatarAsset,
  });

  factory GuitarArtist.fromJson(Map<String, dynamic> json) {
    return GuitarArtist(
      id: json['id'] as String,
      name: json['name'] as String,
      koreanName: json['koreanName'] as String,
      genre: json['genre'] as String,
      era: json['era'] as String,
      signatureGuitar: json['signatureGuitar'] as String,
      bio: json['bio'] as String,
      famousSongs: (json['famousSongs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      avatarAsset: json['avatarAsset'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'koreanName': koreanName,
      'genre': genre,
      'era': era,
      'signatureGuitar': signatureGuitar,
      'bio': bio,
      'famousSongs': famousSongs,
      'avatarAsset': avatarAsset,
    };
  }
}
