import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gemini_model.dart';
import '../models/ai_provider_config.dart';
import '../models/instrument_model.dart';
import '../audio/audio_manager.dart';
import '../utils/app_theme.dart';

/// 앱 전반의 설정 상태를 관리하는 Provider입니다.
/// SharedPreferences를 통해 설정을 영구 저장합니다.
class SettingsState extends ChangeNotifier {
  SharedPreferences? _prefs;

  // --- 상태 변수 ---

  // 1. 테마 프리셋
  AppThemePreset _themePreset = AppThemePreset.slateDark;

  // 2. 마스터 볼륨 (0.0 ~ 1.0)
  double _masterVolume = 0.8;

  // 3. AI Providers & Keys
  String _aiProvider = 'gemini';
  String _geminiApiKey = '';
  String _openAiApiKey = '';
  String _claudeApiKey = '';
  String _deepseekApiKey = '';
  String _customApiKey = '';
  String _customBaseUrl = 'http://localhost:11434/v1';
  String _customModelName = 'llama3';

  // 4. Provider-specific Selected Model IDs
  GeminiModel _geminiModel = GeminiModel.flash37;
  String _openAiModelId = 'gpt-4o';
  String _claudeModelId = 'claude-3-7-sonnet-20250219';
  String _deepseekModelId = 'deepseek-chat';
  ThinkingLevel _thinkingLevel = ThinkingLevel.high;

  // 5. System Prompt
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

  // 6. Chat Font Size
  double _chatFontSize = 14.0;

  // 7. Selected Instrument
  String _selectedInstrumentId = Instrument.guitarStandard.id;

  // Available Instruments
  final List<Instrument> _availableInstruments = [
    Instrument.guitarStandard,
    Instrument.bassStandard,
    Instrument.bass5String,
    Instrument.ukulele,
  ];

  // 8. Tuning Preset
  TuningPreset _tuningPreset = TuningPreset.standard;

  // --- Getters ---
  AppThemePreset get themePreset => _themePreset;
  TuningPreset get tuningPreset => _tuningPreset;
  double get masterVolume => _masterVolume;

  String get aiProvider => _aiProvider;
  AIProviderType get aiProviderType => AIProviderType.fromId(_aiProvider);

  String get geminiApiKey => _geminiApiKey;
  String get openAiApiKey => _openAiApiKey;
  String get claudeApiKey => _claudeApiKey;
  String get deepseekApiKey => _deepseekApiKey;
  String get customApiKey => _customApiKey;
  String get customBaseUrl => _customBaseUrl;
  String get customModelName => _customModelName;

  GeminiModel get geminiModel => _geminiModel;
  String get openAiModelId => _openAiModelId;
  String get claudeModelId => _claudeModelId;
  String get deepseekModelId => _deepseekModelId;
  ThinkingLevel get thinkingLevel => _thinkingLevel;

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

  /// 현재 활성 프로바이더의 모델 ID 반환
  String get currentModelId {
    switch (aiProviderType) {
      case AIProviderType.gemini:
        return _geminiModel.id;
      case AIProviderType.openai:
        return _openAiModelId;
      case AIProviderType.claude:
        return _claudeModelId;
      case AIProviderType.custom:
        return _customModelName;
    }
  }

  /// 현재 활성 프로바이더의 모델 메타데이터 반환
  AIModelInfo get currentModelInfo {
    if (aiProviderType == AIProviderType.custom) {
      return AIModelInfo(
        id: _customModelName,
        label: _customModelName,
        shortLabel: _customModelName.length > 8
            ? _customModelName.substring(0, 8)
            : _customModelName,
        provider: AIProviderType.custom,
      );
    }
    return AIModelInfo.fromId(currentModelId, aiProviderType);
  }

  SettingsState() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load theme preset
    final String? savedThemePreset = _prefs?.getString('themePreset');
    if (savedThemePreset != null) {
      try {
        _themePreset = AppThemePreset.values.byName(savedThemePreset);
      } catch (_) {
        _themePreset = AppThemePreset.slateDark;
      }
    }

    // Load tuning preset
    final String? savedTuning = _prefs?.getString('tuningPreset');
    if (savedTuning != null) {
      try {
        _tuningPreset = TuningPreset.values.byName(savedTuning);
      } catch (_) {
        _tuningPreset = TuningPreset.standard;
      }
    }

    _masterVolume = _prefs?.getDouble('masterVolume') ?? 0.8;
    _aiProvider = _prefs?.getString('aiProvider') ?? 'gemini';
    _geminiApiKey = _prefs?.getString('geminiApiKey') ?? '';
    _openAiApiKey = _prefs?.getString('openAiApiKey') ?? '';
    _claudeApiKey = _prefs?.getString('claudeApiKey') ?? '';
    _deepseekApiKey = _prefs?.getString('deepseekApiKey') ?? '';
    _customApiKey = _prefs?.getString('customApiKey') ?? '';
    _customBaseUrl =
        _prefs?.getString('customBaseUrl') ?? 'http://localhost:11434/v1';
    _customModelName = _prefs?.getString('customModelName') ?? 'llama3';

    final String? modelId = _prefs?.getString('geminiModel');
    _geminiModel =
        modelId != null ? GeminiModel.fromId(modelId) : GeminiModel.flash37;

    _openAiModelId = _prefs?.getString('openAiModelId') ?? 'gpt-4o';
    _claudeModelId =
        _prefs?.getString('claudeModelId') ?? 'claude-3-7-sonnet-20250219';
    _deepseekModelId = _prefs?.getString('deepseekModelId') ?? 'deepseek-chat';

    final String? thinkingId = _prefs?.getString('thinkingLevel');
    _thinkingLevel = thinkingId != null
        ? ThinkingLevel.fromId(thinkingId)
        : _geminiModel.defaultThinking;

    _systemPrompt = _prefs?.getString('systemPrompt') ?? _systemPrompt;
    _chatFontSize = _prefs?.getDouble('chatFontSize') ?? 14.0;
    _huggingFaceToken = _prefs?.getString('huggingFaceToken') ?? '';
    _selectedInstrumentId = _prefs?.getString('selectedInstrumentId') ??
        Instrument.guitarStandard.id;

    notifyListeners();
  }

  void setTuningPreset(TuningPreset preset) {
    if (_tuningPreset != preset) {
      _tuningPreset = preset;
      _prefs?.setString('tuningPreset', preset.name);
      notifyListeners();
    }
  }

  // --- Actions ---

  void setThemePreset(AppThemePreset preset) {
    if (_themePreset != preset) {
      _themePreset = preset;
      _prefs?.setString('themePreset', preset.name);
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
      _thinkingLevel = model.defaultThinking;
      _prefs?.setString('thinkingLevel', _thinkingLevel.id);
      notifyListeners();
    }
  }

  void setThinkingLevel(ThinkingLevel level) {
    if (_thinkingLevel != level) {
      _thinkingLevel = level;
      _prefs?.setString('thinkingLevel', _thinkingLevel.id);
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

  void setClaudeApiKey(String key) {
    if (_claudeApiKey != key) {
      _claudeApiKey = key;
      _prefs?.setString('claudeApiKey', key);
      notifyListeners();
    }
  }

  void clearClaudeApiKey() {
    _claudeApiKey = '';
    _prefs?.remove('claudeApiKey');
    notifyListeners();
  }

  void setDeepSeekApiKey(String key) {
    if (_deepseekApiKey != key) {
      _deepseekApiKey = key;
      _prefs?.setString('deepseekApiKey', key);
      notifyListeners();
    }
  }

  void clearDeepSeekApiKey() {
    _deepseekApiKey = '';
    _prefs?.remove('deepseekApiKey');
    notifyListeners();
  }

  void setCustomApiKey(String key) {
    if (_customApiKey != key) {
      _customApiKey = key;
      _prefs?.setString('customApiKey', key);
      notifyListeners();
    }
  }

  void clearCustomApiKey() {
    _customApiKey = '';
    _prefs?.remove('customApiKey');
    notifyListeners();
  }

  void setCustomBaseUrl(String url) {
    if (_customBaseUrl != url) {
      _customBaseUrl = url;
      _prefs?.setString('customBaseUrl', url);
      notifyListeners();
    }
  }

  void setCustomModelName(String modelName) {
    if (_customModelName != modelName) {
      _customModelName = modelName;
      _prefs?.setString('customModelName', modelName);
      notifyListeners();
    }
  }

  void setOpenAiModelId(String modelId) {
    if (_openAiModelId != modelId) {
      _openAiModelId = modelId;
      _prefs?.setString('openAiModelId', modelId);
      notifyListeners();
    }
  }

  void setClaudeModelId(String modelId) {
    if (_claudeModelId != modelId) {
      _claudeModelId = modelId;
      _prefs?.setString('claudeModelId', modelId);
      notifyListeners();
    }
  }

  void setDeepSeekModelId(String modelId) {
    if (_deepseekModelId != modelId) {
      _deepseekModelId = modelId;
      _prefs?.setString('deepseekModelId', modelId);
      notifyListeners();
    }
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

  /// 활성 프로바이더의 API Key를 업데이트합니다.
  void updateApiKey(String key) {
    final trimmedKey = key.trim();
    updateApiKeyForProvider(aiProviderType, trimmedKey);
  }

  /// 특정 프로바이더의 API Key를 설정합니다.
  void updateApiKeyForProvider(AIProviderType provider, String key) {
    final trimmedKey = key.trim();
    switch (provider) {
      case AIProviderType.gemini:
        setGeminiApiKey(trimmedKey);
        break;
      case AIProviderType.openai:
        setOpenAiApiKey(trimmedKey);
        break;
      case AIProviderType.claude:
        setClaudeApiKey(trimmedKey);
        break;
      case AIProviderType.custom:
        setCustomApiKey(trimmedKey);
        break;
    }
  }

  /// 특정 프로바이더의 API Key를 가져옵니다.
  String getApiKeyForProvider(AIProviderType provider) {
    switch (provider) {
      case AIProviderType.gemini:
        return _geminiApiKey;
      case AIProviderType.openai:
        return _openAiApiKey;
      case AIProviderType.claude:
        return _claudeApiKey;
      case AIProviderType.custom:
        return _customApiKey;
    }
  }

  /// 현재 활성화된 Provider의 API Key를 반환합니다.
  String get currentApiKey => getApiKeyForProvider(aiProviderType);

  /// 현재 활성화된 Provider의 API Key를 삭제합니다.
  void clearCurrentApiKey() {
    switch (aiProviderType) {
      case AIProviderType.gemini:
        clearGeminiApiKey();
        break;
      case AIProviderType.openai:
        clearOpenAiApiKey();
        break;
      case AIProviderType.claude:
        clearClaudeApiKey();
        break;
      case AIProviderType.custom:
        clearCustomApiKey();
        break;
    }
  }

  bool get hasApiKey =>
      aiProviderType == AIProviderType.custom || currentApiKey.isNotEmpty;
}
