import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ai_provider_config.dart';

class ChatDialogs {
  static void confirmClearChat(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        title: Text(
          '대화 기록 삭제',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          '모든 대화 내용이 영구적으로 삭제됩니다.\n계속하시겠습니까?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  static void showEditMessageDialog(
    BuildContext context,
    String currentText,
    ValueChanged<String> onSave,
  ) {
    final editController = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        title: Text(
          '메시지 수정',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
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
            child: Text(
              '취소',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final newText = editController.text.trim();
              Navigator.pop(context);
              if (newText.isNotEmpty && newText != currentText) {
                onSave(newText);
              }
            },
            child: const Text(
              '수정 및 재생성',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> launchExternalWeb({
    required BuildContext context,
    required AIProviderType provider,
    required List<Map<String, dynamic>> messages,
    required String customBaseUrl,
  }) async {
    final url = switch (provider) {
      AIProviderType.gemini => 'https://gemini.google.com/',
      AIProviderType.openai => 'https://chatgpt.com/',
      AIProviderType.claude => 'https://claude.ai/',
      AIProviderType.custom => customBaseUrl,
    };
    final uri = Uri.parse(url);

    void launchSite() async {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        if (context.mounted) {
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

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
                Text(
                  '열리는 사이트의 입력창에 붙여넣기(Ctrl+V)하여\n대화를 이어가세요.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
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
      if (context.mounted) {
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
}
