import 'dart:async';
import 'web_audio_api.dart';
import '../models/chord_model.dart';
import '../utils/theory_utils.dart';

/// This is the web-only implementation of AudioManager.
/// It does not import flutter_soloud and relies on JavaScript for audio.
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  Future<void> initialize() async {}

  Future<void> playNote(String noteInput, int defaultOctave) async {

    // Clean note and extract optional embedded octave (e.g., "C3", "Db4", "F#")
    String rawNote = noteInput.trim();
    int targetOctave = defaultOctave;

    final regex = RegExp(r'^([A-Ga-g][#b]?)([0-9]?)$');
    final match = regex.firstMatch(rawNote);
    if (match != null) {
      rawNote = match.group(1)!;
      if (rawNote.isNotEmpty) {
        rawNote = rawNote[0].toUpperCase() + rawNote.substring(1);
      }
      final octStr = match.group(2);
      if (octStr != null && octStr.isNotEmpty) {
        targetOctave = int.tryParse(octStr) ?? defaultOctave;
      }
    }

    WebAudioApi.playNote(rawNote, targetOctave);
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
    WebAudioApi.scheduleSequence(bpm, progressionJson);
  }

  void stopProgression() {
    WebAudioApi.stop();
  }

  void updateBpm(int bpm) {
    WebAudioApi.setBpm(bpm);
  }

  void setInstrument(String instrumentId) {
    WebAudioApi.setInstrument(instrumentId);
  }

  void setVolume(double volume) {
    WebAudioApi.setVolume(volume);
  }

  void dispose() {
    stopProgression();
  }
}

