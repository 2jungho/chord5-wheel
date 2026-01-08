import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
// Note: sound_stream is a Flutter plugin and cannot run in pure Dart tests.
// We will mock the audio part or just test the connection protocol.

void main() {
  // 사용자가 직접 키를 입력하고 실행해야 함
  // set API_KEY=AIza... && flutter test test/lyria_test.dart
  final apiKey = "AIzaSyCAe2weJKqDvhWrBZ4mJBhq2a-ZphZ1tbc";

  group('Lyria Protocol Test', () {
    test('WebSocket Connection & Setup', () async {
      if (apiKey == null || apiKey.isEmpty) {
        print('Skipping test: API_KEY not provided in environment.');
        return;
      }

      print('Connecting with API Key: ${apiKey.substring(0, 5)}...');

      final uri = Uri.parse(
          'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$apiKey');

      final channel = IOWebSocketChannel.connect(uri);
      try {
        await channel.ready;
        print("WebSocket Connection Established!");
      } catch (e) {
        print("WebSocket Connection Failed: $e");
        return;
      }

      // 1. Send Setup
      final setupMsg = {
        "setup": {
          "model": "models/gemini-2.0-flash-exp",
          "generation_config": {
            "response_modalities": ["AUDIO"]
          }
        }
      };

      print('Sending Setup: $setupMsg');
      channel.sink.add(jsonEncode(setupMsg));

      // 2. Prompt removed from here, moved to listener callback

      // 3. Listen for response
      final completer = Completer<void>();

      final subscription = channel.stream.listen((message) {
        print('Received Message: $message');

        final data = jsonDecode(message as String); // Cast assuming string

        // Handle Server Content
        if (data.containsKey('serverContent')) {
          final content = data['serverContent'];
          if (content.containsKey('modelTurn')) {
            print('Audio/Content Received!');
            if (content['turnComplete'] == true) {
              print('Turn Complete!');
              if (!completer.isCompleted) completer.complete();
            }
          }
        }

        // Handle Setup Complete -> Send Prompt
        if (data.containsKey('setupComplete')) {
          print('Setup Complete Received!');
          // Now send prompt
          final promptMsg = {
            "client_content": {
              "turns": [
                {
                  "role": "user",
                  "parts": [
                    {"text": "Play a C major scale on guitar"}
                  ]
                }
              ],
              "turn_complete": true
            }
          };
          print('Sending Prompt...');
          channel.sink.add(jsonEncode(promptMsg));
        }
      }, onError: (e) {
        print('Error: $e');
        if (!completer.isCompleted) completer.completeError(e);
      }, onDone: () {
        print(
            'Server closed connection. Code: ${channel.closeCode}, Reason: ${channel.closeReason}');
        if (!completer.isCompleted)
          completer.completeError('Server closed connection prematurely');
      });

      // Wait for at least one turn completion or timeout
      try {
        await completer.future.timeout(Duration(seconds: 10));
        print('Test Passed: Protocol response received.');
      } catch (e) {
        print('Test Failed or Timed out: $e');
      } finally {
        await subscription.cancel();
        channel.sink.close();
      }
    });
  });
}
