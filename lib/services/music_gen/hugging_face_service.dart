import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'music_generator_service.dart';

class HuggingFaceService implements MusicGeneratorService {
  final String? token;

  // Update 5: Gemini Gems and Lyria are not available for API-based audio generation.
  // Reverting to Hugging Face, trying 'facebook/musicgen-melody'.
  // This model is often more stable on the Inference API than 'small'.
  static const String _baseUrl =
      'https://api-inference.huggingface.co/models/facebook/musicgen-melody';

  HuggingFaceService({this.token});

  @override
  Future<File?> generateMusic({
    required String prompt,
    int duration = 10,
    void Function(String message)? onStatusChanged,
  }) async {
    if (kIsWeb) {
      onStatusChanged
          ?.call('Error: Web 환경에서는 보안 정책으로 인해 Hugging Face API 직접 호출이 불가능합니다.\n'
              'Windows 앱으로 실행하거나, CORS 해제 옵션을 켜고 실행해주세요.');
      return null;
    }
    return _generateWithRetry(prompt, onStatusChanged, 0);
  }

  Future<File?> _generateWithRetry(
    String prompt,
    void Function(String message)? onStatusChanged,
    int attempt,
  ) async {
    const int maxRetries = 3;

    try {
      final uri = Uri.parse(_baseUrl);

      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty)
          'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'inputs': prompt,
      });

      onStatusChanged?.call('Generating music... (Attempt ${attempt + 1})');

      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        // Success
        onStatusChanged?.call('Download complete. Saving file...');
        final bytes = response.bodyBytes;

        final dir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        // MusicGen usually returns FLAC by default
        final file = File('${dir.path}/musicgen_$timestamp.flac');

        await file.writeAsBytes(bytes);
        onStatusChanged?.call('Music generated successfully!');
        return file;
      } else if (response.statusCode == 503) {
        // Cold Boot / Loading
        final responseBody = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(responseBody);

        double waitTime = 20.0; // Default wait
        if (jsonResponse is Map && jsonResponse.containsKey('estimated_time')) {
          waitTime = (jsonResponse['estimated_time'] as num).toDouble();
        }

        if (attempt < maxRetries) {
          onStatusChanged?.call(
              'Model is loading. Waiting ${waitTime.toStringAsFixed(1)}s...');
          await Future.delayed(
              Duration(milliseconds: (waitTime * 1000).toInt()));
          return _generateWithRetry(prompt, onStatusChanged, attempt + 1);
        } else {
          onStatusChanged?.call('Error: Model loading took too long.');
          return null;
        }
      } else if (response.statusCode == 410) {
        // 410 Gone Error Handling
        onStatusChanged?.call(
            'Error 410: Selected Model (musicgen-medium) is not available.\n'
            'This might be due to HF API changes. Please check updates.');
        return null;
      } else {
        // Other Errors
        onStatusChanged?.call('Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      onStatusChanged?.call('Exception: $e');
      return null;
    }
  }
}
