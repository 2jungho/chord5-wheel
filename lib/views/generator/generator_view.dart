import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/generator_state.dart';
import '../../providers/settings_state.dart';
import '../../models/chord_model.dart';
import '../../models/fretboard_marker.dart';
import '../../widgets/common/app_card_container.dart';
import '../../widgets/common/fretboard/fretboard_section.dart';
import '../../widgets/common/chord_info_section.dart';
import '../../widgets/common/view_control_panel.dart';
import 'widgets/chord_voicing_section.dart';
import 'widgets/extended_analysis_section.dart';
import 'widgets/related_scales_section.dart';
import 'widgets/scale_visualization_section.dart';

class GeneratorView extends StatelessWidget {
  const GeneratorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<GeneratorState, bool>(
      selector: (_, state) => state.hasAnalysisResult,
      builder: (context, hasResult, _) {
        return LayoutBuilder(builder: (context, constraints) {
          final bool isNarrow = constraints.maxWidth < 900;
          final bool isShort = constraints.maxHeight < 700;

          if (!hasResult) {
            return SingleChildScrollView(
              child: SizedBox(
                height: constraints.maxHeight > 200
                    ? constraints.maxHeight - 100
                    : 500,
                child: _buildEmptyState(context),
              ),
            );
          }

          if (isNarrow || isShort) {
            // --- Mobile/Short Layout (Single Scroll) ---
            return SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCardContainer(
                    padding: const EdgeInsets.all(12),
                    child: const _GeneratorMobileDashboard(),
                  ),
                  const SizedBox(height: 16),
                  const _GeneratorFretboardSection(),
                  const SizedBox(height: 40),
                ],
              ),
            );
          }

          // --- Desktop Layout (Unified Scroll) ---
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCardContainer(
                    padding: const EdgeInsets.all(12),
                    child: LayoutBuilder(
                      builder: (context, dashboardConstraints) {
                        final isDashboardWide =
                            dashboardConstraints.maxWidth > 1100;
                        if (isDashboardWide) {
                          return const _GeneratorDesktopDashboard();
                        } else {
                          return const _GeneratorMobileDashboardBody();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _GeneratorFretboardSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  static Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_note,
            size: 80,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            '상단 검색창에 코드를 입력하세요\n(예: Cmaj7, Dm9, F#m7b5)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/// 모바일/작은 화면용 대시보드
class _GeneratorMobileDashboard extends StatelessWidget {
  const _GeneratorMobileDashboard();

  @override
  Widget build(BuildContext context) {
    final instrument = context.watch<SettingsState>().selectedInstrument;

    return Selector<
        GeneratorState,
        ({
          String root,
          String quality,
          String intervals,
          List<String> notes,
          ChordVoicing? voicing,
          bool canRestore,
        })>(
      selector: (_, s) => (
        root: s.analyzedRoot,
        quality: s.analyzedQuality,
        intervals: s.analyzedIntervals,
        notes: s.chordNotes,
        voicing: s.generatedVoicings.isNotEmpty
            ? s.generatedVoicings[s.selectedVoicingIndex ?? 0]
            : null,
        canRestore: s.canRestore,
      ),
      builder: (context, data, _) {
        final state = context.read<GeneratorState>();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChordInfoSection(
              root: data.root,
              quality: data.quality,
              intervals: data.intervals,
              notes: data.notes,
              onPlay: () {
                if (data.voicing != null &&
                    data.voicing!.frets.any((f) => f != -1)) {
                  state.playVoicing(data.voicing!);
                } else {
                  state.playChordStrum();
                }
              },
              onRestore: data.canRestore ? state.restoreInitialChord : null,
              voicing: data.voicing,
              instrument: instrument,
            ),
            const SizedBox(height: 24),
            const _GeneratorMobileDashboardBody(),
          ],
        );
      },
    );
  }
}

/// 데스크톱용 3분할 대시보드
class _GeneratorDesktopDashboard extends StatelessWidget {
  const _GeneratorDesktopDashboard();

  @override
  Widget build(BuildContext context) {
    final instrument = context.watch<SettingsState>().selectedInstrument;

    return Selector<
        GeneratorState,
        ({
          String root,
          String quality,
          String intervals,
          List<String> notes,
          ChordVoicing? voicing,
          bool canRestore,
          String? selectedScaleName,
        })>(
      selector: (_, s) => (
        root: s.analyzedRoot,
        quality: s.analyzedQuality,
        intervals: s.analyzedIntervals,
        notes: s.chordNotes,
        voicing: s.generatedVoicings.isNotEmpty
            ? s.generatedVoicings[s.selectedVoicingIndex ?? 0]
            : null,
        canRestore: s.canRestore,
        selectedScaleName: s.selectedScaleName,
      ),
      builder: (context, data, _) {
        final state = context.read<GeneratorState>();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Info Section (Left)
            Expanded(
              flex: 2,
              child: ChordInfoSection(
                root: data.root,
                quality: data.quality,
                intervals: data.intervals,
                notes: data.notes,
                onPlay: () {
                  if (data.voicing != null &&
                      data.voicing!.frets.any((f) => f != -1)) {
                    state.playVoicing(data.voicing!);
                  } else {
                    state.playChordStrum();
                  }
                },
                onRestore: data.canRestore ? state.restoreInitialChord : null,
                voicing: data.voicing,
                instrument: instrument,
              ),
            ),
            const SizedBox(width: 32),
            // 2. Middle Section
            const Expanded(
              flex: 6,
              child: _GeneratorMobileDashboardBody(),
            ),
            const SizedBox(width: 32),
            // 3. Right Section
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${data.root}${data.quality} 코드입니다. 다양한 보이싱으로 연주해보세요.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ExtendedAnalysisSection(
                    root: data.root,
                    quality: data.quality,
                    selectedScaleName: data.selectedScaleName,
                    onChordSelected: (val) =>
                        state.analyzeChord(val, isNavigation: true),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 대시보드 공통 바디 (Voicing + Scales + Visualization)
class _GeneratorMobileDashboardBody extends StatelessWidget {
  const _GeneratorMobileDashboardBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<GeneratorState>(
      builder: (context, generatorState, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChordVoicingSection(
              root: generatorState.analyzedRoot,
              quality: generatorState.analyzedQuality,
              notes: generatorState.chordNotes,
              voicings: generatorState.generatedVoicings,
              onPlayVoicing: generatorState.playVoicing,
              selectedStyle: generatorState.selectedVoicingStyle,
              onStyleSelected: generatorState.setVoicingStyle,
              selectedVoicingIndex: generatorState.selectedVoicingIndex,
              onVoicingSelected: generatorState.selectVoicing,
            ),
            const SizedBox(height: 8),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 8),
            RelatedScalesSection(
              root: generatorState.analyzedRoot,
              displayQuality: generatorState.analyzedQuality,
              relatedScales: generatorState.relatedScales,
              selectedScaleName: generatorState.selectedScaleName,
              onScaleSelected: (scaleName) =>
                  generatorState.selectScale(scaleName),
              onChordTonesSelected: generatorState.selectChordTones,
              showHeader: false,
              hasContainer: false,
            ),
            const SizedBox(height: 16),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 12),
            ScaleVisualizationSection(
              root: generatorState.analyzedRoot,
              selectedScaleName: generatorState.selectedScaleName,
              baseScaleName: generatorState.relatedScales.isNotEmpty
                  ? generatorState.relatedScales.first
                  : null,
              isMinor: generatorState.isMinor,
              chordNotes: generatorState.chordNotes,
              chordIntervals: generatorState.chordIntervalList,
              onPlayScale: generatorState.playSelectedScale,
              onPlayChord: generatorState.playChordStrum,
              hasContainer: false,
            ),
            const SizedBox(height: 16),
            if (MediaQuery.of(context).size.width <= 1100)
              ExtendedAnalysisSection(
                root: generatorState.analyzedRoot,
                quality: generatorState.analyzedQuality,
                selectedScaleName: generatorState.selectedScaleName,
                onChordSelected: (val) =>
                    generatorState.analyzeChord(val, isNavigation: true),
              ),
          ],
        );
      },
    );
  }
}

/// 프렛보드 영역 (Selector로 최적화)
class _GeneratorFretboardSection extends StatelessWidget {
  const _GeneratorFretboardSection();

  @override
  Widget build(BuildContext context) {
    return Selector<
        GeneratorState,
        ({
          Map<int, List<FretboardMarker>> fretboardHighlights,
          String analyzedRoot,
          String? selectedScaleName,
          String? basePentatonicName,
          Set<String> visibleIntervals,
          String? selectedCagedForm,
          bool isMinor,
          Set<String> availableIntervals,
        })>(
      selector: (_, s) => (
        fretboardHighlights: s.fretboardHighlights,
        analyzedRoot: s.analyzedRoot,
        selectedScaleName: s.selectedScaleName,
        basePentatonicName: s.basePentatonicName,
        visibleIntervals: s.visibleIntervals,
        selectedCagedForm: s.selectedCagedForm,
        isMinor: s.isMinor,
        availableIntervals: s.availableIntervals,
      ),
      builder: (context, data, _) {
        final state = context.read<GeneratorState>();
        return FretboardSection(
          highlightMap: data.fretboardHighlights,
          rootNote: data.analyzedRoot,
          selectedScaleName: data.selectedScaleName,
          pentatonicName: data.basePentatonicName,
          visibleIntervals: data.visibleIntervals,
          focusCagedForm: data.selectedCagedForm,
          isMinor: data.isMinor,
          controlPanel: ViewControlPanel(
            visibleIntervals: data.visibleIntervals,
            availableIntervals: data.availableIntervals,
            selectedCagedForm: data.selectedCagedForm,
            onToggleInterval: state.toggleInterval,
            onSelectForm: state.selectCagedForm,
            onReset: state.resetViewFilters,
          ),
        );
      },
    );
  }
}
