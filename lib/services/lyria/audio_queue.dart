import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioQueue {
  final List<Uint8List> _queue = [];
  bool _isPlaying = false;

  // PCM Format (Gemini Default)
  final int sampleRate;
  final int channels;

  // AudioPlayers instance
  late final AudioPlayer _player;

  AudioQueue({this.sampleRate = 24000, this.channels = 1});

  Future<void> initialize() async {
    _player = AudioPlayer();

    // Set context for mobile/desktop if needed (not strict for web)
    // await _player.setAudioContext(AudioContext(...));

    // Ensure we don't hold session too tight?
  }

  void addChunk(Uint8List chunk) {
    if (chunk.isEmpty) return;
    _queue.add(chunk);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isPlaying) return;
    if (_queue.isEmpty) return;

    _isPlaying = true;

    try {
      while (_queue.isNotEmpty) {
        final chunk = _queue.removeAt(0);
        await _playChunk(chunk);
      }
    } catch (e) {
      debugPrint("Error playing audio chunk: $e");
    } finally {
      _isPlaying = false;
    }
  }

  Future<void> _playChunk(Uint8List pcmData) async {
    try {
      // 1. Add WAV Header
      final wavData = _createWavBuffer(pcmData);

      // 2. Create Data URI
      final base64String = base64Encode(wavData);
      final dataUri = 'data:audio/wav;base64,$base64String';

      // 3. Play
      // SourceUrl is now UrlSource in v6
      await _player.play(UrlSource(dataUri));

      // 4. Wait for completion
      // AudioPlayers play returns void/Future<void> but completes when playback *starts* (or is requested).
      // We must wait for onPlayerComplete to ensure sequential playback of the queue.
      await _player.onPlayerComplete.first;
    } catch (e) {
      debugPrint("AudioPlayers Play Error: $e");
    }
  }

  /// Adds a canonical WAV header to raw PCM data
  Uint8List _createWavBuffer(Uint8List pcmData) {
    // 16-bit audio
    final int bitsPerSample = 16;
    final int byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final int blockAlign = channels * (bitsPerSample ~/ 8);
    final int dataSize = pcmData.length;
    final int fileSize = 36 + dataSize;

    final buffer = Uint8List(44 + dataSize);
    final view = ByteData.view(buffer.buffer);

    // RIFF chunk
    _writeString(view, 0, 'RIFF');
    view.setUint32(4, fileSize, Endian.little);
    _writeString(view, 8, 'WAVE');

    // fmt chunk
    _writeString(view, 12, 'fmt ');
    view.setUint32(16, 16, Endian.little); // fmt chunk size
    view.setUint16(20, 1, Endian.little); // Audio format (1 = PCM)
    view.setUint16(22, channels, Endian.little);
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, byteRate, Endian.little);
    view.setUint16(32, blockAlign, Endian.little);
    view.setUint16(34, bitsPerSample, Endian.little);

    // data chunk
    _writeString(view, 36, 'data');
    view.setUint32(40, dataSize, Endian.little);

    // PCM Data
    buffer.setRange(44, 44 + dataSize, pcmData);

    return buffer;
  }

  void _writeString(ByteData view, int offset, String text) {
    for (int i = 0; i < text.length; i++) {
      view.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  void clear() {
    _queue.clear();
    _isPlaying = false;
    _player.stop();
  }
}
