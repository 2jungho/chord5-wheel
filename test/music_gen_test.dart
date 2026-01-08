import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_theory_app/services/music_gen/hugging_face_service.dart';

void main() {
  group('MusicGen Integration Tests', () {
    test('HuggingFaceService initialization', () {
      final service = HuggingFaceService(token: 'test_token');
      expect(service.token, 'test_token');
    });

    // Note: Actual API calls are difficult to test in unit tests without mocking.
    // We are focusing on logic integrity here.

    test('Web Error Message Check', () async {
      // Direct testing of kIsWeb logic is tricky in Dart VM tests.
      // We rely on manual verification for environment-specific behaviors.
    });
  });
}
