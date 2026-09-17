import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_state.dart';
import '../../providers/settings_state.dart';
import '../../models/instrument_model.dart';
import '../../models/music_constants.dart';
import '../../widgets/common/wheel/interactive_circle_of_fifths.dart';

import 'info_panel.dart';
import '../../widgets/common/theory/diatonic_list.dart';
import '../../widgets/common/theory/caged_list.dart';
import '../../utils/theory_utils.dart';
import '../../widgets/common/fretboard/fretboard_section.dart';
import '../../widgets/common/view_control_panel.dart';
import '../../widgets/common/wheel/mode_selector.dart';

import 'dialogs/modulation_dialog.dart';

import '../../utils/guitar_utils.dart';
import '../../utils/guitar/pentatonic_box_calculator.dart';
import '../../widgets/common/glass_container.dart';
import '../../models/fretboard_marker.dart';
import '../../widgets/lick/chord_lick_recommendation_card.dart';



class ExplorerView extends StatelessWidget {
  const ExplorerView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth >= 960;

      if (isDesktop) {
        return _buildDesktopDashboard(context, constraints);
      } else {
        return _buildMobileDashboard(context, constraints);
      }
    });
  }

  /// 데스크톱(PC) 전용: 안 1 [좌측 마스터 독 + 우측 메인 워크스페이스 + 중단 릭 & CAGED + 하단 전폭 지판]
  Widget _buildDesktopDashboard(
      BuildContext context, BoxConstraints constraints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tier 1: 상단 마스터 독 & 메인 작업 영역 (좌우 1:1 완벽한 높이 수평 일치)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Panel: Controller Master Dock (폭 380px 고정, 우측과 1:1 동일 높이 스트레칭)
                SizedBox(
                  width: 380,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildWheel(context, size: 280),
                        _buildChordTypeToggle(context),
                        _buildModeSelector(context),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Right Panel: Theory Workspace (1층 InfoPanel + 2층 CAGED & Diatonic Side-by-Side)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 1층: 스케일 정보 & 선택 코드 핑거링 다이어그램
                      const InfoPanel(
                          withContainer: true,
                          showLickSection: false,
                          isWide: true),
                      const SizedBox(height: 12),
                      // 2층: CAGED 5개 폼(좌) & Diatonic 7개 코드(우) 나란히 배치 (5:5 Side-by-Side, 높이 완벽 일치)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const CagedList(),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 5,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const DiatonicList(showChordTypeToggle: false),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 거장 릭 섹션 (Full Width 가로 캐러셀)
          Consumer<MusicState>(
            builder: (context, state, _) {
              final chord = state.selectedChord;
              final mode = state.currentMode;
              final root = state.rootNote;
              return ChordLickRecommendationCard(
                chordRoot: chord.root,
                chordQuality: chord.quality,
                keyContext: '$root ${mode.name}',
              );
            },
          ),

          const SizedBox(height: 14),

          // Tier 3: 하단 기타 지판 맵 (Full Width!)
          _buildFretboardSection(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// 모바일/태블릿(차선 대응): 작은 화면을 위한 터치 친화적 1단 세로 스크롤 레이아웃
  Widget _buildMobileDashboard(
      BuildContext context, BoxConstraints constraints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(12),
            opacity: 0.6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWheel(context,
                    size: min(constraints.maxWidth - 20, 320.0)),
                const SizedBox(height: 12),
                _buildChordTypeToggle(context),
                const SizedBox(height: 12),
                _buildModeSelector(context),
                const SizedBox(height: 16),
                Divider(color: Theme.of(context).dividerColor),
                const InfoPanel(withContainer: false, isWide: false),
                const SizedBox(height: 16),
                Divider(color: Theme.of(context).dividerColor),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CagedList(),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: DiatonicList(showChordTypeToggle: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildFretboardSection(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWheel(BuildContext context, {double size = 300}) {
    return Selector<
        MusicState,
        ({
          String rootNote,
          String modeName,
          int currentKeyIndex,
          bool isInnerRingSelected,
          bool isSeventhMode,
        })>(
      selector: (context, state) => (
        rootNote: state.rootNote,
        modeName: state.currentMode.name,
        currentKeyIndex: state.currentKeyIndex,
        isInnerRingSelected: state.isInnerRingSelected,
        isSeventhMode: state.isSeventhMode,
      ),
      builder: (context, data, _) => InteractiveCircleOfFifths(
        size: size,
        rootNote: data.rootNote,
        modeName: data.modeName,
        currentKeyIndex: data.currentKeyIndex,
        isInnerRingSelected: data.isInnerRingSelected,
        isSeventhMode: data.isSeventhMode,
        onKeySelected: (index, isInner) =>
            context.read<MusicState>().selectKeySlice(index, isInner),
        onKeyLongPressed: (index, isInner) {
          final state = context.read<MusicState>();
          final targetKeyData = MusicConstants.KEYS[index];
          final targetKeyName =
              isInner ? targetKeyData.minor : targetKeyData.name;
          final targetKeyLabel = isInner
              ? '${targetKeyName.replaceAll('m', '')} Minor'
              : '$targetKeyName Major';
          final startKeyLabel = '${state.rootNote} ${state.currentMode.name}';
          showDialog(
            context: context,
            builder: (_) => ModulationDialog(
              startKey: startKeyLabel,
              targetKey: targetKeyLabel,
            ),
          );
        },
      ),
    );
  }

  Widget _buildChordTypeToggle(BuildContext context) {
    final isSeventh = context.select<MusicState, bool>((s) => s.isSeventhMode);
    final theme = Theme.of(context);

    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(
            context,
            label: '3화음',
            isSelected: !isSeventh,
            onTap: () => context.read<MusicState>().setSeventhMode(false),
          ),
          _buildToggleOption(
            context,
            label: '7화음',
            isSelected: isSeventh,
            onTap: () => context.read<MusicState>().setSeventhMode(true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    return Selector<MusicState, int>(
      selector: (_, state) => state.currentModeIndex,
      builder: (context, currentModeIndex, _) => ModeSelector(
        currentModeIndex: currentModeIndex,
        onModeSelected: (idx) => context.read<MusicState>().changeMode(idx),
      ),
    );
  }


  Widget _buildFretboardSection(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final tuning = settings.tuningPreset;

    return Selector<
        MusicState,
        ({
          String rootNote,
          String modeName,
          Set<String> visibleIntervals,
          String? selectedCagedForm,
          int selectedPentatonicBox,
        })>(
      selector: (context, state) => (
        rootNote: state.rootNote,
        modeName: state.currentMode.name,
        visibleIntervals: state.visibleIntervals,
        selectedCagedForm: state.selectedCagedForm,
        selectedPentatonicBox: state.selectedPentatonicBox,
      ),
      builder: (context, data, _) {
        final root = data.rootNote;
        final modeName = data.modeName;
        final isMinor = MusicConstants.MODES
            .firstWhere((m) => m.name == modeName)
            .isMinor;

        Map<int, List<FretboardMarker>> map;
        if (data.selectedPentatonicBox > 0) {
          map = PentatonicBoxCalculator.generateBoxMarkers(
            keyRoot: root,
            isMinorKey: isMinor,
            boxNumber: data.selectedPentatonicBox,
          );
        } else {
          final scaleNotes = TheoryUtils.calculateScaleNotes(root, modeName);
          final classified = TheoryUtils.classifyScaleNotes(scaleNotes, modeName);
          final chordTones = classified['chordTones']!;
          final otherNotes = classified['otherNotes']!;

          map = GuitarUtils.generateFretboardMap(
              root: root,
              notes: chordTones,
              ghostNotes: otherNotes,
              scaleNameForIntervals: modeName,
              tuning: tuning.notes);
        }

        final availableIntervals = map.values
            .expand((markers) => markers)
            .map((m) => m.interval)
            .toSet();

        return FretboardSection(
          highlightMap: map,
          rootNote: data.rootNote,
          selectedScaleName: '${data.rootNote} ${data.modeName}',
          visibleIntervals: data.visibleIntervals,
          focusCagedForm: data.selectedCagedForm,
          isMinor: isMinor,
          controlPanel: ViewControlPanel(
            visibleIntervals: data.visibleIntervals,
            availableIntervals: availableIntervals,
            selectedCagedForm: data.selectedCagedForm,
            onToggleInterval: context.read<MusicState>().toggleInterval,
            onSelectForm: context.read<MusicState>().selectCagedForm,
            onReset: context.read<MusicState>().resetViewFilters,
            selectedPentatonicBox: data.selectedPentatonicBox,
            onSelectPentatonicBox: context.read<MusicState>().selectPentatonicBox,
            tuningPreset: tuning,
            onSelectTuning: (newPreset) => settings.setTuningPreset(newPreset),
          ),
        );
      },
    );
  }

}
