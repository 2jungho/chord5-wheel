import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';

class ChatState with ChangeNotifier {
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  AIService? _aiService;
  String? _currentApiKey;

  String? _currentProvider;
  String? _currentModel;
  String? _currentSystemPrompt;

  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;

  ChatState() {
    _loadMessages();
  }

  // 메시지 로드
  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedMessages = prefs.getString('chat_history');
    if (savedMessages != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedMessages);
        _messages.clear();
        _messages.addAll(decoded.cast<Map<String, dynamic>>());
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading chat history: $e');
      }
    }
  }

  // 메시지 저장
  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_messages);
    await prefs.setString('chat_history', encoded);
  }

  StreamSubscription? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // 생성 중단
  void stopGeneration() {
    if (_isLoading) {
      _subscription?.cancel();
      _subscription = null;
      _isLoading = false;
      notifyListeners();
      _saveMessages();
    }
  }

  // 메시지 수정 및 재생성
  Future<void> editMessage(
    int index,
    String newText, {
    required Map<String, dynamic> contextData,
    String? modelName,
    String? systemPrompt,
  }) async {
    if (index < 0 || index >= _messages.length || _isLoading) return;

    // 해당 인덱스 이후의 모든 메시지 삭제
    if (index + 1 < _messages.length) {
      _messages.removeRange(index + 1, _messages.length);
    }

    // 메시지 내용 업데이트
    _messages[index]['text'] = newText;
    final provider =
        _messages[index]['provider'] as String? ?? _currentProvider ?? 'gemini';

    notifyListeners();
    _saveMessages();

    if (_currentApiKey == null) return;

    await _sendAIRequest(newText, _currentApiKey!, provider,
        contextData: contextData,
        modelName: modelName,
        systemPrompt: systemPrompt);
  }

  // 마지막 메시지 재생성
  Future<void> regenerateLastMessage({
    required Map<String, dynamic> contextData,
    String? modelName,
    String? systemPrompt,
  }) async {
    if (_messages.isEmpty || _isLoading) return;

    // 마지막 메시지가 AI인 경우 삭제 (덮어쓰기 위해)
    if (_messages.last['isUser'] == false) {
      _messages.removeLast();
    }

    // 마지막 사용자 메시지 찾기
    final lastUserMsgIndex =
        _messages.lastIndexWhere((m) => m['isUser'] == true);
    if (lastUserMsgIndex == -1) return;

    final lastUserMsg = _messages[lastUserMsgIndex];
    final text = lastUserMsg['text'] as String;
    final provider =
        lastUserMsg['provider'] as String? ?? _currentProvider ?? 'gemini';

    if (_currentApiKey == null) {
      return;
    }

    await _sendAIRequest(text, _currentApiKey!, provider,
        contextData: contextData,
        modelName: modelName,
        systemPrompt: systemPrompt);
  }

  // 메시지 추가 및 API 호출 (Public)
  Future<void> sendMessage(String text, String apiKey, String provider,
      {Map<String, dynamic>? contextData,
      String? modelName,
      String? systemPrompt}) async {
    if (text.trim().isEmpty) return;

    // 1. 사용자 메시지 추가
    _messages.add({'text': text, 'isUser': true, 'provider': provider});
    notifyListeners();
    _saveMessages();

    await _sendAIRequest(text, apiKey, provider,
        contextData: contextData,
        modelName: modelName,
        systemPrompt: systemPrompt);
  }

  // 실제 AI 요청 로직 (Private)
  Future<void> _sendAIRequest(String text, String apiKey, String provider,
      {Map<String, dynamic>? contextData,
      String? modelName,
      String? systemPrompt}) async {
    _isLoading = true;
    notifyListeners();

    // AI Service Init
    if (_aiService == null ||
        _currentApiKey != apiKey ||
        _currentProvider != provider ||
        _currentModel != modelName ||
        _currentSystemPrompt != systemPrompt) {
      _aiService = AIService(
          apiKey: apiKey,
          provider: provider,
          modelName: modelName,
          systemPrompt: systemPrompt);
      _currentApiKey = apiKey;
      _currentProvider = provider;
      _currentModel = modelName;
      _currentSystemPrompt = systemPrompt;
    }

    try {
      // 2. AI 응답 스트리밍 시작
      final stream = _aiService!.sendMessageStream(
        text,
        contextData: contextData,
      );

      // AI 메시지 플레이스홀더 추가
      _messages.add({'text': '', 'isUser': false, 'provider': provider});
      int aiIndex = _messages.length - 1;
      notifyListeners();

      StringBuffer buffer = StringBuffer();

      // 기존 await for 대신 listen 사용
      _subscription?.cancel(); // 기존 구독 취소

      final completer = Completer<void>();

      _subscription = stream.listen(
        (chunk) {
          buffer.write(chunk);
          if (aiIndex < _messages.length) {
            _messages[aiIndex]['text'] = buffer.toString();
          }
          notifyListeners();
        },
        onDone: () {
          _isLoading = false;
          _saveMessages();
          notifyListeners();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (error) {
          final errorMsg = '\n\n[System Error: ${error.toString()}]';
          if (aiIndex < _messages.length &&
              _messages[aiIndex]['isUser'] == false) {
            // Append error to existing text if possible
            final currentText = _messages[aiIndex]['text'] as String;
            _messages[aiIndex]['text'] = currentText + errorMsg;
          } else {
            _messages.add({
              'text': errorMsg.trim(),
              'isUser': false,
              'provider': provider
            });
          }
          _isLoading = false;
          _saveMessages();
          notifyListeners();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );

      await completer.future;
    } catch (e) {
      // 동기적 에러 발생 시
      _messages.add({
        'text': 'Error: ${e.toString()}',
        'isUser': false,
        'provider': provider
      });
      _isLoading = false;
      notifyListeners();
      _saveMessages();
    }
  }

  // 대화 기록 삭제
  Future<void> clearHistory() async {
    _messages.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
    if (_aiService != null) {
      _aiService!.clearSession();
    }
    notifyListeners();
  }
}
