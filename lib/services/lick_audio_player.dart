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

  /// 릭을 순차적으로 재생하며, 풀링오프, 해머링온, 슬라이드, 벤딩 등의 기타 주법을 사실적으로 연주합니다.
  Future<void> playLick(
    ArtistLick lick, {
    double speed = 1.0,
    String? soundProfileId,
    void Function(int noteIndex)? onNoteStep,
    void Function(int noteIndex, NoteTechnique technique)? onTechniqueStep,
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
      final note = lick.notes[i];
      final prevNote = i > 0 ? lick.notes[i - 1] : null;

      onNoteStep?.call(i);
      onTechniqueStep?.call(i, note.technique);

      // duration 기반 음표 재생 총 대기 시간 계산
      final noteDurationMs = (note.duration * baseQuarterMs * 2).clamp(160, 1500).toInt();

      // 테크닉별 음향 표현 처리
      await _playArticulatedLickNote(
        prevNote: prevNote,
        note: note,
        durationMs: noteDurationMs,
        token: token,
      );
    }

    if (token == _playbackToken) {
      _isPlaying = false;
      _currentPlayingIndex = -1;
      onNoteStep?.call(-1);
      onTechniqueStep?.call(-1, NoteTechnique.none);
      onComplete?.call();
    }
  }

  /// 기타 테크닉(벤딩, 슬라이드, 해머링, 풀링, 비브라토)의 세부 아티큘레이션을 오디오로 표현합니다.
  Future<void> _playArticulatedLickNote({
    required LickNote? prevNote,
    required LickNote note,
    required int durationMs,
    required int token,
  }) async {
    switch (note.technique) {
      case NoteTechnique.bendHalf:
      case NoteTechnique.bendFull:
      case NoteTechnique.bend1Half:
        // 1. 벤딩: 기준 프렛 타구 후 ~100ms 시점에 목표 세미톤으로 피치가 치솟는 인플렉션
        _playPitch(note.string, note.fret);
        const bendRiseMs = 100;
        await Future.delayed(const Duration(milliseconds: bendRiseMs));
        if (!_isPlaying || token != _playbackToken) return;

        final bentFret = note.fret + note.technique.bendSemitones;
        _playPitch(note.string, bentFret);

        final remainingMs = (durationMs - bendRiseMs).clamp(60, 2000);
        await Future.delayed(Duration(milliseconds: remainingMs));
        break;

      case NoteTechnique.slide:
        // 2. 슬라이드: 이전 프렛(또는 2프렛 전)에서 목표 프렛으로 연속 반음 글리산도 전이
        int startFret = note.fret - 2;
        if (prevNote != null && prevNote.string == note.string) {
          startFret = prevNote.fret;
        }
        startFret = startFret.clamp(0, 24);

        if ((startFret - note.fret).abs() >= 2) {
          _playPitch(note.string, startFret);
          await Future.delayed(const Duration(milliseconds: 45));
          if (!_isPlaying || token != _playbackToken) return;

          final midFret = (startFret + note.fret) ~/ 2;
          _playPitch(note.string, midFret);
          await Future.delayed(const Duration(milliseconds: 45));
          if (!_isPlaying || token != _playbackToken) return;

          _playPitch(note.string, note.fret);
          final remainingMs = (durationMs - 90).clamp(60, 2000);
          await Future.delayed(Duration(milliseconds: remainingMs));
        } else {
          _playPitch(note.string, startFret);
          await Future.delayed(const Duration(milliseconds: 50));
          if (!_isPlaying || token != _playbackToken) return;

          _playPitch(note.string, note.fret);
          final remainingMs = (durationMs - 50).clamp(60, 2000);
          await Future.delayed(Duration(milliseconds: remainingMs));
        }
        break;

      case NoteTechnique.hammer:
        // 3. 해머링온: 피킹 어택을 생략한 부드러운 상행 레가토 연주
        _playPitch(note.string, note.fret);
        await Future.delayed(Duration(milliseconds: durationMs));
        break;

      case NoteTechnique.pull:
        // 4. 풀링오프: 손가락을 뜯어내며 발생하는 스냅 레가토 하행 연주
        _playPitch(note.string, note.fret);
        await Future.delayed(Duration(milliseconds: durationMs));
        break;

      case NoteTechnique.vibrato:
        // 5. 비브라토: 타구 후 서스테인 구간에서 미세한 피치/앰플리튜드 떨림
        _playPitch(note.string, note.fret);
        const vibDelayMs = 120;
        await Future.delayed(const Duration(milliseconds: vibDelayMs));
        if (!_isPlaying || token != _playbackToken) return;

        _playPitch(note.string, note.fret);
        final remainingMs = (durationMs - vibDelayMs).clamp(60, 2000);
        await Future.delayed(Duration(milliseconds: remainingMs));
        break;

      default:
        // 일반 피킹 노트
        _playPitch(note.string, note.fret);
        await Future.delayed(Duration(milliseconds: durationMs));
        break;
    }
  }

  void _playPitch(int string, int fret) {
    final stringIdx = (6 - string).clamp(0, 5);
    final absPitch = _openStringPitches[stringIdx] + fret;
    final octave = absPitch ~/ 12;
    final noteIndex = absPitch % 12;
    final noteName = TheoryUtils.getNoteName(noteIndex, false);

    AudioManager().playNote(noteName, octave);
  }

  /// 단일 노트를 즉시 미리듣기 재생합니다 (테크닉 아티큘레이션 반영).
  void previewNote(LickNote note, {String? soundProfileId}) {
    if (soundProfileId != null) {
      _soundProfileId = soundProfileId;
    }
    AudioManager().setGuitarSoundProfile(_soundProfileId);

    if (note.technique.bendSemitones > 0) {
      _playPitch(note.string, note.fret);
      Timer(const Duration(milliseconds: 100), () {
        _playPitch(note.string, note.fret + note.technique.bendSemitones);
      });
    } else if (note.technique == NoteTechnique.slide) {
      final startFret = (note.fret - 2).clamp(0, 24);
      _playPitch(note.string, startFret);
      Timer(const Duration(milliseconds: 50), () {
        _playPitch(note.string, note.fret);
      });
    } else {
      _playPitch(note.string, note.fret);
    }
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
