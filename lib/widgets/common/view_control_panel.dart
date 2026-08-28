import 'package:flutter/material.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
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
            // Header: Title + Reset Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('View Controls',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
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
                _buildIntervalsSection(context),
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

  Widget _buildIntervalsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Intervals',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Natural Intervals
            Row(
              children: [
                _buildFixedToggleButton(context, '1P', 'R', Colors.redAccent),
                const SizedBox(width: 4),
                _buildFixedToggleButton(context, 'M2', '2', Colors.grey),
                const SizedBox(width: 4),
                _buildFixedToggleButton(context, 'M3', '3', Colors.amber),
                const SizedBox(width: 4),
                _buildFixedToggleButton(context, 'P4', '4', Colors.grey),
                const SizedBox(width: 4),
                _buildFixedToggleButton(context, 'P5', '5',
                    Theme.of(context).colorScheme.onSurface),
                const SizedBox(width: 4),
                _buildFixedToggleButton(context, 'M6', '6', Colors.grey),
                const SizedBox(width: 4),
                _buildFixedToggleButton(context, 'M7', '7', Colors.cyanAccent),
              ],
            ),
            const SizedBox(height: 2),
            // Row 2: Flat/Sharp Intervals (Staggered)
            Row(
              children: [
                _buildIntervalsRow2(context),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIntervalsRow2(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 60),
        _buildFixedToggleButton(context, 'm3', 'b3', Colors.amber),
        const SizedBox(width: 44),
        _buildFixedToggleButton(
            context, 'd5', 'b5', Theme.of(context).colorScheme.onSurface),
        const SizedBox(width: 44),
        _buildFixedToggleButton(context, 'm7', 'b7', Colors.cyanAccent),
      ],
    );
  }

  Widget _buildFormFocusSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Form Focus',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11)),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildCagedButton(context, 'C'),
              _buildCagedButton(context, 'A'),
              _buildCagedButton(context, 'G'),
              _buildCagedButton(context, 'E'),
              _buildCagedButton(context, 'D'),
              if (onTogglePentatonic != null) ...[
                const SizedBox(width: 4),
                _buildScaleToggleButton(context),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPentatonicBoxSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('솔로 박스 (Box)',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11)),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildBoxButton(context, 0, '전체'),
              _buildBoxButton(context, 1, 'Box 1'),
              _buildBoxButton(context, 2, 'Box 2'),
              _buildBoxButton(context, 3, 'Box 3'),
              _buildBoxButton(context, 4, 'Box 4'),
              _buildBoxButton(context, 5, 'Box 5'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBoxButton(BuildContext context, int boxNum, String label) {
    final isSelected = selectedPentatonicBox == boxNum;
    return SizedBox(
      height: 26,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.tertiary
              : Theme.of(context).colorScheme.surfaceContainerHigh,
          foregroundColor: isSelected
              ? Theme.of(context).colorScheme.onTertiary
              : Theme.of(context).colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).dividerColor)),
        ),
        onPressed: () => onSelectPentatonicBox?.call(boxNum),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
      ),
    );
  }

  Widget _buildFixedToggleButton(
      BuildContext context, String intervalKey, String label, Color color) {
    final isAvailable =
        availableIntervals == null || availableIntervals!.contains(intervalKey);
    final isSelected = visibleIntervals.contains(intervalKey);

    if (!isAvailable) {
      return SizedBox(
        width: 36,
        height: 26,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                    fontSize: 10)),
          ),
        ),
      );
    }

    return SizedBox(
      width: 36,
      height: 26,
      child: InkWell(
        onTap: () => onToggleInterval(intervalKey),
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : Theme.of(context).colorScheme.surface,
            border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.8)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.8),
                width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  color: isSelected
                      ? color
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                )),
          ),
        ),
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
