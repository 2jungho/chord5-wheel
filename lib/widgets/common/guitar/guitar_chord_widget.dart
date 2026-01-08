import 'package:flutter/material.dart';
import '../../../models/chord_model.dart';

class GuitarChordPainter extends CustomPainter {
  final ChordVoicing voicing;
  final bool showFingerings; // Not used yet, placeholder for future
  final bool isMainChord;
  final int stringCount;

  final ColorScheme colorScheme;
  final Color dividerColor;

  GuitarChordPainter({
    required this.voicing,
    this.showFingerings = false,
    this.isMainChord = false,
    this.stringCount = 6,
    required this.colorScheme,
    required this.dividerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Canvas config
    final w = size.width;
    final h = size.height;

    // Scale Logic (Horizontal layout usually wider)
    // Adjust scale factor based on width as primary dimension
    final scale = w / 160.0;

    // Grid Setup
    // Bottom padding needs space for String names (optional) or just symmetry
    // Left padding needs space for Nut/Fret Number/Mute Marks
    final double paddingLeft = 32.0 * scale;
    final double paddingRight = 10.0 * scale;
    final double paddingTop = 6.0 * scale;
    final double paddingBottom = 6.0 * scale;

    final double stringGap = (stringCount <= 1)
        ? (h - paddingTop - paddingBottom)
        : (h - paddingTop - paddingBottom) / (stringCount - 1);
    final double fretGap = (w - paddingLeft - paddingRight) / 5;

    final paintLine = Paint()
      ..color = colorScheme.onSurfaceVariant
      ..strokeWidth = 1.0 * scale;

    final paintFret = Paint()
      ..color = colorScheme.outline
      ..strokeWidth = 1.0 * scale;

    // 1. Strings (Horizontal Lines)
    // i=0 (Low E) -> Bottom
    // i=(stringCount-1) (High String) -> Top
    for (int i = 0; i < stringCount; i++) {
      // Calculate Y position
      // i=0 should be lowest Y (largest value) -> h - paddingBottom
      // i=max should be highest Y (smallest value) -> paddingTop
      final y = (h - paddingBottom) - (i * stringGap);

      // Make low E string (i=0) thicker and use secondary color
      if (i == 0) {
        paintLine.color = colorScheme.secondary;
        paintLine.strokeWidth = 2.5 * scale;
      } else {
        paintLine.color = colorScheme.onSurfaceVariant;
        paintLine.strokeWidth = 1.0 * scale;
      }
      canvas.drawLine(
          Offset(paddingLeft, y), Offset(w - paddingRight, y), paintLine);
    }

    // 2. Frets (Vertical Lines)
    for (int i = 0; i <= 5; i++) {
      final x = paddingLeft + i * fretGap;
      canvas.drawLine(
          Offset(x, paddingTop), Offset(x, h - paddingBottom), paintFret);
    }

    // Nut (Vertical Bar at Left)
    if (voicing.startFret <= 1) {
      final paintNut = Paint()
        ..color = dividerColor
        ..strokeWidth = 4.0 * scale;
      canvas.drawLine(Offset(paddingLeft, paddingTop),
          Offset(paddingLeft, h - paddingBottom), paintNut);
    } else {
      // Draw Start Fret Number on the Left side
      final textSpan = TextSpan(
        text: '${voicing.startFret}fr',
        style: TextStyle(
            color: colorScheme.onSurface, // Improved visibility
            fontSize: 10 * scale,
            fontWeight: FontWeight.bold),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();

      // Position: Centered vertically, and left of paddingLeft
      // Rotate text -90 deg for "2fr" style (reading up)

      canvas.save();
      // Pivot point for rotation: slightly left of the grid
      canvas.translate(paddingLeft - 8 * scale, h / 2);
      canvas.rotate(-3.14159 / 2);
      // Draw centered at pivot
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Tuning offsets: E(0), A(5), D(10), G(15), B(19), E(24) maps to stringIdx 0..5 (Low E to High E)
    // Note: This is hardcoded for Guitar Standard Tuning.
    // For Bass (4 strings), strings 0-3 match Guitar's 0-3 (E, A, D, G).
    // So the existing logic works if we only use indices 0..3 for Bass.
    final tuningOffsets = [0, 5, 10, 15, 19, 24];

    // 3. Dots
    // Calculate Root Absolute Value first for Interval Calculation
    int rootAbsVal = -1;
    // voicing.rootString is 1-based index from High E? Or Low E?
    // Usually rootString is e.g. 6(LowE), 5(A)...
    // Model defines: logic in UI, but usually 1-6.
    // In Painter: int rootStringIdx = 6 - voicing.rootString; // 6 - 6 = 0 (Low E)
    // If stringCount is 4 (Bass), and rootString is 4 (Low E), then we need correct math.
    // Let's assume voicing.rootString refers to "N-th string from High E" convention common in guitar tabs,
    // OR "String Number" where 6=LowE.
    // If we simply use index from voicing.frets, we need to know which index is root.
    // Let's search for the root note in the visual representation.
    // The current code: rootStringIdx = 6 - voicing.rootString.
    // If Bass (4 strings), and we use Guitar Chords, rootString might still be 6 (Low E).
    // If we map Guitar 0..3 to Bass 0..3, then Guitar string 6 (idx 0) is Bass string 4 (idx 0).

    // For now, let's keep the existing logic but clamp index to stringCount?
    // Or better: Re-calculate rootStringIdx for display.
    // If voicing was generated for 6-string, rootString 6 means index 0.
    // If we just render indices 0..3 for bass, index 0 is valid.

    int rootStringIdx = 6 - voicing.rootString; // Default 6-string logic

    if (rootStringIdx >= 0 && rootStringIdx < 6) {
      // Root exists in the 6-string layout.
      // Check if this string is visible in current instrument (stringCount)
      // If stringCount=4, we only show indices 0,1,2,3.
      if (rootStringIdx < stringCount) {
        int rf = voicing.frets[rootStringIdx];
        if (rf != -1) {
          rootAbsVal = tuningOffsets[rootStringIdx] + rf;
        }
      }
    }

    // Iterate only up to stringCount
    for (int stringIdx = 0; stringIdx < stringCount; stringIdx++) {
      if (stringIdx >= voicing.frets.length) break;

      final fret = voicing.frets[stringIdx];

      // Y coord: Same as string drawing
      final y = (h - paddingBottom) - (stringIdx * stringGap);

      if (fret == -1) {
        // X (Mute)
        // Check if we should draw X for unused strings?
        // For Bass, we usually play only 4 strings.
        // If the filtered-out upper strings were played, we just ignore them.

        // Position: Left of Nut (x < paddingLeft)
        final tp = TextPainter(
            text: TextSpan(
                text: 'x',
                style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.bold)),
            textDirection: TextDirection.ltr);
        tp.layout();

        // Align vertically with string line (y)
        // Align horizontally: left of paddingLeft
        tp.paint(canvas, Offset(paddingLeft - 18 * scale, y - tp.height / 2));
      } else if (fret == 0) {
        // Open O
        final paintOpen = Paint()
          ..style = PaintingStyle.stroke
          ..color = colorScheme.onSurfaceVariant
          ..strokeWidth = 1.5 * scale;
        canvas.drawCircle(
            Offset(paddingLeft - 10 * scale, y), 4 * scale, paintOpen);
      } else {
        // Fret Dot
        int sFret = (voicing.startFret <= 1) ? 1 : voicing.startFret;
        int relFret = fret - sFret + 1; // 1-based relative fret index

        if (relFret >= 1 && relFret <= 5) {
          // X coord: paddingLeft + (relFret - 0.5) * fretGap
          final cx = paddingLeft + (relFret * fretGap) - (fretGap / 2);
          final cy = y;

          // Calculate Interval
          String ivText = '';
          Color dotColor = colorScheme.surfaceContainerHighest;
          Color textColor = Colors.white;
          bool isGuideTone = false;

          if (rootAbsVal != -1) {
            int currentVal = tuningOffsets[stringIdx] + fret;
            int diff = (currentVal - rootAbsVal) % 12;
            if (diff < 0) diff += 12;
            ivText = _getIntervalText(diff);

            // Interval-based Coloring
            if (diff == 0) {
              // Root
              dotColor = const Color(0xFFEF5350); // Red 400
              textColor = Colors.white;
            } else if (diff == 3 || diff == 4) {
              // 3rd (Major/Minor) - Guide Tone
              dotColor = const Color(0xFFFFD54F); // Amber 300 (Gold-ish)
              textColor = Colors.black87;
              isGuideTone = true;
            } else if (diff == 7 || diff == 6 || diff == 8) {
              // 5th (Perfect, Flat, Sharp)
              dotColor = const Color(0xFF90CAF9); // Blue 200 (Subtler)
              textColor = Colors.black87;
            } else if (diff == 10 || diff == 11) {
              // 7th (b7, 7) - Guide Tone
              dotColor = const Color(0xFFFFCA28); // Amber 400
              textColor = Colors.black87;
              isGuideTone = true;
            } else {
              // Extensions (2, 4, 6, etc.)
              dotColor = const Color(0xFFCE93D8); // Purple 200
              textColor = Colors.black87;
            }
          }

          // Draw Dot
          final paintDot = Paint()
            ..style = PaintingStyle.fill
            ..color = dotColor;

          canvas.drawCircle(Offset(cx, cy), 8 * scale, paintDot);

          // Add Border
          // Guide Tones get a special border
          if (isGuideTone) {
            final paintGuideBorder = Paint()
              ..style = PaintingStyle.stroke
              ..color = const Color(0xFFF57F17) // Dark Amber/Orange
              ..strokeWidth = 2.5 * scale;
            canvas.drawCircle(Offset(cx, cy), 8.5 * scale, paintGuideBorder);
          } else {
            // Standard border
            final paintBorder = Paint()
              ..style = PaintingStyle.stroke
              ..color = colorScheme.onSurface
              ..strokeWidth = 1.0 * scale;
            canvas.drawCircle(Offset(cx, cy), 8 * scale, paintBorder);
          }

          // Draw Text
          if (ivText.isNotEmpty) {
            final textSpan = TextSpan(
              text: ivText,
              style: TextStyle(
                color: textColor,
                fontSize: 7 * scale,
                fontWeight: FontWeight.bold,
              ),
            );
            final tp =
                TextPainter(text: textSpan, textDirection: TextDirection.ltr);
            tp.layout();
            tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
          }
        }
      }
    }
  }

  String _getIntervalText(int semitones) {
    switch (semitones) {
      case 0:
        return 'R';
      case 1:
        return 'b2';
      case 2:
        return '2';
      case 3:
        return 'b3';
      case 4:
        return '3';
      case 5:
        return '4';
      case 6:
        return 'b5';
      case 7:
        return '5';
      case 8:
        return '#5';
      case 9:
        return '6';
      case 10:
        return 'b7';
      case 11:
        return '7';
      default:
        return '';
    }
  }

  @override
  bool shouldRepaint(covariant GuitarChordPainter oldDelegate) {
    return oldDelegate.voicing != voicing ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.stringCount != stringCount ||
        oldDelegate.dividerColor != dividerColor;
  }
}

class GuitarChordWidget extends StatelessWidget {
  final ChordVoicing voicing;
  final double width;
  final double height;
  final bool isMain;
  final int stringCount;

  const GuitarChordWidget({
    super.key,
    required this.voicing,
    this.width = 160,
    this.height = 120,
    this.isMain = false,
    this.stringCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: CustomPaint(
        painter: GuitarChordPainter(
          voicing: voicing,
          isMainChord: isMain,
          stringCount: stringCount,
          colorScheme: Theme.of(context).colorScheme,
          dividerColor: Theme.of(context).dividerColor,
        ),
        size: Size(width, height),
      ),
    );
  }
}
