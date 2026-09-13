import 'package:flutter/material.dart';
import '../../../../services/youtube_metadata_service.dart';

/// Tab content for searching and loading YouTube song metadata.
class YouTubeSearchTab extends StatelessWidget {
  final TextEditingController urlController;
  final TextEditingController titleController;
  final TextEditingController artistController;
  final YouTubeVideoInfo? youtubeInfo;
  final bool isFetching;
  final VoidCallback onFetch;
  final VoidCallback onClear;

  const YouTubeSearchTab({
    super.key,
    required this.urlController,
    required this.titleController,
    required this.artistController,
    required this.youtubeInfo,
    required this.isFetching,
    required this.onFetch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // YouTube URL Input Row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'YouTube 동영상 URL',
                  hintText: 'https://youtu.be/... 또는 https://www.youtube.com/watch?v=...',
                  prefixIcon: const Icon(Icons.link, color: Colors.redAccent),
                  suffixIcon: urlController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: onClear,
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => onFetch(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: isFetching ? null : onFetch,
              icon: isFetching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: const Text('영상 확인'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Video Preview Card if loaded
        if (youtubeInfo != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        youtubeInfo!.thumbnailUrl,
                        width: 120,
                        height: 75,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 120,
                          height: 75,
                          color: Colors.black26,
                          child: const Icon(Icons.movie, color: Colors.white54),
                        ),
                      ),
                      const Icon(
                        Icons.play_circle_filled,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        youtubeInfo!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        youtubeInfo!.authorName,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '감지: ${titleController.text} (${artistController.text})',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Editable parsed fields
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '곡 제목 (필수)',
                  hintText: '영상 제목에서 자동 추출',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: artistController,
                decoration: const InputDecoration(
                  labelText: '가수명 (선택)',
                  hintText: '채널/가수명',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
