import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/settings_state.dart';
import '../../providers/generator_state.dart';
import '../../providers/music_state.dart';
import '../../providers/chat_state.dart';

import 'chat_message_bubble.dart';

import '../../widgets/common/ai/quota_error_widget.dart'; // import QuotaErrorWidget

import '../../providers/studio_state.dart'; // StudioState 추가
import '../../services/ai_command_service.dart';

class AIChatPanel extends StatefulWidget {
  final VoidCallback? onClose;

  const AIChatPanel({super.key, this.onClose});

  @override
  State<AIChatPanel> createState() => _AIChatPanelState();
}

class _AIChatPanelState extends State<AIChatPanel> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  double _panelWidth = 400.0;
  bool _isUserAtBottom = true;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.isShiftPressed) {
        if (_textController.text.trim().isNotEmpty &&
            !context.read<ChatState>().isLoading) {
          _handleSubmitted(_textController.text);
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      // Consider at bottom if within 50 pixels
      _isUserAtBottom = position.pixels >= position.maxScrollExtent - 50;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    } else {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) {
          debugPrint('STT Error: $errorNotification');
          if (mounted) setState(() => _isListening = false);
        },
      );

      if (available) {
        if (mounted) setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
              _textController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _textController.text.length));
            });
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('음성 인식을 시작할 수 없습니다. 권한을 확인해주세요.')));
        }
      }
    }
  }

  List<String> _getQuickPrompts() {
    final musicState = context.read<MusicState>();
    final genState = context.read<GeneratorState>();
    final studioState = context.read<StudioState>();

    final root = musicState.rootNote;
    final mode = musicState.currentMode.name;
    final key = '$root $mode';
    final scale = genState.selectedScaleName;

    // Studio 진행이 있으면 관련 프롬프트 추가
    final hasProgression = studioState.session.progression.isNotEmpty;

    List<String> prompts = [];

    if (hasProgression) {
      prompts.add('현재 코드 진행 분석해줘');
      prompts.add('이 진행에 어울리는 멜로디 추천');
    } else {
      prompts.add('$key 키의 주요 코드는?');
      prompts.add('$key 키에 어울리는 코드 진행 추천해줘');
    }

    if (scale != null && scale.isNotEmpty) {
      prompts.add('$scale 스케일의 특징은?');
      prompts.add('$scale 스케일로 솔로 연주 팁 알려줘');
    }

    prompts.add('재즈 스타일로 편곡하려면?');
    prompts.add('기타 연습 루틴 추천해줘');

    return prompts;
  }

  Map<String, dynamic> _getContextData() {
    final genState = context.read<GeneratorState>();
    final musicState = context.read<MusicState>();
    final studioState = context.read<StudioState>();

    final progression = studioState.session.progression;
    final progressionStr = progression.isNotEmpty
        ? progression
            .map((b) =>
                '${b.chordSymbol}${b.functionTag != null ? "(${b.functionTag})" : ""}')
            .join(' - ')
        : null;

    return {
      'currentKey': '${musicState.rootNote}${musicState.currentMode.name}',
      'analyzedChord': genState.analyzedRoot.isNotEmpty
          ? '${genState.analyzedRoot}${genState.analyzedQuality}'
          : null,
      'selectedScale': genState.selectedScaleName,
      'cagedForm': genState.selectedCagedForm,
      'studioKey': studioState.session.key,
      'currentProgression': progressionStr,
    };
  }

  void _handleStop() {
    context.read<ChatState>().stopGeneration();
  }

  void _handleRegenerate() async {
    final settings = context.read<SettingsState>();
    final provider = settings.aiProvider;
    final modelName = provider == 'gemini' ? settings.geminiModel.id : null;
    final systemPrompt = settings.systemPrompt;

    await context.read<ChatState>().regenerateLastMessage(
        contextData: _getContextData(),
        modelName: modelName,
        systemPrompt: systemPrompt);

    // AI 명령 파싱 및 실행
    if (mounted) {
      final messages = context.read<ChatState>().messages;
      if (messages.isNotEmpty && messages.last['isUser'] == false) {
        final lastMsg = messages.last['text'] as String;
        final cmd = AICommandService.parse(lastMsg);
        if (cmd != null) {
          AICommandService.execute(context, cmd);
        }
      }
    }

    _isUserAtBottom = true;
    // Scroll to bottom after a slight delay to show the change
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _handleEditMessage(int index, String currentText) {
    final editController = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        title: Text('메시지 수정',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
          controller: editController,
          autofocus: true,
          minLines: 1,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: '메시지를 수정하세요',
            hintStyle: TextStyle(color: Theme.of(context).hintColor),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != currentText) {
                final settings = context.read<SettingsState>();
                final provider = settings.aiProvider;
                final modelName =
                    provider == 'gemini' ? settings.geminiModel.id : null;
                final systemPrompt = settings.systemPrompt;

                Navigator.pop(context); // Close dialog first

                await context.read<ChatState>().editMessage(index, newText,
                    contextData: _getContextData(),
                    modelName: modelName,
                    systemPrompt: systemPrompt);

                // AI 명령 파싱 및 실행
                if (mounted) {
                  final messages = context.read<ChatState>().messages;
                  if (messages.isNotEmpty && messages.last['isUser'] == false) {
                    final lastMsg = messages.last['text'] as String;
                    final cmd = AICommandService.parse(lastMsg);
                    if (cmd != null) {
                      AICommandService.execute(context, cmd);
                    }
                  }
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('수정 및 재생성',
                style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();

    final settings = context.read<SettingsState>();

    final provider = settings.aiProvider;
    final apiKey =
        provider == 'gemini' ? settings.geminiApiKey : settings.openAiApiKey;
    final systemPrompt = settings.systemPrompt;

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${provider == 'gemini' ? 'Gemini' : 'OpenAI'} API Key가 설정되지 않았습니다.')),
      );
      return;
    }

    await context.read<ChatState>().sendMessage(text, apiKey, provider,
        contextData: _getContextData(),
        modelName: provider == 'gemini' ? settings.geminiModel.id : null,
        systemPrompt: systemPrompt);

    // AI 명령 파싱 및 실행
    if (mounted) {
      final messages = context.read<ChatState>().messages;
      if (messages.isNotEmpty && messages.last['isUser'] == false) {
        final lastMsg = messages.last['text'] as String;
        final cmd = AICommandService.parse(lastMsg);
        if (cmd != null) {
          AICommandService.execute(context, cmd);
        }
      }
    }

    _isUserAtBottom = true;
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  // ... (Skip _confirmClearChat, _launchExternalWeb)

  // ... (Inside build)

  //           Expanded(
  //             child: SelectionArea(
  //               child: ListView.builder(
  //                 controller: _scrollController,
  //                 padding: const EdgeInsets.all(16),
  //                 itemCount: messages.length + (isLoading ? 1 : 0),
  //                 itemBuilder: (context, index) {
  // ...
  //                   final msg = messages[index];
  //                   // 유니크 키 추가 (Key)
  //                   return ChatMessageBubble(
  //                     key: ValueKey('msg_${index}_${msg.hashCode}'),
  //                     message: msg['text'] as String,
  //                     isUser: msg['isUser'] as bool,
  //                     provider: msg['provider'] as String?,
  //                     fontSize: settings.chatFontSize, // Add this
  //                     onEdit: (msg['isUser'] as bool) && !isLoading
  //                         ? () => _handleEditMessage(index, msg['text'] as String)
  //                         : null,
  //                   );

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        title: Text('대화 기록 삭제',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('모든 대화 내용이 영구적으로 삭제됩니다.\n계속하시겠습니까?',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatState>().clearHistory();
              Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchExternalWeb(String provider) async {
    final chatState = context.read<ChatState>();
    final messages = chatState.messages;
    final url = provider == 'gemini'
        ? 'https://gemini.google.com/'
        : 'https://chatgpt.com/';
    final uri = Uri.parse(url);

    void launchSite() async {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('링크를 열 수 없습니다: $url')),
          );
        }
      }
    }

    // 1. 대화 내용이 있는 경우: 클립보드 복사 후 다이얼로그 표시
    if (messages.isNotEmpty) {
      final StringBuffer buffer = StringBuffer();
      buffer.writeln("이전 대화 맥락입니다:");
      for (final msg in messages) {
        final role = msg['isUser'] == true ? "User" : "AI";
        final text = msg['text'] as String;
        buffer.writeln("[$role]: $text");
      }
      buffer.writeln("\n이 맥락을 바탕으로 대화를 계속해주세요.");

      await Clipboard.setData(ClipboardData(text: buffer.toString()));

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('복사 완료'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('대화 맥락이 클립보드에 저장되었습니다.'),
                const SizedBox(height: 8),
                Text('열리는 사이트의 입력창에 붙여넣기(Ctrl+V)하여\n대화를 이어가세요.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  launchSite();
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('사이트 열기'),
              ),
            ],
          ),
        );
      }
    } else {
      // 2. 대화 내용이 없는 경우: 즉시 이동
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('외부 사이트로 이동합니다.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      launchSite();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to ChatState changes
    final chatState = context.watch<ChatState>();
    final settings = context.watch<SettingsState>();
    final messages = chatState.messages;
    final isLoading = chatState.isLoading;

    // Check for mobile layout
    final isMobile = MediaQuery.of(context).size.width < 800;

    // Auto-scroll on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (isLoading && _isUserAtBottom) {
          _scrollToBottom();
        }
      }
    });

    // Content Widget
    final content = Container(
      width: isMobile ? double.infinity : _panelWidth,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 4)
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor)),
              color: Theme.of(context).cardColor,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          color: Theme.of(context).colorScheme.tertiary,
                          size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          // AI Tutor Label
                          settings.aiProvider == 'openai'
                              ? 'ChatGPT'
                              : 'Gemini',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSansKr(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      if (settings.aiProvider == 'gemini') ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              settings.geminiModel.label
                                  .replaceFirst('Gemini ', '')
                                  .replaceFirst('Flash', 'FL'),
                              style: GoogleFonts.robotoMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _launchExternalWeb(settings.aiProvider),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Opacity(
                        opacity: 0.7,
                        child: Image.asset(
                          settings.aiProvider == 'gemini'
                              ? 'assets/images/icons8-gemini.png'
                              : 'assets/images/icons8-chatgpt.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Theme.of(context)
                          .iconTheme
                          .color
                          ?.withValues(alpha: 0.5)),
                  onPressed: _confirmClearChat,
                  tooltip: '대화 지우기',
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: Icon(Icons.close,
                        color: Theme.of(context)
                            .iconTheme
                            .color
                            ?.withValues(alpha: 0.5)),
                    onPressed: widget.onClose,
                    tooltip: '닫기',
                  ),
              ],
            ),
          ),

          // Messages Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  );
                }

                final msg = messages[index];
                final msgText = msg['text'] as String;
                if (msgText.startsWith('Error:') &&
                    (msgText.contains('Quota') || msgText.contains('429'))) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: QuotaErrorWidget(
                      errorMessage: msgText.replaceFirst('Error: ', ''),
                      onRetry: _handleRegenerate,
                    ),
                  );
                }

                // 유니크 키 추가 (Key)
                return ChatMessageBubble(
                  key: ValueKey('msg_${index}_${msg.hashCode}'),
                  message: msgText,
                  isUser: msg['isUser'] as bool,
                  provider: msg['provider'] as String?,
                  fontSize: settings.chatFontSize,
                  onEdit: (msg['isUser'] as bool) && !isLoading
                      ? () => _handleEditMessage(index, msgText)
                      : null,
                );
              },
            ),
          ),

          // Quick Prompts Area
          // Quick Prompts Area
          if (!isLoading)
            SizedBox(
              height: 60,
              child: Row(
                children: [
                  // Regenerate Button (Always visible logic)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                    child: IconButton(
                      onPressed: (messages.isNotEmpty &&
                              messages.last['isUser'] == false)
                          ? _handleRegenerate
                          : null,
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: '답변 재생성',
                      // 활성화 상태일 때 Primary Color로 강조
                      color: (messages.isNotEmpty &&
                              messages.last['isUser'] == false)
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: _getQuickPrompts().length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final prompt = _getQuickPrompts()[index];
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        return ActionChip(
                          label: Text(prompt),
                          onPressed: () => _handleSubmitted(prompt),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isDark ? FontWeight.w500 : FontWeight.normal,
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                          side: isDark
                              ? BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.3))
                              : BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening
                          ? Colors.redAccent
                          : Theme.of(context).hintColor),
                  onPressed: _toggleListening,
                  tooltip: '음성 인식',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: '질문 입력...',
                      hintStyle: TextStyle(color: Theme.of(context).hintColor),
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerHigh,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    enabled: !isLoading,
                    cursorColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    isLoading ? Icons.stop_circle_outlined : Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    if (isLoading) {
                      _handleStop();
                    } else {
                      _handleSubmitted(_textController.text);
                    }
                  },
                  tooltip: isLoading ? '생성 중단' : '전송',
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!isMobile) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _panelWidth -= details.delta.dx;
                  if (_panelWidth < 300) _panelWidth = 300;
                  if (_panelWidth > 800) _panelWidth = 800;
                });
              },
              child: Container(
                width: 8,
                color: Colors.transparent,
              ),
            ),
          ),
          content,
        ],
      );
    }

    return content;
  }
}
