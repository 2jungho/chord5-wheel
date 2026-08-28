import 'package:flutter/material.dart';

/// 앱 전체에서 일관된 모달 UX를 제공하기 위한 공통 다이얼로그 프레임 위젯
class AppDialogFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final double width;
  final double height;
  final Widget? headerLeading;
  final Widget? headerTrailing;
  final EdgeInsetsGeometry contentPadding;

  const AppDialogFrame({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions,
    this.width = 600,
    this.height = 700,
    this.headerLeading,
    this.headerTrailing,
    this.contentPadding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    // 모바일/작은 화면 대응 (화면 크기를 초과하지 않도록 제한)
    final effectiveWidth = width > screenSize.width * 0.95
        ? screenSize.width * 0.95
        : width;
    final effectiveHeight = height > screenSize.height * 0.92
        ? screenSize.height * 0.92
        : height;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: effectiveWidth,
        height: effectiveHeight,
        padding: contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standard Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (headerLeading != null) ...[
                  headerLeading!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (headerTrailing != null) ...[
                  headerTrailing!,
                ] else ...[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: '닫기',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Main Body Content
            Expanded(child: body),

            // Optional Actions Bottom Row
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
