import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/lick/artist_lick_model.dart';
import '../audio/audio_manager.dart';
import '../utils/theory_utils.dart';

/// 릭의 각 음을 정확한 옥타브 피치와 타이밍으로 재생하고 UI 동기화 이벤트를 발행하는 오디오 플레이어
class LickAudioPlayer {
  static final LickAudioPlayer _instance = LickAudioPlayer._internal();
  factory LickAudioPlayer() => _instance;
  LickAudioPlayer._internal();

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  int _currentPlayingIndex = -1;
  int get currentPlayingIndex => _currentPlayingIndex;

  String _soundProfileId = 'guitar_overdrive';
  String get soundProfileId => _soundProfileId;

  Timer? _playbackTimer;
  int _playbackToken = 0;

  // Standard Guitar Tuning Open String Pitches (C0 = 0):
  // 6th Low E (E2) = 28, 5th A (A2) = 33, 4th D (D3) = 38, 3rd G (G3) = 43, 2nd B (B3) = 47, 1st High E (E4) = 52
  static const List<int> _openStringPitches = [28, 33, 38, 43, 47, 52];

  /// 기타 사운드 프로필을 변경합니다.
  void setSoundProfile(String profileId) {
    _soundProfileId = profileId;
    AudioManager().setGuitarSoundProfile(profileId);
  }

  /// 릭을 순차적으로 재생합니다.
  Future<void> playLick(
    ArtistLick lick, {
    double speed = 1.0,
    String? soundProfileId,
    void Function(int noteIndex)? onNoteStep,
    VoidCallback? onComplete,
  }) async {
    stop();

    if (lick.notes.isEmpty) {
      onComplete?.call();
      return;
    }

    if (soundProfileId != null) {
      _soundProfileId = soundProfileId;
    }
    AudioManager().setGuitarSoundProfile(_soundProfileId);

    _isPlaying = true;
    final token = ++_playbackToken;

    // 기본 템포 기준 (duration 1.0 = 4분음표 = 약 600ms at 100bpm)
    final baseQuarterMs = (600 / speed).round();

    for (int i = 0; i < lick.notes.length; i++) {
      if (!_isPlaying || token != _playbackToken) break;

      _currentPlayingIndex = i;
      onNoteStep?.call(i);

      final note = lick.notes[i];
      _playSingleLickNote(note);

      // duration 기반 대기 시간 계산
      final noteDurationMs = (note.duration * baseQuarterMs * 2).clamp(150, 1500).toInt();
      await Future.delayed(Duration(milliseconds: noteDurationMs));
    }

    if (token == _playbackToken) {
      _isPlaying = false;
      _currentPlayingIndex = -1;
      onNoteStep?.call(-1);
      onComplete?.call();
    }
  }

  void _playSingleLickNote(LickNote note) {
    final stringIdx = (6 - note.string).clamp(0, 5);
    final absPitch = _openStringPitches[stringIdx] + note.fret + note.technique.bendSemitones;
    final octave = absPitch ~/ 12;
    final noteIndex = absPitch % 12;
    final noteName = TheoryUtils.getNoteName(noteIndex, false);

    AudioManager().playNote(noteName, octave);
  }

  /// 단일 노트를 즉시 미리듣기 재생합니다.
  void previewNote(LickNote note, {String? soundProfileId}) {
    if (soundProfileId != null) {
      _soundProfileId = soundProfileId;
    }
    AudioManager().setGuitarSoundProfile(_soundProfileId);
    _playSingleLickNote(note);
  }

  /// 재생을 중지합니다.
  void stop() {
    _isPlaying = false;
    _playbackToken++;
    _currentPlayingIndex = -1;
    _playbackTimer?.cancel();
    _playbackTimer = null;
  }
}
