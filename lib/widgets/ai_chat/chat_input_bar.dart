import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool isLoading;
  final bool isListening;
  final VoidCallback onToggleListening;
  final ValueChanged<String> onSubmit;
  final VoidCallback onStop;

  const ChatInputBar({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.isLoading,
    required this.isListening,
    required this.onToggleListening,
    required this.onSubmit,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: isListening ? Colors.redAccent : Theme.of(context).hintColor,
            ),
            onPressed: onToggleListening,
            tooltip: '음성 인식',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: textController,
              focusNode: focusNode,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: '질문 입력...',
                hintStyle: TextStyle(color: Theme.of(context).hintColor),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                onStop();
              } else {
                onSubmit(textController.text);
              }
            },
            tooltip: isLoading ? '생성 중단' : '전송',
          ),
        ],
      ),
    );
  }
}
