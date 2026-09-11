import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/lick/artist_lick_model.dart';
import '../../models/progression/progression_models.dart';
import '../../providers/studio_state.dart';
import '../../providers/lick_vault_state.dart';
import '../../services/lick_analyzer_service.dart';
import '../../services/lick_audio_player.dart';
import 'artist_lick_vault_sheet.dart';

/// 코드 진행 탭(StudioView)에서 현재 타임라인의 코드 진행 및 선택 블록에 어울리는 기타 거장의 시그니처 릭을 표시하는 패널
class ProgressionLickPanel extends StatefulWidget {
  final ProgressionSession session;

  const ProgressionLickPanel({
    super.key,
    required this.session,
  });

  @override
  State<ProgressionLickPanel> createState() => _ProgressionLickPanelState();
}

class _ProgressionLickPanelState extends State<ProgressionLickPanel> {
  final LickAudioPlayer _player = LickAudioPlayer();
  String? _currentlyPlayingLickId;
  int _activePlayingNoteIndex = -1;
  NoteTechnique _activePlayingTechnique = NoteTechnique.none;
  bool _isExpanded = true;

  @override
  void dispose() {
    _player.stop();
    super.dispose();
  }

  void _togglePlayLick(ArtistLick lick) async {
    if (_currentlyPlayingLickId == lick.id && _player.isPlaying) {
      _player.stop();
      setState(() {
        _currentlyPlayingLickId = null;
        _activePlayingNoteIndex = -1;
        _activePlayingTechnique = NoteTechnique.none;
      });
    } else {
      _player.stop();
      setState(() {
        _currentlyPlayingLickId = lick.id;
        _activePlayingNoteIndex = 0;
        _activePlayingTechnique = NoteTechnique.none;
      });

      final vaultState = context.read<LickVaultState>();

      await _player.playLick(
        lick,
        soundProfileId: vaultState.selectedGuitarSound.id,
        onNoteStep: (index) {
          if (mounted) {
            setState(() {
              _activePlayingNoteIndex = index;
            });
          }
        },
        onTechniqueStep: (index, technique) {
          if (mounted) {
            setState(() {
              _activePlayingTechnique = technique;
            });
          }
        },
        onComplete: () {
          if (mounted) {
            setState(() {
              _currentlyPlayingLickId = null;
              _activePlayingNoteIndex = -1;
              _activePlayingTechnique = NoteTechnique.none;
            });
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final studio = context.watch<StudioState>();
    final vault = context.watch<LickVaultState>();

    final progression = widget.session.progression;
    final chordSymbols = progression.map((b) => b.chordSymbol).toList();

    // 선택된 특정 코드 블록
    String? selectedChord;
    if (progression.isNotEmpty &&
        studio.selectedBlockIndex >= 0 &&
        studio.selectedBlockIndex < progression.length) {
      selectedChord = progression[studio.selectedBlockIndex].chordSymbol;
    }

    final matchedLicks = LickAnalyzerService.findLicksForProgression(
      progressionChords: chordSymbols,
      selectedChord: selectedChord,
      key: widget.session.key,
      limit: 6,
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 패널 헤더
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.electric_bolt, size: 18, color: Colors.amber),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '코드 진행 매칭 거장 릭',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (selectedChord != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '포커스: $selectedChord',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          progression.isNotEmpty
                              ? '현재 진행 (${chordSymbols.join(" - ")})에 바로 솔로/필인 가능한 릭'
                              : '타임라인 진행에 어울리는 아티스트 릭',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => ArtistLickVaultSheet.show(context),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('보관함', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            const Divider(height: 1),
            if (matchedLicks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    '현재 진행에 적합한 릭을 검색 중이거나 코드가 없습니다.',
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                ),
              )
            else
              Container(
                height: 155,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: matchedLicks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final lick = matchedLicks[index];
                    final isPlaying = _currentlyPlayingLickId == lick.id;

                    return _buildProgressionLickCard(context, lick, isPlaying, vault, studio);
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressionLickCard(
    BuildContext context,
    ArtistLick lick,
    bool isPlaying,
    LickVaultState vault,
    StudioState studio,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 255,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isPlaying
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlaying
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isPlaying ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 상단 아티스트 & 재생
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            lick.artist,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lick.cagedForm,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lick.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => _togglePlayLick(lick),
                icon: Icon(
                  isPlaying ? Icons.stop : Icons.play_arrow,
                  size: 16,
                  color: isPlaying ? Colors.redAccent : colorScheme.primary,
                ),
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                ),
                tooltip: isPlaying ? '정지' : '미리듣기 (테크닉 반영)',
              ),
            ],
          ),

          // 중앙 음표 시퀀스 & 실시간 테크닉 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: lick.notes.asMap().entries.map((entry) {
                        final noteIdx = entry.key;
                        final note = entry.value;
                        final isThisNotePlaying =
                            isPlaying && _activePlayingNoteIndex == noteIdx;

                        return Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: isThisNotePlaying
                                ? Colors.amber
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isThisNotePlaying
                                  ? Colors.amber
                                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '${note.fret}${note.technique.symbol}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isThisNotePlaying
                                  ? Colors.black
                                  : colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (isPlaying && _activePlayingTechnique != NoteTechnique.none) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: Text(
                      _activePlayingTechnique.label,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 하단 버튼들: 타임라인 코드 추가 + 5대 폼 열기
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  studio.addProgressionFromText(lick.targetChord);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${lick.targetChord} 코드가 타임라인에 추가되었습니다.'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 12),
                label: Text('${lick.targetChord} 삽입', style: const TextStyle(fontSize: 10)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  visualDensity: VisualDensity.compact,
                  minimumSize: Size.zero,
                ),
              ),
              InkWell(
                onTap: () {
                  _player.stop();
                  vault.selectLick(lick);
                  ArtistLickVaultSheet.show(context);
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '5대 Box 펼치기',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios, size: 9, color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
