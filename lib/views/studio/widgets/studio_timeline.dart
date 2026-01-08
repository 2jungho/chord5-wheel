import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/studio_state.dart';
import '../../../models/progression/progression_models.dart';
import '../../../models/music_constants.dart'; // Import MusicConstants
import '../../../providers/music_state.dart'; // Import MusicState

import '../../../utils/theory_utils.dart';
import '../../../widgets/common/guitar/guitar_chord_widget.dart';
import '../../../widgets/common/piano/piano_chord_widget.dart';
import '../../../models/instrument_model.dart';
import '../../../audio/audio_manager.dart';
import '../../../widgets/common/circle_of_fifths_selector.dart';
import 'preset_selector_dialog.dart';
import '../../../providers/settings_state.dart';
import '../dialogs/ai_arrange_dialog.dart';
import '../dialogs/ai_song_search_dialog.dart';

import 'soloing_guide_panel.dart';
import 'insight_report_widget.dart';

class StudioTimeline extends StatefulWidget {
  const StudioTimeline({super.key});

  @override
  State<StudioTimeline> createState() => _StudioTimelineState();
}

class _StudioTimelineState extends State<StudioTimeline> {
  final TextEditingController _quickAddController = TextEditingController();
  double _analysisPanelWidth =
      500.0; // Default width for Analysis Panel (Expanded)

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  void _syncKeyWithMusicState(BuildContext context, String keyString) {
    try {
      final musicState = context.read<MusicState>();
      final parts = keyString.split(' ');
      if (parts.isEmpty) return;

      final root = parts[0];
      final isMinor = parts.length > 1 && parts[1] == 'Minor';

      // Find Key Index in MusicConstants.KEYS
      // KEYS are ordered by Circle of Fifths (C, G, D...)
      // If Minor, we look for matching 'minor' name (e.g. 'Am')
      // If Major, we look for matchine 'name' (e.g. 'C')

      int keyIndex = -1;

      if (isMinor) {
        // Minor key logic
        // keyString root might be normalized e.g. "A" from "A Minor"
        // But KEYS minor field is "Am". So we append 'm' if needed or check startsWith
        // Actually StudioState uses "A Minor", so root is "A".
        // We look for minor field equal to "Am" (root + "m")
        final targetMinor = '${root}m';
        keyIndex =
            MusicConstants.KEYS.indexWhere((k) => k.minor == targetMinor);

        // Fallback: check if root directly matches minor name (unlikely given StudioState logic)
        if (keyIndex == -1) {
          keyIndex = MusicConstants.KEYS.indexWhere((k) => k.minor == root);
        }
      } else {
        // Major key logic
        keyIndex = MusicConstants.KEYS.indexWhere((k) => k.name == root);
      }

      if (keyIndex != -1) {
        // Sync MusicState
        // If isMinor -> Inner Ring (true)
        // If Major -> Outer Ring (false)
        musicState.selectKeySlice(keyIndex, isMinor);
      }
    } catch (e) {
      debugPrint('Error syncing Key to MusicState: $e');
    }
  }

  Widget build(BuildContext context) {
    final studio = context.watch<StudioState>();
    final session = studio.session;

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 900;

      if (isMobile) {
        // Mobile Layout: Tabbed Interface
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  labelColor: Theme.of(context).colorScheme.onPrimary,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: const [
                    Tab(text: "Key"),
                    Tab(text: "Timeline"),
                    Tab(text: "Analysis"),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Tab 1: Key
                    _buildKeyPanelContent(context, studio, session,
                        isMobile: true),
                    // Tab 2: Timeline
                    Column(
                      children: [
                        _buildTimelineHeader(context, studio, session,
                            isMobile: true),
                        const Divider(height: 1),
                        Expanded(
                            child:
                                _buildTimelineGrid(context, studio, session)),
                      ],
                    ),
                    // Tab 3: Analysis
                    _buildRightAnalysisPanel(context, studio, session,
                        forceFullWidth: true),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      // Desktop Layout: Side-by-Side
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Panel: Key Selector
            Container(
              width: 380,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: _buildKeyPanelContent(context, studio, session),
            ),
            // Right Panel: Timeline & Controls
            Expanded(
              child: Column(
                children: [
                  _buildTimelineHeader(context, studio, session),
                  const Divider(height: 1),
                  // Main Content: Timeline + Analysis
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Grid Tracks
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                  child: _buildTimelineGrid(
                                      context, studio, session)),
                            ],
                          ),
                        ),
                        // Resize Handle
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeColumn,
                          child: GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              setState(() {
                                double currentWidth = 500.0;
                                try {
                                  final dynamic raw = _analysisPanelWidth;
                                  if (raw != null) {
                                    currentWidth = (raw as num).toDouble();
                                  }
                                } catch (e) {
                                  currentWidth = 500.0;
                                }

                                if (currentWidth.isNaN) currentWidth = 500.0;

                                currentWidth -= details.delta.dx;

                                if (currentWidth < 250) {
                                  currentWidth = 250;
                                }
                                if (currentWidth > 800) {
                                  currentWidth = 800;
                                }
                                _analysisPanelWidth = currentWidth;
                              });
                            },
                            child: Container(
                              width: 12,
                              color: Colors.transparent,
                              child: Center(
                                child: Container(
                                  width: 4,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .dividerColor
                                        .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Right Side Analysis Panel
                        _buildRightAnalysisPanel(context, studio, session),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRightAnalysisPanel(
      BuildContext context, StudioState studio, ProgressionSession session,
      {bool forceFullWidth = false}) {
    // 안전한 너비 계산 (NaN 방어 및 Hot Reload undefined 방어)
    dynamic rawWidth = _analysisPanelWidth;
    double panelWidth;
    try {
      if (rawWidth == null) {
        panelWidth = 500.0;
      } else {
        panelWidth = (rawWidth as num).toDouble();
      }
    } catch (e) {
      panelWidth = 500.0;
    }

    if (forceFullWidth) {
      panelWidth = double.infinity;
    } else if (panelWidth.isNaN || panelWidth < 100 || panelWidth > 2000) {
      panelWidth = 500.0;
    }

    return Container(
      width: forceFullWidth ? double.infinity : panelWidth,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
              color: forceFullWidth
                  ? Colors.transparent
                  : Theme.of(context).dividerColor),
        ),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Analysis Tab Header
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: TabBar(
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurfaceVariant,
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.analytics_outlined, size: 16),
                    text: "기본 분석 (Basic)",
                    iconMargin: EdgeInsets.only(bottom: 4),
                  ),
                  Tab(
                    icon: Icon(Icons.auto_awesome, size: 16),
                    text: "AI 심층 분석 (Deep)",
                    iconMargin: EdgeInsets.only(bottom: 4),
                  ),
                ],
              ),
            ),
            // Tab Contents
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Voice Leading & Soloing (Original Split)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildVoiceLeadingAnalysis(
                              context, studio, session),
                        ),
                      ),
                      VerticalDivider(
                          width: 1,
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.5)),
                      const Expanded(
                        child: SingleChildScrollView(
                          child: SoloingGuidePanel(),
                        ),
                      ),
                    ],
                  ),
                  // Tab 2: AI Insight Report
                  InsightReportWidget(progression: session.progression),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceLeadingAnalysis(
      BuildContext context, StudioState studio, ProgressionSession session) {
    if (session.progression.isEmpty) return const SizedBox.shrink();

    final currentIndex = studio.selectedBlockIndex;
    final currentBlock =
        (currentIndex >= 0 && currentIndex < session.progression.length)
            ? session.progression[currentIndex]
            : null;

    ChordBlock? nextBlock;
    bool isLoop = false;

    if (currentBlock != null && session.progression.isNotEmpty) {
      if (currentIndex < session.progression.length - 1) {
        nextBlock = session.progression[currentIndex + 1];
      } else {
        // Loop back to the first chord
        nextBlock = session.progression.first;
        isLoop = true;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined,
                  size: 18, color: Theme.of(context).colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '보이스 리딩 분석 (Voice Leading)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (currentBlock != null && nextBlock != null) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildAnalysisChordTag(context, currentBlock.chordSymbol),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Icon(isLoop ? Icons.refresh : Icons.arrow_forward,
                            size: 16,
                            color: isLoop
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey),
                        if (isLoop)
                          Text('Loop',
                              style: TextStyle(
                                  fontSize: 9,
                                  color:
                                      Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                  ),
                  _buildAnalysisChordTag(context, nextBlock.chordSymbol),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '가이드톤 연결:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${currentBlock.chordSymbol}의 7음이 ${nextBlock.chordSymbol}의 3음으로 부드럽게 해결됩니다.',
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '반음/온음 간격의 순차 진행이 감지되었습니다.',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.8)),
                  ),
                ],
              ),
            ),
          ] else if (currentBlock != null) ...[
            Text(
              '${currentBlock.chordSymbol} 다음에 오는 코드를 선택하면\n두 코드 간의 연결성을 분석합니다.',
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.outline),
            )
          ] else ...[
            Text(
              '타임라인에서 코드를 선택하여\n보이스 리딩 분석을 확인하세요.',
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.outline),
            )
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisChordTag(BuildContext context, String chordName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        chordName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildChordBlock(
      BuildContext context, ChordBlock block, int index, StudioState studio) {
    final isSelected = studio.selectedBlockIndex == index;
    return Container(
      // GridView에서 제어하므로 고정 크기 제거

      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.2), // 선택 시 약간의 틴트
                  Theme.of(context).colorScheme.surface,
                ]
              : [
                  Theme.of(context).colorScheme.surfaceContainerHigh,
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: isSelected ? 2.0 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 0),
            ),
          const BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            studio.selectBlock(index);
            // Play sound on selection
            final notes = TheoryUtils.analyzeChord(block.chordSymbol).notes;
            AudioManager().playStrum(notes);
          },
          child: Stack(
            children: [
              // 선택 강조 테두리 (Deprecated: Container decoration에서 처리함)
              // if (studio.selectedBlockIndex == index) ...

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Bar Number Label
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Bar ${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.4),
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(block.chordSymbol,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface, // 테마 색상 적용
                                  )),
                          if (block.functionTag != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${block.functionTag!})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6), // 테마 기반 하얀색/검은색 계열로 수정
                              ),
                            ),
                          ],
                          if (block.chordDetail != null) ...[
                            const SizedBox(width: 2),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  studio.selectBlock(index);
                                  final notes = TheoryUtils.analyzeChord(
                                          block.chordSymbol)
                                      .notes;
                                  AudioManager().playStrum(notes);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Icon(
                                    Icons.volume_up_rounded,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (block.voicing != null)
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Consumer<SettingsState>(
                            builder: (context, settings, _) {
                              if (settings.selectedInstrument.type ==
                                  InstrumentType.piano) {
                                return PianoChordWidget(
                                  notes: TheoryUtils.analyzeChord(
                                          block.chordSymbol)
                                      .notes,
                                  width: 130,
                                  height: 80,
                                  showLabels: true,
                                );
                              }
                              return GuitarChordWidget(
                                voicing: block.voicing!,
                                width: 130,
                                height: 100,
                                stringCount:
                                    settings.selectedInstrument.stringCount,
                              );
                            },
                          ),
                        ),
                      )
                    else
                      const Expanded(
                        child: Center(
                          child: Icon(Icons.music_off,
                              size: 24, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  onPressed: () => studio.removeChord(index),
                  tooltip: '삭제',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCagedNode(
      BuildContext context, StudioState studio, String style) {
    // 1. Determine Node Type
    final isMainNode = !style.contains('-'); // C, A, G, E, D
    final isSelected = studio.timelineVoicingStyle == style;

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMainNode ? 2 : 1),
      child: Tooltip(
        message: isMainNode ? '$style Form' : 'Bridge: $style',
        child: InkWell(
          onTap: () => studio.setTimelineVoicingStyle(style),
          borderRadius: BorderRadius.circular(isMainNode ? 20 : 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isMainNode ? 32 : 36,
            height: isMainNode ? 32 : 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: isMainNode ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isMainNode ? null : BorderRadius.circular(6),
              color: isSelected
                  ? colorScheme.primary
                  : (isMainNode
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surfaceContainerHighest
                          .withOpacity(0.3)), // 브릿지도 배경색 부여
              border: isSelected
                  ? Border.all(color: colorScheme.primary, width: 1.5)
                  : (isMainNode
                      ? Border.all(color: colorScheme.outline.withOpacity(0.2))
                      : null),
            ),
            child: Text(
              isMainNode ? style : 'BR',
              style: TextStyle(
                fontSize: isMainNode ? 12 : 9,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : (isMainNode ? FontWeight.w600 : FontWeight.w500),
                color: isSelected
                    ? colorScheme.onPrimary
                    : (isMainNode
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressionBadge(
      BuildContext context, ProgressionSession session, StudioState studio) {
    final matchedPreset =
        TheoryUtils.matchProgressionToPreset(session.progression);

    if (matchedPreset == null) return const SizedBox.shrink();

    return Tooltip(
      message:
          '${matchedPreset.description}\nTags: ${matchedPreset.tags.join(", ")}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final newTitle = studio.regenerateSimilarProgression();
            if (newTitle != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('\'$newTitle\'(으)로 재생성되었습니다.'),
                  duration: const Duration(milliseconds: 1500),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('교체할 유사한 프리셋이 없습니다.'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .tertiaryContainer
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color:
                      Theme.of(context).colorScheme.tertiary.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    Icons
                        .refresh, // Changed icon to refresh to indicate action availability
                    size: 14,
                    color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(width: 6),
                Text(
                  matchedPreset.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                if (matchedPreset.tags.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#${matchedPreset.tags.first}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Methods for Mobile/Desktop Responsive Layout

  Widget _buildKeyPanelContent(
      BuildContext context, StudioState studio, ProgressionSession session,
      {bool isMobile = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note,
                size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Key Center',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double size = min(constraints.maxWidth, constraints.maxHeight);
                return CircleOfFifthsSelector(
                  currentKey: session.key,
                  onKeySelected: (key) {
                    studio.updateKey(key);
                    _syncKeyWithMusicState(context, key);
                  },
                  size: size,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            session.key,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  // _handleGenerateBackingTrack removed (Replaced by LyriaJamPanel)

  Widget _buildTimelineHeader(
      BuildContext context, StudioState studio, ProgressionSession session,
      {bool isMobile = false}) {
    // Shared AI Buttons Logic
    final hasApiKey = context.watch<SettingsState>().currentApiKey.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> aiButtons = hasApiKey
        ? [
            OutlinedButton.icon(
              onPressed: () {
                if (session.progression.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('편곡할 코드가 없습니다.')),
                  );
                  return;
                }
                showDialog(
                  context: context,
                  builder: (ctx) => AIArrangeDialog(
                    currentProgression: session.progression,
                    onApply: (newProgression, style) {
                      studio.setProgression(newProgression,
                          arrangementStyle: style);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('\'$style\' 스타일로 편곡이 적용되었습니다.')),
                      );
                    },
                  ),
                );
              },
              icon: Icon(Icons.auto_fix_high,
                  size: 16, color: isDark ? Colors.white : null),
              label: Text('AI 편곡',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : null,
                      fontWeight: isDark ? FontWeight.bold : null)),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : null,
                side: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5)),
                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : null,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => AISongSearchDialog(
                    onApply: (blocks, key, title) {
                      studio.setProgression(blocks,
                          key: key, title: title, clearArrangement: true);
                      _syncKeyWithMusicState(context, key);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('타임라인에 곡 진행이 적용되었습니다.')),
                      );
                    },
                  ),
                );
              },
              icon: Icon(Icons.search,
                  size: 16, color: isDark ? Colors.white : null),
              label: Text('AI 곡 검색',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : null,
                      fontWeight: isDark ? FontWeight.bold : null)),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : null,
                side: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5)),
                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : null,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ]
        : [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.view_timeline,
                        size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('코드진행',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    const Spacer(),
                    _buildProgressionBadge(context, session, studio),
                  ],
                ),
                if ((session.title.isNotEmpty &&
                        session.title != 'Untitled Progression') ||
                    session.arrangementStyle != null) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (session.title.isNotEmpty &&
                            session.title != 'Untitled Progression')
                          _buildSessionInfoBadge(
                            context,
                            Icons.music_note,
                            session.title,
                            Theme.of(context).colorScheme.secondaryContainer,
                          ),
                        if (session.arrangementStyle != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios,
                              size: 10, color: Colors.grey),
                          const SizedBox(width: 8),
                          _buildSessionInfoBadge(
                            context,
                            Icons.auto_fix_high,
                            session.arrangementStyle!,
                            Theme.of(context).colorScheme.tertiaryContainer,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (aiButtons.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: aiButtons,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(child: _buildQuickAddInput(context, studio)),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            )
          : Row(
              children: [
                Icon(Icons.view_timeline,
                    size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('코드진행',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                const SizedBox(width: 12),
                // Title & Style Badge Display
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (session.title.isNotEmpty &&
                            session.title != 'Untitled Progression') ...[
                          _buildSessionInfoBadge(
                            context,
                            Icons.music_note,
                            session.title,
                            Theme.of(context).colorScheme.secondaryContainer,
                          ),
                        ],
                        if (session.arrangementStyle != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios,
                              size: 10, color: Colors.grey),
                          const SizedBox(width: 8),
                          _buildSessionInfoBadge(
                            context,
                            Icons.auto_fix_high,
                            session.arrangementStyle!,
                            Theme.of(context).colorScheme.tertiaryContainer,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // --- AI Action Buttons ---
                ...aiButtons,
                if (hasApiKey) const SizedBox(width: 12),
                // Quick Add Input (Expanded to occupy optimal space)
                Expanded(
                  flex: 2,
                  child: _buildQuickAddInput(context, studio),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickAddInput(BuildContext context, StudioState studio) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.bolt, size: 20, color: Colors.amber),
              tooltip: '코드 진행 프리셋 탐색기',
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  builder: (context) => PresetSelectorDialog(
                    onSelected: (progression) {
                      _quickAddController.text = progression;
                      setState(() {});
                    },
                    onApply: (progression, title) {
                      studio.addProgressionFromText(progression,
                          replace: true, title: title);
                      _quickAddController.clear();
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _quickAddController,
              onChanged: (val) => setState(() {}),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  studio.addProgressionFromText(value);
                  Future.delayed(const Duration(milliseconds: 50), () {
                    if (mounted) {
                      _quickAddController.clear();
                      setState(() {});
                    }
                  });
                }
              },
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Quick Add (영문/숫자 입력 e.g. C-Am-Dm-G7)',
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (RegExp(r'[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]').hasMatch(_quickAddController.text))
            Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(children: [
                  Icon(Icons.g_translate_rounded,
                      color: Theme.of(context).colorScheme.error, size: 12),
                  const SizedBox(width: 4),
                  Text('한/영 키를 눌러 영문으로 변경하세요',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ])),
          if (_quickAddController.text.trim().isNotEmpty) ...[
            const SizedBox(width: 8),
            Tooltip(
                message: '기존 진행 삭제 후 신규 생성',
                child: InkWell(
                    onTap: () {
                      studio.addProgressionFromText(_quickAddController.text,
                          replace: true);
                      _quickAddController.clear();
                      setState(() {});
                    },
                    child: Text('신규',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary)))),
            const SizedBox(width: 8),
            Tooltip(
                message: '기존 진행 뒤에 추가',
                child: InkWell(
                    onTap: () {
                      studio.addProgressionFromText(_quickAddController.text,
                          replace: false);
                      _quickAddController.clear();
                      setState(() {});
                    },
                    child: Text('추가',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary)))),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineGrid(
      BuildContext context, StudioState studio, ProgressionSession session) {
    return Column(
      children: [
        // CAGED Voicing Selector Toolbar
        Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showLabel = constraints.maxWidth > 300;
              // Ensure we have enough space for the icon and gap (16 + 8 = 24), preventing overflow on very narrow width (e.g. 16px)
              final showIcon = constraints.maxWidth > 40;

              return Row(
                children: [
                  if (showIcon) ...[
                    Icon(Icons.grid_on,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    if (showLabel) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Voicing Shape (CAGED)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    SizedBox(width: showLabel ? 16 : 8),
                  ],
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, innerConstraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minWidth: innerConstraints.maxWidth),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (final style in [
                                  'C',
                                  'C-A',
                                  'A',
                                  'A-G',
                                  'G',
                                  'G-E',
                                  'E',
                                  'E-D',
                                  'D',
                                  'D-C'
                                ])
                                  _buildCagedNode(context, studio, style),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  // Safety check for layout transitions or minimized states
                  if (constraints.maxWidth < 60) return const SizedBox.shrink();

                  // Responsive Grid Calculation
                  int crossAxisCount = (constraints.maxWidth / 160).floor();
                  double sidePadding = 24.0;
                  double spacing = 16.0;

                  // Adaptive settings for narrow screens
                  if (constraints.maxWidth < 360) {
                    crossAxisCount = 2;
                    sidePadding = 8.0;
                    spacing = 8.0;
                  }

                  // Force single column for extremely narrow widths
                  if (constraints.maxWidth < 220) {
                    crossAxisCount = 1;
                    sidePadding = 4.0;
                    spacing = 4.0;
                  } else if (crossAxisCount < 2) {
                    crossAxisCount = 2; // Default minimum preference
                  }

                  if (crossAxisCount > 4) crossAxisCount = 4;

                  return GridView.builder(
                    padding:
                        EdgeInsets.fromLTRB(sidePadding, 24, sidePadding, 48),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: session.progression.length,
                    itemBuilder: (context, index) {
                      final block = session.progression[index];
                      return _buildChordBlock(context, block, index, studio);
                    },
                  );
                },
              ),
              _buildMoreBarsBadge(context, session),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoreBarsBadge(BuildContext context, ProgressionSession session) {
    if (session.progression.length <= 4) return const SizedBox.shrink();
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondaryContainer
                  .withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.keyboard_double_arrow_down,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSecondaryContainer),
              const SizedBox(width: 6),
              Text('${session.progression.length - 4} More Bars Below',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInfoBadge(
      BuildContext context, IconData icon, String text, Color bgColor) {
    // Override color to match the requested Purple/White style (PrimaryContainer)
    // regardless of the passed bgColor to Ensure consistency.
    final containerColor = Theme.of(context).colorScheme.primaryContainer;
    final onContainerColor = Theme.of(context).colorScheme.onPrimaryContainer;

    return Container(
      // Reduced padding to prevent clipping and ensure compact layout
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: containerColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: onContainerColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11, // Reduced from 14 to fit more content
              fontWeight: FontWeight.bold,
              color: onContainerColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
} // End of Class
