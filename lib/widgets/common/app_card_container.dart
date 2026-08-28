import 'dart:ui';
import 'package:flutter/material.dart';

/// 앱 전체에서 패널, 대시보드, 카드 요소의 외형을 일관되게 구성하는 범용 컨테이너
class AppCardContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool enableBlur;
  final double blur;
  final double opacity;
  final Color? backgroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final BoxConstraints? constraints;

  const AppCardContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(12),
    this.margin,
    this.enableBlur = false,
    this.blur = 10.0,
    this.opacity = 1.0,
    this.backgroundColor,
    this.border,
    this.boxShadow,
    this.constraints,
  });

  /// 글래스모피즘(블러 + 반투명) 프리셋 팩토리
  factory AppCardContainer.glass({
    Key? key,
    required Widget child,
    double borderRadius = 16.0,
    EdgeInsetsGeometry? padding = const EdgeInsets.all(12),
    EdgeInsetsGeometry? margin,
    double blur = 10.0,
    double opacity = 0.6,
    Color? color,
    Border? border,
    BoxConstraints? constraints,
  }) {
    return AppCardContainer(
      key: key,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      enableBlur: true,
      blur: blur,
      opacity: opacity,
      backgroundColor: color,
      border: border,
      constraints: constraints,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = backgroundColor ?? theme.colorScheme.surface;
    final effectiveBorder = border ??
        Border.all(
          color: theme.dividerColor.withValues(alpha: enableBlur ? 0.3 : 0.6),
          width: 1.0,
        );

    Widget content = Container(
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: enableBlur
            ? effectiveColor.withValues(alpha: opacity)
            : effectiveColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: effectiveBorder,
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (enableBlur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
