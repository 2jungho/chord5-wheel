import 'package:flutter/material.dart';
import '../../../../utils/theory_utils.dart';
import 'tabs/style_voicing_tab.dart';

class ExtendedAnalysisSection extends StatelessWidget {
  final String root;
  final String quality;
  final String? selectedScaleName;
  final ValueChanged<String>? onChordSelected;

  const ExtendedAnalysisSection({
    super.key,
    required this.root,
    required this.quality,
    this.selectedScaleName,
    this.onChordSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: _buildSection(
                    context,
                    'Diatonic Context',
                    '현재 코드가 어떤 조(Key)에서 어떤 역할을 하는지 분석합니다.',
                    _buildDiatonicContextTab(context))),
            const SizedBox(width: 16),
            Expanded(
                child: _buildSection(
                    context,
                    'Tensions & Guide',
                    '사용 가능한 텐션음과 연주 시 주의사항을 알려줍니다.',
                    _buildTensionTab(context))),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: _buildSection(
                    context,
                    'Substitutions',
                    '화성적으로 교체 가능한 대리 코드를 제안합니다.',
                    _buildSubstitutionTab(context))),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSection(
                context,
                '🎸 Style & Context',
                'AI가 특정 장르에서의 활용법과 관련 명곡을 분석합니다.',
                StyleVoicingTab(
                  root: root,
                  quality: quality,
                  selectedScaleName: selectedScaleName,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
      BuildContext context, String title, String description, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(description,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
                height: 1.2)),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(minHeight: 120),
          child: content,
        ),
      ],
    );
  }

  // 1. Diatonic Context Tab
  Widget _buildDiatonicContextTab(BuildContext context) {
    final contexts = TheoryUtils.findDiatonicKeys(root, quality);

    if (contexts.isEmpty) {
      return Text(
        'No standard diatonic context found.',
        style: TextStyle(
            color: Theme.of(context).colorScheme.outline, fontSize: 12),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: contexts.entries.map((entry) {
        final key = entry.key;
        final roman = entry.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          width: 90,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Key of $key',
                  style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(roman,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 2. Tensions Tab
  Widget _buildTensionTab(BuildContext context) {
    if (selectedScaleName == null) {
      return Text(
        'Select a scale to see tensions.',
        style: TextStyle(
            color: Theme.of(context).colorScheme.outline, fontSize: 12),
      );
    }

    final tensions = TheoryUtils.analyzeTensions(root, selectedScaleName!);

    if (tensions.isEmpty) {
      return const Text('No extensions analyzed',
          style: TextStyle(fontSize: 12));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tensions.map((t) {
        final note = t['note'] as String;
        final degree = t['degree'] as String;
        final status = t['status'] as String;

        Color badgeColor;
        Color textColor;

        if (status.startsWith('Avoid')) {
          badgeColor = Theme.of(context).colorScheme.errorContainer;
          textColor = Theme.of(context).colorScheme.onErrorContainer;
        } else if (status.startsWith('Char')) {
          badgeColor = Theme.of(context).colorScheme.tertiaryContainer;
          textColor = Theme.of(context).colorScheme.onTertiaryContainer;
        } else {
          badgeColor = Theme.of(context).colorScheme.primaryContainer;
          textColor = Theme.of(context).colorScheme.onPrimaryContainer;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Text(note,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: textColor)),
              Text('$degree',
                  style: TextStyle(
                      fontSize: 9, color: textColor.withOpacity(0.8))),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 3. Substitution Tab
  Widget _buildSubstitutionTab(BuildContext context) {
    final subs = TheoryUtils.findSubstitutions(root, quality);

    if (subs.isEmpty) {
      return Text(
        'No common substitutions found.',
        style: TextStyle(
            color: Theme.of(context).colorScheme.outline, fontSize: 12),
      );
    }

    return Column(
      children: subs.take(3).map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            title: Text('${item['root']}${item['quality']}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            subtitle:
                Text(item['relation']!, style: const TextStyle(fontSize: 10)),
            trailing: const Icon(Icons.arrow_forward, size: 14),
            onTap: () {
              if (onChordSelected != null) {
                onChordSelected!('${item['root']}${item['quality']}');
              }
            },
          ),
        );
      }).toList(),
    );
  }
}
