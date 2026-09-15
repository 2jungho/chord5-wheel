import 'package:flutter/material.dart';
import '../../../../utils/changelog_parser.dart';
import '../../../../models/changelog_model.dart';
import 'app_dialog_frame.dart';

class ChangelogDialog extends StatelessWidget {
  const ChangelogDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: '✨ What\'s New',
      subtitle: '최신 업데이트 내역을 확인하세요. (From README.md)',
      width: 600,
      height: 700,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('닫기',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold)),
        ),
      ],
      body: FutureBuilder<List<ChangelogItem>>(
                future: ChangelogParser.loadFromReadme(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary));
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text('데이터를 불러오는데 실패했습니다.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red[300])));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                        child: Text('변경 내역이 없습니다.',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)));
                  }

                  final changelogData = snapshot.data!;

                  return ListView.builder(
                    itemCount: changelogData.length,
                    itemBuilder: (context, index) {
                      final item = changelogData[index];
                      final isLatest = index == 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Version Badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isLatest
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item.version,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isLatest
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface),
                                  ),
                                ),
                                if (item.date.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    item.date,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                                  ),
                                ],
                                if (isLatest) ...[
                                  const SizedBox(width: 8),
                                  const Text('🆕',
                                      style: TextStyle(fontSize: 16)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Changes List
                            ...item.changes.map((change) {
                              final isCategory = change.startsWith('[') &&
                                  change.endsWith(']');
                              final displayText = isCategory
                                  ? change.substring(1, change.length - 1)
                                  : change;

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: isCategory ? 4.0 : 8.0,
                                  top: isCategory ? 8.0 : 0.0,
                                  left: 4.0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isCategory) ...[
                                      Text('•',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              height: 1.4)),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        displayText,
                                        style: TextStyle(
                                          fontSize: isCategory ? 15 : 14,
                                          fontWeight: isCategory
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isCategory
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
