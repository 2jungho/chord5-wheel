import 'package:flutter/material.dart';

/// 프렛보드 렌더링 및 화성학 인터벌/보이스리딩 표현을 위한 불변 색상 상수
class FretboardColors {
  FretboardColors._();

  // --- Voice Leading & Guide Tones ---
  /// 해결선 (Resolution) 및 가이드 톤 (3도, 7도) 하이라이트
  static const Color guideToneOrResolution = Color(0xFFfbbf24);

  /// 텐션선 (Tension) 및 기본 보이싱 강조 색상
  static const Color voiceLeadingTension = Color(0xFFc084fc);

  /// 보이스 리딩 타겟 마커 채우기 색상
  static const Color voiceLeadingTarget = Color(0xFFa855f7);

  /// 비활성/고스트 마커 기본 색상
  static const Color ghostMarker = Color.fromARGB(242, 151, 150, 151);

  // --- Intervals ---
  /// 루트 음 (Root, 1P, 1)
  static const Color root = Color(0xFFef4444);

  /// 장3도 (Major 3rd)
  static const Color majorThird = Color(0xFF60a5fa);

  /// 단3도 (Minor 3rd)
  static const Color minorThird = Color(0xFF22d3ee);

  /// 5도 (5th, 5P)
  static const Color fifth = Color(0xFFfacc15);

  /// 7도 (7th, 7M, 7m)
  static const Color seventh = Color(0xFF4ade80);

  /// 마커 내부 인터벌 라벨 텍스트 색상
  static const Color markerText = Color(0xFF1e293b);

  // --- CAGED Zone Overlay Colors ---
  static const Color cagedE = Color(0xFF4ade80);
  static const Color cagedD = Color(0xFF60a5fa);
  static const Color cagedC = Color(0xFFf87171);
  static const Color cagedA = Color(0xFFfb923c);
  static const Color cagedG = Color(0xFFfacc15);

  /// CAGED 5개 폼 순서별 팔레트 (E, D, C, A, G)
  static const List<Color> cagedZonePalette = [
    cagedE,
    cagedD,
    cagedC,
    cagedA,
    cagedG,
  ];
}
