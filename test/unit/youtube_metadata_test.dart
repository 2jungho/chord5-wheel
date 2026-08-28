import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/services/youtube_metadata_service.dart';

void main() {
  group('YouTubeMetadataService Tests', () {
    test('extractVideoId accurately parses various YouTube URL patterns', () {
      expect(
        YouTubeMetadataService.extractVideoId(
            'https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        YouTubeMetadataService.extractVideoId(
            'https://youtu.be/dQw4w9WgXcQ?si=abcdefg'),
        'dQw4w9WgXcQ',
      );
      expect(
        YouTubeMetadataService.extractVideoId(
            'https://www.youtube.com/shorts/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        YouTubeMetadataService.extractVideoId('invalid_url'),
        isNull,
      );
    });

    test('parseArtistAndTitle splits delimiter-based titles', () {
      final (artist1, title1) = YouTubeMetadataService.parseArtistAndTitle(
        '[MV] IU(아이유) _ Through the Night(밤편지)',
        '1theK',
      );
      expect(artist1, contains('IU'));
      expect(title1, contains('밤편지'));

      final (artist2, title2) = YouTubeMetadataService.parseArtistAndTitle(
        'The Beatles - Let It Be (Official Music Video)',
        'TheBeatlesVEVO',
      );
      expect(artist2, 'The Beatles');
      expect(title2, 'Let It Be');
    });
  });
}
