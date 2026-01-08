import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/theory_utils.dart';
import '../../../models/fretboard_marker.dart';
import '../../../providers/settings_state.dart';
import '../../../models/instrument_model.dart';
import '../piano/piano_keys_widget.dart';

/// 기타 지판(Fretboard)을 시각화하는 위젯입니다.
/// 노트를 표시하고, CAGED 시스템 영역(Zone)을 배경에 그리며, 인터벌 정보를 색상으로 표현합니다.
class FretboardMapWidget extends StatelessWidget {
  /// 각 스트링(0=LowE ~ 5=HighE)별로 표시할 마커 목록
  final Map<int, List<FretboardMarker>> highlightMap;

  /// 표시할 총 프렛 수 (기본 17)
  final int fretCount;

  /// CAGED Zone 계산을 위한 기준 루트 노트 (예: "C", "G")
  /// null일 경우 Zone을 그리지 않습니다.
  final String? rootNote;

  /// 표시할 인터벌 필터 (null이면 모두 표시)
  final Set<String>? visibleIntervals;

  /// 강조할 CAGED 폼 ('C', 'A', 'G', 'E', 'D' 또는 null)
  final String? focusCagedForm;
  final bool isMinor;
  final List<VoiceLeadingLine>? voiceLeadingLines;
  final String? selectedScaleName;

  const FretboardMapWidget({
    super.key,
    required this.highlightMap,
    this.fretCount = 19,
    this.rootNote,
    this.visibleIntervals,
    this.focusCagedForm,
    this.isMinor = false,
    this.voiceLeadingLines,
    this.selectedScaleName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedInstrument =
        context.watch<SettingsState>().selectedInstrument;

    // 피아노일 경우 PianoKeysWidget 반환
    if (selectedInstrument.type == InstrumentType.piano) {
      final Set<String> highlightedNotes = {};

      // 1. 스케일 모드인 경우 (selectedScaleName 존재) 직접 계산하여 표시
      if (rootNote != null && selectedScaleName != null) {
        // "C Major"와 같은 문자열에서 "C"를 제거하여 "Major" 추출
        // 주의: rootNote가 null이 아님을 확인했으므로 안전
        String modeName = selectedScaleName!.replaceFirst(rootNote!, '').trim();

        // 만약 modeName이 비어있다면(이름이 일치하지 않는 경우 등), 원본 사용 시도 또는 예외 처리
        if (modeName.isEmpty) modeName = selectedScaleName!;

        final scaleNotes = TheoryUtils.calculateScaleNotes(rootNote!, modeName);
        highlightedNotes.addAll(scaleNotes);
      }
      // 2. 그 외(highlightMap 기반) 데이터 수집
      // (기존 highlightMap 로직 유지하여 혹시 모를 코드 데이터 표시 지원)
      else {
        highlightMap.forEach((stringIdx, markers) {
          if (selectedInstrument.tuning.length > stringIdx) {
            final openNoteName = selectedInstrument.tuning[stringIdx];
            final openNoteIdx = TheoryUtils.getNoteIndex(openNoteName);

            for (var marker in markers) {
              if (visibleIntervals != null &&
                  !visibleIntervals!.contains(marker.interval)) continue;

              final noteIdx = (openNoteIdx + marker.fret) % 12;
              final useSharp = (rootNote != null &&
                      !rootNote!.contains('b') &&
                      rootNote != 'F') ||
                  rootNote == null;

              final name = TheoryUtils.getNoteName(noteIdx, useSharp);
              highlightedNotes.add(name);
            }
          }
        });
      }

      return Container(
        height: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dividerColor.withOpacity(0.5)),
        ),
        child: PianoKeysWidget(
          rootNote: rootNote,
          highlightedNotes: highlightedNotes,
          startOctave: 1, // C1부터 시작 (Low range)
          endOctave: 7, // B7까지 표시 (High range) - 총 7옥타브
        ),
      );
    }

    return Container(
      height: 190, // Adjusted height for better proportions on all screens
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : const Color(
                0xFFF1F5F9), // Light Mode: Slate 100 for a cleaner look
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor.withOpacity(0.5), width: 1),
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          // 커스텀 페인터를 통해 캔버스에 직접 드로잉
          painter: _FretboardPainter(
            highlightMap: highlightMap,
            fretCount: fretCount,
            rootNote: rootNote,
            visibleIntervals: visibleIntervals,
            focusCagedForm: focusCagedForm,
            isMinor: isMinor,
            voiceLeadingLines: voiceLeadingLines,
            stringColor: dividerColor,
            nutColor: colorScheme.onSurfaceVariant,
            fretColor: colorScheme.onSurface.withValues(alpha: 0.2),
            inlayColor: colorScheme.onSurface.withValues(alpha: 0.1),
            labelColor: colorScheme.onSurfaceVariant,
            instrument: selectedInstrument,
          ),
        ),
      ),
    );
  }
}

class _FretboardPainter extends CustomPainter {
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

  _FretboardPainter({
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
    List<_ZoneDef> zones = [];
    if (rootNote != null) {
      zones = _getZones(TheoryUtils.getNoteIndex(rootNote!), isMinor);
    }

    // Zone 필터링 (Focus Mode)
    if (focusCagedForm != null && zones.isNotEmpty) {
      // Major/Minor 폼 이름 차이(E Form vs Em Form)를 무시하기 위해 첫 글자로 매칭
      final focusChar = focusCagedForm![0];
      final candidates =
          zones.where((z) => z.name.startsWith(focusChar)).toList();
      if (candidates.isNotEmpty) {
        _ZoneDef? bestZone;
        int maxScore = -1;
        for (final zone in candidates) {
          int score = 0;
          highlightMap.forEach((stringIdx, markers) {
            for (final marker in markers) {
              if (visibleIntervals != null &&
                  !visibleIntervals!.contains(marker.interval)) continue;
              if (marker.fret >= zone.min && marker.fret <= zone.max) score++;
            }
          });
          if (score > maxScore) {
            maxScore = score;
            bestZone = zone;
          }
        }
        if (bestZone != null)
          zones = [bestZone];
        else
          zones = [];
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
    // 활성 Zone 외의 영역을 어둡게 처리하여 집중도 향상
    if (focusCagedForm != null && zones.isNotEmpty) {
      // 전체 영역 Path
      final fullRect = Rect.fromLTWH(0, 0, w, h);
      final fullPath = Path()..addRect(fullRect);

      // 활성 Zone 영역 Path
      final zonePath = Path();
      for (final z in zones) {
        // Zone Rect 계산 로직 (drawZoneRect와 동일)
        final s = z.min.clamp(0, fretCount);
        final e = z.max.clamp(0, fretCount);
        if (s > e) continue;

        double startX =
            (s == 0) ? paddingX - 15 : paddingX + (s * fretGap) - fretGap;
        double endX = paddingX + e * fretGap;

        if (s > 0) startX += 2;
        endX -= 2;

        // Zone보다 약간 더 넓게 밝은 영역 잡기 (여유분)
        final zoneRect = Rect.fromLTRB(startX - 10, 0, endX + 10, h);

        // RRect for softer edges
        zonePath.addRRect(
            RRect.fromRectAndRadius(zoneRect, const Radius.circular(8)));
      }

      // Difference: 전체 - Zone = 어두운 영역
      final vignettePath =
          Path.combine(PathOperation.difference, fullPath, zonePath);

      final vignettePaint = Paint()
        ..color = Colors.black.withOpacity(0.55) // 다크 모드/라이트 모드 공통적으로 어두운 오버레이
        ..style = PaintingStyle.fill;

      // Blur 효과를 주어 경계를 부드럽게 (Soft Vignette)
      // CanvasKit 등 성능 고려하여 마스크 필터 사용
      vignettePaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

      canvas.drawPath(vignettePath, vignettePaint);
    }

    // 3. 보이스 리딩 라인 그리기 (Spotlight 위에 그려서 강조)
    if (voiceLeadingLines != null) {
      for (final line in voiceLeadingLines!) {
        // [Fix] 악기의 줄 수를 초과하는 라인 무시
        if (line.fromStr >= strCount || line.toStr >= strCount) continue;

        final isResolution =
            (line.type as dynamic) == VoiceLeadingType.resolution;

        final linePaint = Paint()
          ..color = isResolution
              ? const Color(0xFFfbbf24) // Gold/Amber for resolution
              : const Color(0xFFc084fc) // Bright Purple
          ..strokeWidth = isResolution ? 4.0 : 3.0 // Make it pop more
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        // Add Shadow/Glow for lines
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

        // Draw curved path
        final path = Path()..moveTo(fromX, fromY);
        final midX = (fromX + toX) / 2;
        // Directional curve: resolution curves slightly more
        final double curveHeight = isResolution ? 30 : 15;
        final midY = (fromY + toY) / 2 - (fromX == toX ? 5 : curveHeight);

        path.quadraticBezierTo(midX, midY, toX, toY);

        canvas.drawPath(path, linePaint);

        // Arrowhead or Dot at the end
        final endDotPaint = Paint()
          ..color =
              isResolution ? const Color(0xFFfbbf24) : const Color(0xFFc084fc);

        canvas.drawCircle(Offset(toX, toY), isResolution ? 5 : 4, endDotPaint);

        if (isResolution) {
          // Add a small glow to resolution lines
          canvas.drawCircle(Offset(toX, toY), 8,
              Paint()..color = const Color(0xFFfbbf24).withOpacity(0.3));
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
            !visibleIntervals!.contains(marker.interval)) continue;

        bool isTarget = false;
        if (voiceLeadingLines != null) {
          isTarget = voiceLeadingLines!.any(
              (line) => line.toFret == marker.fret && line.toStr == stringIdx);
        }

        // Spotlight가 이미 어두운 배경을 제공하므로, 'Dimming' 로직 단순화
        // Focus Mode이고 Zone 밖인 Ghost Marker는 투명도를 더 낮춤
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

          // Spotlight 오버레이 아래에 있는(Dimmed) 마커는 더 희미하게
          if (isDimmed)
            fillColor = fillColor.withOpacity(0.3); // 기존 0.15보다 약간 높임 (오버레이 감안)
        } else {
          final iv = marker.interval;
          if (iv == '1P' || iv == '1')
            fillColor = const Color(0xFFef4444);
          else if (iv.contains('3'))
            fillColor = iv.contains('M')
                ? const Color(0xFF60a5fa)
                : const Color(0xFF22d3ee);
          else if (iv.contains('5'))
            fillColor = const Color(0xFFfacc15);
          else if (iv.contains('7')) fillColor = const Color(0xFF4ade80);
        }

        canvas.drawCircle(Offset(x, y), 11,
            Paint()..color = strokeColor.withOpacity(isDimmed ? 0.2 : 1.0));

        if (isTarget) {
          // Target Ring pops over everything
          canvas.drawCircle(
              Offset(x, y),
              13,
              Paint()
                ..color = const Color(0xFFc084fc) // Bright
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.5);
        }

        canvas.drawCircle(Offset(x, y), 9, Paint()..color = fillColor);

        final tp = TextPainter(
            text: TextSpan(
                text: marker.interval,
                style: TextStyle(
                    color: const Color(0xFF1e293b)
                        .withOpacity((marker.isGhost || isDimmed) ? 0.5 : 1.0),
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
            textDirection: TextDirection.ltr)
          ..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
      }
    });

    // 5. (New) Draw missing Voice Leading Targets
    if (voiceLeadingLines != null) {
      final drawnPoints = <String>{};
      highlightMap.forEach((s, markers) {
        for (var m in markers) drawnPoints.add('${m.fret}-$s');
      });

      for (final line in voiceLeadingLines!) {
        // [Fix] 악기의 줄 수를 초과하는 데이터 무시
        if (line.toStr >= strCount || line.fromStr >= strCount) continue;

        final key = '${line.toFret}-${line.toStr}';
        if (drawnPoints.contains(key)) continue;

        final visualRow = (strCount - 1) - line.toStr;
        final y = paddingY + visualRow * stringGap;

        final x = line.toFret == 0
            ? paddingX - 10
            : paddingX + (line.toFret * fretGap) - (fretGap / 2);

        // Highlight Ring
        canvas.drawCircle(
            Offset(x, y),
            13,
            Paint()
              ..color = const Color(0xFFc084fc)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5);

        // Fill Circle
        canvas.drawCircle(
            Offset(x, y), 9, Paint()..color = const Color(0xFFa855f7));
      }
    }
  }

  // Helper: CAGED Zones 가져오기
  List<_ZoneDef> _getZones(int rootIdx, bool isMinor) {
    final openE = 4;
    int baseFret = (rootIdx - openE + 12) % 12;
    final zones = <_ZoneDef>[];

    // 투명도 설정: 배경 0.08 (8%), 강조 폼은 더 명확하게
    const double bgAlpha = 0.08;

    // CagedList와 동일한 오프셋 및 너비(4) 사용
    final offsets = isMinor
        ? [0, 2, 4, 7, 9] // Em, Dm, Cm, Am, Gm 형태
        : [0, 2, 4, 7, 9]; // E, D, C, A, G 형태
    final names = isMinor
        ? ['Em Form', 'Dm Form', 'Cm Form', 'Am Form', 'Gm Form']
        : ['E Form', 'D Form', 'C Form', 'A Form', 'G Form'];
    final colors = [
      const Color(0xFF4ade80), // Green
      const Color(0xFF60a5fa), // Blue
      const Color(0xFFf87171), // Red
      const Color(0xFFfb923c), // Orange
      const Color(0xFFfacc15), // Yellow
    ];

    for (int f = baseFret - 12; f <= 24; f += 12) {
      for (int i = 0; i < names.length; i++) {
        zones.add(_ZoneDef(
            names[i],
            f + offsets[i],
            f + offsets[i] + 4, // 너비 4프렛
            colors[i].withValues(alpha: bgAlpha),
            colors[i]));
      }
    }
    return zones;
  }

  // Helper: Zone 사각형 그리기
  void _drawZoneRect(Canvas canvas, _ZoneDef z, double w, double h, double px,
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

    // 1. 배경 채우기
    canvas.drawRect(rect, Paint()..color = z.bg);

    // 2. 테두리 추가 (시인성 확보)
    final borderPaint = Paint()
      ..color = z.fg.withValues(alpha: 0.2) // 테두리는 약간 더 진하게
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, borderPaint);

    // 3. Zone 이름 라벨
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
  bool shouldRepaint(covariant _FretboardPainter oldDelegate) {
    return oldDelegate.highlightMap != highlightMap ||
        oldDelegate.rootNote != rootNote ||
        oldDelegate.visibleIntervals != visibleIntervals ||
        oldDelegate.focusCagedForm != focusCagedForm ||
        oldDelegate.stringColor != stringColor ||
        oldDelegate.nutColor != nutColor ||
        oldDelegate.instrument != instrument;
  }
}

class _ZoneDef {
  final String name;
  final int min;
  final int max;
  final Color bg;
  final Color fg;
  _ZoneDef(this.name, this.min, this.max, this.bg, this.fg);
}
