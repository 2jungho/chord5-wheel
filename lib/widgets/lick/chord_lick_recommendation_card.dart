import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/lick/artist_lick_model.dart';
import '../../providers/lick_vault_state.dart';
import '../../services/lick_analyzer_service.dart';
import '../../services/lick_audio_player.dart';
import 'artist_lick_vault_sheet.dart';

/// 선택된 코드(5도권 휠 또는 코드 분석 탭)에 가장 잘 어울리는 기타 거장의 릭을 추천하고 미리듣기를 제공하는 컴포넌트
class ChordLickRecommendationCard extends StatefulWidget {
  final String chordRoot;
  final String chordQuality;
  final String? keyContext;
  final List<ArtistLick>? pool;

  const ChordLickRecommendationCard({
    super.key,
    required this.chordRoot,
    required this.chordQuality,
    this.keyContext,
    this.pool,
  });

  @override
  State<ChordLickRecommendationCard> createState() =>
      _ChordLickRecommendationCardState();
}

class _ChordLickRecommendationCardState
    extends State<ChordLickRecommendationCard> {
  final LickAudioPlayer _player = LickAudioPlayer();
  String? _currentlyPlayingLickId;
  int _activePlayingNoteIndex = -1;
  NoteTechnique _activePlayingTechnique = NoteTechnique.none;

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
    if (widget.chordRoot.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vault = context.watch<LickVaultState>();

    // 릭 풀에서 매칭되는 릭 추천 검색
    final licksPool = widget.pool ?? (vault.allArtists.isNotEmpty ? null : null);
    final recommendedLicks = LickAnalyzerService.findLicksForChord(
      pool: licksPool,
      chordRoot: widget.chordRoot,
      chordQuality: widget.chordQuality,
      keyContext: widget.keyContext,
      limit: 4,
    );

    if (recommendedLicks.isEmpty) return const SizedBox.shrink();

    final chordSymbol = '${widget.chordRoot}${widget.chordQuality}';

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 행
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.electric_bolt, size: 18, color: Colors.amber),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$chordSymbol 추천 거장 릭',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '이 코드 위에서 연주하기 좋은 전설적인 기타리스트의 시그니처 릭',
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
                icon: const Icon(Icons.library_music, size: 14),
                label: const Text('보관함 전체', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 릭 카드 가로 리스트
          SizedBox(
            height: 145,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recommendedLicks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final lick = recommendedLicks[index];
                final isPlayingThis = _currentlyPlayingLickId == lick.id;

                return _buildLickMiniCard(context, lick, isPlayingThis, vault);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLickMiniCard(
    BuildContext context,
    ArtistLick lick,
    bool isPlaying,
    LickVaultState vault,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 250,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isPlaying
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
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
          // 상단 아티스트 정보 & 재생 버튼
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
                tooltip: isPlaying ? '정지' : '미리듣기',
              ),
            ],
          ),

          // 중앙 음표 미리보기 & 활성 테크닉 표시
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

          // 하단 보관함 열기 액션 버튼
          InkWell(
            onTap: () {
              _player.stop();
              vault.selectLick(lick);
              ArtistLickVaultSheet.show(context);
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '5대 Box 전체 보기',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios, size: 10, color: colorScheme.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
