import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/lyria/lyria_service.dart';
import '../services/lyria/virtual_band_sequencer.dart';
import '../audio/audio_manager.dart';
import '../models/progression/progression_models.dart';
import '../utils/theory_utils.dart';

class LyriaState extends ChangeNotifier {
  LyriaService? _service;
  String _apiKey = '';

  // UI State
  String _statusMessage = "Ready";
  bool _isConnected = false;
  bool _isReady = false;
  bool _isConnecting = false;
  bool _isPlaying = false;
  String? _currentMoodscapeMode;

  // Jam Parameters
  double _tempo = 120.0;
  String _style = "Neo-Soul";
  double _volume = 0.8;
  double _preMuteVolume = 0.8;

  // Instrument Toggles
  bool _drumsEnabled = true;
  bool _bassEnabled = true;
  bool _keysEnabled = true;
  bool _guitarEnabled = true;

  // Virtual Band Sequencer
  late final VirtualBandSequencer _sequencer;
  int _activeBlockIndex = 0;
  int _activeStepInBlock = 0;

  // Getters
  String get statusMessage => _statusMessage;
  bool get isConnected => _isConnected;
  bool get isReady => _isReady;
  bool get isConnecting => _isConnecting;
  bool get isPlaying => _isPlaying;
  String? get currentMoodscapeMode => _currentMoodscapeMode;
  bool get isMoodscapePlaying => _isPlaying && _currentMoodscapeMode != null;
  double get tempo => _tempo;
  String get style => _style;
  double get volume => _volume;
  bool get isMuted => _volume <= 0.001;

  bool get drumsEnabled => _drumsEnabled;
  bool get bassEnabled => _bassEnabled;
  bool get keysEnabled => _keysEnabled;
  bool get guitarEnabled => _guitarEnabled;

  int get activeBlockIndex => _activeBlockIndex;
  int get activeStepInBlock => _activeStepInBlock;
  int get activeBeat => (_activeStepInBlock ~/ 4) + 1;

  StreamSubscription? _statusSubscription;

  LyriaState() {
    _sequencer = VirtualBandSequencer(
      bpm: _tempo,
      style: _style,
      volume: _volume,
      drumsEnabled: _drumsEnabled,
      bassEnabled: _bassEnabled,
      keysEnabled: _keysEnabled,
      guitarEnabled: _guitarEnabled,
      onStep: (blockIdx, stepIdx, totalSteps) {
        _activeBlockIndex = blockIdx;
        _activeStepInBlock = stepIdx;
        notifyListeners();
      },
    );
  }

  void setApiKey(String key) {
    if (_apiKey == key) return;

    _apiKey = key;

    if (_apiKey.isNotEmpty && _statusMessage == "API Key Missing") {
      _statusMessage = "Ready";
    }

    if (_service != null) {
      _service!.disconnect();
      _service = null;
    }

    if (key.isNotEmpty) {
      _service = LyriaService(apiKey: key);
      _setupListeners();
    }

    notifyListeners();
  }

  void _setupListeners() {
    _statusSubscription?.cancel();
    _statusSubscription = _service?.statusStream.listen((status) {
      _statusMessage = status;
      _isConnected = _service?.isConnected ?? false;
      _isReady = _service?.isReady ?? false;

      if (status.contains("Playing")) {
        _isPlaying = true;
      } else if (status.contains("Disconnected") || status.contains("Closed")) {
        _isConnected = false;
        _isReady = false;
        if (!_sequencer.isRunning) {
          _isPlaying = false;
        }
        _currentMoodscapeMode = null;
      } else if (status.contains("Stopped")) {
        if (!_sequencer.isRunning) {
          _isPlaying = false;
        }
        _currentMoodscapeMode = null;
      }

      notifyListeners();
    });
  }

  Future<void> connect() async {
    if (_apiKey.isEmpty) {
      _statusMessage = "API Key Missing (설정에서 등록)";
      notifyListeners();
      return;
    }

    _isConnecting = true;
    notifyListeners();

    if (_service == null) {
      _service = LyriaService(apiKey: _apiKey);
      _setupListeners();
    }

    try {
      await _service!.connect();
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _service?.disconnect();
    _stopVirtualLoop();
    _isConnected = false;
    _isReady = false;
    _isConnecting = false;
    _isPlaying = false;
    _currentMoodscapeMode = null;
    notifyListeners();
  }

  void stopPlayback() {
    _service?.stopPlayback();
    _stopVirtualLoop();
    _isPlaying = false;
    _isConnecting = false;
    _currentMoodscapeMode = null;
    _statusMessage = "Ready";
    notifyListeners();
  }

  // Current Jam Metadata
  String _currentKey = 'C Major';
  String _currentProgression = 'C - Am - F - G';

  /// Single-click Jam Session entry point: Connects and starts playing full 4-piece band immediately
  Future<void> startJamSession({
    required String chordProgression,
    List<ChordBlock>? blocks,
    String key = 'C Major',
  }) async {
    _isConnecting = true;
    _currentMoodscapeMode = null;
    _currentKey = key;
    _currentProgression = chordProgression;
    notifyListeners();

    // 1. If API Key is present, connect & start Lyria RealTime streaming
    if (_apiKey.isNotEmpty) {
      if (!_isConnected || !_isReady) {
        if (_service == null) {
          _service = LyriaService(apiKey: _apiKey);
          _setupListeners();
        }
        await _service!.connect();

        // Wait briefly for setup
        for (int i = 0; i < 15; i++) {
          if (_isReady) break;
          await Future.delayed(const Duration(milliseconds: 150));
        }
      }

      if (_isReady) {
        // Configure Tempo (BPM)
        _service?.setMusicGenerationConfig(bpm: _tempo.toInt(), temperature: 1.0);

        // Build comprehensive 4-piece band prompt
        final mainPrompt = "Full 4-piece rhythm section backing track in key of $_currentKey, chord progression: $_currentProgression. "
            "1. Drums: Steady dynamic drum groove with punchy kick, snappy snare backbeat, and crisp hi-hat groove. "
            "2. Bass: Deep warm electric bass guitar playing the chord root notes with melodic grooves. "
            "3. Keyboard: Lush Fender Rhodes / Electric Piano chord voicings and rhythmic comping. "
            "4. Guitar: Clean rhythmic acoustic and electric guitar accompaniment. "
            "Style: $_style, Tempo: ${_tempo.toInt()} BPM. High fidelity studio backing track, no vocals, no lead guitar solo.";

        _service?.setWeightedPrompts([
          {"text": mainPrompt, "weight": 1.0},
          {"text": "tight rhythmic backing band with drums, bass, keys, and guitar", "weight": 0.8},
        ]);

        // Start playing the music stream
        _service?.play();
      }
    }

    // 2. Set active state and start virtual multi-instrument sequencer
    _isConnecting = false;
    _isPlaying = true;
    _statusMessage = "Playing ($_style ${_tempo.toInt()} BPM)";
    notifyListeners();

    // Run procedural Virtual Band Sequencer
    _sequencer.updateBpm(_tempo);
    _sequencer.updateStyle(_style);
    _sequencer.updateVolume(_volume);
    _sequencer.setInstruments(
      drums: _drumsEnabled,
      bass: _bassEnabled,
      keys: _keysEnabled,
      guitar: _guitarEnabled,
    );
    _sequencer.start(blocks ?? []);
  }

  void startJam(String chordProgression, {String key = 'C Major'}) {
    startJamSession(chordProgression: chordProgression, key: key);
  }

  void _stopVirtualLoop() {
    _sequencer.stop();
  }

  void toggleInstrument(String instrument) {
    switch (instrument.toLowerCase()) {
      case 'drums':
      case 'drum':
        _drumsEnabled = !_drumsEnabled;
        _sequencer.setInstruments(drums: _drumsEnabled);
        break;
      case 'bass':
        _bassEnabled = !_bassEnabled;
        _sequencer.setInstruments(bass: _bassEnabled);
        break;
      case 'keys':
      case 'keyboard':
      case 'piano':
        _keysEnabled = !_keysEnabled;
        _sequencer.setInstruments(keys: _keysEnabled);
        break;
      case 'guitar':
        _guitarEnabled = !_guitarEnabled;
        _sequencer.setInstruments(guitar: _guitarEnabled);
        break;
    }
    notifyListeners();
  }

  Future<void> playModeMoodscape(
      String modeName, String rootNote, String characterNote) async {
    _currentMoodscapeMode = modeName;
    notifyListeners();

    if (!_isConnected || !_isReady) {
      await connect();
      for (int i = 0; i < 15; i++) {
        if (_isReady) break;
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    if (!_isReady) {
      // Fallback: Play root note & modal chord
      final analyzed = TheoryUtils.analyzeChord(rootNote);
      AudioManager().playBassNote(rootNote, 2);
      AudioManager().playKeyboardChord(analyzed.notes, octave: 3);
      AudioManager().playStrum(analyzed.notes);
      _statusMessage = "Playing $rootNote $modeName";
      _isPlaying = true;
      notifyListeners();
      Timer(const Duration(seconds: 4), () {
        if (_currentMoodscapeMode == modeName) {
          _isPlaying = false;
          _currentMoodscapeMode = null;
          notifyListeners();
        }
      });
      return;
    }

    // Configure Lyria for Mode Moodscape
    _service?.setMusicGenerationConfig(bpm: 80, scale: "$rootNote $modeName", temperature: 0.9);
    _service?.setWeightedPrompts([
      {
        "text": "Ambient musical soundscape in $rootNote $modeName mode, atmospheric guitar textures, pad synth, electric bass, subtle drum groove, emphasizing character note $characterNote",
        "weight": 1.0
      },
      {"text": "peaceful meditative backing band, subtle rhythm", "weight": 0.6}
    ]);
    _service?.play();
  }

  void updateTempo(double newTempo) {
    _tempo = newTempo;
    _sequencer.updateBpm(newTempo);
    notifyListeners();

    if (_isPlaying) {
      _service?.setMusicGenerationConfig(bpm: newTempo.toInt());
    }
  }

  void updateStyle(String newStyle) {
    _style = newStyle;
    _sequencer.updateStyle(newStyle);
    notifyListeners();

    if (_isPlaying) {
      final promptText = "Full 4-piece backing band ($newStyle style) in key of $_currentKey, "
          "chord progression: $_currentProgression, "
          "drums, electric bass, keyboard/piano chords, rhythm guitar";
      _service?.setWeightedPrompts([
        {"text": promptText, "weight": 1.0},
        {"text": "tight rhythmic backing band with drums, bass, keys, guitar", "weight": 0.7}
      ]);
    }
  }

  void updateVolume(double newVolume) {
    _volume = newVolume.clamp(0.0, 1.0);
    if (_volume > 0.001) {
      _preMuteVolume = _volume;
    }
    _sequencer.updateVolume(_volume);
    _service?.setVolume(_volume);
    AudioManager().setVolume(_volume);
    notifyListeners();
  }

  void toggleMute() {
    if (isMuted) {
      updateVolume(_preMuteVolume > 0.05 ? _preMuteVolume : 0.8);
    } else {
      _preMuteVolume = _volume;
      updateVolume(0.0);
    }
  }

  @override
  void dispose() {
    _stopVirtualLoop();
    _statusSubscription?.cancel();
    _service?.disconnect();
    super.dispose();
  }
}

