import 'package:flutter/material.dart';
import '../../../models/lick/artist_lick_model.dart';
import '../../../providers/lick_vault_state.dart';
import '../../../services/lick_analyzer_service.dart';

/// 아티스트 릭 보관함 - 대화형 Guitar TAB 뷰어 & 5대 Box 운지 변환기
class InteractiveTabViewer extends StatelessWidget {
  final LickVaultState vault;
  final ArtistLick activeLick;

  const InteractiveTabViewer({
    super.key,
    required this.vault,
    required this.activeLick,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 상단 헤더 행: 타이틀 + 실시간 테크닉 뱃지 + 5대 폼 펼쳐보기 토글 버튼
          Row(
            children: [
              const Icon(Icons.music_note, size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Guitar TAB Viewer (클릭 시 단음 미리듣기)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (vault.activePlayingTechnique != NoteTechnique.none) ...[
                _buildActiveTechniqueBadge(context, vault.activePlayingTechnique),
                const SizedBox(width: 8),
              ],
              InkWell(
                onTap: () => vault.toggleAllBoxesMode(),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: vault.isAllBoxesMode
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: vault.isAllBoxesMode
                          ? colorScheme.primary
                          : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        vault.isAllBoxesMode ? Icons.view_agenda : Icons.view_agenda_outlined,
                        size: 13,
                        color: vault.isAllBoxesMode ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vault.isAllBoxesMode ? '단일 폼 접기' : '5대 폼 전체 펼치기',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: vault.isAllBoxesMode ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. 5대 CAGED Box 1 ~ Box 5 탭 셀렉터 바
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: LickAnalyzerService.cagedBoxDefinitions.map((def) {
                final isSelected = vault.selectedBox == def.boxNumber;
                final isOriginal = def.boxNumber == vault.selectedLick.pentatonicBox;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => vault.selectBox(def.boxNumber),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Icon(Icons.check, size: 13, color: colorScheme.onPrimary),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            def.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                            ),
                          ),
                          if (isOriginal) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.black.withValues(alpha: 0.25)
                                    : colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '원곡',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // 3. TAB 6선 악보 (단일 폼 모드 vs 5대 폼 모두 펼쳐보기 모드)
          if (!vault.isAllBoxesMode) ...[
            _buildSingleTabStaff(context, vault, activeLick),
          ] else ...[
            ...LickAnalyzerService.cagedBoxDefinitions.map((def) {
              final boxLick = vault.getLickForBox(def.boxNumber);
              final isCurrent = vault.selectedBox == def.boxNumber;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? colorScheme.primary.withValues(alpha: 0.05)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent
                        ? colorScheme.primary.withValues(alpha: 0.4)
                        : colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCurrent ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            def.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? colorScheme.onPrimary : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          def.description,
                          style: TextStyle(fontSize: 10, color: colorScheme.outline),
                        ),
                        const Spacer(),
                        if (!isCurrent)
                          TextButton.icon(
                            onPressed: () => vault.selectBox(def.boxNumber),
                            icon: const Icon(Icons.touch_app, size: 14),
                            label: const Text('이 폼 선택', style: TextStyle(fontSize: 10)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSingleTabStaff(context, vault, boxLick),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleTabStaff(BuildContext context, LickVaultState vault, ArtistLick lick) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeIndex = vault.activePlayingNoteIndex;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(6, (stringIndex) {
          // stringIndex 0 = 1번줄(고음 E), 5 = 6번줄(저음 E)
          final stringNumber = stringIndex + 1;
          const stringNames = ['e', 'B', 'G', 'D', 'A', 'E'];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    stringNames[stringIndex],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  width: 12,
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
                ...lick.notes.asMap().entries.map((entry) {
                  final noteIndex = entry.key;
                  final note = entry.value;
                  final isThisString = note.string == stringNumber;
                  final isPlayingThisNote = activeIndex == noteIndex;

                  Color techColor = Colors.amber;
                  if (note.technique == NoteTechnique.bendFull ||
                      note.technique == NoteTechnique.bendHalf ||
                      note.technique == NoteTechnique.bend1Half) {
                    techColor = Colors.orange;
                  } else if (note.technique == NoteTechnique.slide) {
                    techColor = Colors.cyan;
                  } else if (note.technique == NoteTechnique.hammer) {
                    techColor = Colors.green;
                  } else if (note.technique == NoteTechnique.pull) {
                    techColor = Colors.purpleAccent;
                  }

                  return InkWell(
                    onTap: () => vault.previewNote(note),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 42,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isPlayingThisNote
                            ? techColor.withValues(alpha: 0.35)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: isPlayingThisNote
                            ? Border.all(color: techColor, width: 1.5)
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 42,
                            height: 1,
                            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                          if (isThisString)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isPlayingThisNote ? techColor : colorScheme.surface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isPlayingThisNote
                                      ? techColor
                                      : colorScheme.outlineVariant,
                                ),
                                boxShadow: isPlayingThisNote
                                    ? [
                                        BoxShadow(
                                          color: techColor.withValues(alpha: 0.5),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${note.fret}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isPlayingThisNote
                                          ? Colors.black
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                  if (note.technique.symbol.isNotEmpty) ...[
                                    const SizedBox(width: 1),
                                    Text(
                                      note.technique.symbol,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isPlayingThisNote
                                            ? Colors.black
                                            : colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveTechniqueBadge(BuildContext context, NoteTechnique tech) {
    if (tech == NoteTechnique.none) return const SizedBox.shrink();
    Color badgeColor;
    IconData icon;
    String label;
    switch (tech) {
      case NoteTechnique.bendFull:
        badgeColor = Colors.orange;
        icon = Icons.north_east;
        label = 'Full Bend (+2)';
        break;
      case NoteTechnique.bendHalf:
        badgeColor = Colors.amber;
        icon = Icons.north;
        label = 'Half Bend (+1)';
        break;
      case NoteTechnique.bend1Half:
        badgeColor = Colors.deepOrange;
        icon = Icons.north_east;
        label = '1.5 Bend (+3)';
        break;
      case NoteTechnique.slide:
        badgeColor = Colors.cyan;
        icon = Icons.trending_up;
        label = 'Slide (/)';
        break;
      case NoteTechnique.hammer:
        badgeColor = Colors.green;
        icon = Icons.arrow_upward;
        label = 'Hammer-on (h)';
        break;
      case NoteTechnique.pull:
        badgeColor = Colors.purpleAccent;
        icon = Icons.arrow_downward;
        label = 'Pull-off (p)';
        break;
      case NoteTechnique.vibrato:
        badgeColor = Colors.teal;
        icon = Icons.waves;
        label = 'Vibrato (~)';
        break;
      default:
        badgeColor = Colors.blue;
        icon = Icons.music_note;
        label = tech.label;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
