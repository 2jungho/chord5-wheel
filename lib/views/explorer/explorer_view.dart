import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_state.dart';
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
import '../../widgets/common/glass_container.dart';

class ExplorerView extends StatelessWidget {
  const ExplorerView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Unified Scrollable Layout for all screen sizes
      return SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // 1. Unified Explorer Dashboard
            _buildDashboard(context),
            const SizedBox(height: 16),
            // 2. Full Fretboard Map
            _buildFretboardSection(context),
            const SizedBox(height: 40),
          ],
        ),
      );
    });
  }

  Widget _buildDashboard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      opacity: 0.6,
      child: LayoutBuilder(builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 900;
        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel: Controller
              SizedBox(
                width: 380,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 380,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildWheel(context),
                        const SizedBox(height: 12),
                        _buildModeSelector(context),
                      ],
                    ),
                  ),
                ),
              ),
              // Vertical Spacer (No Divider to avoid intrinsic height issues)
              const SizedBox(width: 48),
              // Right Panel: Information Display
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const InfoPanel(withContainer: false),
                    const SizedBox(height: 16),
                    Divider(color: Theme.of(context).dividerColor),
                    const SizedBox(height: 8),
                    // Side-by-side lists with enough vertical space
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CagedList(),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: DiatonicList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Mobile Layout: Simplified but complete
          return Column(
            mainAxisSize: MainAxisSize.min, // Reduced size
            children: [
              _buildWheel(context, size: min(constraints.maxWidth - 20, 320.0)),
              const SizedBox(height: 16),
              _buildModeSelector(context),
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).dividerColor),
              const InfoPanel(withContainer: false),
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).dividerColor),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CagedList(),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: DiatonicList(),
              ),
            ],
          );
        }
      }),
    );
  }

  Widget _buildWheel(BuildContext context, {double size = 360}) {
    return Selector<
        MusicState,
        ({
          String rootNote,
          String modeName,
          int currentKeyIndex,
          bool isInnerRingSelected
        })>(
      selector: (context, state) => (
        rootNote: state.rootNote,
        modeName: state.currentMode.name,
        currentKeyIndex: state.currentKeyIndex,
        isInnerRingSelected: state.isInnerRingSelected,
      ),
      builder: (context, data, _) => InteractiveCircleOfFifths(
        size: size,
        rootNote: data.rootNote,
        modeName: data.modeName,
        currentKeyIndex: data.currentKeyIndex,
        isInnerRingSelected: data.isInnerRingSelected,
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
    return Selector<
        MusicState,
        ({
          String rootNote,
          String modeName,
          Set<String> visibleIntervals,
          String? selectedCagedForm
        })>(
      selector: (context, state) => (
        rootNote: state.rootNote,
        modeName: state.currentMode.name,
        visibleIntervals: state.visibleIntervals,
        selectedCagedForm: state.selectedCagedForm,
      ),
      builder: (context, data, _) {
        final root = data.rootNote;
        final modeName = data.modeName;
        final scaleNotes = TheoryUtils.calculateScaleNotes(root, modeName);

        final classified = TheoryUtils.classifyScaleNotes(scaleNotes, modeName);
        final chordTones = classified['chordTones']!;
        final otherNotes = classified['otherNotes']!;

        final map = GuitarUtils.generateFretboardMap(
            root: root,
            notes: chordTones,
            ghostNotes: otherNotes,
            scaleNameForIntervals: modeName);

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
          isMinor: MusicConstants.MODES
              .firstWhere((m) => m.name == modeName)
              .isMinor,
          controlPanel: ViewControlPanel(
            visibleIntervals: data.visibleIntervals,
            availableIntervals: availableIntervals,
            selectedCagedForm: data.selectedCagedForm,
            onToggleInterval: context.read<MusicState>().toggleInterval,
            onSelectForm: context.read<MusicState>().selectCagedForm,
            onReset: context.read<MusicState>().resetViewFilters,
          ),
        );
      },
    );
  }
}
