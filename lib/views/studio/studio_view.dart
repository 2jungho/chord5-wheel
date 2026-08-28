import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/studio_state.dart';
import '../../providers/settings_state.dart';
import '../../widgets/common/fretboard/fretboard_section.dart';
import '../../widgets/common/view_control_panel.dart';
import 'widgets/studio_timeline.dart';
import 'widgets/famous_songs_panel.dart';
import 'widgets/lyria_jam_panel.dart';

import '../../utils/guitar_utils.dart';
import '../../utils/guitar/pentatonic_box_calculator.dart';
import '../../utils/theory_utils.dart';
import '../../models/fretboard_marker.dart';
import '../../models/chord_model.dart';
import '../../models/instrument_model.dart';
import '../../models/progression/progression_models.dart';

class StudioView extends StatefulWidget {
  const StudioView({super.key});

  @override
  State<StudioView> createState() => _StudioViewState();
}

class _StudioViewState extends State<StudioView> {
  // 타임라인 영역의 높이
  double _timelineHeight = 340.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const double maxTimelineHeight = 800.0;
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
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // AI Jam Session & Famous Songs Panels
              const _StudioJamAndSongSection(),

              const SizedBox(height: 16),

              // B. Fretboard Section (Bottom) - Selector 기반 최적화
              const _StudioFretboardSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    });
  }
}

/// AI Jam & 유명 곡 패널 영역
class _StudioJamAndSongSection extends StatelessWidget {
  const _StudioJamAndSongSection();

  @override
  Widget build(BuildContext context) {
    return Selector<StudioState, ProgressionSession>(
      selector: (_, s) => s.session,
      builder: (context, session, _) {
        return LayoutBuilder(
          builder: (context, panelConstraints) {
            final isCompact = panelConstraints.maxWidth < 950;

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LyriaJamPanel(),
                  const SizedBox(height: 12),
                  FamousSongsPanel(session: session),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  flex: 5,
                  child: LyriaJamPanel(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: FamousSongsPanel(session: session),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Studio 프렛보드 영역 (Selector 기반 최적화)
class _StudioFretboardSection extends StatelessWidget {
  const _StudioFretboardSection();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final tuning = settings.tuningPreset;

    return Selector<
        StudioState,
        ({
          ProgressionSession session,
          int selectedBlockIndex,
          bool showPentatonicOnBackground,
          int selectedPentatonicBox,
          Set<String> visibleIntervals,
          String? selectedCagedForm,
          List<VoiceLeadingLine> voiceLeadingLines,
        })>(
      selector: (_, s) => (
        session: s.session,
        selectedBlockIndex: s.selectedBlockIndex,
        showPentatonicOnBackground: s.showPentatonicOnBackground,
        selectedPentatonicBox: s.selectedPentatonicBox,
        visibleIntervals: s.visibleIntervals,
        selectedCagedForm: s.selectedCagedForm,
        voiceLeadingLines: s.voiceLeadingLines,
      ),
      builder: (context, data, _) {
        final session = data.session;
        final studio = context.read<StudioState>();

        // 현재 선택된 코드 블록을 기준으로 지판 표시 데이터 생성
        Map<int, List<FretboardMarker>> highlightMap = {};
        String? rootNote;
        bool isMinor = false;

        if (session.progression.isNotEmpty) {
          final safeIndex =
              data.selectedBlockIndex.clamp(0, session.progression.length - 1);
          final currentChordBlock = session.progression[safeIndex];
          final Chord chordData =
              TheoryUtils.analyzeChord(currentChordBlock.chordSymbol);
          rootNote = chordData.root;
          isMinor = chordData.quality.contains('m') &&
              !chordData.quality.contains('maj');

          if (currentChordBlock.voicing != null) {
            highlightMap = GuitarUtils.generateMapFromVoicing(
                currentChordBlock.voicing!, rootNote, tuning.notes);
          } else {
            highlightMap = GuitarUtils.generateFretboardMap(
              root: rootNote,
              notes: chordData.notes,
              tuning: tuning.notes,
            );
          }

          // Key Center 기반 펜타토닉 / 솔로 박스 노트 생성 및 병합
          if (data.showPentatonicOnBackground && session.key.isNotEmpty) {
            String keyRoot = 'C';
            bool isKeyMinor = false;
            final parts = session.key.split(' ');
            if (parts.isNotEmpty) {
              keyRoot = parts[0];
              isKeyMinor = session.key.contains('Minor');
            }

            Map<int, List<FretboardMarker>> boxMarkers;
            if (data.selectedPentatonicBox > 0) {
              boxMarkers = PentatonicBoxCalculator.generateBoxMarkers(
                keyRoot: keyRoot,
                isMinorKey: isKeyMinor,
                boxNumber: data.selectedPentatonicBox,
                currentChordRoot: rootNote,
              );
            } else {
              final scaleType =
                  isKeyMinor ? 'Minor Pentatonic' : 'Major Pentatonic';
              final pentatonicNotes =
                  TheoryUtils.calculateScaleNotes(keyRoot, scaleType);
              boxMarkers = GuitarUtils.generateFretboardMap(
                root: keyRoot,
                notes: [],
                ghostNotes: pentatonicNotes,
              );
            }

            // 기존 highlightMap에 병합
            for (int s = 0; s < 6; s++) {
              final ghostMarkers = boxMarkers[s] ?? [];
              if (ghostMarkers.isEmpty) continue;

              if (!highlightMap.containsKey(s)) {
                highlightMap[s] = ghostMarkers;
              } else {
                final existingFrets =
                    highlightMap[s]!.map((m) => m.fret).toSet();
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

        return FretboardSection(
          highlightMap: highlightMap,
          rootNote: rootNote,
          isMinor: isMinor,
          visibleIntervals: data.visibleIntervals,
          focusCagedForm: data.selectedCagedForm,
          voiceLeadingLines: data.voiceLeadingLines,
          controlPanel: ViewControlPanel(
            visibleIntervals: data.visibleIntervals,
            selectedCagedForm: data.selectedCagedForm,
            onToggleInterval: studio.toggleInterval,
            onSelectForm: studio.selectCagedForm,
            onReset: studio.resetViewFilters,
            showPentatonic: data.showPentatonicOnBackground,
            onTogglePentatonic: studio.togglePentatonicBackground,
            selectedPentatonicBox: data.selectedPentatonicBox,
            onSelectPentatonicBox: studio.selectPentatonicBox,
            tuningPreset: tuning,
            onSelectTuning: (newPreset) => settings.setTuningPreset(newPreset),
          ),
          voiceLeadingLabel: (session.progression.length > 1)
              ? (() {
                  final currentIndex = data.selectedBlockIndex
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
        );
      },
    );
  }
}
