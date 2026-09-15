import 'package:flutter/material.dart';
import '../../settings/settings_content.dart';
import 'app_dialog_frame.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: '환경 설정 (Settings)',
      headerLeading: Icon(
        Icons.tune,
        color: Theme.of(context).colorScheme.primary,
      ),
      width: 480,
      height: 700,
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'v3.0.0 • 2jungho@gmail.com',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('닫기'),
            ),
          ],
        ),
      ],
      body: const SettingsContent(),
    );
  }
}
