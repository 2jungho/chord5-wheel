import 'package:flutter/material.dart';
import '../../../utils/theory_utils.dart';
import '../../../models/fretboard_marker.dart';
import '../../../models/instrument_model.dart';

class ZoneDef {
  final String name;
  final int min;
  final int max;
  final Color bg;
  final Color fg;
  ZoneDef(this.name, this.min, this.max, this.bg, this.fg);
}

class FretboardPainter extends CustomPainter {
  final Map<int, List<FretboardMarker>> highlightMap;
  final int fretCount;
  final String? rootNote;
  final Set<String>? visibleIntervals;
  final String? focusCagedForm;
  final bool isMinor;

  final Color stringColor;
  final Color nutColor;
  final Color fretColor;
  final Color inlayColor;
  final Color labelColor;
  final List<VoiceLeadingLine>? voiceLeadingLines;
  final Instrument instrument;

  FretboardPainter({
    required this.highlightMap,
    required this.fretCount,
    this.rootNote,
    this.visibleIntervals,
    this.focusCagedForm,
    this.isMinor = false,
    this.voiceLeadingLines,
    required this.stringColor,
    required this.nutColor,
    required this.fretColor,
    required this.inlayColor,
    required this.labelColor,
    required this.instrument,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- 레이아웃 설정 ---
    final double paddingX = 30.0;
    final double paddingY = 25.0; // 상하 여백
    // 현 개수에 따라 간격 계산 (현이 1개일 경우 0으로 나누는 것 방지)
    final int strCount = instrument.stringCount;
    final double stringGap =
        strCount > 1 ? (h - 2 * paddingY) / (strCount - 1) : (h - 2 * paddingY);
    final double fretGap = (w - 2 * paddingX) / fretCount; // 프렛 간 간격

    final paintString = Paint()
      ..color = stringColor
      ..strokeWidth = 1.5;
    final paintFret = Paint()
      ..color = fretColor
      ..strokeWidth = 2.0;
    final paintNut = Paint()
      ..color = nutColor
      ..strokeWidth = 4.0;

    // CAGED Zones 계산
    List<ZoneDef> zones = [];
    if (rootNote != null) {
      zones = _getZones(TheoryUtils.getNoteIndex(rootNote!), isMinor);
    }

    // Zone 필터링 (Focus Mode)
    if (focusCagedForm != null && zones.isNotEmpty) {
      final focusChar = focusCagedForm![0];
      final candidates =
          zones.where((z) => z.name.startsWith(focusChar)).toList();
      if (candidates.isNotEmpty) {
        ZoneDef? bestZone;
        int maxScore = -1;
        for (final zone in candidates) {
          int score = 0;
          highlightMap.forEach((stringIdx, markers) {
            for (final marker in markers) {
              if (visibleIntervals != null &&
                  !visibleIntervals!.contains(marker.interval)) {
                continue;
              }
              if (marker.fret >= zone.min && marker.fret <= zone.max) score++;
            }
          });
          if (score > maxScore) {
            maxScore = score;
            bestZone = zone;
          }
        }
        if (bestZone != null) {
          zones = [bestZone];
        } else {
          zones = [];
        }
      } else {
        zones = [];
      }
    }

    // 0. CAGED Zones 그리기
    if (zones.isNotEmpty) {
      for (final z in zones) {
        _drawZoneRect(canvas, z, w, h, paddingX, paddingY, fretGap);
      }
    }

    // 1. 프렛(Frets) 및 인레이(Inlays) 그리기
    for (int i = 0; i <= fretCount; i++) {
      final x = paddingX + i * fretGap;
      canvas.drawLine(Offset(x, paddingY), Offset(x, h - paddingY),
          i == 0 ? paintNut : paintFret);

      if ([3, 5, 7, 9, 15, 17].contains(i)) {
        canvas.drawCircle(
            Offset(x - fretGap / 2, h / 2), 4, Paint()..color = inlayColor);
      } else if (i == 12) {
        canvas.drawCircle(Offset(x - fretGap / 2, h / 2 - stringGap), 4,
            Paint()..color = inlayColor);
        canvas.drawCircle(Offset(x - fretGap / 2, h / 2 + stringGap), 4,
            Paint()..color = inlayColor);
      }

      if ([3, 5, 7, 9, 12, 15, 17].contains(i)) {
        final textSpan = TextSpan(
            text: '$i',
            style: TextStyle(
                color: labelColor, fontSize: 10, fontWeight: FontWeight.bold));
        final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
          ..layout();
        tp.paint(
            canvas, Offset(x - fretGap / 2 - tp.width / 2, h - paddingY + 4));
      }
    }

    // 2. 스트링(Strings) 그리기
    for (int i = 0; i < strCount; i++) {
      paintString.strokeWidth = 1.0 + (i * 0.4);
      final y = paddingY + i * stringGap;
      canvas.drawLine(
          Offset(paddingX, y), Offset(w - paddingX, y), paintString);

      // 튜닝 라벨 (instrument.tuning 활용)
      String noteLabel = '';
      if (instrument.tuning.isNotEmpty && i < instrument.tuning.length) {
        final tuningIndex = (instrument.tuning.length - 1) - i;
        if (tuningIndex >= 0) {
          noteLabel =
              instrument.tuning[tuningIndex].replaceAll(RegExp(r'[0-9]'), '');
        }
      }

      final tp = TextPainter(
          text: TextSpan(
              text: noteLabel,
              style: TextStyle(
                  color: labelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(paddingX - 18, y - tp.height / 2));
    }

    // 2.5. Spotlight Vignette (Focus Mode Overlay)
    if (focusCagedForm != null && zones.isNotEmpty) {
      final fullRect = Rect.fromLTWH(0, 0, w, h);
      final fullPath = Path()..addRect(fullRect);

      final zonePath = Path();
      for (final z in zones) {
        final s = z.min.clamp(0, fretCount);
        final e = z.max.clamp(0, fretCount);
        if (s > e) continue;

        double startX =
            (s == 0) ? paddingX - 15 : paddingX + (s * fretGap) - fretGap;
        double endX = paddingX + e * fretGap;

        if (s > 0) startX += 2;
        endX -= 2;

        final zoneRect = Rect.fromLTRB(startX - 10, 0, endX + 10, h);
        zonePath.addRRect(
            RRect.fromRectAndRadius(zoneRect, const Radius.circular(8)));
      }

      final vignettePath =
          Path.combine(PathOperation.difference, fullPath, zonePath);

      final vignettePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..style = PaintingStyle.fill;

      vignettePaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
      canvas.drawPath(vignettePath, vignettePaint);
    }

    // 3. 보이스 리딩 라인 그리기
    if (voiceLeadingLines != null) {
      for (final line in voiceLeadingLines!) {
        if (line.fromStr >= strCount || line.toStr >= strCount) continue;

        final isResolution =
            (line.type as dynamic) == VoiceLeadingType.resolution;

        final linePaint = Paint()
          ..color = isResolution
              ? const Color(0xFFfbbf24)
              : const Color(0xFFc084fc)
          ..strokeWidth = isResolution ? 4.0 : 3.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        if (isResolution) {
          linePaint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
        }

        final fromVisualRow = (strCount - 1) - line.fromStr;
        final fromY = paddingY + fromVisualRow * stringGap;
        final fromX = line.fromFret == 0
            ? paddingX - 10
            : paddingX + (line.fromFret * fretGap) - (fretGap / 2);

        final toVisualRow = (strCount - 1) - line.toStr;
        final toY = paddingY + toVisualRow * stringGap;
        final toX = line.toFret == 0
            ? paddingX - 10
            : paddingX + (line.toFret * fretGap) - (fretGap / 2);

        final path = Path()..moveTo(fromX, fromY);
        final midX = (fromX + toX) / 2;
        final double curveHeight = isResolution ? 30 : 15;
        final midY = (fromY + toY) / 2 - (fromX == toX ? 5 : curveHeight);

        path.quadraticBezierTo(midX, midY, toX, toY);
        canvas.drawPath(path, linePaint);

        final endDotPaint = Paint()
          ..color =
              isResolution ? const Color(0xFFfbbf24) : const Color(0xFFc084fc);

        canvas.drawCircle(Offset(toX, toY), isResolution ? 5 : 4, endDotPaint);

        if (isResolution) {
          canvas.drawCircle(Offset(toX, toY), 8,
              Paint()..color = const Color(0xFFfbbf24).withValues(alpha: 0.3));
        }
      }
    }

    // 4. 마커(Markers) 그리기
    highlightMap.forEach((stringIdx, markers) {
      if (stringIdx >= strCount) return;

      final visualRow = (strCount - 1) - stringIdx;
      final y = paddingY + visualRow * stringGap;

      for (final marker in markers) {
        if (marker.fret > fretCount) continue;
        if (visibleIntervals != null &&
            !visibleIntervals!.contains(marker.interval)) {
          continue;
        }

        bool isTarget = false;
        if (voiceLeadingLines != null) {
          isTarget = voiceLeadingLines!.any(
              (line) => line.toFret == marker.fret && line.toStr == stringIdx);
        }

        bool isDimmed = false;
        if (!isTarget &&
            marker.isGhost &&
            focusCagedForm != null &&
            zones.isNotEmpty) {
          isDimmed = !zones.any((z) =>
              z.name.startsWith(focusCagedForm!) &&
              marker.fret >= z.min &&
              marker.fret <= z.max &&
              z.max > 0);
        }

        final x = marker.fret == 0
            ? paddingX - 10
            : paddingX + (marker.fret * fretGap) - (fretGap / 2);

        Color fillColor = const Color(0xFFc084fc);
        Color strokeColor = Colors.white;

        if (marker.isGhost || isDimmed) {
          fillColor = isTarget
              ? const Color(0xFFa855f7)
              : const Color.fromARGB(242, 151, 150, 151);
          strokeColor = Colors.transparent;

          if (isDimmed) {
            fillColor = fillColor.withValues(alpha: 0.3);
          }
        } else {
          final iv = marker.interval;
          fillColor = switch (iv) {
            '1P' || '1' => const Color(0xFFef4444),
            _ when iv.contains('3') => iv.contains('M')
                ? const Color(0xFF60a5fa)
                : const Color(0xFF22d3ee),
            _ when iv.contains('5') => const Color(0xFFfacc15),
            _ when iv.contains('7') => const Color(0xFF4ade80),
            _ => fillColor,
          };
        }

        canvas.drawCircle(Offset(x, y), 11,
            Paint()..color = strokeColor.withValues(alpha: isDimmed ? 0.2 : 1.0));

        if (isTarget) {
          canvas.drawCircle(
              Offset(x, y),
              13,
              Paint()
                ..color = const Color(0xFFc084fc)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.5);
        }

        canvas.drawCircle(Offset(x, y), 9, Paint()..color = fillColor);

        final tp = TextPainter(
            text: TextSpan(
                text: marker.interval,
                style: TextStyle(
                    color: const Color(0xFF1e293b)
                        .withValues(alpha: (marker.isGhost || isDimmed) ? 0.5 : 1.0),
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
            textDirection: TextDirection.ltr)
          ..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
      }
    });

    // 5. Missing Voice Leading Targets 그리기
    if (voiceLeadingLines != null) {
      final drawnPoints = <String>{};
      highlightMap.forEach((s, markers) {
        for (var m in markers) {
          drawnPoints.add('${m.fret}-$s');
        }
      });

      for (final line in voiceLeadingLines!) {
        if (line.toStr >= strCount || line.fromStr >= strCount) continue;

        final key = '${line.toFret}-${line.toStr}';
        if (drawnPoints.contains(key)) continue;

        final visualRow = (strCount - 1) - line.toStr;
        final y = paddingY + visualRow * stringGap;

        final x = line.toFret == 0
            ? paddingX - 10
            : paddingX + (line.toFret * fretGap) - (fretGap / 2);

        canvas.drawCircle(
            Offset(x, y),
            13,
            Paint()
              ..color = const Color(0xFFc084fc)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5);

        canvas.drawCircle(
            Offset(x, y), 9, Paint()..color = const Color(0xFFa855f7));
      }
    }
  }

  // CAGED Zones 계산
  List<ZoneDef> _getZones(int rootIdx, bool isMinor) {
    final openE = 4;
    int baseFret = (rootIdx - openE + 12) % 12;
    final zones = <ZoneDef>[];
    const double bgAlpha = 0.08;

    final offsets = [0, 2, 4, 7, 9];
    final names = isMinor
        ? ['Em Form', 'Dm Form', 'Cm Form', 'Am Form', 'Gm Form']
        : ['E Form', 'D Form', 'C Form', 'A Form', 'G Form'];
    final colors = [
      const Color(0xFF4ade80),
      const Color(0xFF60a5fa),
      const Color(0xFFf87171),
      const Color(0xFFfb923c),
      const Color(0xFFfacc15),
    ];

    for (int f = baseFret - 12; f <= 24; f += 12) {
      for (int i = 0; i < names.length; i++) {
        zones.add(ZoneDef(
            names[i],
            f + offsets[i],
            f + offsets[i] + 4,
            colors[i].withValues(alpha: bgAlpha),
            colors[i]));
      }
    }
    return zones;
  }

  void _drawZoneRect(Canvas canvas, ZoneDef z, double w, double h, double px,
      double py, double fg) {
    final startFret = z.min;
    final endFret = z.max;

    if (endFret < 0 || startFret > fretCount) return;

    final s = startFret.clamp(0, fretCount);
    final e = endFret.clamp(0, fretCount);

    if (s > e) return;

    double startX;
    if (s == 0) {
      startX = px - 15;
    } else {
      startX = px + (s * fg) - fg;
    }

    double endX = px + e * fg;

    if (s > 0) startX += 2;
    endX -= 2;

    final rect = Rect.fromLTRB(startX, py / 2, endX, h - py);

    canvas.drawRect(rect, Paint()..color = z.bg);

    final borderPaint = Paint()
      ..color = z.fg.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, borderPaint);

    final tp = TextPainter(
        text: TextSpan(
            text: z.name,
            style: TextStyle(
                color: z.fg,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    offset: const Offset(0, 0),
                    blurRadius: 4,
                  )
                ])),
        textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(
        canvas, Offset(startX + (endX - startX) / 2 - tp.width / 2, py / 4));
  }

  @override
  bool shouldRepaint(covariant FretboardPainter oldDelegate) {
    return oldDelegate.highlightMap != highlightMap ||
        oldDelegate.rootNote != rootNote ||
        oldDelegate.visibleIntervals != visibleIntervals ||
        oldDelegate.focusCagedForm != focusCagedForm ||
        oldDelegate.stringColor != stringColor ||
        oldDelegate.nutColor != nutColor ||
        oldDelegate.instrument != instrument;
  }
}
