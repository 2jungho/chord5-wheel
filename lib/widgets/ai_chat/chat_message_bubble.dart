import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String? provider;
  final VoidCallback? onEdit;
  final double fontSize;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.provider,
    this.onEdit,
    this.fontSize = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    // ... (BgColor logic, skipped for tool brevity if using view_file but here need to skip appropriately or replace whole logic)
    // Actually I'll replace the text styles.
    final bgColor = isUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceContainerHigh;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
      bottomRight: isUser ? Radius.zero : const Radius.circular(12),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                if (provider == 'gemini')
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.transparent,
                    child: Image.asset('assets/images/icons8-gemini.png',
                        width: 24, height: 24),
                  )
                else if (provider == 'openai')
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.transparent,
                    child: Image.asset('assets/images/icons8-chatgpt.png',
                        width: 24, height: 24),
                  )
                else
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    child: Icon(Icons.smart_toy,
                        size: 16,
                        color: Theme.of(context).colorScheme.onTertiary),
                  ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Stack(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: borderRadius,
                        border: isUser
                            ? null
                            : Border.all(
                                color: Theme.of(context).dividerColor,
                                width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser)
                            Align(
                              alignment: Alignment.topRight,
                              child: InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: message));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('메시지가 복사되었습니다.'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Icon(
                                    Icons.content_copy,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          if (isUser && onEdit != null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: onEdit,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      right: 8.0, bottom: 4.0),
                                  child: Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          isUser
                              ? SelectableText(message,
                                  style: TextStyle(
                                      color: Colors.white.withAlpha(240),
                                      fontSize: fontSize))
                              : MarkdownBody(
                                  data: message,
                                  selectable: true,
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontSize: fontSize),
                                    strong: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: fontSize),
                                    code: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        fontFamily: 'monospace',
                                        fontSize: fontSize * 0.9),
                                    codeblockDecoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
