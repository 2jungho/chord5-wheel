import 'package:flutter/material.dart';

import 'fretboard_map_widget.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_state.dart';
import '../../../models/instrument_model.dart';
import '../../../models/fretboard_marker.dart';

class FretboardSection extends StatefulWidget {
  final Map<int, List<FretboardMarker>> highlightMap;
  final String? rootNote;
  final String? selectedScaleName;
  final String? pentatonicName;
  final Set<String>? visibleIntervals;
  final String? focusCagedForm;
  final bool isMinor;
  final Widget? controlPanel;
  final List<VoiceLeadingLine>? voiceLeadingLines;
  final bool showPentatonic;
  final VoidCallback? onTogglePentatonic;
  final String? voiceLeadingLabel;

  const FretboardSection({
    super.key,
    required this.highlightMap,
    this.rootNote,
    this.selectedScaleName,
    this.pentatonicName,
    this.visibleIntervals,
    this.focusCagedForm,
    this.isMinor = false,
    this.controlPanel,
    this.voiceLeadingLines,
    this.showPentatonic = true,
    this.onTogglePentatonic,
    this.voiceLeadingLabel,
  });

  @override
  State<FretboardSection> createState() => _FretboardSectionState();
}

class _FretboardSectionState extends State<FretboardSection> {
  final ScrollController _scrollController = ScrollController();
  bool _showVoiceGuide = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveArea());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FretboardSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightMap != widget.highlightMap ||
        oldWidget.focusCagedForm != widget.focusCagedForm ||
        oldWidget.isMinor != widget.isMinor ||
        oldWidget.selectedScaleName != widget.selectedScaleName ||
        oldWidget.visibleIntervals != widget.visibleIntervals ||
        oldWidget.voiceLeadingLines != widget.voiceLeadingLines) {
      _scrollToActiveArea();
    }
  }

  // 레이아웃 정보를 저장하기 위한 변수
  double _lastContentWidth = 850.0;
  double _lastViewportWidth = 0.0;

  void _scrollToActiveArea() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (_lastViewportWidth >= _lastContentWidth && _lastContentWidth > 0) {
        return;
      }

      int minFret = 999;
      int maxFret = -999;
      bool targetFound = false;

      // 1. Focus Mode일 경우 Zone 기준으로 스크롤
      if (widget.focusCagedForm != null && widget.rootNote != null) {
        final rootIdx = _getNoteIndex(widget.rootNote!);
        final zones = _calculateZones(rootIdx, widget.focusCagedForm!);

        // 화면(0~17프렛)에 가장 적절하게 들어오는 Zone 선택
        // 우선순위: 0~12프렛 사이에 시작하는 Zone
        for (final z in zones) {
          if (z.max > 0 && z.min <= 17) {
            minFret = z.min < 0 ? 0 : z.min; // 0프렛 미만은 0으로 보정
            maxFret = z.max > 17 ? 17 : z.max; // 17프렛 초과는 17로 보정 (화면 밖)

            // 만약 Zone이 완전히 17프렛을 넘어가면 스크롤이 끝까지 가야 함
            if (z.min > 17) {
              minFret = z.min;
              maxFret = z.max;
            }

            targetFound = true;
            break; // 첫 번째 적합한 Zone을 찾으면 종료 (낮은 프렛 우선)
          }
        }
      }

      // 2. Focus Mode가 아니거나 적합한 Zone이 없으면 활성 마커 기준
      if (!targetFound) {
        widget.highlightMap.forEach((stringIdx, markers) {
          for (var marker in markers) {
            if (widget.visibleIntervals != null &&
                !widget.visibleIntervals!.contains(marker.interval)) {
              continue;
            }
            if (marker.fret <= 17) {
              if (marker.fret < minFret) minFret = marker.fret;
              if (marker.fret > maxFret) maxFret = marker.fret;
              targetFound = true;
            }
          }
        });
      }

      if (!targetFound || minFret > maxFret) return;

      // 3. 픽셀 좌표 변환 및 스크롤
      const double paddingX = 30.0;
      const int fretCount = 17;
      final double fretGap = (_lastContentWidth - 2 * paddingX) / fretCount;

      double getFretX(int f) {
        if (f == 0) return paddingX - 10;
        return paddingX + (f * fretGap) - (fretGap / 2);
      }

      final double startX = getFretX(minFret);
      final double endX = getFretX(maxFret);

      final double targetMin = startX - 30.0;
      final double targetMax = endX + 30.0;
      final double activeWidth = targetMax - targetMin;

      double targetScroll;
      if (activeWidth > _lastViewportWidth) {
        targetScroll = targetMin - 10.0;
      } else {
        final double targetCenter = (targetMin + targetMax) / 2;
        final double screenCenter = _lastViewportWidth / 2;
        targetScroll = targetCenter - screenCenter;
      }

      _scrollController.animateTo(
        targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  // --- Helper Methods for Zone Calculation (Simplified) ---
  int _getNoteIndex(String note) {
    // TheoryUtils 의존성 없이 간단 구현 혹은 TheoryUtils 사용 가능하나
    // 여기서는 문자열 처리로 간단히 매핑

    String n = note.replaceAll('m', '');
    // Flat 처리 등은 복잡하므로 단순 매핑 시도, 실패시 0
    // 실제로는 TheoryUtils.getNoteIndex 권장
    // 여기서는 간단히 하드코딩된 Map 사용
    final map = {
      'C': 0,
      'C#': 1,
      'Db': 1,
      'D': 2,
      'D#': 3,
      'Eb': 3,
      'E': 4,
      'F': 5,
      'F#': 6,
      'Gb': 6,
      'G': 7,
      'G#': 8,
      'Ab': 8,
      'A': 9,
      'A#': 10,
      'Bb': 10,
      'B': 11
    };
    return map[n] ?? 0;
  }

  List<({int min, int max})> _calculateZones(int rootIdx, String formName) {
    final openE = 4;
    int baseFret = (rootIdx - openE + 12) % 12;
    final zones = <({int min, int max})>[];

    // CagedList와 동일한 오프셋 및 너비(4) 사용
    final offsets = widget.isMinor
        ? [0, 2, 4, 7, 9] // Em, Dm, Cm, Am, Gm
        : [0, 2, 4, 7, 9]; // E, D, C, A, G
    final names = widget.isMinor
        ? ['Em Form', 'Dm Form', 'Cm Form', 'Am Form', 'Gm Form']
        : ['E Form', 'D Form', 'C Form', 'A Form', 'G Form'];

    // -12 ~ 24 범위 스캔
    for (int f = baseFret - 12; f <= 24; f += 12) {
      for (int i = 0; i < names.length; i++) {
        if (formName.startsWith(names[i].substring(0, 1))) {
          zones.add((min: f + offsets[i], max: f + offsets[i] + 4));
        }
      }
    }
    return zones;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Smart Legend Chips
    final List<Widget> legendChips = [
      _buildLegendChip(context, 'Voice Path', const Color(0xFFc084fc)),
      const SizedBox(width: 8),
      _buildLegendChip(context, 'Guide Tone', const Color(0xFFfbbf24)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header Row ---
          LayoutBuilder(builder: (context, headerConstraints) {
            final isNarrow = headerConstraints.maxWidth < 600;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.music_note,
                        size: 20,
                        color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: 8),
                    // Title
                    Expanded(
                      child: Text(
                          widget.selectedScaleName != null
                              ? 'Fretboard Map : ${widget.selectedScaleName}'
                              : 'Fretboard Map',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: isNarrow ? 14 : 18,
                              fontWeight: FontWeight.bold)),
                    ),
                    if (!isNarrow) ...[
                      const SizedBox(width: 12),
                      _buildHeaderChips(context, legendChips),
                    ],
                  ],
                ),
                if (isNarrow) ...[
                  const SizedBox(height: 8),
                  _buildHeaderChips(context, legendChips),
                ],
              ],
            );
          }),

          if (widget.pentatonicName != null)
            Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 8),
              child: Text(
                'Base: ${widget.pentatonicName}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // const SizedBox(height: 8),

          // --- Main Content (Stack for Overlay) ---
          // --- Main Content (Stack for Overlay) ---
          if (widget.controlPanel != null)
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isNarrow = constraints.maxWidth < 900;
                if (isNarrow) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMapWithOverlay(constraints),
                      const SizedBox(height: 8),
                      widget.controlPanel!,
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildMapWithOverlay(constraints),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(width: 460, child: widget.controlPanel!),
                    ],
                  );
                }
              },
            )
          else
            // controlPanel이 없으면 (StudioView) Full Width + Overlay 모드
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _buildMapWithOverlay(constraints);
                },
              ),
            ),
        ],
      ),
    );
  }

  // State for guide visibility

  Widget _buildHeaderChips(BuildContext context, List<Widget> legendChips) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Pentatonic Toggle
        if (widget.onTogglePentatonic != null)
          ActionChip(
            avatar: Icon(
              widget.showPentatonic ? Icons.visibility : Icons.visibility_off,
              size: 14,
              color: widget.showPentatonic
                  ? Theme.of(context).colorScheme.onSecondary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            label: Text('Key Scale',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: widget.showPentatonic
                      ? Theme.of(context).colorScheme.onSecondary
                      : Theme.of(context).colorScheme.onSurface,
                )),
            backgroundColor: widget.showPentatonic
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            onPressed: widget.onTogglePentatonic,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
          ),

        // Instrument Info
        Consumer<SettingsState>(
          builder: (context, settings, _) {
            final instrument = settings.selectedInstrument;
            if (instrument.type == InstrumentType.piano) {
              return _buildCompactChip(context, '88 Keys');
            }
            final tuning = instrument.tuning.reversed
                .map((s) => s.replaceAll(RegExp(r'[0-9]'), ''))
                .join('');
            return _buildCompactChip(context, '$tuning • 0-17 Fr');
          },
        ),

        // Smart Legends
        if (widget.voiceLeadingLines != null &&
            widget.voiceLeadingLines!.isNotEmpty) ...[
          ...legendChips,
          IconButton(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: Icon(
              _showVoiceGuide ? Icons.info : Icons.info_outline,
              size: 18,
              color: _showVoiceGuide
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Voice Guide 설명 보기',
            onPressed: () {
              setState(() {
                _showVoiceGuide = !_showVoiceGuide;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCompactChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLegendChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceGuidePanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_graph,
                      size: 16, color: colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text(
                    'Voice Guide',
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _showVoiceGuide = false),
                child: Icon(Icons.close,
                    size: 16, color: colorScheme.onSurfaceVariant),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.voiceLeadingLabel ?? 'Voice Leading 정보가 없습니다.',
            style: TextStyle(
                color: colorScheme.onSurfaceVariant, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildMapWithOverlay(BoxConstraints constraints) {
    return Stack(
      children: [
        _buildResponsiveFretboardMap(constraints),
        if (_showVoiceGuide)
          Positioned(
            top: 8,
            right: 8,
            width: 320,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: _buildVoiceGuidePanel(context),
            ),
          ),
      ],
    );
  }

  Widget _buildResponsiveFretboardMap(BoxConstraints constraints) {
    final settings = Provider.of<SettingsState>(context, listen: false);
    final isPiano = settings.selectedInstrument.type == InstrumentType.piano;

    final double minContentWidth = isPiano ? 300.0 : 600.0;
    final double viewportWidth = constraints.maxWidth;
    final double effectiveViewportWidth =
        viewportWidth.isFinite ? viewportWidth : minContentWidth;

    final double baseWidth = effectiveViewportWidth < minContentWidth
        ? minContentWidth
        : effectiveViewportWidth;

    // Mobile: Force wide scrollable area for readability
    // Tablet (600-1100px): Use full width to fill the screen
    // Desktop (>1100px): Use 0.72 factor to compress spacing as requested
    double contentWidth;
    if (constraints.maxWidth < 600) {
      contentWidth = 850.0;
    } else if (constraints.maxWidth < 1100) {
      contentWidth = baseWidth;
    } else {
      contentWidth = baseWidth * 0.72;
    }

    if ((baseWidth - _lastViewportWidth).abs() > 1.0) {
      _lastContentWidth = contentWidth;
      _lastViewportWidth = baseWidth;
      _scrollToActiveArea();
    } else {
      _lastContentWidth = contentWidth;
      _lastViewportWidth = baseWidth;
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 4),
        child: SizedBox(
          width: contentWidth,
          child: FretboardMapWidget(
            fretCount: 17,
            highlightMap: widget.highlightMap,
            rootNote: widget.rootNote,
            visibleIntervals: widget.visibleIntervals,
            focusCagedForm: widget.focusCagedForm,
            isMinor: widget.isMinor,
            voiceLeadingLines: widget.voiceLeadingLines,
            selectedScaleName: widget.selectedScaleName,
          ),
        ),
      ),
    );
  }
}
