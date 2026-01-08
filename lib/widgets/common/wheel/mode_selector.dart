import 'package:flutter/material.dart';
import '../../../models/music_constants.dart';

class ModeSelector extends StatelessWidget {
  final int currentModeIndex;
  final Function(int) onModeSelected;

  const ModeSelector({
    super.key,
    required this.currentModeIndex,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('모드(Mode) 선택',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(MusicConstants.MODES.length, (index) {
              final mode = MusicConstants.MODES[index];
              final isSelected = index == currentModeIndex;
              // Color logic: if Minor -> Secondary(Purple), if Major -> Primary/Cyan
              Color activeColor = mode.isMinor
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary;

              return InkWell(
                onTap: () => onModeSelected(index),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor
                        : Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: isSelected
                            ? activeColor.withValues(alpha: 0.5)
                            : Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.8)),
                  ),
                  child: Text(
                    mode.name,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }
}
