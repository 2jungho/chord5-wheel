import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/lyria/lyria_service.dart';
import '../audio/audio_manager.dart';
import '../models/progression/progression_models.dart';
import '../utils/theory_utils.dart';
import '../utils/guitar_utils.dart';

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

  // Virtual Band Timer
  Timer? _virtualBandTimer;
  int _currentBlockIdx = 0;

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

  StreamSubscription? _statusSubscription;

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
        if (_virtualBandTimer == null) {
          _isPlaying = false;
        }
        _currentMoodscapeMode = null;
      } else if (status.contains("Stopped")) {
        if (_virtualBandTimer == null) {
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

  /// Single-click Jam Session entry point: Connects and starts playing immediately
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

        // Build weighted prompts with style, key, and chords
        final mainPrompt = "$_style backing track band for guitar in key of $_currentKey, "
            "chord progression: $_currentProgression, "
            "rhythm guitar, acoustic chords, electric bassline, steady groove drums, dynamic accompaniment";

        _service?.setWeightedPrompts([
          {"text": mainPrompt, "weight": 1.0},
          {"text": "tight rhythmic backing band, no vocals, clear guitar backing", "weight": 0.7},
        ]);

        // Start playing the music stream
        _service?.play();
      }
    }

    // 2. Set active state and start virtual rhythmic fallback loop
    _isConnecting = false;
    _isPlaying = true;
    _statusMessage = "Playing ($_style ${_tempo.toInt()} BPM)";
    notifyListeners();

    // Run local audio generator alongside if needed or as fallback
    _startVirtualLoop(blocks);
  }

  void startJam(String chordProgression, {String key = 'C Major'}) {
    startJamSession(chordProgression: chordProgression, key: key);
  }

  void _startVirtualLoop(List<ChordBlock>? blocks) {
    _stopVirtualLoop();

    List<ChordBlock> activeBlocks = blocks ?? [];
    if (activeBlocks.isEmpty) {
      // Default 4-chord progression: C - Am - F - G
      final defaultChords = ['C', 'Am', 'F', 'G'];
      activeBlocks = defaultChords.map((sym) {
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
    }

    _currentBlockIdx = 0;

    void playNextBlock() {
      if (!_isPlaying) return;
      if (activeBlocks.isEmpty) return;

      final block = activeBlocks[_currentBlockIdx % activeBlocks.length];
      _currentBlockIdx++;

      final detail = block.chordDetail ?? TheoryUtils.analyzeChord(block.chordSymbol);

      // Beat 1: Bass note (only if Lyria is not streaming directly to avoid clash)
      if (_service == null || !_isReady) {
        final rootNote = detail.root;
        AudioManager().playNote(rootNote, 2);

        // Beat 1: Main chord voicing or strum
        if (block.voicing != null) {
          AudioManager().playVoicing(block.voicing!, root: block.chordSymbol);
        } else if (detail.notes.isNotEmpty) {
          AudioManager().playStrum(detail.notes);
        }
      }

      // Calculate timing based on BPM (1 beat = 60000 / _tempo ms)
      final beatMs = (60000.0 / _tempo).round();
      final totalBlockMs = (beatMs * block.duration).clamp(500, 10000);

      // Beat 3: Add rhythmic syncopation / accent strum if bar is >= 4 beats
      if (block.duration >= 4 && (_service == null || !_isReady)) {
        Timer(Duration(milliseconds: beatMs * 2), () {
          if (!_isPlaying) return;
          if (block.voicing != null) {
            AudioManager().playVoicing(block.voicing!, root: block.chordSymbol);
          } else if (detail.notes.isNotEmpty) {
            AudioManager().playStrum(detail.notes);
          }
        });
      }

      // Schedule next chord block
      _virtualBandTimer = Timer(Duration(milliseconds: totalBlockMs), playNextBlock);
    }

    playNextBlock();
  }

  void _stopVirtualLoop() {
    _virtualBandTimer?.cancel();
    _virtualBandTimer = null;
    AudioManager().stopProgression();
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
      AudioManager().playNote(rootNote, 2);
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
        "text": "Ambient musical soundscape in $rootNote $modeName mode, atmospheric guitar textures, pad synth, emphasizing character note $characterNote",
        "weight": 1.0
      },
      {"text": "peaceful meditative guitar backing, subtle rhythm", "weight": 0.5}
    ]);
    _service?.play();
  }

  void updateTempo(double newTempo) {
    _tempo = newTempo;
    notifyListeners();

    if (_isPlaying) {
      _service?.setMusicGenerationConfig(bpm: newTempo.toInt());
    }
  }

  void updateStyle(String newStyle) {
    _style = newStyle;
    notifyListeners();

    if (_isPlaying) {
      final promptText = "$newStyle guitar backing track in key of $_currentKey, "
          "chord progression: $_currentProgression, "
          "rhythm guitar, bass, groove drums";
      _service?.setWeightedPrompts([
        {"text": promptText, "weight": 1.0},
        {"text": "tight rhythmic backing band", "weight": 0.6}
      ]);
    }
  }

  void updateVolume(double newVolume) {
    _volume = newVolume.clamp(0.0, 1.0);
    if (_volume > 0.001) {
      _preMuteVolume = _volume;
    }
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
