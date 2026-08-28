import 'package:flutter/foundation.dart';
import 'web_audio_api.dart';

/// 가상 밴드 잼 세션 마이크 녹음 및 오디오 스케치북 서비스
class AudioRecorderService {
  static bool _isRecording = false;
  static bool _hasRecordedAudio = false;
  static DateTime? _recordingStartTime;

  static bool get isRecording => _isRecording;
  static bool get hasRecordedAudio => _hasRecordedAudio;
  static DateTime? get recordingStartTime => _recordingStartTime;

  /// 마이크 녹음 시작
  static Future<bool> startRecording() async {
    if (_isRecording) return true;

    if (kIsWeb) {
      final success = await WebAudioApi.startRecording();
      if (success) {
        _isRecording = true;
        _hasRecordedAudio = false;
        _recordingStartTime = DateTime.now();
        return true;
      }
      return false;
    } else {
      // Native Fallback simulation / placeholder
      _isRecording = true;
      _hasRecordedAudio = false;
      _recordingStartTime = DateTime.now();
      return true;
    }
  }

  /// 마이크 녹음 정지
  static bool stopRecording() {
    if (!_isRecording) return false;

    if (kIsWeb) {
      final success = WebAudioApi.stopRecording();
      _isRecording = false;
      _hasRecordedAudio = true;
      return success;
    } else {
      _isRecording = false;
      _hasRecordedAudio = true;
      return true;
    }
  }

  /// 녹음된 오디오 파일 다운로드 (WAV / WebM)
  static bool downloadRecording([String? customFilename]) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = customFilename ?? 'guitar_jam_sketch_$timestamp.webm';

    if (kIsWeb) {
      return WebAudioApi.downloadRecording(filename);
    }
    return false;
  }
}
