import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gemini_model.dart';
import '../models/instrument_model.dart';
import '../audio/audio_manager.dart';

/// 앱 전반의 설정 상태를 관리하는 Provider입니다.
/// SharedPreferences를 통해 설정을 영구 저장합니다.
class SettingsState extends ChangeNotifier {
  SharedPreferences? _prefs;

  // --- 상태 변수 ---

  // 1. 마스터 볼륨 (0.0 ~ 1.0)
  double _masterVolume = 0.8;

  // 2. Gemini API Key
  String _geminiApiKey = '';

  // 3. AI Provider (gemini / openai)
  String _aiProvider = 'gemini';

  // 4. OpenAI API Key
  String _openAiApiKey = '';

  // 5. Theme Mode
  ThemeMode _themeMode = ThemeMode.dark;

  // 6. Gemini Model
  GeminiModel _geminiModel = GeminiModel.flashLite25;

  // 7. System Prompt
  String _systemPrompt = '''
당신은 친절한 기타 이론 선생님입니다. 
사용자의 질문에 대해 음악 이론적으로 분석하고, 초보자도 이해하기 쉽도록 친절하게 설명해주세요.
답변은 반드시 한국어(Korean)로 작성해야 합니다.

[앱 제어 기능]
사용자가 앱의 상태 변경(키 변경, 모드 변경 등)을 요청할 경우, 답변 마지막에 반드시 아래 JSON 포맷의 코드 블록을 포함하세요.
```json
{
  "command": "ACTION_NAME",
  "params": { ... }
}
```

지원하는 명령 (ACTION_NAME):
1. set_key
   - params: "key" (예: "C Major", "Am", "F# Minor")
   - 설명: 5도권의 키를 변경합니다.
2. set_mode
   - params: "mode" (예: "Dorian", "Mixolydian")
   - 설명: 스케일 모드를 변경합니다.

예시:
사용자: "C단조로 바꿔줘"
답변: 네, C 단조(Minor)로 변경하겠습니다.
```json
{
  "command": "set_key",
  "params": { "key": "C Minor" }
}
```
''';

  // 8. Chat Font Size
  double _chatFontSize = 14.0;

  // 9. Selected Instrument
  String _selectedInstrumentId = Instrument.guitarStandard.id;

  // Available Instruments
  final List<Instrument> _availableInstruments = [
    Instrument.guitarStandard,
    Instrument.bassStandard,
    Instrument.bass5String,
    Instrument.ukulele,
  ];

  // --- Getters ---
  double get masterVolume => _masterVolume;
  String get geminiApiKey => _geminiApiKey;
  String get aiProvider => _aiProvider;
  String get openAiApiKey => _openAiApiKey;
  ThemeMode get themeMode => _themeMode;
  GeminiModel get geminiModel => _geminiModel;
  String get systemPrompt => _systemPrompt;
  double get chatFontSize => _chatFontSize;

  String get selectedInstrumentId => _selectedInstrumentId;
  List<Instrument> get availableInstruments => _availableInstruments;

  Instrument get selectedInstrument {
    return _availableInstruments.firstWhere(
      (inst) => inst.id == _selectedInstrumentId,
      orElse: () => Instrument.guitarStandard,
    );
  }

  SettingsState() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _masterVolume = _prefs?.getDouble('masterVolume') ?? 0.8;
    _geminiApiKey = _prefs?.getString('geminiApiKey') ?? '';
    _aiProvider = _prefs?.getString('aiProvider') ?? 'gemini';
    _openAiApiKey = _prefs?.getString('openAiApiKey') ?? '';

    final int themeIndex = _prefs?.getInt('themeMode') ?? 2; // Default to Dark
    if (themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }
    final String? modelId = _prefs?.getString('geminiModel');
    _geminiModel =
        modelId != null ? GeminiModel.fromId(modelId) : GeminiModel.flashLite25;

    _systemPrompt = _prefs?.getString('systemPrompt') ?? _systemPrompt;
    _chatFontSize = _prefs?.getDouble('chatFontSize') ?? 14.0;
    _huggingFaceToken = _prefs?.getString('huggingFaceToken') ?? '';
    _selectedInstrumentId = _prefs?.getString('selectedInstrumentId') ??
        Instrument.guitarStandard.id;

    notifyListeners();
  }

  // --- Actions ---

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _prefs?.setInt('themeMode', mode.index);
      notifyListeners();
    }
  }

  void setMasterVolume(double value) {
    double clampedValue = value.clamp(0.0, 1.0);
    if (_masterVolume != clampedValue) {
      _masterVolume = clampedValue;
      _prefs?.setDouble('masterVolume', _masterVolume);
      notifyListeners();
    }
  }

  void setGeminiApiKey(String key) {
    if (_geminiApiKey != key) {
      _geminiApiKey = key;
      _prefs?.setString('geminiApiKey', _geminiApiKey);
      notifyListeners();
    }
  }

  void clearGeminiApiKey() {
    _geminiApiKey = '';
    _prefs?.remove('geminiApiKey');
    notifyListeners();
  }

  void setGeminiModel(GeminiModel model) {
    if (_geminiModel != model) {
      _geminiModel = model;
      _prefs?.setString('geminiModel', _geminiModel.id);
      notifyListeners();
    }
  }

  void setAiProvider(String provider) {
    if (_aiProvider != provider) {
      _aiProvider = provider;
      _prefs?.setString('aiProvider', provider);
      notifyListeners();
    }
  }

  void setOpenAiApiKey(String key) {
    if (_openAiApiKey != key) {
      _openAiApiKey = key;
      _prefs?.setString('openAiApiKey', key);
      notifyListeners();
    }
  }

  void clearOpenAiApiKey() {
    _openAiApiKey = '';
    _prefs?.remove('openAiApiKey');
    notifyListeners();
  }

  void setSystemPrompt(String prompt) {
    if (_systemPrompt != prompt) {
      _systemPrompt = prompt;
      _prefs?.setString('systemPrompt', prompt);
      notifyListeners();
    }
  }

  void setChatFontSize(double size) {
    if (_chatFontSize != size) {
      _chatFontSize = size;
      _prefs?.setDouble('chatFontSize', size);
      notifyListeners();
    }
  }

  // 9. Hugging Face Access Token
  String _huggingFaceToken = '';
  String get huggingFaceToken => _huggingFaceToken;

  void setHuggingFaceToken(String token) {
    if (_huggingFaceToken != token) {
      _huggingFaceToken = token;
      _prefs?.setString('huggingFaceToken', token);
      notifyListeners();
    }
  }

  void setInstrument(String id) {
    if (_selectedInstrumentId != id) {
      _selectedInstrumentId = id;
      _prefs?.setString('selectedInstrumentId', id);

      // Update Audio Manager (for Web App mostly)
      AudioManager().setInstrument(id);

      notifyListeners();
    }
  }

  // --- Convenience Methods ---

  /// 입력된 API Key를 Gemini Key로 설정합니다.
  void updateApiKey(String key) {
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) return;

    // 무조건 Gemini로 설정 (검증된 모델만 허용)
    setAiProvider('gemini');
    setGeminiApiKey(trimmedKey);
  }

  /// 현재 활성화된 Provider의 API Key를 반환합니다.
  String get currentApiKey =>
      _aiProvider == 'openai' ? _openAiApiKey : _geminiApiKey;

  /// 현재 활성화된 Provider의 API Key를 삭제합니다.
  void clearCurrentApiKey() {
    if (_aiProvider == 'openai') {
      clearOpenAiApiKey();
    } else {
      clearGeminiApiKey();
    }
  }

  bool get hasApiKey => currentApiKey.isNotEmpty;
}
