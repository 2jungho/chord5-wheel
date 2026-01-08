import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/generator_state.dart';
import '../../providers/settings_state.dart';
import '../../models/instrument_model.dart';
import '../../widgets/common/fretboard/fretboard_section.dart';
import '../../widgets/common/chord_info_section.dart';
import '../../widgets/common/view_control_panel.dart';
import 'widgets/chord_voicing_section.dart';
import 'widgets/extended_analysis_section.dart';
import 'widgets/related_scales_section.dart';
import 'widgets/scale_visualization_section.dart';

class GeneratorView extends StatefulWidget {
  const GeneratorView({super.key});

  @override
  State<GeneratorView> createState() => _GeneratorViewState();
}

class _GeneratorViewState extends State<GeneratorView> {
  @override
  Widget build(BuildContext context) {
    final generatorState = context.watch<GeneratorState>();
    final selectedInstrument =
        context.watch<SettingsState>().selectedInstrument;

    return LayoutBuilder(builder: (context, constraints) {
      final bool isNarrow = constraints.maxWidth < 900;
      final bool isShort = constraints.maxHeight < 700;

      if (isNarrow || isShort) {
        // --- Mobile/Short Layout (Single Scroll) ---
        return SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (generatorState.hasAnalysisResult) ...[
                // Dashboard Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChordInfoSection(
                        root: generatorState.analyzedRoot,
                        quality: generatorState.analyzedQuality,
                        intervals: generatorState.analyzedIntervals,
                        notes: generatorState.chordNotes,
                        onPlay: generatorState.playChordStrum,
                        onRestore: generatorState.canRestore
                            ? generatorState.restoreInitialChord
                            : null,
                        voicing: generatorState.generatedVoicings.isNotEmpty
                            ? generatorState.generatedVoicings[
                                generatorState.selectedVoicingIndex ?? 0]
                            : null,
                        instrument: selectedInstrument,
                      ),
                      const SizedBox(height: 24),
                      ChordVoicingSection(
                        root: generatorState.analyzedRoot,
                        quality: generatorState.analyzedQuality,
                        notes: generatorState.chordNotes,
                        voicings: generatorState.generatedVoicings,
                        onPlayVoicing: generatorState.playVoicing,
                        selectedStyle: generatorState.selectedVoicingStyle,
                        onStyleSelected: generatorState.setVoicingStyle,
                        selectedVoicingIndex:
                            generatorState.selectedVoicingIndex,
                        onVoicingSelected: generatorState.selectVoicing,
                      ),
                      const SizedBox(height: 16),
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
                      ExtendedAnalysisSection(
                        root: generatorState.analyzedRoot,
                        quality: generatorState.analyzedQuality,
                        selectedScaleName: generatorState.selectedScaleName,
                        onChordSelected: (val) => generatorState
                            .analyzeChord(val, isNavigation: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Footer: Fretboard Map
                // Footer: Fretboard Map
                FretboardSection(
                  highlightMap: generatorState.fretboardHighlights,
                  rootNote: generatorState.analyzedRoot,
                  selectedScaleName: generatorState.selectedScaleName,
                  pentatonicName: generatorState.basePentatonicName,
                  visibleIntervals: generatorState.visibleIntervals,
                  focusCagedForm: generatorState.selectedCagedForm,
                  isMinor: generatorState.isMinor,
                  controlPanel: ViewControlPanel(
                    visibleIntervals: generatorState.visibleIntervals,
                    availableIntervals: generatorState.availableIntervals,
                    selectedCagedForm: generatorState.selectedCagedForm,
                    onToggleInterval: generatorState.toggleInterval,
                    onSelectForm: generatorState.selectCagedForm,
                    onReset: generatorState.resetViewFilters,
                  ),
                ),
                const SizedBox(height: 40),
              ] else ...[
                // Empty State
                SizedBox(
                  height: constraints.maxHeight - 100,
                  child: _buildEmptyState(context),
                ),
              ],
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
              if (!generatorState.hasAnalysisResult)
                SizedBox(height: 600, child: _buildEmptyState(context)),
              if (generatorState.hasAnalysisResult) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: LayoutBuilder(
                    builder: (context, dashboardConstraints) {
                      final isDashboardWide =
                          dashboardConstraints.maxWidth > 1100;
                      if (isDashboardWide) {
                        return _buildDesktopDashboard(
                            context, generatorState, selectedInstrument);
                      } else {
                        // Tablet/Single Column Dashboard
                        return _buildMobileDashboardBody(
                            context, generatorState);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                FretboardSection(
                  highlightMap: generatorState.fretboardHighlights,
                  rootNote: generatorState.analyzedRoot,
                  selectedScaleName: generatorState.selectedScaleName,
                  pentatonicName: generatorState.basePentatonicName,
                  visibleIntervals: generatorState.visibleIntervals,
                  focusCagedForm: generatorState.selectedCagedForm,
                  isMinor: generatorState.isMinor,
                  controlPanel: ViewControlPanel(
                    visibleIntervals: generatorState.visibleIntervals,
                    availableIntervals: generatorState.availableIntervals,
                    selectedCagedForm: generatorState.selectedCagedForm,
                    onToggleInterval: generatorState.toggleInterval,
                    onSelectForm: generatorState.selectCagedForm,
                    onReset: generatorState.resetViewFilters,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  // --- Helper Widgets to keep build clean ---

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_note,
            size: 80,
            color:
                Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
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

  Widget _buildDesktopDashboard(BuildContext context,
      GeneratorState generatorState, Instrument selectedInstrument) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Info Section
        Expanded(
          flex: 2,
          child: ChordInfoSection(
            root: generatorState.analyzedRoot,
            quality: generatorState.analyzedQuality,
            intervals: generatorState.analyzedIntervals,
            notes: generatorState.chordNotes,
            onPlay: generatorState.playChordStrum,
            onRestore: generatorState.canRestore
                ? generatorState.restoreInitialChord
                : null,
            voicing: generatorState.generatedVoicings.isNotEmpty
                ? generatorState
                    .generatedVoicings[generatorState.selectedVoicingIndex ?? 0]
                : null,
            instrument: selectedInstrument,
          ),
        ),
        const SizedBox(width: 32),
        // 2. Middle Section
        Expanded(
          flex: 6,
          child: _buildMobileDashboardBody(context, generatorState),
        ),
        const SizedBox(width: 32),
        // 3. Right Section
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${generatorState.analyzedRoot}${generatorState.analyzedQuality} 코드입니다. 다양한 보이싱으로 연주해보세요.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              ExtendedAnalysisSection(
                root: generatorState.analyzedRoot,
                quality: generatorState.analyzedQuality,
                selectedScaleName: generatorState.selectedScaleName,
                onChordSelected: (val) =>
                    generatorState.analyzeChord(val, isNavigation: true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileDashboardBody(
      BuildContext context, GeneratorState generatorState) {
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
          onScaleSelected: (scaleName) => generatorState.selectScale(scaleName),
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
        // If narrow dashboard, show extended analysis too
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
  }
}
