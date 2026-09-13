import 'dart:async';
import '../../audio/audio_manager.dart';
import '../../models/chord_model.dart';
import '../../models/progression/progression_models.dart';
import '../../utils/guitar_utils.dart';
import '../../utils/theory_utils.dart';
import 'patterns/band_bass_patterns.dart';
import 'patterns/band_drum_patterns.dart';
import 'patterns/band_guitar_patterns.dart';
import 'patterns/band_keys_patterns.dart';



typedef BandStepCallback = void Function(int blockIndex, int stepInBlock, int totalStepsInBlock);

class VirtualBandSequencer {
  Timer? _timer;
  bool _isRunning = false;

  // Configuration
  double bpm;
  String style;
  double volume;
  double drumsVolume;
  double bassVolume;
  double keysVolume;
  double guitarVolume;

  bool drumsEnabled;
  bool bassEnabled;
  bool keysEnabled;
  bool guitarEnabled;

  // Active progression
  List<ChordBlock> _blocks = [];
  int _currentBlockIndex = 0;
  int _currentStepInBlock = 0;

  // Step Callback for UI sync
  BandStepCallback? onStep;

  VirtualBandSequencer({
    this.bpm = 120.0,
    this.style = 'Neo-Soul',
    this.volume = 0.8,
    this.drumsVolume = 0.85,
    this.bassVolume = 0.85,
    this.keysVolume = 0.75,
    this.guitarVolume = 0.80,
    this.drumsEnabled = true,
    this.bassEnabled = true,
    this.keysEnabled = true,
    this.guitarEnabled = true,
    this.onStep,
  });

  bool get isRunning => _isRunning;

  void start(List<ChordBlock> blocks) {
    stop();

    if (blocks.isEmpty) {
      // Default fallback 4-chord progression: C - Am - F - G
      final defaultChords = ['C', 'Am', 'F', 'G'];
      _blocks = defaultChords.map((sym) {
        final analyzed = TheoryUtils.analyzeChord(sym);
        final voicings = GuitarUtils.generateAllVoicings(analyzed.root, analyzed.quality);
        return ChordBlock(
          chordSymbol: sym,
          functionTag: '',
          duration: 4,
          chordDetail: analyzed,
          voicing: voicings.isNotEmpty ? voicings.first : null,
        );
      }).toList();
    } else {
      _blocks = List<ChordBlock>.from(blocks);
    }

    _currentBlockIndex = 0;
    _currentStepInBlock = 0;
    _isRunning = true;

    _scheduleNextTick();
  }

  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _currentBlockIndex = 0;
    _currentStepInBlock = 0;
    AudioManager().stopProgression();
  }

  void updateBpm(double newBpm) {
    bpm = newBpm.clamp(50.0, 220.0);
  }

  void updateStyle(String newStyle) {
    style = newStyle;
  }

  void updateVolume(double newVolume) {
    volume = newVolume.clamp(0.0, 1.0);
  }

  void setInstrumentVolumes({
    double? drums,
    double? bass,
    double? keys,
    double? guitar,
  }) {
    if (drums != null) drumsVolume = drums.clamp(0.0, 1.0);
    if (bass != null) bassVolume = bass.clamp(0.0, 1.0);
    if (keys != null) keysVolume = keys.clamp(0.0, 1.0);
    if (guitar != null) guitarVolume = guitar.clamp(0.0, 1.0);
  }

  void setInstruments({
    bool? drums,
    bool? bass,
    bool? keys,
    bool? guitar,
  }) {
    if (drums != null) drumsEnabled = drums;
    if (bass != null) bassEnabled = bass;
    if (keys != null) keysEnabled = keys;
    if (guitar != null) guitarEnabled = guitar;
  }

  String _normalizeStyle(String rawStyle) {
    final s = rawStyle.toLowerCase();
    if (s.contains('lofi') || s.contains('로파이') || s.contains('비 오는')) return 'Lofi Chill';
    if (s.contains('neo') || s.contains('soul') || s.contains('소울')) return 'Neo-Soul';
    if (s.contains('blue') || s.contains('블루스')) return 'Blues';
    if (s.contains('city') || s.contains('시티팝') || s.contains('disco') || s.contains('디스코')) return 'City Pop';
    if (s.contains('rock') || s.contains('록') || s.contains('락') || s.contains('펑키')) return 'Rock';
    if (s.contains('jazz') || s.contains('funk') || s.contains('재즈')) return 'Jazz Funk';
    if (s.contains('acoustic') || s.contains('어쿠스틱') || s.contains('ballad') || s.contains('감성')) return 'Acoustic Ballad';
    return rawStyle;
  }

  void _scheduleNextTick() {
    if (!_isRunning) return;

    final baseStepMs = 60000.0 / bpm / 4.0; // 16th-note duration in ms
    final isOddStep = (_currentStepInBlock % 2) == 1;

    // Apply micro-timing swing feel for specific genres
    final swingRatio = (style == 'Neo-Soul' || style == 'Lofi Chill' || style == 'Blues' || style == 'Jazz Funk')
        ? 0.58
        : 0.50;

    final stepDurationMs = isOddStep
        ? (baseStepMs * 2.0 * (1.0 - swingRatio)).round().clamp(30, 500)
        : (baseStepMs * 2.0 * swingRatio).round().clamp(30, 500);

    _timer = Timer(Duration(milliseconds: stepDurationMs), () {
      if (!_isRunning) return;
      _executeStep();
      _scheduleNextTick();
    });
  }

  void _executeStep() {
    if (_blocks.isEmpty) return;

    final block = _blocks[_currentBlockIndex % _blocks.length];
    final detail = block.chordDetail ?? TheoryUtils.analyzeChord(block.chordSymbol);
    final totalStepsInBlock = (block.duration * 4).clamp(4, 32); // 4 steps per beat
    final stepInBar = _currentStepInBlock % 16; // 16 steps in a 4/4 bar
    final normalized = _normalizeStyle(style);

    // Notify UI
    onStep?.call(_currentBlockIndex, _currentStepInBlock, totalStepsInBlock);

    // 1. DRUMS SEQUENCING
    final effectiveDrumsVol = volume * drumsVolume;
    if (drumsEnabled && effectiveDrumsVol > 0.01) {
      _playDrums(normalized, stepInBar, effectiveDrumsVol);
    }

    // 2. BASS SEQUENCING
    final effectiveBassVol = volume * bassVolume;
    if (bassEnabled && effectiveBassVol > 0.01) {
      _playBass(normalized, stepInBar, detail, effectiveBassVol);
    }

    // 3. KEYBOARD / ELECTRIC PIANO SEQUENCING
    final effectiveKeysVol = volume * keysVolume;
    if (keysEnabled && effectiveKeysVol > 0.01) {
      _playKeys(normalized, stepInBar, detail, effectiveKeysVol);
    }

    // 4. GUITAR SEQUENCING
    final effectiveGuitarVol = volume * guitarVolume;
    if (guitarEnabled && effectiveGuitarVol > 0.01) {
      _playGuitar(normalized, stepInBar, block, detail, effectiveGuitarVol);
    }

    // Advance step pointer
    _currentStepInBlock++;
    if (_currentStepInBlock >= totalStepsInBlock) {
      _currentStepInBlock = 0;
      _currentBlockIndex = (_currentBlockIndex + 1) % _blocks.length;
    }
  }

  // --- Pattern Delegates ---
  void _playDrums(String style, int step, double vol) =>
      BandDrumPatterns.play(style, step, vol);

  void _playBass(String style, int step, Chord detail, double vol) =>
      BandBassPatterns.play(style, step, detail, vol);

  void _playKeys(String style, int step, Chord detail, double vol) =>
      BandKeysPatterns.play(style, step, detail, vol);

  void _playGuitar(String style, int step, ChordBlock block, Chord detail, double vol) =>
      BandGuitarPatterns.play(style, step, block, detail, vol);
}
