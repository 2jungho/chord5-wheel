import 'package:flutter/material.dart';
import '../../../../services/youtube_metadata_service.dart';

/// Preview card displaying the AI-analyzed song chord progression, key, and commentary.
class SongSearchResultCard extends StatelessWidget {
  final Map<String, dynamic> searchResult;
  final YouTubeVideoInfo? youtubeInfo;

  const SongSearchResultCard({
    super.key,
    required this.searchResult,
    this.youtubeInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final title = searchResult['title'] ?? 'Unknown';
    final artist = searchResult['artist'] ?? 'Unknown';
    final key = searchResult['key'] ?? 'Unknown Key';
    final comment = searchResult['comment'] ?? '';
    final progression = searchResult['progression'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (youtubeInfo != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    youtubeInfo!.thumbnailUrl,
                    width: 70,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title - $artist',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Original Key: $key',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '분석된 코드 진행:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: progression.length,
            separatorBuilder: (_, __) =>
                const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
            itemBuilder: (context, index) {
              final item = progression[index];
              final chord = item['chord'] ?? '';
              final dur = item['duration'] ?? 4;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      chord,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '$dur박자',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '화성학 해설:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(comment, style: const TextStyle(fontSize: 13, height: 1.5)),
        ],
      ],
    );
  }
}
