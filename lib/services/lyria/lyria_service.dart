import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'audio_queue.dart';

class LyriaService {
  WebSocketChannel? _channel;
  final String _apiKey;
  final String _model = 'models/lyria-realtime-exp';

  // Audio System (Lyria RealTime: 48kHz Stereo)
  final AudioQueue _audioQueue = AudioQueue(sampleRate: 48000, channels: 2);

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

      // Send Setup Message for Lyria RealTime
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

  /// Configure real-time music parameters (BPM, Temperature, Scale, Density)
  void setMusicGenerationConfig({
    required int bpm,
    double temperature = 1.0,
    String? scale,
    double? density,
  }) {
    final Map<String, dynamic> config = {
      "bpm": bpm,
      "temperature": temperature,
    };
    if (scale != null) config["scale"] = scale;
    if (density != null) config["density"] = density;

    final msg = {
      "music_generation_config": config,
    };
    sendJson(msg);
  }

  /// Set or update weighted prompts for real-time steering/morphing
  void setWeightedPrompts(List<Map<String, dynamic>> prompts) {
    final msg = {
      "weighted_prompts": prompts,
    };
    sendJson(msg);
  }

  /// Start playing the music generation stream
  void play() {
    final msg = {
      "play": {}
    };
    sendJson(msg);
    _statusController.add("Playing...");
  }

  /// Pause music generation stream
  void pause() {
    final msg = {
      "pause": {}
    };
    sendJson(msg);
    _statusController.add("Paused");
  }

  /// Stop playback and clear audio queue
  void stopPlayback() {
    final msg = {
      "stop": {}
    };
    sendJson(msg);
    _audioQueue.clear();
    _statusController.add("Stopped");
  }

  /// Send a text prompt (convenience wrapper for weighted prompts / fallback)
  void sendPrompt(String text) {
    setWeightedPrompts([
      {"text": text, "weight": 1.0}
    ]);
  }

  void _onMessage(dynamic message) {
    if (message is String) {
      try {
        final data = jsonDecode(message);
        _handleServerContent(data);
      } catch (e) {
        debugPrint("Lyria JSON Parse Error: $e");
      }
    } else if (message is Uint8List) {
      // Binary message direct
      _audioQueue.addChunk(message);
    }
  }

  void _handleServerContent(Map<String, dynamic> data) {
    // Check for setupComplete signal
    if (data.containsKey('setupComplete')) {
      _isSetupComplete = true;
      _statusController.add("Setup Complete - Ready to Jam");
      return;
    }

    // 1. Direct audioChunks at top level or inside serverContent
    final audioChunks = data['audioChunks'] ?? (data['serverContent'] is Map ? data['serverContent']['audioChunks'] : null);
    if (audioChunks is List) {
      for (var chunk in audioChunks) {
        if (chunk is Map && chunk.containsKey('data')) {
          final base64String = chunk['data'] as String;
          final bytes = base64Decode(base64String);
          _audioQueue.addChunk(bytes);
        }
      }
      _isSetupComplete = true;
      return;
    }

    // 2. Handle serverContent wrapper
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
        _isSetupComplete = true;
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

  void _onError(Object error) {
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

  void setVolume(double volume) {
    _audioQueue.setVolume(volume);
  }
}
