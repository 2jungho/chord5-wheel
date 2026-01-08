import 'dart:async';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../utils/theory_utils.dart';

/// This is the native (Android, iOS) implementation of AudioManager.
/// It uses the flutter_soloud package for audio playback.
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // Make _soLoud nullable and initialize it lazily to prevent web crash during build.
  SoLoud? _soLoud;
  bool _isReady = false;

  final Map<String, AudioSource> _noteSounds = {};
  final List<String> _noteNames = const [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B'
  ];
  final List<int> _octavesToLoad = const [
    2,
    3,
    4,
    5
  ]; // Pre-load octaves 2-5 to cover guitar range and prevent lag.
  final Map<String, String> _noteNameToFileSafeMap = const {
    'C': 'C',
    'C#': 'CSharp',
    'D': 'D',
    'D#': 'DSharp',
    'E': 'E',
    'F': 'F',
    'F#': 'FSharp',
    'G': 'G',
    'G#': 'GSharp',
    'A': 'A',
    'A#': 'ASharp',
    'B': 'B',
    // Flat equivalents
    'Db': 'CSharp',
    'Eb': 'DSharp',
    'Gb': 'FSharp',
    'Ab': 'GSharp',
    'Bb': 'ASharp',
    'Cb': 'B',
    'Fb': 'E',
    'E#': 'F',
    'B#': 'C',
  };

  Future<void> initialize() async {
    if (_isReady) return;

    try {
      // Lazily initialize SoLoud instance.
      _soLoud = SoLoud.instance;
      await _soLoud!.init();
      _soLoud!.setGlobalVolume(1.0);
      print("AudioManager (Native): SoLoud initialized and volume set.");

      print("AudioManager (Native): Pre-loading essential sounds...");
      int loadedCount = 0;

      for (final octave in _octavesToLoad) {
        for (final noteName in _noteNames) {
          final fileSafeNoteName = _noteNameToFileSafeMap[noteName]!;
          final noteId = '$noteName$octave';
          final soundPath = 'assets/sounds/$fileSafeNoteName$octave.mp3';

          try {
            final source = await _soLoud!.loadAsset(soundPath);
            _noteSounds[noteId] = source;
            loadedCount++;
          } catch (e) {
            // Expected if some non-essential files are missing.
          }
        }
      }

      if (loadedCount > 0) {
        _isReady = true;
        print(
            'AudioManager (Native): Audio System Ready. $loadedCount sounds pre-loaded.');
      } else {
        print(
            'AudioManager (Native): WARNING - No sound files were pre-loaded.');
      }
    } catch (e) {
      print('AudioManager (Native): FATAL - Error initializing SoLoud: $e');
    }
  }

  Future<void> playNote(String noteName, int octave) async {
    if (!_isReady || _soLoud == null) return;

    final noteId = '$noteName$octave';
    var soundToPlay = _noteSounds[noteId];

    if (soundToPlay == null) {
      if (!_noteNameToFileSafeMap.containsKey(noteName)) {
        print('AudioManager (Native): ERROR - Unknown note name "$noteName".');
        return;
      }
      final fileSafeNoteName = _noteNameToFileSafeMap[noteName]!;
      final soundPath = 'assets/sounds/$fileSafeNoteName$octave.mp3';
      print('AudioManager (Native): Attempting to load "$noteId" on-demand...');

      try {
        final newSource = await _soLoud!.loadAsset(soundPath);
        _noteSounds[noteId] = newSource;
        soundToPlay = newSource;
        print(
            'AudioManager (Native): Successfully loaded "$noteId" on-demand.');
      } catch (e) {
        print(
            'AudioManager (Native): ERROR - Could not load sound for "$noteId".');
        return;
      }
    }

    // Reduce volume to 50% to prevent clipping when multiple notes are played together (Chord)
    final handle = await _soLoud!.play(soundToPlay, volume: 0.5);
    if (handle.id <= 0) {
      print(
          'AudioManager (Native): ERROR - Failed to play sound for "$noteId".');
    }
  }

  void playChordBlock(List<String> notes) {
    if (!_isReady) return;
    int currentOctave = 3;
    int lastIndex = -1;
    for (String note in notes) {
      int idx = TheoryUtils.getNoteIndex(note);
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
      int idx = TheoryUtils.getNoteIndex(note);
      if (idx <= lastIndex) currentOctave++;
      playNote(note, currentOctave);
      lastIndex = idx;
      await Future.delayed(const Duration(milliseconds: 40));
    }
  }

  // --- Phase 2: High Precision Scheduling ---
  void startProgression(int bpm, String progressionJson) {
    // Native implementation for progression scheduling can be added here in Phase 4.
    print("AudioManager (Native): Progression scheduling not yet implemented.");
  }

  void stopProgression() {
    print("AudioManager (Native): Stopping progression.");
  }

  void updateBpm(int bpm) {
    print("AudioManager (Native): BPM updated to $bpm.");
  }

  void dispose() {
    print("AudioManager (Native): Disposing resources.");
    _soLoud?.deinit();
  }

  void setInstrument(String instrumentId) {
    // Native implementation ignores instrument for now (Web App feature)
  }
}
