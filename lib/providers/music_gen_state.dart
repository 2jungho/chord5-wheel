import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/music_gen/music_generator_service.dart';
import '../services/music_gen/hugging_face_service.dart';
import 'settings_state.dart';

class MusicGenState extends ChangeNotifier {
  final SettingsState _settings;
  MusicGeneratorService? _service;

  bool _isGenerating = false;
  String? _errorMessage;
  File? _lastGeneratedFile;

  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  File? get lastGeneratedFile => _lastGeneratedFile;
  bool get hasToken => _settings.huggingFaceToken.isNotEmpty;

  MusicGenState(this._settings) {
    _updateService();
    // Settings 변경 감지 (Token 변경 시 서비스 재생성)
    _settings.addListener(_updateService);
  }

  @override
  void dispose() {
    _settings.removeListener(_updateService);
    super.dispose();
  }

  void _updateService() {
    final token = _settings.huggingFaceToken;
    if (token.isNotEmpty) {
      // 이미 서비스가 있고 토큰이 같다면 최적화 가능하지만 간결함을 위해 재성성
      _service = HuggingFaceService(token: token);
    } else {
      _service = null;
    }
    notifyListeners();
  }

  /// 음악 생성 요청
  Future<bool> generateMusic(String prompt, {int duration = 10}) async {
    if (_service == null) {
      _errorMessage = 'Hugging Face Token이 설정되지 않았습니다. 설정 메뉴에서 입력해주세요.';
      notifyListeners();
      return false;
    }

    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastGeneratedFile =
          await _service!.generateMusic(prompt: prompt, duration: duration);
      return _lastGeneratedFile != null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      return false;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
}
