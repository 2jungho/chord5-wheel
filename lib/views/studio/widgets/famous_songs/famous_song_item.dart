import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FamousSongItem extends StatelessWidget {
  final String songTitle;

  const FamousSongItem({
    super.key,
    required this.songTitle,
  });

  static Future<void> launchYoutubeSearch(String query) async {
    final encoded = Uri.encodeComponent(query);
    final url = Uri.parse('https://www.youtube.com/results?search_query=$encoded');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    String title = songTitle;
    String artist = '';
    final separatorIndex = songTitle.lastIndexOf(' - ');
    if (separatorIndex != -1) {
      title = songTitle.substring(0, separatorIndex).trim();
      artist = songTitle.substring(separatorIndex + 3).trim();
    }

    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.music_note_rounded,
              size: 14, color: Theme.of(context).colorScheme.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: title,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (artist.isNotEmpty)
                  Tooltip(
                    message: artist,
                    child: Text(
                      '($artist)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconButton(
                context,
                tooltip: '원곡 듣기',
                icon: Icons.play_circle_fill,
                onTap: () => launchYoutubeSearch(songTitle),
                isPrimary: true,
              ),
              const SizedBox(width: 4),
              _buildIconButton(
                context,
                tooltip: '배킹 트랙',
                icon: Icons.graphic_eq,
                onTap: () => launchYoutubeSearch('$songTitle backing track'),
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isPrimary ? colorScheme.primary : colorScheme.surfaceDim,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPrimary
                    ? Colors.transparent
                    : colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isPrimary ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
