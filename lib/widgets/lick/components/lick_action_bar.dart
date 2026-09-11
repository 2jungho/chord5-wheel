import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/audio/band_sound_profile.dart';
import '../../../providers/lick_vault_state.dart';
import '../../../providers/studio_state.dart';

/// 아티스트 릭 보관함 - 하단 재생 속도 / 톤 프리셋 / 재생 / 타임라인 삽입 액션 바
class LickActionBar extends StatelessWidget {
  final LickVaultState vault;

  const LickActionBar({super.key, required this.vault});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          // 템포 / 배속 선택
          PopupMenuButton<double>(
            initialValue: vault.playbackSpeed,
            tooltip: '재생 배속 설정',
            onSelected: (speed) => vault.setPlaybackSpeed(speed),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed, size: 15),
                  const SizedBox(width: 3),
                  Text('${vault.playbackSpeed}x', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0.5, child: Text('0.5x (슬로우 연습)')),
              const PopupMenuItem(value: 0.75, child: Text('0.75x (미디엄 연습)')),
              const PopupMenuItem(value: 1.0, child: Text('1.0x (원곡 템포)')),
            ],
          ),
          const SizedBox(width: 8),

          // 기타 사운드 선택 (통기타, 나일론, 클린, 오버드라이브, 디스토션)
          PopupMenuButton<SoundProfile>(
            initialValue: vault.selectedGuitarSound,
            tooltip: '기타 사운드 / 톤 선택',
            onSelected: (profile) => vault.selectGuitarSound(profile),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.25),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(vault.selectedGuitarSound.icon, size: 15, color: colorScheme.primary),
                  const SizedBox(width: 5),
                  Text(
                    vault.selectedGuitarSound.shortName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down, size: 16, color: colorScheme.primary),
                ],
              ),
            ),
            itemBuilder: (context) => vault.availableGuitarSounds.map((profile) {
              final isSelected = profile.id == vault.selectedGuitarSound.id;
              return PopupMenuItem<SoundProfile>(
                value: profile,
                child: SizedBox(
                  width: 250,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.15)
                              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          profile.icon,
                          size: 18,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  profile.shortName,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? colorScheme.primary : null,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  profile.genreTag.split('/').first.trim(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle_rounded, size: 16, color: colorScheme.primary),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),

          // 재생 / 정지 버튼
          Expanded(
            child: FilledButton.icon(
              onPressed: () => vault.togglePlay(),
              icon: Icon(vault.isPlaying ? Icons.stop : Icons.play_arrow, size: 18),
              label: Text(
                vault.isPlaying ? '정지' : '릭 재생',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 스튜디오 타임라인에 코드 추가
          OutlinedButton.icon(
            onPressed: () {
              final studio = context.read<StudioState>();
              vault.insertLickChordIntoStudio(studio);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('\'${vault.currentTransposedLick.targetChord}\' 코드가 스튜디오 타임라인에 추가되었습니다.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.add_box_outlined, size: 15),
            label: const Text('코드 삽입', style: TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
