import 'package:flutter/material.dart';
import '../../../models/lick/guitar_artist.dart';
import '../../../providers/lick_vault_state.dart';

/// 아티스트 릭 보관함 - 장르/아티스트/태그 필터 바 및 아티스트 프로필 배너
class LickFilterBar extends StatelessWidget {
  final LickVaultState vault;

  const LickFilterBar({super.key, required this.vault});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 장르 카테고리 필터
        _buildGenreSelector(context, vault),
        const SizedBox(height: 12),

        // 2. 아티스트 선택 칩 바
        _buildArtistSelector(context, vault),

        // 3. 선택된 아티스트 프로필 & 악기 배너
        _buildArtistInfoBanner(context, vault.selectedArtist),
        const SizedBox(height: 10),

        // 4. 태그 필터
        _buildTagFilters(context, vault),
      ],
    );
  }

  Widget _buildGenreSelector(BuildContext context, LickVaultState vault) {
    final genres = ['전체', ...vault.genres];
    final selected = vault.selectedGenre ?? '전체';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: genres.map((genre) {
          final isSelected = selected == genre;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                genre,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => vault.selectGenre(genre == '전체' ? null : genre),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildArtistSelector(BuildContext context, LickVaultState vault) {
    final artists = vault.allArtists.where((artist) {
      if (vault.selectedGenre == null) return true;
      return artist.genre.toLowerCase() == vault.selectedGenre!.toLowerCase();
    }).toList();

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final artist = artists[index];
          final isSelected = vault.selectedArtist?.id == artist.id;
          final colorScheme = Theme.of(context).colorScheme;

          return FilterChip(
            label: Text(artist.koreanName),
            avatar: CircleAvatar(
              backgroundColor: isSelected ? colorScheme.onPrimary : colorScheme.primaryContainer,
              child: Text(
                artist.name.substring(0, 1),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? colorScheme.primary : colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            selected: isSelected,
            onSelected: (_) => vault.selectArtist(artist),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _buildArtistInfoBanner(BuildContext context, GuitarArtist? artist) {
    if (artist == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.person, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      artist.koreanName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '• ${artist.era} • ${artist.signatureGuitar}',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  artist.bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagFilters(BuildContext context, LickVaultState vault) {
    final tags = vault.availableTags;
    if (tags.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(
            'Tags: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          ...tags.map((tag) {
            final isSelected = vault.selectedTag == tag;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(tag, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                onSelected: (_) => vault.selectTag(tag),
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
        ],
      ),
    );
  }
}
