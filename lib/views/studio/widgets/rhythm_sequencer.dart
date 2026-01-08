import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/studio_state.dart';
import '../../../models/progression/progression_models.dart';

class RhythmSequencer extends StatelessWidget {
  const RhythmSequencer({super.key});

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<StudioState>();
    final pattern = studio.session.rhythmPattern;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preset Selection Area
          const Text(
            'Quick Presets',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: RhythmPattern.presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final p = RhythmPattern.presets[index];
                final isSelected = pattern.name == p.name;
                return ChoiceChip(
                  padding: EdgeInsets.zero,
                  label: Text(p.name, style: const TextStyle(fontSize: 10)),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) studio.updateRhythmPattern(p);
                  },
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Text(
                'Editing: ${pattern.name}',
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              _buildControlChip(context, '4/4 Time', Icons.timer_outlined),
            ],
          ),
          const SizedBox(height: 6),
          // Simplified Grid
          SizedBox(
            height: 56,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 16,
                childAspectRatio: 0.7,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
              ),
              itemCount: 16,
              itemBuilder: (context, index) {
                final step = pattern.steps.firstWhere(
                  (s) => s.position == index,
                  orElse: () => RhythmStep(
                      position: index, action: RhythmActionType.none),
                );
                return _buildCompactStepTile(context, index, step, studio);
              },
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tip: Click to toggle, Long-press for accent.',
            style: TextStyle(
                fontSize: 9, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStepTile(
      BuildContext context, int index, RhythmStep step, StudioState studio) {
    final bool isActive = step.action != RhythmActionType.none;
    final bool isBeatStart = index % 4 == 0;

    return GestureDetector(
      onTap: () => studio.toggleRhythmStep(index),
      onLongPress: () => studio.toggleAccent(index),
      child: Column(
        children: [
          // Beat indicator
          Text(
            isBeatStart ? '${(index ~/ 4) + 1}' : '',
            style: const TextStyle(fontSize: 8, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isActive
                    ? (step.isAccent
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primaryContainer)
                    : Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                      : (isBeatStart
                          ? Colors.grey.withOpacity(0.3)
                          : Colors.transparent),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isActive)
                    Icon(
                      _getActionIcon(step.action),
                      size: 14,
                      color: step.isAccent
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary,
                    ),
                  if (!isActive && isBeatStart)
                    Container(
                      width: 2,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(RhythmActionType action) {
    switch (action) {
      case RhythmActionType.down:
        return Icons.keyboard_double_arrow_down;
      case RhythmActionType.up:
        return Icons.keyboard_double_arrow_up;
      case RhythmActionType.mute:
        return Icons.close;
      case RhythmActionType.bass:
        return Icons.unfold_more;
      case RhythmActionType.none:
        return Icons.remove;
    }
  }

  Widget _buildControlChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
