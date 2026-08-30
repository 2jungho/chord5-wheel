import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/music_constants.dart';

class CircleOfFifthsPainter extends CustomPainter {
  final int selectedKeyIndex;
  final bool isInnerSelected;
  final bool isSeventhMode;
  final List<KeyData> keys;
  final ThemeData theme;

  CircleOfFifthsPainter({
    required this.selectedKeyIndex,
    required this.isInnerSelected,
    this.isSeventhMode = false,
    required this.keys,
    ThemeData? theme,
  }) : theme = theme ?? ThemeData.dark();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Base size for scaling calculations: 280
    final scale = size.width / 280.0;

    // Radii
    final rOuter = size.width * 0.45; // Max radius (legacy 190/210 approx)
    final rMiddle = size.width * 0.32; // Boundary between Major/Minor
    final rInner =
        size.width * 0.15; // Inner hole radius (Reduced from 0.19 to 0.15)

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = theme.scaffoldBackgroundColor
      ..strokeWidth = 1.0;

    final selectedBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = theme.scaffoldBackgroundColor
      ..strokeWidth = 3.0;

    // Draw Slices
    for (int i = 0; i < 12; i++) {
      final startRad = (i * 30 - 90) * (pi / 180);
      final sweepRad = 30 * (pi / 180);

      final key = keys[i];
      final isSelected = (i == selectedKeyIndex);
      final int dist = (i - selectedKeyIndex + 12) % 12;

      // --- Major Slice (Outer) ---
      final isMajorActive = isSelected && !isInnerSelected;

      paint.color = isMajorActive
          ? theme.colorScheme.primary
          : (i % 2 == 0
              ? theme.colorScheme.surface
              : theme.colorScheme.surfaceContainerHigh); // Alternating

      // Path for Outer Arc
      final pathOuter = Path();
      pathOuter.arcTo(Rect.fromCircle(center: center, radius: rOuter), startRad,
          sweepRad, false);
      pathOuter.arcTo(Rect.fromCircle(center: center, radius: rMiddle),
          startRad + sweepRad, -sweepRad, false // Reverse to go back
          );
      pathOuter.close();

      canvas.drawPath(pathOuter, paint);
      canvas.drawPath(
          pathOuter, isMajorActive ? selectedBorderPaint : borderPaint);

      // --- Minor Slice (Inner) ---
      final isMinorActive = isSelected && isInnerSelected;

      paint.color = isMinorActive
          ? theme.colorScheme.secondary
          : (i % 2 == 0
              ? theme.colorScheme.surfaceContainerHigh
              : theme.colorScheme.surface); // Alternating (swapped)

      final pathInner = Path();
      pathInner.arcTo(Rect.fromCircle(center: center, radius: rMiddle),
          startRad, sweepRad, false);
      pathInner.arcTo(Rect.fromCircle(center: center, radius: rInner),
          startRad + sweepRad, -sweepRad, false);
      pathInner.close();

      canvas.drawPath(pathInner, paint);
      canvas.drawPath(
          pathInner, isMinorActive ? selectedBorderPaint : borderPaint);

      // --- Determine slice text labels (Triad vs 7th) ---
      String majorText = key.name;
      String minorText = key.minor;

      if (isSeventhMode) {
        if (!isInnerSelected) {
          // Major Key mode: Diatonic major chords
          if (dist == 0 || dist == 11) {
            majorText = '${key.name}maj7';
          } else if (dist == 1) {
            majorText = '${key.name}7';
          }

          // Diatonic minor chords
          if (dist == 0 || dist == 1 || dist == 11) {
            minorText = '${key.minor}7';
          }
        } else {
          // Minor Key mode: Diatonic minor chords
          if (dist == 0 || dist == 1 || dist == 11) {
            minorText = '${key.minor}7';
          }

          // Diatonic relative major chords
          if (dist == 0 || dist == 11) {
            majorText = '${key.name}maj7';
          } else if (dist == 1) {
            majorText = '${key.name}7';
          }
        }
      }

      // --- Text Labels with adjusted radius to avoid badge overlap ---
      final midAngle = startRad + (15 * pi / 180);

      double majorTextR = (rMiddle + (rOuter - 26 * scale)) / 2 + 5 * scale;
      double majorFontSize = (majorText.length > 4
              ? 11.0
              : (majorText.length > 2 ? 12.5 : 14.0)) *
          scale;

      _drawText(
          canvas,
          center,
          midAngle,
          majorTextR,
          majorText,
          isMajorActive
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          FontWeight.bold,
          majorFontSize);

      // Minor Text (Inner Slice: rInner to rMiddle)
      double minorTextR = (rMiddle + (rInner + 24 * scale)) / 2 - 2 * scale;
      double minorFontSize = (minorText.length > 4
              ? 9.0
              : (minorText.length > 2 ? 10.0 : 11.0)) *
          scale;

      _drawText(
          canvas,
          center,
          midAngle,
          minorTextR,
          minorText,
          isMinorActive
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
          FontWeight.normal,
          minorFontSize);

      // --- Badges (I, IV, V, vi, ii, iii... or Imaj7, IVmaj7, V7... ) ---
      if (!isInnerSelected) {
        // === Major Key Selected ===
        if (dist == 0) {
          _drawBadge(
              canvas,
              center,
              midAngle,
              rOuter - 10 * scale,
              isSeventhMode ? 'Imaj7' : 'I',
              theme.colorScheme.primary,
              scale);
        } else if (dist == 1) {
          _drawBadge(canvas, center, midAngle, rOuter - 10 * scale,
              isSeventhMode ? 'V7' : 'V', Colors.amber, scale);
        } else if (dist == 11) {
          _drawBadge(canvas, center, midAngle, rOuter - 10 * scale,
              isSeventhMode ? 'IVmaj7' : 'IV', Colors.green, scale);
        }

        if (dist == 0) {
          _drawBadge(
              canvas,
              center,
              midAngle,
              rInner + 12 * scale,
              isSeventhMode ? 'vi7' : 'vi',
              theme.colorScheme.secondary,
              scale);
        } else if (dist == 1) {
          _drawBadge(canvas, center, midAngle, rInner + 12 * scale,
              isSeventhMode ? 'iii7' : 'iii', Colors.amber, scale);
        } else if (dist == 11) {
          _drawBadge(canvas, center, midAngle, rInner + 12 * scale,
              isSeventhMode ? 'ii7' : 'ii', Colors.green, scale);
        }
      } else {
        // === Minor Key Selected ===
        if (dist == 0) {
          _drawBadge(
              canvas,
              center,
              midAngle,
              rInner + 12 * scale,
              isSeventhMode ? 'i7' : 'i',
              theme.colorScheme.secondary,
              scale);
        } else if (dist == 1) {
          _drawBadge(canvas, center, midAngle, rInner + 12 * scale,
              isSeventhMode ? 'v7' : 'v', Colors.amber, scale);
        } else if (dist == 11) {
          _drawBadge(canvas, center, midAngle, rInner + 12 * scale,
              isSeventhMode ? 'iv7' : 'iv', Colors.green, scale);
        }

        // Outer Ring (Relative Majors):
        if (dist == 0) {
          _drawBadge(
              canvas,
              center,
              midAngle,
              rOuter - 10 * scale,
              isSeventhMode ? 'IIImaj7' : 'III',
              theme.colorScheme.primary,
              scale);
        } else if (dist == 1) {
          _drawBadge(canvas, center, midAngle, rOuter - 10 * scale,
              isSeventhMode ? 'VII7' : 'VII', Colors.amber, scale);
        } else if (dist == 11) {
          _drawBadge(canvas, center, midAngle, rOuter - 10 * scale,
              isSeventhMode ? 'VImaj7' : 'VI', Colors.green, scale);
        }
      }
    }
  }

  void _drawText(Canvas canvas, Offset center, double angle, double radius,
      String text, Color color, FontWeight weight, double size) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: size, fontWeight: weight),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();

    final x = center.dx + radius * cos(angle);
    final y = center.dy + radius * sin(angle);

    final offset =
        Offset(x - textPainter.width / 2, y - textPainter.height / 2);
    textPainter.paint(canvas, offset);
  }

  void _drawBadge(Canvas canvas, Offset center, double angle, double radius,
      String text, Color color, double scale) {
    final x = center.dx + radius * cos(angle);
    final y = center.dy + radius * sin(angle);
    final pos = Offset(x, y);

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
          color: Colors.white,
          fontSize:
              (text.length > 4 ? 7.0 : (text.length > 2 ? 8.0 : 9.0)) * scale,
          fontWeight: FontWeight.bold),
    );
    final textPainter =
        TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();

    final badgeHeight = 18.0 * scale;
    final badgeWidth = max(badgeHeight, textPainter.width + 8.0 * scale);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: badgeWidth, height: badgeHeight),
      Radius.circular(badgeHeight / 2),
    );

    final bgPaint = Paint()..color = color;
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawRRect(rrect, borderPaint);

    textPainter.paint(
        canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CircleOfFifthsPainter oldDelegate) {
    return oldDelegate.selectedKeyIndex != selectedKeyIndex ||
        oldDelegate.isInnerSelected != isInnerSelected ||
        oldDelegate.isSeventhMode != isSeventhMode;
  }
}
