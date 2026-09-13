import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/lick/artist_lick_model.dart';
import '../../providers/lick_vault_state.dart';
import '../../services/lick_analyzer_service.dart';
import '../../services/lick_audio_player.dart';
import 'artist_lick_vault_sheet.dart';
import 'components/mini_lick_player_card.dart';

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

                return MiniLickPlayerCard(
                  lick: lick,
                  isPlaying: isPlayingThis,
                  activeNoteIndex: _activePlayingNoteIndex,
                  activeTechnique: _activePlayingTechnique,
                  onTogglePlay: () => _togglePlayLick(lick),
                  onOpenVault: () {
                    _player.stop();
                    vault.selectLick(lick);
                    ArtistLickVaultSheet.show(context);
                  },
                  vaultActionText: '5대 Box 전체 보기',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
