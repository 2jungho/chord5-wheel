import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/progression/progression_models.dart';
import '../../../../providers/settings_state.dart';
import '../../../../widgets/common/ai/quota_error_widget.dart';
import 'famous_song_info_box.dart';
import 'famous_song_item.dart';

class FamousSongsAiSearchView extends StatelessWidget {
  final ProgressionSession session;
  final Map<String, List<String>>? aiGeneratedSongs;
  final bool isGenerating;
  final String? aiErrorMessage;
  final String? selectedGenre;
  final bool isExpanded;
  final bool hasMatchedPreset;
  final ValueChanged<String> onGenreSelected;
  final VoidCallback onToggleExpanded;
  final VoidCallback onBackToDb;
  final VoidCallback onFetchFromAi;

  const FamousSongsAiSearchView({
    super.key,
    required this.session,
    required this.aiGeneratedSongs,
    required this.isGenerating,
    required this.aiErrorMessage,
    required this.selectedGenre,
    required this.isExpanded,
    required this.hasMatchedPreset,
    required this.onGenreSelected,
    required this.onToggleExpanded,
    required this.onBackToDb,
    required this.onFetchFromAi,
  });

  @override
  Widget build(BuildContext context) {
    if (aiGeneratedSongs != null && aiGeneratedSongs!.isNotEmpty) {
      final genres = aiGeneratedSongs!.keys.toList();
      final effectiveGenre = (selectedGenre != null && genres.contains(selectedGenre))
          ? selectedGenre!
          : genres.first;
      final currentSongs = (aiGeneratedSongs![effectiveGenre] ?? []).take(5).toList();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(builder: (context, headerConstraints) {
              final isNarrow = headerConstraints.maxWidth < 600;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI가 찾은 유명 곡',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildAiBadge(context),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: onToggleExpanded,
                        tooltip: isExpanded ? '접기' : '펴기',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (isNarrow) ...[
                        const FamousSongModelBadge(),
                        const SizedBox(width: 8),
                      ],
                      if (hasMatchedPreset)
                        _buildBackToDbButton(context),
                      const Spacer(),
                      _buildGenreDropdown(context, genres, effectiveGenre),
                      const SizedBox(width: 8),
                      _buildRegenerateButton(context),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: !isExpanded
                  ? const SizedBox.shrink()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 850;

                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSongList(currentSongs),
                              const SizedBox(height: 16),
                              FamousSongInfoBox(session: session, isMobile: true),
                            ],
                          );
                        }

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _buildSongList(currentSongs)),
                              const SizedBox(width: 24),
                              FamousSongInfoBox(session: session, isMobile: false),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (aiErrorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: QuotaErrorWidget.isQuotaErrorDetected(aiErrorMessage!)
                    ? QuotaErrorWidget(
                        errorMessage: aiErrorMessage!,
                        onRetry: onFetchFromAi,
                      )
                    : Text(
                        aiErrorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
              ),
          ],
        ),
      );
    }

    final settings = context.watch<SettingsState>();
    final bool hasApiKey = settings.currentApiKey.isNotEmpty;
    final bool hasProgression = session.progression.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.queue_music,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '이 코드 진행이 쓰인 유명 곡 (Famous Songs)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const FamousSongModelBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHigh
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(builder: (context, promoConstraints) {
              final isPromoNarrow = promoConstraints.maxWidth < 450;
              return Row(
                children: [
                  if (!isPromoNarrow) ...[
                    Icon(
                      Icons.smart_toy_outlined,
                      size: 32,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '알려진 프리셋 진행이 아닙니다.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          !hasProgression
                              ? '먼저 코드 진행을 입력해주세요.'
                              : hasApiKey
                                  ? 'AI를 통해 이 진행이 사용된 곡을 찾아볼까?'
                                  : 'AI 기능을 사용하려면 설정에서 API 키를 입력해주세요.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (aiErrorMessage != null &&
                      QuotaErrorWidget.isQuotaErrorDetected(aiErrorMessage!))
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: QuotaErrorWidget(
                        errorMessage: aiErrorMessage!,
                        onRetry: onFetchFromAi,
                      ),
                    )
                  else ...[
                    SizedBox(
                      height: 40,
                      child: FilledButton.icon(
                        onPressed: isGenerating
                            ? null
                            : (hasApiKey && hasProgression ? onFetchFromAi : null),
                        icon: isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 16),
                        label: Text(
                          isPromoNarrow
                              ? (isGenerating ? '찾는 중...' : 'AI 찾기')
                              : (isGenerating ? '곡 찾는 중...' : 'AI로 유명곡 찾기'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList(List<String> songs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: songs.map((songTitle) => FamousSongItem(songTitle: songTitle)).toList(),
    );
  }

  Widget _buildAiBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'BETA',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildBackToDbButton(BuildContext context) {
    return SizedBox(
      height: 28,
      child: TextButton.icon(
        onPressed: onBackToDb,
        icon: const Icon(Icons.storage_rounded, size: 14),
        label: const Text('기본 유명곡 보기', style: TextStyle(fontSize: 11)),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.secondary,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor:
              Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _buildGenreDropdown(
    BuildContext context,
    List<String> genres,
    String effectiveGenre,
  ) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveGenre,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          items: genres.map((String genre) {
            return DropdownMenuItem<String>(
              value: genre,
              child: Row(
                children: [
                  Icon(Icons.library_music,
                      size: 14, color: Theme.of(context).colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Text(genre),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onGenreSelected(newValue);
            }
          },
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
      ),
    );
  }

  Widget _buildRegenerateButton(BuildContext context) {
    return IconButton(
      onPressed: isGenerating ? null : onFetchFromAi,
      icon: isGenerating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh, size: 20),
      tooltip: '다시 찾기',
    );
  }
}
