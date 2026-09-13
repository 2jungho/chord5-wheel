import 'package:flutter/material.dart';

/// Interactive interval toggles for natural and flat/sharp intervals on the fretboard.
class IntervalsSelector extends StatelessWidget {
  final Set<String> visibleIntervals;
  final Set<String>? availableIntervals;
  final Function(String) onToggleInterval;

  const IntervalsSelector({
    super.key,
    required this.visibleIntervals,
    this.availableIntervals,
    required this.onToggleInterval,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Intervals',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
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
                _buildFixedToggleButton(context, 'P5', '5', colorScheme.onSurface),
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
                const SizedBox(width: 60),
                _buildFixedToggleButton(context, 'm3', 'b3', Colors.amber),
                const SizedBox(width: 44),
                _buildFixedToggleButton(context, 'd5', 'b5', colorScheme.onSurface),
                const SizedBox(width: 44),
                _buildFixedToggleButton(context, 'm7', 'b7', Colors.cyanAccent),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFixedToggleButton(
    BuildContext context,
    String intervalKey,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
              color: theme.dividerColor.withValues(alpha: 0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
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
                : colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.8)
                  : theme.dividerColor.withValues(alpha: 0.8),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
