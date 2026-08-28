import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeVideoInfo {
  final String title;
  final String authorName;
  final String? authorUrl;
  final String thumbnailUrl;
  final String videoId;
  final String originalUrl;
  final String guessedTitle;
  final String guessedArtist;

  YouTubeVideoInfo({
    required this.title,
    required this.authorName,
    this.authorUrl,
    required this.thumbnailUrl,
    required this.videoId,
    required this.originalUrl,
    required this.guessedTitle,
    required this.guessedArtist,
  });
}

class YouTubeMetadataService {
  static final RegExp _youtubeUrlRegex = RegExp(
    r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/|youtube\.com\/shorts\/)([^"&?\/\s]{11})',
    caseSensitive: false,
  );

  /// Extracts YouTube 11-character video ID from URL.
  static String? extractVideoId(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    final match = _youtubeUrlRegex.firstMatch(trimmed);
    return match?.group(1);
  }

  /// Checks if string is a valid YouTube URL.
  static bool isValidYouTubeUrl(String url) {
    return extractVideoId(url) != null;
  }

  /// Fetches video title, author, and thumbnail via YouTube oEmbed API.
  static Future<YouTubeVideoInfo> fetchMetadata(String url) async {
    final videoId = extractVideoId(url);
    if (videoId == null) {
      throw Exception(
          '유효한 YouTube 동영상 URL 형식이 아닙니다.\n(예: https://youtu.be/... 또는 https://www.youtube.com/watch?v=...)');
    }

    final fallbackThumb =
        'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    final oembedUri = Uri.parse(
      'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json',
    );

    try {
      final response = await http.get(oembedUri).timeout(
            const Duration(seconds: 8),
            onTimeout: () =>
                throw Exception('YouTube 메타데이터 요청 시간이 초과되었습니다.'),
          );

      if (response.statusCode == 200) {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final rawTitle = json['title'] as String? ?? 'YouTube Video';
        final author = json['author_name'] as String? ?? '';
        final thumb = json['thumbnail_url'] as String? ?? fallbackThumb;

        final (guessedArtist, guessedTitle) =
            parseArtistAndTitle(rawTitle, author);

        return YouTubeVideoInfo(
          title: rawTitle,
          authorName: author,
          authorUrl: json['author_url'] as String?,
          thumbnailUrl: thumb,
          videoId: videoId,
          originalUrl: url,
          guessedTitle: guessedTitle,
          guessedArtist: guessedArtist,
        );
      } else {
        return YouTubeVideoInfo(
          title: 'YouTube Video ($videoId)',
          authorName: '',
          thumbnailUrl: fallbackThumb,
          videoId: videoId,
          originalUrl: url,
          guessedTitle: '',
          guessedArtist: '',
        );
      }
    } catch (_) {
      return YouTubeVideoInfo(
        title: 'YouTube Video ($videoId)',
        authorName: '',
        thumbnailUrl: fallbackThumb,
        videoId: videoId,
        originalUrl: url,
        guessedTitle: '',
        guessedArtist: '',
      );
    }
  }

  /// Parses strings like "IU - Through the Night", "[MV] IU(아이유) _ 밤편지(Through the Night)", "Official MV - Song"
  static (String artist, String title) parseArtistAndTitle(
      String rawTitle, String channelName) {
    var cleaned = rawTitle
        .replaceAll(RegExp(r'\[.*?\]'), '') // remove [MV], [Official Video]
        .replaceAll(RegExp(r'\(.*?Official.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(.*?MV.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(.*?Audio.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(.*?Live.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(.*?Cover.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(.*?가사.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(.*?Lyrics.*?\)', caseSensitive: false), '')
        .trim();

    // Check for delimiter like ' - ' or ' _ ' or ' | '
    final delimiters = [' - ', ' _ ', ' | ', ' : '];
    for (final delimiter in delimiters) {
      if (cleaned.contains(delimiter)) {
        final parts = cleaned.split(delimiter);
        if (parts.length >= 2) {
          final p0 = parts[0].trim();
          final p1 = parts.sublist(1).join(delimiter).trim();
          return (p0, p1);
        }
      }
    }

    // If no delimiter, use channelName as artist
    var cleanChannel = channelName
        .replaceAll('Official', '')
        .replaceAll('VEVO', '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .trim();
    return (cleanChannel.isNotEmpty ? cleanChannel : '', cleaned);
  }
}
