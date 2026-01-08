import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'audio_queue.dart';

class LyriaService {
  WebSocketChannel? _channel;
  final String _apiKey;
  final String _model = 'models/gemini-2.0-flash-exp'; // Updated to valid model

  // Audio System
  final AudioQueue _audioQueue =
      AudioQueue(sampleRate: 24000); // Gemini def: 24kHz

  // Status Stream
  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  // Connection State
  bool get isConnected => _channel != null;
  bool _isSetupComplete = false;
  bool get isReady => _isSetupComplete;

  LyriaService({required String apiKey}) : _apiKey = apiKey;

  /// Initialize Audio Player
  Future<void> _initAudio() async {
    await _audioQueue.initialize();
  }

  /// Connect to Lyria WebSocket
  Future<void> connect() async {
    if (_channel != null) return;

    try {
      _statusController.add("Connecting...");
      await _initAudio();

      final uri = Uri.parse(
          'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$_apiKey');

      _channel = WebSocketChannel.connect(uri);

      // Listen to incoming messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      // Send Setup Message
      _sendSetupMessage();

      _statusController.add("Connected");
    } catch (e, stackTrace) {
      debugPrint("Error connecting to Lyria: $e");
      debugPrint("Stack Trace:\n$stackTrace");
      _statusController.add("Connection Failed: $e");
      disconnect();
    }
  }

  void _sendSetupMessage() {
    final setupMsg = {
      "setup": {
        "model": _model,
        "generation_config": {
          "response_modalities": ["AUDIO"],
          "speech_config": {
            "voice_config": {
              "prebuilt_voice_config": {
                "voice_name": "Aoede" // Example voice
              }
            }
          }
        }
      }
    };
    sendJson(setupMsg);
  }

  void sendJson(Map<String, dynamic> data) {
    if (_channel == null) return;
    final jsonString = jsonEncode(data);
    _channel!.sink.add(jsonString);
  }

  /// Send a text prompt to generate music context
  void sendPrompt(String text) {
    if (!_isSetupComplete) {
      debugPrint("Cannot send prompt, setup not complete.");
      return;
    }

    final msg = {
      "client_content": {
        "turns": [
          {
            "role": "user",
            "parts": [
              {"text": text}
            ]
          }
        ],
        "turn_complete": true
      }
    };
    sendJson(msg);
  }

  void _onMessage(dynamic message) {
    if (message is String) {
      try {
        final data = jsonDecode(message);
        _handleServerContent(data);
      } catch (e) {
        print("Lyria JSON Parse Error: $e");
      }
    } else if (message is Uint8List) {
      // Binary message direct
      _audioQueue.addChunk(message);
    }
  }

  void _handleServerContent(Map<String, dynamic> data) {
    // Check for "serverContent" -> "modelTurn" -> "parts" -> "inlineData"

    // Also check for setupComplete at top level (sometimes)
    // Actually the protocol structure: { "serverContent": { "modelTurn": ... } }
    // Setup complete might be a separate toolUse or empty turn?
    // Let's assume after first response or specific signal.
    // Spec: "The server will send a 'setupComplete' message..." - actually it's inside serverContent usually?
    // Wait, checked docs: yes, it can be a top-level key or inside.

    // For now, if we get ANY response that is valid, consider setup done?
    // No, better check explicit keys.

    // Check top level keys
    // debugPrint("Lyria Msg: ${data.keys.toList()}");

    // Handling various message types
    if (data.containsKey('setupComplete')) {
      _isSetupComplete = true;
      _statusController.add("Setup Complete - Ready to Jam");
      return;
    }

    if (data.containsKey('serverContent')) {
      final serverContent = data['serverContent'];

      // Handle Turn Complete
      if (serverContent['turnComplete'] == true) {
        _statusController.add("Playing...");
      }

      // Handle Interrupted
      if (serverContent['interrupted'] == true) {
        _statusController.add("Interrupted");
        _audioQueue.clear();
      }

      // Handle Model Turn (Audio Data)
      if (serverContent.containsKey('modelTurn')) {
        final parts = serverContent['modelTurn']['parts'] as List?;
        if (parts != null) {
          for (var part in parts) {
            if (part is Map && part.containsKey('inlineData')) {
              final mimeType = part['inlineData']['mimeType'];
              final base64String = part['inlineData']['data'];

              if (mimeType != null && mimeType.startsWith('audio/pcm')) {
                // Decode Base64 -> Uint8List -> Audio Queue
                final bytes = base64Decode(base64String);
                _audioQueue.addChunk(bytes);
              }
            }
          }
        }
      }
    }
  }

  void _onError(error) {
    _statusController.add("Error: $error");
    disconnect();
  }

  void _onDone() {
    String reason = "Connection Closed";
    if (_channel != null) {
      reason +=
          " (Code: ${_channel!.closeCode}, Reason: ${_channel!.closeReason})";
    }
    _statusController.add(reason);
    disconnect();
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    _audioQueue.clear();
    _isSetupComplete = false;
  }
}
