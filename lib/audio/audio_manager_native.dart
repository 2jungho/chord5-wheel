import 'dart:async';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../models/chord_model.dart';
import '../utils/theory_utils.dart';

/// This is the native (Android, iOS, Windows, macOS, Linux) implementation of AudioManager.
/// It uses the flutter_soloud package for audio playback.
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  SoLoud? _soLoud;
  bool _isReady = false;

  final Map<String, AudioSource> _noteSounds = {};

  // Standard note names & file map
  static const Map<String, String> _noteNameToFileSafeMap = {
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

  // Set of exact sound files available in assets/sounds/
  static const Set<String> _availableSoundFiles = {
    'A2', 'A3', 'A4',
    'ASharp2', 'ASharp3', 'ASharp4',
    'B2', 'B3', 'B4',
    'C3', 'C4',
    'CSharp3', 'CSharp4',
    'D3', 'D4', 'D5',
    'DSharp3', 'DSharp4', 'DSharp5',
    'E2', 'E3', 'E4', 'E5',
    'F2', 'F3', 'F4',
    'FSharp2', 'FSharp3', 'FSharp4',
    'G2', 'G3', 'G4', 'G5',
    'GSharp2', 'GSharp3', 'GSharp4', 'GSharp5',
  };

  Future<void> _ensureReady() async {
    if (!_isReady) {
      await initialize();
    }
  }

  Future<void> initialize() async {
    if (_isReady) return;

    try {
      _soLoud = SoLoud.instance;
      await _soLoud!.init();
      _soLoud!.setGlobalVolume(1.0);

      for (final soundId in _availableSoundFiles) {
        final soundPath = 'assets/sounds/$soundId.mp3';
        try {
          final source = await _soLoud!.loadAsset(soundPath);
          _noteSounds[soundId] = source;
        } catch (_) {
          // Non-critical if individual sound fails to load
        }
      }

      _isReady = true;
    } catch (e) {
      // Allow re-trying on next user action if init failed
      _isReady = false;
    }
  }

  /// Resolve (fileSafeNote, octave) to an existing sound file, falling back to closest octave
  String? _resolveSoundId(String fileSafeNote, int octave) {
    // 1. Exact match
    final exact = '$fileSafeNote$octave';
    if (_availableSoundFiles.contains(exact)) return exact;

    // 2. Try nearby octaves (3, 4 are most complete)
    final fallbacks = [3, 4, 2, 5];
    for (final oct in fallbacks) {
      final candidate = '$fileSafeNote$oct';
      if (_availableSoundFiles.contains(candidate)) return candidate;
    }

    return null;
  }

  Future<void> playNote(String noteInput, int defaultOctave) async {
    await _ensureReady();
    if (!_isReady || _soLoud == null) return;

    // Clean note and extract optional embedded octave (e.g., "C3", "Db4", "F#")
    String rawNote = noteInput.trim();
    int targetOctave = defaultOctave;

    final regex = RegExp(r'^([A-Ga-g][#b]?)([0-9]?)$');
    final match = regex.firstMatch(rawNote);
    if (match != null) {
      rawNote = match.group(1)!;
      // Normalize case e.g. "c#" -> "C#"
      if (rawNote.isNotEmpty) {
        rawNote = rawNote[0].toUpperCase() + rawNote.substring(1);
      }
      final octStr = match.group(2);
      if (octStr != null && octStr.isNotEmpty) {
        targetOctave = int.tryParse(octStr) ?? defaultOctave;
      }
    }

    if (!_noteNameToFileSafeMap.containsKey(rawNote)) {
      return;
    }

    final fileSafeNote = _noteNameToFileSafeMap[rawNote]!;
    final resolvedSoundId = _resolveSoundId(fileSafeNote, targetOctave);
    if (resolvedSoundId == null) return;

    var soundToPlay = _noteSounds[resolvedSoundId];
    if (soundToPlay == null) {
      final soundPath = 'assets/sounds/$resolvedSoundId.mp3';
      try {
        final newSource = await _soLoud!.loadAsset(soundPath);
        _noteSounds[resolvedSoundId] = newSource;
        soundToPlay = newSource;
      } catch (_) {
        return;
      }
    }

    try {
      await _soLoud!.play(soundToPlay, volume: 0.6);
    } catch (_) {}
  }

  /// Play full guitar voicing across all strings with accurate pitches and arpeggio strum
  Future<void> playVoicing(ChordVoicing voicing, {String? root}) async {
    // Standard Guitar Tuning Open String Pitches (C0 = 0):
    // E2=28, A2=33, D3=38, G3=43, B3=47, E4=52
    const openStringPitches = [28, 33, 38, 43, 47, 52];
    bool hasPlayedNote = false;

    for (int i = 0; i < 6 && i < voicing.frets.length; i++) {
      final fret = voicing.frets[i];
      if (fret != -1) {
        hasPlayedNote = true;
        final absPitch = openStringPitches[i] + fret;
        final octave = absPitch ~/ 12;
        final noteIndex = absPitch % 12;
        final noteName = TheoryUtils.getNoteName(
            noteIndex, !(root?.contains('b') ?? false));

        playNote(noteName, octave);
        await Future.delayed(const Duration(milliseconds: 35));
      }
    }

    // Fallback if voicing has no active frets
    if (!hasPlayedNote && root != null) {
      final analyzed = TheoryUtils.analyzeChord(root);
      playStrum(analyzed.notes);
    }
  }

  void playChordBlock(List<String> notes) {
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
    int currentOctave = 3;
    int lastIndex = -1;
    for (String note in notes) {
      final idx = TheoryUtils.getNoteIndex(note);
      if (idx <= lastIndex) currentOctave++;
      playNote(note, currentOctave);
      lastIndex = idx;
      await Future.delayed(const Duration(milliseconds: 40));
    }
  }

  // --- Phase 2: High Precision Scheduling ---
  void startProgression(int bpm, String progressionJson) {}

  void stopProgression() {}

  void updateBpm(int bpm) {}

  void dispose() {
    _soLoud?.deinit();
  }

  void setInstrument(String instrumentId) {}

  void setVolume(double volume) {
    try {
      _soLoud?.setGlobalVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}
  }
}

