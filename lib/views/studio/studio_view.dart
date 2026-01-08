import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/studio_state.dart';
import '../../widgets/common/fretboard/fretboard_section.dart';
import '../../widgets/common/view_control_panel.dart';
import 'widgets/studio_timeline.dart';
import 'widgets/famous_songs_panel.dart';

import '../../utils/guitar_utils.dart';
import '../../utils/theory_utils.dart';
import '../../models/fretboard_marker.dart';
import '../../models/chord_model.dart';

class StudioView extends StatefulWidget {
  const StudioView({super.key});

  @override
  State<StudioView> createState() => _StudioViewState();
}

class _StudioViewState extends State<StudioView> {
  // 타임라인 영역의 초기 높이
  double _timelineHeight = 340.0;

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<StudioState>();
    final session = studio.session;

    // 현재 선택된 코드 블록을 기준으로 지판 표시 데이터 생성
    Map<int, List<FretboardMarker>> highlightMap = {};
    String? rootNote;
    bool isMinor = false;

    if (session.progression.isNotEmpty) {
      final safeIndex =
          studio.selectedBlockIndex.clamp(0, session.progression.length - 1);
      final currentChordBlock = session.progression[safeIndex];
      final Chord chordData =
          TheoryUtils.analyzeChord(currentChordBlock.chordSymbol);
      rootNote = chordData.root;
      isMinor =
          chordData.quality.contains('m') && !chordData.quality.contains('maj');
      if (currentChordBlock.voicing != null) {
        highlightMap = GuitarUtils.generateMapFromVoicing(
            currentChordBlock.voicing!, rootNote);
      } else {
        highlightMap = GuitarUtils.generateFretboardMap(
          root: rootNote,
          notes: chordData.notes,
        );
      }

      // [New] Key Center 기반 펜타토닉 고스트 노트 생성 및 병합
      if (studio.showPentatonicOnBackground && session.key.isNotEmpty) {
        String keyRoot = 'C';
        bool isKeyMinor = false;
        final parts = session.key.split(' ');
        if (parts.isNotEmpty) {
          keyRoot = parts[0];
          isKeyMinor = session.key.contains('Minor');
        }

        final scaleType = isKeyMinor ? 'Minor Pentatonic' : 'Major Pentatonic';
        final pentatonicNotes =
            TheoryUtils.calculateScaleNotes(keyRoot, scaleType);

        // Key Root 기준의 펜타토닉 맵 생성 (오직 ghostNotes만 포함)
        final ghostMap = GuitarUtils.generateFretboardMap(
          root: keyRoot,
          notes: [],
          ghostNotes: pentatonicNotes,
        );

        // 기존 highlightMap에 병합 (코드가 있는 위치는 덮어쓰지 않음)
        for (int s = 0; s < 6; s++) {
          final ghostMarkers = ghostMap[s] ?? [];
          if (ghostMarkers.isEmpty) continue;

          if (!highlightMap.containsKey(s)) {
            highlightMap[s] = ghostMarkers;
          } else {
            final existingFrets = highlightMap[s]!.map((m) => m.fret).toSet();
            for (var gm in ghostMarkers) {
              if (!existingFrets.contains(gm.fret)) {
                highlightMap[s]!.add(gm);
              }
            }
            highlightMap[s]!.sort((a, b) => a.fret.compareTo(b.fret));
          }
        }
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
      // Allow timeline to be resized but keep it within reasonable bounds
      // Since we are scrollable, max height isn't strictly limited by screen height,
      // but we don't want it to get too crazy. 800px seems like a good safety max.
      final double maxTimelineHeight = 800.0;

      // Effective height for timeline
      final double effectiveHeight =
          _timelineHeight.clamp(200.0, maxTimelineHeight);

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A. Timeline Section (Top) - Resizable Height
              SizedBox(
                height: effectiveHeight,
                child: const StudioTimeline(),
              ),

              // Resize Handle
              MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _timelineHeight += details.delta.dy;
                      if (_timelineHeight < 200) {
                        _timelineHeight = 200;
                      }
                      if (_timelineHeight > maxTimelineHeight) {
                        _timelineHeight = maxTimelineHeight;
                      }
                    });
                  },
                  child: Container(
                    height: 16,
                    width: double.infinity,
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),

              // Famous Songs Panel (Independent Section)
              FamousSongsPanel(session: session),

              const SizedBox(height: 16),

              // B. Fretboard Section (Bottom) - Fixed Height in ScrollView
              FretboardSection(
                highlightMap: highlightMap,
                rootNote: rootNote,
                isMinor: isMinor,
                visibleIntervals: studio.visibleIntervals,
                focusCagedForm: studio.selectedCagedForm,
                voiceLeadingLines: studio.voiceLeadingLines,
                controlPanel: ViewControlPanel(
                  visibleIntervals: studio.visibleIntervals,
                  selectedCagedForm: studio.selectedCagedForm,
                  onToggleInterval: studio.toggleInterval,
                  onSelectForm: studio.selectCagedForm,
                  onReset: studio.resetViewFilters,
                  showPentatonic: studio.showPentatonicOnBackground,
                  onTogglePentatonic: studio.togglePentatonicBackground,
                ),
                voiceLeadingLabel: (session.progression.length > 1)
                    ? (() {
                        final currentIndex = studio.selectedBlockIndex
                            .clamp(0, session.progression.length - 1);
                        final nextIndex =
                            (currentIndex + 1) % session.progression.length;
                        final currentSymbol =
                            session.progression[currentIndex].chordSymbol;
                        final nextSymbol =
                            session.progression[nextIndex].chordSymbol;
                        return '예: $currentSymbol → $nextSymbol 진행 시, 현재 코드의 구성음이 다음 코드의 가장 가까운 구성음으로 어떻게 연결되는지(Voice Leading)를 시각화한 것입니다.';
                      })()
                    : null,
              ),
              const SizedBox(height: 40), // Bottom padding
            ],
          ),
        ),
      );
    });
  }
}
