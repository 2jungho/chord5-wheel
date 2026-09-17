import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/generator_state.dart';
import '../../providers/settings_state.dart';
import '../../models/chord_model.dart';
import '../../models/instrument_model.dart';
import '../../models/fretboard_marker.dart';
import '../../widgets/common/app_card_container.dart';
import '../../widgets/common/fretboard/fretboard_section.dart';
import '../../widgets/common/chord_info_section.dart';
import '../../widgets/common/view_control_panel.dart';
import 'widgets/chord_voicing_section.dart';
import 'widgets/extended_analysis_section.dart';
import 'widgets/related_scales_section.dart';
import 'widgets/scale_visualization_section.dart';
import '../../widgets/lick/chord_lick_recommendation_card.dart';

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

          // --- Desktop Layout (Unified Scroll - Scheme 1) ---
          return const SingleChildScrollView(
            padding: EdgeInsets.all(12.0),
            child: _GeneratorDesktopDashboard(),
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ChordResultCard(
              root: data.root,
              quality: data.quality,
              intervals: data.intervals,
              notes: data.notes,
              voicing: data.voicing,
              canRestore: data.canRestore,
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

/// 코드 분석 상단 결과 카드 (모바일/데스크톱 공통 컴포넌트)
class _ChordResultCard extends StatelessWidget {
  final String root;
  final String quality;
  final String intervals;
  final List<String> notes;
  final ChordVoicing? voicing;
  final bool canRestore;
  final Instrument instrument;

  const _ChordResultCard({
    required this.root,
    required this.quality,
    required this.intervals,
    required this.notes,
    required this.voicing,
    required this.canRestore,
    required this.instrument,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<GeneratorState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ChordInfoSection(
          root: root,
          quality: quality,
          intervals: intervals,
          notes: notes,
          onPlay: () {
            if (voicing != null && voicing!.frets.any((f) => f != -1)) {
              state.playVoicing(voicing!);
            } else {
              state.playChordStrum();
            }
          },
          onRestore: canRestore ? state.restoreInitialChord : null,
          voicing: voicing,
          instrument: instrument,
        ),
        ChordLickRecommendationCard(
          chordRoot: root,
          chordQuality: quality,
        ),
      ],
    );
  }
}

/// 데스크톱용 통일 대시보드 (안 1: 마스터 독 + 워크스페이스 + 보이싱/릭 + 지판)
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
          List<ChordVoicing> voicings,
          String selectedStyle,
          int? selectedVoicingIndex,
          List<String> relatedScales,
          bool isMinor,
          List<String> chordIntervalList,
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
        voicings: s.generatedVoicings,
        selectedStyle: s.selectedVoicingStyle,
        selectedVoicingIndex: s.selectedVoicingIndex,
        relatedScales: s.relatedScales,
        isMinor: s.isMinor,
        chordIntervalList: s.chordIntervalList,
      ),
      builder: (context, data, _) {
        final state = context.read<GeneratorState>();
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tier 1: 상단 코드 마스터 독 (좌) + 화성학 분석 워크스페이스 (우)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 좌측 마스터 독: 코드 심볼 & 기본 핑거링 다이어그램 (고정 폭 380px)
                Container(
                  width: 380,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
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
                    onRestore:
                        data.canRestore ? state.restoreInitialChord : null,
                    voicing: data.voicing,
                    instrument: instrument,
                  ),
                ),
                const SizedBox(width: 14),

                // 우측 메인 워크스페이스: 연관 스케일 & 스케일 구성음 + 심층 화성 분석
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. 연관 스케일 & 스케일 구성음 시각화 카드
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RelatedScalesSection(
                              root: data.root,
                              displayQuality: data.quality,
                              relatedScales: data.relatedScales,
                              selectedScaleName: data.selectedScaleName,
                              onScaleSelected: (scaleName) =>
                                  state.selectScale(scaleName),
                              onChordTonesSelected: state.selectChordTones,
                              showHeader: false,
                              hasContainer: false,
                            ),
                            const SizedBox(height: 10),
                            Divider(color: theme.dividerColor),
                            const SizedBox(height: 10),
                            ScaleVisualizationSection(
                              root: data.root,
                              selectedScaleName: data.selectedScaleName,
                              baseScaleName: data.relatedScales.isNotEmpty
                                  ? data.relatedScales.first
                                  : null,
                              isMinor: data.isMinor,
                              chordNotes: data.notes,
                              chordIntervals: data.chordIntervalList,
                              onPlayScale: state.playSelectedScale,
                              onPlayChord: state.playChordStrum,
                              hasContainer: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2. 다각도 심층 화성 분석 카드 (Diatonic, Tensions, Substitutions, Style)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ExtendedAnalysisSection(
                          root: data.root,
                          quality: data.quality,
                          selectedScaleName: data.selectedScaleName,
                          onChordSelected: (val) =>
                              state.analyzeChord(val, isNavigation: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Tier 2: 중단 실전 보이싱 & 거장 릭
            // 1. Recommended Voicings (5개 폼 전폭 가로 카드)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ChordVoicingSection(
                root: data.root,
                quality: data.quality,
                notes: data.notes,
                voicings: data.voicings,
                onPlayVoicing: state.playVoicing,
                selectedStyle: data.selectedStyle,
                onStyleSelected: state.setVoicingStyle,
                selectedVoicingIndex: data.selectedVoicingIndex,
                onVoicingSelected: state.selectVoicing,
              ),
            ),

            const SizedBox(height: 14),

            // 2. 추천 거장 릭 (Full Width 가로 캐러셀)
            ChordLickRecommendationCard(
              chordRoot: data.root,
              chordQuality: data.quality,
            ),

            const SizedBox(height: 14),

            // Tier 3: 하단 기타 지판 맵 (Full Width!)
            const _GeneratorFretboardSection(),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }
}

/// 대시보드 공통 바디 (Voicing + Scales + Visualization + Analysis)
class _GeneratorMobileDashboardBody extends StatelessWidget {
  const _GeneratorMobileDashboardBody();

  @override
  Widget build(BuildContext context) {
    return Selector<
        GeneratorState,
        ({
          String root,
          String quality,
          List<String> chordNotes,
          List<ChordVoicing> voicings,
          String selectedStyle,
          int? selectedVoicingIndex,
          List<String> relatedScales,
          String? selectedScaleName,
          bool isMinor,
          List<String> chordIntervalList,
        })>(
      selector: (_, s) => (
        root: s.analyzedRoot,
        quality: s.analyzedQuality,
        chordNotes: s.chordNotes,
        voicings: s.generatedVoicings,
        selectedStyle: s.selectedVoicingStyle,
        selectedVoicingIndex: s.selectedVoicingIndex,
        relatedScales: s.relatedScales,
        selectedScaleName: s.selectedScaleName,
        isMinor: s.isMinor,
        chordIntervalList: s.chordIntervalList,
      ),
      builder: (context, data, _) {
        final generatorState = context.read<GeneratorState>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChordVoicingSection(
              root: data.root,
              quality: data.quality,
              notes: data.chordNotes,
              voicings: data.voicings,
              onPlayVoicing: generatorState.playVoicing,
              selectedStyle: data.selectedStyle,
              onStyleSelected: generatorState.setVoicingStyle,
              selectedVoicingIndex: data.selectedVoicingIndex,
              onVoicingSelected: generatorState.selectVoicing,
            ),
            const SizedBox(height: 8),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 8),
            RelatedScalesSection(
              root: data.root,
              displayQuality: data.quality,
              relatedScales: data.relatedScales,
              selectedScaleName: data.selectedScaleName,
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
              root: data.root,
              selectedScaleName: data.selectedScaleName,
              baseScaleName: data.relatedScales.isNotEmpty
                  ? data.relatedScales.first
                  : null,
              isMinor: data.isMinor,
              chordNotes: data.chordNotes,
              chordIntervals: data.chordIntervalList,
              onPlayScale: generatorState.playSelectedScale,
              onPlayChord: generatorState.playChordStrum,
              hasContainer: false,
            ),
            const SizedBox(height: 16),
            ExtendedAnalysisSection(
              root: data.root,
              quality: data.quality,
              selectedScaleName: data.selectedScaleName,
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
