import 'dart:math';
import 'package:flutter/material.dart';

/// 5도권 휠의 터치 좌표 계산 및 슬라이스 판별을 담당하는 공통 수학 헬퍼
class WheelMathHelper {
  static const double defaultOuterRadiusRatio = 0.45;
  static const double defaultMiddleRadiusRatio = 0.32;
  static const double defaultInnerRadiusRatio = 0.15;

  /// 터치 좌표(Offset)와 휠 크기(size)로부터 선택된 키의 인덱스(0~11)와 Inner(Minor)/Outer(Major) 링 여부를 계산합니다.
  /// 휠의 중심 구멍(Hole) 내부나 휠 바깥쪽을 터치한 경우 null을 반환합니다.
  static ({int index, bool isInner})? calculateKeySelection(
    Offset localPosition,
    double size, {
    double outerRatio = defaultOuterRadiusRatio,
    double middleRatio = defaultMiddleRadiusRatio,
    double innerRatio = defaultInnerRadiusRatio,
  }) {
    final center = size / 2;
    final dx = localPosition.dx - center;
    final dy = localPosition.dy - center;
    final dist = sqrt(dx * dx + dy * dy);

    final rOuter = size * outerRatio;
    final rMiddle = size * middleRatio;
    final rInner = size * innerRatio;

    // 휠 영역 바깥 또는 중앙 구멍 터치 시 무효
    if (dist < rInner || dist > rOuter) return null;

    final isInner = dist <= rMiddle;
    final angle = atan2(dy, dx); // -pi to pi

    double deg = angle * 180 / pi;
    double normalized = deg + 90;
    if (normalized < 0) normalized += 360;

    int index = (normalized / 30).floor() % 12;

    return (index: index, isInner: isInner);
  }
}
