import 'package:flutter/material.dart';

/// Tab content for manual text search mode (song title and artist).
class TextSearchTab extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController artistController;

  const TextSearchTab({
    super.key,
    required this.titleController,
    required this.artistController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: '곡 제목 (필수)',
            hintText: '예: Let It Be, 밤편지, Dynamite',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: artistController,
          decoration: const InputDecoration(
            labelText: '가수명 (선택)',
            hintText: '예: Beatles, 아이유, BTS',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
