import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/music_constants.dart';

class CircleOfFifthsPainter extends CustomPainter {
  final int selectedKeyIndex;
  final bool isInnerSelected;
  final List<KeyData> keys;
  final ThemeData theme;

  CircleOfFifthsPainter({
    required this.selectedKeyIndex,
    required this.isInnerSelected,
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

      // --- Text Labels with adjusted radius to avoid badge overlap ---
      final midAngle = startRad + (15 * pi / 180);

      // If badge exists, push text slightly. But better to fix badge pos near edge.
      // Current Badge Pos: Outer (rOuter - 13), Inner (rInner + 12).
      // Let's place Text centered in available space.

      // Major Text (Outer Slice: rMiddle to rOuter)
      // Radius Range: rMiddle ~ rOuter. Center: (rOuter + rMiddle)/2.
      // Badge is at rOuter-13. So clear space is rMiddle to rOuter-26.
      // Text Radius adjustment:
      double majorTextR = (rOuter + rMiddle) / 2;
      // If we have a badge on outer rim, maybe push text inward slightly?
      // Or just keep it centered. Overlap happens if text is large.
      majorTextR = (rMiddle + (rOuter - 26 * scale)) / 2 +
          5 * scale; // Slight shift down

      _drawText(
          canvas,
          center,
          midAngle,
          majorTextR,
          key.name,
          isMajorActive
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          FontWeight.bold,
          14 * scale);

      // Minor Text (Inner Slice: rInner to rMiddle)
      // Center: (rMiddle + rInner)/2.
      // Badge is at rInner + 12.
      double minorTextR = (rMiddle + (rInner + 24 * scale)) / 2 - 2 * scale;

      _drawText(
          canvas,
          center,
          midAngle,
          minorTextR,
          key.minor,
          isMinorActive
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
          FontWeight.normal,
          11 * scale);

      // --- Badges (I, IV, V, vi, ii, iii... ) ---
      // Logic: distance from selected index.
      int dist = (i - selectedKeyIndex + 12) % 12;

      // We need to draw Badges for BOTH rings depending on Major/Minor context.

      if (!isInnerSelected) {
        // === Major Key Selected ===
        // Outer Ring: I (0), IV (11), V (1)
        if (dist == 0) {
          _drawBadge(canvas, center, midAngle, rOuter - 10 * scale, 'I',
              theme.colorScheme.primary, scale);
        } else if (dist == 1) {
          _drawBadge(canvas, center, midAngle, rOuter - 10 * scale, 'V',
              Colors.amber, scale);
        } else if (dist == 11) {
          _drawBadge(canvas, center, midAngle, rOuter - 10 * scale, 'IV',
              Colors.green, scale);
        }

        if (dist == 0) {
          _drawBadge(canvas, center, midAngle, rInner + 12 * scale, 'vi',
              theme.colorScheme.secondary, scale);
        } else if (dist == 1) {
          _drawBadge(canvas, center, midAngle, rInner + 12 * scale, 'iii',
              Colors.amber, scale);
        } else if (dist == 11) {
          _drawBadge(canvas, center, midAngle, rInner + 12 * scale, 'ii',
              Colors.green, scale);
        }
      } else {
        // === Minor Key Selected ===
        // Inner Ring: i (0), iv (11), v (1)
        if (dist == 0) {
          _drawBadge(canvas, center, midAngle, rInner + 12 * scale, 'i',
              theme.colorScheme.secondary, scale);
        } else if (dist == 1) {
          _drawBadge(canvas, center, midAngle, rInner + 12 * scale, 'v',
              Colors.amber, scale);
        } else if (dist == 11) {
          _drawBadge(canvas, center, midAngle, rInner + 12 * scale, 'iv',
              Colors.green, scale);
        }

        // Outer Ring (Relative Majors):
        if (dist == 0) {
          _drawBadge(canvas, center, midAngle, rOuter - 10 * scale, 'III',
              theme.colorScheme.primary, scale);
        } else if (dist == 1) {
          _drawBadge(canvas, center, midAngle, rOuter - 10 * scale, 'VII',
              Colors.amber, scale);
        } else if (dist == 11) {
          _drawBadge(canvas, center, midAngle, rOuter - 10 * scale, 'VI',
              Colors.green, scale);
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

    // Convert polar to cartesian
    final x = center.dx + radius * cos(angle);
    final y = center.dy + radius * sin(angle);

    // Center the text on that point
    final offset =
        Offset(x - textPainter.width / 2, y - textPainter.height / 2);
    textPainter.paint(canvas, offset);
  }

  void _drawBadge(Canvas canvas, Offset center, double angle, double radius,
      String text, Color color, double scale) {
    final x = center.dx + radius * cos(angle);
    final y = center.dy + radius * sin(angle);
    final pos = Offset(x, y);

    final bgPaint = Paint()..color = color;
    canvas.drawCircle(pos, 9 * scale, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawCircle(pos, 9 * scale, borderPaint);

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
          color: Colors.white,
          fontSize: 9 * scale,
          fontWeight: FontWeight.bold),
    );
    final textPainter =
        TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CircleOfFifthsPainter oldDelegate) {
    return oldDelegate.selectedKeyIndex != selectedKeyIndex ||
        oldDelegate.isInnerSelected != isInnerSelected;
  }
}
