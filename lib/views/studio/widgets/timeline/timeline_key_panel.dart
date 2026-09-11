import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/studio_state.dart';
import '../../../../models/progression/progression_models.dart';
import '../../../../models/music_constants.dart';
import '../../../../providers/music_state.dart';
import '../../../../widgets/common/circle_of_fifths_selector.dart';

class TimelineKeyPanel extends StatelessWidget {
  final StudioState studio;
  final ProgressionSession session;
  final bool isMobile;

  const TimelineKeyPanel({
    super.key,
    required this.studio,
    required this.session,
    this.isMobile = false,
  });

  void _syncKeyWithMusicState(BuildContext context, String keyString) {
    try {
      final musicState = context.read<MusicState>();
      final parts = keyString.split(' ');
      if (parts.isEmpty) return;

      final root = parts[0];
      final isMinor = parts.length > 1 && parts[1] == 'Minor';

      int keyIndex = -1;
      if (isMinor) {
        final targetMinor = '${root}m';
        keyIndex = MusicConstants.KEYS.indexWhere((k) => k.minor == targetMinor);
        if (keyIndex == -1) {
          keyIndex = MusicConstants.KEYS.indexWhere((k) => k.minor == root);
        }
      } else {
        keyIndex = MusicConstants.KEYS.indexWhere((k) => k.name == root);
      }

      if (keyIndex != -1) {
        musicState.selectKeySlice(keyIndex, isMinor);
      }
    } catch (e) {
      debugPrint('Error syncing Key to MusicState: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note,
                size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Key Center',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double size = min(constraints.maxWidth, constraints.maxHeight);
                return CircleOfFifthsSelector(
                  currentKey: session.key,
                  isSeventhMode: context.watch<MusicState>().isSeventhMode,
                  onKeySelected: (key) {
                    studio.updateKey(key);
                    _syncKeyWithMusicState(context, key);
                  },
                  size: size,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            session.key,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TimelineChordTypeToggle(studio: studio),
      ],
    );
  }
}

class TimelineChordTypeToggle extends StatelessWidget {
  final StudioState studio;

  const TimelineChordTypeToggle({super.key, required this.studio});

  @override
  Widget build(BuildContext context) {
    final musicState = context.watch<MusicState>();
    final isSeventh = musicState.isSeventhMode;
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
          _buildTogglePill(
            context,
            label: '3화음',
            isSelected: !isSeventh,
            onTap: () {
              context.read<MusicState>().setSeventhMode(false);
              studio.convertProgressionDensity(toSeventh: false);
            },
          ),
          _buildTogglePill(
            context,
            label: '7화음',
            isSelected: isSeventh,
            onTap: () {
              context.read<MusicState>().setSeventhMode(true);
              studio.convertProgressionDensity(toSeventh: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTogglePill(
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
}
