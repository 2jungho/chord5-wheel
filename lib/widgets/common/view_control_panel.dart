import 'package:flutter/material.dart';

import '../../models/instrument_model.dart';
import 'view_controls/intervals_selector.dart';
import 'view_controls/tuning_dropdown.dart';

class ViewControlPanel extends StatelessWidget {
  final Set<String> visibleIntervals;
  final Set<String>? availableIntervals; // 프렛보드에 존재하는 인터벌 목록 (null이면 모두 활성)
  final String? selectedCagedForm;
  final Function(String) onToggleInterval;
  final Function(String?) onSelectForm;
  final VoidCallback onReset;
  final bool showPentatonic;
  final VoidCallback? onTogglePentatonic;
  final int selectedPentatonicBox;
  final Function(int)? onSelectPentatonicBox;
  final TuningPreset tuningPreset;
  final Function(TuningPreset)? onSelectTuning;

  const ViewControlPanel({
    super.key,
    required this.visibleIntervals,
    this.availableIntervals,
    this.selectedCagedForm,
    required this.onToggleInterval,
    required this.onSelectForm,
    required this.onReset,
    this.showPentatonic = true,
    this.onTogglePentatonic,
    this.selectedPentatonicBox = 0,
    this.onSelectPentatonicBox,
    this.tuningPreset = TuningPreset.standard,
    this.onSelectTuning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(

        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title + Tuning Chip + Reset Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View Controls',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        if (onSelectTuning != null) ...[
                          const SizedBox(width: 8),
                          TuningDropdown(
                            tuningPreset: tuningPreset,
                            onSelectTuning: onSelectTuning,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 24,
                  child: TextButton.icon(
                      onPressed: onReset,
                      icon: Icon(Icons.refresh,
                          size: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      label: Text('Reset',
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8))),
                )
              ],
            ),
            const SizedBox(height: 4),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            const SizedBox(height: 8),

            // Responsive Content - Always use Vertical Layout
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntervalsSelector(
                  visibleIntervals: visibleIntervals,
                  availableIntervals: availableIntervals,
                  onToggleInterval: onToggleInterval,
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                const SizedBox(height: 8),
                _buildFormFocusSection(context),
                if (onSelectPentatonicBox != null) ...[
                  const SizedBox(height: 8),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  const SizedBox(height: 8),
                  _buildPentatonicBoxSection(context),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildFormFocusSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Form Focus',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCagedButton(context, 'C'),
                const SizedBox(width: 4),
                _buildCagedButton(context, 'A'),
                const SizedBox(width: 4),
                _buildCagedButton(context, 'G'),
                const SizedBox(width: 4),
                _buildCagedButton(context, 'E'),
                const SizedBox(width: 4),
                _buildCagedButton(context, 'D'),
                if (onTogglePentatonic != null) ...[
                  const SizedBox(width: 8),
                  _buildScaleToggleButton(context),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPentatonicBoxSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('솔로 박스',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBoxButton(context, 0, '전체'),
                const SizedBox(width: 4),
                _buildBoxButton(context, 1, 'Box 1'),
                const SizedBox(width: 4),
                _buildBoxButton(context, 2, 'Box 2'),
                const SizedBox(width: 4),
                _buildBoxButton(context, 3, 'Box 3'),
                const SizedBox(width: 4),
                _buildBoxButton(context, 4, 'Box 4'),
                const SizedBox(width: 4),
                _buildBoxButton(context, 5, 'Box 5'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoxButton(BuildContext context, int boxNum, String label) {
    final isSelected = selectedPentatonicBox == boxNum;
    final theme = Theme.of(context);
    return SizedBox(
      height: 26,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHigh,
          foregroundColor: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          elevation: isSelected ? 1 : 0,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.dividerColor.withValues(alpha: 0.6))),
        ),
        onPressed: () => onSelectPentatonicBox?.call(boxNum),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }


  Widget _buildCagedButton(BuildContext context, String? form,
      {String? label}) {
    final isSelected = selectedCagedForm == form;
    return SizedBox(
      width: 32,
      height: 28,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHigh,
          foregroundColor: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
          padding: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor)),
        ),
        onPressed: () => onSelectForm(form),
        child: Text(label ?? form ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }

  Widget _buildScaleToggleButton(BuildContext context) {
    return SizedBox(
      height: 28,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: showPentatonic
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.surfaceContainerHigh,
          foregroundColor: showPentatonic
              ? Theme.of(context).colorScheme.onSecondary
              : Theme.of(context).colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                  color: showPentatonic
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).dividerColor)),
        ),
        onPressed: onTogglePentatonic,
        icon: Icon(showPentatonic ? Icons.visibility : Icons.visibility_off,
            size: 14),
        label: const Text('Key Scale',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }
}
