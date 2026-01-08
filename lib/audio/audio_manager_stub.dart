import 'web_audio_api.dart';
import 'dart:async';
import '../utils/theory_utils.dart';

/// This is the web-only implementation of AudioManager.
/// It does not import flutter_soloud and relies on JavaScript for audio.
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  bool _isReady = false;

  Future<void> initialize() async {
    if (_isReady) return;
    print("AudioManager (Web): Audio is ready.");
    _isReady = true;
  }

  Future<void> playNote(String noteName, int octave) async {
    if (!_isReady) return;
    WebAudioApi.playNote(noteName, octave);
  }

  void playChordBlock(List<String> notes) {
    if (!_isReady) return;
    int currentOctave = 3;
    int lastIndex = -1;
    for (String note in notes) {
      final idx = TheoryUtils.getNoteIndex(note);
      if (idx <= lastIndex) {
        currentOctave++;
      }
      playNote(note, currentOctave);
      lastIndex = idx;
    }
  }

  Future<void> playStrum(List<String> notes) async {
    if (!_isReady) return;
    int currentOctave = 3;
    int lastIndex = -1;
    for (String note in notes) {
      final idx = TheoryUtils.getNoteIndex(note);
      if (idx <= lastIndex) {
        currentOctave++;
      }
      playNote(note, currentOctave);
      lastIndex = idx;
      await Future.delayed(const Duration(milliseconds: 40));
    }
  }

  // --- Phase 2: High Precision Scheduling ---
  void startProgression(int bpm, String progressionJson) {
    if (!_isReady) return;
    WebAudioApi.scheduleSequence(bpm, progressionJson);
  }

  void stopProgression() {
    if (!_isReady) return;
    WebAudioApi.stop();
  }

  void updateBpm(int bpm) {
    if (!_isReady) return;
    WebAudioApi.setBpm(bpm);
  }

  void setInstrument(String instrumentId) {
    if (!_isReady) return;
    WebAudioApi.setInstrument(instrumentId);
  }

  void dispose() {
    stopProgression();
    print("AudioManager (Web): Disposing resources.");
  }
}
