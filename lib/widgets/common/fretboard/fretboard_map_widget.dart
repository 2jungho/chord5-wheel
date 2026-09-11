import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/theory_utils.dart';
import '../../../models/fretboard_marker.dart';
import '../../../providers/settings_state.dart';
import '../../../models/instrument_model.dart';
import '../piano/piano_keys_widget.dart';
import 'fretboard_painter.dart';

export 'fretboard_painter.dart';

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
        String modeName = selectedScaleName!.replaceFirst(rootNote!, '').trim();
        if (modeName.isEmpty) modeName = selectedScaleName!;

        final scaleNotes = TheoryUtils.calculateScaleNotes(rootNote!, modeName);
        highlightedNotes.addAll(scaleNotes);
      }
      // 2. 그 외(highlightMap 기반) 데이터 수집
      else {
        highlightMap.forEach((stringIdx, markers) {
          if (selectedInstrument.tuning.length > stringIdx) {
            final openNoteName = selectedInstrument.tuning[stringIdx];
            final openNoteIdx = TheoryUtils.getNoteIndex(openNoteName);

            for (var marker in markers) {
              if (visibleIntervals != null &&
                  !visibleIntervals!.contains(marker.interval)) {
                continue;
              }

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
          border: Border.all(color: dividerColor.withValues(alpha: 0.5)),
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
            : const Color(0xFFF1F5F9), // Light Mode: Slate 100
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor.withValues(alpha: 0.5), width: 1),
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: FretboardPainter(
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
