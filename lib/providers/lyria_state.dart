import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/lyria/lyria_service.dart';

class LyriaState extends ChangeNotifier {
  LyriaService? _service;
  String _apiKey = '';

  // UI State
  String _statusMessage = "Ready to Connect";
  bool _isConnected = false;
  bool _isReady = false;
  bool _isPlaying = false;

  // Jam Parameters
  double _tempo = 120.0;
  String _style = "Rock";

  // Getters
  String get statusMessage => _statusMessage;
  bool get isConnected => _isConnected;
  bool get isReady => _isReady;
  bool get isPlaying => _isPlaying;
  double get tempo => _tempo;
  String get style => _style;

  StreamSubscription? _statusSubscription;

  void setApiKey(String key) {
    if (_apiKey == key) return;

    _apiKey = key;

    // 만약 키가 있어서 설정되었는데, 이전 상태가 "API Key Missing" 이었다면 상태 초기화
    if (_apiKey.isNotEmpty && _statusMessage == "API Key Missing") {
      _statusMessage = "Ready to Connect";
    }

    // 서비스가 이미 존재한다면, 키가 바뀌었으므로 재설정을 위해 기존 연결 해제
    if (_service != null) {
      _service!.disconnect();
      _service = null;
    }

    // 새 키로 서비스 생성 (키가 있을 경우에만)
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
        _isPlaying = false;
      }

      notifyListeners();
    });
  }

  Future<void> connect() async {
    if (_apiKey.isEmpty) {
      _statusMessage = "API Key Missing";
      notifyListeners();
      return;
    }

    if (_service == null) {
      _service = LyriaService(apiKey: _apiKey);
      _setupListeners();
    }

    await _service!.connect();
  }

  Future<void> disconnect() async {
    await _service?.disconnect();
    _isConnected = false;
    _isReady = false;
    _isPlaying = false;
    notifyListeners();
  }

  void startJam(String chordProgression) {
    if (!_isReady) return;

    // Construct Prompt
    final prompt = "Style: $_style, Tempo: ${_tempo.toInt()} BPM\n"
        "Chords: $chordProgression\n"
        "Create a backing track that follows these chords directly.";

    _service?.sendPrompt(prompt);
  }

  void updateTempo(double newTempo) {
    _tempo = newTempo;
    notifyListeners();

    if (_isPlaying) {
      // In a real scenario, we send a control message.
      // For verified protocol (Text/Audio bidi), we might send a text command.
      _service?.sendPrompt("Change tempo to ${newTempo.toInt()} BPM");
    }
  }

  void updateStyle(String newStyle) {
    _style = newStyle;
    notifyListeners();

    if (_isPlaying) {
      _service?.sendPrompt("Change style to $newStyle");
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _service?.disconnect();
    super.dispose();
  }
}
