import 'package:flutter/material.dart';
import '../../../providers/lick_vault_state.dart';

/// 아티스트 릭 보관함 - 릭 선택 카드 목록 위젯
class LickCardList extends StatelessWidget {
  final LickVaultState vault;

  const LickCardList({super.key, required this.vault});

  @override
  Widget build(BuildContext context) {
    final licks = vault.filteredLicks;
    if (licks.isEmpty) {
      return const Center(child: Text('해당 조건에 맞는 릭이 없습니다.'));
    }

    return SizedBox(
      height: 115,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: licks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final lick = licks[index];
          final isSelected = vault.selectedLick.id == lick.id;
          final colorScheme = Theme.of(context).colorScheme;

          return InkWell(
            onTap: () => vault.selectLick(lick),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 240,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                    : colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(lick.difficulty).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          lick.difficulty,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getDifficultyColor(lick.difficulty),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Chord: ${lick.targetChord}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    lick.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    lick.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.amber.shade700;
      case 'advanced':
        return Colors.red.shade400;
      default:
        return Colors.blue;
    }
  }
}
