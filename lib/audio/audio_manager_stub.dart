import 'dart:async';
import 'web_audio_api.dart';
import '../models/chord_model.dart';
import '../utils/theory_utils.dart';
import 'virtual_band_synth.dart';

/// This is the web-only implementation of AudioManager.
/// It does not import flutter_soloud and relies on JavaScript for audio.
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  Future<void> initialize() async {}

  Future<void> playDrum(DrumSound sound, {double volume = 0.8}) async {
    WebAudioApi.playDrum(sound.name, volume);
  }

  Future<void> playBassNote(String noteName, int octave, {double volume = 0.75}) async {
    WebAudioApi.playBass(noteName, octave, volume);
  }

  Future<void> playKeyboardNote(String noteName, int octave, {double volume = 0.65}) async {
    WebAudioApi.playKeys(noteName, octave, volume);
  }

  Future<void> playKeyboardChord(List<String> notes, {int octave = 3, double volume = 0.6}) async {
    int currentOctave = octave;
    int lastIndex = -1;
    for (String note in notes) {
      final idx = TheoryUtils.getNoteIndex(note);
      if (idx <= lastIndex) currentOctave++;
      playKeyboardNote(note, currentOctave, volume: volume);
      lastIndex = idx;
    }
  }

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

  /// Play a single specific string from the voicing (stringIdx: 0=6th Low E, 5=1st High E)
  void playVoicingString(ChordVoicing voicing, int stringIdx, {String? root, double volume = 0.75}) {
    const openStringPitches = [28, 33, 38, 43, 47, 52];
    if (stringIdx >= 0 && stringIdx < voicing.frets.length && voicing.frets[stringIdx] != -1) {
      final fret = voicing.frets[stringIdx];
      final absPitch = openStringPitches[stringIdx] + fret;
      final octave = absPitch ~/ 12;
      final noteIndex = absPitch % 12;
      final noteName = TheoryUtils.getNoteName(noteIndex, !(root?.contains('b') ?? false));
      playNote(noteName, octave);
      return;
    }

    // Fallback to lowest active bass note if the requested string is muted
    for (int i = 0; i < voicing.frets.length; i++) {
      if (voicing.frets[i] != -1) {
        final fret = voicing.frets[i];
        final absPitch = openStringPitches[i] + fret;
        final octave = absPitch ~/ 12;
        final noteIndex = absPitch % 12;
        final noteName = TheoryUtils.getNoteName(noteIndex, !(root?.contains('b') ?? false));
        playNote(noteName, octave);
        return;
      }
    }
  }

  /// Play 1st & 2nd treble strings together (Pinch picking)
  Future<void> playVoicingPinch(ChordVoicing voicing, {String? root, double volume = 0.70}) async {
    const openStringPitches = [28, 33, 38, 43, 47, 52];
    // Check 1st string (index 5) and 2nd string (index 4)
    if (voicing.frets.length >= 6) {
      if (voicing.frets[4] != -1) {
        final absPitch2 = openStringPitches[4] + voicing.frets[4];
        playNote(TheoryUtils.getNoteName(absPitch2 % 12, !(root?.contains('b') ?? false)), absPitch2 ~/ 12);
      }
      if (voicing.frets[5] != -1) {
        final absPitch1 = openStringPitches[5] + voicing.frets[5];
        playNote(TheoryUtils.getNoteName(absPitch1 % 12, !(root?.contains('b') ?? false)), absPitch1 ~/ 12);
      }
    }
  }

  /// Quick tight funk staccato strum across active strings
  Future<void> playStaccatoVoicing(ChordVoicing voicing, {String? root, double volume = 0.75}) async {
    const openStringPitches = [28, 33, 38, 43, 47, 52];
    for (int i = 0; i < 6 && i < voicing.frets.length; i++) {
      final fret = voicing.frets[i];
      if (fret != -1) {
        final absPitch = openStringPitches[i] + fret;
        playNote(TheoryUtils.getNoteName(absPitch % 12, !(root?.contains('b') ?? false)), absPitch ~/ 12);
        await Future.delayed(const Duration(milliseconds: 8));
      }
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


  // --- High Precision Scheduling ---
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


