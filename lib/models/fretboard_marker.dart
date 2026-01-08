/// 프렛보드 상의 마커 정보를 담는 데이터 클래스입니다.
class FretboardMarker {
  final int fret; // 프렛 번호 (0 = 개방현)
  final String interval; // 인터벌 이름 (예: 1P, 3M, 5P) - 이에 따라 색상이 결정됨
  final bool isGhost; // (향후 확장용) 희미하게 표시할지 여부

  const FretboardMarker({
    required this.fret,
    required this.interval,
    this.isGhost = false,
  });
}

/// 보이스 리딩 라인의 유형
enum VoiceLeadingType {
  resolution, // 가이드톤 해결 (7 -> 3 등)
  economical, // 경제적 이동 (최단 거리)
}

/// 보이스 리딩 라인을 표현하는 데이터 클래스
class VoiceLeadingLine {
  final int fromStr; // 0 (Low E) ~ 5 (High E)
  final int fromFret;
  final int toStr;
  final int toFret;
  final String interval; // 이동하는 음의 인터벌 정보
  final VoiceLeadingType? _type;

  const VoiceLeadingLine({
    required this.fromStr,
    required this.fromFret,
    required this.toStr,
    required this.toFret,
    required this.interval,
    VoiceLeadingType? type = VoiceLeadingType.economical,
  }) : _type = type;

  VoiceLeadingType get type => _type ?? VoiceLeadingType.economical;
}
