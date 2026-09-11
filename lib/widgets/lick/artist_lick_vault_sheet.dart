import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/lick/guitar_artist.dart';
import '../../models/lick/artist_lick_model.dart';
import '../../models/audio/band_sound_profile.dart';
import '../../providers/lick_vault_state.dart';
import '../../providers/studio_state.dart';

/// 아티스트 릭 보관함 및 인터랙티브 TAB / 화성 분석 바텀시트
class ArtistLickVaultSheet extends StatelessWidget {
  const ArtistLickVaultSheet({super.key});

  static void show(BuildContext context) {
    // 릭 보관함 초기화 및 스튜디오 세션 키 동기화
    final vault = context.read<LickVaultState>();
    final studioKey = context.read<StudioState>().session.key;
    vault.initialize();
    vault.syncKey(studioKey);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ArtistLickVaultSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vault = context.watch<LickVaultState>();
    final activeLick = vault.currentTransposedLick;
    final analysis = vault.harmonicAnalysis;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // 상단 드래그 핸들
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // 헤더 바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Artist Lick Vault',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Key: ${vault.activeKey}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 메인 스크롤 콘텐츠
          Expanded(
            child: vault.isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 14),
                        Text('아티스트 및 릭 데이터를 불러오는 중...', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
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
                        const SizedBox(height: 16),

                        // 5. 릭 카드 목록
                        _buildLickCards(context, vault),
                        const SizedBox(height: 20),

                        // 6. 대화형 TAB 뷰어
                        _buildInteractiveTabView(context, vault, activeLick),
                        const SizedBox(height: 20),

                        // 7. 이론 분석 및 연주 팁 카드
                        _buildTheoryAnalysisCard(context, activeLick, analysis),
                      ],
                    ),
                  ),
          ),

          // 하단 플레이백 & 액션 컨트롤 바
          _buildBottomActionBar(context, vault),
        ],
      ),
    );
  }

  /// 장르 카테고리 탭 선택 바
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

  /// 아티스트 가로 스크롤 칩 선택 바
  Widget _buildArtistSelector(BuildContext context, LickVaultState vault) {
    final artists = vault.filteredArtists;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: artists.map((artist) {
          final isSelected = vault.selectedArtist?.id == artist.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: CircleAvatar(
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(
                  artist.name.split(' ').map((s) => s[0]).take(2).join(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              label: Text(
                '${artist.koreanName} (${artist.name})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => vault.selectArtist(artist),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 선택된 아티스트 프로필 & 시그니처 악기 요약 배너
  Widget _buildArtistInfoBanner(BuildContext context, GuitarArtist? artist) {
    if (artist == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
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

  Widget _buildLickCards(BuildContext context, LickVaultState vault) {
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
                  color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.3),
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

  Widget _buildInteractiveTabView(BuildContext context, LickVaultState vault, ArtistLick lick) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeIndex = vault.activePlayingNoteIndex;

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
          Row(
            children: [
              const Icon(Icons.music_note, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Guitar TAB Viewer (클릭 시 단음 미리듣기)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${lick.cagedForm} | Box ${lick.pentatonicBox}',
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // TAB 6선 악보 본체
          SingleChildScrollView(
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

                        return InkWell(
                          onTap: () => vault.previewNote(note),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 38,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isPlayingThisNote
                                  ? Colors.amber.withValues(alpha: 0.35)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 38,
                                  height: 1,
                                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                                ),
                                if (isThisString)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isPlayingThisNote ? Colors.amber : colorScheme.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isPlayingThisNote
                                            ? Colors.amber
                                            : colorScheme.outlineVariant,
                                      ),
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
                                        if (note.technique.symbol.isNotEmpty)
                                          Text(
                                            note.technique.symbol,
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: isPlayingThisNote
                                                  ? Colors.black87
                                                  : colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTheoryAnalysisCard(
    BuildContext context,
    ArtistLick lick,
    ({String summary, List<String> noteAnalyses}) analysis,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, size: 20, color: colorScheme.tertiary),
              const SizedBox(width: 8),
              Text(
                '화성학적 분석 & 연주 가이드',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            analysis.summary,
            style: const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 플레이 팁 & 화성학 타겟팅:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  lick.theoryTips,
                  style: TextStyle(fontSize: 11, height: 1.4, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('음표별 화성학 역할:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 6),
          ...analysis.noteAnalyses.map(
            (noteStr) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('• $noteStr', style: const TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, LickVaultState vault) {
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
