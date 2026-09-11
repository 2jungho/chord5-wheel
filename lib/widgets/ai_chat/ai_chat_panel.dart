import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../providers/chat_state.dart';
import '../../providers/generator_state.dart';
import '../../providers/music_state.dart';
import '../../providers/settings_state.dart';
import '../../providers/studio_state.dart';
import '../../services/ai_command_service.dart';
import '../common/ai/quota_error_widget.dart';
import 'chat_dialogs.dart';
import 'chat_input_bar.dart';
import 'chat_message_bubble.dart';
import 'chat_panel_header.dart';
import 'chat_quick_prompts_bar.dart';

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
                TextPosition(offset: _textController.text.length),
              );
            });
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('음성 인식을 시작할 수 없습니다. 권한을 확인해주세요.')),
          );
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
    final modelName = settings.currentModelId;
    final systemPrompt = settings.systemPrompt;

    await context.read<ChatState>().regenerateLastMessage(
          contextData: _getContextData(),
          modelName: modelName,
          systemPrompt: systemPrompt,
          thinkingLevel: settings.thinkingLevel,
          customBaseUrl: settings.customBaseUrl,
        );

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

  void _handleEditMessage(int index, String currentText) {
    ChatDialogs.showEditMessageDialog(
      context,
      currentText,
      (newText) async {
        final settings = context.read<SettingsState>();
        final modelName = settings.currentModelId;
        final systemPrompt = settings.systemPrompt;
        final chatState = context.read<ChatState>();

        await chatState.editMessage(
          index,
          newText,
          contextData: _getContextData(),
          modelName: modelName,
          systemPrompt: systemPrompt,
          thinkingLevel: settings.thinkingLevel,
          customBaseUrl: settings.customBaseUrl,
        );

        if (!mounted) return;
        final messages = chatState.messages;
        if (messages.isNotEmpty && messages.last['isUser'] == false) {
          final lastMsg = messages.last['text'] as String;
          final cmd = AICommandService.parse(lastMsg);
          if (cmd != null && mounted) {
            AICommandService.execute(context, cmd);
          }
        }
      },
    );
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();

    final settings = context.read<SettingsState>();
    final provider = settings.aiProvider;
    final apiKey = settings.currentApiKey;
    final systemPrompt = settings.systemPrompt;

    if (!settings.hasApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${settings.aiProviderType.label} API Key가 설정되지 않았습니다. 설정창에서 키를 등록해주세요.',
          ),
        ),
      );
      return;
    }

    await context.read<ChatState>().sendMessage(
          text,
          apiKey,
          provider,
          contextData: _getContextData(),
          modelName: settings.currentModelId,
          systemPrompt: systemPrompt,
          thinkingLevel: settings.thinkingLevel,
          customBaseUrl: settings.customBaseUrl,
        );

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

  void _confirmClearChat() {
    ChatDialogs.confirmClearChat(
      context,
      () => context.read<ChatState>().clearHistory(),
    );
  }

  void _launchExternalWeb() {
    final settings = context.read<SettingsState>();
    final chatState = context.read<ChatState>();
    ChatDialogs.launchExternalWeb(
      context: context,
      provider: settings.aiProviderType,
      messages: chatState.messages,
      customBaseUrl: settings.customBaseUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = context.watch<ChatState>();
    final settings = context.watch<SettingsState>();
    final messages = chatState.messages;
    final isLoading = chatState.isLoading;
    final isMobile = MediaQuery.of(context).size.width < 800;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (isLoading && _isUserAtBottom) {
          _scrollToBottom();
        }
      }
    });

    final content = Container(
      width: isMobile ? double.infinity : _panelWidth,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          ChatPanelHeader(
            settings: settings,
            onClearChat: _confirmClearChat,
            onClose: widget.onClose,
            onLaunchExternalWeb: _launchExternalWeb,
            isMobile: isMobile,
          ),
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
                          color: Theme.of(context).colorScheme.primary,
                        ),
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
          if (!isLoading)
            ChatQuickPromptsBar(
              canRegenerate:
                  messages.isNotEmpty && messages.last['isUser'] == false,
              onRegenerate: _handleRegenerate,
              prompts: _getQuickPrompts(),
              onSelectPrompt: _handleSubmitted,
            ),
          ChatInputBar(
            textController: _textController,
            focusNode: _focusNode,
            isLoading: isLoading,
            isListening: _isListening,
            onToggleListening: _toggleListening,
            onSubmit: _handleSubmitted,
            onStop: _handleStop,
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
